import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { execFile as execFileCallback } from "node:child_process";
import { basename } from "node:path";
import { promisify } from "node:util";

const execFile = promisify(execFileCallback);

type Backend = "osc" | "notify-send" | "osascript" | "powershell" | "bell";

type Config = {
  disabled: boolean;
  minDurationMs: number;
  title: string;
  body: string;
  backends: Backend[];
};

const VALID_BACKENDS = new Set<Backend>(["osc", "notify-send", "osascript", "powershell", "bell"]);
const EXEC_TIMEOUT_MS = 2_000;
const NOTIFICATION_EXPIRE_MS = 5_000;
const READY_CHECK_DELAY_MS = 100;

export default function readyNotifyExtension(pi: ExtensionAPI) {
  let agentStartMs: number | undefined;
  let runSerial = 0;

  pi.on("agent_start", () => {
    agentStartMs = Date.now();
    runSerial += 1;
  });

  pi.on("agent_end", (_event, ctx) => {
    const startedAt = agentStartMs;
    const endedSerial = runSerial;
    agentStartMs = undefined;

    const config = readConfig();
    if (config.disabled || !isInteractiveTerminal(ctx)) return;

    const elapsedMs = startedAt === undefined ? 0 : Date.now() - startedAt;
    const sessionLabel = getSessionLabel(ctx, pi);

    // agent_end extension handlers can run before the interactive UI has fully
    // returned to input mode. Do the readiness check shortly after the event and
    // never await notification backends from the lifecycle handler.
    setTimeout(() => {
      if (endedSerial !== runSerial) return;
      void notifyReady(ctx, { elapsedMs, ignorePendingAndDuration: false, sessionLabel }).catch(() => {
        // Best effort only: reloads, stale contexts, missing binaries, or broken
        // terminal protocols must never affect the agent run.
      });
    }, READY_CHECK_DELAY_MS);
  });

  pi.registerCommand("ready-notify-test", {
    description: "Send a test ready notification using PI_READY_NOTIFY_* settings.",
    async handler(_args, ctx) {
      await notifyReady(ctx, {
        elapsedMs: 0,
        ignorePendingAndDuration: true,
        sessionLabel: getSessionLabel(ctx, pi)
      });
      ctx.ui.notify("Ready notification sent", "info");
    }
  });
}

async function notifyReady(
  ctx: ExtensionContext,
  options: { elapsedMs: number; ignorePendingAndDuration: boolean; sessionLabel: string }
): Promise<void> {
  const config = readConfig();
  if (config.disabled || !isInteractiveTerminal(ctx)) return;

  if (!options.ignorePendingAndDuration) {
    if (!ctx.isIdle()) return;
    if (ctx.hasPendingMessages()) return;
    if (options.elapsedMs < config.minDurationMs) return;
  }

  await dispatchNotification(config, options.sessionLabel);
}

async function dispatchNotification(config: Config, sessionLabel: string): Promise<void> {
  const title = renderTemplate(config.title, sessionLabel);
  const body = renderTemplate(config.body, sessionLabel);

  for (const backend of config.backends) {
    try {
      const delivered = await sendWithBackend(backend, title, body);
      if (delivered) return;
    } catch {
      // Try the next backend.
    }
  }
}

async function sendWithBackend(backend: Backend, title: string, body: string): Promise<boolean> {
  switch (backend) {
    case "osc":
      return sendOscNotification(title, body);
    case "notify-send":
      return execFileQuiet("notify-send", [
        "--expire-time",
        String(NOTIFICATION_EXPIRE_MS),
        title,
        body
      ]);
    case "osascript":
      return execFileQuiet("osascript", [
        "-e",
        `display notification ${appleScriptString(body)} with title ${appleScriptString(title)}`
      ]);
    case "powershell":
      return execFileQuiet(
        "powershell.exe",
        [
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy",
          "Bypass",
          "-Command",
          windowsToastScript()
        ],
        {
          PI_READY_NOTIFY_TITLE: title,
          PI_READY_NOTIFY_BODY: body
        }
      );
    case "bell":
      process.stdout.write("\u0007");
      return true;
  }
}

async function execFileQuiet(
  file: string,
  args: string[],
  extraEnv: Record<string, string> = {}
): Promise<boolean> {
  await execFile(file, args, {
    env: { ...process.env, ...extraEnv },
    timeout: EXEC_TIMEOUT_MS,
    windowsHide: true
  });
  return true;
}

function sendOscNotification(title: string, body: string): boolean {
  if (process.env.KITTY_WINDOW_ID) {
    const id = `pi-ready-${process.pid}-${Date.now()}`;
    process.stdout.write(
      `\u001b]99;i=${id}:p=title:d=0:e=1;${base64Utf8(title)}\u001b\\` +
        `\u001b]99;i=${id}:p=body:d=1:e=1;${base64Utf8(body)}\u001b\\`
    );
  } else {
    process.stdout.write(`\u001b]777;notify;${osc777Field(title)};${osc777Field(body)}\u0007`);
  }
  return true;
}

function readConfig(): Config {
  return {
    // PI_READY_NOTIFY=0 or PI_READY_NOTIFY_DISABLED=1|true|yes disables all
    // notification side effects.
    disabled: process.env.PI_READY_NOTIFY === "0" || isTruthy(process.env.PI_READY_NOTIFY_DISABLED),
    // PI_READY_NOTIFY_MIN_DURATION_MS=<number> skips shorter agent runs.
    minDurationMs: readNonNegativeNumber(process.env.PI_READY_NOTIFY_MIN_DURATION_MS, 0),
    title: process.env.PI_READY_NOTIFY_TITLE || "Pi — {session}",
    body: process.env.PI_READY_NOTIFY_BODY || "Ready for input",
    // PI_READY_NOTIFY_BACKENDS=<comma-list> supports osc, notify-send,
    // osascript, powershell, bell, and auto. Invalid entries are ignored.
    backends: readBackends(process.env.PI_READY_NOTIFY_BACKENDS)
  };
}

function readBackends(value: string | undefined): Backend[] {
  if (!value || !value.trim()) return defaultBackends();

  const backends: Backend[] = [];
  for (const rawPart of value.split(",")) {
    const part = rawPart.trim().toLowerCase();
    if (!part) continue;
    if (part === "auto") {
      backends.push(...defaultBackends());
    } else if (VALID_BACKENDS.has(part as Backend)) {
      backends.push(part as Backend);
    }
  }

  return dedupe(backends.length > 0 ? backends : defaultBackends());
}

function defaultBackends(): Backend[] {
  if (isSshSession()) return ["osc", "bell"];
  if (process.platform === "darwin") return ["osascript", "osc", "bell"];
  if (process.platform === "win32") return ["powershell", "osc", "bell"];
  if (isWsl() || process.env.WT_SESSION) return ["powershell", "osc", "notify-send", "bell"];
  if (process.platform === "linux") {
    return process.env.DISPLAY || process.env.WAYLAND_DISPLAY
      ? ["notify-send", "osc", "bell"]
      : ["osc", "bell"];
  }
  return ["osc", "bell"];
}

function isInteractiveTerminal(ctx: ExtensionContext): boolean {
  return ctx.hasUI && Boolean(process.stdout.isTTY);
}

function getSessionLabel(ctx: ExtensionContext, pi: ExtensionAPI): string {
  const namedSession = safeString(() => pi.getSessionName()) || safeString(() => ctx.sessionManager.getSessionName());
  if (namedSession) return normalizeLabel(namedSession);

  // Match Pi's session selector semantics: unnamed sessions are shown by their
  // first user message, not by the opaque JSONL session id/file name.
  const firstUserMessage = getFirstUserMessageLabel(ctx);
  if (firstUserMessage) return firstUserMessage;

  const cwdBase = basename(ctx.cwd || process.cwd());
  return cwdBase ? `Unnamed session in ${cwdBase}` : "Unnamed session";
}

function getFirstUserMessageLabel(ctx: ExtensionContext): string | undefined {
  try {
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type !== "message") continue;
      const message = entry.message;
      if (message.role !== "user") continue;
      const text = extractMessageText(message);
      if (text) return normalizeLabel(text);
    }
  } catch {
    // Fall through to cwd fallback.
  }
  return undefined;
}

function extractMessageText(message: { content?: unknown }): string | undefined {
  const content = message.content;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return undefined;

  const parts: string[] = [];
  for (const block of content) {
    if (isTextBlock(block)) parts.push(block.text);
  }
  return parts.join(" ");
}

function isTextBlock(value: unknown): value is { type: "text"; text: string } {
  return (
    typeof value === "object" &&
    value !== null &&
    "type" in value &&
    "text" in value &&
    (value as { type?: unknown }).type === "text" &&
    typeof (value as { text?: unknown }).text === "string"
  );
}

function normalizeLabel(value: string): string {
  const normalized = value.replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();
  return truncate(normalized, 96) || "Unnamed session";
}

function truncate(value: string, maxLength: number): string {
  return value.length <= maxLength ? value : `${value.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

function renderTemplate(template: string, sessionLabel: string): string {
  return template.replace(/\{session\}/g, sessionLabel);
}

function safeString(read: () => string | undefined): string | undefined {
  try {
    const value = read()?.trim();
    return value || undefined;
  } catch {
    return undefined;
  }
}

function isSshSession(): boolean {
  return Boolean(process.env.SSH_CONNECTION || process.env.SSH_CLIENT || process.env.SSH_TTY);
}

function isWsl(): boolean {
  return Boolean(process.env.WSL_DISTRO_NAME || process.env.WSL_INTEROP);
}

function isTruthy(value: string | undefined): boolean {
  return value === "1" || value?.toLowerCase() === "true" || value?.toLowerCase() === "yes";
}

function readNonNegativeNumber(value: string | undefined, fallback: number): number {
  if (value === undefined || value.trim() === "") return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}

function appleScriptString(value: string): string {
  return `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/[\u0000-\u001f\u007f]/g, " ")}"`;
}

function windowsToastScript(): string {
  return [
    "Add-Type -AssemblyName System.Windows.Forms;",
    "$n = New-Object System.Windows.Forms.NotifyIcon;",
    "$n.Icon = [System.Drawing.SystemIcons]::Information;",
    "$n.Visible = $true;",
    "$n.ShowBalloonTip(5000, $env:PI_READY_NOTIFY_TITLE, $env:PI_READY_NOTIFY_BODY, [System.Windows.Forms.ToolTipIcon]::Info);",
    "Start-Sleep -Milliseconds 750;",
    "$n.Dispose();"
  ].join(" ");
}

function osc777Field(value: string): string {
  return value.replace(/[\u0000-\u001f\u007f\u009b]/g, " ").replace(/;/g, ",").trim();
}

function base64Utf8(value: string): string {
  return Buffer.from(value, "utf8").toString("base64");
}

function dedupe<T>(values: T[]): T[] {
  return [...new Set(values)];
}

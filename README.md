# Pi Agent Setup

Private non-secret bootstrap for running the same Pi agent stack on `nl-2-nvme`.

## What this installs

- Pi CLI via Vite+: `@earendil-works/pi-coding-agent@0.74.0`
- OpenAI Codex CLI via Vite+: `@openai/codex@0.130.0`
- User settings at `~/.pi/agent/settings.json` on the remote install user, falling back to root when needed
- Custom executable subagents and chains at `~/.pi/agent/agents/`:
  - `aad-implementer`
  - `aad-failure-classifier`
  - `chrome-browser-agent`
  - `aad-explorer`
  - `aad-slice-owner`
  - `aad-acceptance-auditor`
  - `visual-critic`
  - AAD chains: `aad-discovery-plan`, `aad-owned-change`, `aad-problem-investigation`, `visual-ui-change`
- Shared AAD skills at `~/.pi/agent/skills/aad-*`
- Browser Chrome skill at `~/.pi/agent/skills/browser-chrome` via git submodule
- Browser Chrome MCP entries in `~/.pi/agent/mcp.json` pointing directly at skill scripts:
  - `browser-chrome-headed`
  - `browser-chrome-headless`
- Ready-notify extension at `~/.pi/agent/extensions/ready-notify.ts`
- Pi packages/extensions from `settings/pi-settings.vps.json`

## Ready notifications

This repo includes `extensions/ready-notify.ts`. In interactive Pi sessions it sends a best-effort desktop/terminal notification or bell after an agent run ends and Pi is idle/waiting for input. It does not notify in print/RPC/non-TTY runs or while follow-up/steering messages are queued.

Configure it in the shell (or service environment) that launches Pi:

```bash
# disable all ready-notify side effects
export PI_READY_NOTIFY=0
# or
export PI_READY_NOTIFY_DISABLED=1

# skip short runs; default is 0
export PI_READY_NOTIFY_MIN_DURATION_MS=30000

# customize text; {session} expands to the visible Pi session title:
# explicit session name first, otherwise the latest user prompt
export PI_READY_NOTIFY_TITLE="Pi — {session}"
export PI_READY_NOTIFY_BODY="Ready for input"

# choose backend order: auto, osc, notify-send, osascript, powershell, bell
export PI_READY_NOTIFY_BACKENDS=auto,bell
# force terminal bell fallback only
export PI_READY_NOTIFY_BACKENDS=bell
```

Default title is `Pi — {session}`, so the popup identifies which Pi session finished. `{session}` expands to the explicit session display name when set; for unnamed sessions it uses the latest user prompt instead of the opaque session file id. Defaults prefer native desktop notification where available on local desktop sessions (`notify-send` on Linux, `osascript` on macOS, `powershell.exe` on Windows/WSL), then terminal OSC notification, then `bell`. In SSH sessions the default is OSC first, then `bell`, because remote `notify-send` usually cannot notify the local desktop. `osc` uses Kitty OSC 99 when `KITTY_WINDOW_ID` is present, otherwise OSC 777.

After changing this repo locally, run `scripts/update-local.sh`, then use `/reload` in Pi or restart Pi. Test manually in an interactive session with:

```text
/ready-notify-test
```

For VPS installs, `scripts/install-vps.sh` deploys the extension into `~/.pi/agent/extensions/`; set any `PI_READY_NOTIFY_*` variables in the remote Pi launch environment. No host-specific notification settings or secrets are stored in this repo.

## Agent pipeline diagrams

See [`docs/agent-pipelines.html`](docs/agent-pipelines.html) for Mermaid diagrams of the checked-in subagents, AAD chains, and related worker loops.

## Visual/UI lane

For future public page visual work, landing pages, templates, hero sections, marketing blocks, or other product-quality UI surfaces, activate the optional `visual-ui-change` lane instead of the generic AAD flow. The slice owner should record a concise design/composition decision, route implementation with screenshot-first acceptance criteria, collect browser screenshots for the relevant viewports, identify the worst screenshot, and use `visual-critic` evidence before the acceptance auditor decides final status. DOM metrics, bounding boxes, and intersection checks remain supporting evidence only.

## What is intentionally not stored here

See `docs/secrets.md`. In short: no `auth.json`, no API keys/tokens, no sessions,
no SSH private keys, no runtime state.

## Update local Pi setup

Use the local update script after changing checked-in agents or the vendored `pi-codex` submodule:

```bash
scripts/update-local.sh
```

It installs `agents/*.md` into `~/.pi/agent/agents/`, installs `extensions/*.ts` into `~/.pi/agent/extensions/`, syncs checked-in skills into `~/.pi/agent/skills/`, reinstalls the vendored `packages/pi-codex` runtime dependencies with `npm ci`, verifies the ready-notify extension is declared, removes stale renamed agents/chains, rewrites the local Pi package entry for `pi-codex` to `packages/pi-codex`, backs up `~/.pi/agent/settings.json`, and verifies that installed AAD agents do not expose `codex_task`.

## Install on NL-2-NVMe

Prerequisite: Vite+ already installed for the remote install user on the VPS. Set `REMOTE_USER_HOME=/path/to/home` to override auto-detection; if no usable user home is found, scripts fall back to `/root`.

Optional version overrides:

```bash
PI_VERSION=0.74.0 CODEX_VERSION=0.130.0 TARGET_HOST=nl-2-nvme scripts/install-vps.sh
```

```bash
TARGET_HOST=nl-2-nvme scripts/install-vps.sh
```

## Codex login

After install, log in interactively on the VPS when needed:

```bash
ssh nl-2-nvme
~/.vite-plus/bin/codex login
```

Do not commit Codex auth/session files to this repo.

## Optional Pi auth import

Only after explicit approval. Uses the same remote home resolution as install/verify unless `REMOTE_AUTH` is set explicitly:

```bash
CONFIRM_COPY_PI_AUTH=1 TARGET_HOST=nl-2-nvme scripts/import-auth-vps.sh
```

## Verify

```bash
TARGET_HOST=nl-2-nvme scripts/verify-vps.sh
```

## Notes

`pi-subagents` discovers user agents from:

```text
~/.pi/agent/agents/*.md
~/.agents/*.md
```

The older local stash at `~/.pi/agents` is not used by current `pi-subagents`
discovery, so this repo stores normalized agent definitions with YAML
frontmatter and deploys them to `~/.pi/agent/agents` on the remote install user.

Pi loads global skills from `~/.pi/agent/skills/`. This repo also declares
`pi.skills` in `package.json`, so the `skills/` directory can be reused later as
a git/npm Pi package, while the VPS bootstrap still installs the skills directly
for deterministic availability.

## Browser Chrome

`skills/browser-chrome` is a submodule pointing at
`github.com/blockedby/browser-chrome-skill`. Clone/update with submodules before
installing:

```bash
git submodule update --init --recursive
```

The `browser-chrome` skill chooses between:

- `browser-chrome-headless` — disposable headless Chrome for public/simple/parallel checks.
- `browser-chrome-headed` — headed persistent Chrome only for auth/session/profile tasks.

The install script merges the two MCP servers into `~/.pi/agent/mcp.json` using
absolute paths to the installed skill scripts. It does not add wrapper commands
to `~/.local/bin`. The headed profile, Chrome cookies, saved sessions, and
browser cache are not stored in this repository.

For remote/VPS setups, headed and headless Chrome can both run on another host
behind LAN/Tailscale/SSH tunnel. Configure the skill with environment variables
such as `BROWSER_CHROME_HEADED_URL`, `BROWSER_CHROME_HEADED_START_COMMAND`,
`BROWSER_CHROME_HEADLESS_START_COMMAND`, and `BROWSER_CHROME_HEADLESS_CLOSE_COMMAND`.

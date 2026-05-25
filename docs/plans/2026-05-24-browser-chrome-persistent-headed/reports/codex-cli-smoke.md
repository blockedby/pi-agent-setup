# Codex CLI smoke: browser-chrome-control MCP

## Goal

Install the new `browser-chrome-control` MCP server into local Codex CLI and verify that Codex can discover/call it.

## Codex CLI environment

```text
codex-cli 0.130.0
command: /home/kcnc/.vite-plus/js_runtime/node/24.15.0/bin/codex
```

## Install command

```bash
codex mcp add browser-chrome-control -- \
  /home/kcnc/code/tools/pi-agent-setup/.worktrees/browser-chrome-control-mcp/skills/browser-chrome/scripts/control-mcp.sh
```

`codex mcp list` showed:

```text
browser-chrome-control ... enabled ... transport: stdio
```

## First Codex smoke result

Initial Codex smoke failed:

```text
STATUS_FAIL MCP startup failed: timed out handshaking with MCP server after 30s
```

Root cause: the control MCP server spoke only `Content-Length` framed JSON-RPC. Codex CLI expects newline-delimited JSON-RPC on stdio for MCP.

## Fix applied

Updated `skills/browser-chrome/control-mcp/server.mjs` to support both:

- newline-delimited JSON-RPC, used by Codex CLI;
- `Content-Length` framed JSON-RPC, preserving the existing local smoke style.

Also added MCP tool annotations so read-only status can be called by Codex non-interactively without user approval:

```json
{
  "readOnlyHint": true,
  "destructiveHint": false,
  "idempotentHint": true,
  "openWorldHint": false
}
```

## Verification after fix

### Direct stdio newline smoke

```bash
printf '%s\n' '<initialize json>' '<initialized notification>' '<tools/list json>' \
  | timeout 2 skills/browser-chrome/scripts/control-mcp.sh
```

Result: returned valid newline-delimited JSON-RPC initialize and tools/list responses.

### Codex status smoke

```bash
codex exec --ephemeral --json -s read-only \
  "Use the configured MCP server browser-chrome-control. Do not run shell commands. Call the browser_chrome_status tool, then answer with only: STATUS_OK if it returns forms including headed-persistent, otherwise STATUS_FAIL plus the issue."
```

Result:

```text
STATUS_OK
```

Codex successfully called:

```text
server: browser-chrome-control
tool: browser_chrome_status
```

Returned forms included:

```text
headless-disposable
headed-disposable
headed-persistent
```

### Codex headless guidance smoke

```bash
codex exec --ephemeral --json -s read-only -c 'approval_policy="never"' \
  "Use the configured MCP server browser-chrome-control. Do not run shell commands. Call browser_chrome_acquire_session with form=headless-disposable and purpose=codex-smoke, then answer ACQUIRE_OK if it returns mcpServer browser-chrome-headless; otherwise ACQUIRE_FAIL plus issue."
```

Result:

```text
ACQUIRE_OK
```

Returned guidance pointed Codex to:

```text
browser-chrome-headless
```

## Targeted tests after fix

```bash
node --test skills/browser-chrome/control-mcp/*.test.mjs
bash -n skills/browser-chrome/scripts/*.sh
node --check skills/browser-chrome/control-mcp/server.mjs
```

Result: passed.

## Notes

- The Codex MCP config currently points at this worktree path for validation.
- `browser_chrome_acquire_session` / `browser_chrome_assert_persistent` for headed persistent can launch/reuse Chrome, so those remain non-read-only and may need interactive approval in Codex unless `approval_policy="never"` is explicitly used.

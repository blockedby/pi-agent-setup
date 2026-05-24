# Implementation brief: browser-chrome control MCP

## Goal

Implement Phase 1 of the browser Chrome session-policy layer: a `browser-chrome-*` MCP server that makes session acquisition/status/assertion explicit, while preserving the existing script-first Chrome lifecycle and existing Chrome DevTools MCP servers for actual browser actions.

## Must-haves

- Add a control/session MCP server, preferably named `browser-chrome-control` in MCP config.
- Add policy tools with `browser_chrome_*` prefix, at minimum:
  - `browser_chrome_status`
  - `browser_chrome_acquire_session`
  - `browser_chrome_assert_persistent`
  - `browser_chrome_release`
- Preserve existing `browser-chrome-headed` and `browser-chrome-headless` entries.
- Do not hardcode Hermes/KCNC private paths.
- Do not require agents to memorize raw Chrome launch commands.
- Keep Chrome lifecycle delegated to existing scripts where possible.
- Model browser forms clearly:
  - `headless-disposable`
  - `headed-disposable`
  - `headed-persistent`
- Implement cross-process advisory locking for headed persistent acquisition.
- Headed release must not close the whole headed browser.
- Add/update docs so agents first call control tools, then use the returned MCP server guidance for browser actions.
- Add tests/smoke checks that do not require real private Chrome auth.

## Out of scope for this phase

- Full proxy of `chrome-devtools-mcp` tools.
- Proxying upstream MCP resources/prompts.
- Environment-specific Hermes topology or hardcoded profile paths.

## Inputs

- `decisions.md`
- `reports/hermes-vs-pi-browser-chrome.md`
- `d6b7d991/reports/subagent-managed-mcp-scout.md`
- `d6b7d991/reports/subagent-managed-mcp-plan.md`
- `d6b7d991/reports/subagent-managed-mcp-oracle.md`

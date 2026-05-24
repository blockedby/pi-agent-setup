# Acceptance plan: browser-chrome control MCP

## Acceptance criteria
- AC1: Add a `browser-chrome-control` MCP server exposing exactly the four `browser_chrome_*` policy tools.
- AC2: Preserve existing `browser-chrome-headed` and `browser-chrome-headless` MCP entries.
- AC3: Keep Phase 1 script-first lifecycle, with headed-persistent acquisition/release delegated to existing scripts and no full `chrome-devtools-mcp` proxy scope creep.
- AC4: Implement cross-process advisory locking for `headed-persistent` acquisition and ensure release does not close the whole headed browser.
- AC5: Model `headless-disposable`, `headed-disposable`, and `headed-persistent` clearly, with saved auth/session/profile state restricted to `headed-persistent`.
- AC6: Avoid hardcoded Hermes/KCNC private paths and avoid leaking private profile paths in returned status/output.
- AC7: Update installer/config/docs so agents are guided to call control tools first and then use returned DevTools MCP guidance.
- AC8: Provide fresh tests/smokes that do not require real private Chrome auth.

## Planned verification evidence
- `node --test skills/browser-chrome/control-mcp/server.test.mjs`
- `node --test skills/browser-chrome/control-mcp/config.test.mjs`
- `node --test skills/browser-chrome/control-mcp/*.test.mjs`
- stdio smoke via `skills/browser-chrome/scripts/control-mcp.sh`
- shell check for invalid headed port policy
- diff/doc inspection for hardcoded path / proxy scope / preserved MCP entries

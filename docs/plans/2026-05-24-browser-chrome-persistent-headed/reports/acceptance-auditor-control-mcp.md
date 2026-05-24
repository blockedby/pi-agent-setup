## Task package
- Task name: browser-chrome persistent headed protocol / control MCP
- Task package: docs/plans/2026-05-24-browser-chrome-persistent-headed/
- Report path: docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/acceptance-auditor-control-mcp.md
- Acceptance plan path: docs/plans/2026-05-24-browser-chrome-persistent-headed/verification/acceptance-plan.md

## Acceptance verdict
- Status: accepted
- Summary: Phase 1 control/session MCP is implemented, tested, docs/config are updated, existing headed/headless entries are preserved, and the implementation stays within the staged no-proxy scope.

## Acceptance coverage
- AC1: Add a `browser-chrome-control` MCP server exposing exactly the four `browser_chrome_*` policy tools.
  - Evidence present: `node --test skills/browser-chrome/control-mcp/server.test.mjs`; stdio smoke via `skills/browser-chrome/scripts/control-mcp.sh`.
  - Result: passed
  - Gap: none
- AC2: Preserve existing `browser-chrome-headed` and `browser-chrome-headless` MCP entries.
  - Evidence present: `node --test skills/browser-chrome/control-mcp/config.test.mjs`; `skills/browser-chrome/mcp/browser-chrome.mcp.json`; installer test output.
  - Result: passed
  - Gap: none
- AC3: Keep Phase 1 script-first lifecycle, with headed-persistent acquisition/release delegated to existing scripts and no full `chrome-devtools-mcp` proxy scope creep.
  - Evidence present: `skills/browser-chrome/control-mcp/server.mjs` calls `scripts/open-headed.sh`; docs in `skills/browser-chrome/SKILL.md` and `references/mcp-config.md`; no tool/resource/prompt proxy code in the control server.
  - Result: passed
  - Gap: none
- AC4: Implement cross-process advisory locking for `headed-persistent` acquisition and ensure release does not close the whole headed browser.
  - Evidence present: `node --test skills/browser-chrome/control-mcp/server.test.mjs` lock contention/release case; `release` returns `closedBrowser: false` and only removes the lock dir.
  - Result: passed
  - Gap: none
- AC5: Model `headless-disposable`, `headed-disposable`, and `headed-persistent` clearly, with saved auth/session/profile state restricted to `headed-persistent`.
  - Evidence present: `server.test.mjs` status/acquire/assert cases; `SKILL.md` mode-selection section.
  - Result: passed
  - Gap: none
- AC6: Avoid hardcoded Hermes/KCNC private paths and avoid leaking private profile paths in returned status/output.
  - Evidence present: source inspection of changed implementation files; `server.test.mjs` asserts private `user-data-dir` path is not present in status output; grep found Hermes/KCNC strings only in investigation/docs, not in implementation code.
  - Result: passed
  - Gap: none
- AC7: Update installer/config/docs so agents are guided to call control tools first and then use returned DevTools MCP guidance.
  - Evidence present: `skills/browser-chrome/SKILL.md`, `README.md`, `references/mcp-config.md`, `scripts/install-local.sh`.
  - Result: passed
  - Gap: none
- AC8: Provide fresh tests/smokes that do not require real private Chrome auth.
  - Evidence present: `node --test skills/browser-chrome/control-mcp/*.test.mjs` (8/8), stdio initialize/tools/list smoke, invalid headed-port shell check.
  - Result: passed
  - Gap: none

## System readiness coverage
- Routes / registration: covered — `initialize`/`tools/list` expose the new server and the installer writes the `browser-chrome-control` MCP entry.
- Services / APIs: covered — control server implements the four policy tools; existing `browser-chrome-headed` / `browser-chrome-headless` DevTools wrappers remain unchanged.
- Config / env / secrets: covered — headed port validation is enforced; control/status use env-driven home/profile settings and do not expose private paths.
- Docker / containers: not relevant.
- Permissions / access: covered — lease acquisition/release enforces single-owner headed-persistent access.
- Database / migrations: not relevant.
- Frontend-backend integration: not relevant.
- Runtime / deployment wiring: covered — launcher script, installer, and MCP config are wired for the new control server while preserving the existing DevTools entries.

## Check freshness
- Targeted checks: fresh
- Full local checks: not needed
- Remote checks / CI: not available before push

## Required before done
- None for acceptance. Optional future work: define stale-lock recovery policy if desired, but it is not required for Phase 1 acceptance.

## Files written
- docs/plans/2026-05-24-browser-chrome-persistent-headed/verification/acceptance-plan.md: created
- docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/acceptance-auditor-control-mcp.md: created

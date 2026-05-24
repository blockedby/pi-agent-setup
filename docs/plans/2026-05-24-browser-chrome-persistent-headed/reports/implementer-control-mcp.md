PI_RESULT: PASS
TASK: browser-chrome control MCP
TASK_PACKAGE: docs/plans/2026-05-24-browser-chrome-persistent-headed
REPORT_PATH: docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/implementer-control-mcp.md
PROGRESS_PATH: progress.md
COMMITS:
- 64edc90545bcf358c6355697b01518e51dfbfd4f: Add browser Chrome control MCP
- parent worktree commit: pending at report write; final response records the actual parent commit that adds this report/progress and updates the submodule pointer.
FILES_CHANGED:
- skills/browser-chrome/control-mcp/server.mjs: added focused stdio JSON-RPC/MCP control server with `browser_chrome_status`, `browser_chrome_acquire_session`, `browser_chrome_assert_persistent`, and `browser_chrome_release`.
- skills/browser-chrome/control-mcp/server.test.mjs: added node:test coverage for MCP initialize, tools/list, status, policy enforcement, headed-persistent lock contention/release, assert behavior, and headless guidance without real Chrome/auth.
- skills/browser-chrome/control-mcp/config.test.mjs: added config/installer checks preserving headed/headless while adding control.
- skills/browser-chrome/scripts/control-mcp.sh: added portable Node launcher using `${BROWSER_CHROME_NODE:-node}`.
- skills/browser-chrome/scripts/common.sh: added headed persistent port validation for `9200-9300`.
- skills/browser-chrome/scripts/install-local.sh: installer now writes `browser-chrome-control` plus existing `browser-chrome-headed`/`browser-chrome-headless` entries.
- skills/browser-chrome/mcp/browser-chrome.mcp.json: example MCP config now includes `browser-chrome-control` and preserves headed/headless entries.
- skills/browser-chrome/SKILL.md, README.md, references/mcp-config.md: documented control-first workflow, modeled forms, headed-persistent lease/release semantics, and no full proxy.
- progress.md: implementation progress ledger.
- docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/implementer-control-mcp.md: this implementation report.
AC_VERIFICATION:
- Add browser-chrome control/session MCP with exact four `browser_chrome_*` policy tools: `node --test skills/browser-chrome/control-mcp/server.test.mjs` passed; initialize/tools-list test asserts exact tool names — passed.
- Preserve existing headed/headless DevTools MCP entries: `node --test skills/browser-chrome/control-mcp/config.test.mjs` passed; asserts control/headed/headless exist in example and installer output — passed.
- Script-first lifecycle and no full proxy: implementation calls `scripts/open-headed.sh` for headed-persistent acquire/assert and returns MCP guidance; it does not proxy `chrome-devtools-mcp` tools/resources/prompts — passed by code inspection and tests.
- Cross-process advisory locking for headed-persistent acquisition: node:test lock contention verifies second controller gets busy while first lease is active and can acquire after release — passed.
- Headed release must not close the whole headed browser: release test verifies `closedBrowser: false` and no close script invocation; implementation only removes the control lock dir — passed.
- Model `headless-disposable`, `headed-disposable`, and `headed-persistent`: status test asserts all three forms; acquire/assert reject inappropriate persistent/disposable combinations — passed.
- Avoid private Chrome auth/path dependency: tests use fake lifecycle scripts, temp `BROWSER_CHROME_HOME`, and local fake `/json/version`; no real Chrome/auth/profile is launched or inspected — passed.
- Installer/config/docs updated for control-first workflow: config/installer node:test plus doc changes in `SKILL.md`, `README.md`, and `references/mcp-config.md` — passed.
TESTS_RUN:
- `node --test skills/browser-chrome/control-mcp/server.test.mjs`: passed (6 tests).
- `node --test skills/browser-chrome/control-mcp/config.test.mjs`: passed (2 tests).
- `node --test skills/browser-chrome/control-mcp/*.test.mjs`: passed (8 tests).
- Stdio smoke via `skills/browser-chrome/scripts/control-mcp.sh` with framed `initialize` and `tools/list`: passed (`stdio smoke ok`).
- Invalid headed port shell check with `BROWSER_CHROME_HEADED_PORT=9400` and `bc_headed_port`: passed by failing non-zero and printing `hint=use-9200-9300`.
QUALITY_CHECKS:
- `bash -n skills/browser-chrome/scripts/*.sh`: passed.
- `node --check skills/browser-chrome/control-mcp/server.mjs`: passed.
- `node --test skills/browser-chrome/control-mcp/*.test.mjs`: passed (8/8).
- Installer temp smoke embedded in `config.test.mjs`: passed with temp `BROWSER_CHROME_MCP_JSON` and `BROWSER_CHROME_SKILL_TARGET`.
QUALITY_NOTES:
- Readability/reuse: reused existing browser-chrome scripts for lifecycle; new code is isolated to a small control MCP and tests because no adjacent MCP control helper existed.
- Error handling/logging: tool errors are explicit and structured; raw `open-headed.sh` output/stderr is not echoed back to avoid leaking profile paths.
- Backend/API/data: MCP JSON-RPC contract is additive; no storage/db/migrations. Lease file is local control state under `BROWSER_CHROME_HOME/control`.
- Frontend/UI: not relevant.
- DevOps/runtime: installer/config adds one MCP server while preserving existing headed/headless runtime entries; launcher resolves skill dir and uses `BROWSER_CHROME_NODE` override.
- Security: no secrets, cookies, tokens, profile contents, or private profile paths are logged or returned; tests use fake endpoints and temp homes.
- Concurrency/idempotency: headed-persistent uses atomic lock-directory acquisition with lease id validation; release is safe/no-op when no active lease and does not close Chrome.
- Compatibility/performance: existing headed/headless MCP script behavior is preserved; status performs only a bounded local endpoint check and does not launch Chrome.
SIDE_FINDINGS:
- Blocking: none.
- Non-blocking follow-up candidates: future Phase 2 could proxy DevTools MCP if owner decides the two-server workflow is too costly; stale lock recovery policy may need an explicit owner decision if agents die while holding a lease.
NOTES: Implementation intentionally excludes full `chrome-devtools-mcp` proxying and environment-specific Hermes/KCNC paths. The parent repo sees `skills/browser-chrome` as a submodule; implementation is committed inside that submodule and the parent commit will update the submodule pointer plus task-package report/progress.

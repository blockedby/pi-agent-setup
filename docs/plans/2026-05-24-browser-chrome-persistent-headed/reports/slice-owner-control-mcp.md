## Task
- Mission: Own the Phase 1 implementation slice for browser Chrome control/session MCP and leave an implementation-ready brief.
- Target: `skills/browser-chrome` skill and existing task package `docs/plans/2026-05-24-browser-chrome-persistent-headed`.
- Boundaries: Phase 1 only: control/session MCP with `browser_chrome_*` policy tools, script-first lifecycle, headed persistent locking, docs/tests. Do not build the full `chrome-devtools-mcp` proxy. Do not hardcode Hermes/KCNC paths. Do not edit unrelated files. Do not use Codex as implementation delegate.
- Done when: The next implementer can execute without reopening proxy design questions.
- Expected evidence: Intake from implementation brief, decisions, Hermes comparison, and oracle report; scoped plan/routing packet; acceptance and verification targets.

## Context
- Thread: Browser Chrome persistent headed/session policy work.
- Slice: Phase 1 browser Chrome control/session MCP.
- Task name: browser-chrome control MCP.
- Task package: `docs/plans/2026-05-24-browser-chrome-persistent-headed`.
- Report path: `docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/slice-owner-control-mcp.md`.
- Worktree: `/home/kcnc/code/tools/pi-agent-setup/.worktrees/browser-chrome-control-mcp`.
- Branch: `browser-chrome-control-mcp`.
- Verify scope: targeted script syntax, Node tests/smoke checks, installer/config generation, no real private Chrome auth required.
- Review target: implementation should be confined to `skills/browser-chrome/**` and task-package docs/reports as needed.

## Slice decision
- Keep as one owned slice. The Phase 1 surface has one ownership boundary: a small control MCP plus docs/tests around the existing browser-chrome scripts.
- Delegate implementation as one clear `aad-implementer` task unless it grows unexpectedly. No sub-slice needed.
- Do not delegate to Codex.

## Inputs read
- `implementation-brief.md`: requires `browser-chrome-control` MCP and policy tools `browser_chrome_status`, `browser_chrome_acquire_session`, `browser_chrome_assert_persistent`, `browser_chrome_release`.
- `decisions.md`: confirms prefixed policy tools, three modeled browser forms, advisory locking for headed persistent, no Phase 1 upstream proxy.
- `reports/hermes-vs-pi-browser-chrome.md`: establishes the key UX problem: agents confuse any headed/CDP Chrome with persistent logged-in headed profile; preserve portable script-first design.
- `d6b7d991/reports/subagent-managed-mcp-oracle.md`: recommends Phase 1 control MCP first; warns full proxy introduces unnecessary lifecycle/protocol risk.
- Existing `plan.md` and `d6b7d991/reports/subagent-managed-mcp-plan.md`: contain older/full-proxy ideas and must not drive this Phase 1 as written.

## Repo orientation / reuse targets
- Current skill entry: `skills/browser-chrome/SKILL.md`.
- Existing MCP config example: `skills/browser-chrome/mcp/browser-chrome.mcp.json`.
- Installer: `skills/browser-chrome/scripts/install-local.sh` currently writes `browser-chrome-headed` and `browser-chrome-headless` entries.
- Lifecycle source of truth:
  - `scripts/open-headed.sh` for persistent headed open/reuse.
  - `scripts/open-headless.sh` and `scripts/close-headless.sh` for disposable headless lifecycle.
  - `scripts/check-opened.sh` for reachability checks.
  - `scripts/mcp.sh` for existing DevTools MCP servers; preserve unchanged behavior unless a minimal shared helper is needed.
- Shared shell helpers: `scripts/common.sh` for URL/profile/env helpers.
- Current evidence mismatch to verify during implementation: older reports say headed port validation already exists, but this worktree's `common.sh` currently shows `bc_headed_port()` returning `${BROWSER_CHROME_HEADED_PORT:-9233}` without visible `9200-9300` validation. The implementer should inspect current files and add/restore validation only if still absent and required by acceptance.

## Phase 1 implementation-ready brief

### Goal
Add a portable `browser-chrome-control` MCP server that makes browser session policy explicit before agents use existing `browser-chrome-headed` / `browser-chrome-headless` Chrome DevTools MCP servers for browser actions.

### In scope
- New control/session MCP entry, preferably `browser-chrome-control`.
- Policy tools with exact prefixed names:
  - `browser_chrome_status`
  - `browser_chrome_acquire_session`
  - `browser_chrome_assert_persistent`
  - `browser_chrome_release`
- Explicit browser forms in tool inputs/outputs/docs:
  - `headless-disposable`
  - `headed-disposable`
  - `headed-persistent`
- Cross-process advisory lock for headed persistent acquisition.
- Script-first lifecycle: invoke/reuse existing scripts; do not duplicate Chrome launch command logic in the MCP server.
- Headed release releases only the control lease/lock; it must not close the whole headed browser.
- Docs/tests/smoke checks that avoid private auth.

### Out of scope
- Full proxy of `chrome-devtools-mcp` tools/resources/prompts.
- Merging upstream `tools/list`.
- Replacing existing `browser-chrome-headed` / `browser-chrome-headless` servers.
- Hermes/KCNC topology, private paths, profile contents, cookies/tokens.

### Expected implementation shape
- Add a launcher script such as `skills/browser-chrome/scripts/control-mcp.sh` that validates arguments, resolves the skill directory, and execs Node through `${BROWSER_CHROME_NODE:-node}`.
- Add a small Node stdio MCP server under `skills/browser-chrome/control-mcp/` or similar. Keep it focused on MCP initialize/tools/list/tools/call for the four policy tools only.
- Add a lock mechanism for `headed-persistent` acquisition. Prefer an advisory lock file under `${BROWSER_CHROME_HOME:-...}` or a dedicated subdir, implemented with a portable primitive available in the target environment. If using `flock`, fail clearly when unavailable or document the dependency.
- For `headed-persistent` acquisition/assertion, call `scripts/open-headed.sh` and parse its `url=` output, then probe `/json/version` via existing helper behavior or equivalent safe local HTTP check.
- For `headless-disposable`, Phase 1 can return guidance to use `browser-chrome-headless` for actual browser actions. Avoid creating an uncontrollable headless orphan unless the control server also owns cleanup. If implemented, acquisition must return an id/url and release/exit must close via `close-headless.sh`.
- For `headed-disposable`, document/status can model the form, but do not invent a new disposable-headed launcher unless required; persistent-auth assertions must reject it.
- Update `skills/browser-chrome/mcp/browser-chrome.mcp.json` and `scripts/install-local.sh` to add `browser-chrome-control` while preserving existing headed/headless entries.
- Update `SKILL.md`, `README.md`, and `references/mcp-config.md` so agents first call control tools, then use returned guidance naming the existing MCP server for actual browser actions.

### Tool contract acceptance
- `browser_chrome_status` returns configured forms, current known lease/lock state, relevant endpoint/guidance, and whether persistent headed is reachable without printing private profile data.
- `browser_chrome_acquire_session` accepts a requested form/purpose, enforces that saved auth/session/profile use requires `headed-persistent`, acquires the headed-persistent advisory lock when requested, opens/reuses via script, and returns MCP guidance such as `use browser-chrome-headed for chrome_devtools_* actions`.
- `browser_chrome_assert_persistent` fails clearly for headless/disposable forms and succeeds only when headed-persistent config is present, the endpoint is reachable after script-first open/reuse, and port/profile policy passes.
- `browser_chrome_release` releases only the control lease/lock. For headed-persistent it must not close Chrome; for any headless lease it owns, it must clean up safely.

### Tests / verification targets
- Static/syntax:
  - `bash -n skills/browser-chrome/scripts/*.sh`
  - `node --check <new Node server files>`
- Unit/smoke without real private Chrome:
  - Node `node:test` coverage for MCP initialize, `tools/list`, and each policy tool.
  - Fake/stub lifecycle scripts or temp environment so tests do not launch real Chrome or inspect auth.
  - Lock contention test: second headed-persistent acquire should fail or report busy while first lease is active; after release it can acquire.
  - Release test: headed release removes lease/lock and does not call any whole-browser close path.
  - Docs/config test or assertion: existing `browser-chrome-headed` and `browser-chrome-headless` entries remain.
- Installer smoke:
  - Run `skills/browser-chrome/scripts/install-local.sh` only if acceptable in local environment; otherwise validate generated config logic in test with temp `BROWSER_CHROME_MCP_JSON` and `BROWSER_CHROME_SKILL_TARGET`.
- Optional Pi smoke after implementation:
  - `scripts/update-local.sh`
  - `timeout 120 "$HOME/.vite-plus/bin/pi" --no-session --mode text -p 'Say OK and exit.'`

## Dependency graph / routing packet
- Task A: Implement control MCP server and launcher.
  - Goal: Four `browser_chrome_*` tools work over stdio MCP and delegate lifecycle to scripts.
  - Depends on: none.
  - Blocks: docs/config final verification.
  - Executor: `aad-implementer`.
- Task B: Add installer/config/docs for control-first workflow.
  - Goal: `browser-chrome-control` is registered without removing existing servers; docs teach acquire/assert then use existing DevTools MCP.
  - Depends on: Task A launcher/tool names.
  - Executor: same `aad-implementer` unless split is cheaper.
- Task C: Tests and verification.
  - Goal: prove policy behavior, lock behavior, and compatibility without private auth.
  - Depends on: Tasks A/B.
  - Executor: same `aad-implementer`.

Recommended handoff to implementer:
- Reads: `implementation-brief.md`, `decisions.md`, this report, `reports/hermes-vs-pi-browser-chrome.md`, `d6b7d991/reports/subagent-managed-mcp-oracle.md`.
- Report path: `docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/aad-implementer-control-mcp.md`.
- Progress path: `docs/plans/2026-05-24-browser-chrome-persistent-headed/progress/aad-implementer-control-mcp.md` if a progress directory is created.
- Do-not-touch: no full proxy; no Hermes paths; no unrelated repo files; no Codex implementation delegate.

## Spec compliance
- Phase 1 scoping: done for handoff. Evidence: this report narrows older full-proxy plan to control MCP only.
- Policy tool naming: done for handoff. Evidence: exact `browser_chrome_*` names recorded above.
- Script-first lifecycle: done for handoff. Evidence: reuse targets are existing `open-*`, `close-*`, `check-opened.sh`, and existing MCP servers.
- Locking: planned but not implemented in this report.
- Docs/tests: planned but not implemented in this report.

## Acceptance verification
- AC: Read provided task package files.
  - Result: passed.
  - Evidence: inputs listed above.
- AC: Keep scope to Phase 1 and avoid full proxy.
  - Result: passed for planning/handoff.
  - Evidence: out-of-scope and implementation shape exclude upstream proxying.
- AC: Produce implementation-ready brief.
  - Result: passed.
  - Evidence: Phase 1 implementation-ready brief and routing packet above.

## System readiness
- Routes / registration: missing; implementer must add `browser-chrome-control` config/installer entry.
- Services / APIs: missing; implementer must add MCP server/tool handlers.
- Config / env / secrets: ready with constraints; no secrets/private paths should be added.
- Permissions / access: no private auth needed for tests.
- Database / migrations: not relevant.
- Frontend-backend integration: not relevant.
- Runtime / deployment wiring: missing until installer/config is updated and smoke-tested.

## Verification run
- Local / targeted checks:
  - File/task-package read-through: passed.
    - Evidence: report cites exact files and current worktree paths.
  - Code tests: not run.
    - Reason: this slice-owner pass did not implement code.
- Local / full checks:
  - Not run; no production changes made.
- Remote checks / CI:
  - Not available before implementation/push.

## Issues
### Issue U-01: Implementation still required
- Description: Control MCP, docs, tests, and installer/config entries are not yet implemented.
- Evidence: current worktree still has only existing `browser-chrome-headed` and `browser-chrome-headless` config entries; no `browser-chrome-control` code was added by this owner pass.
- Why unresolved: this report is the requested implementation-ready handoff, not production/test implementation.
- Needed next: Dispatch `aad-implementer` with the routing packet above.
- Depends on: none.

### Issue U-02: Current port-validation evidence conflicts with prior report
- Description: Prior scout/oracle evidence says headed port validation exists, but current `skills/browser-chrome/scripts/common.sh` in this worktree does not visibly validate `BROWSER_CHROME_HEADED_PORT` in `bc_headed_port()`.
- Evidence: `bc_headed_port()` currently prints `${BROWSER_CHROME_HEADED_PORT:-9233}` directly.
- Why unresolved: needs implementation-time inspection/fix as part of policy validation; no code changes were requested in this owner handoff.
- Needed next: Implementer should add or restore `9200-9300` validation if absent, with tests.
- Depends on: Task A/C.

## Side findings
- Blocking findings folded into active work: U-01 and U-02.
- Non-blocking findings tracked separately: none.

## Verdict
- Status: partial.
- Goal state: handoff achieved; implementation not yet achieved.
- Final readiness: not ready until implementer completes code/docs/tests and verification.
- Summary: Phase 1 should proceed as one control-MCP implementation task, explicitly excluding full proxy work and preserving the existing script-first DevTools MCP servers.

## Next-agent brief
- Objective: Implement Phase 1 `browser-chrome-control` MCP with the four `browser_chrome_*` policy tools, advisory headed-persistent locking, installer/docs updates, and tests.
- Target: `skills/browser-chrome/**` plus task-package report/progress files only.
- Settled already: no full proxy; policy tools are prefixed; actual browser actions remain on existing `browser-chrome-headed` / `browser-chrome-headless`; headed release must not close Chrome; no private paths/auth data.
- Boundaries: do not build/merge upstream `chrome-devtools-mcp` proxy tools; do not remove existing MCP entries; do not use Codex as implementation delegate.
- Verification target: syntax checks, Node tests with fake/stub lifecycle, lock contention/release tests, config/installer validation, docs showing control-first workflow.
- Expected output: implementation report at `docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/aad-implementer-control-mcp.md` with commands run, files changed, unresolved blockers, and acceptance evidence.

# Implementation Plan

## Goal
Add a portable `browser-chrome-managed` MCP wrapper that preserves the existing script-first Chrome lifecycle, proxies `chrome-devtools-mcp` tools, and exposes session-policy tools for acquiring, checking, releasing, and asserting persistent headed sessions.

## Tasks
1. **Define the managed MCP tool contract**
   - File: `skills/browser-chrome/references/mcp-config.md`
   - Changes: Document the new managed server contract before implementation: managed servers run in `headed` or `headless` mode, proxy upstream `chrome-devtools-mcp` tools unchanged, and add policy tools named `acquire_session`, `status`, `release`, and `assert_persistent`.
   - Acceptance: Docs state exact inputs/outputs and mode behavior for all four policy tools, including that `assert_persistent` succeeds only for headed mode with a reachable DevTools endpoint on a `9200`-`9300` port.

2. **Create a managed MCP launcher script**
   - File: `skills/browser-chrome/scripts/managed-mcp.sh`
   - Changes: Add a small Bash wrapper that resolves `SCRIPT_DIR`, validates `headed|headless`, exports existing defaults like `CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1`, and execs a Node script using `${BROWSER_CHROME_NODE:-node}`. Keep lifecycle delegated to existing scripts; do not embed Chrome launch logic here.
   - Acceptance: `skills/browser-chrome/scripts/managed-mcp.sh headed --help` reaches the Node entrypoint; invalid mode exits with usage; no hardcoded user/Hermes paths appear.

3. **Implement the managed MCP stdio server MVP**
   - File: `skills/browser-chrome/managed-mcp/server.mjs`
   - Changes: Add a dependency-free Node MCP stdio server that handles at least `initialize`, `tools/list`, `tools/call`, and basic notifications. It should spawn the upstream `chrome-devtools-mcp` process as a child over stdio, initialize it as an MCP client, merge upstream tools with the four policy tools, and forward calls to upstream tools unchanged.
   - Acceptance: A fake upstream MCP server can be proxied through the managed server; `tools/list` includes both fake upstream tools and the four policy tools; `tools/call` forwards upstream calls and returns upstream results.

4. **Delegate session acquisition to existing browser scripts**
   - File: `skills/browser-chrome/managed-mcp/server.mjs`
   - Changes: Implement `ensureSession()` by invoking existing scripts instead of duplicating lifecycle logic:
     - headed: run `scripts/open-headed.sh`, parse `url=...`, and reuse `bc_headed_url` behavior indirectly through script output.
     - headless: run `scripts/open-headless.sh`, parse `id=...` and `url=...`, and register process-exit cleanup through `scripts/close-headless.sh <id>`.
     - upstream child command defaults to the current `npx -y ${BROWSER_CHROME_MCP_PACKAGE:-chrome-devtools-mcp@latest} --no-usage-statistics --no-performance-crux --browser-url=<url>` behavior.
     - add a test/debug override such as `BROWSER_CHROME_MCP_COMMAND` for spawning a fake upstream without relying on `npx`.
   - Acceptance: Managed headed starts/reuses through `open-headed.sh`; managed headless creates and cleans up through `open-headless.sh`/`close-headless.sh`; existing `scripts/mcp.sh` behavior remains unchanged.

5. **Implement policy tools**
   - File: `skills/browser-chrome/managed-mcp/server.mjs`
   - Changes:
     - `acquire_session`: starts/reuses the configured browser, starts the upstream MCP child if needed, and returns mode, URL, acquired state, persistence status, and headless id when applicable.
     - `status`: returns configured mode, acquired state, endpoint URL if known, upstream child status, reachability probe result, and persistence policy summary.
     - `release`: releases the managed MCP lease; for headless, closes the headless browser via `close-headless.sh`; for headed, stops only the upstream child/managed lease and leaves the browser open.
     - `assert_persistent`: validates that the server is in headed mode, the DevTools URL has a port in `9200`-`9300`, the configured headed profile values are non-empty, and the endpoint is reachable after `open-headed.sh` has run.
   - Acceptance: Policy tools return structured MCP tool results with clear success/failure text; `release` never closes the whole headed browser; `assert_persistent` fails clearly in headless mode.

6. **Handle lifecycle, errors, and signal cleanup**
   - File: `skills/browser-chrome/managed-mcp/server.mjs`
   - Changes: Add cleanup handlers for `exit`, `SIGINT`, and `SIGTERM`; kill the upstream MCP child on release/exit; close headless sessions on exit; propagate upstream initialization and tool-call errors as MCP errors with actionable messages.
   - Acceptance: Ctrl-C or MCP disconnect cleans up headless state; headed browser remains running; upstream child is not orphaned in normal shutdown.

7. **Expose managed servers in checked-in MCP config**
   - File: `skills/browser-chrome/mcp/browser-chrome.mcp.json`
   - Changes: Add managed server entries alongside the existing compatibility entries:
     - `browser-chrome-managed-headed`: command `browser-chrome-managed-mcp`, args `["headed"]`, lifecycle `lazy`.
     - `browser-chrome-managed-headless`: command `browser-chrome-managed-mcp`, args `["headless"]`, lifecycle `lazy`, `idleTimeout: 1`.
   - Acceptance: Existing `browser-chrome-headed` and `browser-chrome-headless` entries remain available; new managed entries are documented and use the same env defaults.

8. **Update the local installer**
   - File: `skills/browser-chrome/scripts/install-local.sh`
   - Changes: Install the new `managed-mcp.sh` script and write two additional MCP entries to `~/.pi/agent/mcp.json` using the installed script path, not a wrapper binary or hardcoded path. Keep existing entries unchanged for compatibility.
   - Acceptance: Running `scripts/install-local.sh` creates/updates four MCP servers: headed, headless, managed-headed, and managed-headless; generated config points at `~/.pi/agent/skills/browser-chrome/scripts/managed-mcp.sh` or the configured install target.

9. **Update skill and README usage guidance**
   - Files: `skills/browser-chrome/SKILL.md`, `skills/browser-chrome/README.md`, `skills/browser-chrome/references/mcp-config.md`
   - Changes: Explain when to prefer managed MCP servers, show example `mcp({ server: "browser-chrome-managed-headed" })`, and state that policy tools are the preferred way to assert persistent auth/session requirements before interacting with private pages.
   - Acceptance: Documentation preserves the existing headless-vs-headed contract, continues to say headed only for auth/session/profile tasks, and includes no machine-specific private paths.

10. **Add unit/integration tests for the managed server**
    - Files: `skills/browser-chrome/tests/managed-mcp.test.mjs`, `skills/browser-chrome/tests/fixtures/fake-upstream-mcp.mjs`, optionally `skills/browser-chrome/tests/fixtures/fake-devtools-endpoint.mjs`
    - Changes: Use Node's built-in `node:test` to spawn `managed-mcp.sh` or `server.mjs` with fake upstream and fake DevTools endpoint. Cover initialize, tools/list merge, upstream call forwarding, each policy tool, headless cleanup, and headed persistence validation.
    - Acceptance: `node --test skills/browser-chrome/tests/*.test.mjs` passes without launching real Chrome and without network access beyond localhost fixtures.

11. **Add shell/static verification**
    - Files: `skills/browser-chrome/scripts/managed-mcp.sh`, `skills/browser-chrome/managed-mcp/server.mjs`
    - Changes: Add executable bit for the new shell script; run `bash -n` on shell scripts and `node --check` on the Node server. If this repo has no central test script, document these commands in the report/progress for the implementation.
    - Acceptance: Syntax checks pass; existing `scripts/mcp.sh` remains unchanged and usable.

12. **Manual smoke test with real MCP/Pi after installation**
    - Files: installed local config under `~/.pi/agent/mcp.json` after `scripts/install-local.sh`
    - Changes: No repo code change; run install and exercise managed MCP through Pi.
    - Acceptance: Pi can connect to `browser-chrome-managed-headed`, call `status`, call `assert_persistent`, list proxied Chrome DevTools tools, and call at least one safe proxied tool such as page listing. Pi can connect to `browser-chrome-managed-headless`, call `acquire_session`, list proxied tools, and release/exit with headless cleanup.

## Files to Modify
- `skills/browser-chrome/SKILL.md` - document managed MCP usage and policy-tool workflow.
- `skills/browser-chrome/README.md` - add managed server overview, examples, and env override notes.
- `skills/browser-chrome/references/mcp-config.md` - add canonical managed MCP config and policy tool contract.
- `skills/browser-chrome/mcp/browser-chrome.mcp.json` - add managed headed/headless server entries.
- `skills/browser-chrome/scripts/install-local.sh` - install and register managed MCP servers using installed script paths.

## New Files
- `skills/browser-chrome/scripts/managed-mcp.sh` - script-first launcher for the managed MCP server.
- `skills/browser-chrome/managed-mcp/server.mjs` - dependency-free MCP proxy/server implementation.
- `skills/browser-chrome/tests/managed-mcp.test.mjs` - Node test coverage for proxy and policy tools.
- `skills/browser-chrome/tests/fixtures/fake-upstream-mcp.mjs` - fake upstream MCP server for tests.
- `skills/browser-chrome/tests/fixtures/fake-devtools-endpoint.mjs` - optional localhost `/json/version` fixture for reachability tests.

## Dependencies
- Tasks 2-6 depend on Task 1's contract decisions.
- Task 3 depends on Task 2 for the launcher path and environment conventions.
- Tasks 4-6 depend on Task 3's MCP request/response plumbing.
- Tasks 7-9 depend on the new launcher and tool contract.
- Tasks 10-11 depend on the implementation files from Tasks 2-6.
- Task 12 depends on installer/config updates from Tasks 7-9.

## Risks
- MCP protocol compatibility: a hand-rolled dependency-free stdio server must correctly handle the protocol version and `tools/list` pagination used by `chrome-devtools-mcp`. Validate against the real upstream package, not only fixtures.
- Tool name collisions: if upstream later exposes `acquire_session`, `status`, `release`, or `assert_persistent`, the managed server needs a deterministic collision policy. MVP should fail fast and report the collision rather than silently shadowing upstream tools.
- Upstream command override ambiguity: current scripts expose `BROWSER_CHROME_NPX` and `BROWSER_CHROME_MCP_PACKAGE`; tests may need a full-command override. Define and document `BROWSER_CHROME_MCP_COMMAND` carefully to avoid breaking existing env behavior.
- Persistent-profile verification is limited for remote headed sessions. The wrapper can validate configured URL/port/profile env and endpoint reachability, but cannot always prove the remote Chrome process used the intended `--user-data-dir` unless the start command cooperates.
- `release` semantics need product validation. This plan treats release as releasing the managed lease/upstream child and never closing headed Chrome, consistent with the skill safety rules.
- Installer config growth may surprise users with four browser MCP servers. Consider whether managed servers should be added alongside compatibility entries first, then promoted later after validation.
- Real Chrome smoke tests can touch private headed sessions. Keep acceptance checks safe: list pages or navigate to a benign public/local page only, and do not inspect cookies/tokens/storage.

## Open Questions
- Should the managed servers eventually replace `browser-chrome-headed` and `browser-chrome-headless`, or remain opt-in under `browser-chrome-managed-*` names?
- Should policy tool names be unprefixed exactly as planned, or prefixed as `browser_chrome_*` to reduce future collision risk?
- Should `acquire_session` implement cross-process advisory locking for headed sessions, or is the current reusable shared-headed model sufficient for MVP?
- Should the managed server proxy only tools, or also proxy upstream resources/prompts if `chrome-devtools-mcp` adds them?

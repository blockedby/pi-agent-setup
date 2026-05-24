# Code Context

## Files Retrieved
1. `skills/browser-chrome/SKILL.md` (lines 1-113) - primary contract: headless vs headed rules, persistent headed launch requirements, MCP-first usage, safety.
2. `skills/browser-chrome/scripts/common.sh` (lines 8-98) - source of truth for headed port validation, profile/env helpers, endpoint checks.
3. `skills/browser-chrome/scripts/open-headed.sh` (lines 7-67) - reuse/start headed persistent Chrome; blocks duplicate profile launches when endpoint is closed.
4. `skills/browser-chrome/scripts/open-headless.sh` (lines 7-95) - disposable headless lifecycle, state file creation, cleanup on failure.
5. `skills/browser-chrome/scripts/mcp.sh` (lines 10-41) - MCP wrapper that starts Chrome and proxies to `chrome-devtools-mcp`.
6. `skills/browser-chrome/scripts/check-opened.sh` (lines 7-55) - reachability probe for headed/headless endpoints.
7. `skills/browser-chrome/scripts/close-headless.sh` (lines 7-66) - closes remote/local headless instances and removes profiles/state.
8. `skills/browser-chrome/scripts/install-local.sh` (lines 6-64) - installs skill files and writes MCP server entries.
9. `skills/browser-chrome/README.md` (lines 46-86) - human-facing mode semantics, env vars, portability rules.
10. `skills/browser-chrome/references/mcp-config.md` (lines 1-38) - canonical two-server MCP config.
11. `skills/browser-chrome/references/mode-selection.md` (lines 1-71) - policy and remote-host examples.
12. `skills/browser-chrome/mcp/browser-chrome.mcp.json` (lines 1-21) - checked-in MCP server example.
13. `docs/plans/2026-05-24-browser-chrome-persistent-headed/plan.md` (lines 1-24) - scoped goals for the persistent-headed protocol.
14. `docs/plans/2026-05-24-browser-chrome-persistent-headed/reports/hermes-vs-pi-browser-chrome.md` (lines 27-177) - comparison evidence, constraints, and open questions.

## Key Code
- `bc_validate_headed_port()` in `common.sh` enforces `9200-9300`; `bc_headed_port()` and `bc_headed_url()` both depend on it.
- `bc_headed_user_data_dir()` / `bc_headed_profile_directory()` provide the persistent headed profile defaults.
- `open-headed.sh` flow:
  - reuse if `bc_endpoint_ok "$url"`;
  - honor `BROWSER_CHROME_HEADED_START_COMMAND` via `bash -lc`;
  - fail if profile process exists but DevTools endpoint is closed;
  - launch Chrome with `--remote-debugging-address`, `--remote-debugging-port`, `--user-data-dir`, `--profile-directory`, `--no-first-run`, `--no-default-browser-check`, `--new-window`.
- `open-headless.sh` flow:
  - optional remote start command must print `id=` and `url=`;
  - local headless uses a fresh temp profile and unique port;
  - cleanup removes state/profile on failure.
- `mcp.sh` is the main proxy entrypoint:
  - headed: `open-headed.sh` then `chrome-devtools-mcp --browser-url=$url`;
  - headless: open, parse id/url, trap cleanup via `close-headless.sh`.
- `install-local.sh` writes `browser-chrome-headed` and `browser-chrome-headless` into `~/.pi/agent/mcp.json` using the installed script path, not a hardcoded wrapper binary.

## Architecture
The skill is layered:
1. **Policy/docs** (`SKILL.md`, `README.md`, `mode-selection.md`) say headless is disposable and headed is the only mode for persistent auth/session/profile state.
2. **Shared helpers** (`common.sh`) centralize ports, profile paths, reachability, and Chrome discovery.
3. **Lifecycle scripts** (`open-headed.sh`, `open-headless.sh`, `check-opened.sh`, `close-headless.sh`, `close-headed-tab.sh`) own browser/session management.
4. **MCP wrapper** (`mcp.sh`) is the user-facing bridge: it opens/reuses the right browser and proxies into `chrome-devtools-mcp`.
5. **Local install** (`install-local.sh`) materializes two MCP servers in `~/.pi/agent/mcp.json`.

This repo intentionally stays portable: config comes from env/start commands, not Hermes-specific paths or host topology.

## Start Here
Open `skills/browser-chrome/SKILL.md` first. It states the mode contract and the persistent-headed requirements that all scripts/docs must obey; from there, `scripts/common.sh` and `scripts/open-headed.sh` are the implementation anchors.
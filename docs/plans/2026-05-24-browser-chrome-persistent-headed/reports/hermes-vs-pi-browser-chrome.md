# Hermes vs Pi browser-chrome persistent headed report

## Task

Compare the current Pi `browser-chrome` skill with the Hermes Chrome Browser Agent skill on `everyday-white`, focusing on why another agent failed to use the user's persistent headed Chrome session without repeated explanation.

This report is investigation/planning evidence only. It does not apply code changes.

## Sources inspected

### Pi setup repo

- `skills/browser-chrome/SKILL.md`
- `skills/browser-chrome/README.md`
- `skills/browser-chrome/references/mode-selection.md`
- `skills/browser-chrome/references/mcp-config.md`
- `skills/browser-chrome/scripts/common.sh`
- `skills/browser-chrome/scripts/open-headed.sh`
- `skills/browser-chrome/scripts/mcp.sh`

### Hermes on `everyday-white`

- Host: `everyday-white.ptr.network`
- User: `robot`
- Skill path: `~/.hermes/skills/software-development/chrome-browser-agent/SKILL.md`

## Current Pi behavior / facts

### Built-in headed script already launches persistent Chrome

`skills/browser-chrome/scripts/open-headed.sh` already starts Chrome with persistent-profile flags:

```bash
--remote-debugging-address=$bind_address
--remote-debugging-port=$port
--user-data-dir=$profile_dir
--profile-directory=$profile_directory
--no-first-run
--no-default-browser-check
--new-window
```

The values come from `skills/browser-chrome/scripts/common.sh`:

```bash
BROWSER_CHROME_HEADED_PORT       # default 9233
BROWSER_CHROME_HEADED_USER_DATA_DIR
BROWSER_CHROME_HEADED_PROFILE_DIRECTORY # default Default
```

So the core local script is not the main problem. The missing piece is agent-facing guidance/contract clarity.

### Pi MCP wrapper uses the headed script

`skills/browser-chrome/scripts/mcp.sh` in headed mode does:

```bash
scripts/open-headed.sh
url="$(bc_headed_url)"
chrome-devtools-mcp --browser-url="$url"
```

So if the MCP server `browser-chrome-headed` is used, it should reuse/open the configured headed browser endpoint using the script. Agents should not need to memorize a raw Chrome command in normal Pi usage.

### Current Pi docs are portable by design

Pi's `browser-chrome` skill is intended to be reusable across machines. It should not hardcode machine-specific paths such as a Hermes profile directory. Configuration should remain through env/settings/scripts.

## Hermes skill behavior / facts

Hermes skill is more operationally explicit for its environment.

It states:

- Hermes runs on VPS `everyday-white`.
- Chrome runs on KCNC-PC.
- CDP is exposed to the VPS through a reverse SSH tunnel.
- CDP port pool is `127.0.0.1:9200-9300`.
- Default CDP endpoint is `http://127.0.0.1:9222`.
- KCNC-PC helpers exist:

```bash
/home/kcnc/.local/bin/hermes-vps-chrome-open 9222 headless
/home/kcnc/.local/bin/hermes-vps-chrome-open 9222 headed
/home/kcnc/.local/bin/hermes-vps-chrome-close 9222
```

Most importantly, it distinguishes persistent headed Chrome from disposable headed/helper Chrome:

```text
Do not use /home/kcnc/.local/bin/hermes-vps-chrome-open <port> headed when saved auth/profile state is required: that helper creates a disposable profile at ~/.hermes/chrome-debug-vps/profile-<port>.
```

It also shows a raw persistent Chrome launch command for KCNC-PC. That command is useful as environment-specific documentation, but it is not the right abstraction for Pi's reusable skill when Pi already has scripts/MCP wrappers.

## Key difference

The useful distinction to copy is conceptual, not the hardcoded command:

```text
headed persistent profile != any headed/debug browser
```

For tasks needing saved auth/profile state, the agent must use the configured persistent headed profile and must not use a disposable temporary profile, even if that disposable browser is headed or reachable through CDP.

## What we should adopt in Pi

### Adopt

1. Explicit headed persistent contract:
   - headed mode for auth/profile state must use stable persistent `user-data-dir` and `profile-directory`;
   - disposable/temporary profile is not acceptable when saved auth/session/profile state matters;
   - custom headed start commands must preserve the same contract.

2. Port pool rule:
   - headed DevTools ports should be in `9200-9300`;
   - this should be stated in the skill and ideally enforced in scripts.

3. Strong mode warning:
   - if auth/session/profile data is required, do not fall back to headless or disposable headed/debug helpers;
   - if the configured persistent profile is locked/running but endpoint is unreachable, stop and report instead of opening another browser with a different profile.

4. MCP/script-first usage:
   - normal Pi agents should use `browser-chrome-headed` MCP or `scripts/open-headed.sh`, not memorize raw Chrome launch commands;
   - raw command shape is only a diagnostic/reference explanation of what the script/start command must do.

### Do not adopt directly

1. Do not hardcode Hermes-specific paths such as:

```text
/home/kcnc/.cache/hermes-google-chrome-mcp
```

2. Do not require agents to use raw `curl /json/new` CDP calls as the normal path if MCP tools expose the needed browser actions. Direct CDP HTTP may be documented as fallback/diagnostics only.

3. Do not make Pi's portable skill assume the `everyday-white` ↔ KCNC-PC topology. Put environment-specific values in env/config/start commands.

## Open design questions

1. Should `browser-chrome` scripts enforce the headed port range `9200-9300`, or should this remain documentation-only?
   - Pro enforcement: catches wrong endpoints early.
   - Con enforcement: may break users with existing non-9200 ports.
   - Current user preference: port should be `9200-9300`.

2. Should `open-headed.sh` fail if `BROWSER_CHROME_HEADED_USER_DATA_DIR` appears temporary?
   - Possible heuristic: reject `/tmp/*` for headed unless explicitly overridden.
   - Risk: false positives for valid custom environments.

3. Should `browser-chrome-headed` expose or document a direct tool equivalent for "open URL in existing session"?
   - If Chrome DevTools MCP already provides page creation/navigation, prefer MCP.
   - If not reliable, document direct CDP HTTP as fallback, but not as primary workflow.

4. Should local setup define default env for headed persistent profile?
   - Example generic default already exists: `$BROWSER_CHROME_HOME/headed-profile`.
   - User-specific profile paths should remain local config, not repo defaults.

## Recommended next changes

1. Update `skills/browser-chrome/SKILL.md` and references to say:
   - headed persistent mode requires stable profile state;
   - disposable headed/debug profile is not acceptable for saved auth/profile tasks;
   - use MCP/server/scripts first;
   - custom start commands must launch Chrome with persistent profile flags.

2. Keep raw command examples generic, not Hermes-specific, or avoid raw command examples entirely if they confuse agents into bypassing scripts.

3. Add a script-level validation for headed CDP port `9200-9300` if we accept the compatibility tradeoff.

4. Add a short troubleshooting note:
   - If user says "use my logged-in Chrome", verify `browser-chrome-headed` endpoint.
   - If unavailable, run/open configured headed script.
   - If it opens a fresh loginless profile, the headed profile config is wrong; report the configured `BROWSER_CHROME_HEADED_USER_DATA_DIR`/`PROFILE_DIRECTORY` without printing private profile contents.

## Current local note

At the time of this report, local uncommitted edits exist in `skills/browser-chrome` from an initial attempt to add the headed contract and port validation. Review those edits against this report before committing or reverting.

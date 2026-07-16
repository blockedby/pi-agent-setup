# Pi Agent Setup

Public, non-secret bootstrap for my Pi/Codex agent stack and AAD (Agentic Application Development) workflow. This repository is not a universal product or turnkey installer; it is a practical, inspectable example of how I keep coding-agent infrastructure bounded, repeatable, and verification-oriented across local and remote machines.

It is meant to show the "how I work" layer: owner/implementer/auditor routing, reusable skills, browser tooling, setup scripts, secrets boundaries, and smoke checks. Hostnames, paths, credentials, sessions, and machine inventory are intentionally omitted or parameterized.

## What this installs

- Pi CLI via ordinary npm into `$HOME/.local`: the current `@earendil-works/pi-coding-agent` release
- OpenAI Codex CLI via Vite+: the current `@openai/codex` release
- User settings at `$REMOTE_USER_HOME/.pi/agent/settings.json` on a target host
- Global terminal append prompt at `$REMOTE_USER_HOME/.pi/agent/APPEND_SYSTEM.md`
- Custom executable subagents at `$REMOTE_USER_HOME/.pi/agent/agents/`:
  - `aad-root-owner`
  - `aad-slice-owner`
  - `aad-implementer`
  - `aad-failure-classifier`
  - `chrome-browser-agent`
  - `aad-explorer`
  - `aad-acceptance-auditor`
  - `visual-critic`
- Shared AAD skills at `$REMOTE_USER_HOME/.pi/agent/skills/aad-*`
- Browser Chrome skill at `$REMOTE_USER_HOME/.pi/agent/skills/browser-chrome` via git submodule
- Browser Chrome MCP entries in `$REMOTE_USER_HOME/.pi/agent/mcp.json` pointing directly at skill scripts:
  - `browser-chrome-headed`
  - `browser-chrome-headless`
- 21st.dev Magic MCP skill and lazy MCP entry:
  - skill: `$REMOTE_USER_HOME/.pi/agent/skills/21st-magic-mcp`
  - MCP server: `21st-magic` using `npx -y @21st-dev/magic@latest`
- Ready-notify extension at `$REMOTE_USER_HOME/.pi/agent/extensions/ready-notify.ts`
- Pi-subagents config at `$REMOTE_USER_HOME/.pi/agent/extensions/subagent/config.json` with scheduled runs enabled and a 3-minute `needs_attention` threshold
- Pi packages/extensions from `settings/pi-settings.example.json` or a local settings file selected with `PI_SETTINGS_FILE`

## Public-safety boundary

This repository should remain useful without exposing private infrastructure. Do not commit secrets, raw logs, credentials, tokens, cookies, chat IDs, private URLs, browser profiles, or machine inventory. Put local overrides in ignored files such as `.env`, `.env.local`, `settings/*.local.json`, or shell profile exports.

See [`docs/secrets.md`](docs/secrets.md) and [`docs/public-readiness.md`](docs/public-readiness.md) for the exact boundary and customization model.

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

For remote installs, `scripts/install-remote.sh` deploys the extension into `$REMOTE_USER_HOME/.pi/agent/extensions/`; set any `PI_READY_NOTIFY_*` variables in the remote Pi launch environment. No host-specific notification settings or secrets are stored in this repo.

## AAD routing model

The installed global append prompt (`APPEND_SYSTEM.md`) tells the terminal main assistant to keep direct handling only for trivial one-step edits, questions, or checks. Clear small/single-slice AAD implementation work routes directly to `aad-slice-owner`. Multi-step, unclear, multi-slice, cross-cutting, or integration-heavy AAD work routes to `aad-root-owner`, which slices the work, delegates to slice owners, integrates results, and reports the final done-state.

Skills are runbooks/support material and do not replace the owner/subagent hierarchy. `aad-implementer` and support agents are internal execution/evidence targets delegated by owners, not top-level default terminal routes.

This personal setup uses the GPT-5.6 model family in three tiers. The allocation follows each agent's expected workload; it is a local workflow choice rather than a universal recommendation.

| Agent | Goal | Model |
| --- | --- | --- |
| `aad-root-owner` | Own multi-step or multi-slice work, coordinate slices, and integrate the final result. | `openai-codex/gpt-5.6-sol` |
| `aad-implementer` | Execute scoped implementation tasks with verification and coherent handoff evidence. | `openai-codex/gpt-5.6-sol` |
| `aad-slice-owner` | Own one scoped slice, delegate execution, and decide its local done-state. | `openai-codex/gpt-5.6-terra` |
| `aad-acceptance-auditor` | Independently decide whether acceptance criteria and evidence are sufficient. | `openai-codex/gpt-5.6-terra` |
| `chrome-browser-agent` | Collect browser automation and visual evidence using the appropriate Chrome mode. | `openai-codex/gpt-5.6-terra` |
| `visual-critic` | Review screenshots for composition, hierarchy, responsiveness, and obvious visual failures. | `openai-codex/gpt-5.6-terra` |
| `aad-explorer` | Perform read-only discovery, reuse analysis, and evidence gathering. | `openai-codex/gpt-5.6-luna` |
| `aad-failure-classifier` | Classify concrete failures and recommend the narrow next action without editing source. | `openai-codex/gpt-5.6-luna` |

Files ending in `.md.temp` are disabled templates and are not part of the installed active-agent set.

### Parallel delegation

Slicing and scheduling are separate decisions. Slices are defined by scope, ownership, size, and acceptance boundaries; they are not execution waves and are not automatically parallel. Planning gives every delegated task explicit `Depends on`, `Blocks`, and `Can run in parallel with` relationships so the task carries its prior-work, future-work, and concurrency context without fixing a permanent execution order.

Before each delegation, an owner identifies tasks whose dependencies are complete. If two or more ready tasks explicitly list each other as safe to run in parallel, the owner confirms that their planned contracts and boundaries are still settled and sends them together in one `subagent` call using `tasks: [...]`; otherwise the owner uses a single call or waits for the dependency. Parallel execution and background execution are separate: `tasks: [...]` controls concurrency, while `async: true` lets the complete run continue without blocking the owner.

One root request has one `aad-root-owner`. The root owner may dispatch independent slice owners together when safe, and slice owners apply the same rule to implementer or support tasks inside their scope. The checked-in harness configuration allows at most six tasks in a parallel call and runs at most three concurrently. This conservative per-run limit reduces nested fan-out; the harness does not currently enforce a process-wide concurrency limit across several simultaneous owners.

## Agent pipeline diagrams

See [`docs/agent-pipelines.html`](docs/agent-pipelines.html) for Mermaid diagrams of the checked-in subagents, owner routing, and related worker loops.

## Visual/UI lane

For future public page visual work, landing pages, templates, hero sections, marketing blocks, or other product-quality UI surfaces, the slice owner should record a concise design/composition decision, route implementation with screenshot-first acceptance criteria, collect browser screenshots for the relevant viewports, identify the worst screenshot, and use `visual-critic` evidence before the acceptance auditor decides final status. DOM metrics, bounding boxes, and intersection checks remain supporting evidence only.

## Update local Pi setup

Use the local update script after changing checked-in agents or the vendored `pi-codex` submodule:

```bash
scripts/update-local.sh
```

The local updater prefers Vite+'s npm runtime, detects the active Pi executable, and reinstalls Pi with ordinary npm under `$HOME/.local` when Pi is missing or resolves to Vite+. This keeps extension loading outside Vite+'s hashed package paths. It also installs one managed Bash PATH file under `$HOME/.config/pi-agent-setup/` and adds a delimited source block to the active Bash login startup file and `.bashrc`, so fresh Bash login and interactive shells resolve `$HOME/.local/bin/pi` before Vite+. Repeated runs update only the managed file and do not duplicate the source blocks or replace unrelated shell content.

The updater applies `defaultProvider`, `defaultModel`, and `defaultThinkingLevel` from `settings/pi-settings.example.json` while preserving other installed settings and packages; existing settings are backed up first. To keep machine-specific defaults, pass an ignored local settings file explicitly:

```bash
PI_SETTINGS_FILE=settings/pi-settings.local.json scripts/update-local.sh
```

It installs `APPEND_SYSTEM.md` into `$HOME/.pi/agent/APPEND_SYSTEM.md`, installs `agents/*.md` into `$HOME/.pi/agent/agents/`, installs `extensions/*.ts` into `$HOME/.pi/agent/extensions/`, syncs checked-in skills into `$HOME/.pi/agent/skills/`, installs `settings/pi-subagents.config.json` into `$HOME/.pi/agent/extensions/subagent/config.json`, merges the checked-in `21st-magic` MCP entry into `$HOME/.pi/agent/mcp.json`, reinstalls the vendored `packages/pi-codex` runtime dependencies with `npm ci`, verifies the ready-notify extension is declared, removes stale renamed agents, rewrites the local Pi package entry for `pi-codex` to `packages/pi-codex` while preserving other installed packages, backs up `$HOME/.pi/agent/settings.json`, and verifies that installed AAD agents do not expose `codex_task`.

## Install on a remote host

Prerequisite: Vite+ already installed for the remote install user. The installer uses its Node/npm runtime, installs Pi with ordinary npm under `$REMOTE_USER_HOME/.local`, and continues to install Codex through Vite+. Keeping Pi outside Vite+'s hashed package directories avoids extension-loader resolution failures when an installation path contains `#`. The same managed Bash setup makes `.local/bin` precede `.vite-plus/bin` in fresh Bash login and interactive shells without replacing existing startup files. Set the target and optional paths explicitly for your environment:

```bash
TARGET_HOST=<host> \
REMOTE_USER_HOME=/home/<user> \
PI_SETTINGS_FILE=settings/pi-settings.example.json \
scripts/install-remote.sh
```

The installer uses each package's npm `latest` tag by default. Check the numeric versions currently behind those tags with:

```bash
npm view @earendil-works/pi-coding-agent version
npm view @openai/codex version
```

For a reproducible install, resolve those versions first and pass explicit `PI_VERSION` and `CODEX_VERSION` values. The environment variables accept either a numeric version or another npm dist-tag:

```bash
PI_VERSION=<version> \
CODEX_VERSION=<version> \
TARGET_HOST=<host> \
scripts/install-remote.sh
```

`REMOTE_USER_HOME` is optional. If it is omitted, the scripts use the remote shell's `$HOME`; they only fall back to `/root` when no usable home is available. `PI_SETTINGS_FILE` may point to an ignored local settings file such as `settings/pi-settings.local.json`.

## Codex login

After install, log in interactively on the target host when needed:

```bash
ssh <host>
$HOME/.vite-plus/bin/codex login
```

Do not commit Codex auth/session files to this repo.

## Optional Pi auth import

Only after explicit approval. Uses the same remote home resolution as install/verify unless `REMOTE_AUTH` is set explicitly:

```bash
CONFIRM_COPY_PI_AUTH=1 \
TARGET_HOST=<host> \
REMOTE_USER_HOME=/home/<user> \
LOCAL_AUTH=$HOME/.pi/agent/auth.json \
scripts/import-auth-remote.sh
```

## Verify a remote install

```bash
TARGET_HOST=<host> REMOTE_USER_HOME=/home/<user> scripts/verify-remote.sh
```

The verifier checks the installed `APPEND_SYSTEM.md`, the `aad-root-owner` and `aad-slice-owner` agents, required skills, stale-agent cleanup, Pi packages, and a smoke prompt.

## Notes

`pi-subagents` discovers user agents from:

```text
$HOME/.pi/agent/agents/*.md
$HOME/.agents/*.md
```

The older local stash at `$HOME/.pi/agents` is not used by current `pi-subagents` discovery, so this repo stores normalized agent definitions with YAML frontmatter and deploys them to `$HOME/.pi/agent/agents` on the install user.

Pi loads global skills from `$HOME/.pi/agent/skills/`. This repo also declares `pi.skills` in `package.json`, so the `skills/` directory can be reused later as a git/npm Pi package, while the remote bootstrap still installs the skills directly for deterministic availability.

## Browser Chrome

`skills/browser-chrome` is a submodule pointing at `github.com/blockedby/browser-chrome-skill`. Clone/update with submodules before installing:

```bash
git submodule update --init --recursive
```

The `browser-chrome` skill chooses between:

- `browser-chrome-headless` — disposable headless Chrome for public/simple/parallel checks.
- `browser-chrome-headed` — headed persistent Chrome only for auth/session/profile tasks.

The install script merges the Browser Chrome MCP servers into `$HOME/.pi/agent/mcp.json` using absolute paths to the installed skill scripts. It also merges `skills/21st-magic-mcp/mcp/21st-magic.mcp.json` for the lazy `21st-magic` server. It does not add wrapper commands to `$HOME/.local/bin`. The headed profile, Chrome cookies, saved sessions, browser cache, and 21st.dev API keys are not stored in this repository.

For remote setups, headed and headless Chrome can both run on another host behind a LAN/VPN/SSH tunnel. Configure the skill with environment variables such as `BROWSER_CHROME_HEADED_URL`, `BROWSER_CHROME_HEADED_START_COMMAND`, `BROWSER_CHROME_HEADLESS_START_COMMAND`, and `BROWSER_CHROME_HEADLESS_CLOSE_COMMAND`.

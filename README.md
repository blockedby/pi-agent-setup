# Pi Agent Setup

This repository contains the local setup I use for a Pi/Codex coding workflow, plus an experimental OpenCode compatibility adapter. It keeps agent prompts, reusable skills, browser tooling, configuration, and verification in one inspectable place.

It is personal workflow infrastructure—not a universal installer, hosted service, or fully autonomous development system.

## What is included

- `APPEND_SYSTEM.md` — terminal routing rules loaded by Pi.
- `agents/` — executable AAD and browser agent sources.
- `skills/` — checked-in runbooks and the Browser Chrome submodule.
- `.opencode/plugins/pi-agent-setup.js` — OpenCode adapter for the shared agents and skills.
- `extensions/ready-notify.ts` — optional completion notifications.
- `settings/` — public example Pi and `pi-subagents` configuration.
- `packages/pi-codex` — local Pi package submodule.
- `scripts/update-local.sh` — the Pi setup entrypoint.
- `docs/agent-pipelines.html` — a visual overview of the routing model.

## Routing model

The terminal assistant handles only trivial one-step work directly. AAD-owned changes use an owner hierarchy:

1. `aad-root-owner` owns unclear, multi-step, multi-slice, or integration-heavy work.
2. `aad-slice-owner` owns one clear slice.
3. Owners delegate implementation and supporting evidence while retaining acceptance responsibility.
4. `aad-step-completion` requires fresh evidence before a done-state claim.

Independent slices may run in parallel only after their dependencies and write boundaries are explicit.

### Agents

| Agent | Role |
| --- | --- |
| `aad-root-owner` | Slices non-trivial root work, integrates results, and decides root completion. |
| `aad-slice-owner` | Owns a scoped slice from plan through verification. |
| `aad-implementer` | Implements a bounded task in its delegated worktree and reports evidence. |
| `aad-explorer` | Performs read-only codebase discovery and evidence gathering. |
| `aad-auditor` | Reviews acceptance evidence and decides whether work is supportably done. |
| `chrome-browser-agent` | Runs browser checks using the Browser Chrome safety policy. |

### Skills

The checked-in skills cover planning, slicing and delegation, reporting, evidence-based completion, target-branch handling, workflow feedback, task packages, and focused frontend/backend/DevOps/visual quality checks. Skills are support material; they do not replace owner responsibility.

Folder names are deployment identities. A skill's runtime name comes from its `SKILL.md` frontmatter, so those names may intentionally differ. The OpenCode adapter materializes a normalized cache view where folder names match runtime names.

## Requirements

- Bash
- Git
- Python 3
- `rsync`
- Node.js and npm
- repository submodules

Vite+ may provide npm, but Pi itself is installed under `$HOME/.local`. This avoids extension-loading problems caused by Vite+'s hashed package paths.

## Local Pi setup

Clone with submodules, then run:

```bash
git clone --recurse-submodules <repo-url>
cd pi-agent-setup
scripts/update-local.sh
```

After an update, restart Pi or run `/reload`.

The installer:

1. validates current agent and skill frontmatter;
2. initializes missing `pi-codex` and Browser Chrome submodules;
3. installs Pi under `$HOME/.local` when needed;
4. runs `npm ci --omit=dev` for the local `pi-codex` package;
5. installs the current prompt, agents, skills, extension, and `pi-subagents` config;
6. removes stale files only from repository-owned AAD namespaces while preserving unrelated user agents and skills;
7. updates Pi settings while preserving existing packages and ensuring packages from the selected settings file are present;
8. configures `browser-chrome-control`, `browser-chrome-headed`, and `browser-chrome-headless` in `mcp.json`.

### Local overrides

The installer accepts environment variables rather than maintaining multiple command variants:

| Variable | Purpose | Default |
| --- | --- | --- |
| `LOCAL_USER_HOME` | Home used for local installation. | `$HOME` |
| `PI_AGENT_DIR` | Pi agent configuration directory. | `$LOCAL_USER_HOME/.pi/agent` |
| `PI_SETTINGS_FILE` | Public or ignored local settings JSON; absolute or repository-relative. | `settings/pi-settings.example.json` |
| `PI_VERSION` | Pi package version to install when Pi is missing. | `latest` |
| `NPM_BIN` | Explicit npm executable override. | resolved automatically |

Use an ignored local settings file for machine-specific preferences:

```bash
cp settings/pi-settings.example.json settings/pi-settings.local.json
PI_SETTINGS_FILE=settings/pi-settings.local.json scripts/update-local.sh
```

## OpenCode compatibility

The compatibility adapter targets OpenCode 1.18.2 or newer. Add the git-backed plugin to a global or project-level `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "pi-agent-setup@git+https://github.com/blockedby/pi-agent-setup.git"
  ],
  "subagent_depth": 4
}
```

Restart OpenCode after changing the config.

The plugin reads the same files under `agents/` and `skills/`, registers OpenCode subagents with explicit delegation permissions, normalizes skill directory names in a content-addressed cache, and injects an OpenCode tool-mapping bootstrap. It does not copy Pi-specific model IDs; generated subagents inherit the invoking OpenCode model unless the user overrides an agent in `opencode.json`.

Browser Chrome remains an explicit boundary: the browser agent is registered only when the Browser Chrome skill submodule is present, and OpenCode MCP configuration is still required separately.

See [`docs/opencode.md`](docs/opencode.md) for the mapping, permission model, limitations, and troubleshooting notes.

## Browser tooling

`skills/browser-chrome` is a submodule. The Pi installer copies it into Pi's skill directory and configures three lazy MCP servers:

- `browser-chrome-control` — selects and coordinates the browser mode;
- `browser-chrome-headless` — disposable browser state for public and parallel checks;
- `browser-chrome-headed` — persistent profile use only when authentication or saved state is required.

Browser profiles, cookies, saved sessions, passwords, and API keys are not stored in this repository.

## Ready notifications

`extensions/ready-notify.ts` can notify when an interactive Pi run becomes idle. Configure it in the environment that launches Pi:

```bash
export PI_READY_NOTIFY=1
export PI_READY_NOTIFY_BACKEND=auto
export PI_READY_NOTIFY_MIN_SECONDS=10
```

Set `PI_READY_NOTIFY=0` to disable notification side effects. Notification delivery is best effort and does not affect task results.

## Verification

Run the local test suite:

```bash
npm test
npm run secrets:check
git diff --check
```

After changing Pi setup behavior, run the actual installer and a Pi smoke test:

```bash
scripts/update-local.sh
PI_BIN="$(command -v pi)"
timeout 120 "$PI_BIN" --no-session --mode text -p 'Say OK and exit.'
```

A clean smoke test ends with `OK` and no skill or extension loading errors.

For the OpenCode adapter, `npm run test:opencode` verifies agent translation, permission boundaries, bootstrap idempotence, and normalized skill discovery without requiring an OpenCode installation.

## Public-safety boundary

Never commit credentials, tokens, cookies, auth files, browser profiles, private URLs, machine inventory, raw agent logs, or session data. Use placeholders such as `$HOME`, `<repo>`, and environment variables in public documentation.

Keep machine-specific values in ignored files such as:

- `settings/*.local.json`;
- shell profile exports.

## Additional documentation

- [Agent pipeline overview](docs/agent-pipelines.html)
- [OpenCode compatibility](docs/opencode.md)

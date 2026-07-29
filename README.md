# Pi Agent Setup

This repository contains the local setup I use for a Pi/Codex coding workflow, plus an experimental OpenCode compatibility adapter. It keeps agent prompts, reusable skills, browser tooling, configuration, and verification in one inspectable place.

It is personal workflow infrastructure—not a universal installer, hosted service, or fully autonomous development system.

## What is included

- `APPEND_SYSTEM.md` — terminal routing rules loaded by Pi.
- `agents/` — executable AAD and browser agent sources.
- `skills/general/` — reusable engineering, verification, browser, Git workflow, explanation, and skill-maintenance capabilities.
- `skills/aad/` — AAD-specific planning, delegation, reporting, and task-package contracts.
- `.opencode/plugins/pi-agent-setup.js` — OpenCode adapter for the composed AAD setup.
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
4. `completion-verification` requires fresh evidence before a done-state claim.

Independent slices may run in parallel only after their dependencies and write boundaries are explicit.

### Agents

| Agent | Role |
| --- | --- |
| `aad-root-owner` | Orchestrates and completes root work. |
| `aad-slice-owner` | Owns one scoped slice end to end. |
| `aad-implementer` | Implements bounded delegated changes. |
| `aad-explorer` | Performs read-only discovery. |
| `aad-auditor` | Audits evidence and acceptance. |
| `chrome-browser-agent` | Runs safe Chrome automation. |

### Skill sets

General skills form a reusable foundation:

| Skill | Purpose |
| --- | --- |
| `backend-quality` | Checks backend, API, and data quality. |
| `browser-chrome` | Routes safe Chrome automation. |
| `completion-verification` | Requires fresh evidence before completion claims. |
| `devops-quality` | Checks deployment and runtime readiness. |
| `explanatory-html-pages` | Builds clear visual explainers. |
| `frontend-quality` | Checks frontend implementation quality. |
| `git-branching` | Prepares, merges, and synchronizes branches and worktrees safely. |
| `modern-skill-revising` | Rightsizes SOTA-model context. |
| `visual-composition` | Shapes polished visual composition. |

AAD skills provide the workflow overlay:

| Skill | Purpose |
| --- | --- |
| `aad-delegation` | Routes delegated agents safely. |
| `aad-plan-writing` | Builds and tracks AAD plans. |
| `aad-reporting` | Produces AAD continuation and final reports. |
| `aad-task-package` | Manages AAD task-package artifacts. |
| `aad-workflow-feedback` | Records reusable AAD workflow feedback. |

The supported AAD setup composes both sets. A general-only setup loads `skills/general/` without AAD agents, routing prompt, task-package convention, or subagent configuration. Skills remain support material; they do not replace agent ownership.

Checked-in leaf folder names match their `SKILL.md` runtime names. The category directories are source boundaries only and do not become part of installed or invoked skill names.

### Runtime-name migration

The reusable quality and completion skills previously carried AAD-prefixed runtime names. Existing external prompts or configuration should use this mapping:

| Previous name | Current name |
| --- | --- |
| `aad-quality-backend` | `backend-quality` |
| `aad-quality-frontend` | `frontend-quality` |
| `aad-quality-devops` | `devops-quality` |
| `aad-quality-composition` | `visual-composition` |
| `aad-step-completion` | `completion-verification` |
| `aad-git-branching` | `git-branching` |

The Git workflow source also moves from `skills/aad/aad-git-branching/` to `skills/general/git-branching/`. The installer removes repository-owned legacy destinations during migration. Compatibility alias skills are intentionally not installed because duplicate descriptions would create ambiguous discovery and two maintained identities.

## Requirements

- Bash
- Git
- Python 3
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
5. installs the current prompt, agents, both skill sets, extensions, and `pi-subagents` config;
6. replaces/prunes exact repository-owned skill identities and managed agent namespaces while preserving unrelated user agents and skills;
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

### Reusing one skill set

Use the skill-only installer when another local agent setup should receive skills without this repository's agents, routing prompt, extensions, settings, packages, or MCP configuration:

```bash
PI_AGENT_DIR="$HOME/.pi/agent" scripts/install-skills.sh --set general
PI_AGENT_DIR="$HOME/.pi/agent" scripts/install-skills.sh --set aad
PI_AGENT_DIR="$HOME/.pi/agent" scripts/install-skills.sh --set all
```

`general` and `aad` select source sets; `all` composes them. Installing one set does not remove the other set or unrelated user skills. A first skill-only install refuses to overwrite an existing same-name destination that is not recorded in this repository's ownership manifest. The full updater separately adopts only the unchanged identities it owned before the manifest migration. The general set includes the Browser Chrome skill, but this skill-only command does not configure Chrome MCP servers.

Agent setups that reference this checkout directly can instead add one root to Pi settings:

```json
{
  "skills": ["<repo>/skills/general"]
}
```

Use `<repo>/skills/aad` for the overlay root. The checked-in AAD agents require the composed `all` set because they use general capabilities, including Git branching, as well as the AAD overlay.

Pi package filters can narrow the root package to `skills/general/**`, but a normal git-package checkout does not initialize the Browser Chrome submodule. It therefore yields eight tracked skills rather than the complete nine-skill general set. Use a recursive local clone plus the direct root or skill-only installer when Browser Chrome is required.

This repository does not publish the sets as independently versioned packages; direct roots are composition boundaries over the same repository revision.

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

The plugin reads the same files under `agents/`, `skills/general/`, and `skills/aad/`, registers OpenCode subagents with explicit delegation permissions, materializes both skill sets into one flat content-addressed cache, and injects an OpenCode tool-mapping bootstrap. It does not copy Pi-specific model IDs; generated subagents inherit the invoking OpenCode model unless the user overrides an agent in `opencode.json`.

Browser Chrome remains an explicit boundary: the browser agent is registered only when the Browser Chrome skill submodule is present, and OpenCode MCP configuration is still required separately.

See [`docs/opencode.md`](docs/opencode.md) for the mapping, permission model, limitations, and troubleshooting notes.

## Browser tooling

`skills/general/browser-chrome` is a submodule. The full Pi installer copies it into Pi's flat skill directory and configures three lazy MCP servers:

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

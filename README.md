# Pi Agent Setup

Private non-secret bootstrap for running the same Pi agent stack on `nl-2-nvme`.

## What this installs

- Pi CLI via Vite+: `@earendil-works/pi-coding-agent@0.74.0`
- OpenAI Codex CLI via Vite+: `@openai/codex@0.130.0`
- User settings at `/root/.pi/agent/settings.json`
- Custom executable subagents and chains at `/root/.pi/agent/agents/`:
  - `implementer`
  - `quinn-validator`
  - `aad-failure-classifier`
  - `chrome-browser-agent`
  - `aad-explorer`
  - `aad-slice-owner`
  - `aad-acceptance-auditor`
  - AAD chains: `aad-discovery-plan`, `aad-owned-change`, `aad-problem-investigation`
- Shared AAD skills at `/root/.pi/agent/skills/aad-*`
- Browser Chrome skill at `/root/.pi/agent/skills/browser-chrome` via git submodule
- Browser Chrome MCP entries in `/root/.pi/agent/mcp.json` pointing directly at skill scripts:
  - `browser-chrome-headed`
  - `browser-chrome-headless`
- Pi packages/extensions from `settings/pi-settings.vps.json`

## Agent pipeline diagrams

See [`docs/agent-pipelines.html`](docs/agent-pipelines.html) for Mermaid diagrams of the checked-in subagents, AAD chains, and related worker loops.

## What is intentionally not stored here

See `docs/secrets.md`. In short: no `auth.json`, no API keys/tokens, no sessions,
no SSH private keys, no runtime state.

## Install on NL-2-NVMe

Prerequisite: Vite+ already installed for root on the VPS.

Optional version overrides:

```bash
PI_VERSION=0.74.0 CODEX_VERSION=0.130.0 TARGET_HOST=nl-2-nvme scripts/install-vps.sh
```

```bash
TARGET_HOST=nl-2-nvme scripts/install-vps.sh
```

## Codex login

After install, log in interactively on the VPS when needed:

```bash
ssh nl-2-nvme
/root/.vite-plus/bin/codex login
```

Do not commit Codex auth/session files to this repo.

## Optional Pi auth import

Only after explicit approval:

```bash
CONFIRM_COPY_PI_AUTH=1 TARGET_HOST=nl-2-nvme scripts/import-auth-vps.sh
```

## Verify

```bash
TARGET_HOST=nl-2-nvme scripts/verify-vps.sh
```

## Notes

`pi-subagents` discovers user agents from:

```text
~/.pi/agent/agents/*.md
~/.agents/*.md
```

The older local stash at `~/.pi/agents` is not used by current `pi-subagents`
discovery, so this repo stores normalized agent definitions with YAML
frontmatter and deploys them to `/root/.pi/agent/agents`.

Pi loads global skills from `~/.pi/agent/skills/`. This repo also declares
`pi.skills` in `package.json`, so the `skills/` directory can be reused later as
a git/npm Pi package, while the VPS bootstrap still installs the skills directly
for deterministic availability.

## Browser Chrome

`skills/browser-chrome` is a submodule pointing at
`github.com/blockedby/browser-chrome-skill`. Clone/update with submodules before
installing:

```bash
git submodule update --init --recursive
```

The `browser-chrome` skill chooses between:

- `browser-chrome-headless` — disposable headless Chrome for public/simple/parallel checks.
- `browser-chrome-headed` — headed persistent Chrome only for auth/session/profile tasks.

The install script merges the two MCP servers into `~/.pi/agent/mcp.json` using
absolute paths to the installed skill scripts. It does not add wrapper commands
to `~/.local/bin`. The headed profile, Chrome cookies, saved sessions, and
browser cache are not stored in this repository.

For remote/VPS setups, headed and headless Chrome can both run on another host
behind LAN/Tailscale/SSH tunnel. Configure the skill with environment variables
such as `BROWSER_CHROME_HEADED_URL`, `BROWSER_CHROME_HEADED_START_COMMAND`,
`BROWSER_CHROME_HEADLESS_START_COMMAND`, and `BROWSER_CHROME_HEADLESS_CLOSE_COMMAND`.

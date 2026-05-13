# Pi Agent Setup

Private non-secret bootstrap for running the same Pi agent stack on `nl-2-nvme`.

## What this installs

- Pi CLI via Vite+: `@earendil-works/pi-coding-agent@0.74.0`
- OpenAI Codex CLI via Vite+: `@openai/codex@0.130.0`
- User settings at `/root/.pi/agent/settings.json`
- Custom executable subagents and chains at `/root/.pi/agent/agents/`:
  - `tdd-coder`
  - `quinn-validator`
  - `failure-classifier`
  - `aad-explorer`
  - `aad-reviewer`
  - `aad-slice-owner`
  - `aad-test-auditor`
  - AAD chains: `aad-discovery-plan`, `aad-owned-change`, `aad-parallel-investigation`
- Shared AAD skills at `/root/.pi/agent/skills/aad-*`
- Pi packages/extensions from `settings/pi-settings.vps.json`

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

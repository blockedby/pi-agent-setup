# Pi Agent Setup

Private non-secret bootstrap for running the same Pi agent stack on `nl-2-nvme`.

## What this installs

- Pi CLI via Vite+ npm: `@earendil-works/pi-coding-agent@0.74.0`
- User settings at `/root/.pi/agent/settings.json`
- Custom executable subagents at `/root/.pi/agent/agents/`:
  - `tdd-coder`
  - `quinn-validator`
  - `failure-classifier`
- Pi packages/extensions from `settings/pi-settings.vps.json`

## What is intentionally not stored here

See `docs/secrets.md`. In short: no `auth.json`, no API keys/tokens, no sessions,
no SSH private keys, no runtime state.

## Install on NL-2-NVMe

Prerequisite: Vite+ already installed for root on the VPS.

```bash
TARGET_HOST=nl-2-nvme scripts/install-vps.sh
```

## Optional auth import

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

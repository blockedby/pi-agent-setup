# Public-readiness notes

This repository is public-facing workflow infrastructure, not a secret-bearing operations repo.

## What is intentionally included

- AAD owner/implementer/auditor agent definitions and routing prompts.
- Reusable skills and submodule pointers for browser/Codex tooling.
- Example Pi settings in `settings/pi-settings.example.json`.
- Setup, verification, and auth-copy scripts that are parameterized by environment variables.
- Documentation of the verification and safety habits used around the stack.

## What is intentionally omitted

- Real hostnames, server inventory, private domains, and access notes.
- Auth files, API keys, OAuth tokens, cookies, browser profiles, sessions, and raw logs.
- Machine-specific paths outside generic examples such as `$HOME`, `<repo>`, `<host>`, and `/home/<user>`.
- Historical task packages under `docs/plans/**`; those are useful during work but are too likely to contain local context for a public repo.

## Local customization model

Use environment variables or ignored local files instead of editing public docs with private values:

```bash
export TARGET_HOST=<host>
export REMOTE_USER_HOME=/home/<user>
export PI_SETTINGS_FILE=settings/pi-settings.local.json
```

Copy `settings/pi-settings.example.json` to `settings/pi-settings.local.json` when a machine needs a different package list, theme, model, or `npmCommand`. Files matching `settings/*.local.json` are ignored by git.

## Submodules

The checked-in submodules are intended to point at public repositories:

- `https://github.com/blockedby/browser-chrome-skill.git`
- `https://github.com/blockedby/pi-codex.git`

Before changing repository visibility, confirm with `gh repo view` that every submodule target is public or remove/document the dependency without committing a private submodule URL.

## Public positioning

Safe profile/lab wording:

> Pi Agent Setup — a non-secret bootstrap for a Pi/Codex agent stack, including AAD routing agents, reusable skills, browser tooling, local/remote install scripts, and verification checks for bounded coding-agent workflows.

Use this as supporting evidence for disciplined agentic workflow infrastructure. Do not describe it as a polished product, managed service, universal installer, or autonomous replacement for engineering review.

# Public-readiness notes

This repository is public-facing workflow infrastructure, not a secret-bearing operations repo.

## Intentionally included

- AAD owner, implementer, explorer, browser, critic, classifier, and auditor definitions.
- Dynamic Direct / Slice / Root routing and GPT-5.6 model profiles.
- Reusable skills and public submodule pointers.
- Example settings and deterministic routing policy.
- Parameterized setup, verification, and auth-copy scripts.
- Documentation of safety, worktree, browser, audit, and evidence practices.

## Intentionally omitted

- Real hostnames, server inventory, private domains, and access notes.
- Auth files, API keys, OAuth tokens, cookies, browser profiles, sessions, and raw logs.
- Machine-specific paths outside placeholders such as `$HOME`, `<repo>`, `<host>`, and `/home/<user>`.
- Task records, progress state, screenshots, patches, and local run evidence.

Local AAD records belong under ignored `.pi/aad/**`. They are useful during execution but too likely to contain machine, repository, or task context for a public repository.

## Local customization

Use environment variables or ignored local files:

```bash
export TARGET_HOST=<host>
export REMOTE_USER_HOME=/home/<user>
export PI_SETTINGS_FILE=settings/pi-settings.local.json
```

Copy `settings/pi-settings.example.json` to `settings/pi-settings.local.json` when a machine needs different package, theme, model, or npm defaults.

## Submodules

The checked-in submodules point to public repositories:

- `https://github.com/blockedby/browser-chrome-skill.git`
- `https://github.com/blockedby/pi-codex.git`

Before changing visibility, verify every submodule target remains public or remove/document the dependency without committing a private URL.

## Public positioning

Safe wording:

> Pi Agent Setup — a non-secret bootstrap for a Pi/Codex coding-agent stack with dynamic ownership routing, model profiles, isolated worktrees, browser evidence, independent acceptance, local task records, and local/remote verification.

Do not describe it as a polished product, managed service, universal installer, or autonomous replacement for engineering review.

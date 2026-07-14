# Pi Agent Setup Guidance

## Public-safety rules

This repository is intended to be public, non-secret evidence of a disciplined Pi/Codex/AAD agent stack. Keep public-facing material English, professional, and honest: describe it as personal workflow infrastructure, not a universal product or fully autonomous system.

Never commit secrets, raw logs, credentials, tokens, cookies, chat IDs, private URLs, browser profiles, sessions, or machine inventory. Use placeholders such as `$HOME`, `<repo>`, `<host>`, `<remote>`, `/home/<user>`, environment variables, or ignored local config files. Machine-specific settings belong in `.env*` or `settings/*.local.json`, not public docs.

Do not recreate historical task packages under `docs/plans/**` for public-bound work in this repo unless explicitly approved; write temporary task reports outside the repo or use a clearly sanitized public doc. The old historical plans were intentionally removed for public readiness.

## Setup and verification checks

Public-readiness changes should run, when feasible:

```bash
git status --short
git diff --check
npm run secrets:check
rg -n "<add-old-hostname>|<add-old-local-path>|BEGIN (RSA|OPENSSH)|api[_-]?key|token|cookie|chat_id|webhook" -S --glob '!node_modules/**' --glob '!packages/pi-codex/node_modules/**' .
```

For local Pi setup checks, use the debugging loop below. Remote install/verify scripts require explicit `TARGET_HOST=<host>` and accept `REMOTE_USER_HOME=/home/<user>` and `PI_SETTINGS_FILE=settings/pi-settings.local.json`.

## Visual/UI acceptance rubric

For tasks that touch public page visuals, landing pages, templates, hero sections, marketing blocks, or product-quality UI surfaces, acceptance is screenshot-first. Require current screenshots for the relevant viewport set, identify the worst screenshot, and make a human-obvious-fail check before relying on technical metrics.

Reject visual/UI work when screenshots show concise anti-patterns such as clipped or overlapping content, broken responsive layout, collage/debug-looking composition, generic low-premium template output, weak hierarchy/typography/spacing, or unreadable contrast. DOM metrics, bounding boxes, and intersection checks are supporting evidence only; they do not override an obvious visual failure in the screenshot.

## Local Pi setup debugging

When a local `/reload` or Pi startup reports skill conflicts or extension load issues after changing this repo, debug the installed local setup, not just the checked-in files.

Useful loop:

1. Re-run the local installer:

   ```bash
   scripts/update-local.sh
   ```

2. Check installed AAD agents for forbidden `codex_task` exposure:

   ```bash
   rg -n "codex_task" ~/.pi/agent/agents agents || true
   ```

   AAD agents should not expose `codex_task`; use AAD subagents for implementation/discovery/audit routing instead.

3. Check skill frontmatter when Pi reports `description is required` or a skill conflict:

   ```bash
   head -8 ~/.pi/agent/skills/<skill-name>/SKILL.md
   head -8 skills/<skill-name>/SKILL.md
   ```

   Every checked-in skill needs YAML frontmatter with at least `name` and `description`.

4. Check local-path package dependencies when Pi reports `Cannot find module ...` for a vendored package:

   ```bash
   test -d packages/pi-codex/node_modules/@mozilla/readability && echo ok
   git -C packages/pi-codex status --short
   ```

   `packages/pi-codex` is used as a local Pi package, so its runtime `node_modules` must exist locally. Dependency installation must not leave the submodule dirty.

5. Smoke-test Pi startup/resource loading with a tiny prompt:

   ```bash
   PI_BIN="$(command -v pi)"
   timeout 120 "$PI_BIN" --no-session --mode text -p 'Say OK and exit.' 2>&1 | tail -n 80
   ```

   A clean run should end with `OK` and no skill/extension load errors. This is the quick check that caught the `aad-implementation-report` frontmatter issue and the missing `@mozilla/readability` dependency in the local `pi-codex` submodule.

## Local pi-codex dependency policy

For this setup repo, `packages/pi-codex` is a git submodule and a local Pi package source. Pi does not install dependencies for arbitrary local package paths during normal startup, so `scripts/update-local.sh` installs missing runtime dependencies.

Preferred behavior:

- run deterministic install on every local setup update: `npm ci --omit=dev`
- keep `packages/pi-codex/package-lock.json` correct in the `pi-codex` repository
- never use `npm install --package-lock=false` as a normal path
- never leave tracked files dirty inside `packages/pi-codex`
- verify with `git -C packages/pi-codex status --short`

If the submodule's lockfile is wrong, fix that in the `pi-codex` repository and update the submodule pointer separately. This setup repo owns the vendored local-package workflow, but the submodule still owns its own package metadata.

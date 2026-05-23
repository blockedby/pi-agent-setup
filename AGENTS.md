# Pi Agent Setup Guidance

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
   timeout 120 "$HOME/.vite-plus/bin/pi" --no-session --mode text -p 'Say OK and exit.' 2>&1 | tail -n 80
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

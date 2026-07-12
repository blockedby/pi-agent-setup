# Pi Agent Setup Guidance

## Public-safety rules

This repository is public, non-secret evidence of a disciplined Pi/Codex/AAD stack. Keep public-facing material English, professional, sanitized, and honest: this is personal workflow infrastructure, not a universal product or fully autonomous system.

Never commit secrets, raw logs, credentials, tokens, cookies, chat IDs, private URLs, browser profiles, sessions, machine inventory, or real user/host paths. Use placeholders such as `$HOME`, `<repo>`, `<host>`, `/home/<user>`, environment variables, or ignored local settings.

AAD task records and runtime evidence belong under ignored project-local `.pi/aad/`. Do not recreate committed historical packages under `docs/plans/**`.

## Ownership and authorization

Use the Direct / Slice / Root gate in `APPEND_SYSTEM.md` and `aad-slicing-and-delegation`.

A review/explanation/diagnosis/plan request does not authorize implementation. A change/build/fix request authorizes in-scope local edits and non-destructive verification. External writes, destructive/costly actions, credentials/sessions, merge/deploy, and material scope expansion require approval.

Any mutation uses an isolated worktree unless the user explicitly requests the current checkout.

## Active model policy

- Evidence profile: Luna medium.
- Work profile: Terra high.
- Deep profile: Sol high.
- `xhigh` and `max` are not used.

Agent frontmatter is a fallback. Owners may pass a runtime `model` override after applying the routing policy.

## Agent policy

- `aad-slice-owner` is a working owner and implements ordinary slices directly.
- Browser automation/evidence always uses a separate `chrome-browser-agent` context.
- Slice/root acceptance always uses a separate auditor context.
- Legacy static chains are not part of the active workflow.
- Root/slice owners may discover project skills; specialist children receive explicit selected skills.
- Do not expose `codex_task` to active AAD agents.

## Setup and verification checks

Public-readiness changes should run, when feasible:

```bash
git status --short
git diff --check
npm run secrets:check
npm run verify:aad
rg -n "<add-old-hostname>|<add-old-local-path>|BEGIN (RSA|OPENSSH)|api[_-]?key|token|cookie|chat_id|webhook" -S --glob '!node_modules/**' --glob '!packages/pi-codex/node_modules/**' .
```

After changing installed resources:

```bash
scripts/update-local.sh
```

Then use `/reload` or restart Pi and smoke-test startup:

```bash
timeout 120 "$HOME/.vite-plus/bin/pi" --no-session --mode text -p 'Say OK and exit.' 2>&1 | tail -n 80
```

## Local pi-codex dependency policy

`packages/pi-codex` is a git submodule and local Pi package source. `scripts/update-local.sh` runs `npm ci --omit=dev` for deterministic runtime dependencies.

Never leave tracked files dirty inside the submodule. If its lockfile or package metadata is wrong, fix that in the `pi-codex` repository and update the submodule pointer separately.

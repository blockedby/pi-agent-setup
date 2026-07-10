# Global Pi terminal routing for AAD work

Use these routing rules before choosing a skill, chain, or subagent for repository work.

## Default terminal posture

You are the terminal main assistant. Handle only clearly trivial, one-step edits, questions, or checks directly when no AAD ownership is needed.

## Global git branch and commit conventions

These rules apply in every repository unless that repository's own instructions define a stricter or more specific git convention. Do not rename, amend, squash, or rewrite existing branches/commits only to satisfy this convention unless explicitly asked.

Before creating a new branch, worktree branch, or PR branch, choose and validate a conventional branch name. Allowed default form:

```text
<type>/<short-lowercase-kebab-slug>
```

Default branch types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `build`, `perf`, `hotfix`, `release`.

Branch slugs must be concise lowercase kebab-case using only letters, numbers, dots, and hyphens. Do not create vague or non-conventional branches such as `update`, `updates`, `changes`, `work`, `wip`, `temp`, `fixes`, `agent`, or unprefixed task names. If the correct type is unclear, stop and ask rather than inventing a vague branch.

Before committing, choose and validate a Conventional Commit subject. Allowed default form:

```text
<type>[optional scope]: <imperative summary>
```

Default commit types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `build`, `perf`, `revert`.

The summary must be specific, imperative, and lowercase unless a proper noun/code token requires otherwise. Do not commit vague subjects such as `update`, `updates`, `changes`, `fix`, `fixes`, `fix stuff`, `wip`, `misc`, or `checkpoint`.

Before running any `git commit` command, inspect the staged state and ensure the subject is valid for the staged change. Prefer `git status --short` plus a staged diff/stat check. Do not run raw `git commit` without a valid subject in the command unless the user explicitly asks for an editor-based commit. If the user provides a non-conforming branch name or commit subject, ask for confirmation or suggest a corrected conventional form before proceeding.

For AAD-owned work, route to the owner hierarchy instead of treating a skill or worker as the top-level owner:

- Clear small or single-slice AAD implementation/change tasks: call `aad-slice-owner` directly.
- Multi-step, unclear, multi-slice, cross-cutting, or integration-heavy AAD tasks: call `aad-root-owner`.
- Read-only discovery, narrow review, browser evidence, failure classification, and implementation work should be delegated by the relevant owner, not selected as the terminal default route.

## Owner hierarchy

`aad-root-owner` owns non-trivial root-level AAD work. It slices the work, delegates slices to `aad-slice-owner`, integrates slice results, and reports the final done-state.

`aad-slice-owner` owns one clear slice. It may be called directly by the terminal main assistant for a clear single-slice task, or by `aad-root-owner` as one slice in a larger effort. It delegates execution to `aad-implementer` and supporting agents as needed while retaining slice ownership.

`aad-implementer` and support agents are internal execution and evidence targets. Do not use them as top-level default routes from the terminal main assistant unless the user explicitly asks for a direct specialist invocation and the task is not AAD-owned.

## Parallel and background delegation

Parallelism and background execution are separate decisions. When two or more delegated tasks are ready and independent, dispatch the entire ready wave in one `subagent` call using `tasks: [...]` and an explicit `concurrency` limit. Do not issue repeated synchronous single-agent calls for tasks in the same wave, and do not wait for one ready task before launching another ready task. Use individual calls only when later work genuinely depends on an earlier result or the tasks cannot safely overlap.

Use at most one `aad-root-owner` for a single root request. That root owner may launch independent `aad-slice-owner` tasks as one parallel wave. Do not launch competing root owners for the same integration narrative.

Use `async: true` when a safe delegated run should continue in the background while the owner has other useful work. Backgrounding does not replace `tasks: [...]` batching: an independent wave may be parallel, asynchronous, both, or neither. Do not background tasks that need immediate interactive clarification, must edit the same files in sequence, require tight owner supervision, or could conflict with other active work.

For async subagents, do not run polling loops such as `sleep 20` followed by repeated `subagent({ action: "status" })` checks. Check async status only when the user asks for it or when a completion / `needs_attention` event arrives.

## Skills and chains

Skills are runbooks and support material. They do not replace the owner/subagent hierarchy, do not own acceptance, and do not decide done-state by themselves.

`aad-owned-change.chain.md` and other chain files remain available for optional legacy/manual workflows, but the default AAD-owned implementation path is terminal routing to `aad-slice-owner` or `aad-root-owner` as described above.

## Long-running process output discipline

When starting long-running commands with the process tool, do not poll `process.output` repeatedly. After `process.start`, continue other useful work or wait for the process notification.

Allowed manual output checks:

- once shortly after start, only to confirm the command began correctly;
- when the process sends a success/failure notification;
- when the user explicitly asks for current status;
- after a long quiet period, no more than once every several minutes.

Do not call `process.output` in a tight loop or every few seconds. Prefer `alertOnSuccess`, `alertOnFailure`, and `logWatches` for important events.

---
name: aad-target-branch-preparation
description: Use when an AAD owner is finalizing a branch and needs the repo's PR-first, target-branch-preparation, merge-from-primary-checkout workflow.
---

# AAD Target Branch Preparation

## Overview

Use this skill after the work is implemented and freshly verified, when the branch is ready to be aligned with `origin/main` and finalized.

Treat PR creation as the first finish milestone. After the PR exists, prepare the branch against the target branch, decide whether regression verification must be rerun, and merge from the primary checkout only when authorized.

## Workflow

1. In the feature worktree, confirm the current branch is not `main`.
2. Run fresh proving verification for the current branch state.
3. Open or update the PR to `main`. Record the PR URL, number, and intended `owner/repo`. If fork/upstream ambiguity exists, use `gh ... --repo owner/repo` for every PR/check operation rather than relying on the worktree remote or a numeric PR alone.
4. Run `bash scripts/aad/target-branch-prepare.sh --base main` from the feature worktree.
5. Read the script output and decide the verification next step:
   - if `rerun_required=true`, run fresh regression verification now
   - if you add new fix-up commits after rebase fallout, rerun fresh verification again after those commits
6. Push the refreshed branch.
7. If `gh pr view <N> --json state` reports `state=MERGED`, skip merge and proceed only to the post-merge root-sync rule below. In fork/upstream-ambiguous contexts, run this as `gh pr view <N> --repo owner/repo --json state`.
8. If merge is authorized, move to the primary checkout and run the mandatory **pre-remote-merge** preflight below. It must be clean, on `main`, and exactly aligned with `origin/main` before `gh pr merge`; otherwise abort without a merge or any primary-checkout mutation.
9. Only after that preflight passes, run `gh pr merge <N> --squash` from the primary checkout. In fork/upstream-ambiguous contexts, include `--repo owner/repo`.
10. After the remote merge, apply the post-merge root-sync rule below. It permits only a clean, equal-state no-op cleanup or behind-only `git merge --ff-only origin/main` update after fetching; otherwise abort the sync without push, rebase, stash, reset, or remote mutation. Perform local worktree/branch cleanup only after a successful allowed no-op or sync.
11. Report the PR URL, rebase result, verification result, pre-merge preflight result, merge result, post-merge sync result, and cleanup result. Do not report or create a stash as part of this flow.

## Re-run regression rules

- Re-run when `target-branch-prepare.sh` reports `content_changed=true`.
- Re-run when the rebase required conflict resolution.
- Re-run whenever new fix-up commits were added after rebase fallout.
- Skip the second run only when the rebase was a no-op / metadata-only update and no new commits were added afterward.

## Merge rules

- Merge only when the user asked for autonomous completion or task policy clearly allows it.
- Never run `gh pr merge` from a feature worktree.
- Never pass `--delete-branch` to `gh pr merge`.
- Keep the remote feature branch after merge unless the user explicitly asks to delete it.

## Root sync rules

- The primary checkout must stay on `main`.
- A dirty primary checkout fails both preflight and post-merge sync; do not stash it as part of this finalization flow.
- Resolve or deliberately preserve dirty state outside this flow, then restart the appropriate check.

## Fail-closed pre-remote-merge primary-checkout preflight

Before **remote merge** (`gh pr merge`) and before any other primary-checkout mutation, run this preflight from the primary checkout. It is mandatory even if a prompt says the checkout should be clean:

1. `git fetch origin main` (inspection only).
2. Require `git branch --show-current` to be exactly `main`.
3. Require both index and worktree to be clean (`git status --porcelain` is empty).
4. Require `HEAD` to equal `origin/main` exactly, and require `git rev-list --left-right --count origin/main...HEAD` to report `0 0`.

If any check fails, stop non-zero and report the branch, cleanliness result, ahead/behind counts, and local-only commit subjects when present. **Do not** rebase, merge, push, stash, reset, or invoke a sync helper. A local-only primary commit is never an implicit publish candidate. Resolve divergence deliberately outside this finalization flow, then restart the preflight.

## Fail-closed post-merge root sync

After `gh pr merge` advances remote `main` (or when the PR is already merged), the primary checkout may sync only through this bounded path:

1. Run `git fetch origin main` (inspection only).
2. Require branch `main` and an empty `git status --porcelain`.
3. Require local `HEAD` to be an ancestor of `origin/main` and `git rev-list --left-right --count HEAD...origin/main` to show either `0 0` (equal) or `0 <behind>` with `<behind>` greater than zero. Equal is an allowed no-op sync state; ahead and diverged states are rejected.
4. If behind, run only `git merge --ff-only origin/main`; if equal, do not mutate `main` and proceed with local cleanup.

If any condition fails, abort with no push, rebase, stash, reset, or remote mutation. A local-only commit is never an implicit publish candidate.

## Helper scripts

- `scripts/aad/target-branch-prepare.sh` — feature-branch fetch / rebase / status helper
- `scripts/aad/root-main-sync.sh` — bounded equal/behind-only primary-checkout sync and local cleanup helper; it must enforce the post-merge root-sync contract above

## Common mistakes

- merging before opening the PR
- rebasing before the PR exists
- treating stale pre-rebase verification as enough after branch content changed
- merging from a feature worktree
- deleting the remote branch out of habit
- switching the feature worktree to `main` as a finish step

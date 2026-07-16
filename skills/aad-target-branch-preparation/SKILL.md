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
4. Prepare the feature branch against `origin/main` with this installed skill's `scripts/aad-finalization-helper.sh target-branch-prepare --base main` helper. Resolve that helper from the installed skill directory, never from an arbitrary repository copy; see **Bundled helper resolution** below. Otherwise use the direct fallback: run `git fetch origin main`;  record `pre_rebase_head=$(git rev-parse HEAD)` and `pre_rebase_tree=$(git rev-parse HEAD^{tree})`; run `git rebase origin/main`; record `post_rebase_head=$(git rev-parse HEAD)` and `post_rebase_tree=$(git rev-parse HEAD^{tree})`; and use `git diff --quiet "$pre_rebase_tree" "$post_rebase_tree"` to determine whether tree content changed. Record whether conflict resolution or any fix-up commit occurred. Require fresh regression verification when the pre/post trees differ, conflicts were resolved, or a fix-up commit was added. A no-op rebase with identical trees and no conflict/fix-up may retain the prior verification.
5. Push the refreshed branch.
6. If `gh pr view <N> --json state` reports `state=MERGED`, skip merge and proceed only to the post-merge root-sync rule below. In fork/upstream-ambiguous contexts, run this as `gh pr view <N> --repo owner/repo --json state`.
7. If merge is authorized, move to the primary checkout and run the mandatory **pre-remote-merge** preflight below. It must be clean, on `main`, and exactly aligned with `origin/main` before `gh pr merge`; otherwise abort without a merge or any primary-checkout mutation.
8. Only after that preflight passes, run `gh pr merge <N> --squash` from the primary checkout. In fork/upstream-ambiguous contexts, include `--repo owner/repo`.
9. After the remote merge, apply the post-merge root-sync rule below with this installed skill's `scripts/aad-finalization-helper.sh root-main-sync --base main` helper. Resolve that helper from the installed skill directory, never from an arbitrary repository copy; see **Bundled helper resolution** below. Otherwise use its direct fallback. It permits only a clean, equal-state no-op cleanup or behind-only `git merge --ff-only origin/main` update after fetching; otherwise abort the sync without push, rebase, stash, reset, or remote mutation. Perform local worktree/branch cleanup only after a successful allowed no-op or sync.
10. Report the PR URL, rebase result, verification result, pre-merge preflight result, merge result, post-merge sync result, and cleanup result. Do not report or create a stash as part of this flow.

## Re-run regression rules

- Re-run when the recorded pre- and post-rebase trees differ.
- Re-run when the rebase required conflict resolution.
- Re-run whenever new fix-up commits were added after rebase fallout.
- Skip the second run only when the rebase was a no-op with identical trees and no new commits were added afterward.

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

## Bundled helper resolution

This setup owns the generic helpers under this skill, so invoke the installed skill-relative dispatcher rather than a project-local copy:

```bash
SKILL_DIR="$HOME/.pi/agent/skills/aad-target-branch-preparation"
HELPER="$SKILL_DIR/scripts/aad-finalization-helper.sh"
bash "$HELPER" target-branch-prepare --base main
# From the primary checkout after an authorized remote merge:
bash "$HELPER" root-main-sync --base main
```

The dispatcher resolves its bundled scripts from its own location (`BASH_SOURCE`), which remains stable after installation. `AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR` is an explicit **test-only** override for hermetic fixtures; production workflow must not set it. The fallback commands above remain valid when the global skill is unavailable. Helpers are not authority to weaken these contracts: do not use a helper that pushes local `main`, rebases primary `main`, stashes, resets, or accepts ahead/diverged/dirty primary state.

## Common mistakes

- merging before opening the PR
- rebasing before the PR exists
- treating stale pre-rebase verification as enough after branch content changed
- merging from a feature worktree
- deleting the remote branch out of habit
- switching the feature worktree to `main` as a finish step

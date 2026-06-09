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
7. If `gh pr view <N> --json state` reports `state=MERGED`, skip merge and continue with local sync / cleanup reporting. In fork/upstream-ambiguous contexts, run this as `gh pr view <N> --repo owner/repo --json state`.
8. If merge is authorized, move to the primary checkout on `main` and run `gh pr merge <N> --squash`. In fork/upstream-ambiguous contexts, include `--repo owner/repo`.
9. From the primary checkout, run `bash scripts/aad/root-main-sync.sh --delete-worktree "<feature-worktree-path>" --delete-branch "<feature-branch>"`.
10. Report the PR URL, rebase result, verification result, merge result, cleanup result, and any stash label used to preserve root-checkout state.

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
- Dirty primary-checkout state may be stashed, synced, and restored automatically.
- `root-main-sync.sh` must report the stash label and stop without dropping it if stash restore conflicts appear.

## Helper scripts

- `scripts/aad/target-branch-prepare.sh` — feature-branch fetch / rebase / status helper
- `scripts/aad/root-main-sync.sh` — primary-checkout sync / stash restore / local cleanup helper

## Common mistakes

- merging before opening the PR
- rebasing before the PR exists
- treating stale pre-rebase verification as enough after branch content changed
- merging from a feature worktree
- deleting the remote branch out of habit
- switching the feature worktree to `main` as a finish step

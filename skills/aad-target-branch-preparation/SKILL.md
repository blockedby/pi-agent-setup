---
name: aad-target-branch-preparation
description: Use when an AAD owner is finalizing a branch and needs a PR-first workflow for preparing, merging, and synchronizing against an explicit target branch.
---

# AAD Target Branch Preparation

## Overview

Use this skill after the work is implemented and freshly verified, when the feature branch is ready to be aligned with its target branch and finalized.

Determine the target branch from the PR base or explicit task context; do not assume it is `main`. Treat PR creation as the first finish milestone. After the PR exists, prepare the feature branch against `origin/<target-branch>`, decide whether regression verification must be rerun, and merge from the checkout holding the target branch only when authorized.

## Workflow

1. Determine `<target-branch>` from the PR base or explicit task context. Use `main` only when it is actually the target.
2. In the feature worktree, confirm the current branch is not `<target-branch>`.
3. Run fresh proving verification for the current branch state.
4. Open or update the PR to `<target-branch>`. Record the PR URL, number, target branch, and intended `owner/repo`. If fork/upstream ambiguity exists, use `gh ... --repo owner/repo` for every PR/check operation rather than relying on the worktree remote or a numeric PR alone.
5. Resolve [`scripts/prepare-target-branch.sh`](scripts/prepare-target-branch.sh) relative to the directory containing this `SKILL.md`. Keep the feature worktree as the current working directory and run `bash "<resolved-skill-directory>/scripts/prepare-target-branch.sh" --base "<target-branch>"`.
6. Read the script output and decide the verification next step:
   - if `rerun_required=true`, run fresh regression verification now
   - if you add new fix-up commits after rebase fallout, rerun fresh verification again after those commits
7. Push the refreshed branch.
8. If `gh pr view <N> --json state` reports `state=MERGED`, skip merge and continue with local sync / cleanup reporting. In fork/upstream-ambiguous contexts, run this as `gh pr view <N> --repo owner/repo --json state`.
9. If merge is authorized, move to the checkout holding `<target-branch>` and run `gh pr merge <N> --squash`. In fork/upstream-ambiguous contexts, include `--repo owner/repo`.
10. From that target-branch checkout, resolve [`scripts/sync-target-branch.sh`](scripts/sync-target-branch.sh) relative to this skill directory and run `bash "<resolved-skill-directory>/scripts/sync-target-branch.sh" --base "<target-branch>" --delete-worktree "<feature-worktree-path>" --delete-branch "<feature-branch>"`.
11. Report the PR URL, target branch, rebase result, verification result, merge result, cleanup result, and any stash label used to preserve target-checkout state.

## Re-run regression rules

- Re-run when `prepare-target-branch.sh` reports `content_changed=true`.
- Re-run when the rebase required conflict resolution.
- Re-run whenever new fix-up commits were added after rebase fallout.
- Skip the second run only when the rebase was a no-op / metadata-only update and no new commits were added afterward.

## Merge rules

- Merge only when the user asked for autonomous completion or task policy clearly allows it.
- Never run `gh pr merge` from a feature worktree; use the checkout holding the target branch.
- Never pass `--delete-branch` to `gh pr merge`.
- Keep the remote feature branch after merge unless the user explicitly asks to delete it.

## Target-branch sync rules

- Run the sync helper from the worktree where `<target-branch>` is checked out.
- Dirty target-checkout state may be stashed, synced, and restored automatically.
- `sync-target-branch.sh` must report the stash label and stop without dropping it if stash restore conflicts appear.

## Helper scripts

- [`scripts/prepare-target-branch.sh`](scripts/prepare-target-branch.sh) — feature-branch fetch / rebase / status helper
- [`scripts/sync-target-branch.sh`](scripts/sync-target-branch.sh) — target-checkout sync / stash restore / local cleanup helper

Resolve both paths relative to the directory containing this `SKILL.md`, not relative to the target repository.

## Common mistakes

- merging before opening the PR
- rebasing before the PR exists
- treating stale pre-rebase verification as enough after branch content changed
- merging from a feature worktree
- deleting the remote branch out of habit
- assuming the target branch is `main` without checking the PR base or task context
- switching the feature worktree to the target branch as a finish step

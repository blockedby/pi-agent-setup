---
name: aad-worktree-management
description: Use before any authorized repository mutation to create or enter an isolated worktree with safe parent/child lineage, protecting against unseen parallel terminals and agent runs.
---

# AAD Worktree Management

Any repository mutation uses an isolated worktree unless the user explicitly requests the current checkout. Read-only work may use the current checkout.

## Defaults

- Root worktree base: intended target branch, normally `main`.
- Slice worktree base: active parent branch for child work; target branch for top-level slice work.
- Path: `.worktrees/<branch-or-topic>`.
- Branch: `<type>/<short-lowercase-kebab-slug>` unless repository guidance is stricter.

## Workflow

1. Verify `.worktrees/` is ignored.
2. Inspect current branch and dirty state.
3. Choose the correct base and branch.
4. Create or enter the isolated worktree.
5. Record path, branch, and base in `.pi/aad/<task-id>/task.md`.
6. Continue without narrating routine git mechanics.

## Parent/child lineage

A child slice belongs to its parent until integrated:

```text
target branch
  -> root/top-level slice branch
      -> child slice branch
```

Integrate child results into the parent worktree before final target-branch preparation. Do not send a child directly to `main` unless it is promoted to an independent root-level slice.

## Parallel writers

Each concurrent writer requires a separate worktree. Read-only explorer/auditor agents may read the owner's worktree. A browser agent uses a separate agent context but may inspect a preview served from the owner worktree.

## Safety

Do not overwrite unrelated dirty state, delete unknown worktrees, switch a feature worktree to `main`, or merge from a feature worktree.

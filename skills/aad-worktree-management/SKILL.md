---
name: aad-worktree-management
description: Use when an AAD owner needs an isolated git worktree using the repo's conventions without external worktree rituals.
---

# AAD Worktree Management

## Overview

Use this skill when isolated workspace setup is warranted for owned implementation work.

Follow the repo convention directly. Do not ask the user where to place worktrees unless they explicitly request a different location.

## Workflow

1. Use `.worktrees/` at the repository root.
2. Verify `.worktrees/` is ignored before creating a new worktree.
3. Create the branch from the intended base branch.
4. Create the worktree under `.worktrees/<branch-or-topic>`.
5. Report the resulting path and branch clearly.

## Parent/child worktree lineage

For root owned work, the default base branch is `main` unless the delegated task or repo state requires a different base.

For sub-slice implementation work, default to the parent slice branch/worktree as the base, not `main`. A child sub-slice is part of the parent slice until integrated.

Child sub-slice results should merge or otherwise integrate back into the parent slice worktree/branch first. The parent slice owner decides the parent done-state, resolves overlap, reruns needed verification, and prepares the parent branch/PR to the target branch.

Do not send a child sub-slice directly to `main` unless the parent explicitly promotes it to an independent root-level slice.

## Implementation-bound task package

For implementation-bound root slice work, the owner should create the task package in the new worktree, commit and push it, and open a draft PR early unless the user or repo policy says not to. Use `aad-task-package` for the task package layout.

## Defaults

- Default base branch for root owned work: `main`, unless the delegated task or repo state requires a different base.
- Default base branch for sub-slice work: the parent slice branch.
- Default purpose: isolation for meaningful implementation work.
- Default behavior: continue autonomously once the worktree is ready.

## Common mistakes

- asking for directory selection when repo policy already sets it
- creating a worktree without checking ignore safety
- treating worktree creation as a full workflow of its own
- over-explaining routine git mechanics

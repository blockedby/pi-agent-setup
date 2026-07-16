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
4. When creating a new task branch, prefer Conventional Branch-style lowercase prefixes: `feat/`, `fix/`, `hotfix/`, `release/`, or `chore/`. Use the prefix that best matches the delegated change and a concise description segment made only of lowercase letters, numbers, hyphens, and dots; do not use spaces or underscores. Follow an existing local branch convention instead if it is stricter.
5. Do not rename or recreate existing branches just to satisfy the convention.
6. Create the worktree under `.worktrees/<branch-or-topic>`.
7. Report the resulting path and branch clearly.

## Parent/child worktree lineage

For root owned work, use the target branch explicitly supplied by the user or repository guidance; do not assume a branch name. After creating the feature branch, record provenance with `git config branch.<feature>.aadTarget <target>`.

For sub-slice implementation work, default to the parent slice branch/worktree as the base, not the target branch. A child sub-slice is part of the parent slice until integrated.

Child sub-slice results should merge or otherwise integrate back into the parent slice worktree/branch first. The parent slice owner decides the parent done-state, resolves overlap, reruns needed verification, and prepares the parent branch/PR to the target branch.

Do not send a child sub-slice directly to the target branch unless the parent explicitly promotes it to an independent root-level slice.

## Implementation-bound task package

For implementation-bound root slice work, the owner should create the task package in the new worktree, commit and push it, and open a draft PR early unless the user or repo policy says not to. Use `aad-task-package` for the task package layout.

## Defaults

- Default base branch for root owned work: explicit user/repository target; otherwise stop rather than guessing.
- Default base branch for sub-slice work: the parent slice branch.
- Default purpose: isolation for meaningful implementation work.
- Default behavior: continue autonomously once the worktree is ready.

## Common mistakes

- asking for directory selection when repo policy already sets it
- creating a worktree without checking ignore safety
- treating worktree creation as a full workflow of its own
- over-explaining routine git mechanics

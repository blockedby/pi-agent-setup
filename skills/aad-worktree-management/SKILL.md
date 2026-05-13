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

## Defaults

- Default base branch: `main`, unless the delegated task or repo state requires a different base.
- Default purpose: isolation for meaningful implementation work.
- Default behavior: continue autonomously once the worktree is ready.

## Common mistakes

- asking for directory selection when repo policy already sets it
- creating a worktree without checking ignore safety
- treating worktree creation as a full workflow of its own
- over-explaining routine git mechanics

---
name: aad-plan-writing
description: Use when an AAD owner needs a repo-local implementation plan that follows the ownership model directly without external workflow choreography.
---

# AAD Plan Writing

## Overview

Use this skill when the design is settled enough to define execution.

The plan should help an owner or slice owner execute directly. Supporting agents remain optional and should appear only where they make continuation cheaper.

## Workflow

1. Read the approved requirements, design notes, and local repo guidance.
2. Identify the files or areas likely to change.
3. Define the ownership model:
   - stays whole under one owner
   - or splits into named slices with clear boundaries
4. Write an execution plan in `docs/superpowers/plans/` with:
   - goal
   - scope and do-not-touch boundaries
   - files or areas involved
   - ordered implementation steps
   - verification targets
   - optional delegation points only where they are genuinely cheaper
5. Keep the plan compact and directly executable.

## Plan rules

- Prefer one owner carrying the work when one owner can do it cheaply.
- Do not inject mandatory review loops or external workflow skills.
- Make verification explicit for each meaningful checkpoint.
- Use checklist steps when that makes execution easier.

## Common mistakes

- turning the plan into generic advice
- forcing delegation where direct execution is cheaper
- leaving verification implicit
- bloating the plan with workflow ceremony unrelated to the actual change

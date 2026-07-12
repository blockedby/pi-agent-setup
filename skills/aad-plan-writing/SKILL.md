---
name: aad-plan-writing
description: Use when an AAD owner needs an acceptance-driven execution plan inside the local .pi/aad task record; keep it compact for a slice and explicit about dependencies only for real root or delegated work.
---

# AAD Plan Writing

Write just enough plan to make execution and verification safe.

## Compact slice plan

For a normal slice, add a short `Plan` section to `task.md`:

```md
## Plan
1. <behavior change> — verify with <check>
2. <behavior change> — verify with <check>

Dependencies:
- none
```

Do not create a separate plan file unless the user or repository explicitly requires one.

## Root plan

For Root work, define named slices with:

```md
### <slice id>: <outcome>
- Owner:
- Runtime model:
- Goal:
- Scope:
- Acceptance:
- Evidence route:
- Depends on:
- Blocks:
- Can run in parallel with:
- Browser:
- Audit:
- Record:
```

Slice boundaries follow independently accepted outcomes, not mechanical file edits.

## Planning rules

- Reuse repository patterns before proposing new abstractions.
- One coherent verification story normally stays one slice.
- Split when ownership or acceptance stories separate, not merely to gain parallelism.
- Record consequential uncertainty and select `CONSULT` only when repository evidence cannot safely settle it.
- Name the smallest proving check for each criterion.
- Select task-specific skills explicitly.
- The slice owner implements normal work directly; do not insert an implementer handoff by habit.
- Browser work and acceptance audits remain separate contexts.
- Keep the plan current, but do not turn it into a timeline or diary.

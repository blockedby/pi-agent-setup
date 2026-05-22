---
name: aad-plan-writing
description: Use when an AAD owner needs a repo-local, acceptance-driven implementation plan that follows the ownership model directly without external workflow choreography.
---

# AAD Plan Writing

## Overview

Use this skill when the design is settled enough to define execution.

The plan should help an owner or slice owner execute directly. Supporting agents remain optional and should appear only where they make continuation cheaper.

A good AAD plan is operational: it states what will change, what will prove each change, and how the work should be ordered.

## Workflow

1. Read the approved requirements, design notes, and local repo guidance.
2. Normalize the task:
   - goal
   - in-scope behavior
   - out-of-scope boundaries
   - done-state
   - known constraints and blocking unknowns
3. Identify the files, components, services, data models, APIs, tests, or docs likely to change.
4. Identify existing patterns or reusable implementations the plan should follow.
5. Define the ownership model:
   - stays whole under one owner
   - or splits into named slices with clear boundaries
6. Write an execution plan in `docs/superpowers/plans/` with:
   - goal
   - scope and do-not-touch boundaries
   - reuse notes
   - staged implementation plan
   - dependency notes
   - verification targets
   - optional delegation points only where they are genuinely cheaper
7. Keep the plan compact and directly executable.

## Stage format

Every meaningful stage should use this structure:

```md
### Stage N: <name>

Goal:
- <what this stage makes true>

Scope / likely files:
- <files, areas, components, services, APIs, schemas, tests>

Acceptance criteria:
- <observable criterion 1>
- <observable criterion 2>

Test plan:
- Positive: <targeted test/check>
- Negative: <targeted test/check, when relevant>
- Edge case: <targeted test/check, when relevant>
- Manual: <only when automation is not practical>

Dependencies:
- Depends on: <none / stage IDs / external decision>
- Blocks: <none / stage IDs>
- Can run parallel with: <none / stage IDs>

Owner candidate:
- <current owner / sub-slice owner / supporting agent>
```

No meaningful stage should omit acceptance criteria or a verification plan. If a criterion cannot be automated, state the manual evidence expected.

## Slicing by system boundary

For multi-component features, prefer stages that align with real system boundaries, for example:

- database schema, migration, or model
- backend service or API endpoint
- API client, SDK, or shared contract
- frontend page, component, hook, or state boundary
- integration between components
- browser, e2e, or final readiness verification

Do not split cosmetic steps into separate slices unless doing so makes execution cheaper.

## Plan rules

- Prefer one owner carrying the work when one owner can do it cheaply.
- Do not inject mandatory review loops or external workflow skills.
- Make verification explicit for each meaningful checkpoint.
- Tie acceptance criteria to tests or checks wherever possible.
- Prefer TDD for stages where the repo has suitable test infrastructure.
- Use checklist steps when that makes execution easier.
- Record dependencies so the owner can later decide parallel execution waves.

## Common mistakes

- turning the plan into generic advice
- forcing delegation where direct execution is cheaper
- leaving verification implicit
- listing implementation tasks without acceptance criteria
- writing acceptance criteria that cannot be checked
- bloating the plan with workflow ceremony unrelated to the actual change

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
6. Write an execution plan in `docs/plans/` with:
   - goal
   - scope and do-not-touch boundaries
   - task boundaries based on independently verifiable behavior
   - acceptance criteria and test plan per task
   - dependencies and optional delegation points only where they are genuinely cheaper
7. Keep the plan compact and directly executable.

## Task sizing

A plan task is the smallest independently verifiable behavior change inside the current slice.

Do not size plan tasks by file count, estimated minutes, or mechanical edit steps. Size them by the behavior they make true and the primary verification that can prove it.

A good plan task is:

- small enough that one implementer agent can execute it and return a complete acceptance verification report
- large enough to represent meaningful behavior, not just "create file", "add import", or "change CSS class"
- centered on one primary system boundary and one primary verification story
- explicit about what existing pattern or implementation it will reuse

Prefer task boundaries around verification boundaries:

- database schema, migration, or model behavior
- backend service or API behavior
- API client, SDK, or shared contract behavior
- frontend page, component, hook, or state behavior
- integration between components or services
- browser, e2e, or final readiness behavior

Split a plan task when:

- it needs a different primary test type or verification command
- it crosses independent ownership boundaries
- part of it can run in parallel with another part
- one part blocks another
- acceptance criteria no longer fit one coherent verification story

Do not split a plan task when:

- the pieces are only mechanical file edits
- no piece has independent acceptance criteria
- verification only makes sense after the pieces are combined
- splitting would create more coordination than clarity

## Slices, tasks, and executors

A slice is the ownership boundary. A plan task is the execution unit inside that slice.

The parent slice owner remains responsible for the slice result even when tasks are delegated. Plan tasks do not create new ownership by default.

Use an implementer agent for a delegated plan task when the task is already clear enough to execute. Escalate a task to a child slice owner only when it needs its own planning, decomposition, coordination, or integration.

## Task format

Every meaningful plan task should use this structure:

```md
### Task N: <independently verifiable behavior>

Goal:
- <what this task makes true>

Boundary:
- System area: <backend/API/frontend/component/integration/etc>
- Primary verification: <test suite/check/manual evidence that proves this task>

Existing pattern / reuse:
- <existing file/symbol/pattern to follow or reuse>

Missing change:
- <minimal new behavior/code needed>

Scope / likely files:
- <files, areas, components, services, APIs, schemas, tests>

Acceptance criteria:
- <observable criterion 1>
- <observable criterion 2>

Test plan:
- Positive:
  - <targeted test/check for happy path 1>
  - <targeted test/check for happy path 2, when relevant>
- Negative:
  - <targeted test/check for invalid/error/unauthorized path 1, when relevant>
  - <targeted test/check for invalid/error/unauthorized path 2, when relevant>
- Edge cases:
  - <targeted test/check for boundary/empty/large/special case 1, when relevant>
  - <targeted test/check for boundary/empty/large/special case 2, when relevant>
- Manual:
  - <only when automation is not practical>

Dependencies:
- Depends on: <none / task IDs / external decision>
- Blocks: <none / task IDs>
- Can run parallel with: <none / task IDs>

Executor:
- <implementer / browser-agent / failure-classifier / child slice owner if too large>
```

No meaningful plan task should omit acceptance criteria or a verification plan. If a criterion cannot be automated, state the manual evidence expected.

## Plan rules

- Prefer one owner carrying the work when one owner can do it cheaply.
- Do not inject mandatory review loops or external workflow skills.
- Make verification explicit for each meaningful checkpoint.
- Tie acceptance criteria to tests or checks wherever possible.
- Prefer TDD for plan tasks where the repo has suitable test infrastructure.
- Use checklist steps inside a task when that makes execution easier, but do not mistake mechanical checklist items for plan tasks.
- Record dependencies so the owner can later decide parallel execution waves.

## Common mistakes

- turning the plan into generic advice
- forcing delegation where direct execution is cheaper
- leaving verification implicit
- splitting by mechanical file edits instead of independently verifiable behavior
- listing implementation tasks without acceptance criteria
- writing acceptance criteria that cannot be checked
- making tasks so broad that they require unrelated verification stories
- delegating a clear execution task to a child slice owner when an implementer agent would be cheaper
- bloating the plan with workflow ceremony unrelated to the actual change

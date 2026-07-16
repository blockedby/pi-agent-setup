---
name: aad-plan-writing
description: Use for every AAD-owned job to create, execute, maintain, and audit a task-package plan with acceptance-driven tasks before delegation and done-state decisions.
---

# AAD Plan Writing

## Overview

Use this skill for every AAD-owned job. If the design is not settled enough to define execution, record the blocking questions and use narrow discovery or design refinement to settle them before implementation delegation.

The plan is the execution contract for the owner or slice owner, not optional preparation. Supporting agents remain optional and should appear only where they make continuation cheaper.

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
6. Use `aad-task-package` to create or update `<task-package>`.
7. Write the execution plan to `<task-package>/plan.md` with:
   - goal
   - scope and do-not-touch boundaries
   - task boundaries based on independently verifiable behavior
   - acceptance criteria and test plan per task
   - dependencies and optional delegation points only where they are genuinely cheaper
   - report paths for delegated agents
8. Check plan readiness before delegation: every task has a goal, acceptance criteria, evidence route, test plan, dependencies, executor, report path, and do-not-touch boundaries where relevant.
9. Execute only ready tasks from the plan and update task status, evidence, blockers, follow-ups, and deviations after every routed result.
10. Before done-state, audit every task and acceptance criterion against fresh evidence and write the plan scorecard.

## Mandatory planning lifecycle

Every root or slice owner must:

1. **Plan** — create `<task-package>/plan.md` before implementation delegation.
2. **Gate** — stop implementation dispatch until the plan is complete enough to execute and verify.
3. **Follow** — select ready work from the plan and pass the plan task into every routing packet.
4. **Update** — record child results, task status, evidence, blockers, and deviations before routing subsequent work.
5. **Audit** — compare the integrated result with every task and acceptance criterion.
6. **Score** — write the plan scorecard before any unqualified completion claim.

A small job may use one compact plan task. It may not omit the plan, acceptance criteria, evidence route, or final scorecard once an AAD owner is executing the job.

## Task sizing

A plan task is the smallest independently verifiable behavior change inside the current slice.

Do not size plan tasks by file count, estimated minutes, or mechanical edit steps. Size them by the behavior they make true and the primary verification that can prove it.

A good plan task is:

- small enough that one aad-implementer agent can execute it and return a complete acceptance verification report
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

Use an aad-implementer agent for a delegated plan task when the task is already clear enough to execute. Escalate a task to a child slice owner only when it needs its own planning, decomposition, coordination, or integration.

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

Evidence route:
- Existing automated checks first: <relevant existing tests/scripts/checks, or none found>
- If existing checks do not cover a criterion: <add/extend a test, run a bounded runtime/browser/container/API probe, use parent/user-held env or credential via HANDOFF, or accept a limited claim>
- Bounded acceptance probe: <smallest direct runtime/manual/browser/container/client reproduction that exercises the claim, or why not authorized/practical>
- Access/runtime needed: <env/profile/device/service/credential path needed, if any; executor/parent/user responsible for providing it>
- Outcome boundary: <what PASS/FAIL/HANDOFF/BLOCKED/limited claim can and cannot prove>

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
- <aad-implementer / browser-agent / aad-failure-classifier / child slice owner if too large>

Routed files:
- Report path: <task-package>/reports/<agent-or-task>.md
- Progress path: <task-package>/progress/<agent-or-task>.md or not needed

Execution status:
- Status: <pending / ready / running / done / blocked / follow-up>
- Evidence: <not run / exact test, check, artifact, or report reference>
- Deviation: <none / recorded scope, acceptance, dependency, executor, or verification change>
```

No meaningful plan task should omit acceptance criteria or a verification plan. If a criterion cannot be automated, state the manual evidence expected.

## Plan audit and scorecard

Before an owner claims done-state, append or update:

```md
## Plan scorecard
- Plan tasks completed: <completed>/<total>
- Acceptance criteria satisfied: <satisfied>/<total>
- Evidence routes passed: <passed>/<total>
- Deviations resolved or explicitly accepted: <resolved>/<total>
- Open blockers: <count>
- Final plan result: <pass / partial / fail / blocked>
```

Each total must link to the corresponding plan task, criterion, evidence, or deviation entry. A `partial`, `fail`, or `blocked` result, uncovered criterion, missing evidence route, or unresolved blocker prevents an unqualified completion claim.

## Plan rules

- Use `aad-task-package` for all durable plan/report/verification artifacts.
- Create and read `<task-package>/plan.md` before implementation delegation for every AAD-owned job.
- Do not dispatch implementation while required plan fields are missing, contradictory, or unverifiable.
- Follow ready plan tasks instead of inventing unrecorded work during execution.
- Update the plan after every routed result and before acting on a changed scope, acceptance criterion, dependency, executor, or verification route.
- Audit and score the completed work against the plan before done-state.
- Prefer one owner carrying the work when one owner can do it cheaply.
- Do not inject mandatory review loops or external workflow skills.
- Make verification explicit for each meaningful checkpoint.
- Tie acceptance criteria to tests or checks wherever possible.
- Prefer TDD for plan tasks where the repo has suitable test infrastructure.
- Include an Evidence route for each meaningful task: start with existing automated checks, then name the smallest bounded acceptance probe needed to exercise uncovered criteria.
- When existing tests do not cover a criterion, the plan must say whether to add or extend a test, run a bounded runtime/browser/container/API probe, use parent/user-held environment or credentials via `HANDOFF`, or accept a clearly limited claim.
- Evidence routes must name access/runtime needs, including required env, profile, device, service, credential path, and whether the executor, parent, or user supplies them.
- Evidence routes must state the outcome boundary: what the planned evidence can prove, what it cannot prove, and when the result should become `PASS`, `FAIL`, `HANDOFF`, `BLOCKED`, or a limited claim.
- Use checklist steps inside a task when that makes execution easier, but do not mistake mechanical checklist items for plan tasks.
- Record dependencies so the owner can later decide parallel execution waves.

## Common mistakes

- treating planning as optional because the requested change looks small
- delegating implementation before the plan-readiness gate passes
- following child output instead of updating and following the plan
- claiming done without auditing and scoring the plan
- turning the plan into generic advice
- forcing delegation where direct execution is cheaper
- leaving verification implicit
- splitting by mechanical file edits instead of independently verifiable behavior
- listing implementation tasks without acceptance criteria
- writing acceptance criteria that cannot be checked
- making tasks so broad that they require unrelated verification stories
- delegating a clear execution task to a child slice owner when an aad-implementer agent would be cheaper
- bloating the plan with workflow ceremony unrelated to the actual change

---
name: aad-plan-writing
description: Use for every AAD-owned job to locate or create one entrypoint-independent plan, define task dependencies and agent order, route plan context, maintain execution state, and audit done-state.
---

# AAD Plan Writing

## Overview

Use this skill for every AAD-owned job. If the design is not settled enough to define execution, record the blocking questions and use narrow discovery or design refinement to settle them before implementation delegation.


## Workflow

1. Locate the supplied or repo-local task package and `<task-package>/plan.md`.
   - If a plan exists, read it and preserve its settled scope, task IDs, evidence, agent order, and history.
   - If no plan exists, use `aad-task-package` to create the task package and become the initial plan coordinator.
2. Read the approved requirements, design notes, and local repo guidance.
3. Normalize the task:
   - goal
   - in-scope behavior
   - out-of-scope boundaries
   - done-state
   - known constraints and blocking unknowns
   - risk level: low-risk or risky/concurrent/destructive
4. When the risk gate in `aad-audit-convergence` applies, load it and record its frozen charter before implementation or concurrent dispatch.
5. Identify the files, components, services, data models, APIs, tests, or docs likely to change.
6. Identify existing patterns or reusable implementations the plan should follow.
7. Define the ownership model:
   - stays whole under the current owner
   - or splits into named slices with clear boundaries
8. Write or update `<task-package>/plan.md` with:
   - active plan coordinator
   - goal
   - scope and do-not-touch boundaries
   - task boundaries based on independently verifiable behavior
   - acceptance criteria and test plan per task
   - task dependencies
   - agent order, their delegation role
   - report paths for delegated agents
9. Check plan readiness before delegation: every task has a goal, acceptance criteria, evidence route, test plan, dependencies, executor, agent-order entry, plan context to pass, report path, and do-not-touch boundaries where relevant.
10. Execute only ready work in the recorded agent order. Keep the ignored canonical task package as the sole per-result routing ledger; batch any tracked phase-publication updates at phase boundaries instead of committing per routed result.
11. Before done-state, audit every task and acceptance criterion against fresh evidence and write the plan scorecard and readiness ladder.

## Mandatory planning lifecycle

Every root or slice owner must:

1. **Locate** — check for the task package and existing plan before writing a new one.
2. **Plan** — create `<task-package>/plan.md` only when it is absent; otherwise continue the existing plan.
3. **Gate** — stop implementation dispatch until the plan is complete enough to execute and verify.
4. **Order** — record which agent acts first, which agents depend on earlier results, which may overlap, and what plan context each receives.
5. **Route** — pass the whole plan or the exact assigned section plus every referenced dependency and contract field.
6. **Update** — the active plan coordinator records child results, task status, evidence, blockers, deviations, and any changed order in the ignored canonical ledger before subsequent routing. When repository policy requires tracked task documents, publish only consolidated phase snapshots (charter/planning, integrated implementation, baseline disposition, closure or escalation, final result); the tracked publication is not a second routing ledger.
7. **Audit** — compare the integrated result with every task and criterion. When `aad-audit-convergence` applies, follow its audit state machine and budget.
8. **Score** — write the plan scorecard and readiness ladder before any unqualified completion claim.

The first owner called is the initial plan coordinator when no plan exists. An owner receiving an existing plan does not replace it. Delegated children write their assigned report/progress files; they edit the plan only after an explicit coordination transfer recorded in the plan.

A small job may use one compact plan task. It may not omit the plan, acceptance criteria, evidence route, agent order when delegation occurs, or final scorecard once an AAD owner is executing the job.

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

## Agent order

Every plan that delegates work must contain an `Agent order` section. This is a task-specific dispatch graph, not a fixed reusable sequence. Derive it from task dependencies and update it when evidence changes the route.

Use one entry per owner, implementer, or supporting-agent call:

```md
## Agent order

### O1: <purpose>
- Agent: <aad-root-owner / aad-slice-owner / aad-implementer / supporting agent / owner action>
- Plan scope: <whole plan / slice name / task IDs / named sections>
- Starts after: <none / order IDs / external decision>
- Enables: <order IDs / done-state decision>
- Can run with: <none / order IDs>
- Receives: <whole plan or exact sections plus referenced dependencies>
- Returns to: <active plan coordinator / report path / next agent>
- Status: <pending / ready / running / done / blocked / skipped>
```

Order entries state consequence: an agent is ready only when every `Starts after` condition is satisfied. `Can run with` records safe concurrency but does not override dependencies. Before dispatch, the coordinator checks the current order, then passes:

- the whole plan when the child owns a broad slice, must integrate multiple tasks, or needs the complete decision history;
- the exact task/slice sections when the child has a narrow assignment, together with all referenced dependencies, acceptance criteria, evidence routes, constraints, and output paths.

If execution reveals a new prerequisite, different executor, or changed sequence, update the plan before dispatching under the new order. Do not rely on caller memory or chat-only ordering.

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
- Agent order entry: <O1 / O2 / ...>
- Plan context to pass: <whole plan / exact task and named supporting sections>

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
- Readiness rung reached: <implemented / owner-verified / independently accepted / runtime/full-suite accepted / merge-ready>
- Executable/product tree identity: <accepted identity / not applicable>
- Head reconciliation: <not needed / bounded docs-only passed / executable-product change requires reassessment>
- Final plan result: <pass / partial / fail / blocked>
```

Each total must link to the corresponding plan task, criterion, evidence, or deviation entry. A `partial`, `fail`, or `blocked` result, uncovered criterion, missing evidence route, or unresolved blocker prevents an unqualified completion claim.

## Plan rules

- Use `aad-task-package` for all durable plan/report/verification artifacts.
- Check for and read `<task-package>/plan.md` before implementation delegation for every AAD-owned job; create it only when absent.
- Keep one active plan coordinator and record any coordination transfer before a different owner edits the plan.
- Do not dispatch implementation while required plan fields are missing, contradictory, or unverifiable.
- Record every delegated call in `Agent order`, including prerequisites, safe concurrency, plan context, and return path.
- Follow ready plan tasks and order entries instead of inventing unrecorded work during execution.
- Pass the whole plan or a self-contained assigned section to every child; never pass an isolated task that omits referenced dependencies or constraints.
- Keep the ignored canonical ledger current after each routed result. When tracked task documents are required, batch consolidated phase-publication updates rather than creating a tracked write, commit, or exact-head audit target for each result; record a changed scope, acceptance criterion, dependency, executor, agent order, or verification route in the ignored ledger before acting on it.
- Audit and score completed work before done-state. When `aad-audit-convergence` applies, preserve its charter, budget, finding dispositions, product identity, and readiness state.
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
- creating a second plan because a different owner was called later
- leaving agent order implicit in chat or caller memory
- passing a child an isolated plan fragment without its referenced dependencies and constraints
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

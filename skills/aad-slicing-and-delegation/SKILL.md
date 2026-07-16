---
name: aad-slicing-and-delegation
description: Use when an AAD root orchestrator or slice owner must decide whether to keep work whole, split it into slices or sub-slices, or delegate to supporting agents while preserving ownership, dependencies, and routing context.
---

# AAD Slicing and Delegation

## Overview

Use this skill when you must choose the cheapest reliable ownership model for the current work.

The goal is not maximum delegation. The goal is stable ownership, clear routing, explicit dependencies, and cheap continuation.

A slice owner should separate decomposition from scheduling: slices define scope and ownership, while each task's `Depends on`, `Blocks`, and `Can run in parallel with` relationships describe its place in the wider plan.

## Plan readiness prerequisite

Do not delegate implementation, an owned slice, or supporting work that assumes an execution direction until `<task-package>/plan.md` contains the routed task, acceptance criteria, evidence route, test plan, dependencies, executor, report/progress paths, and relevant boundaries. Narrow discovery or design refinement may be delegated to complete the plan.

Before every delegation, read the current plan, confirm the task is `ready`, and copy its current contract into the routing packet. After every result, the owner updates the plan before routing dependent or changed work.

## Keep work whole when

- one local ownership boundary still holds
- one clear verification story still holds
- one owner can still carry the narrative cheaply
- slicing would add more orchestration than value
- dependency coordination would be more expensive than direct execution

## Slice when

- more than one local ownership boundary appears
- more than one independent verification story appears
- one owner would otherwise carry too many unrelated decisions
- the scope is too large or varied for one owner to carry cheaply
- a blocking subproblem needs focused ownership before the parent can continue

## Delegate supporting work when

- narrow discovery is cheaper than holding it in owner context
- narrow review is cheaper than doing it inline
- narrow verification audit is cheaper than carrying it yourself
- failure classification or browser evidence would make the next owner decision cheaper

Supporting agents help inside delegated scope. They do not take ownership.

## Dependency graph

When slicing or defining delegated tasks, record each task's relationship to prior, future, and parallel-safe work explicitly. Do not define a fixed wave structure or treat separate slices as automatically parallel. Use this shape for every task so each routing packet can stand on its own:

```md
Task A: <name>
- Goal: <what becomes true>
- Acceptance criteria: <short list or reference>
- Verify scope: <tests/checks/artifacts>
- Depends on: []
- Blocks: [C]
- Can run in parallel with: [B]
- Executor: <aad-implementer / support-agent / sub-slice-owner if too large>

Task B: <name>
- Goal: <what becomes true>
- Acceptance criteria: <short list or reference>
- Verify scope: <tests/checks/artifacts>
- Depends on: []
- Blocks: [C]
- Can run in parallel with: [A]
- Executor: <aad-implementer / support-agent / sub-slice-owner if too large>

Task C: <name>
- Goal: <what becomes true>
- Acceptance criteria: <short list or reference>
- Verify scope: <tests/checks/artifacts>
- Depends on: [A, B]
- Blocks: []
- Can run in parallel with: []
- Executor: <aad-implementer / support-agent / sub-slice-owner if too large>
```

`Depends on` names the earlier results this task needs. `Blocks` names the future work waiting on this task. `Can run in parallel with` names peers that planning has explicitly judged safe to overlap; list the relationship on both tasks so either packet remains understandable independently.

Before each delegation, re-evaluate these planned relationships. An item is ready when its `Depends on` items are complete. If two or more ready items explicitly list each other under `Can run in parallel with`, confirm that their shared contracts and boundaries are still settled, then dispatch them in one parallel `tasks: [...]` call. Otherwise use a single call or wait for the dependency.

## Dependency rules

- A task can run in parallel only when it does not require another task's unmerged implementation result.
- A frontend and backend slice may run in parallel if they share a settled contract; integration must depend on both.
- A test or CI failure fix may run in parallel with other fixes only when file ownership and root cause are independent.
- A blocker for the current goal becomes part of the active plan, not a follow-up.
- Non-blocking observations become follow-up issues and should not expand the active scope.

## Routing packet

Every delegated task should include all applicable routing context needed for safe execution.

Use this packet shape and fill all applicable fields:

```md
## Routing context
- Thread: <thread/request context>
- Slice: <parent slice / child slice name>
- Worktree: <path>
- Branch: <branch>
- Verify scope: <what evidence should prove this task>
- Review target: <diff/files/behavior to review, when relevant>

## Task package
- Task name: <task name>
- Task package path: <task-package or not used for trivial work>
- Canonical owner ledger: <task-package>/plan.md
- Report path: <task-package>/reports/<agent-or-task>.md
- Progress path: <task-package>/progress/<agent-or-task>.md, when relevant
- Verification artifact path: <task-package>/verification/<file>.md when relevant
- Runtime-state note: the default `.pi/aad/tasks/` contains canonical ignored AAD state; pi-subagents 0.34 `.pi-subagents/` debug artifacts are ignored compatibility output, not task packages

## Execution target
- Plan task goal: <specific delegated goal>
- Acceptance criteria: <criteria or plan references>
- Test plan: <positive/negative/edge/manual checks or plan references>
- Task relationships: <Depends on / Blocks / Can run in parallel with>
- Existing patterns or reusable files to follow: <paths/symbols>
- Do-not-touch boundaries: <files/areas/scope limits>
- Expected output format: <report/status format>

## pi-subagents options
- mode: <use tasks: [...] when two or more ready items explicitly list each other under Can run in parallel with; otherwise use a single call>
- concurrency: <explicit maximum for a parallel call; omit for a single call>
- reads: <plan/report files to pass into the agent>
- progress: <true for aad-implementer or long-running work>
- async: <whether the whole run continues in the background; true only for long-running work with report path and completion signal>
- worktree: <avoid for AAD implementation slices; use aad-worktree-management instead>
```

Pass all applicable fields. Supporting agents may refine their local target, but they do not redefine routing or ownership boundaries.

## Delegation checklist

- [ ] Read `<task-package>/plan.md` and confirm the delegated task is ready.
- [ ] Confirm acceptance criteria, evidence route, test plan, dependencies, executor, report/progress paths, and boundaries are present.
- [ ] Decide whether the work stays whole or should be sliced.
- [ ] If slicing, define one owner per slice or sub-slice.
- [ ] Give every task `Depends on`, `Blocks`, and `Can run in parallel with` relationships.
- [ ] Before dispatch, identify tasks whose `Depends on` items are complete.
- [ ] If two or more ready tasks explicitly list each other as parallel-safe, confirm the assumption and dispatch them in one parallel tasks call.
- [ ] If delegating support work, keep ownership at the delegating owner.
- [ ] Pass all applicable routing context.
- [ ] Delegate only the narrow work needed.
- [ ] Keep overlap acceptable and resolve it later during integration.
- [ ] Update the plan with the delegated status and later result before routing dependent work.

## Common mistakes

- delegating implementation before the plan-readiness gate passes
- routing work that is absent from the plan
- failing to update the plan after delegated results
- slicing for cosmetic reasons
- delegating because delegation exists, not because it is cheaper
- losing ownership when delegating support work
- passing incomplete routing context
- treating slices as execution waves or creating slices merely to manufacture parallelism
- serializing ready tasks that are explicitly marked safe to run in parallel
- running tasks in parallel when they share unsettled contracts
- treating non-blocking observations as permission to refactor


## Progress and async contract

For non-trivial routes, nominate one owner as the only writer of the canonical ledger at `<task-package>/plan.md`. Give every child unique report/progress files under the task package; the owner must read them before integrating, and children append only to their own files. The default `.pi/` task package is ignored canonical AAD state and is not committed. Pi-subagents 0.34 still creates `.pi-subagents/` debug artifacts upstream; that compatibility path is also ignored and is not the task package. Preserve raw evidence and diagnostics when a report is invalid, using `report-invalid` rather than an opaque task-failure status.

In interactive sessions, `async: true` means dispatch then return control: do not invoke blocking `wait` merely to keep the turn alive, and defer dependent dispatch until a completion or `needs_attention` event. Explicit synchronous requests and non-interactive one-turn aggregation may wait. This is prompt-level discipline; the installed runtime/UI ultimately controls input availability and cancellation semantics.

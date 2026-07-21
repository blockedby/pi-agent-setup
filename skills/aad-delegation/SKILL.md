---
name: aad-slicing-and-delegation
description: Use when an AAD delegate to supporting agents while preserving ownership, dependencies, and routing context.
---

# AAD Slicing and Delegation

## Overview

Use this skill when you must choose the best reliable ownership model for the current work.

The goal is stable ownership, clear routing, explicit dependencies, maximising speed and quality of agents computation.

An owner should separate decomposition from scheduling: slices define scope and ownership, while the plan's agent order and each task's `Depends on`, `Blocks`, and `Can run in parallel with` relationships describe who acts first, what follows, and what may overlap.

## Keep work one-thread when

- one task blocks another that could be parallelized
- delegating definitely duplicate work
- work in scope is straightforward: `aad-explorer` => `aad-implementer` => `aad-auditor` or smaller agents/skills chain is more than enough
- dependency coordination would be more expensive than direct execution

## Slice when

- more than one independent verification or ownership boundary appears; `aad-root-owner` for long-running complex multi-slice mission (epic, milestone), `aad-slice-owner` for rich multi-implementers work (PR); `aad-implementer` for scoped planned tasks (issue);
- the scope is too large or varied for one owner to carry cheaply
- implementing independent modules behind a settled interface
- a blocking subproblem needs focused ownership before the parent can continue
- no human intervention or attention needed, target is clear
- parallel bounded implementation slices with settled interfaces and disjoint write scopes gives implementing-speed benifits

## Delegate to subagents when

- deep or shallow exploration needs; many files or big log analysis needs; `aad-explorer` agent is always much cheaper and faster then direct tools calling
- `aad-auditor` subagents could run in parallel while independent test failures whose root causes and file ownership are distinct; they can provide separate verification in dimensions such as correctness, security, performance, accessibility, and reproduction 
- producing bounded “sidecar” work that can run while the parent performs useful local work.
- narrow discovery is cheaper than holding it in owner context
- calling many MCP tools or cli repeated calls to keep usefull context in owner's thread rather than tool calls metadata;
- audit/review benifits from having new context to provide independent opinion
- verification audit is cheaper than carrying it yourself

## Dependency graph

When slicing or defining **complex** delegated tasks, record each task's relationship to prior, future, and parallel-safe work explicitly, then map its executor into the `Agent order` section defined by `aad-plan-writing`. Do not define a fixed wave structure or treat separate slices as automatically parallel. Use this shape for every task so each routing packet can stand on its own:

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

`Depends on` names the earlier results this task needs.
`Blocks` names the future work waiting on this task. 
`Can run in parallel with` names peers that planning has explicitly judged safe to overlap; list the relationship on both tasks so either packet remains understandable independently.

Before each delegation, re-evaluate these planned relationships. An item is ready when its `Depends on` items are complete. If two or more ready items explicitly list each other under `Can run in parallel with`, confirm that their shared contracts and boundaries are still settled, then dispatch them in one parallel `tasks: [...]` call. Otherwise use a single call or wait for the dependency.

## Dependency rules

- A task can run in parallel only when it does not require another task's unmerged implementation result.
- A frontend and backend slice may run in parallel if they share a settled contract; integration must depend on both.
- A test or CI failure fix may run in parallel with other fixes only when file ownership and root cause are independent.
- A blocker for the current goal becomes part of the active plan, not a follow-up; tasks sequence could be changed from re-evaluate when blocker comes-up or paused if human interaction needed.
- Non-blocking observations become follow-up issues and should not expand the active scope.

## Routing packet

Every delegated task should include all applicable routing context needed for safe execution.

Use this packet shape and fill all applicable fields:

```md
## Routing context
- Thread: <thread/request context>
- Agent order entry: <O1 / O2 / ...>
- Slice: <parent slice / child slice name>
- Worktree: <path>
- Branch: <branch>
- Verify scope: <what evidence should prove this task>
- Review target: <diff/files/behavior to review, when relevant>

## Task package
- Task name: <task name>
- Task package path: <task-package or not used for trivial work>
- Canonical owner ledger: <task-package>/plan.md
- Active plan coordinator: <owner recorded in plan>
- Plan context passed: <whole plan / exact assigned sections plus referenced dependencies>
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
- reads: <plan/report files to pass into the agent context automatically>
- progress: <true for aad-implementer or long-running work>
- async: <whether the whole run continues in the background; true only for long-running work with report path and completion signal>
- worktree: <avoid for AAD implementation slices; use aad-git-branching instead>
```

Pass all applicable fields. Supporting agents may refine their local target, but they do not redefine routing or ownership boundaries.

## Delegation checklist

- [ ] Read `<task-package>/plan.md` and confirm the delegated agent-order entry is ready.
- [ ] Confirm acceptance criteria, evidence route, test plan, dependencies, executor, plan context, report/progress paths, and boundaries are present.
- [ ] Pass the whole plan or a self-contained assigned section with every referenced dependency and constraint.
- [ ] Decide whether the work stays whole or should be sliced.
- [ ] If slicing, define one owner per slice or sub-slice.
- [ ] Give every task `Depends on`, `Blocks`, and `Can run in parallel with` relationships.
- [ ] Before dispatch, identify tasks whose `Depends on` items are complete.
- [ ] If two or more ready tasks explicitly list each other as parallel-safe, confirm the assumption and dispatch them in one parallel tasks call.
- [ ] If delegating support work, keep ownership at the delegating owner.
- [ ] Pass all applicable routing context.
- [ ] Delegate only the narrow work needed.
- [ ] Keep overlap acceptable and resolve it later during integration.
- [ ] The active plan coordinator updates the plan with the delegated status and later result before routing dependent work.

## Common mistakes

- delegating implementation before the plan-readiness gate passes
- routing work that is absent from the plan or its agent order
- passing a plan fragment without its referenced dependencies or constraints
- treating receipt of plan context as an implicit coordination transfer
- failing to update the plan after delegated results
- slicing for cosmetic reasons
- delegating because delegation exists, not because it is cheaper
- losing ownership when delegating support work
- passing incomplete routing context
- treating slices as execution waves or creating slices merely to manufacture parallelism
- serializing ready tasks that are explicitly marked safe to run in parallel
- running tasks in parallel when they share unsettled contracts
- treating non-blocking observations as permission to refactor
- using pi-subagents `worktree: true` for AAD implementation slices; use `aad-git-branching` so parent/child worktree lineage stays explicit

## Progress and async contract

For non-trivial routes, follow the active plan-coordinator contract in `aad-task-package`. Give every child unique report/progress files; the coordinator reads them before integration, and children append only to their own files unless coordination was explicitly transferred. Preserve raw evidence and diagnostics when a report is invalid, using `report-invalid` rather than an opaque task-failure status.

In interactive sessions, `async: true` means dispatch then return control: do not invoke blocking `wait` merely to keep the turn alive, and defer dependent dispatch until a completion or `needs_attention` event. Explicit synchronous requests and non-interactive one-turn aggregation may wait. This is prompt-level discipline; the installed runtime/UI ultimately controls input availability and cancellation semantics.

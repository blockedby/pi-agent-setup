---
name: aad-slicing-and-delegation
description: Use when an AAD root orchestrator or slice owner must decide whether to keep work whole, split it into slices or sub-slices, or delegate to supporting agents while preserving ownership, dependencies, and routing context.
---

# AAD Slicing and Delegation

## Overview

Use this skill when you must choose the cheapest reliable ownership model for the current work.

The goal is not maximum delegation. The goal is stable ownership, clear routing, explicit dependencies, and cheap continuation.

A slice owner should separate decomposition from scheduling: slices define scope and ownership, while dependencies and conflicts determine what can safely run at the same time.

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

When slicing or defining delegated tasks, record dependencies and known execution conflicts explicitly. Do not define a fixed wave structure or treat separate slices as automatically parallel. Use a compact shape like:

```md
Task A: <name>
- Goal: <what becomes true>
- Acceptance criteria: <short list or reference>
- Verify scope: <tests/checks/artifacts>
- Depends on: []
- Conflicts with: []
- Executor: <aad-implementer / support-agent / sub-slice-owner if too large>

Task B: <name>
- Depends on: []
- Conflicts with: []

Task C: <name>
- Depends on: [A, B]
- Conflicts with: []
```

Before each delegation, re-evaluate which work items can safely start now. An item is ready when its dependencies are complete and required contracts are settled. Ready items may run together only when they do not conflict over files, resources, or decisions. If two or more items meet those conditions, dispatch them in one parallel `tasks: [...]` call; otherwise use a single call or wait for the dependency.

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
- Task package path: <docs/plans/YYYY-MM-DD-slug>
- Plan path: <task-package>/plan.md
- Report path: <task-package>/reports/<agent-or-task>.md
- Progress path: <task-package>/progress/<agent-or-task>.md, when relevant
- Verification artifact path: <task-package>/verification/<file>.md, when relevant

## Execution target
- Plan task goal: <specific delegated goal>
- Acceptance criteria: <criteria or plan references>
- Test plan: <positive/negative/edge/manual checks or plan references>
- Dependencies and blockers: <upstream/downstream dependencies>
- Existing patterns or reusable files to follow: <paths/symbols>
- Do-not-touch boundaries: <files/areas/scope limits>
- Expected output format: <report/status format>

## pi-subagents options
- mode: <use tasks: [...] when this dispatch has two or more ready, non-conflicting items; otherwise use a single call>
- concurrency: <explicit maximum for a parallel call; omit for a single call>
- reads: <plan/report files to pass into the agent>
- progress: <true for aad-implementer or long-running work>
- async: <whether the whole run continues in the background; true only for long-running work with report path and completion signal>
- worktree: <avoid for AAD implementation slices; use aad-worktree-management instead>
```

Pass all applicable fields. Supporting agents may refine their local target, but they do not redefine routing or ownership boundaries.

## Delegation checklist

- [ ] Decide whether the work stays whole or should be sliced.
- [ ] If slicing, define one owner per slice or sub-slice.
- [ ] Record dependencies, blockers, and known execution conflicts.
- [ ] Before dispatch, identify the work items that can safely start now.
- [ ] If two or more ready items do not conflict, dispatch them in one parallel tasks call.
- [ ] If delegating support work, keep ownership at the delegating owner.
- [ ] Pass all applicable routing context.
- [ ] Delegate only the narrow work needed.
- [ ] Keep overlap acceptable and resolve it later during integration.

## Common mistakes

- slicing for cosmetic reasons
- delegating because delegation exists, not because it is cheaper
- losing ownership when delegating support work
- passing incomplete routing context
- treating slices as execution waves or creating slices merely to manufacture parallelism
- serializing ready, non-conflicting tasks that could be dispatched together
- running tasks in parallel when they share unsettled contracts
- treating non-blocking observations as permission to refactor

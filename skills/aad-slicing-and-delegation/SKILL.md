---
name: aad-slicing-and-delegation
description: Use when an AAD root orchestrator or slice owner must decide whether to keep work whole, split it into slices or sub-slices, or delegate to supporting agents while preserving ownership, dependencies, and routing context.
---

# AAD Slicing and Delegation

## Overview

Use this skill when you must choose the cheapest reliable ownership model for the current work.

The goal is not maximum delegation. The goal is stable ownership, clear routing, explicit dependencies, and cheap continuation.

A slice owner should understand not only whether work should be split, but also which split pieces can move in parallel and which pieces must wait.

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
- parts can move in parallel without constant coordination
- a blocking subproblem needs focused ownership before the parent can continue

## Delegate supporting work when

- narrow discovery is cheaper than holding it in owner context
- narrow review is cheaper than doing it inline
- narrow verification audit is cheaper than carrying it yourself
- failure classification or browser evidence would make the next owner decision cheaper

Supporting agents help inside delegated scope. They do not take ownership.

## Dependency graph

When slicing, record the dependency graph explicitly. Use a compact shape like:

```md
Task A: <name>
- Goal: <what becomes true>
- Acceptance criteria: <short list or reference>
- Verify scope: <tests/checks/artifacts>
- Depends on: []
- Blocks: [C]
- Can run parallel with: [B]
- Executor: <implementer / support-agent / sub-slice-owner if too large>

Task B: <name>
- Depends on: []
- Blocks: [C]
- Can run parallel with: [A]

Task C: <name>
- Depends on: [A, B]
- Blocks: []
```

Then define execution waves:

```md
Execution waves:
- Wave 1: A, B in parallel
- Wave 2: C after A+B
- Wave 3: final integration and verification
```

Only create waves when parallel execution is actually useful. For small work, a direct ordered checklist is cheaper.

## Dependency rules

- A task can run in parallel only when it does not require another task's unmerged implementation result.
- A frontend and backend slice may run in parallel if they share a settled contract; integration must depend on both.
- A test or CI failure fix may run in parallel with other fixes only when file ownership and root cause are independent.
- A blocker for the current goal becomes part of the active plan, not a follow-up.
- Non-blocking observations become follow-up issues and should not expand the active scope.

## Routing packet

Every delegated task should include all applicable routing context needed for safe execution:

- Thread
- Slice
- Worktree
- Branch
- Verify scope
- Review target
- Task name
- Task package path
- Report path
- Verification artifact path, when relevant
- Acceptance criteria
- Dependencies
- Do-not-touch boundaries

Pass all applicable fields. Supporting agents may refine their local target, but they do not redefine routing or ownership boundaries.

## Delegation checklist

- [ ] Decide whether the work stays whole or should be sliced.
- [ ] If slicing, define one owner per slice or sub-slice.
- [ ] Record dependencies, blockers, and parallel-safe tasks.
- [ ] Define execution waves when useful.
- [ ] If delegating support work, keep ownership at the delegating owner.
- [ ] Pass all applicable routing context.
- [ ] Delegate only the narrow work needed.
- [ ] Keep overlap acceptable and resolve it later during integration.

## Common mistakes

- slicing for cosmetic reasons
- delegating because delegation exists, not because it is cheaper
- losing ownership when delegating support work
- passing incomplete routing context
- running tasks in parallel when they share unsettled contracts
- treating non-blocking observations as permission to refactor

---
name: aad-slicing-and-delegation
description: Use when an AAD root orchestrator or slice owner must decide whether to keep work whole, split it into slices or sub-slices, or delegate to supporting agents while preserving ownership and routing context.
---

# AAD Slicing and Delegation

## Overview

Use this skill when you must choose the cheapest reliable ownership model for the current work.

The goal is not maximum delegation. The goal is stable ownership, clear routing, and cheap continuation.

## Keep work whole when

- one local ownership boundary still holds
- one clear verification story still holds
- one owner can still carry the narrative cheaply
- slicing would add more orchestration than value

## Slice when

- more than one local ownership boundary appears
- more than one independent verification story appears
- one owner would otherwise carry too many unrelated decisions
- parts can move in parallel without constant coordination

## Delegate supporting work when

- narrow discovery is cheaper than holding it in owner context
- narrow review is cheaper than doing it inline
- narrow verification audit is cheaper than carrying it yourself

Supporting agents help inside delegated scope. They do not take ownership.

## Routing packet

Every delegated task should include all applicable routing context needed for safe execution:

- Thread
- Slice
- Worktree
- Branch
- Verify scope
- Review target

Pass all applicable fields. Supporting agents may refine their local target, but they do not redefine routing or ownership boundaries.

## Delegation checklist

- [ ] Decide whether the work stays whole or should be sliced.
- [ ] If slicing, define one owner per slice or sub-slice.
- [ ] If delegating support work, keep ownership at the delegating owner.
- [ ] Pass all applicable routing context.
- [ ] Delegate only the narrow work needed.
- [ ] Keep overlap acceptable and resolve it later during integration.

## Common mistakes

- slicing for cosmetic reasons
- delegating because delegation exists, not because it is cheaper
- losing ownership when delegating support work
- passing incomplete routing context

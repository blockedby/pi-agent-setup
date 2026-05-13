---
name: aad-verification
description: Use before claiming completion, closure, or correctness so AAD work reports results from fresh evidence instead of assumption.
---

# AAD Verification

## Overview

Use this skill before claiming that work is complete, fixed, reviewed, or ready.

Evidence comes before claims.

## Workflow

1. Identify the exact command, check, or artifact that proves the claim.
2. Run that check freshly.
3. Read the actual result, including failures.
4. State the real status with evidence.
5. Only then claim completion, readiness, or closure.

## Rules

- Fresh verification beats memory.
- Narrow verification is fine when it directly proves the changed path.
- If the proving check fails, report failure instead of softening it.
- Do not rely on earlier runs once new changes have been made.

## Common mistakes

- saying something should pass without running it
- relying on stale output
- claiming closure from partial evidence
- treating confidence as proof

---
name: aad-systematic-debugging
description: Use when an AAD owner or supporting agent hits unclear, broken, or contradictory behavior and needs a disciplined local debugging loop.
---

# AAD Systematic Debugging

## Overview

Use this skill when safe progress stops because behavior is unclear or broken.

The goal is to replace guessing with a short evidence-driven debugging loop.

## Workflow

1. State the exact symptom.
2. Reproduce it with the narrowest reliable check.
3. Identify the most likely local cause.
4. Test that hypothesis directly.
5. Fix the smallest confirmed cause.
6. Re-run the proving check and any relevant regression check.

## Rules

- Do not claim a root cause without evidence.
- Prefer narrow checks over broad test suites while isolating the problem.
- Keep the fix scoped to the confirmed cause until evidence requires more.
- Ask for help only when the blocker is external or the reproduction cannot be made reliable.

## Common mistakes

- debugging by intuition alone
- changing multiple things before the cause is confirmed
- running broad verification too early instead of isolating first
- calling the issue resolved without re-running the proving check

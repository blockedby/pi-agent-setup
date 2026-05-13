---
name: aad-review-handling
description: Use when an AAD owner needs to process review findings technically and efficiently without mandatory review ping-pong.
---

# AAD Review Handling

## Overview

Use this skill when review feedback exists and you need to decide what to fix, what to question, and what to track.

The goal is technical correctness and cheap continuation, not performative agreement.

## Workflow

1. Read all findings fully.
2. Classify each finding:
   - correct and fix now
   - unclear and needs one targeted question
   - incorrect and should be pushed back on with evidence
   - valid but outside current scope and should become explicit follow-up
3. Verify disputed findings against the current code and requirements.
4. Apply the smallest correct fix for accepted findings.
5. Re-verify the affected behavior.
6. Report the outcome factually.

## Rules

- Do not agree performatively before verification.
- Do not create mandatory re-review loops unless the current workflow actually needs them.
- Keep accepted fixes in current scope and turn real extras into follow-up.
- Push back briefly and technically when the feedback is wrong.

## Common mistakes

- accepting feedback before checking it
- turning review into a social ritual
- fixing optional ideas as if they were blockers
- reopening broad redesign during a narrow fix pass

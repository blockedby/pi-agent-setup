---
name: aad-failure-classification
description: Use when an AAD owner or diagnostic agent needs to classify a concrete failing test, command, CI job, or agent attempt from evidence without taking ownership of the fix.
---

# AAD Failure Classification

## Overview

Use this skill for narrow classification of a concrete failure.

This skill is not a problem investigation workflow and not an implementation plan. It answers: what kind of failure is this, how confident are we, and what should the owner route next?

## When to use

Use when there is concrete failure evidence:

- failing test output
- failing CI job
- failed command
- failed implementer attempt
- error log or stack trace
- repeated agent loop or stalled attempt

Do not use for broad design concerns, side observations without a failed check, or normal feature planning. Use `aad-problem-investigation` or owner discovery for those.

## Categories

- `CODE_BUG`: product/application implementation is wrong or incomplete.
- `TEST_CONTRACT`: the test encodes a valid product contract; implementation should adapt to satisfy it.
- `TEST_BUG`: the test is wrong, ambiguous, stale, or inconsistent with the accepted spec.
- `INFRA`: service, dependency, env var, network, permission, filesystem, CI, tool, or environment issue.
- `SCOPE_GAP`: story/spec lacks required information or has contradictory requirements.
- `AGENT_LOOP`: worker repeated the same failed approach, thrashed files, or stalled without new evidence.
- `SECURITY_BLOCKER`: secrets, credentials, access, or private data are required; do not invent or expose them.
- `UNKNOWN`: evidence is insufficient or contradictory.

## Classification rules

1. Classify from evidence, not intuition.
2. Prefer the narrowest category that explains the failure.
3. If multiple failures are present, classify each failure separately.
4. Do not recommend changing tests unless the classification is `TEST_BUG` or the owner has explicitly requested test-contract work.
5. Do not decide final routing for the slice; recommend a next owner action.
6. Do not fix code or tests while classifying.
7. If secrets or access are needed, classify as `SECURITY_BLOCKER` and stop.

## Output format

```text
FAILURE_ID: <id-or-short-name>
CLASSIFICATION: CODE_BUG|TEST_CONTRACT|TEST_BUG|INFRA|SCOPE_GAP|AGENT_LOOP|SECURITY_BLOCKER|UNKNOWN
CONFIDENCE: high|medium|low
ROOT_CAUSE: <1-3 sentences>
EVIDENCE:
- <file/log/test/diff evidence>
NEXT_OWNER_ACTION: <exact recommended routing/action for the owner>
RETRY_ALLOWED: yes|no
MODEL_ESCALATION: none|stronger-model|human
```

For multiple failures, repeat the block per failure and add:

```text
SUMMARY:
- total: <n>
- code bugs: <n>
- test bugs: <n>
- infra/security/scope blockers: <n>
```

## Common mistakes

- treating every failure as a code bug
- rewriting the implementation plan instead of classifying the failure
- recommending test changes without evidence that the test is wrong
- hiding insufficient evidence behind a confident classification
- retrying an agent loop without changing the approach

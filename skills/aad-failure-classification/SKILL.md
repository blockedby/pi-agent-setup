---
name: aad-failure-classification
description: Use for narrow evidence-based classification of a concrete failing test, command, CI job, log, or repeated agent attempt without editing source or owning the fix.
---

# AAD Failure Classification

Use only with concrete failure evidence.

## Categories

- `CODE_BUG`
- `TEST_CONTRACT`
- `TEST_BUG`
- `INFRA`
- `SCOPE_GAP`
- `AGENT_LOOP`
- `SECURITY_BLOCKER`
- `UNKNOWN`

## Result

```text
FAILURE_ID:
CLASSIFICATION:
CONFIDENCE: high|medium|low
ROOT_CAUSE:
EVIDENCE:
- ...
NEXT_OWNER_ACTION:
RETRY_ALLOWED: yes|no
MODEL_ESCALATION: none|sol-high|human
```

## Rules

- Classify from evidence, not intuition.
- Split independent failures.
- Do not edit code/tests or dispatch agents.
- Do not recommend changing tests without evidence the test is wrong.
- For an agent loop, require a changed hypothesis, task packet, model profile, or evidence route before retry.
- Use `SECURITY_BLOCKER` for unavailable or unauthorized secrets/access.

---
name: aad-systematic-debugging
description: Use when behavior is broken, unclear, or contradictory; reproduce narrowly, test one hypothesis at a time, preserve evidence across model escalation, and stop repeated agent loops.
---

# AAD Systematic Debugging

Replace guessing with a short evidence loop.

1. State the exact symptom.
2. Reproduce it with the narrowest reliable check.
3. Collect the relevant diff/log/runtime evidence.
4. Form one testable hypothesis.
5. Test it without changing multiple variables.
6. Apply the smallest confirmed fix.
7. Re-run the proving check and affected regression checks.

## Model escalation

Escalate from Terra high to Sol high when:

- evidence contradicts itself;
- security, permissions, migration, persistent data, or data-loss risk appears;
- one evidence-backed Terra attempt did not resolve the issue;
- root cause crosses system contracts.

Pass the reproduction, failed hypotheses, exact evidence, and approaches not to repeat. Do not restart discovery from zero.

## Agent loops

Use the failure classifier when an agent repeats the same failed approach, thrashes files, or stops producing new evidence. Do not retry unchanged instructions on a stronger model as a substitute for diagnosis.

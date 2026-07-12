---
name: aad-design-refinement
description: Use when a real AAD goal is still too ambiguous to implement safely; converge on one recommended approach and select NONE, INFORM, CONSULT, or APPROVE without turning refinement into a long ceremony.
---

# AAD Design Refinement

Produce only enough clarity to route and execute safely.

1. Read relevant repository context.
2. Separate settled facts from consequential ambiguity.
3. Prefer one recommended approach.
4. Choose the human gate:
   - `NONE` for safe autonomous inference;
   - `INFORM` for a non-blocking route/plan update;
   - `CONSULT` for one material product/architecture decision;
   - `APPROVE` for an approval-gated action.
5. Record goal, constraints, approach, main risks, and verification story in the task record.

Do not ask about low-consequence details already answered by repository patterns. Do not write a spec-sized document for a small implementation decision.

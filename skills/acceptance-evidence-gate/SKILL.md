---
name: acceptance-evidence-gate
description: Use by an independent auditor at a Slice or Root boundary to map acceptance claims to fresh evidence, choose compact or full-risk depth, and return one evidence-based verdict without implementing fixes.
---

# Acceptance Evidence Gate

Every Slice and Root boundary uses an independent auditor context.

## Compact audit

Default for an ordinary slice:

```md
## Audit
- Verdict: accepted / accepted with limitations / not accepted / blocked
- Evidence reviewed: <task record, diff, checks, specialist artifacts>

| AC | Evidence | Result | Gap |
| --- | --- | --- | --- |

- Required next action: <none or exact action>
```

Do not create a separate acceptance plan when acceptance criteria already exist.

## Full-risk audit

Use full-risk depth for:

- security or permissions;
- persisted data or migrations;
- data-loss/destructive risk;
- external integrations;
- runtime/deployment wiring;
- contradictory evidence;
- root integration;
- high-visibility public visual work.

Add only relevant readiness dimensions. Do not emit a universal checklist full of `not applicable`.

## Browser and visual work

Browser automation/evidence comes from a separate browser agent. For visual acceptance require:

- current screenshots for the selected browser mode;
- worst-screenshot reasoning;
- unresolved hard failures absent;
- visual critic verdict resolved.

Technical metrics cannot overrule an obvious screenshot failure.

## Re-audit

After a focused fix, inspect only changed or previously failed criteria unless integration changed the wider system.

## Guardrails

Do not accept when:

- an AC lacks relevant evidence;
- evidence is stale;
- a broad check does not exercise changed behavior;
- a failure is hidden or unclassified;
- a waiver lacks source, scope, consequence, or date;
- browser/visual evidence required by the route is absent.

The auditor does not implement fixes or redefine scope.

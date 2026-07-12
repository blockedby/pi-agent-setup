---
name: aad-reporting
description: Use when an owner or specialist must return a compact reusable result with verdict, scope, evidence, caveats, and next action; sections are optional and repetition is forbidden.
---

# AAD Reporting

A report is a continuation packet, not a diary.

## Minimum result

Always preserve:

```md
## Result
- Verdict: <success / partial / blocked / failed / accepted / not accepted>
- Changed or inspected: <scope>
- Fresh evidence: <checks/artifacts or unavailable>
- Material caveats: <none or exact limitations>
- Next action: <none or one immediate action>
```

## Optional sections

Add only when they carry information:

- `Acceptance coverage`
- `System readiness`
- `Issues`
- `Decisions`
- `Handoff`
- `Files changed`
- `Commits`
- `Browser evidence`
- `Model escalation`

Do not emit empty or `not applicable` sections merely because a template contains them.

## Evidence rows

Use compact rows:

```md
| Claim / AC | Evidence | Result | Freshness / gap |
| --- | --- | --- | --- |
```

One fact should appear once. Reference the specialist file instead of copying it.

## Owner reports

Owners update `.pi/aad/<task-id>/task.md` and return a short chat summary. They integrate child outcomes into the acceptance table without reproducing every child explanation.

## Specialist reports

A specialist reports only its delegated question, evidence, conclusion, uncertainty, and recommended owner action. It does not produce root/slice readiness sections outside its authority.

## Continuation

Include a Handoff only when work remains:

```md
## Handoff
- Settled:
- Remaining:
- Exact next action:
- Evidence to reuse:
- Do not repeat:
- Stop condition:
```

## Rules

- State failures and unavailable checks plainly.
- Distinguish `zero`, `not collected`, and `unavailable`.
- Do not turn current status into a second final report.
- Do not claim acceptance from implementation activity.

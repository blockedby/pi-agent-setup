---
name: aad-audit-convergence
description: Use when planning, routing, auditing, or completing risky, concurrent, destructive, security/privacy-sensitive, or data-loss-sensitive AAD work that needs a frozen acceptance charter and a finite independent-audit route.
---

# AAD Audit Convergence

Keep independent review adversarial but finite. This skill defines the shared contract; owner, auditor, planning, delegation, reporting, and completion prompts should reference it rather than restating it.

## Risk gate

Use this contract for work with concurrency, destructive effects, security/privacy boundaries, data-loss risk, or another reason independent acceptance must be stable before runtime effects or merge.

For low-risk, reversible work, existing acceptance criteria may be the compact target. Use proportionate evidence and do not add independent audits without a repository or task requirement.

## Freeze the charter

Before implementation or concurrent dispatch, the owner records:

```md
## Frozen acceptance charter
- Risk trigger: <why this contract applies>
- Criteria/invariants: <stable AC-* / INV-* IDs>
- Threat boundaries: <security, privacy, data-loss, concurrency, destructive effects>
- Evidence map: <criterion ID → direct check or artifact>
- Product identity: <accepted commit/ref plus explicit product path set and digest>
- Scope boundary: <what audit must not silently add>
- Required readiness: <target state>
```

The owner may clarify wording without changing meaning. A material scope, invariant, or threat-boundary change requires an explicit human/architect decision or successor charter; do not absorb it silently into the active target.

## Audit modes and budget

Normal budget: one baseline audit and, only when baseline remediation is required, one closure audit.

| Mode | Allowed scope | Terminal result |
| --- | --- | --- |
| `baseline` | Full frozen charter | accepted, accepted with limitations, or stable `AUD-*` findings |
| `closure` | Baseline finding IDs plus remediation-caused regressions | accepted, accepted with limitations, or escalation |
| `docs-reconcile` | Approved documentation-only delta from an accepted product identity | reconciled or product change detected |

`docs-reconcile` is not another audit. A closure audit must not reopen broad discovery or create audit 3.

A baseline finding records:

```md
- ID: AUD-<number>
- Charter mapping: <AC-* / INV-* / critical exception>
- Severity and consequence: <...>
- Proof: <minimal reproduction or static evidence>
- Closure test: <exact bounded evidence>
- Recommended disposition: <remediate / follow-up / escalate>
```

The owner decides disposition:

- in-charter blocker → one remediation batch, then closure;
- noncritical out-of-charter observation → follow-up;
- critical security, privacy, or data-loss issue → human/architect decision or successor charter;
- remediation regression unresolved at closure → human/architect decision or successor charter.

After closure, stop. Do not schedule another audit under the same charter.

## Product identity and documentation reconciliation

Bind code acceptance to an accepted commit/ref plus an explicit executable/product path set and digest. A whole-repository Git tree may be supporting provenance, but it is not the product identity when approved evidence-only documents are excluded.

For a later documentation-only head:

1. identify accepted and current heads;
2. list changed paths;
3. prove every change is an approved documentation/evidence path;
4. recompute and compare the product path-set digest;
5. reconcile without a full code audit when the digest is unchanged.

Any product-path change leaves reconciliation mode and requires an owner-chosen chartered route.

## Readiness states

Report only the highest evidence-backed state:

1. `implemented`
2. `owner-verified`
3. `independently accepted` — when independent audit is required
4. `runtime/full-suite accepted` — when required runtime and broad checks pass
5. `merge-ready` — all required prior states, finding dispositions, and branch rules are satisfied

Do not use implementation or a narrow green check as evidence for a higher state.

## Task-state publication

Use `aad-task-package` for the filesystem contract. Raw child reports, progress, and repeated evidence stay in the ignored canonical ledger. Tracked plans/reports are sanitized phase publications and must not create a new exact-head audit target per child result.

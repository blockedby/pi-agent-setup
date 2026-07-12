---
name: aad-verification
description: Use before claiming fixed, ready, complete, or correct; select and run the narrowest fresh proof for each acceptance claim and record only material evidence in the local task record.
---

# AAD Verification

Evidence precedes claims.

## Workflow

1. Name the exact claim or acceptance criterion.
2. Select the narrowest check that exercises it.
3. Run the check after the relevant change.
4. Read the real result.
5. Record evidence and freshness in the task record or specialist output.
6. Broaden verification only when integration or risk requires it.

## Evidence priority

- targeted automated test;
- focused build/lint/typecheck/static check;
- bounded API/runtime/container/client probe;
- separate browser evidence;
- explicit manual evidence;
- explicit waiver with owner, scope, consequence, and date.

Broad green checks do not replace a missing targeted proof.

## Terminal outcomes

Before `PASS`, `HANDOFF`, `BLOCKED`, `ready`, or `done`, execute the planned evidence route or state why it was unavailable and what the limitation means.

A failed proving check is evidence. Report it; do not soften it.

## Freshness

Re-run affected checks after:

- implementation changes;
- conflict resolution;
- a content-changing rebase;
- integration of child work;
- a focused audit fix.

Do not rerun unrelated broad checks merely for ceremony.

---
name: aad-integration
description: Use when a root or parent slice owner must integrate distinct child outcomes, resolve overlap, rerun affected proof, and update one parent task record without copying child reports.
---

# AAD Integration

Integration converts child outcomes into one parent state.

## Steps

1. Read child records as evidence packets.
2. Integrate implementation changes into the parent worktree.
3. Resolve conflicting assumptions, files, contracts, or acceptance claims.
4. Reference child evidence from the parent acceptance table; do not copy full reports.
5. Re-run checks affected by integration.
6. Classify remaining issues as current blockers or non-blocking follow-ups.
7. Send the integrated state to the independent boundary auditor.
8. Update the parent verdict from the integrated evidence and audit.

## Rules

- Do not reopen broad discovery without a concrete integration gap.
- Do not count a child `PASS` as parent acceptance.
- A child `HANDOFF` is actionable parent work when authorized, not automatic failure.
- Re-audit only what integration or follow-up fixes changed.
- Preserve one root narrative and one final root verdict.

---
name: aad-integration
description: Use when an AAD root orchestrator or slice owner must integrate child slice, sub-slice, or supporting-agent results back into a parent scope and decide the parent done-state.
---

# AAD Integration

## Overview

Use this skill when child results have returned and you need to decide what the parent scope now knows, what is done, what remains follow-up, and what stays unresolved.

Integration is where overlap is resolved and parent done-state is decided. Use `aad-task-package` when child reports or verification artifacts belong in a task package.

## Integration steps

1. Read child reports as continuation packets.
2. Save or link child reports in the parent task package when a task package exists.
3. Extract completed outcomes that now count for the parent scope.
4. Merge or otherwise integrate child implementation results into the parent slice worktree/branch before target-branch preparation.
5. Merge `R-*`, `F-*`, and `U-*` into the parent picture.
6. Resolve overlap between child results without reopening unnecessary rediscovery.
7. Update `<task-package>/plan.md` with integrated task status, verification evidence, blockers, and follow-ups when a task package exists.
8. Rerun the parent-level verification needed after integration.
9. Decide whether the parent goal is now fully achieved, partially achieved, or still not achieved.
10. Produce a parent report with `aad-reporting`.

## Integration checklist

- [ ] I know which child results now count as completed for the parent.
- [ ] I know which follow-ups survive at parent scope.
- [ ] I know which unresolved issues still block the parent goal.
- [ ] I integrated child implementation results into the parent slice worktree/branch, not directly into the final target branch.
- [ ] I resolved overlap instead of duplicating it in the parent report.
- [ ] I reran needed parent verification after child-result integration.
- [ ] I updated the parent done-state based on integrated evidence.

## Common mistakes

- treating child reports as loose notes instead of reusable packets
- reopening broad discovery during integration
- duplicating overlapping issues without resolving them
- declaring parent completion before child unresolved issues are integrated


## File-backed integration rule

For non-trivial work, first read the canonical parent ledger—`<task-package>/plan.md` when committed task docs are required, otherwise `.pi-subagents/routes/<task-id>/<route-id>.md`—and every routed child report/progress file it names. Treat inline child output and harness artifact locations as supplementary only. `.pi-subagents/` is ignored generated runtime state and is not committed. Preserve a child report that is `report-invalid`: record the validation diagnostic separately and integrate any readable findings/evidence rather than treating it as an opaque child failure. The parent owner alone updates the canonical ledger after this read.

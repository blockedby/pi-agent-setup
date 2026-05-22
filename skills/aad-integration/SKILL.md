---
name: aad-integration
description: Use when an AAD root orchestrator or slice owner must integrate child slice, sub-slice, or supporting-agent results back into a parent scope and decide the parent done-state.
---

# AAD Integration

## Overview

Use this skill when child results have returned and you need to decide what the parent scope now knows, what is done, what remains follow-up, and what stays unresolved.

Integration is where overlap is resolved and parent done-state is decided.

## Integration steps

1. Read child reports as continuation packets.
2. Extract completed outcomes that now count for the parent scope.
3. Merge or otherwise integrate child implementation results into the parent slice worktree/branch before target-branch preparation.
4. Merge `R-*`, `F-*`, and `U-*` into the parent picture.
5. Resolve overlap between child results without reopening unnecessary rediscovery.
6. Rerun the parent-level verification needed after integration.
7. Decide whether the parent goal is now fully achieved, partially achieved, or still not achieved.
8. Produce a parent report with `aad-reporting`.

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

---
name: aad-problem-investigation
description: AAD support workflow for investigating a bug, failing test, suspicious behavior, or side finding before deciding whether it is a current-goal blocker, follow-up, false alarm, or scoped fix task.
---

## aad-explorer

Investigate the reported problem read-only. Gather direct evidence only: reproduction steps, failing command or observed behavior, relevant files/symbols, logs, linked task package context, existing similar code, and known project patterns. If a Task package path is provided, write the evidence report to `<task-package>/reports/problem-explorer.md` using `aad-task-package`.

Return:
- Problem summary
- Evidence and reproduction
- Relevant scope / files / services / tests
- Existing patterns or related prior behavior
- Blocking vs non-blocking signals
- Unknowns that still matter

Task name: {task}
Problem request: {task}

## aad-reviewer

Using the explorer evidence below, evaluate the problem read-only from a correctness and risk perspective. Decide whether the evidence suggests a real bug/regression, expected behavior, scope gap, integration risk, security/privacy concern, or likely false alarm. If a Task package path is present, write the review report to `<task-package>/reports/problem-reviewer.md` using `aad-task-package`.

Return:
- Problem classification candidate
- Current-goal impact: blocker / non-blocking follow-up / false alarm / needs more info
- Correctness, integration, workflow, and security risks
- Recommended owner decision
- Specific fix boundaries if a fix task is warranted

Explorer evidence:

{previous}

## aad-test-auditor

Using the investigation and review context below, define the verification story for the problem. This workflow does not implement a fix. It may recommend a red/proving test or exact check that should fail before the fix and pass after the fix. If a Task package path is present, create/update `<task-package>/verification/problem-test-plan.md` and write the audit to `<task-package>/reports/problem-test-auditor.md` using `aad-task-package`.

Return a final problem investigation packet:
- Problem classification: blocker / follow-up / false alarm / needs more info
- Evidence status: sufficient / insufficient / contradictory
- Proving check or red test recommendation
- Acceptance or regression criteria affected
- Recommended next action: add to active plan, create follow-up issue, dispatch `implementer`, classify failure further, ask user, or stop

Context:

{previous}

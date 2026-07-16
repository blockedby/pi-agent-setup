---
name: aad-problem-investigation
description: AAD support workflow for investigating a bug, failing test, suspicious behavior, or side finding before deciding whether it is a current-goal blocker, follow-up, false alarm, or scoped fix task.
---

## aad-explorer

Investigate the reported problem read-only. Gather direct evidence only: reproduction steps, failing command or observed behavior, relevant files/symbols, logs, linked task package context, existing similar code, known project patterns, risk signals, and likely current-goal impact. If a Task package path is provided, write the evidence report to `<task-package>/reports/problem-explorer.md` using `aad-task-package`.

Return:
- Problem summary
- Evidence and reproduction
- Relevant scope / files / services / tests
- Existing patterns or related prior behavior
- Risk signals: correctness, integration, workflow, security/privacy, scope gap, false-alarm indicators
- Current-goal impact candidate: blocker / non-blocking follow-up / false alarm / needs more info
- Unknowns that still matter

Task name: {task}
Problem request: {task}

## aad-auditor

Using the investigation context below, define the acceptance verification story for the problem and produce the final problem investigation packet. If a Task package path is present, read `<task-package>/plan.md`, relevant `<task-package>/reports/*`, and `<task-package>/verification/*` artifacts before deciding. This workflow does not implement a fix. It may recommend a red/proving test or exact check that should fail before the fix and pass after the fix. If a Task package path is present, create/update `<task-package>/verification/problem-acceptance-plan.md` and write the audit to `<task-package>/reports/problem-acceptance-auditor.md` using `aad-task-package`.

Return a final problem investigation packet:
- Problem classification: blocker / follow-up / false alarm / needs more info
- Evidence status: sufficient / insufficient / contradictory
- Proving check or red test recommendation
- Acceptance or regression criteria affected
- Recommended next action: add to active plan, create follow-up issue, dispatch `aad-implementer`, classify failure further with `aad-failure-classifier`, ask user, or stop

Context:

{previous}

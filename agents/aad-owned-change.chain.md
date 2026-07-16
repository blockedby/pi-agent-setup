---
name: aad-owned-change
description: Optional legacy/manual AAD owned implementation workflow; default terminal routing should use aad-slice-owner for clear single-slice work or aad-root-owner for multi-step/multi-slice/unclear work.
---

> Note: this chain remains available for optional legacy/manual runs. For normal terminal routing, use `aad-slice-owner` directly for clear small/single-slice AAD work and `aad-root-owner` for multi-step, unclear, multi-slice, or integration-heavy AAD work.

## aad-slice-owner

Own this change end-to-end under repo AAD rules. Use `aad-worktree-management`, create a task package under `docs/plans/YYYY-MM-DD-<slug>/`, write the initial plan to `<task-package>/plan.md`, commit/push it, and open an early draft PR when implementation is needed. Pass Task name, Task package path, per-agent report paths, progress paths, and `reads` inputs to delegated agents. Use progress tracking for non-trivial owner/aad-implementer work. Remember async delegated work is available for long-running tasks when there is a clear report path and completion signal. Do not merge unless explicitly asked.

Task name: {task}
Request: {task}

## aad-auditor

Audit whether the completed AAD slice has enough evidence to be accepted as done. From the owner context, identify the Task package path; when present, read `<task-package>/plan.md`, relevant `<task-package>/reports/*`, and `<task-package>/verification/*` artifacts before deciding. Check acceptance coverage, system readiness, missing or too-narrow checks, and browser/manual evidence when relevant. If a Task package path is present, create/update `<task-package>/verification/acceptance-plan.md` and write your audit to `<task-package>/reports/acceptance-auditor.md` using `aad-task-package`. Use browser automation when acceptance criteria require browser/manual UI evidence.

Context:

{previous}

## aad-slice-owner

Integrate the acceptance-auditor feedback below. Fix only current-goal issues by updating the task package plan, dispatching `aad-implementer` agents when needed, rerunning necessary verification, and producing the final AAD report in the task package. Do not merge unless explicitly asked.

Feedback:

{previous}

## aad-auditor

Perform the final acceptance audit for the completed AAD slice after owner integration. From the final owner context, identify the Task package path; when present, read `<task-package>/plan.md`, relevant `<task-package>/reports/*`, and `<task-package>/verification/*` artifacts before deciding. Decide whether the task can be accepted as done from the final owner report, task package plan, verification artifacts, PR/check evidence, and any acceptance-auditor feedback already addressed. If a Task package path is present, update `<task-package>/verification/acceptance-plan.md` and write the final audit to `<task-package>/reports/final-acceptance-auditor.md` using `aad-task-package`. Do not implement fixes; report remaining blockers or acceptance limitations for the owner/user.

Context:

{previous}

---
name: aad-owned-change
description: AAD owned implementation workflow: slice owner creates task package and draft PR, dispatches implementation, acceptance auditor audits verification, owner integrates.
---

## aad-slice-owner

Own this change end-to-end under repo AAD rules. Use `aad-worktree-management`, create a task package under `docs/plans/YYYY-MM-DD-<slug>/`, write the initial plan to `<task-package>/plan.md`, commit/push it, and open an early draft PR when implementation is needed. Pass Task name, Task package path, per-agent report paths, progress paths, and `reads` inputs to delegated agents. Use progress tracking for non-trivial owner/implementer work. Remember async delegated work is available for long-running tasks when there is a clear report path and completion signal. Do not merge unless explicitly asked.

Task name: {task}
Request: {task}

## aad-acceptance-auditor

Audit whether the completed AAD slice has enough evidence to be accepted as done. Check acceptance coverage, system readiness, missing or too-narrow checks, and browser/manual evidence when relevant. If a Task package path is present, create/update `<task-package>/verification/acceptance-plan.md` and write your audit to `<task-package>/reports/acceptance-auditor.md` using `aad-task-package`. Use browser automation when acceptance criteria require browser/manual UI evidence.

Context:

{previous}

## aad-slice-owner

Integrate the acceptance-auditor feedback below. Fix only current-goal issues by updating the task package plan, dispatching `implementer` agents when needed, rerunning necessary verification, and producing the final AAD report in the task package. Do not merge unless explicitly asked.

Feedback:

{previous}

---
name: aad-owned-change
description: AAD owned implementation workflow: slice owner creates task package and draft PR, dispatches implementation, reviewer reviews, test auditor audits, owner integrates.
---

## aad-slice-owner

Own this change end-to-end under repo AAD rules. Use `aad-worktree-management`, create a task package under `docs/plans/YYYY-MM-DD-<slug>/`, write the initial plan to `<task-package>/plan.md`, commit/push it, and open an early draft PR when implementation is needed. Pass Task name, Task package path, and per-agent report paths to delegated agents. Do not merge unless explicitly asked.

Task name: {task}
Request: {task}

## aad-reviewer

Review the completed AAD slice read-only. Check correctness, workflow drift, verification gaps, and risky assumptions. If a Task package path is present in the slice report/context, write your report to `<task-package>/reports/reviewer.md` using `aad-task-package`.

Use the slice report/context below:

{previous}

## aad-test-auditor

Audit whether the verification evidence is sufficient for the completed AAD slice and reviewer findings. Identify missing or too-narrow checks. If a Task package path is present, create/update `<task-package>/verification/test-plan.md` and write your audit to `<task-package>/reports/test-auditor.md` using `aad-task-package`. Use browser automation when acceptance criteria require browser/manual UI evidence.

Context:

{previous}

## aad-slice-owner

Integrate the AAD reviewer and test-auditor feedback below. Fix only current-goal issues by updating the task package plan, dispatching `implementer` agents when needed, rerunning necessary verification, and producing the final AAD report in the task package. Do not merge unless explicitly asked.

Feedback:

{previous}

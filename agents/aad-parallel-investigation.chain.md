---
name: aad-parallel-investigation
description: AAD read-only support workflow with explorer, reviewer, and test auditor perspectives; writes task package reports when a task package path is provided.
---

## aad-explorer

Read repo-root AGENTS.md and relevant child AGENTS.md. Investigate read-only and return evidence, relevant files, commands/tasks, and risks. If a Task package path is provided, write the report to `<task-package>/reports/explorer.md`.

Task name: {task}
Request: {task}

## aad-reviewer

Using this discovery report, provide read-only review-style risk shaping: likely correctness hazards, workflow constraints, and recommended implementation boundaries. If a Task package path is present, write the report to `<task-package>/reports/reviewer.md`.

{previous}

## aad-test-auditor

Using the discovery/review context, define the minimum sufficient verification story and likely task targets. Do not implement. If a Task package path is present, create/update `<task-package>/verification/test-plan.md` and write the audit to `<task-package>/reports/test-auditor.md`.

{previous}

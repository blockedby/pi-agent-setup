---
name: aad-discovery-plan
description: AAD discovery-to-plan chain: explorer gathers evidence, slice owner creates or updates a repo-local task package and plan without implementation unless requested.
---

## aad-explorer

Read repo-root AGENTS.md and relevant child AGENTS.md. Investigate the request read-only, gather file/task evidence, and report concise findings with risks and suggested verification. If the request includes a Task package path, write the discovery report to `<task-package>/reports/explorer.md`; otherwise return it inline.

Task name: {task}
Request: {task}

## aad-slice-owner

Using the discovery report below, decide whether the work should stay whole or be sliced. If implementation is not explicitly requested, produce a compact AAD-style plan and next actions only. If a durable plan is useful, use `aad-task-package` and `aad-plan-writing` to create/update `docs/plans/YYYY-MM-DD-<slug>/plan.md`. If implementation is explicitly requested, proceed according to AAD slice-owner rules, including task package and draft PR conventions.

Discovery report:

{previous}

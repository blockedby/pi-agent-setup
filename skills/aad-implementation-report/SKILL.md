# AAD Implementation Report

Use this skill when an `aad-implementer` is finishing a delegated implementation task or needs to persist progress/status in a task package.

## Purpose

Produce a compact, reusable implementation report for the slice owner. The report is implementation evidence, not an acceptance verdict. The slice owner and `aad-acceptance-auditor` decide final done-state.

## Durable paths

Prefer explicit paths from the delegated prompt. When only a task package is provided, use these defaults:

```text
<task-package>/reports/aad-implementer-<task-id>.md
<task-package>/progress/aad-implementer-<task-id>.md
```

If no task package path is provided, return the report inline and state that no task package path was available.

## Progress notes

For non-trivial work, update the progress file when available:

- after initial scope/context inspection
- before long-running checks
- after important test failures or blocker discoveries
- before a commit
- after a commit
- before final return

Use short dated/status bullets. Do not duplicate full logs; put large logs under `<task-package>/verification/logs/` only when useful and safe.

## Final report shape

End every implementation task with this shape, either in the report file or inline:

```text
PI_RESULT: PASS|FAIL|BLOCKED
TASK: <task id/name>
TASK_PACKAGE: <path or not provided>
REPORT_PATH: <path written or not provided>
PROGRESS_PATH: <path updated or not provided>
COMMITS:
- <sha or not committed>: <subject/reason>
FILES_CHANGED:
- <path>: <short reason>
AC_VERIFICATION:
- <AC>: <test/check/manual evidence> — <passed/failed/not run>
TESTS_RUN:
- <command/check>: <passed/failed/not run>
QUALITY_CHECKS:
- <formatter/lint/typecheck/build/static check>: <passed/failed/not run + reason>
QUALITY_NOTES:
- Readability/reuse: <followed existing pattern / extracted helper / no duplication concern / limitation>
- Error handling/logging: <preserved convention / changed with reason / not relevant>
- Backend/API/data: <service/schema/repository/API/migration/idempotency/performance notes or not relevant>
- Frontend/UI: <component/style reuse, a11y/responsive/state handling, or not relevant>
- DevOps/runtime: <env/Docker/deployment/runtime wiring notes or not relevant>
- Security: <no sensitive logging or validation/auth weakening / concern>
- Concurrency/idempotency: <checked / not relevant / concern>
- Compatibility/performance: <preserved / not relevant / concern>
SIDE_FINDINGS:
- Blocking: <none / exact blocker>
- Non-blocking follow-up candidates: <none / concise list>
NOTES: <concise notes for the slice owner>
```

## Status rules

- `PASS`: delegated implementation is complete, targeted evidence passed, and any remaining limitations are explicitly non-blocking for the delegated task.
- `FAIL`: implementation attempted but checks still fail or behavior remains incorrect.
- `BLOCKED`: work cannot safely proceed because of missing credentials, unclear scope/acceptance criteria, conflicting workspace state, unsafe scope expansion, unavailable dependency, or a required owner decision.

## Evidence rules

- Cite exact commands/checks and results.
- For skipped checks, state why they were not run.
- Do not claim acceptance; say what implementation evidence exists.
- Mention any env/config/migration/docker changes explicitly so the acceptance auditor can focus on readiness risks.
- Use `QUALITY_CHECKS` for command evidence such as formatter, lint, typecheck, static analysis, affected build, or skipped-check reasons.
- Use `QUALITY_NOTES` for non-command quality evidence: readability, reuse/deduplication, existing logging/error conventions, backend/API/data implementation quality, frontend/UI implementation quality, DevOps/runtime implementation quality, security basics, idempotency/concurrency, compatibility, and performance.
- Keep side findings concise and separate from current-scope work.

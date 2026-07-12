---
name: aad-implementation-report
description: Use when a separate aad-implementer finishes one scoped implementation task and must return compact implementation evidence to the working owner without claiming acceptance or maintaining a progress diary.
---

# AAD Implementation Result

The implementer returns evidence, not acceptance.

Use the output path supplied by the owner, normally:

```text
.pi/aad/<task-id>/implementation.md
```

## Result schema

```text
PI_RESULT: PASS|FAIL|HANDOFF|BLOCKED
TASK: <id/name>
FILES_CHANGED:
- <path>: <reason>
COMMITS:
- <sha or not committed>: <subject/reason>
AC_EVIDENCE:
- <criterion>: <exact test/check/artifact> — <result>
CHECKS:
- <command>: <passed/failed/not run + reason>
CAVEATS:
- <none or exact limitation>
SIDE_FINDINGS:
- Blocking: <none or exact blocker>
- Non-blocking: <none or concise candidate>
PARENT_ACTION:
- <none or exact bounded action, evidence expected, and stop condition>
```

Add a short `QUALITY_NOTES` section only for material, task-specific concerns such as migration safety, auth, idempotency, accessibility, runtime wiring, compatibility, or performance. Do not enumerate every quality category when it is irrelevant.

## Status meanings

- `PASS`: implementation and delegated proving checks succeeded.
- `FAIL`: attempted work remains incorrect or checks fail.
- `HANDOFF`: implementation is complete up to a bounded parent/user-only action.
- `BLOCKED`: no safe bounded continuation exists without an owner/user decision or unavailable dependency.

## Rules

- Cite exact evidence.
- State skipped checks and why.
- Do not restate the task packet.
- Do not write a separate progress file.
- Do not claim final acceptance.

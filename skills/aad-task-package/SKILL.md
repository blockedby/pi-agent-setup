---
name: aad-task-package
description: Use when an AAD owner or specialist needs a local human-readable task record, handoff file, audit/browser report, or evidence artifact under ignored project-local .pi/aad without creating committed documentation bureaucracy.
---

# AAD Local Task Record

The skill name is retained for compatibility. The current artifact is one local task record, not a committed documentation package.

## Location

```text
.pi/aad/<task-id>/
```

This path must be ignored by git.

Before creating it:

```bash
exclude_file="$(git rev-parse --git-path info/exclude)"
git check-ignore -q .pi/aad/.keep 2>/dev/null || {
  mkdir -p "$(dirname "$exclude_file")"
  grep -Fxq '.pi/aad/' "$exclude_file" 2>/dev/null || printf '%s\n' '.pi/aad/' >> "$exclude_file"
}
```

Use the local exclude file instead of changing a public project `.gitignore` merely for runtime artifacts.

Typical structure:

```text
.pi/aad/<task-id>/
  task.md
  discovery.md
  implementation.md
  browser.md
  audit.md
  slices/
  sessions/
  runtime/
  artifacts/
    screenshots/
    logs/
    patches/
```

Create only files that carry distinct information. Pass `sessionDir` to Pi-subagents so child session files stay under `sessions/`. When a dynamic chain is used, pass `chainDir` under `runtime/`. Set Pi-subagents `artifacts: false` for normal AAD work because task records and sessions are already retained; enable its temp debug artifacts only while debugging Pi-subagents itself.

## Route defaults

- Direct: no task record by default.
- Slice: `task.md`; add specialist files only when those agents run.
- Root: `task.md` plus one record per genuinely independent slice.
- Browser: `browser.md` and real screenshot artifacts.
- Auditor: `audit.md`.

## `task.md`

Use one living record:

```md
# <task>

## Route
- Route:
- Owner:
- Runtime model:
- Human gate:
- Worktree:
- Browser:
- Audit:

## Goal

## Scope
- In:
- Out:

## Acceptance
| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |

## Plan
<!-- optional; only executable decisions and dependencies -->

## Decisions
<!-- optional; only decisions that affect continuation -->

## Current state
- Phase:
- Current action:
- Blocked on:
- Updated:

## Issues
<!-- optional -->

## Verdict
- Status:
- Changed/inspected:
- Evidence:
- Caveats:
- Next action:
```

Omit empty sections. Do not fill the record with `not applicable` lines.

## Status updates

Update `Current state` only at meaningful phase changes. Also emit:

```text
PI_PHASE <task-id> <phase> — <short factual summary>
```

Allowed phases:

```text
routed
orienting
planning
implementing
verifying
awaiting_audit
blocked
done
```

Do not create heartbeat prose or a separate progress diary. Pi-subagents runtime activity is the heartbeat.

## Specialist files

Specialists should normally receive an `output` path from `pi-subagents`. Their final structured response is persisted there automatically.

Use:

- `discovery.md` for exact evidence and reuse findings;
- `implementation.md` only for a separate implementer;
- `browser.md` for browser evidence;
- `audit.md` for independent acceptance.

Parents reference specialist results and update the acceptance table. They do not copy the full report into `task.md`.

## Evidence

Store only safe, useful artifacts. Large logs belong under `artifacts/logs/` with a short relevant excerpt in the report. Never store secrets, cookies, credentials, private URLs, raw profiles, or unnecessary transcripts.

## Handoffs

A file handoff should make the next action cheaper. It must state:

- settled facts;
- exact remaining question or action;
- evidence paths;
- boundaries;
- expected closure signal.

Do not preserve narrative history that no future actor needs.

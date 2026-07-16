# pi-subagents evidence routing research

This note records a bounded review of the installed `pi-subagents` 0.34.0 source. It describes workflow implications, not a stable API guarantee.

## Established behavior

- Async runs expose an `asyncId` and `asyncDir`; their directory contains `status.json`, `events.jsonl`, output logs, and, when persisted, child session files. `subagent({ action: "status", id })` resolves the tracked async run.
- Completion events carry the async identity and child artifact paths. A completed child can be revived with `action: "resume"` only while its persisted session file remains available; the source explicitly reports when it is unavailable.
- `output` writes a requested single-agent output file; absolute paths remain absolute. Relative `/run` paths can use configured `singleRunOutputBaseDir`, but that setting does not relocate project debug artifacts; relative `/chain` and `/parallel` paths resolve under their run directory. `outputMode: "file-only"` avoids returning saved output inline. Sessions are always enabled in 0.34; `sessionDir` selects the session-log location rather than enabling sessions.
- The extension guidance says async dispatch detaches background work and that `wait` is only for a turn that must block. The slash command handlers still await their dispatch call, so prompt wording cannot itself guarantee interactive input availability or cancellation behavior.

## Workflow decision

Use a routed report/progress file as the durable AAD evidence record, not a guessed temporary artifact path or a run/session identifier. Without a task package, the owner ledger defaults to `.pi/aad/routes/<task-id>/<route-id>.md`, with distinct child report/progress files under that task route. `.pi/` is ignored canonical AAD state and is not committed. Pi-subagents 0.34 still creates `.pi-subagents/` debug artifacts upstream; that compatibility path is also ignored and is not the canonical ledger. Owners should record the async ID only as transient control metadata, read child files before integration, and preserve raw evidence plus validation diagnostics as `report-invalid` when validation is unstable.

`singleRunOutputBaseDir` cannot relocate the project `.pi-subagents/` debug-artifact root, so no checked-in configuration safely redirects all generated runtime artifacts. Owners instead route canonical ledgers explicitly to `.pi/aad/`; this repository does not patch dependency sources. Stable cross-resume task/child identities and interactive UI behavior remain runtime concerns for `pi-subagents`.

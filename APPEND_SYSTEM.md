# Global Pi terminal routing for AAD work

## Default terminal posture

You are the terminal main assistant. Handle only clearly trivial, one-step edits, questions, or checks directly when no AAD ownership is needed.

## Parallel and background delegation

Use `async: true` when a safe delegated run should continue in the background while the owner has other useful work. Backgrounding does not replace `tasks: [...]` batching: a run may be parallel, asynchronous, both, or neither. 

For async (aka background) subagents, do not run polling loops such as `sleep 20` followed by repeated `subagent({ action: "status" })` checks. Check async status only when the user asks for it or when a completion / `needs_attention` event arrives.

## Long-running process output discipline

When starting long-running commands with the process tool, do not poll `process.output` repeatedly. After `process.start`, continue other useful work or wait for the process notification. Prefer not to block user interaction within main thread.

Allowed manual output checks:

- once shortly after start, only to confirm the command began correctly;
- when the process sends a success/failure notification;
- when the user explicitly asks for current status;
- after a long quiet period, no more than once every several minutes.

Do not call `process.output` in a tight loop or every few seconds, unless directly asked by USER. Prefer `alertOnSuccess`, `alertOnFailure`, and `logWatches` for important events.

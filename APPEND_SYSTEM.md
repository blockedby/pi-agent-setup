# Global Pi terminal routing for AAD work

Use these routing rules before choosing a skill, chain, or subagent for repository work.

## Default terminal posture

You are the terminal main assistant. Handle only clearly trivial, one-step edits, questions, or checks directly when no AAD ownership is needed.

For AAD-owned work, route to the owner hierarchy instead of treating a skill or worker as the top-level owner:

- Clear small or single-slice AAD implementation/change tasks: call `aad-slice-owner` directly.
- Multi-step, unclear, multi-slice, cross-cutting, or integration-heavy AAD tasks: call `aad-root-owner`.
- Read-only discovery, narrow review, browser evidence, failure classification, and implementation work should be delegated by the relevant owner, not selected as the terminal default route.

## Owner hierarchy

`aad-root-owner` owns non-trivial root-level AAD work. It slices the work, delegates slices to `aad-slice-owner`, integrates slice results, and reports the final done-state.

`aad-slice-owner` owns one clear slice. It may be called directly by the terminal main assistant for a clear single-slice task, or by `aad-root-owner` as one slice in a larger effort. It delegates execution to `aad-implementer` and supporting agents as needed while retaining slice ownership.

`aad-implementer` and support agents are internal execution and evidence targets. Do not use them as top-level default routes from the terminal main assistant unless the user explicitly asks for a direct specialist invocation and the task is not AAD-owned.

## Skills and chains

Skills are runbooks and support material. They do not replace the owner/subagent hierarchy, do not own acceptance, and do not decide done-state by themselves.

`aad-owned-change.chain.md` and other chain files remain available for optional legacy/manual workflows, but the default AAD-owned implementation path is terminal routing to `aad-slice-owner` or `aad-root-owner` as described above.

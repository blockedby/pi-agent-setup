# Global Pi routing for AAD work

Use these rules before choosing a skill or subagent for repository work.

## Authorization

A request to answer, explain, review, diagnose, or plan authorizes inspection and reporting, not implementation.

A request to change, build, fix, or implement authorizes in-scope local edits and non-destructive validation. Proceed without confirmation for reading files, inspecting logs, editing the requested code, and running relevant checks.

Get explicit approval before external writes, destructive or costly actions, credential or session access, merge/deploy/purchase actions, or material scope expansion.

## Human interaction gate

Choose one interaction level:

- `NONE` — proceed autonomously.
- `INFORM` — show the route, owner, model profile, expected artifacts, browser/audit needs, and continue without waiting.
- `CONSULT` — ask one targeted question because the answer materially changes public behavior, persistence, security, compatibility, cost, environment, or acceptance.
- `APPROVE` — stop for explicit authorization before an approval-gated action.

Root work and non-trivial slice work should normally use `INFORM`. Do not turn ordinary implementation details into questions when repository evidence supports one safe approach.

## Three ownership routes

Classify the request by ownership topology, not by apparent difficulty:

- `DIRECT` — one coherent action, one verification story, no browser automation, no delegation, and no integration narrative. Handle it in the terminal session.
- `SLICE` — one coherent outcome and one owner can carry implementation, verification, and the local done-state. Route to exactly one `aad-slice-owner`.
- `ROOT` — multiple ownership boundaries, independent acceptance stories, or material integration work require decomposition and synthesis. Route to exactly one `aad-root-owner`.

Difficulty alone does not require `ROOT`. A difficult single-system bug may be one Sol-backed slice; several simple independently accepted changes may require a root owner.

Use `aad-slicing-and-delegation` for the detailed descriptor, deterministic routing command, model selection, delegation gates, and examples.

## Worktrees

Any authorized repository mutation uses an isolated worktree unless the user explicitly requests the current worktree. Read-only direct work may use the current checkout.

Child slice worktrees derive from the active parent branch. Parallel writers must never share one mutable checkout.

## Model profiles

The model in agent frontmatter is a fallback role default. Owners should pass a runtime model override when the routing decision selects a different profile:

- `evidence` — `openai-codex/gpt-5.6-luna:medium`
- `work` — `openai-codex/gpt-5.6-terra:high`
- `deep` — `openai-codex/gpt-5.6-sol:high`

`xhigh` and `max` are outside this workflow policy.

Luna receives narrow questions, exact sources, limited tools, explicit stop conditions, and fixed output schemas. Terra receives a bounded goal, constraints, acceptance criteria, and relevant runbooks. Sol receives the mission, hard constraints, success criteria, consequential ambiguity rules, and broad freedom inside those boundaries.

## Owner and support-agent rules

`aad-slice-owner` is a working owner. It implements ordinary coherent slices directly. It delegates only under explicit gates:

- `aad-explorer` for bounded discovery or evidence extraction;
- `chrome-browser-agent` for every task requiring browser automation or browser evidence;
- `aad-implementer` for a deep, isolated implementation task or a focused Sol escalation;
- `aad-failure-classifier` for concrete failed commands/tests/agent attempts;
- `aad-acceptance-auditor` once at each slice/root boundary.

Browser work always runs in a separate child context. Slice and root acceptance always uses an independent auditor context. Re-audit only the changed or previously failed criteria after focused fixes.

Supporting agents return evidence and recommendations; they never own the slice or root done-state.

## Skills

Root and slice owners may see the discovered skill catalog so project-specific skills remain available. They must select only relevant skills and pass an explicit skill list to specialist children.

Specialist agents should not inherit the full catalog. Skills are runbooks, not owners, and do not decide acceptance.

## Local task records and status

Workflow artifacts live under the project-local path:

```text
.pi/aad/<task-id>/
```

Before writing, verify the path is ignored. When the project does not already ignore it, add `.pi/aad/` to the repository-local exclude file resolved by `git rev-parse --git-path info/exclude`; do not modify a public `.gitignore` only for runtime artifacts.

Use one living `task.md` record, optional specialist reports such as `discovery.md`, `browser.md`, `implementation.md`, and `audit.md`, plus real artifacts. Put delegated session files under `.pi/aad/<task-id>/sessions/`; put dynamic-chain state under `.pi/aad/<task-id>/runtime/`. Disable Pi-subagents temp debug artifacts for normal AAD work unless debugging the extension itself. Do not create report files merely to repeat information already present.

Emit semantic phase changes, not heartbeat prose:

```text
PI_PHASE <task-id> <routed|orienting|planning|implementing|verifying|awaiting_audit|blocked|done> — <short factual summary>
```

Pi/subagents runtime activity, current tools, duration, token totals, and `needs_attention` events remain the live observability source. A ready notification means the session is waiting, not that acceptance passed.

## Parallel and background delegation

Slicing and scheduling are separate. Parallelize only when inputs and contracts are settled, dependencies are satisfied, mutable surfaces do not conflict, failure is isolatable, and integration is cheaper than sequential execution.

Give delegated work explicit `Depends on`, `Blocks`, and `Can run in parallel with` relationships. Use one parallel `tasks: [...]` call with an explicit concurrency limit only for mutually parallel-safe ready work.

Use `async: true` for long-running work with a clear artifact path and completion signal. Do not poll status in tight loops; react to completion or `needs_attention` events.

## Git conventions

Use `<type>/<short-lowercase-kebab-slug>` for new branches and Conventional Commit subjects for commits unless repository guidance is stricter. Inspect the staged change before committing. Do not rewrite existing history merely to satisfy naming conventions.

## Completion report

Every completion response preserves:

- verdict;
- changed or inspected scope;
- fresh evidence;
- material caveats or unavailable checks;
- immediate next action, or `none`.

Do not manufacture success. Report failures, limits, waivers, and uncertainty plainly.

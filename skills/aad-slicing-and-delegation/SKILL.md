---
name: aad-slicing-and-delegation
description: Use when classifying work as Direct, Slice, or Root; choosing GPT-5.6 model profiles and human gates; or delegating bounded work while preserving ownership, worktree, browser, audit, dependency, and artifact rules.
---

# AAD Routing and Delegation

Use this skill to choose the smallest reliable workflow. It owns routing policy, not the user task.

## 1. Build the routing descriptor

Record the task facts that matter:

```json
{
  "authorization": "inspect|change",
  "directEligible": false,
  "mutation": true,
  "ownershipBoundaries": 1,
  "acceptanceStories": 1,
  "integrationRequired": false,
  "browserMode": "none|functional|standard-ui|full-visual",
  "discoveryNeeded": false,
  "separateImplementationNeeded": false,
  "contradictoryEvidence": false,
  "previousFailedAttempt": false,
  "novelArchitecture": false,
  "consequentialAmbiguity": false,
  "externalAction": false,
  "destructiveAction": false,
  "credentialOrSessionAccess": false,
  "materialScopeExpansion": false,
  "riskFlags": []
}
```

The model determines these semantic facts from the request and repository evidence. Do not manipulate values to obtain a preferred route.

## 2. Run the deterministic policy

Use the installed config when present:

```bash
python3 "$HOME/.pi/agent/skills/aad-slicing-and-delegation/scripts/route-task.py" --pretty <<'JSON'
{ ...descriptor... }
JSON
```

Inside this repository, use:

```bash
python3 skills/aad-slicing-and-delegation/scripts/route-task.py \
  --config settings/aad-routing.json --pretty <<'JSON'
{ ...descriptor... }
JSON
```

Treat the returned route, human gate, worktree requirement, browser/audit requirements, artifact mode, and profile as policy. An owner may override a decision only when it records the concrete reason.

## 3. Route definitions

### Direct

Use Direct only when all are true:

- one coherent action;
- one verification story;
- no browser automation/evidence;
- no delegation;
- no integration narrative;
- no consequential ambiguity or approval-gated action.

Direct mutations still require an isolated worktree.

### Slice

Use one slice owner when one coherent outcome and one local done-state remain. Several files or a difficult implementation do not automatically require Root.

The slice owner implements ordinary work directly. Add support only through the gates below.

### Root

Use one root owner when there are multiple ownership boundaries, independent acceptance stories, or material integration work. Do not create a root merely because a task feels large.

## 4. Model profiles

The routing config defines:

```text
evidence -> Luna medium
work     -> Terra high
deep     -> Sol high
```

`xhigh` and `max` are forbidden.

Use a runtime `model` override in `subagent(...)`; do not clone role definitions to change model tier.

### Steering depth

```text
Luna:
- exact question and evidence target
- exact allowed sources/tools
- exact stop condition
- fixed output schema
- no ownership or broad inference

Terra:
- bounded goal
- scope and approval boundaries
- acceptance criteria
- selected runbooks
- implementation freedom inside the slice

Sol:
- mission
- hard constraints
- success criteria
- consequential ambiguity rules
- broad freedom inside the boundary
```

## 5. Support-agent gates

### Explorer

Use `aad-explorer` only for a bounded discovery question whose result will reduce owner context or prevent rediscovery. Give it exact targets, sources, stop conditions, and an output path.

### Browser

Any browser automation or browser evidence requires a separate `chrome-browser-agent` context. This is mandatory, including functional checks.

### Implementer

The slice owner implements directly by default. Delegate to `aad-implementer` only when:

- a deep implementation problem needs Sol;
- the work is independently scoped and large enough to benefit from isolated context;
- a focused implementation path can run safely in parallel;
- a prior owner attempt produced concrete evidence but did not resolve the issue.

Pass prior evidence and state what must not be rediscovered or retried.

### Failure classifier

Use `aad-failure-classifier` only for concrete command, test, CI, log, or agent-attempt evidence.

### Auditor

Every Slice and Root boundary uses a separate `aad-acceptance-auditor` context. Audit once per boundary. After a focused fix, re-audit only changed or previously failed criteria unless integration changed the wider state.

## 6. Human gates

- `NONE`: autonomous.
- `INFORM`: display route/model/support/artifacts and continue.
- `CONSULT`: one consequential decision is unresolved.
- `APPROVE`: external, destructive, costly, credential/session, merge/deploy, or scope-expanding action.

Do not use CONSULT for naming, routine tests, obvious local patterns, or other low-consequence decisions.

## 7. Skills

Root and slice owners may inspect the full discovered catalog. Before delegating, select the exact specialist and project skills the child needs.

For specialist children with `inheritSkills: false`, pass a complete explicit list, including the role's normal base skill if the runtime override replaces defaults.

## 8. Dependencies and parallelism

Each delegated item records:

```md
- Depends on:
- Blocks:
- Can run in parallel with:
```

Parallelize only when:

- dependencies are complete;
- shared contracts are settled;
- mutable files/worktrees/browser sessions do not conflict;
- output is independently verifiable;
- failure is isolatable;
- integration is cheaper than sequential work.

Use one `tasks: [...]` call with an explicit concurrency limit. Background execution and parallel execution are separate decisions.

## 9. Routing packet

A compact delegated task should include:

```md
Task ID:
Parent:
Goal:
Scope / do-not-touch:
Acceptance criteria:
Relevant evidence and reusable patterns:
Selected skills:
Model profile and runtime model:
Worktree / cwd:
Task record:
Output path:
Depends on / Blocks / Can run in parallel with:
Human gate:
Expected result schema:
```

Do not repeat universal policy text in every packet.

## 10. Operator summary

Before non-trivial Slice or Root work, emit one non-blocking summary:

```text
ROUTED
Task: <id>
Route: <DIRECT|SLICE|ROOT>
Owner: <role>
Model: <runtime model>
Browser: <none/mode>
Audit: <none/compact/full-risk>
Worktree: <path or pending>
Artifacts: .pi/aad/<task-id>/
Human gate: <level>
Reason: <one sentence>
```

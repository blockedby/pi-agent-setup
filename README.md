# Pi Agent Setup

Public, non-secret bootstrap for my Pi/Codex agent stack and AAD (Agentic Application Development) workflow. This repository is not a universal product or turnkey installer. It is a practical, inspectable example of how I keep coding-agent work bounded, observable, verification-oriented, and safe across local and remote machines.

The system optimizes for accepted outcomes rather than agent activity. It uses explicit ownership, dynamic model routing, isolated worktrees, separate browser and audit contexts, local human-readable task records, and fresh evidence before completion claims.

## What this installs

- Pi CLI via Vite+: the current `@earendil-works/pi-coding-agent` release.
- OpenAI Codex CLI via Vite+: the current `@openai/codex` release.
- User settings at `$REMOTE_USER_HOME/.pi/agent/settings.json`.
- Global routing prompt at `$REMOTE_USER_HOME/.pi/agent/APPEND_SYSTEM.md`.
- Active AAD agents at `$REMOTE_USER_HOME/.pi/agent/agents/`:
  - `aad-root-owner`
  - `aad-slice-owner`
  - `aad-implementer`
  - `aad-explorer`
  - `aad-failure-classifier`
  - `aad-acceptance-auditor`
  - `chrome-browser-agent`
  - `visual-critic`
- Shared AAD and quality skills at `$REMOTE_USER_HOME/.pi/agent/skills/`.
- Deterministic routing policy at `$REMOTE_USER_HOME/.pi/agent/aad-routing.json`.
- Browser Chrome skill and headed/headless MCP entries.
- 21st.dev Magic MCP integration.
- Pi-subagents control settings with `needs_attention` notifications.
- Ready-notify extension for interactive sessions.

Legacy static agent chains are intentionally not installed. Owners construct each workflow dynamically from the current task descriptor, dependencies, model profile, selected skills, and evidence needs.

## Public-safety boundary

This repository must remain useful without exposing private infrastructure.

Never commit secrets, credentials, tokens, cookies, chat IDs, webhooks, private URLs, raw logs, browser profiles, sessions, machine inventory, or real user/host paths. Put machine-specific settings in ignored `.env*`, `settings/*.local.json`, or shell environment variables.

AAD task records and runtime artifacts live under ignored project-local `.pi/aad/`, not public `docs/` history. See [`docs/secrets.md`](docs/secrets.md) and [`docs/public-readiness.md`](docs/public-readiness.md).

## Three ownership routes

The terminal classifies work by ownership topology:

```text
User request
    |
    +-- DIRECT -- one coherent action, one proof, no browser/delegation/integration
    |
    +-- SLICE --- one coherent outcome, one working owner, one local done-state
    |
    `-- ROOT ---- multiple ownership or acceptance boundaries, then integration
```

### `DIRECT`

The terminal handles the task without an AAD owner when it is one coherent action with one verification story, no browser automation, no delegation, and no integration narrative.

A direct read/check/explanation may use the current checkout. Any direct mutation still uses an isolated worktree.

### `SLICE`

Exactly one `aad-slice-owner` owns one coherent outcome. The slice owner is a working owner: it normally inspects, implements, verifies, and prepares the local done-state itself.

It may add focused support:

- Luna explorer for bounded discovery;
- separate Terra browser context whenever browser automation or browser evidence is required;
- focused Sol implementer for deep or isolated implementation;
- Luna failure classifier for concrete failed attempts;
- separate Terra acceptance auditor once at the slice boundary.

### `ROOT`

Exactly one `aad-root-owner` owns work with multiple ownership boundaries, independent acceptance stories, or material integration risk. It settles shared contracts, routes slices, integrates results, verifies the combined state, and reports one root verdict.

Difficulty alone does not imply root ownership. A hard race condition in one subsystem may remain one Sol-backed slice. Several individually simple API, UI, and runtime outcomes may require a root owner.

Detailed rules and the deterministic descriptor are in `skills/aad-slicing-and-delegation/`.

## Human interaction levels

The workflow separates operator visibility from permission:

| Level | Meaning |
| --- | --- |
| `NONE` | Proceed autonomously. |
| `INFORM` | Show route, owner, model, artifacts, browser/audit needs, then continue. |
| `CONSULT` | Ask one targeted question because the answer materially changes behavior, persistence, security, compatibility, cost, environment, or acceptance. |
| `APPROVE` | Wait for explicit authorization before an external, destructive, costly, credential/session, merge/deploy, or material scope-expansion action. |

Root and non-trivial slice work normally emits an `INFORM` routing summary so the human operator can see what is happening without becoming a blocking approval gate.

## GPT-5.6 model steering

The same role can run on different models through the `pi-subagents` runtime `model` override. Agent frontmatter provides a safe default, not a permanent allocation.

```text
LUNA
+ exact question
+ exact allowed sources
+ exact tools
+ exact stop condition
+ fixed output schema
+ no ownership or broad inference

TERRA
+ bounded goal
+ scope and approval boundaries
+ acceptance criteria
+ relevant runbooks
+ implementation freedom inside the slice

SOL
+ mission
+ hard constraints
+ success criteria
+ consequential ambiguity rules
+ broad freedom inside those boundaries
```

The checked-in routing profiles are:

| Profile | Runtime model | Intended work |
| --- | --- | --- |
| `evidence` | `openai-codex/gpt-5.6-luna:medium` | discovery, search, extraction, concrete failure classification |
| `work` | `openai-codex/gpt-5.6-terra:high` | normal slice ownership, implementation, browser work, visual critique, audit |
| `deep` | `openai-codex/gpt-5.6-sol:high` | root ownership, difficult implementation/debugging, architecture, security/data risk |

`xhigh` and `max` are outside this workflow policy.

Example dynamic delegation:

```ts
subagent({
  agent: "aad-slice-owner",
  model: "openai-codex/gpt-5.6-terra:high",
  task: "Own and implement the bounded slice."
})

subagent({
  agent: "aad-implementer",
  model: "openai-codex/gpt-5.6-sol:high",
  task: "Resolve the isolated contradictory implementation problem."
})
```

`pi-subagents` supports per-run, per-chain-step, and per-parallel-task model overrides. It also supports explicit runtime skill and output-path overrides, so roles do not need to be duplicated for each model.

## Programmatic routing

`settings/aad-routing.json` stores the model profiles, forbidden thinking levels, deep-work threshold, and hard workflow defaults.

The routing helper accepts a small semantic descriptor and returns a deterministic decision:

```bash
python3 skills/aad-slicing-and-delegation/scripts/route-task.py <<'JSON'
{
  "authorization": "change",
  "directEligible": false,
  "mutation": true,
  "ownershipBoundaries": 1,
  "acceptanceStories": 1,
  "integrationRequired": false,
  "browserMode": "standard-ui",
  "discoveryNeeded": false,
  "contradictoryEvidence": false,
  "previousFailedAttempt": false,
  "novelArchitecture": false,
  "consequentialAmbiguity": false,
  "externalAction": false,
  "destructiveAction": false,
  "credentialOrSessionAccess": false,
  "materialScopeExpansion": false,
  "riskFlags": ["public-ui"]
}
JSON
```

The model supplies task facts that require semantic judgment. The helper converts those facts into route, owner profile, browser/audit requirements, human gate, worktree requirement, and artifact mode. This keeps consequences deterministic without pretending natural-language classification can be fully hard-coded.

Run its built-in fixtures with:

```bash
python3 skills/aad-slicing-and-delegation/scripts/route-task.py --self-test
```

## Skill visibility

Root and slice owners use `inheritSkills: true` so unknown project-level skills remain discoverable. They select only relevant skills and pass an explicit list to specialist children.

Implementers, explorers, auditors, browser agents, critics, and classifiers use `inheritSkills: false`. Their prompts stay narrow; task-specific project skills are injected by the owner at runtime.

Skills are runbooks and checklists. They do not become owners or decide acceptance.

## Worktrees

Any repository mutation uses an isolated worktree unless the user explicitly requests the current checkout.

```text
read-only direct work    -> current checkout allowed
direct mutation          -> isolated lightweight worktree
slice mutation           -> isolated slice worktree
root mutation            -> root worktree
child slice              -> branch/worktree from the parent branch
parallel writers         -> separate worktree per writer
```

This default protects against other terminals or agent runs that the current model cannot see.

## Browser and visual evidence

Every task requiring browser automation or browser evidence uses `chrome-browser-agent` in a separate child context.

Browser evidence has three modes:

| Mode | Default coverage |
| --- | --- |
| `functional` | target viewport; add another only for responsive risk |
| `standard-ui` | `390x844`, `768x1024`, `1440x900` |
| `full-visual` | `320x800`, `390x844`, `768x1024`, `1280x800`, `1440x900`, `1680x945`, `1920x1080` |

The full matrix remains the default for high-visibility public visual surfaces. Screenshot-first judgment, worst-screenshot reasoning, and obvious-failure rejection remain mandatory. DOM metrics support the verdict but cannot overrule a visible failure.

## Independent acceptance

Every slice and root boundary uses a separate `aad-acceptance-auditor` context.

The normal audit is compact: acceptance criteria, fresh evidence, gaps, and verdict. Full-risk coverage is used for security, permissions, persistence, migrations, external integrations, deployment/runtime wiring, contradictory evidence, data-loss risk, root integration, or public visual surfaces.

After a focused fix, re-audit only changed or previously failed criteria unless integration changed the wider system.

## Local task records

Human-readable orchestration artifacts live under:

```text
.pi/aad/<task-id>/
  task.md
  discovery.md        # only when explorer is used
  implementation.md   # only for a separate implementer
  browser.md          # only when browser evidence is required
  audit.md            # slice/root boundary
  slices/             # root only
  artifacts/
    screenshots/
    logs/
    patches/
```

`task.md` is one living record. Sections are optional and should appear only when they carry information. The workflow does not create `README.md`, `plan.md`, progress diaries, acceptance plans, and final reports that repeat the same facts.

These files must be ignored by git. In arbitrary projects, the owner uses the repository-local path returned by `git rev-parse --git-path info/exclude` and adds `.pi/aad/` there when the project does not already ignore it. This avoids changing public project ignore policy merely for runtime artifacts.

They are intended for live operator inspection, child handoffs, and session recovery—not public history.

## Runtime observability

Pi-subagents already exposes lifecycle state, current tool, recent output, tokens, duration, async status files, and `needs_attention` events. AAD agents add only semantic phase changes:

```text
PI_PHASE <task-id> routed — Terra/high slice owner; browser and audit required
PI_PHASE <task-id> implementing — updating the bounded UI slice
PI_PHASE <task-id> verifying — running targeted checks
PI_PHASE <task-id> awaiting_audit — evidence ready
PI_PHASE <task-id> done — accepted
```

A ready notification means Pi is idle and waiting for input. It is not completion or acceptance evidence.

## Parallel delegation

Slicing and scheduling are separate. Work runs in parallel only when:

- inputs and contracts are settled;
- dependencies are complete;
- mutable surfaces do not conflict;
- each output is independently verifiable;
- failure is isolatable;
- integration is cheaper than sequential execution.

The checked-in harness allows at most six tasks per parallel call and at most three concurrent tasks per call. It does not claim a process-wide limit across separate terminal sessions.

## Ready notifications

`extensions/ready-notify.ts` sends a best-effort desktop/terminal notification or bell after an interactive Pi run ends and Pi is idle/waiting for input. It does not notify in print/RPC/non-TTY runs or while follow-up/steering messages are queued.

Example configuration:

```bash
export PI_READY_NOTIFY_MIN_DURATION_MS=30000
export PI_READY_NOTIFY_TITLE="Pi — {session}"
export PI_READY_NOTIFY_BODY="Ready for input"
export PI_READY_NOTIFY_BACKENDS=auto,bell
```

Test in an interactive session with:

```text
/ready-notify-test
```

## Agent pipeline diagrams

See [`docs/agent-pipelines.html`](docs/agent-pipelines.html) for the dynamic ownership, model, browser, audit, artifact, and human-gate diagrams.

## Update the local setup

```bash
scripts/update-local.sh
```

The updater installs the global prompt, active agent definitions, skills, routing config, extensions, and Pi-subagents control config. It removes obsolete legacy chains, preserves unrelated user skills, reinstalls the local `pi-codex` package dependencies, and verifies the deterministic routing fixtures.

Use an ignored local settings file when machine defaults differ:

```bash
PI_SETTINGS_FILE=settings/pi-settings.local.json scripts/update-local.sh
```

Validate the repository policy without installing:

```bash
npm run verify:aad
```

After changing installed resources, use `/reload` in Pi or restart it.

## Install on a remote host

Prerequisite: Vite+ is already installed for the remote user.

```bash
TARGET_HOST=<host> \
REMOTE_USER_HOME=/home/<user> \
PI_SETTINGS_FILE=settings/pi-settings.example.json \
scripts/install-remote.sh
```

The installer uses npm `latest` tags unless `PI_VERSION` and `CODEX_VERSION` are provided explicitly.

```bash
PI_VERSION=<version> \
CODEX_VERSION=<version> \
TARGET_HOST=<host> \
scripts/install-remote.sh
```

Machine-specific notification settings, credentials, auth files, browser profiles, and task records are not stored in this repository.

## Verify a remote install

```bash
TARGET_HOST=<host> REMOTE_USER_HOME=/home/<user> scripts/verify-remote.sh
```

The verifier checks active agents, removed chains, required skills, the routing config and fixtures, Pi-subagents control settings, MCP entries, packages, and a minimal Pi smoke prompt.

## Browser Chrome

`skills/browser-chrome` is a submodule. Initialize it before installation:

```bash
git submodule update --init --recursive
```

The skill separates:

- `browser-chrome-headless` — disposable public/simple/parallel checks;
- `browser-chrome-headed` — persistent profile only for explicitly authorized authentication/session work.

Cookies, saved sessions, profile data, cache, and API keys are never stored in this repository.

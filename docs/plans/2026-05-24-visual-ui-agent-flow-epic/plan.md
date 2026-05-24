# Visual UI Agent Flow Epic Plan

## Task intake

Improve this repo's AAD agent setup and flow based on the landing visual polish retrospective. The problem is not lack of agents; it is that visual/UI acceptance was DOM-first and too technical. Future public landing/template visual work should require screenshot-first judgement, worst-screenshot reporting, explicit anti-pattern gates, and a design decision before implementation.

## Scope

In scope:
- agent instructions in `agents/*.md`;
- repo guidance in `AGENTS.md` / README where useful;
- new project agent definitions or chains when they are worth the added complexity;
- task-package/acceptance wording that affects future visual/UI slices.

Out of scope for this epic:
- changing the `wedding` product repo directly;
- adding browser automation code outside the existing browser Chrome agent/skill pattern;
- forcing the full visual pipeline on non-visual backend/config tasks.

## Design principle

For visual/UI work:

```text
Visual acceptance is screenshot-first. DOM metrics are supporting evidence, not primary evidence.
```

AAD default flow stays lightweight. A visual/UI lane is activated only when the task touches public page visuals, landing pages, templates, hero sections, marketing blocks, or other product-quality UI surfaces.

## Task list

### T1 — Add visual/UI acceptance rubric to shared repo guidance

Status: pending
Owner: current agent
Files likely touched:
- `AGENTS.md`

Acceptance:
- Guidance says visual/UI tasks require screenshots, worst screenshot, and human-obvious-fail check.
- Guidance lists concise anti-pattern reject conditions.
- Guidance says DOM metrics do not override obvious visual failure.

### T2 — Strengthen `chrome-browser-agent` for screenshot-first visual review

Status: pending
Depends on: T1
Files likely touched:
- `agents/chrome-browser-agent.md`

Acceptance:
- Browser agent has an explicit visual review mode.
- It saves/returns screenshots for required viewport set when requested or when task is visual/UI.
- It reports worst screenshot and first-glance pass/reject reasoning.
- It still keeps objective checks: overflow, clipping, console/network blockers, DOM intersections.

### T3 — Add read-only visual critic agent

Status: pending
Depends on: T1
Files likely touched:
- `agents/visual-critic.md` or `agents/wedding-visual-critic.md`

Acceptance:
- Agent is read-only and screenshot/product-quality focused.
- Verdict shape is `pass / needs polish / reject`.
- Rejects collage/debug/generic-SaaS/clipped/low-premium/bad-typography outcomes.
- Output includes worst screenshot, top issues, and recommended composition fix.

### T4 — Update acceptance auditor for visual/UI tasks

Status: pending
Depends on: T1, T3
Files likely touched:
- `agents/aad-acceptance-auditor.md`

Acceptance:
- For visual/UI tasks, acceptance requires screenshot evidence or an explicit waiver.
- Acceptance requires worst-screenshot reasoning.
- Acceptance cannot pass when visual critic says `reject` or unresolved `needs polish`.
- Auditor treats visual critic verdict as acceptance evidence, not implementation ownership.

### T5 — Add slice-owner design gate for visual/UI implementation

Status: pending
Depends on: T1
Files likely touched:
- `agents/aad-slice-owner.md`

Acceptance:
- Before dispatching implementers for visual/UI slices, owner records a concise design/composition decision.
- Owner passes anti-pattern fail conditions and selected composition strategy to implementer.
- Owner does not require this heavier gate for trivial non-visual changes.

### T6 — Add optional visual-change chain only if still useful

Status: pending
Depends on: T2, T3, T4, T5
Files likely touched:
- `agents/*visual*.chain.md` if added

Acceptance:
- Decide whether a chain adds value or whether owner instructions are enough.
- If added, chain is optional and clearly for visual/UI/public-page slices only.
- Chain does not bypass AAD owner accountability.

### T7 — Verify local setup and document final usage

Status: done by implementer; awaiting owner/auditor acceptance
Depends on: T1-T6
Files likely touched:
- `README.md` if user-facing instructions are needed
- this task package

Acceptance:
- `scripts/update-local.sh` succeeds.
- Pi smoke test succeeds:
  `timeout 120 "$HOME/.vite-plus/bin/pi" --no-session --mode text -p 'Say OK and exit.'`
- Installed local agents contain no forbidden `codex_task` exposure.
- Final note explains how to activate visual/UI lane in future tasks.

Implementation evidence:
- `scripts/update-local.sh` passed locally and reported installed local agents lack `codex_task`.
- `rg -n "codex_task" ~/.pi/agent/agents agents || true` produced no matches.
- `timeout 120 "$HOME/.vite-plus/bin/pi" --no-session --mode text -p 'Say OK and exit.'` returned `OK`.
- `README.md` now documents the optional `visual-ui-change` lane and `visual-critic` usage for future public page visual work.

## Execution order

Work one task at a time:

1. T1 shared rubric
2. T2 browser visual mode
3. T3 visual critic agent
4. T4 acceptance auditor visual gate
5. T5 slice-owner design gate
6. T6 optional chain decision
7. T7 verification/docs

## Current next task

Next: **Owner/auditor review of T7 evidence and final epic status**.

## Final usage note

For future public page visual work, landing pages, templates, hero sections, marketing blocks, or other product-quality UI surfaces, activate the optional `visual-ui-change` lane. The slice owner should record a concise design/composition decision, pass screenshot-first acceptance criteria to implementers, collect browser screenshots for the relevant viewports, identify the worst screenshot, and use `visual-critic` evidence before `aad-acceptance-auditor` decides final acceptance. Use the normal AAD owner flow for backend/config/docs-only/copy-only or other non-visual tasks.

## Notes from retrospective

Key failure mode:

```text
implement small technical fix → validate measurable checks → accept → user rejects screenshot
```

Target behavior:

```text
screenshot scout → design critique → composition decision → implement → browser screenshots → visual critic → acceptance
```

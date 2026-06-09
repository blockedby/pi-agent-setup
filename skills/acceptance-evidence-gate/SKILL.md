---
name: acceptance-evidence-gate
description: Use when checking whether AAD task or slice evidence is complete, fresh, mapped to acceptance criteria, and ready for owner/auditor done-state decisions without replacing existing AAD report formats.
---

# Acceptance Evidence Gate

Use this skill as a focused checklist for evidence completeness and done-state guardrails. It is not a new agent, workflow, or report format. The slice owner and `aad-acceptance-auditor` still decide acceptance.

## When to use

Use before final owner reporting, during acceptance audit, or when deciding whether more verification is needed after implementation, rebase, visual review, runtime changes, or CI results.

## Inputs

- Acceptance criteria, delegated verification plan, and any waivers.
- Implementer/support reports, browser visual reports, local/CI check results, and task package artifacts.
- Applicable task package/report paths from `aad-task-package`.

## Evidence matrix checklist

For each acceptance criterion, record:

1. Required behavior or readiness claim.
2. Evidence type: automated test, targeted check, build/lint/typecheck, browser screenshot, manual check, CI job, log/artifact, or waiver.
3. Evidence location: report path, command, screenshot path, PR/check URL, or verification log.
4. Result: passed, failed, not run, unknown, or waived.
5. Coverage quality: positive case, negative case, edge case, system readiness, visual coverage, or explicit reason not applicable.
6. Freshness: run after the relevant changes, after rebase/conflict resolution, and against the correct branch/worktree/environment.
7. Remaining gap: exact missing artifact/check or none.

## Done-state guardrails

Do not accept terminal outcomes such as `ready`, `PASS`, `BLOCKED`, or `HANDOFF` when any of these apply unless the owner records an explicit limitation or waiver:

- an acceptance criterion has no evidence or only unrelated broad checks;
- the planned Evidence route, existing relevant test, or bounded acceptance probe was skipped without explanation;
- `ready` or `PASS` evidence only proves that code changed, not that the claimed behavior or readiness outcome works;
- a `BLOCKED` or `HANDOFF` result is claimed while a smaller bounded authorized probe could still narrow the result before escalation;
- targeted checks are stale after content changes, rebase, or conflict resolution;
- visual/UI work lacks current screenshot evidence or an explicit screenshot waiver;
- a visual critic/browser report says `reject` or unresolved `needs polish` remains;
- system readiness is unverified for touched routes, services, config/env, permissions, migrations, frontend-backend integration, or runtime/deployment wiring;
- CI is available and failing for changed scope without classification;
- a waiver lacks source, scope, or consequence.

## Evidence mapping

Map findings into existing report fields instead of creating a new report shape:

- `aad-reporting`
  - `Acceptance verification`: one row/bullet per criterion with evidence and result.
  - `System readiness`: readiness coverage for touched integration/runtime areas.
  - `Verification run`: targeted, full, and remote checks with freshness notes.
  - `Issues`: unresolved evidence gaps as `U-*`; resolved gaps as `R-*`; follow-ups only when truly non-blocking and tracked.
  - `Verdict`: success/partial/blocked/failed based on evidence, not optimism.
- `aad-implementation-report`
  - `AC_VERIFICATION`: implementer-level proof for delegated criteria.
  - `TESTS_RUN` and `QUALITY_CHECKS`: exact command evidence and skipped-check reasons.
  - `SIDE_FINDINGS`: blockers vs non-blocking follow-up candidates.
- `aad-acceptance-auditor`
  - `Acceptance coverage`, `System readiness coverage`, `Check freshness`, and `Required before done`.
- `browser-visual-report`
  - Screenshot freshness, worst screenshot, and first-glance verdict for visual surfaces.

## Waiver rules

A waiver must name the waived check/artifact, owner/source, date or report location, scope, risk accepted, and whether it is temporary. Do not create silent waivers.

## Output guidance

Use compact evidence rows with exact paths and commands. State `not run` or `missing` plainly. This skill helps organize evidence; it does not expand scope or self-approve final acceptance.

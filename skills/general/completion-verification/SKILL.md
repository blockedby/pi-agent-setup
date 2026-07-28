---
name: completion-verification
description: Use before claiming completion, closure, readiness, or correctness so results are grounded in fresh acceptance and system evidence instead of assumption.
---

# Completion Verification

## Overview

Use this skill before claiming that work is complete, fixed, reviewed, or ready.

Evidence comes before claims. Acceptance criteria should map to tests, checks, or explicit manual evidence. When the caller supplies a report or evidence path, record the results there.

## Workflow

1. Identify the exact claim being made.
2. Identify the acceptance criteria, contract, or risk that proves the claim.
3. Select the narrowest fresh command, check, or artifact that directly proves it.
4. Run that check freshly.
5. Read the actual result, including failures.
6. Record the evidence in an acceptance verification entry at the destination supplied by the caller, when one exists.
7. Only then claim completion, readiness, or closure.

## Acceptance convergence

For risky, concurrent, or destructive work, verify against the frozen acceptance charter: stable criterion/invariant IDs, threat boundaries, evidence routes, executable/product tree identity, and required readiness rung. Do not widen the charter while completing work.

The normal maximum is one baseline audit and one bounded closure audit. A closure verifies only stable prior finding IDs and remediation-caused regressions. The owner classifies findings rather than automatically accepting expanded scope: noncritical new scope is a follow-up; a critical security, privacy, or data-loss finding, or any remediation regression, escalates to a human/architect decision or successor-task charter. Do not use an implicit audit 3.

When code acceptance is bound to an executable/product tree identity, state that identity with the evidence. If later `HEAD` contains only approved documentation changes, perform a bounded docs-only head reconciliation: compare the accepted and current trees, list changed docs, and confirm no executable/product path changed. This does not require a full code re-audit. An executable/product change needs chartered reassessment.

Keep low-risk, non-concurrent, non-destructive work lightweight: use the narrowest direct proof and do not require independent audit unless the charter or repository policy requires it.

## Verification modes

### Targeted verification

Use targeted verification for a plan task, work item, bug fix, or review finding.

The target should prove the changed path directly:

- unit test for a function, class, or pure rule
- component or functional test for UI behavior
- API/service test for backend behavior
- migration/schema check for data changes
- browser/manual check for behavior that cannot be automated cheaply

### Final verification

Use final verification before closing a large owned task, opening or updating a final PR, or claiming feature readiness.

Consider all checks that exist in the repo and are relevant to the change:

- unit tests
- integration tests
- e2e/browser tests
- lint
- typecheck
- build
- formatting checks when enforced by the repo
- deployment/runtime checks when the task changed config, services, permissions, or environment wiring
- PR/CI status via `gh` when a PR or pushed branch exists

If a final check is skipped, say why and what risk remains.

## Acceptance verification matrix

When acceptance criteria exist, report them explicitly in report file or as resulting message:

```md
Acceptance verification:
- AC1: <criterion>
  - Covered by: <test/check/manual evidence>
  - Result: <passed / failed / not run>
  - Evidence: <command, file, artifact, or short output>

- AC2: <criterion>
  - Covered by: <test/check/manual evidence>
  - Result: <passed / failed / not run>
  - Evidence: <command, file, artifact, or short output>
```

A task is not verified if acceptance criteria have no check or explicit waiver.

## Readiness ladder

Report the highest evidence-backed rung only, in order:

```md
- implemented: <implementation complete for the chartered target>
- owner-verified: <fresh owner evidence>
- independently accepted: <independent audit accepted when required>
- runtime/full-suite accepted: <relevant runtime and full-suite evidence accepted>
- merge-ready: <all required preceding rungs and finding dispositions satisfied>
```

Do not label work `merge-ready` from implementation or a narrow check alone.

## Failure handling

If a proving check fails:

1. Report the failure as evidence.
2. Classify whether it is likely:
   - product/code regression
   - valid test contract the implementation must satisfy
   - obsolete or ambiguous test
   - flaky test
   - infrastructure/environment/config issue
   - missing or contradictory scope
3. Fix only current-goal failures in scope.
4. Convert non-blocking failures or observations into follow-up issues.
5. Re-run the proving check after any fix.

## Evidence route before terminal outcomes

Before reporting a terminal outcome such as `PASS`, `FAIL`, `HANDOFF`, `BLOCKED`, `ready`, `done`, `fixed`, or `not enough evidence`, execute the planned Evidence route or update it with the closest available direct evidence.

Do not stop at code inspection or static reasoning when existing tests, project scripts, browser checks, `curl`/API smoke checks, disposable containers, clients, or focused reproductions can cheaply exercise the claim.

Credentials and access are not automatic skip reasons. Use authorized available access when it is already in scope; use `HANDOFF` when the parent or user holds the needed env/profile/device/service/credential path and the requested probe is bounded; use `BLOCKED` only when no bounded authorized route exists.

## Rules

- Fresh verification beats memory.
- Narrow verification is fine when it directly proves the changed path.
- Final readiness needs broader evidence than a local task check.
- Acceptance criteria must be covered by tests or explicit manual checks wherever possible.
- Execute the planned Evidence route before any terminal outcome, or revise it with the closest bounded direct evidence that was actually available.
- If the proving check fails, report failure instead of softening it.
- Do not rely on earlier runs once new changes have been made.
- Do not claim readiness from partial evidence unless the unverified areas are listed as risk, follow-up, or blocker.

## Common mistakes

- saying something should pass without running it
- relying on stale output
- claiming closure from partial evidence
- treating confidence as proof
- running broad tests while skipping the targeted check that proves the change
- omitting failed or skipped acceptance criteria from the report

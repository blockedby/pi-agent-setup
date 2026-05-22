---
name: aad-reporting
description: Use when an AAD owner or supporting agent is finishing delegated work and needs to produce a compact, reusable report with the shared Task, Context, evidence, Issues, Verdict, and Next-agent brief structure.
---

# AAD Reporting

## Overview

Use this skill when you are finishing work in Advanced Agent Development and need to leave a report that makes continuation cheap.

The report is a continuation packet, not a diary.

## Use this report structure

```md
## Task
- Mission: <the concrete job I executed>
- Target: <exact area / files / system / environment>
- Boundaries: <scope / do-not-touch / escalation limits>
- Done when: <what outcome would satisfy this job>
- Expected evidence: <what proof / artifact / decision this job should return>

## Context
- Thread: <...>
- Slice: <...>
- Worktree: <...>
- Branch: <...>
- Verify scope: <...>
- Review target: <...>

## Spec compliance
- Requirement / AC: <requirement or acceptance criterion>
  - Status: <done / partial / missing / not applicable>
  - Evidence: <test/check/file/artifact/decision>
  - Gap if any: <none / exact missing work or blocker>

## Acceptance verification
- AC1: <criterion>
  - Covered by: <test/check/manual evidence>
  - Result: <passed / failed / not run>
  - Evidence: <command, file, artifact, or short output>
- AC2: <criterion>
  - Covered by: <test/check/manual evidence>
  - Result: <passed / failed / not run>
  - Evidence: <command, file, artifact, or short output>

## System readiness
- Routes / registration: <done / not relevant / missing>
- Services / APIs: <done / not relevant / missing>
- Config / env / secrets: <done / not relevant / missing / blocked>
- Permissions / access: <done / not relevant / missing / blocked>
- Database / migrations: <done / not relevant / missing>
- Frontend-backend integration: <done / not relevant / missing>
- Runtime / deployment wiring: <done / not relevant / missing / blocked>

## Verification run
- Local / targeted checks:
  - <command/check>: <passed / failed / not run>
    - Evidence: <short output, artifact, or reason>
- Local / full checks:
  - <command/check>: <passed / failed / not run>
    - Evidence: <short output, artifact, or reason>
- Remote checks / CI:
  - Status: <not available before push / passed / failed / not checked>
  - Evidence: <PR/check URL, job name, or reason>

## Issues
### Issue R-01: <short title>
- Description: <what exactly was found>
- Evidence: <short exact proof>
- Resolution: <what was done here>
- Depends on: <none / ...>

### Issue F-01: <short title>
- Description: <what exactly was found>
- Evidence: <short exact proof>
- Current handling: <what was done now>
- Trade-off: <short explanation>
- GitHub follow-up: <created #123 / updated #123>
- Depends on: <none / ...>

### Issue U-01: <short title>
- Description: <what exactly remains unresolved>
- Evidence: <short exact proof>
- Why unresolved: <external blocker / hard role boundary / unsafe scope boundary>
- Needed next: <exact next action>
- Depends on: <none / ...>

## Side findings
- Blocking findings folded into active work: <none / list issue IDs>
- Non-blocking findings tracked separately: <none / GitHub issue links>

## Verdict
- Status: <success / partial / blocked / failed>
- Goal state: <fully achieved / partially achieved / not achieved>
- Final readiness: <ready / not ready / ready except explicit limitation / not applicable for supporting report>
- Summary: <one short operational statement based on the evidence above>

## Next-agent brief
- Objective: <what still needs to be achieved>
- Target: <exact area / files / system>
- Settled already: <what is already established and should not be re-explored first>
- Boundaries: <constraints / do-not-touch>
- Verification target: <what should prove closure>
- Expected output: <what the next actor should return>
```

Use every section that applies to the report scope. Owner-level and final reports must fill `Spec compliance`, `Acceptance verification`, `System readiness`, `Verification run`, `Issues`, and `Side findings`. Supporting-agent reports may mark owner-only sections as `not applicable` when the delegated scope does not include them. Remote checks / CI should be reported only when a branch or PR has been pushed and such checks exist; before push, record it as `not available before push` rather than treating it as skipped verification.

## Fill rules

- Keep `Mission` operational, not vague.
- Put completed outcomes into `Spec compliance`, `Acceptance verification`, `System readiness`, or `Issues` instead of duplicating them in a separate summary section.
- Use `R-*` for issues fully resolved in the current work.
- Use `F-*` for tracked follow-up; every `F-*` must carry a GitHub issue.
- Use `U-*` only when the original goal is still unresolved and safe continuation stopped on a real boundary.
- Blocking side findings must be added to active work or reported as `U-*`; they are not follow-ups.
- Non-blocking side findings should be grouped into a follow-up issue when that is cheaper than many small issues.
- Keep each issue self-contained; do not scatter description, evidence, and outcome across sections.
- Include `Next-agent brief` only when continuation is needed.

## Finish-time checklist

- [ ] My report is understandable without opening GitHub first.
- [ ] Each completed outcome is represented in spec compliance, acceptance verification, system readiness, or resolved issues with short exact evidence.
- [ ] Each acceptance criterion has a test, check, manual evidence, or explicit waiver.
- [ ] System readiness gaps are listed when the task touches integration, config, runtime, or deployment wiring.
- [ ] Each issue is self-contained.
- [ ] Every `F-*` has a GitHub issue reference.
- [ ] Every `U-*` reflects a real stop condition, not ordinary leftover work.
- [ ] If continuation is needed, the `Next-agent brief` makes the next step cheap.

## Common mistakes

- turning the report into a narrative story
- using vague mission or target descriptions
- adding a duplicate completed-summary section instead of filling the evidence sections
- creating `F-*` without a GitHub issue
- using `U-*` when safe continuation still exists
- claiming final readiness without acceptance verification
- hiding skipped checks or available remote/CI failures

---
name: aad-reporting
description: Use when an AAD owner or supporting agent is finishing delegated work and needs to produce a compact, reusable report with the shared Task, Context, Verdict, Completed, Issues, and Next-agent brief structure.
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

## Verdict
- Status: <success / partial / blocked / failed>
- Goal state: <fully achieved / partially achieved / not achieved>
- Summary: <one short operational statement>

## Completed
- <completed result>
  - Evidence: <short exact proof>

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

## Next-agent brief
- Objective: <what still needs to be achieved>
- Target: <exact area / files / system>
- Settled already: <what is already established and should not be re-explored first>
- Boundaries: <constraints / do-not-touch>
- Verification target: <what should prove closure>
- Expected output: <what the next actor should return>
```

## Fill rules

- Keep `Mission` operational, not vague.
- Put only actual completed outcomes in `Completed`, with short exact evidence.
- Use `R-*` for issues fully resolved in the current work.
- Use `F-*` for tracked follow-up; every `F-*` must carry a GitHub issue.
- Use `U-*` only when the original goal is still unresolved and safe continuation stopped on a real boundary.
- Keep each issue self-contained; do not scatter description, evidence, and outcome across sections.
- Include `Next-agent brief` only when continuation is needed.

## Finish-time checklist

- [ ] My report is understandable without opening GitHub first.
- [ ] Each completed item has short exact evidence.
- [ ] Each issue is self-contained.
- [ ] Every `F-*` has a GitHub issue reference.
- [ ] Every `U-*` reflects a real stop condition, not ordinary leftover work.
- [ ] If continuation is needed, the `Next-agent brief` makes the next step cheap.

## Common mistakes

- turning the report into a narrative story
- using vague mission or target descriptions
- mixing unfinished work into `Completed`
- creating `F-*` without a GitHub issue
- using `U-*` when safe continuation still exists

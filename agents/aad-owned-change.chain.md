---
name: aad-owned-change
description: AAD owned implementation workflow: slice owner implements, reviewer reviews, test auditor audits, owner integrates.
---

## aad-slice-owner

Own this change end-to-end under repo AAD rules. Create or enter the appropriate repo-local worktree if implementation is needed, keep scope tight, make reasonable commits, and run fresh verification. Do not merge unless explicitly asked. Request: {task}

## aad-reviewer

Review the completed AAD slice read-only. Check correctness, workflow drift, verification gaps, and risky assumptions. Use the slice report/context below:

{previous}

## aad-test-auditor

Audit whether the verification evidence is sufficient for the completed AAD slice and reviewer findings. Identify missing or too-narrow checks. Context:

{previous}

## aad-slice-owner

Integrate the AAD reviewer and test-auditor feedback below. Fix only current-goal issues, rerun necessary verification, and produce the final AAD report. Do not merge unless explicitly asked.

Feedback:

{previous}

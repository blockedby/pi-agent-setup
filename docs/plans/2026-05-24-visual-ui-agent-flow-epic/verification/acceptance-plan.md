# Acceptance plan

## Audit target
Visual UI Agent Flow Epic final acceptance audit.

## Acceptance criteria to verify
- T1 shared visual/UI rubric in `AGENTS.md`.
- T2 `agents/chrome-browser-agent.md` visual review mode.
- T3 `agents/visual-critic.md` read-only screenshot-first critic.
- T4 `agents/aad-acceptance-auditor.md` visual gate.
- T5 `agents/aad-slice-owner.md` visual design/composition gate.
- T6 optional `agents/visual-ui-change.chain.md` scoped chain and owner accountability.
- T7 local setup and docs evidence: `scripts/update-local.sh`, Pi smoke test, and no `codex_task` exposure in installed agents.

## Evidence sources to check
- Current file contents in `AGENTS.md`, `README.md`, and the touched agent/chain files.
- Task package reports for T1-T7 implementation evidence.
- Local verification evidence recorded in T7 report.
- Repository grep for `codex_task` in repo agents and installed local agent paths as reported.

## Decision rule
Accept only if every criterion has concrete evidence and no unresolved visual-gate or local-setup blocker remains.

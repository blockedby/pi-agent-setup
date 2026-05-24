# Draft five specialized AAD quality skills

PI_RESULT: PASS
TASK: Draft five specialized AAD quality skills
TASK_PACKAGE: docs/plans/2026-05-24-visual-ui-agent-flow-epic
REPORT_PATH: docs/plans/2026-05-24-visual-ui-agent-flow-epic/reports/aad-implementer-five-quality-skills.md
ADDITIONAL_OUTPUT_PATH: docs/plans/2026-05-24-visual-ui-agent-flow-epic/reports/subagent-five-quality-skills-output.md
PROGRESS_PATH: docs/plans/2026-05-24-visual-ui-agent-flow-epic/progress/aad-implementer-five-quality-skills.md
COMMITS:
- not committed: user explicitly requested no commit

FILES_CHANGED:
- skills/frontend-ui-quality/SKILL.md: new frontend/UI implementation quality checklist and evidence mapping.
- skills/backend-api-data-quality/SKILL.md: new backend/API/data quality checklist and evidence mapping.
- skills/devops-runtime-readiness/SKILL.md: new config/deployment/runtime readiness checklist and evidence mapping.
- skills/visual-composition-quality/SKILL.md: new design/composition and visual anti-pattern gate checklist.
- skills/acceptance-evidence-gate/SKILL.md: new acceptance evidence matrix, freshness, waiver, and done-state guardrail checklist.
- docs/plans/2026-05-24-visual-ui-agent-flow-epic/progress/aad-implementer-five-quality-skills.md: progress notes for this implementer task.
- docs/plans/2026-05-24-visual-ui-agent-flow-epic/reports/subagent-five-quality-skills-output.md: final requested findings/report.
- docs/plans/2026-05-24-visual-ui-agent-flow-epic/reports/aad-implementer-five-quality-skills.md: implementer report mirror for the delegated report path.

## Skill purpose summary

- `frontend-ui-quality`: exists to pull frontend implementation concerns out of the general implementer prompt into a reusable checklist for component reuse, styling consistency, accessibility, responsive behavior, and UI-state coverage. It maps findings into `AC_VERIFICATION`, `QUALITY_CHECKS`, `QUALITY_NOTES`, `Acceptance verification`, `System readiness`, `Verification run`, `Issues`, and `browser-visual-report` where screenshots are needed.
- `backend-api-data-quality`: exists to focus backend/API/data checks on contracts, validation, auth/permissions, migrations, idempotency, and data-path performance. It maps findings into implementer `QUALITY_NOTES` plus owner/auditor `System readiness` and `Verification run` fields.
- `devops-runtime-readiness`: exists to make env/config/container/deployment wiring checks explicit without creating a new deployment workflow. It maps readiness findings into `QUALITY_CHECKS`, `QUALITY_NOTES`, `Acceptance verification`, `System readiness`, and acceptance-auditor readiness coverage.
- `visual-composition-quality`: exists to capture the pre-implementation/review composition decision and hard visual anti-patterns from AGENTS.md/research while delegating persisted screenshot evidence to `browser-visual-report`.
- `acceptance-evidence-gate`: exists to centralize evidence completeness, freshness, waiver, and done-state guardrails while preserving `aad-reporting`, `aad-implementation-report`, `aad-acceptance-auditor`, and `browser-visual-report` structures.

## Recommended later agent wiring

No agent files were changed. Suggested follow-up wiring after human review:

- `aad-implementer`: consider adding `frontend-ui-quality`, `backend-api-data-quality`, and `devops-runtime-readiness` to explicit skills because this agent uses `inheritSkills: false` and already contains matching inline guidance.
- `aad-slice-owner`: consider loading `visual-composition-quality` for visual/UI design gates and `acceptance-evidence-gate` before final slice reporting.
- `aad-acceptance-auditor`: consider loading `acceptance-evidence-gate`, `devops-runtime-readiness`, and `visual-composition-quality` for acceptance audits involving evidence freshness, runtime readiness, or visual/UI surfaces.
- Browser/visual reviewer agents, if present in this repo later: consider loading `visual-composition-quality` alongside existing `browser-visual-report`.

AC_VERIFICATION:
- Five new `skills/*/SKILL.md` files exist with valid frontmatter: `python3` frontmatter validation passed for all five files — passed.
- Skills are concise, non-overlapping, and operational: files are 52, 51, 52, 61, and 69 lines respectively; scopes are frontend, backend/data, runtime, visual composition, and acceptance evidence — passed.
- Skills refer back to existing report/task package structures rather than replacing them: grep confirmed mappings to `QUALITY_CHECKS`, `QUALITY_NOTES`, `Acceptance verification`, `System readiness`, `Verification run`, `Issues`, and/or `Acceptance coverage` across the drafts — passed.
- Do not change agents and do not commit: no `agents/*` files edited; no commit created — passed.

TESTS_RUN:
- `test -f` loop for five target files before creation: passed as RED/document check; all five were missing before drafting.
- `python3` frontmatter/reference validation over five new `SKILL.md` files: passed after one draft-check correction to `devops-runtime-readiness` wording.
- `grep -R "^name:\|^description:\|QUALITY_CHECKS\|QUALITY_NOTES\|Acceptance verification\|System readiness\|Verification run\|Issues\|Acceptance coverage" ...`: passed; confirmed required frontmatter and report-field references.
- `wc -l` on five new skill files: passed; 285 total lines.
- `git status --short`: passed for status visibility; shows only untracked task artifacts/skill drafts plus pre-existing untracked research report.

QUALITY_CHECKS:
- Frontmatter/static validation: passed via `python3` script checking opening/closing YAML fence, matching `name`, non-empty `description`, and required report-reference terms.
- Report field reference check: passed via `grep -R` for key existing AAD report fields.
- Broad build/smoke test: not run; task only adds draft Markdown skills and prompt requested exploratory draft work for review.

QUALITY_NOTES:
- Readability/reuse: followed existing `skills/*/SKILL.md` frontmatter and concise Markdown checklist style; reused existing AAD report structures rather than inventing formats.
- Error handling/logging: not relevant; no runtime code changed.
- Backend/API/data: addressed in the new `backend-api-data-quality` checklist; no backend code changed.
- Frontend/UI: addressed in `frontend-ui-quality` and `visual-composition-quality`; no UI code changed.
- DevOps/runtime: addressed in `devops-runtime-readiness`; no runtime/config code changed.
- Security: skills explicitly caution against logging/committing secrets; no secrets touched.
- Concurrency/idempotency: covered in backend/API/data checklist for jobs/webhooks/writes; no runtime behavior changed.
- Compatibility/performance: skills emphasize preserving contracts and avoiding obvious performance regressions; no production behavior changed.

SIDE_FINDINGS:
- Blocking: none.
- Non-blocking follow-up candidates: human review should decide final wording and whether/where to wire these skills into agent frontmatter.

NOTES: The existing untracked `research-agent-prompt-repos.md` was present before editing and was only read as requested. No Codex delegation was used.

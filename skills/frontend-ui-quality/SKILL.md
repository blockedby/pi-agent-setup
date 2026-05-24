---
name: frontend-ui-quality
description: Use when planning, implementing, or reviewing frontend/UI changes that need evidence for component reuse, styling consistency, accessibility, responsive behavior, and UI-state coverage within existing AAD reports.
---

# Frontend UI Quality

Use this skill as a focused checklist for frontend/UI quality. It is not a new agent, workflow, or report format. Record findings in the existing AAD task package and reports.

## When to use

Use when a task touches frontend components, routes, forms, client data fetching, styling, public UI states, or browser-visible behavior.

For screenshot-first visual judgment, also use `browser-visual-report`. For design/composition strategy, use `visual-composition-quality`.

## Inputs

- Delegated acceptance criteria and verification plan.
- Existing adjacent components, hooks, client services, routes, styles, and tests.
- Applicable task package/report paths from `aad-task-package`.

## Checklist

1. Reuse existing UI primitives: shared components, layout wrappers, design tokens, hooks, routing helpers, form helpers, and API clients before adding new code.
2. Match local styling conventions: class naming, CSS modules/Tailwind/styled patterns, spacing scale, typography, colors, breakpoints, and responsive containers.
3. Preserve component contracts: props, events, route names, navigation behavior, data shapes, and public UI hierarchy unless the task explicitly allows a breaking change.
4. Cover required UI states: loading, empty, error, success, disabled/submitting, permission-denied, and partial-data states when relevant to the acceptance criteria.
5. Preserve accessibility basics: semantic elements, visible labels, keyboard operation, focus states, alt text, form errors, disabled semantics, and readable contrast.
6. Check responsive integrity: mobile, tablet, and desktop breakpoints do not clip, overlap, overflow horizontally, or hide required controls.
7. Avoid one-off fetch logic or duplicated client state when an existing API/client hook or state pattern applies.
8. Keep browser/manual evidence scoped to the changed surface; do not claim final acceptance from implementation checks alone.

## Evidence mapping

Map findings into existing report fields instead of creating a new report shape:

- `aad-implementation-report`
  - `AC_VERIFICATION`: UI behavior proven by targeted tests, browser checks, or manual evidence.
  - `QUALITY_CHECKS`: frontend lint/typecheck/test/build commands and results.
  - `QUALITY_NOTES` → `Frontend/UI`: component reuse, styling convention, a11y/responsive/state handling notes.
  - `QUALITY_NOTES` → `Security` and `Compatibility/performance`: no unsafe rendering, route/API contract, or avoidable render/data-fetch regressions.
- `aad-reporting`
  - `Acceptance verification`: UI acceptance criteria and evidence.
  - `System readiness` → `Frontend-backend integration`: client/API wiring and route registration status.
  - `Verification run`: browser/manual checks plus local frontend checks.
  - `Issues`: unresolved UI state, accessibility, responsive, or integration gaps.
- `browser-visual-report`
  - Screenshot artifacts, worst screenshot, and visual issues when the changed surface is visually significant.

## Output guidance

Use short bullets with exact file paths, commands, routes, viewports, and states checked. If evidence is missing, report the gap and the closest safe next check rather than filling with subjective claims.

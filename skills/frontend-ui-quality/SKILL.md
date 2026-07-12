---
name: frontend-ui-quality
description: Select for frontend routes, components, forms, styling, client data, or browser-visible behavior; apply focused reuse, state, accessibility, responsive, and integration checks without creating another report layer.
---

# Frontend / UI Quality

This is a task-selected checklist, not a new workflow or report.

## Check the touched surface

- reuse shared components, layouts, tokens, hooks, clients, form helpers, and routing patterns;
- match local styling, spacing, typography, breakpoint, and state-management conventions;
- preserve component props/events, routes/navigation, data shapes, and public hierarchy unless change is explicitly accepted;
- cover relevant loading, empty, error, success, disabled/submitting, permission-denied, and partial-data states;
- preserve semantic markup, labels, keyboard/focus behavior, alt text, form errors, disabled semantics, and readable contrast;
- check mobile, tablet, and desktop integrity where the change is responsive;
- avoid duplicate fetch/state logic and obvious render or network regressions;
- verify client/API wiring when the UI depends on backend changes.

## Browser boundary

Implementation checks do not replace browser evidence. Any browser automation/evidence uses the separate browser agent. Use `visual-composition-quality` and `full-visual` coverage only for product-quality visual surfaces.

## Evidence

Record acceptance proof and exact checks in the current task/result. Add short `QUALITY_NOTES` only for material reuse, state, accessibility, responsive, integration, security, compatibility, or performance findings. Do not enumerate irrelevant categories.

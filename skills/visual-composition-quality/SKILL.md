---
name: visual-composition-quality
description: Use when planning or reviewing product-quality visual surfaces that need a concise composition strategy, visual anti-pattern gates, and screenshot-first evidence mapping within existing AAD reports.
---

# Visual Composition Quality

Use this skill as a focused checklist for product-quality visual composition. It is not a new agent, workflow, or report format. It complements `browser-visual-report`, which owns persisted screenshot evidence.

## When to use

Use for public page visuals, landing pages, templates, hero sections, marketing blocks, dashboards, forms, or other UI surfaces where first-glance composition and polish affect acceptance.

Do not use this as a heavyweight gate for trivial copy-only, backend-only, or invisible implementation changes.

## Inputs

- Delegated design/composition decision or owner constraints.
- Brand/layout constraints, target viewport set, route/URL, and visual acceptance criteria.
- Existing components, sections, tokens, spacing/typography rules, and screenshot artifacts when available.

## Composition decision checklist

Before implementation or review, record the smallest useful decision:

1. Primary user message and main CTA or task.
2. Selected layout strategy: hero + proof, card grid, split panel, form flow, dashboard hierarchy, content-first page, or other named pattern.
3. Visual hierarchy: what should dominate, support, and recede.
4. Grouping/alignment rules: grids, columns, section rhythm, image/card placement, and whitespace intent.
5. Responsive intent: how the composition should simplify on mobile/tablet and avoid over-wide desktop emptiness.
6. Brand constraints: tone, color/contrast limits, typography style, image/mockup treatment, and forbidden motifs.

## Anti-pattern gate

Treat these as hard visual risks unless the owner explicitly waives them:

- clipped, overlapping, hidden, or unusably positioned primary text, forms, controls, or CTAs;
- broken responsive layout, horizontal overflow, awkward one-word-per-line headings, or cramped mobile composition;
- collage/debug-looking composition, random floating assets, disconnected cards, or decoration overpowering content;
- generic low-premium template output, weak hierarchy, weak typography, inconsistent spacing, or unintentional dead zones;
- unreadable contrast, same-tone text/background, missing/broken/stretched assets, or visibly placeholder-only visuals.

## Evidence mapping

Map findings into existing report fields instead of creating a new report shape:

- `aad-reporting`
  - `Spec compliance`: composition strategy and anti-pattern requirements satisfied or missing.
  - `Acceptance verification`: screenshot/manual evidence tied to visual acceptance criteria.
  - `Issues`: unresolved composition or anti-pattern failures.
- `aad-implementation-report`
  - `AC_VERIFICATION`: implemented visual behavior checked by route/viewport/manual evidence.
  - `QUALITY_NOTES` → `Frontend/UI`: component/style reuse, responsive behavior, and visual-state handling.
- `browser-visual-report`
  - `Screenshot matrix`, `Worst screenshot`, `First-glance verdict`, and `Issues by priority` for screenshot-first visual evidence.
- `aad-task-package`
  - Put screenshots under `artifacts/screenshots/<scope>/<run-id>/` and reports under the task package paths.

## Output guidance

Use concise, screenshot-visible language: route, viewport, section, artifact path, and exact observed risk. Objective DOM metrics can support the decision, but they cannot override an obvious visual failure in the screenshot.

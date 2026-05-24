---
name: browser-visual-report
description: Use when a browser or visual-review agent needs to save screenshot artifacts and write a screenshot-first visual/UI evidence report inside an AAD task package.
---

# Browser Visual Report

Use this skill when `chrome-browser-agent`, `visual-critic`, an acceptance auditor, or another delegated browser/visual reviewer is collecting screenshot-first evidence for a visual/UI task.

The report is visual evidence, not implementation ownership and not final acceptance by itself. The slice owner and `aad-acceptance-auditor` decide final done-state.

## Durable paths

Prefer explicit paths from the delegated prompt. When only a task package and visual scope are provided, use these defaults:

```text
<task-package>/reports/browser-<scope>.md
<task-package>/verification/browser.md
<task-package>/artifacts/screenshots/<scope>/<run-id>/<viewport>-<section-or-scroll>.png
```

Where:

- `<scope>` is a short slug such as `landing-hero`, `templates-page`, or `checkout-form`.
- `<run-id>` is a stable timestamp or attempt slug, for example `2026-05-24T142233Z` or `attempt-2`.
- `<viewport>` uses `WIDTHxHEIGHT`, for example `390x844`.
- `<section-or-scroll>` is semantic when possible (`hero`, `features`, `pricing-cta`, `footer`) or positional (`top`, `25pct`, `50pct`, `75pct`, `bottom`).

Examples:

```text
docs/plans/2026-05-24-landing-polish/artifacts/screenshots/landing-hero/2026-05-24T142233Z/390x844-hero.png
docs/plans/2026-05-24-landing-polish/artifacts/screenshots/landing-hero/2026-05-24T142233Z/1440x900-top.png
docs/plans/2026-05-24-landing-polish/reports/browser-landing-hero.md
```

If no task package path is provided, return the report inline and state that screenshots were not persisted to a task package.

## Screenshot set

Use the viewport set from the prompt or project guidance. If visual/UI work has no explicit viewport set, use this default set unless the app cannot support it:

```text
320x800
390x844
768x1024
1280x800
1440x900
1680x945
1920x1080
```

For each viewport, inspect more than the first fold when the page is scrollable. Prefer semantic sections when obvious from DOM/page structure. Otherwise use representative scroll positions:

```text
top
25pct
50pct
75pct
bottom
```

## Inspection method

For every screenshot, inspect before deciding pass/fail:

1. First glance: page purpose, primary message, CTA, and whether the composition feels intentional.
2. Layout integrity: clipped/cropped elements, overlapping text or controls, horizontal overflow, offscreen elements, stretched images, missing/broken assets, and random floating cards/media.
3. Text readability: contrast, same-tone foreground/background, awkward wrapping, orphan words, cramped leading, tiny text, and weak CTA text.
4. Composition: divide the screenshot into a rough 3x3 grid and check visual weight, empty space, grouping, alignment, hierarchy, dead zones, overloaded zones, decoration overpowering content, and disconnected components.
5. Responsive behavior: compare mobile, tablet, and desktop for compressed desktop layouts, sparse over-wide desktop layouts, or breakpoint-specific breakage.

## Hard visual failures

Treat any of these as a hard failure unless explicitly waived:

- primary text, form fields, navigation, or CTA is overlapped, hidden, clipped, cropped, or unusably positioned;
- CTA is missing, unreadable, below the expected fold without reason, or visually weaker than decoration;
- image, mockup, card, or media object is clipped in a way that looks accidental;
- text contrast is too low, text is same-tone with the background, or important text is hard to read;
- line wrapping creates ugly orphan words, one-word-per-line headings, or unreadable text blocks;
- layout has large accidental blank panels, dead zones, or overloaded regions without intent;
- visual objects feel randomly scattered rather than grouped/aligned;
- section looks like a debug placeholder, AI collage, unstyled SaaS template, stock block, or low-premium generated layout;
- mobile/tablet layout has obvious first-glance breakage;
- important assets are missing, broken, stretched, pixelated, inconsistent, or visibly placeholder-only.

## Worst screenshot selection

Do not choose the worst screenshot by vague intuition.

For each screenshot:

1. Mark hard failures.
2. Score soft risk from 0 to 3 in each category:

```text
composition badness: 0-3
readability risk: 0-3
spacing/alignment risk: 0-3
responsive awkwardness: 0-3
product-quality risk: 0-3
```

Worst screenshot rules:

1. Any hard failure outranks screenshots without hard failures.
2. Otherwise choose the screenshot with the highest total soft-risk score.
3. On ties, prefer mobile over desktop, above-the-fold/hero over lower sections, and CTA/form/product-critical sections over secondary content.

## Report shape

Write this shape to the report path or return it inline:

```md
## Task package
- Task name: <name>
- Task package: <path or not provided>
- Report path: <path written or not provided>
- Screenshot artifact root: <task-package>/artifacts/screenshots/<scope>/<run-id>/ or not persisted
- Scope: <visual surface reviewed>
- URL / route: <local URL, deployed URL, route, or not provided>

## Screenshot matrix
| Viewport | Section / scroll | Artifact path | Hard failures | Soft score |
| --- | --- | --- | --- | --- |
| <390x844> | <hero/top> | <path> | <none/list> | <total; category scores> |

## Worst screenshot
- Path: <artifact path>
- Viewport: <WIDTHxHEIGHT>
- Section / scroll: <section or position>
- Hard failures: <none / list>
- Soft risk score: <total and category scores>
- Why this is worst: <concise screenshot-visible reason>

## First-glance verdict
- Verdict: <pass / needs polish / reject>
- Would a product owner reject this screenshot immediately? <yes / no>
- Reason: <one or two sentences>

## Issues by priority
1. <screenshot-visible issue, with viewport/artifact reference>
2. <screenshot-visible issue, with viewport/artifact reference>
3. <screenshot-visible issue, with viewport/artifact reference>

## Objective supporting checks
- Horizontal overflow: <passed / failed / not checked + evidence>
- Clipped or overlapped elements: <passed / failed / not checked + evidence>
- DOM intersections: <passed / failed / not checked + evidence>
- Console/network blockers: <passed / failed / not checked + evidence>
- Missing/broken assets: <passed / failed / not checked + evidence>

## Coverage gaps and waivers
- Missing viewports/sections: <none / list>
- Waivers: <none / explicit waiver and source>
- Stale evidence risk: <none / exact risk>

## Recommendation
- Status: <pass / needs polish / reject>
- Next action: <accept visual evidence / route focused fix / collect missing screenshots / ask owner for waiver>
```

## Rules

- Save screenshots under the task package `artifacts/screenshots/` tree when a task package exists.
- Do not store screenshots outside the task package unless the user explicitly asks.
- Use relative artifact paths in reports when possible.
- Do not include cookies, tokens, local storage, private profile data, or secrets in screenshots or logs.
- If a screenshot may contain sensitive data, stop and ask for direction before persisting it.
- Do not claim final acceptance. Say what the screenshot evidence proves and what remains uncovered.
- Objective metrics cannot turn an obvious visual failure into a pass.

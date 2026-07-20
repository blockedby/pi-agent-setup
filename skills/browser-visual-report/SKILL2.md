---
name: browser-visual-report
description: Collect current, traceable screenshot evidence for a browser-visible change and write a concise visual report covering representative viewports, states, visible failures, objective supporting checks, evidence gaps, and the clearest next action. Use after a surface can be rendered; do not use it to design or implement the interface.
---

# Browser Visual Report

Use this skill to decide which screenshots are needed and how to record what they prove. The report is a durable, screenshot-first account of the rendered surface, not a design brief, implementation plan, or final product acceptance decision.

Use `visual-composition-quality` for the intended hierarchy, flow, composition, and visual character. Use `frontend-ui-quality` for correctness in components, state, accessibility, responsive behavior, and performance. This skill observes and reports those outcomes without inventing the criteria or fixing the code.

## Core principles

1. **Collect evidence for decisions, not screenshots for volume.** Every artifact should cover a meaningful viewport, state, section, risk, or acceptance criterion. Extra captures that prove nothing make the important evidence harder to find.
2. **Make every artifact traceable.** A reviewer must be able to identify the surface, route, build or revision, viewport, state, data conditions, capture time, and artifact path without guessing.
3. **Inspect the image before trusting measurements.** Screenshots expose hierarchy, readability, grouping, accidental crops, and overall coherence that DOM metrics miss. Technical checks can independently prove overflow, overlap, contrast, console, or asset failures, but they cannot turn an obvious visual failure into a pass.
4. **Cover changed and risky behavior, not the full Cartesian product.** Choose representative viewports and states from the brief, product support, breakpoints, and changed behavior. Expand coverage when evidence reveals a problem.
5. **Separate failure from missing evidence.** A visible contradiction is a finding. A viewport, state, or run identity that was never captured is an evidence gap. Do not convert uncertainty into an invented pass or defect.
6. **Name the visible consequence.** Report what the user cannot see, understand, trust, or do, with a precise artifact reference. Avoid unexplained labels such as `bad`, `generic`, or `not polished`.
7. **Keep the report reproducible and private by default.** Store only the evidence needed for the task, use stable paths, and exclude secrets, private profiles, personal data, and unrelated machine details.

## Required inputs

Collect or explicitly mark missing:

- task name, visual scope, acceptance criteria, and report destination;
- design brief, reference surfaces, or the approved visual intent;
- URL or route and instructions for starting or reaching the tested build;
- build, deployment, revision, or commit identity;
- supported viewport range, breakpoint risks, input modes, themes, and locales;
- important default, loading, empty, error, success, pending, permission, expanded, or interaction states;
- stable test data, account role, feature flags, and prerequisites needed to reproduce the surface;
- privacy constraints, explicit waivers, and areas that must not be persisted.

If the build, route, state, or reference is ambiguous, record the ambiguity. Do not imply that screenshots from an unidentified or stale surface prove the current change.

## Artifact locations and identity

Prefer paths supplied by the task. Otherwise keep the report and artifacts inside the current task package or another explicitly approved evidence location:

```text
<task-package>/reports/browser-<scope>.md
<task-package>/verification/browser.md
<task-package>/artifacts/screenshots/<scope>/<run-id>/<viewport>-<state>-<section>.png
```

Use:

- a short semantic `<scope>`, such as `checkout-form` or `project-dashboard`;
- a stable UTC timestamp or attempt identifier for `<run-id>`;
- CSS viewport dimensions such as `390x844` for `<viewport>`;
- semantic state and section names such as `loading-results`, `error-payment`, `top`, `filters`, or `confirmation`.

If no approved persistence location exists, return the report inline and state that artifacts were not persisted. Do not create a historical plans package merely to satisfy this skill.

Record enough run identity to distinguish evidence:

```md
Run ID:
Captured at:
Revision or build:
URL or route:
Browser and device emulation:
Theme, locale, role, flags, and data fixture:
```

## Build a risk-based coverage matrix

Start with the viewport and state requirements from the task or product. When none are supplied, use a small fallback set and mark it as provisional:

```text
390x844   representative narrow mobile
768x1024  representative tablet or narrow split layout
1440x900  representative desktop
```

Also verify reflow at `320` CSS pixels when web accessibility is in scope. This means the page should remain readable and operable at a viewport 320 CSS pixels wide without two-dimensional scrolling, except for content that inherently requires it, such as a large data table or map. Record an explicit waiver when the surface or exception is out of scope.

Adapt the matrix instead of treating the fallback as a universal device list:

- capture immediately below and above a changed or suspicious breakpoint;
- include wide desktop only when container behavior, density, or media composition can change there;
- include landscape, safe-area, touch, zoom, theme, or locale variants only when supported behavior or task risk requires them;
- include the default state and every changed or acceptance-critical state;
- include loading, empty, error, permission, long-content, or interaction states when their visual behavior is part of the change or a likely failure mode;
- avoid multiplying every viewport by every state when one capture already proves the shared behavior.

For scrollable pages, capture semantic regions that carry distinct decisions or visual structures. Use positional captures such as `top`, `middle`, and `bottom` only when the page has no meaningful landmarks or when continuous flow itself is under review.

Write the intended matrix before capture:

| Viewport | State | Section | Why this evidence is needed |
| --- | --- | --- | --- |
| `<390x844>` | `<default>` | `<top>` | `<primary task and narrow hierarchy>` |

## Prepare the surface

- Confirm that the intended build and route are actually loaded.
- Reach the state using a reproducible action or documented fixture; do not invent data that changes the product meaning.
- Wait for the state being captured: fonts, critical images, data, and animations should settle unless loading or transition behavior is the subject.
- Capture loading or pending states deliberately rather than accidentally catching an unfinished frame.
- Keep the same fixture and conditions across comparable screenshots.
- Record any mocked response, feature flag, role, theme, locale, reduced-motion setting, or emulation that materially affects the result.
- Remove only irrelevant nondeterminism such as changing timestamps or rotating content, and document that normalization.
- Check the frame for personal data, tokens, private URLs, browser profile details, notifications, and unrelated applications before saving it.

## Capture and inspect

For each matrix row:

1. Navigate to the exact route and reproduce the named state.
2. Set the CSS viewport and relevant browser or input conditions.
3. Capture the semantic region or full-page flow needed by the criterion.
4. Open the saved artifact and inspect the image itself.
5. Record visible findings before running supporting technical checks.
6. Run only the objective checks that clarify a suspected failure or a stated criterion.
7. Expand the matrix near a breakpoint, state, or section when the first evidence reveals uncertainty.

Inspect in this order:

1. **Evidence validity:** correct surface, build, state, fixture, viewport, and complete artifact.
2. **Human-obvious integrity:** clipping, overlap, hidden controls, unreadable text, broken media, accidental empty regions, or unusable placement.
3. **Brief fidelity:** primary task, intended hierarchy, grouping, reading order, emphasis, visual signature, and required content.
4. **System continuity:** typography, spacing, tokens, component behavior, imagery, and interaction states relative to the approved product context.
5. **Responsive and state continuity:** whether priority, task order, content, and controls survive the viewport or state change.
6. **Polish:** alignment, wrapping, crop, rhythm, density, and motion residue that affect comprehension or trust.

## Findings and supporting checks

A finding must include:

- the visible condition;
- its user consequence;
- the exact artifact, viewport, state, and section;
- the criterion, brief decision, or product invariant it contradicts;
- supporting technical evidence when it materially clarifies the cause or extent.

Use objective checks in both directions:

- a screenshot can fail even when overflow and intersection checks pass;
- a technical check can independently fail even when the selected screenshot does not make the defect obvious;
- a console or network error matters when it prevents, corrupts, or makes the captured state unreliable;
- DOM bounds, computed styles, contrast calculations, accessibility inspection, and asset status are supporting facts, not substitutes for inspecting the rendered image.

Distinguish clearly:

- **observed failure** — the artifact or technical check shows the problem;
- **pass for covered condition** — the captured condition satisfies the named criterion;
- **not checked** — no relevant check was run;
- **not enough evidence** — the required artifact, state, identity, or reference is missing;
- **waived** — the owner explicitly excluded the condition and the waiver is recorded.

## Severity and worst screenshot

Assign severity from user consequence, not from how easy the defect is to fix:

| Severity | Meaning |
| --- | --- |
| `3 — blocking` | Prevents the primary task, hides required content or controls, is unreadable, or clearly contradicts the brief. |
| `2 — major` | Prominently damages comprehension, orientation, trust, responsive behavior, or a required state. |
| `1 — minor` | Localized polish or consistency issue that does not obscure the task or meaning. |
| `0 — none` | No reportable issue for the covered criterion. |

Do not total aesthetic category scores. A single blocking failure matters more than several minor spacing issues.

Choose the worst screenshot by this order:

1. highest-severity integrity, accessibility, or task failure;
2. clearest contradiction of the approved brief, reference, or required state;
3. greatest visible consequence on comprehension, orientation, trust, or action;
4. on a tie, prefer the primary task, changed state, narrow viewport, or earliest meaningful region.

If no screenshot contains a failure, choose the artifact that places the most visual or interaction pressure on the implementation and explain why it is the strongest representative evidence. If evidence is incomplete, do not label a clean available screenshot as worst merely to conceal the gap.

## Verdict vocabulary

Use one evidence verdict:

- `pass` — the required screenshot coverage is current and no blocking or major visual issue is observed;
- `needs polish` — coverage is sufficient and only minor findings remain;
- `reject` — a blocking or major visual issue contradicts the task, brief, or required behavior;
- `not enough evidence` — required coverage, run identity, state, or reference is missing or unreliable.

The verdict describes the visual evidence set. It does not declare the whole implementation or task accepted. If the surrounding workflow supports only pass or fail, map `not enough evidence` to failure and preserve the missing-evidence reason.

## Report shape

Write the report at the supplied location or return it inline:

```md
## Scope and run identity
- Task:
- Surface and route:
- Report path:
- Artifact root:
- Run ID and capture time:
- Revision or build:
- Browser and emulation:
- Fixture, role, flags, theme, and locale:

## Brief and criteria
- Primary user task:
- Intended hierarchy or composition:
- References and product invariants:
- Acceptance criteria covered:

## Coverage matrix
| Viewport | State | Section | Artifact | Criterion | Result |
| --- | --- | --- | --- | --- | --- |
| <...> | <...> | <...> | <relative path> | <...> | <pass/finding/gap> |

## Worst screenshot
- Artifact:
- Viewport, state, and section:
- Severity:
- Visible consequence:
- Contradicted criterion:
- Why this is the worst representative artifact:

## Evidence verdict
- Verdict: <pass / needs polish / reject / not enough evidence>
- Would an owner reject the rendered result immediately? <yes / no / cannot determine>
- Reason:

## Findings by priority
1. <severity, visible condition, user consequence, criterion, artifact reference>

## Objective supporting checks
- Reflow or horizontal overflow:
- Clipping, overlap, and DOM intersections:
- Contrast and accessible state where checked:
- Console and network blockers:
- Missing, broken, or unstable assets:

## Coverage gaps and waivers
- Missing or unreliable evidence:
- Explicit waivers and source:
- Stale-evidence risk:

## Next action
- <accept the visual evidence / route a focused design or implementation fix / collect named missing evidence / request an explicit decision>
```

Keep artifact paths relative to the report when practical. Link each finding to its strongest artifact rather than repeating the same observation for every screenshot.

## Reporting anti-patterns

Avoid:

- capturing only a desktop hero for a responsive or stateful change;
- applying a fixed seven-viewport grid when three risk-based captures prove the behavior;
- creating dozens of scroll-position screenshots without semantic purpose;
- comparing screenshots from different fixtures, themes, roles, builds, or states without saying so;
- choosing the worst screenshot from a summed taste score that lets minor issues outweigh one serious failure;
- calling absent coverage a pass or describing it as a visual defect;
- letting DOM metrics override obvious clipping, unreadability, weak hierarchy, or broken composition;
- reporting taste words without a visible consequence and criterion;
- diagnosing or prescribing code changes without enough implementation evidence;
- editing the interface while acting as an independent evidence collector;
- persisting screenshots that expose secrets, personal data, private URLs, browser profiles, or unrelated machine information;
- claiming final acceptance for the whole task from the visual report alone.

## Reporting handoff

When this skill is used by itself, return only:

- run identity and evidence location;
- the planned and completed coverage matrix;
- the worst representative screenshot and why it matters;
- prioritized visible findings with artifact references;
- objective supporting checks actually performed;
- evidence verdict, gaps, waivers, and the clearest next action.

Route design contradictions to `visual-composition-quality`, implementation defects to `frontend-ui-quality`, and final done-state decisions to the acceptance owner. Do not silently broaden the report into redesign, code review, implementation, or final acceptance.

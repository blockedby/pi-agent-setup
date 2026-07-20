---
name: frontend-ui-quality
description: Implement or review browser-visible frontend changes for component reuse, explicit UI states, semantic interaction, resilient responsive behavior, accessible forms and controls, efficient data flow, and user-perceived performance. Use after the visual direction is known and before screenshot evidence or final acceptance is produced.
---

# Frontend UI Quality

Use this skill to decide whether a visual design is implemented correctly in frontend code. It translates an approved brief and composition into maintainable components, predictable behavior, accessible interaction, and responsive rendering.

Use `visual-composition-quality` to decide what the interface should communicate and how it should be composed. Use `browser-visual-report` to decide which screenshots to collect and how to record visual evidence. This skill does not invent the visual direction, define a screenshot matrix, score screenshots, or issue a final acceptance verdict.

## Core principles

1. **Implement the product contract, not only the ideal screenshot.** The code must preserve the intended task, content hierarchy, interaction, and behavior across real data, asynchronous transitions, edge states, and supported environments.
2. **Reuse semantics and behavior before reusing appearance.** Prefer existing components, tokens, hooks, clients, and route patterns when their contracts fit. A visually similar component with different meaning or behavior should not be forced into the same abstraction.
3. **Make state explicit.** Model loading, empty, error, success, pending, disabled, partial, and permission states as deliberate product behavior. Scattered booleans and incidental rendering rules create contradictory UI states.
4. **Keep the user's current action responsive.** Typing, selection, navigation, and direct manipulation should react immediately. Localize slow work and defer non-urgent updates instead of freezing or replacing the whole surface.
5. **Treat semantics and accessibility as implementation contracts.** Correct elements, labels, focus behavior, keyboard operation, errors, and announcements are part of the component API, not optional review polish.
6. **Let layout respond to content.** Use CSS layout, intrinsic sizing, wrapping, and content-driven breakpoints before JavaScript measurement or overflow masking. The interface must survive long content, localization, zoom, and narrow widths.
7. **Optimize visible consequences.** Fix waterfalls, layout shifts, blocked interaction, oversized bundles, and unnecessary rendering when they affect the experience. Do not add complexity for speculative micro-optimizations.

## Required inputs

Collect or explicitly mark missing:

- the design brief, acceptance criteria, and primary user task;
- relevant routes, components, hooks, services, styles, tokens, tests, and adjacent implementations;
- required data states, interaction states, navigation behavior, and public component contracts;
- framework, runtime, rendering mode, and relevant version constraints;
- supported viewport range, browsers, input methods, themes, locales, and accessibility requirements;
- backend or client data contracts, including error and permission behavior;
- performance constraints and known high-cost interactions;
- files, APIs, or behavior that must not change.

Do not invent missing product behavior silently. Preserve it as a named implementation question when the answer changes the component contract, data flow, navigation, or user consequence.

## Inspect before changing

- Trace the changed route from entry point through layout, components, state, client calls, and styles.
- Inspect nearby product surfaces for established primitives and behavior, not only matching colors or shapes.
- Find the existing source of truth for data, navigation, form state, validation, permissions, and feature flags.
- Check whether the framework already provides loading, error, image, routing, or code-splitting primitives for the problem.
- Identify the states and boundaries affected by the change before extracting components or adding effects.
- Preserve public props, events, URLs, data shapes, focus behavior, and persisted state unless a deliberate contract change is in scope.

## Component structure and reuse

- Give each component one coherent responsibility and a clear public contract.
- Reuse a shared component when its semantics, behavior, states, and styling roles match the new use.
- Prefer composition, slots, children, and small explicit variants over many unrelated boolean props.
- Keep variants finite and meaningful, such as `tone="danger"` or `size="compact"`; do not turn a component into a page-specific configuration language.
- Keep route-specific orchestration near the route and reusable presentation or interaction in the shared layer appropriate to the repository.
- Avoid defining component types inside render paths when that would recreate identity and reset state.
- Keep styling with the repository's established tokens, utilities, modules, or component conventions.
- Add a token or shared primitive only when the role recurs or belongs to the system; keep genuinely local exceptions local and explain them.
- Preserve stable keys and component identity when reordering, filtering, hiding, or revealing content.
- Prefer direct, traceable imports over broad convenience barrels when a barrel would pull unnecessary client code or hide ownership.

## State and data flow

- Represent mutually exclusive UI states with one explicit status or discriminated state rather than combinations of booleans that can disagree.
- Derive display values from current props and state during render when possible; do not mirror derived values through effects.
- Use effects for synchronization with external systems, not as the default mechanism for computing UI state.
- Keep one source of truth for shared server data and one deliberate owner for local interaction state.
- Reuse the existing client, cache, query, mutation, and invalidation patterns instead of adding parallel fetch logic.
- Start independent work together and await it at the latest useful boundary to avoid serial request waterfalls.
- Handle cancellation, stale responses, retries, duplicate submission, optimistic failure, and unmount behavior where they can affect the user.
- Preserve useful previous content during refresh when it supports orientation; mark the changing region as pending.
- Keep meaningful filters, tabs, sorting, pagination, and selected records in the URL when they should be shareable or recoverable.
- Warn before discarding unsaved work. Require confirmation or provide undo for destructive actions according to existing product conventions.

## Loading, errors, and transitions

- Keep the stable route or page shell visible when only a nested region is waiting.
- Place loading, empty, permission, and error boundaries around the region that owns the state.
- Match skeleton dimensions and structure to the expected result so content does not jump when it arrives.
- Reserve space for images, charts, embeds, asynchronous labels, and deferred panels.
- Show pending feedback near the action that caused it while keeping unrelated controls usable.
- Keep input updates urgent and defer expensive results, filtering, or visualization when the framework supports that distinction.
- Preload a heavy interaction after clear intent such as hover, focus, or pointer-down when it materially shortens the next response.
- Prevent the first frame from flashing an incorrect theme, authentication state, locale, or layout.
- Put errors near their cause, preserve correct user input, explain the next action, and move focus to the first actionable error when appropriate.
- Announce meaningful asynchronous success, failure, and progress without stealing focus unnecessarily.

## Semantic interaction and accessibility

- Use buttons for actions, links for navigation, headings for structure, lists for collections, and native form controls when they satisfy the interaction.
- Do not make a generic container clickable without supplying the complete keyboard, focus, name, role, and state behavior of the control it replaces.
- Give every interactive element an accessible name and every visible form control a persistent label.
- Keep icon-only controls named; hide decorative icons and images from assistive technology.
- Preserve logical DOM, reading, tab, and focus order even when the visual layout changes.
- Show a visible `focus-visible` treatment and never remove focus indication without a clear replacement.
- Support keyboard activation, dismissal, navigation, and focus return for menus, dialogs, drawers, popovers, and other composite interactions.
- Use correct disabled and pending semantics; do not expose a control as available while silently ignoring activation.
- Associate help and validation messages with their controls. Do not rely on color alone to communicate status.
- Use live announcements only for meaningful dynamic changes and avoid repetitive or noisy updates.
- Respect reduced-motion, increased text size, zoom, high contrast, and forced-color behavior where supported.

## Forms and direct input

- Use the correct input type, input mode, autocomplete value, name, and spellcheck behavior for the field.
- Allow paste and password-manager behavior. Do not replace standard editing shortcuts with custom restrictions.
- Validate at a time that helps correction without punishing normal entry; retain the user's value after failure.
- Keep field, help, unit, requirement, and error text visually and programmatically connected.
- Prevent duplicate submission while showing a stable pending state that retains the action's meaning.
- Distinguish a temporarily pending action from a permanently unavailable one.
- Use autofocus only when it is expected, does not hide context, and will not unexpectedly move a narrow viewport.
- Make touch targets and the gaps between them sufficient for reliable activation.

## Responsive and content resilience

- Build the intended responsive transformation with grid, flexbox, container rules, intrinsic sizing, and wrapping before measuring layout in JavaScript.
- Keep DOM order compatible with task and reading order when columns collapse or regions move visually.
- Add breakpoints where content relationships fail, while respecting the repository's existing breakpoint system.
- Let flexible children shrink with rules such as `min-width: 0`; wrap or deliberately truncate long values instead of forcing page overflow.
- Fix the element that overflows. Do not hide page-level overflow to conceal a broken layout.
- Test implementation logic against short, typical, long, missing, malformed, and localized content.
- Format dates, times, numbers, plural forms, and currency with locale-aware APIs.
- Keep controls usable with touch, mouse, and keyboard, including safe-area insets and nested scrolling surfaces.
- Prefer native selection and input behavior on mobile unless a custom control provides a necessary, fully implemented benefit.
- Preserve selected, expanded, entered, and scroll state across responsive changes when the user's work should survive them.

## Rendering and user-perceived performance

- Keep the initial client bundle limited to code needed for the first useful interaction.
- Load heavy editors, charts, media, or rarely opened panels only when their cost and usage justify separation.
- Defer non-critical third-party scripts and decorative work that compete with the primary task.
- Give images explicit dimensions or aspect ratios; prioritize critical visible media and defer offscreen media.
- Avoid repeated layout reads during render, scroll, pointer movement, or animation.
- Use passive listeners for observational touch and wheel handlers when they never cancel scrolling.
- Virtualize or progressively render large collections when rendering every item harms startup or interaction; do not virtualize small lists without need.
- Use offscreen rendering containment where it improves long pages without breaking search, focus, measurement, or sticky behavior.
- Memoize or cache only when identity or computation cost is meaningful and the repository's framework conventions support it.
- Keep server-only work out of the client bundle and minimize data serialized across server/client boundaries where that architecture applies.
- Measure the user-visible bottleneck before adding complex performance machinery, then confirm that the chosen change improves it.

## Motion and visual implementation

- Implement the motion intent supplied by the design brief; do not add animation merely because a library makes it easy.
- Prefer transform and opacity for frequent animation and avoid broad `transition: all` rules.
- Keep animations interruptible and responsive to new input.
- Supply a reduced-motion behavior that preserves state and spatial meaning without unnecessary movement.
- Reserve final geometry before animating appearance to avoid layout shifts.
- Animate a wrapper when direct animation of an SVG or complex child is unstable.
- Keep hidden content out of focus and accessibility navigation when it is not meant to be available.
- Preserve component state while hiding content only when the product expects the user's work to remain.

## Implementation anti-patterns

Avoid:

- copying markup and state logic when an established component or hook already owns the contract;
- forcing unrelated behavior into one component through a growing set of boolean props;
- duplicating server data in local state and synchronizing it with effects;
- replacing the whole page with a spinner for a local request;
- allowing impossible combinations such as loading and success, or disabled and actively submitting;
- hiding overflow, errors, or failed requests to make the happy path appear complete;
- using JavaScript viewport measurements for layout CSS can express reliably;
- intercepting native keyboard, paste, scrolling, or form behavior without a necessary user benefit;
- clickable containers, unlabeled icon buttons, invisible focus, inaccessible custom controls, or color-only status;
- changing route, component, API, focus, or persisted-state contracts incidentally during visual work;
- loading every optional dependency in the initial route bundle;
- speculative memoization, virtualization, or abstraction that adds complexity without a visible or measured benefit;
- declaring implementation quality from a single screenshot or declaring visual acceptance from passing code checks.

## Implementation loop

1. Read the design brief, acceptance criteria, contracts, and repository guidance.
2. Trace the existing route, data flow, components, styles, states, and tests.
3. Define component ownership and explicit UI states before editing.
4. Implement the primary path with existing primitives and semantic controls.
5. Complete loading, empty, error, pending, permission, long-content, and responsive behavior that is relevant to the task.
6. Run focused type, lint, unit, component, integration, and build checks in proportion to the change.
7. Render representative states while implementation is still easy to correct, using the rendered result as feedback rather than as the final report.
8. Remove duplicated logic, accidental abstractions, blocked interaction, layout shifts, and accessibility regressions.

## Implementation handoff

When this skill is used by itself, return only:

- components, routes, hooks, services, and contracts changed or reused;
- explicit UI states and interaction behavior implemented;
- accessibility, responsive, data-flow, and performance decisions that materially affect users;
- focused checks run and their results;
- unresolved implementation questions, risks, or verification gaps.

Do not create a screenshot matrix, choose the worst screenshot, score visual quality, write an acceptance report, or declare final acceptance. Hand the rendered surface to the browser/reporting skill when durable visual evidence is required.

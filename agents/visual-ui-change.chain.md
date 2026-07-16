---
name: visual-ui-change
description: Optional AAD workflow for visual/UI/public-page slices that need screenshot-first browser evidence and visual critique without replacing owner accountability.
---

This chain is optional. Use it only for visual/UI/public-page slices such as public page visuals, landing pages, templates, hero sections, marketing blocks, or other product-quality UI surfaces. For backend, config, docs-only, copy-only, or non-visual work, use the normal AAD owner flow instead.

The chain does not replace owner accountability. The `aad-slice-owner` still owns scope, implementation routing, task-package state, integration, and final done-state; browser and critic steps provide evidence only.

## aad-slice-owner

Own this visual/UI/public-page change end-to-end under normal AAD rules. Create or update the task package, record the visual design/composition decision, route any implementation through `aad-implementer`, and define the required viewport set plus visual anti-pattern gates. When implementation is ready for visual evidence, return the task package path, relevant report paths, local/preview URL, viewport set, and any screenshot waiver or constraints.

Task name: {task}
Request: {task}

## chrome-browser-agent

Collect screenshot-first browser evidence for the implemented visual/UI/public-page slice. Capture the required viewport screenshots, identify the worst screenshot with first-glance reasoning, and include objective supporting checks for overflow, clipping, console/network blockers, and DOM intersections. Write evidence into the task package when a path is available.

Owner context:

{previous}

## visual-critic

Review the current screenshots as read-only visual/product-quality evidence. Return `pass`, `needs polish`, or `reject`, identify the worst screenshot, list the top screenshot-visible issues, and recommend one composition fix. Do not implement fixes or decide final acceptance.

Browser evidence:

{previous}

## aad-auditor

Audit the visual/UI/public-page slice using the owner context, browser screenshots, and visual critic verdict as acceptance evidence. Do not implement fixes. Do not accept a visual/UI slice without screenshot evidence or an explicit waiver, worst-screenshot reasoning, and resolved visual-critic concerns.

Critic evidence:

{previous}

## aad-slice-owner

Integrate the browser, visual critic, and acceptance-auditor evidence while preserving AAD owner accountability. If evidence identifies current-goal blockers, route focused fixes through `aad-implementer` and repeat the needed visual evidence. If evidence is sufficient, record the final owner status in the task package. Do not merge unless explicitly asked.

Audit context:

{previous}

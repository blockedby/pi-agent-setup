---
name: visual-composition-quality
description: Select for public or product-quality visual surfaces that need an explicit composition decision, screenshot-first anti-pattern gates, and a separate browser/critic evidence path.
---

# Visual Composition Quality

Use only when first-glance composition and polish affect acceptance. It is not required for invisible, backend, config, or trivial copy-only work.

## Minimal composition decision

Before implementation, record only what the implementer needs:

1. primary user message or task and main CTA;
2. named layout/composition strategy;
3. what should dominate, support, and recede;
4. grouping, alignment, section rhythm, and whitespace intent;
5. mobile/tablet simplification and wide-desktop behavior;
6. brand, typography, contrast, image, and forbidden-motif constraints.

## Hard visual risks

Treat these as blocking unless explicitly waived:

- clipped, overlapping, hidden, or unusable primary content or controls;
- broken responsive layout, horizontal overflow, or pathological wrapping;
- collage/debug composition, disconnected cards, random decoration, or visual noise overpowering content;
- generic low-trust template output, weak hierarchy, typography, spacing, or accidental dead zones;
- unreadable contrast or missing, broken, stretched, pixelated, or placeholder-only assets.

## Evidence path

- implementation remains with the working owner or delegated implementer;
- screenshots come from a separate browser agent using `standard-ui` or `full-visual` coverage;
- visual judgment comes from the separate visual critic;
- final acceptance comes from the independent auditor.

Record the composition decision once in the task record. Reference browser and critic artifacts; do not copy them into another visual report. Objective DOM metrics can explain but never overrule an obvious screenshot failure.

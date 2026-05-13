---
name: aad-design-refinement
description: Use when an AAD owner needs to sharpen requirements or design before planning or implementation without falling into heavyweight brainstorming rituals.
---

# AAD Design Refinement

## Overview

Use this skill when the goal is real but the execution shape is still fuzzy.

The objective is to produce just enough design clarity to move forward safely.

Default to autonomous refinement. Ask the user only when ambiguity blocks safe progress or when a decision changes scope materially.

## Workflow

1. Read the local context that actually matters.
2. Identify what is already settled versus what is still ambiguous.
3. Collapse the work into one recommended approach unless multiple approaches are genuinely live.
4. Ask only the minimum blocking question if a decision cannot be made safely from repo context.
5. Produce a short design note that covers:
   - goal
   - constraints
   - recommended approach
   - main risks
   - verification story

## Output standard

- Keep the design operational, not theatrical.
- Prefer one recommended approach with brief trade-offs.
- Keep the note short enough that an owner can execute or plan from it immediately.

## Common mistakes

- turning refinement into a long gated conversation
- asking non-blocking questions the repo already answers
- exploring multiple approaches when one is already clearly cheaper
- writing a spec-sized document for a small implementation decision

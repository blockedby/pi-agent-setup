---
name: explanatory-html-pages
description: Create self-contained HTML pages that explain technical concepts with plain language, evidence-backed diagrams, responsive editorial layouts, and code-and-logic validation. Use for explanatory or “explanationary” pages, visual guides, architecture explainers, concept maps, system walkthroughs, or printable teaching pages.
---

# Explanatory HTML Pages

Create a page that helps a reader understand a concept. Favor clarity and source accuracy over decoration. Use the user's request and the surrounding project as the main specification; the defaults below are guidance, not a fixed page recipe.

## 1. Start from evidence

Inspect the relevant source, documentation, or user-provided material before drawing the system. Determine:

- what the reader is trying to understand;
- the actors, actions, sequence, and boundaries that matter;
- which claims are supported and which remain uncertain;
- the target file, language level, and existing visual system.

Ask a focused question only when missing information would materially change the explanation. Otherwise proceed and label uncertainty honestly.

## 2. Choose the teaching structure

Use only the sections that help this topic. Useful patterns include:

- a direct definition for an unfamiliar term;
- a graph for relationships between actors;
- a before/after or filter view for a transformation;
- numbered steps for a process;
- an aligned table for capability differences;
- a short rationale for why the design works this way;
- source links for deeper reading.

Order the page around the reader's next question. Do not add empty sections or force unrelated topics into the same structure.

## 3. Build the page

Follow an existing product design system when one is present. For a standalone page with no brand rules:

- prefer one self-contained HTML file with semantic markup and inline CSS;
- use a strong black-and-white editorial system as the starting direction;
- keep diagrams as readable HTML/CSS when practical;
- add JavaScript or external assets only when they materially improve the explanation;
- include print treatment when the page is intended to be saved or shared as a document.

For a from-scratch page, `assets/explanatory-page-template.html` is an optional high-fidelity code reference. Load it only when useful. Adapt its visual language and remove irrelevant sections; it is not a required page schema, and no placeholders may remain in the final file.

When the user requests B2 English, use common words, define necessary technical terms, keep one main idea per paragraph, and explain cause and effect directly without reducing technical accuracy.

## 4. Make relationships unambiguous

- Give diagram nodes concrete names and short role labels.
- Make arrow meaning clear through nearby text or an accessible label.
- Keep meaningful diagram text in the document rather than flattening it into an image.
- Do not rely on color alone to distinguish roles or states.
- Make diagrams, tables, and prose describe the same system.
- On narrow screens, recompose horizontal relationships vertically instead of hiding overflow.
- Preserve logical reading order when columns stack.

## 5. Check code and explanation logic

Before handoff:

- parse the HTML without errors;
- confirm one `h1`, ordered headings, and unique IDs;
- remove unresolved placeholders and broken references;
- verify links and local paths;
- confirm scripts and external assets are intentional;
- check that actors, actions, arrows, and steps match the source evidence;
- confirm diagrams, tables, and written explanations agree;
- mark uncertain claims clearly and remove unsupported statements.

## 6. Handoff

Report the created file path, the teaching structure, the language level, and any intentional dependencies or unresolved factual gaps. Keep the response short; the page should carry the explanation.

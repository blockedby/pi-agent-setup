---
name: explanatory-html-pages
description: Create polished, self-contained HTML explanation pages that teach technical concepts with plain-language definitions, architecture graphs, process diagrams, comparisons, responsive editorial layouts, print styles, and code-and-logic validation. Use when the user asks for an explanatory or “explanationary” HTML page, visual guide, concept map, architecture explainer, system walkthrough, or printable technical teaching page.
---

# Explanatory HTML Pages

Create an HTML page that helps a reader understand a concept, not merely admire a layout. Turn source evidence into a clear teaching sequence, then render and refine the actual page.

Use `assets/explanatory-page-template.html` as a structural reference or starting point. Resolve this path relative to this skill directory. Adapt it to the subject; do not ship its placeholders or force every topic into the same layout.

## Default outcome

Unless the project or user asks for something else, produce:

- one self-contained `.html` file;
- semantic HTML with inline CSS;
- no build step, external font, remote image, tracking, or JavaScript;
- a strong black-and-white editorial visual system;
- plain language at approximately CEFR B2 level;
- diagrams made from accessible HTML and CSS rather than flattened images;
- responsive desktop and mobile compositions;
- useful print styling;
- source links or local source references for factual claims.

An existing product design system or an explicit user style request takes priority over the black-and-white default.

## 1. Establish the teaching brief

Write the smallest useful brief before creating the page:

```md
Audience and reading situation:
Concept the reader must understand:
Reader's likely question or confusion:
Required facts and source evidence:
Requested language level and locale:
Required diagrams, comparisons, or examples:
Target file and existing visual system:
Supported viewport range and print need:
```

If the user requests B2 English:

- use common words before specialist words;
- define necessary technical terms at first use;
- keep most sentences between roughly 10 and 22 words;
- use active voice and concrete subjects;
- keep one main idea per paragraph;
- explain cause and effect directly;
- use examples or analogies after the exact definition, not instead of it.

Do not reduce technical accuracy to make the writing simpler.

## 2. Verify the concept before drawing it

Inspect the relevant source, documentation, or user-provided evidence. Identify:

- actors or components;
- allowed and blocked actions;
- direction of data, tasks, or control;
- sequence and concurrency;
- limits, permissions, and failure boundaries;
- facts that are certain versus assumptions.

Do not invent architecture from names alone. If evidence is incomplete, label the uncertainty or ask a focused question.

## 3. Build a teaching sequence

Prefer this progression when it fits the topic:

1. **Orientation** — state what the reader will understand.
2. **Direct definition** — answer the main vocabulary question in one bold sentence.
3. **System graph** — show who or what connects to whom.
4. **Transformation or filter** — show what changes between input and output.
5. **Step-by-step flow** — show the normal sequence.
6. **Capability comparison** — align what each actor can and cannot do.
7. **Reasoning** — explain why the design works this way.
8. **Sources** — provide evidence and paths for deeper reading.

Change the sequence when the information relationship requires it. Do not add empty sections only to match this list.

## 4. Draw diagrams that teach

A useful diagram must remain understandable without color.

- Give every node a short role label and a concrete name.
- Label arrows by meaning: task, result, data, control, or response.
- Keep the main reading direction consistent.
- Distinguish coordinator, worker, input, output, and blocked action with border, fill, pattern, shape, or text—not color alone.
- Place a one-sentence caption below each figure.
- Keep meaningful diagram text in the DOM.
- Use lists or tables as a text equivalent when a graph carries important facts.
- On narrow screens, recompose horizontal graphs into vertical flows. Do not rely on hidden overflow.
- Use SVG only when HTML/CSS cannot express the relationship clearly; include an accessible name and text alternative.

For excluded or unavailable capabilities, show the difference clearly:

```text
AVAILABLE TO PARENT     FILTER       AVAILABLE TO CHILD
read                             →    read
write                            →    write
spawn another worker   removed  ✕    —
```

Explain that “removed” can mean “not present in this actor's tool list”; it does not automatically mean a file was deleted.

## 5. Use an editorial visual system

When there is no existing visual system, start with:

- white paper and near-black ink;
- one sans-serif family plus monospace labels;
- strong rules, borders, and numbered sections;
- one large opening headline;
- a readable body measure;
- large spacing between concepts and tighter spacing within a concept;
- flat surfaces with at most one deliberate hard-edged shadow;
- patterns, line styles, and typography for state differences.

Every large visual element must orient the reader or clarify meaning. Avoid gradients, glow, decorative dashboards, generic card grids, ornamental icons, and motion that does not teach.

## 6. Implement resilient HTML

Use semantic elements:

- one `h1` and ordered heading levels;
- `header`, `main`, `section`, and `footer` for page structure;
- `figure` and `figcaption` for diagrams;
- `ol` for sequences and `ul` for sets;
- real `table` markup for aligned comparisons;
- links for navigation and buttons only for actions.

Also include:

- `lang`, UTF-8 charset, viewport metadata, title, and description;
- visible `:focus-visible` styles;
- readable contrast without relying on color;
- wrapping for long URLs, code, and labels;
- `min-width: 0` for flexible children where needed;
- a reduced-motion rule if any motion exists;
- print rules that remove decorative shadows and expose useful link targets;
- no final placeholder text, fake metrics, or broken links.

Prefer CSS Grid and Flexbox. Avoid JavaScript layout measurement and page-level `overflow-x: hidden`.

## 7. Recompose for mobile

Do not shrink the desktop page unchanged.

- Stack definition layouts.
- Turn left-to-right graphs into top-to-bottom graphs.
- Turn multi-column steps into a vertical sequence.
- Convert wide comparison tables into labeled row blocks, or use a deliberate scroll region when alignment is essential.
- Preserve the same reading and task order in the DOM.
- Keep the full page at the viewport width with no unintended horizontal overflow.

A useful baseline is desktop around `1440 × 900` and mobile around `390 × 844`, adjusted to the project's supported range.

## 8. Check code and explanation logic

Before handoff:

- parse the HTML without errors;
- confirm one `h1`, ordered headings, and unique IDs;
- remove unresolved placeholders and broken references;
- verify links and local paths;
- confirm scripts and external assets are intentional;
- check that actors, actions, arrows, and steps match the source evidence;
- confirm diagrams, tables, and written explanations agree;
- mark uncertain claims clearly and remove unsupported statements.

## 9. Handoff

Report:

- the created file path;
- the main teaching structure;
- the language level used;
- desktop and mobile verification performed;
- any intentional external dependencies or unresolved factual gaps.

Keep the response short. The page itself should carry the explanation.

## Anti-patterns

Do not:

- create a decorative landing page instead of an explanation;
- use jargon without a direct definition;
- show a graph whose arrows have no meaning;
- use an analogy as the only explanation;
- claim “removed” means “deleted” without source evidence;
- flatten essential text into a screenshot;
- make every section an equal card;
- use tiny desktop diagrams on mobile;
- hide overflow instead of fixing the element;
- introduce JavaScript for a static teaching page;
- skip code and explanation-logic checks before handoff.

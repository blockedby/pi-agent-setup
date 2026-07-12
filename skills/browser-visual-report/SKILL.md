---
name: browser-visual-report
description: Use when the separate browser agent must collect persisted functional or screenshot-first evidence under .pi/aad with a coverage mode, artifact manifest, worst-screenshot reasoning, and compact report.
---

# Browser and Visual Evidence

Browser automation always runs in a separate `chrome-browser-agent` context.

## Paths

```text
.pi/aad/<task-id>/browser.md
.pi/aad/<task-id>/artifacts/screenshots/<scope>/<run-id>/
.pi/aad/<task-id>/artifacts/logs/
```

## Coverage modes

### `functional`

Use for behavior such as route loading, form submission, auth flow, console/network checks, or one bounded browser reproduction.

Default:

- target viewport;
- add one contrasting viewport only when responsive risk is relevant.

### `standard-ui`

Use for normal application UI review:

```text
390x844
768x1024
1440x900
```

### `full-visual`

Use for public landing pages, hero sections, marketing surfaces, polished templates, and other high-visibility visual acceptance:

```text
320x800
390x844
768x1024
1280x800
1440x900
1680x945
1920x1080
```

Inspect more than the first fold when the page is scrollable. Prefer semantic sections; otherwise use representative positions.

## Browser mode

Use disposable headless Chrome for anonymous/public/local/simple/parallel work. Use headed persistent Chrome only when explicitly authorized saved authentication, profile, extension, or session state is required.

Never persist or report cookies, tokens, local storage, passwords, profile data, or private session contents.

## Screenshot review

For each screenshot:

1. first-glance purpose and CTA;
2. clipping, overlap, overflow, missing assets;
3. text readability and wrapping;
4. grouping, hierarchy, balance, whitespace;
5. responsive comparison.

Hard failures include unusable controls, clipped primary content, broken responsive layout, unreadable contrast, accidental dead zones, collage/debug composition, generic low-trust templates, or missing/broken assets.

## Worst screenshot

Any hard failure outranks soft risk. Otherwise score:

```text
composition: 0-3
readability: 0-3
spacing/alignment: 0-3
responsive behavior: 0-3
product-quality risk: 0-3
```

On ties prefer mobile, above-the-fold, and task-critical surfaces.

## Compact report

```md
## Browser evidence
- Mode:
- Route / URL:
- Run ID:
- Screenshots:
- Worst screenshot:
- First-glance verdict: pass / needs polish / reject
- Console/network:
- Functional result:
- Coverage gaps / waivers:
- Recommended owner action:
```

For `full-visual`, add a compact screenshot matrix. Do not write a narrative per viewport.

Browser evidence is not final acceptance. The independent auditor reads this report.

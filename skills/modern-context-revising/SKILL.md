---
name: modern-context-revising
description: Review and rightsize agent context for capable modern models. Use when simplifying or modernizing SKILL.md, AGENTS.md, CLAUDE.md, system prompts, tool instructions, memory guidance, or agent runbooks by removing conflicts, repetition, obsolete constraints, and eager context while preserving safety, project-specific gotchas, and verifiable behavior.
---

# Modern Context Revising

Revise agent context so the model receives less noise and more useful signal. Prefer a small, clear entrypoint, expressive interfaces, and details loaded only when needed. Do not pursue shorter files as an end in itself.

## 1. Establish scope

Identify the context surfaces that can affect the target behavior, including prompt files, skills, tool descriptions, referenced documents, memory, and user or project overrides.

Before editing, determine:

- the intended model and harness;
- instruction precedence and ownership;
- the behavior or failure that motivated the revision;
- safety, permission, compliance, and irreversible-action boundaries;
- project-specific rules that the model cannot infer from the codebase.

Use transcripts, failures, or evaluation evidence when available. Do not invent a problem only because a file is long.

## 2. Classify the current context

Treat each instruction as one of these:

- **essential boundary** — safety, authorization, data loss, cost, compliance, or irreversible action;
- **local gotcha** — surprising project behavior that is not obvious from code or structure;
- **interface contract** — parameters, schemas, states, or output requirements;
- **reference knowledge** — detailed material needed only for some tasks;
- **duplicate or conflict** — overlapping guidance with unclear precedence;
- **obsolete scaffolding** — repetition, generic advice, or constraints retained for weaker models.

This classification decides what to keep, move, combine, or remove.

## 3. Revise the context

- Keep the always-loaded entrypoint lightweight and specific to its scope.
- Remove obvious guidance the model can derive from the repository, tools, or user request.
- Resolve conflicts instead of adding another exception.
- Put tool-specific behavior in the tool description or interface rather than repeating it globally.
- Prefer expressive schemas, enums, parameters, and file structure over long prose examples.
- Remove illustrative examples when they unnecessarily narrow valid solutions; retain examples that define a real compatibility contract.
- Move conditional detail into focused skills, references, scripts, or assets that can be loaded when needed.
- Prefer code, specs, and working artifacts over prose descriptions when they communicate the requirement more precisely.
- Let the model use judgment for reversible implementation choices unless the project has a concrete reason to constrain them.

Preserve explicit user intent and higher-priority instructions. Never weaken a critical boundary merely to reduce context size.

## 4. Check the revision

Before handoff:

- validate frontmatter, configuration, schemas, and referenced paths;
- confirm no required instruction became unreachable after content was moved;
- search the remaining context for conflicting or repeated rules;
- compare preserved obligations before and after the revision;
- run the repository's focused tests and context-loading checks;
- report size reduction as information, not as a quality score;
- state any uncertain deletion or behavior that still needs evaluation.

When a live model evaluation would cost money, use credentials, or change external state, ask before running it.

## 5. Handoff

Report:

- files revised;
- important guidance kept, moved, combined, or removed;
- before-and-after size;
- validation performed;
- residual risks or evaluation gaps.

Keep the report concise and make the diff easy to review.

## Source perspective

This workflow is informed by Anthropic's article, [“The new rules of context engineering for Claude 5 generation models”](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models). Apply its principles with current project evidence and platform documentation rather than treating any fixed reduction target as a requirement.

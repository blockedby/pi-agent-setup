---
name: aad-workflow-feedback
description: Use when an agent has concrete, reusable feedback about agent-pipeline friction after completing a task and needs to leave a concise, non-blocking note for setup/prompt/skill/tool improvement.
---

# Agent Pipeline Feedback

Use this skill opportunistically after a task when you observed concrete friction in the agent pipeline that is likely reusable beyond the current task.

Do not use this as a mandatory done-state step. Do not invent feedback. Do not delay, block, or expand the user's task just to write feedback.

## When to write feedback

Write a note only when all are true:

- You observed specific pipeline friction while doing the task.
- The friction is reusable: it could inform a setup, prompt, skill, tool, routing, or workflow improvement.
- You can describe it without secrets, credentials, private user data, sensitive repo content, or unnecessary transcript detail.
- It is not already clearly covered by an existing recent feedback note.

Do not write a note for one-off confusion, ordinary task complexity, speculative improvements, or feedback that would duplicate an existing note.

## Where to write it

Use the feedback directory supplied by the caller or repository guidance. For this setup repository, resolve it relative to the active checkout:

```text
<repo>/feedback/
```

Use a short, descriptive filename such as:

```text
YYYY-MM-DD-short-topic.md
```

If no feedback directory is supplied or the resolved directory is unavailable, skip the note or mention the feedback briefly in your normal report; do not block the task.

## Compact template

```md
# <short feedback title>

- Date: <YYYY-MM-DD>
- Agent/task context: <agent role and brief task type>
- Observed friction: <what happened, concretely>
- Why it mattered: <cost, risk, confusion, repeated manual work, or quality impact>
- Suggested setup/prompt/skill/tool change: <specific improvement idea>
- Evidence: <minimal command/file/behavior reference; no secrets or sensitive details, session ids>
- Risk/guardrails: <how to avoid overfitting, extra burden, privacy leakage, or false positives>
```

## Dedupe and privacy rules

- Keep notes concise and actionable; avoid diary-style logs.
- Redact paths, branch names, or snippets when they would reveal sensitive information and are not needed for the improvement.
- Feedback is advisory only; it must not redefine task acceptance or claim the user task is incomplete.

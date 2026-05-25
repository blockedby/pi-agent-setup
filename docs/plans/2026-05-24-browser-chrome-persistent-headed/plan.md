# Browser Chrome persistent headed protocol plan

## Problem

Agents can confuse any headed/CDP-reachable Chrome with the user's persistent logged-in Chrome profile. This breaks tasks that need saved auth/session/profile state.

## Key rule

```text
headed persistent profile != disposable headed/debug browser
```

For auth/session/profile tasks, use the configured persistent headed browser through Pi's MCP/scripts. Do not use disposable headless or disposable headed helper profiles.

## Evidence

See [`reports/hermes-vs-pi-browser-chrome.md`](reports/hermes-vs-pi-browser-chrome.md).

## Candidate tasks

1. Finalize browser-chrome skill wording around persistent headed contract.
2. Decide whether to enforce headed port `9200-9300` in scripts.
3. Keep usage MCP/script-first and avoid hardcoded Hermes-specific commands/paths.
4. Add troubleshooting note for "opened fresh profile instead of my logged-in Chrome".

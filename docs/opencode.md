# OpenCode compatibility

The repository remains Pi-first. Its checked-in AAD agents and composed general and AAD skill sets can also be loaded by OpenCode through the included compatibility plugin.

The adapter follows the same general pattern as `obra/superpowers`: keep one source of workflow instructions, then translate runtime-specific discovery, permissions, and tool names at the integration boundary.

## Install

The adapter targets OpenCode 1.18.2 or newer because the nested AAD hierarchy relies on configurable `subagent_depth`.

Add the git-backed package to a global or project-level `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "pi-agent-setup@git+https://github.com/blockedby/pi-agent-setup.git"
  ],
  "subagent_depth": 4
}
```

Restart OpenCode after changing the config. Pin a branch, tag, or commit by adding a fragment to the git URL when reproducibility matters.

The plugin sets `subagent_depth` to `4` only when the merged OpenCode config does not already define it. Keeping the value explicit in `opencode.json` is recommended because the AAD hierarchy may use primary → root owner → slice owner → implementer, with an additional level for a child slice.

## What the plugin does

At startup, `.opencode/plugins/pi-agent-setup.js`:

1. reads the existing Markdown definitions from `agents/`;
2. strips Pi frontmatter and registers equivalent OpenCode subagents through the `config` hook;
3. translates Pi tool declarations into deny-by-default OpenCode permissions without weakening stricter global or built-in rules;
4. applies role-specific OpenCode permissions to delegation and read-only agents;
5. discovers both `skills/general/` and `skills/aad/` and creates one flat normalized skill view in the OpenCode cache, using each skill's frontmatter `name` as its directory name;
6. registers that normalized directory through `config.skills.paths`;
7. injects a small routing and tool-mapping bootstrap into the conversation.

The normalized cache is content-addressed and stored below:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/opencode/pi-agent-setup/skills/
```

It is derived data and does not modify the checkout.

## Agent mapping

| Shared agent source | OpenCode mode | Delegation policy |
| --- | --- | --- |
| `aad-root-owner` | `subagent` | May call slice owners, explorers, auditors, and the browser agent. |
| `aad-slice-owner` | `subagent` | May call implementers, child slice owners, explorers, auditors, and the browser agent. |
| `aad-implementer` | `subagent` | Cannot create child agents. |
| `aad-explorer` | `subagent` | File edits and child agents are denied; shell commands require approval. |
| `aad-auditor` | `subagent` | File edits and child agents are denied; shell and browser MCP use require approval. |
| `chrome-browser-agent` | `subagent` | Registered only when `skills/general/browser-chrome/SKILL.md` is present. |

The adapter intentionally does not copy Pi model IDs into OpenCode. OpenCode subagents inherit the invoking primary agent's model unless the user supplies an override. This keeps the package provider-neutral and avoids failing on a Pi-specific model alias.

Example override:

```json
{
  "agent": {
    "aad-implementer": {
      "model": "<provider>/<model>",
      "permission": {
        "bash": "ask"
      }
    }
  }
}
```

User-defined OpenCode agent settings may tighten generated defaults. The adapter compiles global and per-agent permission restrictions together, retains protected `.env` reads, and keeps the generated wildcard deny. An `allow` override cannot grant a capability that the shared agent did not declare or that a stricter inherited rule denies.

## Runtime tool mapping

The shared prompts still describe the Pi execution protocol. The OpenCode adapter prepends runtime rules and rewrites executable-looking Pi-only call syntax in generated prompts; the checked-in Pi prompts stay unchanged.

| Shared/Pi wording | OpenCode behavior |
| --- | --- |
| named `subagent` call | `task` with the matching `subagent_type` |
| `tasks` / `concurrency` | separate independent `task` calls, parallel only when the live runtime supports it safely |
| `reads` | put requirements in repository files and tell the child agent to read them |
| `progress` | update the task package or progress file |
| `async` | no direct field mapping; use OpenCode child sessions and continue only when the parent can do useful independent work |
| skill invocation | native `skill` tool |
| `web_search_codex` / `web_fetch_codex` | `websearch` / `webfetch` |
| `apply_patch_codex`, `write`, `edit` | OpenCode file-editing tools governed by `permission.edit` |
| `find`, `ls` | `glob` |

`PI_RESULT` remains a text protocol in reports. It is not treated as a runtime-specific tool call.

## General skills without the AAD plugin

The plugin is intentionally the composed AAD profile: besides skills, it registers AAD agents, permission boundaries, subagent depth, and the AAD routing bootstrap. A general-only OpenCode setup should not load it.

When this repository is available locally, add only the general root to OpenCode's native skill paths:

```json
{
  "skills": {
    "paths": ["<repo>/skills/general"]
  }
}
```

This loads the reusable capabilities, including `git-branching`, without AAD agents or routing. The category directory is not part of any runtime skill name.

## Browser boundary

The plugin does not install or configure Chrome, browser profiles, or MCP servers. The browser agent is exposed only when the Browser Chrome skill submodule is present at `skills/general/browser-chrome`. Its MCP tools must still be configured separately in OpenCode.

Do not assume that Bun or another git-package installer initialized repository submodules. For a browser-enabled local package, clone this repository with submodules and point OpenCode at that local package path.

## Verification

Run the repository checks:

```bash
npm test
npm run secrets:check
git diff --check
```

The OpenCode adapter test verifies:

- Pi frontmatter parsing;
- effective deny-by-default permissions, inherited restrictions, protected reads, and delegation boundaries;
- deep handling of partial task overrides;
- default versus explicit `subagent_depth`;
- idempotent bootstrap injection;
- nested general/AAD discovery, cross-set collision handling, and flat normalized skill directories, including a folder/frontmatter-name mismatch;
- set/source-sensitive fingerprints, concurrent cache publication, and mode-sensitive fingerprints;
- preservation of skill support files.

## Limitations

This is a compatibility adapter for a personal workflow, not a promise that every Pi extension has an OpenCode equivalent. In particular:

- Pi notifications remain Pi-only;
- `pi-subagents` scheduling, background events, and control channels do not map one-to-one;
- browser MCP configuration is external to this plugin;
- prompt text may still use Pi terminology, with the adapter's runtime mapping taking precedence for tool calls.

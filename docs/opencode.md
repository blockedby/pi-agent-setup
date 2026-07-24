# OpenCode compatibility

The repository remains Pi-first, but its checked-in AAD agent prompts and skills can also be loaded by OpenCode through the included compatibility plugin.

The adapter follows the same general pattern as `obra/superpowers`: keep one source of workflow instructions, then translate runtime-specific discovery, permissions, and tool names at the integration boundary.

## Install

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
3. translates Pi tool declarations to OpenCode permissions;
4. applies stricter OpenCode permissions to read-only agents;
5. creates a normalized skill view in the OpenCode cache, using each skill's frontmatter `name` as its directory name;
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
| `chrome-browser-agent` | `subagent` | Registered only when `skills/browser-chrome/SKILL.md` is present. |

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

User-defined OpenCode agent settings win over generated defaults. Permission objects are merged so a user can tighten an individual permission without replacing the whole generated agent.

## Runtime tool mapping

The shared prompts still describe parts of the Pi execution protocol. The OpenCode adapter prepends these rules to each generated agent:

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
| `find`, `ls` | `glob`, `list` |

`PI_RESULT` remains a text protocol in reports. It is not treated as a runtime-specific tool call.

## Browser boundary

The plugin does not install or configure Chrome, browser profiles, or MCP servers. The browser agent is exposed only when the Browser Chrome skill submodule is present in the installed package. Its MCP tools must still be configured separately in OpenCode.

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
- agent permission translation and delegation boundaries;
- user override precedence;
- default versus explicit `subagent_depth`;
- idempotent bootstrap injection;
- normalized skill directories, including a folder/frontmatter-name mismatch;
- preservation of skill support files.

## Limitations

This is a compatibility adapter for a personal workflow, not a promise that every Pi extension has an OpenCode equivalent. In particular:

- Pi notifications remain Pi-only;
- `pi-subagents` scheduling, background events, and control channels do not map one-to-one;
- browser MCP configuration is external to this plugin;
- prompt text may still use Pi terminology, with the adapter's runtime mapping taking precedence for tool calls.

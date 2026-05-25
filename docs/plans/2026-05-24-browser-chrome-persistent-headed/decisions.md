# Browser Chrome managed/control MCP decisions

## User decisions captured before implementation

1. **Naming**
   - MCP server names should remain under the `browser-chrome-*` family.
   - Policy tool names should be prefixed `browser_chrome_*` to avoid collisions and keep agent UX obvious.

2. **Phasing**
   - Start with the safer staged implementation recommended by oracle: a control/session MCP first, preserving existing Chrome DevTools MCP tools for actual browser actions.
   - Do not force agents to memorize raw Chrome launch commands.
   - The control MCP should make the first step obvious: acquire/assert the intended session, then use returned MCP guidance.

3. **Persistent headed vs disposable**
   - Explicitly model the three browser forms:
     - `headless-disposable`
     - `headed-disposable`
     - `headed-persistent`
   - Only `headed-persistent` is valid for saved auth/session/profile state.

4. **Locking**
   - Cross-process advisory locking for headed persistent session acquisition is required, not optional.
   - The lock should prevent two agents/processes from racing to start/use the same headed persistent profile.

5. **Proxy scope question**
   - MCP can expose tools, resources, and prompts.
   - Chrome DevTools MCP currently matters to us primarily for tools (navigate, screenshot, evaluate, list pages, etc.).
   - For the Phase 1 control MCP, proxying upstream tools/resources/prompts is out of scope.
   - If/when a full managed proxy is built, start by proxying tools; resources/prompts can be added only if Chrome DevTools MCP exposes useful non-tool capabilities and agents need them.

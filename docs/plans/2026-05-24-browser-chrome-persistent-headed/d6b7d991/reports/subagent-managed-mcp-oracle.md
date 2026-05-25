Inherited decisions:
- Keep `browser-chrome` portable: no Hermes/private hardcoded paths or topology.
- Preserve script-first lifecycle. `open-headed.sh`, `open-headless.sh`, and `close-headless.sh` remain the lifecycle source of truth.
- Headed means persistent profile/auth state; headless means disposable isolated state.
- Headed DevTools ports are constrained to `9200-9300`; current code already enforces this.
- Existing `browser-chrome-headed` / `browser-chrome-headless` MCP entries must remain compatible.
- Do not close the whole headed browser except by explicit user request.
- The real problem is agent policy/UX clarity: agents confuse “any headed CDP Chrome” with “the persistent logged-in headed profile.”

Diagnosis:
- The proposed full managed proxy is feasible, but it is the highest-risk part of the plan.
- The current root need can be satisfied earlier with a smaller control MCP that exposes session-policy tools and delegates actual DevTools work to the existing MCP servers.
- Full proxying requires the managed server to be both an MCP server and MCP client. That introduces protocol, lifecycle, and UX risks that are not necessary for the first validation pass.

Drift / contradiction check:
- Task 3 says `tools/list` should merge upstream tools. To know upstream tools, the proxy likely has to acquire a browser and start upstream MCP during tool listing. That means mere MCP connection/listing may open headed Chrome or spawn disposable headless Chrome. This is a hidden lifecycle side effect.
- A control-only MCP for headless is less useful unless it can pass the acquired URL to the actual DevTools MCP. Existing `browser-chrome-headless` creates its own instance, so a separate control `acquire_session` for headless could create an uncontrollable orphan unless carefully scoped.
- Unprefixed policy names are acceptable only if collision handling is explicit. For a proxy, prefer fail-fast or use prefixed names.
- “Dependency-free hand-rolled MCP proxy” conflicts with the plan’s need for robust protocol compatibility unless real upstream tests are mandatory.

Recommendation:
- Stage via a control MCP first, focused primarily on headed persistent validation.
- Phase 1 should add a small `browser-chrome-control` or `browser-chrome-session-headed` MCP exposing:
  - `status`
  - `acquire_session`
  - `assert_persistent`
  - optionally `release`, with headed release meaning “release control lease only; do not close Chrome”
- Keep actual browser automation on existing `browser-chrome-headed` / `browser-chrome-headless`.
- Do not build the full upstream proxy until the control workflow proves useful and the UX cost of two MCP servers is clearly unacceptable.

Changes the owner should make to the plan:
1. Split implementation into phases:
   - Phase 1: control MCP only, no upstream proxy.
   - Phase 2: optional full managed proxy after real MCP compatibility testing.
2. Scope Phase 1 to headed persistent session assurance. Avoid headless `acquire_session` unless it is part of a single server that also owns DevTools proxying.
3. If full proxy proceeds later, require tests against real `chrome-devtools-mcp`, not only fixtures.
4. Decide policy tool names now. Prefer prefixed names like `browser_chrome_status`, `browser_chrome_acquire_session`, etc., if proxying upstream tools.
5. Add an explicit rule: `tools/list` must not unexpectedly launch headed/headless Chrome unless that side effect is documented and accepted.

Risks:
- Full proxy may mishandle MCP initialize/version negotiation, pagination, cancellations, notifications, stderr/stdout framing, or upstream errors.
- Tool listing may accidentally become a browser-launch operation.
- Headless control-only lifecycle is awkward without proxying because dynamic URLs cannot be handed cleanly to the existing static MCP entry.
- Persistent-profile validation can prove endpoint/port/profile config, but not always prove a remote custom start command actually used the intended profile.

Need from main agent:
- Decide whether Phase 1 should be headed-only control MCP or include limited headless status documentation.
- Decide whether policy tools should be prefixed before implementation.

Suggested execution prompt:
- No executor handoff warranted for full proxy now. If executing next, ask for a staged control-MCP implementation plan, not the full proxy.
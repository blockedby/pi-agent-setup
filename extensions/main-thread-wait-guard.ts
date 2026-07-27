import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const BLOCK_REASON =
  "subagent_wait is forbidden in the user-facing main session. Return control and wait for completion events.";

export default function mainThreadWaitGuardExtension(pi: ExtensionAPI) {
  pi.on("tool_call", (event, ctx) => {
    if (event.toolName !== "subagent_wait" || !ctx.hasUI) return;
    return { block: true, reason: BLOCK_REASON };
  });
}

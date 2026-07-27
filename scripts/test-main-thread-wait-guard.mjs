#!/usr/bin/env node

import assert from "node:assert/strict";
import mainThreadWaitGuardExtension from "../extensions/main-thread-wait-guard.ts";

let toolCallHandler;
mainThreadWaitGuardExtension({
  on(eventName, handler) {
    if (eventName === "tool_call") toolCallHandler = handler;
  },
});

assert.equal(typeof toolCallHandler, "function");
assert.deepEqual(toolCallHandler({ toolName: "subagent_wait" }, { hasUI: true }), {
  block: true,
  reason:
    "subagent_wait is forbidden in the user-facing main session. Return control and wait for completion events.",
});
assert.equal(toolCallHandler({ toolName: "subagent_wait" }, { hasUI: false }), undefined);
assert.equal(toolCallHandler({ toolName: "subagent" }, { hasUI: true }), undefined);

console.log("main-thread wait guard tests passed");

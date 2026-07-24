#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  DEFAULT_OPENCODE_SUBAGENT_DEPTH,
  OPENCODE_AGENT_NAMES,
  OPENCODE_BOOTSTRAP_MARKER,
  createPiAgentSetupPlugin,
  extractAndStripFrontmatter,
  loadOpenCodeAgentDefinitions,
  materializeOpenCodeSkillView,
} from "../.opencode/lib/pi-agent-setup-core.js";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const pluginEntrypoint = await import("../.opencode/plugins/pi-agent-setup.js");
assert.deepEqual(Object.keys(pluginEntrypoint), ["PiAgentSetupPlugin"]);
assert.equal(typeof pluginEntrypoint.PiAgentSetupPlugin, "function");

function write(pathname, content) {
  fs.mkdirSync(path.dirname(pathname), { recursive: true });
  fs.writeFileSync(pathname, content);
}

function agentSource(name, tools, extra = "") {
  return `---\nname: ${name}\ndescription: Test ${name}\ntools: ${tools}\ninheritSkills: true\n${extra}---\n\nYou are ${name}. Ask aad-acceptance-auditor for acceptance.\n`;
}

function makeFixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pi-agent-setup-opencode-"));
  write(
    path.join(root, "agents/aad-root-owner.md"),
    agentSource("aad-root-owner", "read, write, bash, subagent, web_search_codex"),
  );
  write(
    path.join(root, "agents/aad-slice-owner.md"),
    agentSource("aad-slice-owner", "read, edit, bash, subagent"),
  );
  write(
    path.join(root, "agents/aad-implementer.md"),
    agentSource("aad-implementer", "read, write, bash, apply_patch_codex"),
  );
  write(
    path.join(root, "agents/aad-explorer.md"),
    agentSource("aad-explorer", "read, write, edit, bash, ls, web_fetch_codex"),
  );
  write(
    path.join(root, "agents/aad-auditor.md"),
    agentSource("aad-auditor", "read, write, edit, bash, mcp"),
  );
  write(
    path.join(root, "agents/chrome-browser-agent.md"),
    agentSource(
      "chrome-browser-agent",
      "read, write, bash, mcp",
      "skills: browser-chrome,aad-task-package\ninheritSkills: false\n",
    ),
  );

  write(
    path.join(root, "skills/aad-delegation/SKILL.md"),
    "---\nname: aad-slicing-and-delegation\ndescription: Delegation\n---\n\n# Delegation\n",
  );
  write(
    path.join(root, "skills/aad-delegation/scripts/helper.sh"),
    "#!/usr/bin/env bash\necho helper\n",
  );
  write(
    path.join(root, "skills/browser-chrome/SKILL.md"),
    "---\nname: browser-chrome\ndescription: Browser\n---\n\n# Browser\n",
  );

  return root;
}

{
  const parsed = extractAndStripFrontmatter(
    "---\r\nname: test-agent\r\ndescription: quoted: value\r\nenabled: true\r\n---\r\nBody\r\n",
  );
  assert.equal(parsed.frontmatter.name, "test-agent");
  assert.equal(parsed.frontmatter.description, "quoted: value");
  assert.equal(parsed.frontmatter.enabled, true);
  assert.equal(parsed.content, "Body\n");
}

const fixture = makeFixture();
const cacheBase = fs.mkdtempSync(path.join(os.tmpdir(), "pi-agent-setup-cache-"));

try {
  const definitions = loadOpenCodeAgentDefinitions(fixture);
  assert.deepEqual(Object.keys(definitions), OPENCODE_AGENT_NAMES);
  assert.equal(definitions["aad-root-owner"].mode, "subagent");
  assert.equal(definitions["aad-root-owner"].permission.task["*"], "deny");
  assert.equal(definitions["aad-root-owner"].permission.task["aad-slice-owner"], "allow");
  assert.equal(definitions["aad-slice-owner"].permission.task["aad-implementer"], "allow");
  assert.equal(definitions["aad-implementer"].permission.task, "deny");
  assert.equal(definitions["aad-explorer"].permission.edit, "deny");
  assert.equal(definitions["aad-explorer"].permission.bash, "ask");
  assert.equal(definitions["aad-explorer"].permission.glob, "allow");
  assert.equal(definitions["aad-auditor"].permission.edit, "deny");
  assert.equal(definitions["chrome-browser-agent"].permission["browser-chrome-*"], "allow");
  assert.match(definitions["chrome-browser-agent"].prompt, /Declared skills/);
  assert.match(definitions["aad-root-owner"].prompt, /OpenCode runtime mapping/);
  assert.doesNotMatch(definitions["aad-root-owner"].prompt, /aad-acceptance-auditor/);
  assert.equal("model" in definitions["aad-root-owner"], false);

  const skillView = materializeOpenCodeSkillView(fixture, cacheBase);
  assert.ok(skillView);
  assert.ok(fs.existsSync(path.join(skillView, "aad-slicing-and-delegation/SKILL.md")));
  assert.ok(fs.existsSync(path.join(skillView, "aad-slicing-and-delegation/scripts/helper.sh")));
  assert.ok(fs.existsSync(path.join(skillView, "browser-chrome/SKILL.md")));
  assert.equal(materializeOpenCodeSkillView(fixture, cacheBase), skillView);

  const plugin = createPiAgentSetupPlugin({ packageRoot: fixture, cacheBase });
  const hooks = await plugin({});
  const config = {
    agent: {
      "aad-explorer": {
        hidden: true,
        permission: { bash: "deny" },
      },
    },
  };
  await hooks.config(config);
  assert.equal(config.subagent_depth, DEFAULT_OPENCODE_SUBAGENT_DEPTH);
  assert.equal(config.agent["aad-explorer"].hidden, true);
  assert.equal(config.agent["aad-explorer"].permission.edit, "deny");
  assert.equal(config.agent["aad-explorer"].permission.bash, "deny");
  assert.deepEqual(config.skills.paths, [skillView]);

  const shorthandPermission = {
    agent: {
      "aad-auditor": { permission: "deny" },
    },
  };
  await hooks.config(shorthandPermission);
  assert.equal(shorthandPermission.agent["aad-auditor"].permission, "deny");

  const explicitDepth = { subagent_depth: 2 };
  await hooks.config(explicitDepth);
  assert.equal(explicitDepth.subagent_depth, 2);

  const output = {
    messages: [
      {
        info: { role: "user" },
        parts: [{ type: "text", text: "hello" }],
      },
    ],
  };
  await hooks["experimental.chat.messages.transform"]({}, output);
  assert.match(output.messages[0].parts[0].text, new RegExp(OPENCODE_BOOTSTRAP_MARKER));
  assert.equal(output.messages[0].parts.length, 2);
  await hooks["experimental.chat.messages.transform"]({}, output);
  assert.equal(output.messages[0].parts.length, 2);
} finally {
  fs.rmSync(fixture, { recursive: true, force: true });
  fs.rmSync(cacheBase, { recursive: true, force: true });
}

// Validate the checked-in repository when the full source tree is available.
if (fs.existsSync(path.join(ROOT, "agents/aad-root-owner.md"))) {
  const definitions = loadOpenCodeAgentDefinitions(ROOT);
  for (const name of OPENCODE_AGENT_NAMES.filter((agentName) => agentName !== "chrome-browser-agent")) {
    assert.ok(definitions[name], `missing generated OpenCode agent: ${name}`);
  }
  assert.equal(definitions["aad-explorer"].permission.edit, "deny");
  assert.equal(definitions["aad-auditor"].permission.edit, "deny");

  const repositoryCache = fs.mkdtempSync(path.join(os.tmpdir(), "pi-agent-setup-repo-cache-"));
  try {
    const skillView = materializeOpenCodeSkillView(ROOT, repositoryCache);
    assert.ok(skillView, "expected at least one checked-in skill");
    for (const entry of fs.readdirSync(skillView, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const skillPath = path.join(skillView, entry.name, "SKILL.md");
      const { frontmatter } = extractAndStripFrontmatter(fs.readFileSync(skillPath, "utf8"));
      assert.equal(frontmatter.name, entry.name, `skill directory mismatch for ${entry.name}`);
    }
  } finally {
    fs.rmSync(repositoryCache, { recursive: true, force: true });
  }
}

console.log("OpenCode adapter tests passed");

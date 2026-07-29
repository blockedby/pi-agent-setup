#!/usr/bin/env node

import assert from "node:assert/strict";
import { fork } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  DEFAULT_OPENCODE_SUBAGENT_DEPTH,
  OPENCODE_AGENT_NAMES,
  OPENCODE_BOOTSTRAP_MARKER,
  OPENCODE_SKILL_ROOTS,
  createPiAgentSetupPlugin,
  extractAndStripFrontmatter,
  loadOpenCodeAgentDefinitions,
  materializeOpenCodeSkillView,
} from "../.opencode/lib/pi-agent-setup-core.js";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const rootPackage = JSON.parse(fs.readFileSync(path.join(ROOT, "package.json"), "utf8"));
assert.deepEqual(
  rootPackage.pi.skills,
  OPENCODE_SKILL_ROOTS.map(({ sourceRoot }) => `./${sourceRoot}`),
  "the root Pi package must compose all logical skill roots",
);

const pluginEntrypoint = await import("../.opencode/plugins/pi-agent-setup.js");
assert.deepEqual(Object.keys(pluginEntrypoint), ["PiAgentSetupPlugin"]);
assert.equal(typeof pluginEntrypoint.PiAgentSetupPlugin, "function");

function write(pathname, content) {
  fs.mkdirSync(path.dirname(pathname), { recursive: true });
  fs.writeFileSync(pathname, content);
}

function agentSource(name, tools, extra = "") {
  const inheritedSkills = /(^|\n)inheritSkills:/.test(extra) ? "" : "inheritSkills: true\n";
  return `---\nname: ${name}\ndescription: Test ${name}\ntools: ${tools}\n${inheritedSkills}${extra}---\n\nYou are ${name}. Ask aad-acceptance-auditor for acceptance.\n`;
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
    path.join(root, "skills/aad/workflows/aad-delegation/SKILL.md"),
    "---\nname: aad-slicing-and-delegation\ndescription: Delegation\n---\n\n# Delegation\n",
  );
  write(
    path.join(root, "skills/aad/workflows/aad-delegation/scripts/helper.sh"),
    "#!/usr/bin/env bash\necho helper\n",
  );
  write(
    path.join(root, "skills/general/browser-chrome/SKILL.md"),
    "---\nname: browser-chrome\ndescription: Browser\n---\n\n# Browser\n",
  );
  write(
    path.join(root, "skills/general/git-branching/SKILL.md"),
    "---\nname: git-branching\ndescription: Git branching\n---\n\n# Git branching\n",
  );

  return root;
}

function evaluatePermission(permission, name, pattern = "*") {
  const rules = [];
  for (const [permissionPattern, value] of Object.entries(permission)) {
    if (typeof value === "string") {
      rules.push({ permissionPattern, pattern: "*", action: value });
    } else {
      for (const [inputPattern, action] of Object.entries(value)) {
        rules.push({ permissionPattern, pattern: inputPattern, action });
      }
    }
  }
  const matches = (value, glob) => {
    const escaped = glob
      .replace(/[.+^${}()|[\]\\]/g, "\\$&")
      .replaceAll("*", ".*")
      .replaceAll("?", ".");
    return new RegExp(`^${escaped}$`).test(value);
  };
  return rules.findLast(
    (rule) => matches(name, rule.permissionPattern) && matches(pattern, rule.pattern),
  )?.action;
}

function materializeInChild(fixture, cacheBase) {
  return new Promise((resolve, reject) => {
    const child = fork(new URL("./test-opencode-cache-worker.mjs", import.meta.url), [], {
      env: { ...process.env, OPENCODE_FIXTURE: fixture, OPENCODE_CACHE_BASE: cacheBase },
      stdio: ["ignore", "pipe", "pipe", "ipc"],
    });
    let stderr = "";
    let result;
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("message", (message) => {
      result = message;
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code !== 0) {
        reject(new Error(stderr || `cache worker exited ${code}`));
      } else if (typeof result !== "string") {
        reject(new Error("cache worker did not return a target"));
      } else {
        resolve(result);
      }
    });
  });
}

{
  const parsed = extractAndStripFrontmatter(
    '---\r\nname: test-agent\r\ndescription: "quoted: value"\r\nenabled: true\r\n---\r\nBody\r\n',
  );
  assert.equal(parsed.frontmatter.name, "test-agent");
  assert.equal(parsed.frontmatter.description, "quoted: value");
  assert.equal(parsed.frontmatter.enabled, true);
  assert.equal(parsed.content, "Body\n");
  assert.throws(
    () =>
      extractAndStripFrontmatter(
        "---\nname: invalid\ndescription: malformed: yaml\n---\nBody\n",
      ),
    /quote the value/,
  );
  assert.throws(
    () =>
      extractAndStripFrontmatter(
        "---\nname: invalid\ndescription: # YAML null, not a string\n---\nBody\n",
      ),
    /quote the value/,
  );
}

const fixture = makeFixture();
const cacheBase = fs.mkdtempSync(path.join(os.tmpdir(), "pi-agent-setup-cache-"));

try {
  const definitions = loadOpenCodeAgentDefinitions(fixture);
  assert.deepEqual(Object.keys(definitions), OPENCODE_AGENT_NAMES);

  const browserSkill = path.join(fixture, "skills/general/browser-chrome/SKILL.md");
  const disabledBrowserSkill = `${browserSkill}.disabled`;
  fs.renameSync(browserSkill, disabledBrowserSkill);
  write(
    path.join(fixture, "skills/browser-chrome/SKILL.md"),
    "---\nname: browser-chrome\ndescription: Old browser path\n---\n",
  );
  assert.equal(
    loadOpenCodeAgentDefinitions(fixture)["chrome-browser-agent"],
    undefined,
    "the legacy browser skill path must not enable the browser agent",
  );
  fs.rmSync(path.join(fixture, "skills/browser-chrome"), { recursive: true, force: true });
  fs.renameSync(disabledBrowserSkill, browserSkill);
  assert.ok(loadOpenCodeAgentDefinitions(fixture)["chrome-browser-agent"]);

  assert.equal(definitions["aad-root-owner"].mode, "subagent");
  assert.equal(definitions["aad-root-owner"].permission["*"], "deny");
  assert.equal(definitions["aad-root-owner"].permission.task["*"], "deny");
  assert.equal(definitions["aad-root-owner"].permission.task["aad-slice-owner"], "allow");
  assert.equal(definitions["aad-slice-owner"].permission.task["aad-implementer"], "allow");
  assert.equal(definitions["aad-implementer"].permission.task, "deny");
  assert.equal(definitions["aad-explorer"].permission.edit, "deny");
  assert.equal(definitions["aad-explorer"].permission.bash, "ask");
  assert.equal(definitions["aad-explorer"].permission.glob, "allow");
  assert.equal(definitions["aad-root-owner"].permission.read["*.env"], "ask");
  assert.equal(definitions["aad-root-owner"].permission.read["*.env.*"], "ask");
  assert.equal(definitions["aad-root-owner"].permission.read["*.env.example"], "allow");
  assert.equal(definitions["aad-auditor"].permission.edit, "deny");
  assert.equal(definitions["chrome-browser-agent"].permission["browser-chrome-*"], "allow");
  assert.match(definitions["chrome-browser-agent"].prompt, /Declared skills/);
  assert.match(definitions["aad-root-owner"].prompt, /OpenCode runtime mapping/);
  assert.doesNotMatch(definitions["aad-root-owner"].prompt, /aad-acceptance-auditor/);
  for (const executablePiSyntax of [
    /`subagent`/,
    /`tasks: \[\.\.\.\]`/,
    /`concurrency`/,
    /`reads`/,
    /`progress: true`/,
    /`async: true`/,
    /`subagent_type`/,
  ]) {
    for (const definition of Object.values(definitions)) {
      assert.doesNotMatch(definition.prompt, executablePiSyntax);
    }
  }
  assert.equal("model" in definitions["aad-root-owner"], false);

  const skillView = materializeOpenCodeSkillView(fixture, cacheBase);
  assert.ok(skillView);
  assert.ok(fs.existsSync(path.join(skillView, "aad-slicing-and-delegation/SKILL.md")));
  assert.ok(fs.existsSync(path.join(skillView, "aad-slicing-and-delegation/scripts/helper.sh")));
  assert.ok(fs.existsSync(path.join(skillView, "browser-chrome/SKILL.md")));
  const marker = JSON.parse(
    fs.readFileSync(path.join(skillView, ".pi-agent-setup-skill-view.json"), "utf8"),
  );
  assert.equal(marker.fingerprint, path.basename(skillView));
  assert.deepEqual(marker.skills, [
    {
      runtimeName: "aad-slicing-and-delegation",
      logicalSet: "aad",
      sourceRelativePath: "skills/aad/workflows/aad-delegation",
    },
    {
      runtimeName: "browser-chrome",
      logicalSet: "general",
      sourceRelativePath: "skills/general/browser-chrome",
    },
    {
      runtimeName: "git-branching",
      logicalSet: "general",
      sourceRelativePath: "skills/general/git-branching",
    },
  ]);
  assert.equal(materializeOpenCodeSkillView(fixture, cacheBase), skillView);

  const helper = path.join(
    fixture,
    "skills/aad/workflows/aad-delegation/scripts/helper.sh",
  );
  fs.chmodSync(helper, 0o755);
  const executableSkillView = materializeOpenCodeSkillView(fixture, cacheBase);
  assert.notEqual(executableSkillView, skillView);
  assert.equal(
    fs.statSync(path.join(executableSkillView, "aad-slicing-and-delegation/scripts/helper.sh")).mode &
      0o777,
    0o755,
  );

  const concurrentCacheBase = fs.mkdtempSync(
    path.join(os.tmpdir(), "pi-agent-setup-concurrent-cache-"),
  );
  try {
    const concurrentViews = await Promise.all(
      Array.from({ length: 8 }, () => materializeInChild(fixture, concurrentCacheBase)),
    );
    assert.equal(new Set(concurrentViews).size, 1);
    const concurrentView = concurrentViews[0];
    assert.ok(fs.existsSync(path.join(concurrentView, ".pi-agent-setup-skill-view.json")));
    assert.ok(
      fs.existsSync(path.join(concurrentView, "aad-slicing-and-delegation/scripts/helper.sh")),
    );
    assert.equal(
      fs.readdirSync(path.dirname(concurrentView)).filter((name) => name.includes(".tmp-")).length,
      0,
    );
  } finally {
    fs.rmSync(concurrentCacheBase, { recursive: true, force: true });
  }

  const boundaryFixture = fs.mkdtempSync(
    path.join(os.tmpdir(), "pi-agent-setup-boundary-fixture-"),
  );
  const boundaryCache = fs.mkdtempSync(
    path.join(os.tmpdir(), "pi-agent-setup-boundary-cache-"),
  );
  try {
    const sourceLeaf = "nested/source-leaf";
    const skillContent =
      "---\nname: boundary-skill\ndescription: Boundary cache test\n---\n\n# Boundary\n";
    write(path.join(boundaryFixture, "skills/general", sourceLeaf, "SKILL.md"), skillContent);
    const generalView = materializeOpenCodeSkillView(boundaryFixture, boundaryCache);

    fs.mkdirSync(path.join(boundaryFixture, "skills/aad/nested"), { recursive: true });
    fs.renameSync(
      path.join(boundaryFixture, "skills/general", sourceLeaf),
      path.join(boundaryFixture, "skills/aad", sourceLeaf),
    );
    const aadView = materializeOpenCodeSkillView(boundaryFixture, boundaryCache);
    assert.notEqual(aadView, generalView, "moving a skill between sets must invalidate cache");
    const aadMarker = JSON.parse(
      fs.readFileSync(path.join(aadView, ".pi-agent-setup-skill-view.json"), "utf8"),
    );
    assert.deepEqual(aadMarker.skills, [
      {
        runtimeName: "boundary-skill",
        logicalSet: "aad",
        sourceRelativePath: "skills/aad/nested/source-leaf",
      },
    ]);
  } finally {
    fs.rmSync(boundaryFixture, { recursive: true, force: true });
    fs.rmSync(boundaryCache, { recursive: true, force: true });
  }

  const collisionFixture = fs.mkdtempSync(
    path.join(os.tmpdir(), "pi-agent-setup-collision-fixture-"),
  );
  const collisionCache = fs.mkdtempSync(
    path.join(os.tmpdir(), "pi-agent-setup-collision-cache-"),
  );
  try {
    write(
      path.join(collisionFixture, "skills/general/nested/first/SKILL.md"),
      "---\nname: duplicate-skill\ndescription: First\n---\n",
    );
    write(
      path.join(collisionFixture, "skills/aad/deeper/second/SKILL.md"),
      "---\nname: duplicate-skill\ndescription: Second\n---\n",
    );
    assert.throws(
      () => materializeOpenCodeSkillView(collisionFixture, collisionCache),
      /Duplicate OpenCode skill name duplicate-skill: skills\/general\/nested\/first and skills\/aad\/deeper\/second/,
    );
    await assert.rejects(
      createPiAgentSetupPlugin({
        packageRoot: collisionFixture,
        cacheBase: collisionCache,
      })({}),
      /Duplicate OpenCode skill name duplicate-skill/,
    );
  } finally {
    fs.rmSync(collisionFixture, { recursive: true, force: true });
    fs.rmSync(collisionCache, { recursive: true, force: true });
  }

  const plugin = createPiAgentSetupPlugin({ packageRoot: fixture, cacheBase });
  const hooks = await plugin({});
  const config = {
    permission: {
      bash: "deny",
      read: { "*": "allow", "secrets/**": "deny" },
      "browser-chrome-screenshot": "deny",
      "custom_*": "ask",
    },
    agent: {
      "aad-root-owner": {
        permission: {
          read: { "secrets/**": "ask", "secrets/*": "ask" },
          task: { "aad-explorer": "deny" },
        },
      },
      "aad-explorer": {
        hidden: true,
        permission: { bash: "deny" },
      },
    },
  };
  await hooks.config(config);
  assert.equal(config.subagent_depth, DEFAULT_OPENCODE_SUBAGENT_DEPTH);
  assert.equal(config.agent["aad-root-owner"].permission["*"], "deny");
  assert.equal(config.agent["aad-root-owner"].permission.bash, "deny");
  assert.equal(config.agent["aad-root-owner"].permission.task["*"], "deny");
  assert.equal(config.agent["aad-root-owner"].permission.task["aad-slice-owner"], "allow");
  assert.equal(config.agent["aad-root-owner"].permission.task["aad-explorer"], "deny");
  assert.equal(
    evaluatePermission(config.agent["aad-root-owner"].permission, "read", ".env"),
    "ask",
  );
  assert.equal(
    evaluatePermission(config.agent["aad-root-owner"].permission, "read", "secrets/key.txt"),
    "deny",
  );
  assert.equal(config.agent["aad-root-owner"].permission.read["secrets/**"], "deny");
  assert.equal(
    evaluatePermission(config.agent["aad-root-owner"].permission, "custom_destructive"),
    "deny",
  );
  assert.equal(
    evaluatePermission(
      config.agent["chrome-browser-agent"].permission,
      "browser-chrome-screenshot",
    ),
    "deny",
  );
  assert.equal(
    evaluatePermission(config.agent["chrome-browser-agent"].permission, "browser-chrome-open"),
    "allow",
  );
  assert.equal(config.agent["aad-explorer"].hidden, true);
  assert.equal(config.agent["aad-explorer"].permission.edit, "deny");
  assert.equal(config.agent["aad-explorer"].permission.bash, "deny");
  assert.deepEqual(config.skills.paths, [executableSkillView]);

  const shorthandPermission = {
    agent: {
      "aad-auditor": { permission: "deny" },
    },
  };
  await hooks.config(shorthandPermission);
  const compiledShorthand = shorthandPermission.agent["aad-auditor"].permission;
  assert.equal(compiledShorthand["*"], "deny");
  assert.ok(Object.values(compiledShorthand).every((action) => action === "deny"));

  const inheritedShorthand = { permission: "deny" };
  await hooks.config(inheritedShorthand);
  assert.equal(inheritedShorthand.agent["aad-root-owner"].permission.read, "deny");
  assert.equal(inheritedShorthand.agent["aad-root-owner"].permission.bash, "deny");
  assert.equal(
    inheritedShorthand.agent["aad-root-owner"].permission.task["aad-slice-owner"],
    "deny",
  );

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

for (const { sourceRoot } of OPENCODE_SKILL_ROOTS) {
  assert.ok(
    fs.existsSync(path.join(ROOT, sourceRoot)),
    `checked-in skill root is missing: ${sourceRoot}`,
  );
}
assert.ok(
  fs.existsSync(path.join(ROOT, "agents/aad-root-owner.md")),
  "checked-in AAD agent sources are missing",
);

{
  const definitions = loadOpenCodeAgentDefinitions(ROOT);
  for (const name of OPENCODE_AGENT_NAMES.filter((agentName) => agentName !== "chrome-browser-agent")) {
    assert.ok(definitions[name], `missing generated OpenCode agent: ${name}`);
  }
  const browserSkillExists = fs.existsSync(
    path.join(ROOT, "skills/general/browser-chrome/SKILL.md"),
  );
  assert.equal(Boolean(definitions["chrome-browser-agent"]), browserSkillExists);
  assert.equal(definitions["aad-explorer"].permission.edit, "deny");
  assert.equal(definitions["aad-auditor"].permission.edit, "deny");

  const repositoryCache = fs.mkdtempSync(path.join(os.tmpdir(), "pi-agent-setup-repo-cache-"));
  try {
    const skillView = materializeOpenCodeSkillView(ROOT, repositoryCache);
    assert.ok(skillView, "expected at least one checked-in skill");
    const marker = JSON.parse(
      fs.readFileSync(path.join(skillView, ".pi-agent-setup-skill-view.json"), "utf8"),
    );
    for (const skill of marker.skills) {
      const sourceDirectory = path.join(ROOT, skill.sourceRelativePath);
      const sourceSkillPath = path.join(sourceDirectory, "SKILL.md");
      const { frontmatter } = extractAndStripFrontmatter(
        fs.readFileSync(sourceSkillPath, "utf8"),
      );
      assert.equal(
        path.basename(sourceDirectory),
        skill.runtimeName,
        `checked-in skill leaf mismatch for ${skill.sourceRelativePath}`,
      );
      assert.equal(frontmatter.name, skill.runtimeName);
      assert.ok(
        skill.sourceRelativePath.startsWith(`skills/${skill.logicalSet}/`),
        `skill set/path mismatch for ${skill.runtimeName}`,
      );
      assert.ok(fs.existsSync(path.join(skillView, skill.runtimeName, "SKILL.md")));
    }
  } finally {
    fs.rmSync(repositoryCache, { recursive: true, force: true });
  }
}

console.log("OpenCode adapter tests passed");

import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const moduleDirectory = path.dirname(fileURLToPath(import.meta.url));
const defaultPackageRoot = path.resolve(moduleDirectory, "../..");

export const OPENCODE_BOOTSTRAP_MARKER = "pi-agent-setup:opencode-bootstrap";
export const DEFAULT_OPENCODE_SUBAGENT_DEPTH = 4;
export const OPENCODE_AGENT_NAMES = [
  "aad-root-owner",
  "aad-slice-owner",
  "aad-implementer",
  "aad-explorer",
  "aad-auditor",
  "chrome-browser-agent",
];

const PI_TOOL_TO_PERMISSION = {
  read: "read",
  write: "edit",
  edit: "edit",
  apply_patch_codex: "edit",
  bash: "bash",
  grep: "grep",
  find: "glob",
  ls: "glob",
  web_search_codex: "websearch",
  web_fetch_codex: "webfetch",
  subagent: "task",
};

const AGENT_POLICIES = {
  "aad-root-owner": {
    permission: {
      todowrite: "allow",
      task: {
        "*": "deny",
        "aad-slice-owner": "allow",
        "aad-explorer": "allow",
        "aad-auditor": "allow",
        "chrome-browser-agent": "allow",
      },
    },
  },
  "aad-slice-owner": {
    permission: {
      todowrite: "allow",
      task: {
        "*": "deny",
        "aad-slice-owner": "allow",
        "aad-implementer": "allow",
        "aad-explorer": "allow",
        "aad-auditor": "allow",
        "chrome-browser-agent": "allow",
      },
    },
  },
  "aad-implementer": {
    permission: {
      task: "deny",
      todowrite: "allow",
    },
  },
  "aad-explorer": {
    permission: {
      edit: "deny",
      task: "deny",
      todowrite: "deny",
      bash: "ask",
    },
  },
  "aad-auditor": {
    permission: {
      edit: "deny",
      task: "deny",
      todowrite: "deny",
      bash: "ask",
      "browser-chrome-*": "ask",
      "browser_chrome_*": "ask",
    },
  },
  "chrome-browser-agent": {
    requiredPaths: ["skills/browser-chrome/SKILL.md"],
    permission: {
      task: "deny",
      "browser-chrome-*": "allow",
      "browser_chrome_*": "allow",
    },
  },
};

export const OPENCODE_RUNTIME_MAPPING = `## OpenCode runtime mapping

This agent prompt is shared with Pi. Resolve runtime actions through OpenCode as follows:

- Invoke a named child agent with OpenCode's \`task\` tool and the matching \`subagent_type\`.
- Pi-only \`subagent\` fields such as \`tasks\`, \`concurrency\`, \`async\`, \`reads\`, and \`progress\` express intent, not an OpenCode tool schema. Use separate \`task\` calls for independent work, and pass durable context through repository files or task-package artifacts.
- Load reusable instructions with OpenCode's native \`skill\` tool.
- Track todos with \`todowrite\` when useful.
- Map Pi tools to OpenCode tools: \`web_search_codex\` → \`websearch\`, \`web_fetch_codex\` → \`webfetch\`, \`apply_patch_codex\`/\`write\`/\`edit\` → OpenCode file editing, \`find\`/\`ls\` → \`glob\`.
- Preserve existing \`PI_RESULT\` status labels as a compatibility protocol; they are report text, not tool calls.
- Never invent Pi-only arguments when calling an OpenCode tool. Follow the live OpenCode tool schema.
`;

function parseScalar(value) {
  const trimmed = value.trim();
  if (
    trimmed.length >= 2 &&
    ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'")))
  ) {
    return trimmed.slice(1, -1);
  }
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  if (/^-?\d+$/.test(trimmed)) return Number.parseInt(trimmed, 10);
  return trimmed;
}

export function extractAndStripFrontmatter(content) {
  const normalized = content.replace(/\r\n/g, "\n");
  const match = normalized.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  if (!match) return { frontmatter: {}, content: normalized };

  const frontmatter = {};
  for (const line of match[1].split("\n")) {
    if (!line.trim() || /^\s/.test(line) || line.trimStart().startsWith("#")) continue;
    const colon = line.indexOf(":");
    if (colon <= 0) continue;
    const key = line.slice(0, colon).trim();
    const value = line.slice(colon + 1);
    frontmatter[key] = parseScalar(value);
  }

  return { frontmatter, content: match[2] };
}

function splitCsv(value) {
  if (typeof value !== "string") return [];
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function permissionsFromPiAgent(frontmatter) {
  const permission = {};
  for (const piTool of splitCsv(frontmatter.tools)) {
    const openCodePermission = PI_TOOL_TO_PERMISSION[piTool];
    if (openCodePermission) permission[openCodePermission] = "allow";
  }
  if (frontmatter.inheritSkills === true || splitCsv(frontmatter.skills).length > 0) {
    permission.skill = "allow";
  }
  return permission;
}

function mergeAgentConfig(generated, existing) {
  const override =
    existing && typeof existing === "object" && !Array.isArray(existing) ? existing : {};
  const merged = {
    ...generated,
    ...override,
  };

  if (override.permission === undefined) {
    merged.permission = generated.permission;
  } else if (
    override.permission &&
    typeof override.permission === "object" &&
    !Array.isArray(override.permission)
  ) {
    merged.permission = {
      ...generated.permission,
      ...override.permission,
    };
  } else {
    merged.permission = override.permission;
  }

  return merged;
}

function adaptSharedPromptForOpenCode(body) {
  return body.replaceAll("aad-acceptance-auditor", "aad-auditor");
}

function runtimePrompt(body, frontmatter) {
  const declaredSkills = splitCsv(frontmatter.skills);
  const skillNote = declaredSkills.length
    ? `## Declared skills\n\nLoad these skills with OpenCode's \`skill\` tool when they are available: ${declaredSkills
        .map((name) => `\`${name}\``)
        .join(", ")}. If a required skill is unavailable, report the missing capability instead of inventing it.\n\n`
    : "";
  return `${OPENCODE_RUNTIME_MAPPING}\n${skillNote}${adaptSharedPromptForOpenCode(body).trim()}\n`;
}

export function loadOpenCodeAgentDefinitions(packageRoot = defaultPackageRoot) {
  const definitions = {};

  for (const agentName of OPENCODE_AGENT_NAMES) {
    const policy = AGENT_POLICIES[agentName] || {};
    if (
      policy.requiredPaths?.some(
        (relativePath) => !fs.existsSync(path.join(packageRoot, relativePath)),
      )
    ) {
      continue;
    }

    const agentPath = path.join(packageRoot, "agents", `${agentName}.md`);
    if (!fs.existsSync(agentPath)) continue;

    const { frontmatter, content } = extractAndStripFrontmatter(
      fs.readFileSync(agentPath, "utf8"),
    );
    if (frontmatter.name && frontmatter.name !== agentName) {
      throw new Error(
        `Agent name mismatch: ${agentPath} declares ${frontmatter.name}, expected ${agentName}`,
      );
    }
    if (!frontmatter.description) {
      throw new Error(`Agent description is required: ${agentPath}`);
    }

    definitions[agentName] = {
      description: frontmatter.description,
      mode: "subagent",
      prompt: runtimePrompt(content, frontmatter),
      permission: {
        ...permissionsFromPiAgent(frontmatter),
        ...(policy.permission || {}),
      },
    };
  }

  return definitions;
}

function isSafeSkillName(name) {
  return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name);
}

function discoverSkills(packageRoot) {
  const skillsRoot = path.join(packageRoot, "skills");
  if (!fs.existsSync(skillsRoot)) return [];

  const skills = [];
  const names = new Set();
  for (const entry of fs.readdirSync(skillsRoot, { withFileTypes: true })) {
    const sourceDirectory = path.join(skillsRoot, entry.name);
    const skillPath = path.join(sourceDirectory, "SKILL.md");
    if (!fs.existsSync(skillPath)) continue;

    const { frontmatter } = extractAndStripFrontmatter(fs.readFileSync(skillPath, "utf8"));
    const runtimeName = frontmatter.name;
    if (typeof runtimeName !== "string" || !isSafeSkillName(runtimeName)) {
      throw new Error(`Invalid OpenCode skill name in ${skillPath}: ${String(runtimeName)}`);
    }
    if (names.has(runtimeName)) {
      throw new Error(`Duplicate OpenCode skill name: ${runtimeName}`);
    }
    names.add(runtimeName);
    skills.push({ runtimeName, sourceDirectory });
  }

  return skills.sort((left, right) => left.runtimeName.localeCompare(right.runtimeName));
}

function hashDirectory(hash, directory, relativePrefix = "") {
  for (const entry of fs
    .readdirSync(directory, { withFileTypes: true })
    .sort((left, right) => left.name.localeCompare(right.name))) {
    if (entry.name === ".git") continue;
    const absolutePath = path.join(directory, entry.name);
    const relativePath = path.posix.join(relativePrefix, entry.name);
    hash.update(relativePath);
    if (entry.isDirectory()) {
      hash.update("directory");
      hashDirectory(hash, absolutePath, relativePath);
    } else if (entry.isSymbolicLink()) {
      hash.update("symlink");
      hash.update(fs.readlinkSync(absolutePath));
    } else if (entry.isFile()) {
      hash.update("file");
      hash.update(fs.readFileSync(absolutePath));
    }
  }
}

function skillViewFingerprint(skills) {
  const hash = createHash("sha256");
  for (const skill of skills) {
    hash.update(skill.runtimeName);
    hashDirectory(hash, skill.sourceDirectory);
  }
  return hash.digest("hex").slice(0, 20);
}

function defaultCacheBase() {
  return process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache");
}

function copySkillDirectory(source, destination) {
  fs.cpSync(source, destination, {
    recursive: true,
    filter: (sourcePath) => path.basename(sourcePath) !== ".git",
  });
}

export function materializeOpenCodeSkillView(
  packageRoot = defaultPackageRoot,
  cacheBase = defaultCacheBase(),
) {
  const skills = discoverSkills(packageRoot);
  if (skills.length === 0) return null;

  const fingerprint = skillViewFingerprint(skills);
  const parent = path.join(cacheBase, "opencode", "pi-agent-setup", "skills");
  const target = path.join(parent, fingerprint);
  const marker = path.join(target, ".pi-agent-setup-skill-view.json");
  if (fs.existsSync(marker)) return target;

  fs.mkdirSync(parent, { recursive: true });
  if (fs.existsSync(target)) {
    fs.rmSync(target, { recursive: true, force: true });
  }
  const temporary = `${target}.tmp-${process.pid}-${Date.now()}`;
  fs.mkdirSync(temporary, { recursive: true });

  try {
    for (const skill of skills) {
      copySkillDirectory(skill.sourceDirectory, path.join(temporary, skill.runtimeName));
    }
    fs.writeFileSync(
      path.join(temporary, ".pi-agent-setup-skill-view.json"),
      `${JSON.stringify(
        {
          packageRoot,
          fingerprint,
          skills: skills.map((skill) => skill.runtimeName),
        },
        null,
        2,
      )}\n`,
    );

    try {
      fs.renameSync(temporary, target);
    } catch (error) {
      if (!fs.existsSync(marker)) throw error;
      fs.rmSync(temporary, { recursive: true, force: true });
    }
  } catch (error) {
    fs.rmSync(temporary, { recursive: true, force: true });
    throw error;
  }

  return target;
}

export function buildOpenCodeBootstrap() {
  return `<PI_AGENT_SETUP_BOOTSTRAP>\n${OPENCODE_BOOTSTRAP_MARKER}\n\n## AAD routing in OpenCode\n\nWhen you are the primary terminal assistant:\n\n- Handle only clearly trivial one-step work directly.\n- Route one clear implementation slice to \`aad-slice-owner\` through the \`task\` tool.\n- Route unclear, multi-step, multi-slice, cross-cutting, or integration-heavy work to \`aad-root-owner\`.\n- Use \`aad-explorer\` only for bounded read-only discovery when no owner handoff is needed.\n\nWhen you are already running as an AAD or browser subagent, ignore the primary routing rules and follow your own agent prompt.\n\n${OPENCODE_RUNTIME_MAPPING}\n</PI_AGENT_SETUP_BOOTSTRAP>`;
}

function messageContainsBootstrap(message) {
  const parts = message?.parts;
  if (!Array.isArray(parts)) return false;
  return parts.some(
    (part) =>
      part?.type === "text" &&
      typeof part.text === "string" &&
      part.text.includes(OPENCODE_BOOTSTRAP_MARKER),
  );
}

async function logWarning(client, message) {
  try {
    await client?.app?.log?.({
      body: {
        service: "pi-agent-setup",
        level: "warn",
        message,
      },
    });
  } catch {
    // Logging must never prevent the adapter from loading.
  }
}

export function createPiAgentSetupPlugin({
  packageRoot = defaultPackageRoot,
  cacheBase = defaultCacheBase(),
} = {}) {
  return async ({ client } = {}) => {
    let skillView;
    try {
      skillView = materializeOpenCodeSkillView(packageRoot, cacheBase);
    } catch (error) {
      await logWarning(client, `Could not materialize normalized skills: ${error.message}`);
      const directSkills = path.join(packageRoot, "skills");
      skillView = fs.existsSync(directSkills) ? directSkills : null;
    }

    const generatedAgents = loadOpenCodeAgentDefinitions(packageRoot);
    const bootstrap = buildOpenCodeBootstrap();

    return {
      config: async (config) => {
        if (skillView) {
          config.skills ||= {};
          config.skills.paths ||= [];
          if (!config.skills.paths.includes(skillView)) {
            config.skills.paths.push(skillView);
          }
        }

        config.agent ||= {};
        for (const [agentName, generated] of Object.entries(generatedAgents)) {
          config.agent[agentName] = mergeAgentConfig(generated, config.agent[agentName]);
        }

        if (config.subagent_depth === undefined || config.subagent_depth === null) {
          config.subagent_depth = DEFAULT_OPENCODE_SUBAGENT_DEPTH;
        }
      },

      "experimental.chat.messages.transform": async (_input, output) => {
        if (!Array.isArray(output.messages) || output.messages.length === 0) return;
        if (output.messages.some(messageContainsBootstrap)) return;

        const firstUser = output.messages.find((message) => message?.info?.role === "user");
        if (!firstUser) return;
        firstUser.parts ||= [];
        const reference = firstUser.parts[0] || {};
        firstUser.parts.unshift({ ...reference, type: "text", text: bootstrap });
      },
    };
  };
}


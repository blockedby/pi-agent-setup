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
export const OPENCODE_SKILL_ROOTS = [
  { logicalSet: "general", sourceRoot: "skills/general" },
  { logicalSet: "aad", sourceRoot: "skills/aad" },
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
    requiredPaths: ["skills/general/browser-chrome/SKILL.md"],
    permission: {
      task: "deny",
      "browser-chrome-*": "allow",
      "browser_chrome_*": "allow",
    },
  },
};

export const OPENCODE_RUNTIME_MAPPING = `## OpenCode runtime mapping

This agent prompt is shared with Pi. Resolve every runtime action through the live OpenCode tool schema:

- Invoke named child agents with OpenCode's \`task\` tool and the matching child-agent type.
- Translate independent or parallel delegation into separate \`task\` calls. Put required file paths and durable context in each child prompt.
- Use OpenCode child sessions for background work only when the parent can continue useful independent work.
- Load reusable instructions with OpenCode's native \`skill\` tool.
- Track todos with \`todowrite\` when useful.
- Map shared tools to OpenCode tools: web search → \`websearch\`, web fetch → \`webfetch\`, file changes → OpenCode editing tools, directory discovery → \`glob\`.
- Preserve existing \`PI_RESULT\` status labels as a compatibility protocol; they are report text, not tool calls.
- Ignore any Pi-specific call shape remaining in prose. Never send Pi-only arguments to an OpenCode tool; follow the live schema.
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

const PROTECTED_READ_PERMISSION = {
  "*": "allow",
  "*.env": "ask",
  "*.env.*": "ask",
  "*.env.example": "allow",
};

function permissionsFromPiAgent(frontmatter) {
  const permission = { "*": "deny" };
  for (const piTool of splitCsv(frontmatter.tools)) {
    const openCodePermission = PI_TOOL_TO_PERMISSION[piTool];
    if (openCodePermission) {
      permission[openCodePermission] =
        openCodePermission === "read" ? { ...PROTECTED_READ_PERMISSION } : "allow";
    }
  }
  if (frontmatter.inheritSkills === true || splitCsv(frontmatter.skills).length > 0) {
    permission.skill = "allow";
  }
  return permission;
}

function wildcardMatch(value, pattern) {
  const escaped = pattern
    .replaceAll("\\", "/")
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replaceAll("*", ".*")
    .replaceAll("?", ".");
  const optionalArgument = escaped.endsWith(" .*")
    ? `${escaped.slice(0, -3)}(?: .*)?`
    : escaped;
  return new RegExp(`^${optionalArgument}$`).test(value.replaceAll("\\", "/"));
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function permissionRules(config) {
  const normalized = typeof config === "string" ? { "*": config } : config;
  if (!isPlainObject(normalized)) return [];

  const rules = [];
  for (const [permission, value] of Object.entries(normalized)) {
    if (typeof value === "string") {
      rules.push({ permission, pattern: "*", action: value });
    } else if (isPlainObject(value)) {
      for (const [pattern, action] of Object.entries(value)) {
        if (typeof action === "string") rules.push({ permission, pattern, action });
      }
    }
  }
  return rules;
}

const ACTION_RANK = { allow: 0, ask: 1, deny: 2 };

function stricterAction(left, right) {
  return ACTION_RANK[right] > ACTION_RANK[left] ? right : left;
}

function evaluatePermission(rules, permission, pattern) {
  return (
    rules.findLast(
      (rule) =>
        wildcardMatch(permission, rule.permission) && wildcardMatch(pattern, rule.pattern),
    )?.action || "allow"
  );
}

function compilePatternPermission(permission, canonical, layers) {
  const canonicalIsObject = isPlainObject(canonical);
  let baseAction = canonicalIsObject ? canonical["*"] : canonical;
  const ruleLayers = layers.map(permissionRules);
  for (const rules of ruleLayers) {
    baseAction = stricterAction(baseAction, evaluatePermission(rules, permission, "*"));
  }
  if (baseAction === "deny") return "deny";

  const patterns = { "*": baseAction };
  if (canonicalIsObject) {
    for (const [pattern, action] of Object.entries(canonical)) {
      if (pattern === "*" || typeof action !== "string") continue;
      patterns[pattern] = stricterAction(baseAction, action);
    }
  }

  const restrictions = new Map();
  for (const rules of ruleLayers) {
    for (const rule of rules) {
      if (
        rule.pattern === "*" ||
        !wildcardMatch(permission, rule.permission) ||
        rule.action === "allow"
      ) {
        continue;
      }
      const action = stricterAction(baseAction, rule.action);
      const previous = restrictions.get(rule.pattern);
      restrictions.set(rule.pattern, previous ? stricterAction(previous, action) : action);
    }
  }

  for (const [pattern, action] of [...restrictions].sort(
    (left, right) => ACTION_RANK[left[1]] - ACTION_RANK[right[1]],
  )) {
    delete patterns[pattern];
    patterns[pattern] = action;
  }

  return Object.keys(patterns).length === 1 ? baseAction : patterns;
}

function compileTaskPermission(canonical, layers) {
  const compiled = { "*": "deny" };
  const ruleLayers = layers.map(permissionRules);

  for (const [target, canonicalAction] of Object.entries(canonical)) {
    if (target === "*") continue;
    let action = canonicalAction;
    for (const rules of ruleLayers) {
      action = stricterAction(action, evaluatePermission(rules, "task", target));
    }
    compiled[target] = action;
  }
  return compiled;
}

function compileNamedPermissionRestrictions(canonical, layers) {
  const canonicalPatterns = Object.keys(canonical).filter((permission) => permission !== "*");
  const restrictions = new Map();

  for (const rules of layers.map(permissionRules)) {
    for (const rule of rules) {
      if (rule.pattern !== "*" || rule.permission === "*" || rule.action === "allow") continue;
      if (
        !canonicalPatterns.some(
          (canonicalPattern) =>
            canonicalPattern !== rule.permission &&
            wildcardMatch(rule.permission, canonicalPattern),
        )
      ) {
        continue;
      }
      const previous = restrictions.get(rule.permission);
      restrictions.set(
        rule.permission,
        previous ? stricterAction(previous, rule.action) : rule.action,
      );
    }
  }

  return [...restrictions].sort(
    (left, right) => ACTION_RANK[left[1]] - ACTION_RANK[right[1]],
  );
}

function compileAgentPermission(canonical, inherited, override) {
  if (typeof inherited === "string") {
    inherited = { "*": inherited };
  }
  if (typeof override === "string") {
    override = { "*": override };
  }
  const layers = [inherited, override].filter((layer) => isPlainObject(layer));
  const compiled = { "*": "deny" };

  for (const [permission, canonicalValue] of Object.entries(canonical)) {
    if (permission === "*") continue;
    if (permission === "task" && isPlainObject(canonicalValue)) {
      compiled.task = compileTaskPermission(canonicalValue, layers);
      continue;
    }
    const canonicalAction = isPlainObject(canonicalValue)
      ? canonicalValue["*"]
      : canonicalValue;
    if (typeof canonicalAction !== "string") continue;
    compiled[permission] =
      canonicalAction === "deny"
        ? "deny"
        : compilePatternPermission(permission, canonicalValue, layers);
  }

  for (const [permission, action] of compileNamedPermissionRestrictions(canonical, layers)) {
    delete compiled[permission];
    compiled[permission] = action;
  }

  return compiled;
}

function mergeAgentConfig(generated, existing, inheritedPermission = {}) {
  const override = isPlainObject(existing) ? existing : {};
  const merged = {
    ...generated,
    ...override,
  };
  merged.permission = compileAgentPermission(
    generated.permission,
    inheritedPermission,
    override.permission,
  );
  return merged;
}

function adaptSharedPromptForOpenCode(body) {
  const replacements = new Map([
    ["aad-acceptance-auditor", "aad-auditor"],
    ["`subagent`", "OpenCode's `task` tool"],
    ["`tasks: [...]`", "parallel `task` calls"],
    ["`concurrency`", "a safe parallelism limit"],
    ["`reads`", "repository context named in the child prompt"],
    ["`progress: true`", "durable progress updates"],
    ["`async: true`", "a background child session"],
  ]);

  let adapted = body;
  for (const [source, replacement] of replacements) {
    adapted = adapted.replaceAll(source, replacement);
  }
  return adapted;
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

class OpenCodeSkillDiscoveryError extends Error {}

function toPosixRelativePath(packageRoot, sourceDirectory) {
  return path.relative(packageRoot, sourceDirectory).split(path.sep).join("/");
}

function findSkillDirectories(directory, found = []) {
  const skillPath = path.join(directory, "SKILL.md");
  if (fs.existsSync(skillPath)) found.push(directory);

  for (const entry of fs
    .readdirSync(directory, { withFileTypes: true })
    .sort((left, right) => left.name.localeCompare(right.name))) {
    if (entry.name === ".git" || !entry.isDirectory()) continue;
    findSkillDirectories(path.join(directory, entry.name), found);
  }
  return found;
}

function discoverSkills(packageRoot) {
  const skills = [];
  const names = new Map();

  for (const root of OPENCODE_SKILL_ROOTS) {
    const absoluteRoot = path.join(packageRoot, root.sourceRoot);
    if (!fs.existsSync(absoluteRoot)) continue;

    for (const sourceDirectory of findSkillDirectories(absoluteRoot)) {
      const skillPath = path.join(sourceDirectory, "SKILL.md");
      const { frontmatter } = extractAndStripFrontmatter(fs.readFileSync(skillPath, "utf8"));
      const runtimeName = frontmatter.name;
      const sourceRelativePath = toPosixRelativePath(packageRoot, sourceDirectory);
      if (typeof runtimeName !== "string" || !isSafeSkillName(runtimeName)) {
        throw new OpenCodeSkillDiscoveryError(
          `Invalid OpenCode skill name in ${skillPath}: ${String(runtimeName)}`,
        );
      }
      if (names.has(runtimeName)) {
        throw new OpenCodeSkillDiscoveryError(
          `Duplicate OpenCode skill name ${runtimeName}: ${names.get(runtimeName)} and ${sourceRelativePath}`,
        );
      }
      names.set(runtimeName, sourceRelativePath);
      skills.push({
        runtimeName,
        logicalSet: root.logicalSet,
        sourceRelativePath,
        sourceDirectory,
      });
    }
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
    const stats = fs.lstatSync(absolutePath);
    hash.update(relativePath);
    hash.update(String(stats.mode & 0o777));
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
    hash.update(`runtimeName\0${skill.runtimeName}\0`);
    hash.update(`logicalSet\0${skill.logicalSet}\0`);
    hash.update(`sourceRelativePath\0${skill.sourceRelativePath}\0`);
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
  const temporary = fs.mkdtempSync(path.join(parent, `.${fingerprint}.tmp-`));

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
          skills: skills.map(({ runtimeName, logicalSet, sourceRelativePath }) => ({
            runtimeName,
            logicalSet,
            sourceRelativePath,
          })),
        },
        null,
        2,
      )}\n`,
    );

    try {
      fs.renameSync(temporary, target);
    } catch (error) {
      if (!fs.existsSync(marker)) throw error;
    }
  } finally {
    fs.rmSync(temporary, { recursive: true, force: true });
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
    let skillPaths = [];
    try {
      const skillView = materializeOpenCodeSkillView(packageRoot, cacheBase);
      if (skillView) skillPaths = [skillView];
    } catch (error) {
      if (error instanceof OpenCodeSkillDiscoveryError) throw error;
      await logWarning(client, `Could not materialize normalized skills: ${error.message}`);
      skillPaths = OPENCODE_SKILL_ROOTS.map(({ sourceRoot }) =>
        path.join(packageRoot, sourceRoot),
      ).filter((sourceRoot) => fs.existsSync(sourceRoot));
    }

    const generatedAgents = loadOpenCodeAgentDefinitions(packageRoot);
    const bootstrap = buildOpenCodeBootstrap();

    return {
      config: async (config) => {
        if (skillPaths.length > 0) {
          config.skills ||= {};
          config.skills.paths ||= [];
          for (const skillPath of skillPaths) {
            if (!config.skills.paths.includes(skillPath)) {
              config.skills.paths.push(skillPath);
            }
          }
        }

        config.agent ||= {};
        for (const [agentName, generated] of Object.entries(generatedAgents)) {
          config.agent[agentName] = mergeAgentConfig(
            generated,
            config.agent[agentName],
            config.permission,
          );
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

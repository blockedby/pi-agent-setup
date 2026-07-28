#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(
  process.argv[2] ?? path.join(path.dirname(fileURLToPath(import.meta.url)), ".."),
);

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function requireText(source, relativePath, fragments) {
  for (const fragment of fragments) {
    assert.ok(
      source.includes(fragment),
      `${relativePath} must contain ${JSON.stringify(fragment)}`,
    );
  }
}

const forbiddenPolicies = [
  /may refine the local acceptance target/i,
  /supporting agents may refine their local target/i,
  /aad-auditor.*subagents could run in parallel/i,
  /closure audit (?:may|can|should) reopen broad discovery/i,
];

function rejectUnboundedPolicy(source, label) {
  for (const pattern of forbiddenPolicies) {
    assert.doesNotMatch(source, pattern, `${label} contains forbidden policy ${pattern}`);
  }
}

const canonicalPolicyPaths = [
  ...fs.readdirSync(path.join(root, "agents"), { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(".md"))
    .map((entry) => `agents/${entry.name}`),
  ...fs.readdirSync(path.join(root, "skills"), { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && fs.existsSync(path.join(root, "skills", entry.name, "SKILL.md")))
    .map((entry) => `skills/${entry.name}/SKILL.md`),
];
const canonicalPolicy = canonicalPolicyPaths.map(read).join("\n");
rejectUnboundedPolicy(canonicalPolicy, "canonical AAD prompts/skills");
for (const historicalMutation of [
  "You may refine the local acceptance target when that helps the audit.",
  "Supporting agents may refine their local target, but they do not redefine routing or ownership boundaries.",
  "`aad-auditor` subagents could run in parallel for independent review dimensions.",
  "A closure audit may reopen broad discovery when useful.",
]) {
  assert.throws(
    () => rejectUnboundedPolicy(`${canonicalPolicy}\n${historicalMutation}`, "mutation fixture"),
    `mutation must be rejected: ${historicalMutation}`,
  );
}

const auditor = read("agents/aad-auditor.md");
requireText(auditor, "agents/aad-auditor.md", [
  "frozen acceptance charter",
  "one baseline audit and one bounded closure audit",
  "stable finding IDs from the baseline and remediation-caused regressions",
  "implicit audit 3",
  "critical security, privacy, or data-loss issue, or any remediation regression",
  "noncritical observation outside the charter is a follow-up candidate",
  "The owner, not the auditor, classifies each finding",
  "stable audit ID (for example, `AUD-001`)",
  "do not reuse the reporting skill's `F-*` follow-up IDs",
  "non-audit `docs-only head reconciliation` mode",
  "do not count reconciliation as another audit",
]);

for (const relativePath of ["agents/aad-root-owner.md", "agents/aad-slice-owner.md"]) {
  const owner = read(relativePath);
  requireText(owner, relativePath, [
    "acceptance charter",
    "stable criterion/invariant IDs",
    "threat boundaries",
    "evidence routes",
    "executable/product tree identity",
    "one baseline audit and one bounded closure audit",
    "remediation-caused regressions",
    "implicit audit 3",
    "noncritical",
    "follow-up",
    "human/architect",
    "bounded docs-only head reconciliation",
    "implemented` → `owner-verified` → `independently accepted` → `runtime/full-suite accepted` → `merge-ready",
    "low-risk, non-concurrent, non-destructive",
  ]);
}

const planWriting = read("skills/aad-plan-writing/SKILL.md");
requireText(planWriting, "skills/aad-plan-writing/SKILL.md", [
  "## Frozen acceptance charter and audit control",
  "Stable criterion/invariant IDs",
  "Threat boundaries",
  "Evidence routes",
  "Executable/product tree identity",
  "one baseline audit and one bounded closure audit as the normal maximum",
  "stable prior finding IDs and remediation-caused regressions",
  "Noncritical new scope is a follow-up",
  "successor-task charter",
  "implicit audit 3",
  "ignored canonical task package as the sole per-result routing ledger",
  "tracked phase-publication updates at phase boundaries",
  "## Tree identity, reconciliation, and readiness",
  "explicit path set and digest for executable/product inputs",
  "it is not the product identity when approved evidence-only documentation is excluded",
  "bounded docs-only head reconciliation",
  "runtime/full-suite accepted",
  "merge-ready",
]);

const taskPackage = read("skills/aad-task-package/SKILL.md");
requireText(taskPackage, "skills/aad-task-package/SKILL.md", [
  "## Ledger and publication roles",
  "sole per-result routing ledger",
  "Tracked phase publication",
  "prove the ledger path is ignored with `git check-ignore`",
  "Keep raw child reports, progress, and repeated verification logs in the ignored canonical package",
  "Consolidate the ignored ledger into the tracked phase publication only at phase boundaries",
  "must not create a new exact-head audit target per child result",
  "frozen acceptance charter for risky, concurrent, or destructive work",
  "audit finding IDs and owner classifications",
  "readiness ladder: implemented, owner-verified, independently accepted, runtime/full-suite accepted, merge-ready",
]);

const completion = read("skills/aad-step-completion/SKILL.md");
requireText(completion, "skills/aad-step-completion/SKILL.md", [
  "## Acceptance convergence",
  "frozen acceptance charter",
  "one baseline audit and one bounded closure audit",
  "noncritical new scope is a follow-up",
  "remediation regression",
  "bounded docs-only head reconciliation",
  "## Readiness ladder",
  "runtime/full-suite accepted",
  "merge-ready",
]);

const delegation = read("skills/aad-delegation/SKILL.md");
requireText(delegation, "skills/aad-delegation/SKILL.md", [
  "Frozen acceptance charter",
  "bounded closure for stable finding IDs and remediation-caused regressions",
  "do not refine the acceptance target",
  "implicit audit 3",
]);

const reporting = read("skills/aad-reporting/SKILL.md");
requireText(reporting, "skills/aad-reporting/SKILL.md", [
  "## Acceptance state",
  "Frozen charter",
  "Audit stage",
  "Executable/product identity",
  "Readiness rung",
  "bounded docs-only passed",
]);

const gitignore = read(".gitignore");
assert.match(gitignore, /^\.pi\/aad\/$/m, ".pi/aad must be ignored in a fresh clone");

const helper = read("skills/aad-task-package/scripts/create-task-package.sh");
requireText(helper, "skills/aad-task-package/scripts/create-task-package.sh", [
  "git check-ignore",
  "Default task ledger is not ignored",
  'ledger_mode="ignored-canonical"',
  'ledger_mode="tracked-publication"',
  "printf 'ledger_mode=%s",
]);

const fixture = fs.mkdtempSync(path.join(os.tmpdir(), "aad-audit-convergence-"));
try {
  assert.equal(spawnSync("git", ["init", "-q"], { cwd: fixture }).status, 0);
  const helperPath = path.join(root, "skills/aad-task-package/scripts/create-task-package.sh");
  const rejected = spawnSync(
    "bash",
    [helperPath, "--date", "2026-01-01", "--slug", "unsafe-default"],
    { cwd: fixture, encoding: "utf8" },
  );
  assert.equal(rejected.status, 3, "unignored default ledger must fail closed");
  assert.match(rejected.stderr, /Default task ledger is not ignored/);
  assert.ok(!fs.existsSync(path.join(fixture, ".pi/aad")));

  fs.writeFileSync(path.join(fixture, ".gitignore"), ".pi/aad/\n");
  const ignored = spawnSync(
    "bash",
    [helperPath, "--date", "2026-01-01", "--slug", "ignored-ledger"],
    { cwd: fixture, encoding: "utf8" },
  );
  assert.equal(ignored.status, 0, ignored.stderr);
  assert.match(ignored.stdout, /ledger_mode=ignored-canonical/);
  assert.equal(
    spawnSync("git", ["check-ignore", "-q", ".pi/aad/tasks/2026-01-01-ignored-ledger/plan.md"], { cwd: fixture }).status,
    0,
  );

  const tracked = spawnSync(
    "bash",
    [helperPath, "--date", "2026-01-01", "--slug", "phase-publication", "--location", "docs/tasks"],
    { cwd: fixture, encoding: "utf8" },
  );
  assert.equal(tracked.status, 0, tracked.stderr);
  assert.match(tracked.stdout, /ledger_mode=tracked-publication/);
  assert.notEqual(
    spawnSync("git", ["check-ignore", "-q", "docs/tasks/2026-01-01-phase-publication/plan.md"], { cwd: fixture }).status,
    0,
  );
} finally {
  fs.rmSync(fixture, { recursive: true, force: true });
}

const packageJson = JSON.parse(read("package.json"));
assert.equal(
  packageJson.scripts["test:aad-audit-convergence"],
  "node scripts/test-aad-audit-convergence.mjs",
  "package.json must expose the audit-convergence contract test",
);
assert.match(
  packageJson.scripts.test,
  /npm run test:aad-audit-convergence/,
  "npm test must run the audit-convergence contract test",
);

console.log("AAD audit-convergence contract tests passed");

#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
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

const auditor = read("agents/aad-auditor.md");
assert.ok(
  !auditor.includes("may refine the local acceptance target"),
  "aad-auditor must not retain the unbounded acceptance-target wording",
);
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
  "ignored task state as the per-result ledger",
  "batch tracked task-package updates at phase boundaries",
  "## Tree identity, reconciliation, and readiness",
  "explicit path set and digest for executable/product inputs",
  "it is not the product identity when approved evidence-only documentation is excluded",
  "bounded docs-only head reconciliation",
  "runtime/full-suite accepted",
  "merge-ready",
]);

const taskPackage = read("skills/aad-task-package/SKILL.md");
requireText(taskPackage, "skills/aad-task-package/SKILL.md", [
  "ignored canonical AAD state: keep it as the per-result ledger",
  "keep raw child reports, progress, and repeated verification logs in the ignored canonical package",
  "Consolidate the ignored ledger into the tracked plan/report only at phase boundaries",
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

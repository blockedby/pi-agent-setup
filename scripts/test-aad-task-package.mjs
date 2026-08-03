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
const helperPath = path.join(
  root,
  "skills/aad/aad-task-package/scripts/create-task-package.sh",
);
const fixture = fs.mkdtempSync(path.join(os.tmpdir(), "aad-task-package-"));

function createPackage(...args) {
  return spawnSync("bash", [helperPath, ...args], {
    cwd: fixture,
    encoding: "utf8",
  });
}

try {
  assert.equal(spawnSync("git", ["init", "-q"], { cwd: fixture }).status, 0);

  const rejected = createPackage(
    "--date",
    "2026-01-01",
    "--slug",
    "unsafe-default",
  );
  assert.equal(rejected.status, 3, "an unignored default ledger must fail closed");
  assert.ok(!fs.existsSync(path.join(fixture, ".pi/aad")));

  fs.writeFileSync(path.join(fixture, ".gitignore"), ".pi/aad/\n");
  const ignored = createPackage(
    "--date",
    "2026-01-01",
    "--slug",
    "ignored-ledger",
  );
  assert.equal(ignored.status, 0, ignored.stderr);
  const ignoredPlan = ".pi/aad/tasks/2026-01-01-ignored-ledger/plan.md";
  assert.ok(fs.existsSync(path.join(fixture, ignoredPlan)));
  assert.equal(
    spawnSync("git", ["check-ignore", "-q", ignoredPlan], { cwd: fixture }).status,
    0,
  );

  const duplicate = createPackage(
    "--date",
    "2026-01-01",
    "--slug",
    "ignored-ledger",
  );
  assert.equal(duplicate.status, 2, "an existing task package must not be overwritten");

  const tracked = createPackage(
    "--date",
    "2026-01-01",
    "--slug",
    "phase-publication",
    "--location",
    "docs/tasks",
  );
  assert.equal(tracked.status, 0, tracked.stderr);
  const trackedPlan = "docs/tasks/2026-01-01-phase-publication/plan.md";
  assert.ok(fs.existsSync(path.join(fixture, trackedPlan)));
  assert.notEqual(
    spawnSync("git", ["check-ignore", "-q", trackedPlan], { cwd: fixture }).status,
    0,
  );
} finally {
  fs.rmSync(fixture, { recursive: true, force: true });
}

console.log("AAD task-package behavior tests passed");

---
name: devops-runtime-readiness
description: Use when planning, implementing, or reviewing config, environment, deployment, container, CI, startup, or runtime-wiring changes that need readiness evidence within existing AAD reports.
---

# DevOps Runtime Readiness

Use this skill as a focused checklist for runtime and deployment readiness. It is not a new agent, workflow, or report format. Record findings in the existing AAD task package and reports.

## When to use

Use when a task touches environment variables, config loading/validation, Dockerfiles, Compose/Kubernetes/deployment manifests, entrypoints, healthchecks, CI scripts, build args, service startup, migrations-at-startup, exposed ports, volumes, or runtime service dependencies.

## Inputs

- Delegated acceptance criteria, deployment assumptions, and verification plan.
- Existing env examples/templates, docs, local/dev wiring, CI/secrets expectations, config loaders, container files, and startup scripts.
- Applicable task package/report paths from `aad-task-package`.

## Checklist

1. Pair config changes with required declarations: examples/templates, docs, local/dev env wiring, CI/secrets expectations, deployment manifests, and runtime validation/config loaders.
2. Do not commit secrets or real environment-specific values; use placeholders or documented secret names only.
3. Preserve container conventions: build args, service env propagation, exposed ports, volumes, users, entrypoints, and frontend/backend boundaries.
4. Preserve startup behavior: service dependencies, readiness/healthchecks, migration timing, seed/bootstrap commands, and rollback expectations.
5. Check CI/build scripts affected by the change; prefer updating existing targets over adding parallel one-off commands.
6. Verify local runtime paths when possible: config validation, build, container startup, health endpoint, migration dry run, or smoke test.
7. Identify environment-specific gaps: missing secret source, unverified production manifest, unavailable external service, or stale deployment docs.
8. Avoid unsafe logging of env values, tokens, credentials, cookies, private hostnames, or sensitive config.

## Evidence mapping

Map findings into existing report fields instead of creating a new report shape:

- `aad-implementation-report`
  - `AC_VERIFICATION`: runtime/config behavior proven by targeted checks or documented manual evidence.
  - `QUALITY_CHECKS`: build, config validation, container, smoke, or CI-equivalent commands.
  - `QUALITY_NOTES` → `DevOps/runtime`: paired files updated, startup/readiness/deployment wiring notes, unresolved readiness limits.
  - `QUALITY_NOTES` → `Security` and `Compatibility/performance`: no secrets committed, no avoidable startup/runtime regressions.
- `aad-reporting`
  - `Acceptance verification`: runtime readiness criteria tied to exact checks, artifacts, or waivers.
  - `System readiness` → `Config / env / secrets`, `Runtime / deployment wiring`, and container/Docker notes where applicable.
  - `Verification run`: local targeted/full checks and remote CI after push when available.
  - `Issues`: unresolved env, deployment, healthcheck, or CI gaps.
- `aad-acceptance-auditor` report shape
  - `System readiness coverage`: config/env/secrets, Docker/containers, runtime/deployment wiring, database/migration startup coverage.
- `aad-task-package`
  - Store safe build/runtime logs under `verification/logs/` only when they materially help continuation.

## Output guidance

Use exact file paths, variable names without values, command names, service names, and healthcheck URLs. If a production deployment check cannot be run locally, state the limitation and the required owner/CI evidence.

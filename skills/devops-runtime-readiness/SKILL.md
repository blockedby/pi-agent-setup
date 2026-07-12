---
name: devops-runtime-readiness
description: Select for config, environment, containers, CI, deployment, startup, healthchecks, or runtime wiring; apply focused readiness and secret-safety checks and surface only evidence or gaps that affect acceptance.
---

# DevOps / Runtime Readiness

This is a task-selected checklist, not a new workflow or report.

## Check the touched runtime path

- pair config changes with the repository's examples/templates, docs, validation loaders, CI expectations, and deployment manifests;
- use placeholders or secret names, never real values;
- preserve container build args, environment propagation, ports, users, volumes, entrypoints, and service boundaries;
- preserve startup dependencies, health/readiness checks, migration timing, bootstrap behavior, and rollback expectations;
- update existing CI/build targets instead of adding unexplained parallel commands;
- run the narrowest available config validation, build, container, startup, health, migration, or smoke proof;
- identify environment-specific gaps such as unavailable services, secret sources, devices, production manifests, or credentials;
- keep private hosts, env values, tokens, cookies, and sensitive payloads out of logs and task artifacts.

## Evidence

Record exact files, variable names without values, services, commands, results, and remaining runtime boundary. Use full-risk audit depth for material deployment/runtime changes. Do not manufacture production readiness from a local static check or fill an all-purpose readiness table with irrelevant rows.

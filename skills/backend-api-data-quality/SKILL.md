---
name: backend-api-data-quality
description: Use when planning, implementing, or reviewing backend, API, storage, job, migration, or integration changes that need evidence for contracts, validation, auth, data safety, idempotency, and performance within existing AAD reports.
---

# Backend API Data Quality

Use this skill as a focused checklist for backend/API/data implementation quality. It is not a new agent, workflow, or report format. Record findings in the existing AAD task package and reports.

## When to use

Use when a task touches API routes/controllers, services, repositories, models, serializers, validators, jobs/queues, migrations, database access, webhooks, external integrations, or persisted data formats.

## Inputs

- Delegated acceptance criteria, API/data contract expectations, and verification plan.
- Existing adjacent handlers, services, repositories, schemas/DTOs, auth/permission helpers, transaction patterns, and tests.
- Applicable task package/report paths from `aad-task-package`.

## Checklist

1. Reuse established layers: router/controller, service, repository/model, schema/DTO, serializer, validator, auth helper, and integration client patterns.
2. Preserve public contracts unless explicitly approved: routes, methods, status codes, response fields, event payloads, CLI output, config keys, and persisted formats.
3. Match validation and error conventions: input validation, structured error shapes, logging level, retry behavior, and user-facing messages.
4. Keep permissions intact: authentication, authorization, tenant/account scoping, CSRF/CORS, and resource ownership checks.
5. Protect data writes: transaction boundaries, locking/version checks, duplicate-submit handling, safe retries, and idempotency for jobs, webhooks, and external callbacks.
6. Check migrations when relevant: naming/numbering, order conflicts, down/rollback expectations, data backfill safety, and deployment timing.
7. Avoid obvious data-path regressions: N+1 queries, missing indexes for new lookups, unbounded result sets, full-table scans, loading large payloads, and repeated external calls.
8. Keep sensitive data out of logs, errors, task artifacts, and test output.
9. Cover positive, negative, and edge cases that prove the API/data behavior within delegated scope.

## Evidence mapping

Map findings into existing report fields instead of creating a new report shape:

- `aad-implementation-report`
  - `AC_VERIFICATION`: request/response, persistence, job, or migration behavior proven by tests/checks/manual evidence.
  - `QUALITY_CHECKS`: targeted backend tests, typecheck, lint/static analysis, migration checks, affected build.
  - `QUALITY_NOTES` → `Backend/API/data`: layers reused, contracts preserved, migration/data/idempotency/performance notes.
  - `QUALITY_NOTES` → `Security`, `Concurrency/idempotency`, and `Compatibility/performance`: exact safeguards or gaps.
- `aad-reporting`
  - `Acceptance verification`: API/data acceptance criteria and evidence.
  - `System readiness`: routes/registration, services/APIs, permissions/access, database/migrations, frontend-backend integration, runtime wiring.
  - `Verification run`: local targeted/full checks and CI status when available.
  - `Issues`: unresolved contract, migration, permission, or data-safety gaps.
- `aad-task-package`
  - Put large safe logs under `verification/logs/` only when useful; summarize evidence in reports.

## Output guidance

Use exact endpoints, models/tables, migration filenames, command names, and short result excerpts. If a contract or migration risk cannot be verified locally, mark it as a gap for the owner/auditor rather than assuming readiness.

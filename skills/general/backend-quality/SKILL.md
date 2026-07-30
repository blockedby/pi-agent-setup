---
name: backend-quality
description: Use when planning, implementing, or reviewing backend, API, storage, job, migration, or integration changes that need evidence for contracts, validation, auth, data safety, idempotency, and performance.
---

# Backend API Data Quality

Use this skill as a focused checklist for backend/API/data implementation quality.

## When to use

Use when a task touches API routes/controllers, services, repositories, models, serializers, validators, jobs/queues, migrations, database access, webhooks, external integrations, or persisted data formats.

## Inputs

- Caller-provided acceptance criteria, API/data contract expectations, and verification plan.
- Existing adjacent handlers, services, repositories, schemas/DTOs, auth/permission helpers, transaction patterns, and tests.

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

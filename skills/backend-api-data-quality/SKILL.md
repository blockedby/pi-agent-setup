---
name: backend-api-data-quality
description: Select for backend, API, storage, jobs, migrations, webhooks, or persisted-data work; apply a focused contract/data-safety checklist and record only material evidence in the current task result.
---

# Backend / API / Data Quality

This is a task-selected checklist, not a new workflow or report.

## Check the touched boundary

- reuse established router/controller, service, repository/model, schema/DTO, validator, auth, and client patterns;
- preserve public routes, methods, status codes, payloads, events, config keys, and persisted formats unless a breaking change is explicitly accepted;
- match validation, structured error, logging, retry, and user-facing message conventions;
- preserve authentication, authorization, tenant/account scoping, ownership checks, CSRF/CORS, and secret-handling boundaries;
- check transaction, duplicate-submit, idempotency, locking/version, retry, race, and webhook/job behavior when relevant;
- check migration order, conflicts, rollback expectations, backfill safety, and deployment timing when relevant;
- avoid N+1 queries, unbounded reads, missing indexes, repeated external calls, and large in-memory payloads;
- prove relevant positive, negative, and edge behavior.

## Evidence

Record only material results:

- acceptance evidence in the owner task record;
- exact tests/checks in the implementation result;
- a short `QUALITY_NOTES` entry only for meaningful contract, auth, migration, data-safety, concurrency, compatibility, or performance findings;
- unresolved risk as an exact audit gap.

Do not emit every checklist item as `not applicable`. If production/runtime evidence is unavailable, state the boundary and required owner/CI proof.

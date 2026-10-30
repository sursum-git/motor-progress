# Continuous Parallel Worker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep Sursum/MED parallel exports fed continuously while snapshotting four or eight concurrent partitions according to the enqueue time in São Paulo.

**Architecture:** The saved query declares a São Paulo time schedule and the PASOE resolves it once at enqueue into a numeric `maxWorkers` snapshot. The private PHP worker repeats bounded batches of authenticated `/consumer-jobs/drain` requests; every request remains subject to that saved lease cap and processes no caller-selected target.

**Tech Stack:** PHP 8 private worker, OpenEdge/PASOE MED, JSON query configuration, PHP lint and PASOE integration validation.

**Spec:** `docs/superpowers/specs/2026-10-30-continuous-parallel-worker-design.md`

## Global Constraints

- Only Sursum/MED/9911 may be changed or validated.
- Workers remain private and are invoked locally only.
- PASOE leases remain the concurrency authority; no public worker endpoint is added.
- Existing job plans are immutable snapshots; only newly enqueued jobs receive `maxWorkers: 4` or `8`.

## Review Focus

- Empty queue after a productive round must terminate cleanly without a busy loop.
- A PASOE response error must stop the worker and retain the existing health/error behavior.
- Four concurrent leases by day and eight at night must be the maximum even when PHP starts more requests.
- The bounded cycle must not run indefinitely on a long queue.
- Swagger/Postman must describe the new limit without implying a change to existing jobs.

---

### Task 1: Bounded private worker rounds

**Files:**
- Modify: `ops/consumer-jobs-worker.php:38-50`
- Test: `tests/php/consumer-jobs-worker-rounds.test.php`

**Interfaces:**
- Consumes: existing authenticated `workerPasoe()`/TLS helpers and `/consumer-jobs/drain` response `{success, processed}`.
- Produces: a bounded round loop that stops on zero processed jobs and accumulates the worker health count.

- [ ] **Step 1: Write the failing round-loop test**

Assert that productive rounds repeat only to the fixed round cap and that the first zero-processed round ends dispatch.

- [ ] **Step 2: Run the PHP test to verify it fails**

Run: `php tests/php/consumer-jobs-worker-rounds.test.php`
Expected: FAIL because the current worker dispatches only one batch.

- [ ] **Step 3: Extract and implement bounded drain-round dispatch**

Use a fixed round cap, retain the current ten request handles per round, and stop after a round reports no processed jobs. Keep each PASOE response validation unchanged.

- [ ] **Step 4: Run PHP lint and the round-loop test**

Run: `php -l ops/consumer-jobs-worker.php; php tests/php/consumer-jobs-worker-rounds.test.php`
Expected: both pass.

### Task 2: Time-scheduled saved-query policy and generated API documentation

**Files:**
- Modify: `sursum-api/querys/movimentacoes-estoque.json`
- Modify: `web/query-api-docs-lib.php`
- Regenerate: `docs/api/sursum-med-openapi.json`, `docs/api/sursum-med-postman.collection.json`

**Interfaces:**
- Consumes: `asyncParallel.workerSchedule` with São Paulo intervals and worker counts.
- Produces: new async job snapshots with resolved `maxWorkers: 4` or `8` and matching public documentation.

- [ ] **Step 1: Write failing ABL schedule-resolution tests and update the catalog assertion**

Assert 20:00 resolves to eight, 05:00 resolves to four, and a created plan retains the resolved number. Assert the generated OpenAPI and Postman collection describe both schedule values.

- [ ] **Step 2: Run the tests to verify they fail**

Run the official ABL schedule test and documentation assertion.
Expected: FAIL while the JSON still declares one static value.

- [ ] **Step 3: Add `workerSchedule` and resolve it at enqueue**

Use `America/Sao_Paulo`, 20:00–05:00 → 8 and 05:00–20:00 → 4. Preserve all partition record, byte and result limits. Do not modify stored job plans.

- [ ] **Step 4: Regenerate and validate API artifacts**

Run PHP lint, JSON parse checks, and the catalog assertion.

### Task 3: Private deployment and MED validation

**Files:**
- Deploy private worker only to its existing gateway location.
- Deploy compiled MED configuration only through the Sursum/MED publishing procedure.

**Interfaces:**
- Consumes: the private cron/local worker and saved-query policy.
- Produces: new jobs whose plans report `maxWorkers: 4` or `8` and never exceed their captured active-lease ceiling.

- [ ] **Step 1: Publish with backup and scope guards**

Validate PHP before atomically replacing the private worker; publish the saved-query JSON only to `/mnt/datasul/ERP/sursum` and refresh only MED.

- [ ] **Step 2: Run new short external async exports at controlled schedule boundaries**

Issue a least-privilege temporary consumer token, enqueue `movimentacoes-estoque` with `paginate:false`, and verify plan metadata has the expected snapshot for each boundary.

- [ ] **Step 3: Verify runtime and artifact completion**

Observe no more than the captured four/eight running partitions, wait for completed status, download gzip result, and remove the temporary consumer.

- [ ] **Step 4: Verify existing five-year job snapshot remains at two workers**

Read its plan only; report it separately rather than mutating it.

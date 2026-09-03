# Runtime Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add closed runtime screen definition and endpoint execution support for the builder contract.

**Architecture:** Add a focused OOABL service that reads `sursum-conf/runtime-screens.json`, validates screen and endpoint ids, and delegates to existing query/program execution paths. Extend `DynamicQueryWebHandler.cls` only for route matching and service handoff.

**Tech Stack:** OpenEdge ABL/OOABL, Progress JSON ObjectModel, PASOE IWebHandler, PHP contract tests.

**Spec:** `docs/superpowers/specs/2026-09-03-runtime-screens-design.md`

## Global Constraints

- Do not expose free API URLs in production screen definitions.
- Do not implement generic database writes in this slice.
- Program endpoints must reference allowlisted `program-executor.json` codes, not paths.
- Progress sources changed in motor-progress must be compiled on `192.168.0.42`.

---

### Task 1: Runtime Catalog Contract

**Files:**
- Create: `sursum-conf/runtime-screens.json`
- Create: `tests/e2e/sursum_runtime_screens_contract_test.php`

**Interfaces:**
- Produces: `sursum-conf/runtime-screens.json` with `screens.{screenId}.definition` and `screens.{screenId}.endpoints`.

- [ ] **Step 1: Write the failing PHP contract test**

Create a PHP test that loads the catalog, asserts `cadastros.customer` exists, asserts the definition has no `url` keys, and asserts `read` is a `query` endpoint while `create/update/delete` are `program` endpoints.

- [ ] **Step 2: Run the test and verify it fails**

Run: `php tests/e2e/sursum_runtime_screens_contract_test.php`
Expected: fail because `sursum-conf/runtime-screens.json` does not exist.

- [ ] **Step 3: Add the initial catalog**

Create `cadastros.customer` with `pageType: "crud"`, closed API endpoint ids, a grid/form definition over `CustNum`, `Name`, `City`, `State`, and endpoint definitions for `read`, `get`, `create`, `update`, and `delete`.

- [ ] **Step 4: Run the test and verify it passes**

Run: `php tests/e2e/sursum_runtime_screens_contract_test.php`
Expected: pass.

### Task 2: Runtime Service and Routes

**Files:**
- Create: `sursum-api/sursum/RuntimeScreenService.cls`
- Modify: `sursum-api/rest/DynamicQueryWebHandler.cls`

**Interfaces:**
- Produces: `RuntimeScreenService:getScreenDefinition(screenId AS CHARACTER) AS JsonObject`
- Produces: `RuntimeScreenService:executeEndpoint(screenId AS CHARACTER, endpointId AS CHARACTER, body AS LONGCHAR) AS JsonObject`

- [ ] **Step 1: Add route handling**

Extend `DynamicQueryWebHandler.cls` for runtime GET and POST routes and delegate to `RuntimeScreenService`.

- [ ] **Step 2: Implement catalog loading and validation**

`RuntimeScreenService` loads `sursum-conf/runtime-screens.json`, rejects invalid ids, and returns standard runtime errors.

- [ ] **Step 3: Implement query endpoint execution**

For endpoint `type: "query"`, clone/use the configured `query` object, merge runtime paging/sort/filter payload into it, and execute through `DynamicMultiTableQueryService`.

- [ ] **Step 4: Implement program endpoint execution**

For endpoint `type: "program"`, validate the program code against `program-executor.json`, resolve the allowlisted path, and run the program with a request object containing screen, endpoint, and body.

### Task 3: Verification

**Files:**
- Modify only if needed: `temp/ValidateSursumCurrent.p`

**Interfaces:**
- Consumes: changed Progress sources from Task 2.

- [ ] **Step 1: Run local contract test**

Run: `php tests/e2e/sursum_runtime_screens_contract_test.php`
Expected: pass.

- [ ] **Step 2: Copy changed Progress sources to compiler host**

Copy changed `.cls` sources to `C:/opencode/motor-progress` on `192.168.0.42`.

- [ ] **Step 3: Run OpenEdge compile validation**

Run the standard `_progres.exe` validation command.
Expected: exit code 0 with empty stdout/stderr.

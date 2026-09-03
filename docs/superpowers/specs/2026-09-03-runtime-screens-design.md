# Runtime Screens Design

## Goal

Add a runtime layer to motor-progress so the frontend builder can load declarative screen definitions and execute closed endpoints by `screenId` and `endpointId`.

## Scope

This first slice adds the generic runtime contract and a working CRUD read example. It does not add generic writes to arbitrary database tables. Create, update, delete, and custom business behavior are routed to allowlisted Progress programs.

## HTTP Contract

The PASOE handler exposes:

- `GET /web/SursumDynamicQuery/runtime/screens/{screenId}`
- `POST /web/SursumDynamicQuery/runtime/screens/{screenId}/endpoints/{endpointId}`

The PHP middleware can map these to the public builder routes:

- `GET /api/runtime/screens/{screenId}`
- `POST /api/runtime/screens/{screenId}/endpoints/{endpointId}`

## Catalog

Runtime screens are configured in `sursum-conf/runtime-screens.json`.

Each `screens.{screenId}` entry has:

- `definition`: the declarative screen JSON returned to the frontend.
- `endpoints`: closed endpoint definitions keyed by endpoint id.

Endpoint types:

- `query`: executes the existing `DynamicMultiTableQueryService`.
- `program`: executes an allowlisted `.p` through `sursum-conf/program-executor.json`.

Program endpoints do not reference paths directly. They reference program codes already present in `program-executor.json`.

## Safety Rules

- `screenId`, `endpointId`, and program codes use the same safe identifier policy already used by saved queries: letters, numbers, `_`, `-`, and `.`.
- Runtime definitions expose only `endpointId` and method metadata, not free API URLs.
- Endpoint requests fail if the screen or endpoint is not configured.
- Runtime errors use the builder envelope: `{ "error": { "code", "message", "details" } }`.
- Writes are not generic in this slice; custom write behavior must go through allowlisted Progress programs.

## Initial Example

The catalog includes `cadastros.customer`, a CRUD screen backed by `DICTDB.Customer`.

Supported endpoints:

- `read`: query endpoint over `Customer`.
- `get`: query endpoint with a required `CustNum` parameter.
- `create`, `update`, `delete`: program endpoints using `echo-json` as placeholders for custom write programs.

## Verification

Verification must include:

- a local contract test for the catalog structure and route declarations;
- OpenEdge syntax/compile validation for changed `.cls` and `.p` files on the Windows compiler host;
- if PASOE is available, smoke requests for screen definition and the `read` endpoint.

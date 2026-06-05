---
name: sursum-openedge
description: Use when working in the D:\opencode\motor-progress Sursum OpenEdge/Progress project, especially to operate sports2000, PASOE sursumpasoedev, dynamic query API examples, async workers, ABL validation, or project-specific curl benchmarks.
metadata:
  short-description: Operate the Sursum OpenEdge/PASOE dynamic query project
---

# Sursum OpenEdge project operations

Use this skill for tasks in `D:\opencode\motor-progress` involving OpenEdge ABL, OOABL, PASOE, sports2000, dynamic query API, async queue, workers, curl examples, or local benchmarks.

## First checks

- Work from `D:\opencode\motor-progress`.
- Prefer project context files before broad exploration:
  - `.codex/context/project-state.md`
  - `.codex/context/openedge-pasoe-operations.md`
  - `.codex/context/api-contract-notes.md`
- Do not use `boConsDin.p` or `boMetaDados.p` in the runtime flow. They are reference only.
- Do not run validation, compile, PASOE start/stop, or benchmarks unless the user asks for it.

## Core environment

```text
OpenEdge bin: C:\Progress\OpenEdge\bin
Database:     D:\opencode\motor-progress\db\sports2000
PASOE name:   sursumpasoedev
PASOE HTTP:   http://localhost:8890
API base:     http://localhost:8890/web/SursumDynamicQuery
```

## Start PASOE

```powershell
& "C:\Progress\OpenEdge\bin\pasman.bat" start -I sursumpasoedev
```

## Stop PASOE

```powershell
& "C:\Progress\OpenEdge\bin\pasman.bat" stop -I sursumpasoedev
```

## Compile/validate ABL

If PASOE is connected with `-1`, stop PASOE first.

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB -p "D:\opencode\motor-progress\temp\ValidateSursumCurrent.p"
```

## Run API examples

Sequential 10k Customer:

```powershell
.\examples\curl-customer-10000.bat
```

Parallel by page:

```powershell
.\examples\curl-customer-10000-parallel.bat
```

Parallel by key range:

```powershell
.\examples\curl-customer-10000-keyrange.bat
```

Pipeline:

```powershell
.\examples\curl-customer-pipeline.bat
```

## API request naming

Use the currently implemented serializer names:

- `sources[].nome`
- `sources[].alias`
- `sources[].campos` as comma-separated string
- `select[].sourceAlias`
- `select[].field`
- `select[].outputAlias`
- `filters[].sourceAlias`
- `orderBy[].sourceAlias`

Avoid assuming that `sources[].name`, `fields[]`, `alias` in select, or `as` in select are accepted by the current implementation.

## Known page limit

Current API validation limit:

```text
pageSize <= 500
```

For 10.000 records, use 20 requests of 500 or key-range partitioning.

## Operational guidance

- For simple API validation, use sync with pageSize up to 500.
- For large exports, prefer async or key-range partitioning.
- For deep pages, avoid offset-style pagination when possible; use indexed key filters like `CustNum >= X and CustNum <= Y`.
- For PASOE worker validation, use `POST /web/SursumDynamicQuery/jobs/drain`.
- For troubleshooting, inspect `pasoe/sursum-pasoe-dev/logs`.

## More detail

Read these when needed:

- `.codex/context/project-state.md` for project history, files, benchmarks, examples and git state.
- `.codex/context/openedge-pasoe-operations.md` for exact commands and PASOE/banco operations.
- `.codex/context/api-contract-notes.md` for request JSON details and known serializer behavior.


# Contexto do projeto Sursum Dynamic Query

Este arquivo registra o estado operacional conhecido do projeto em `D:\opencode\motor-progress`.

## Objetivo do projeto

Construir um motor OOABL para consultas dinamicas em Progress/OpenEdge, exposto por API TOTVS REST/PASOE, com suporte a:

- consulta estruturada sem SQL/ABL livre;
- leitura `NO-LOCK`;
- uma ou mais tabelas com alias e join explicito;
- pipeline inicial de preparacao de consulta;
- execucao `sync`, `async` e `auto`;
- fila persistida em banco;
- workers em modo `PASOE` e `CLIENT`;
- resultado JSON em arquivo;
- contexto de execucao com dados de agente, PID, host, banco e modo.

## Decisoes tecnicas ja tomadas

- `boConsDin.p` e `boMetaDados.p` nao fazem parte do fluxo novo.
- Os `.p` antigos sao apenas referencia conceitual.
- O fluxo novo usa classes OOABL.
- O banco local de validacao e `sports2000`.
- O PASOE local de validacao e `sursumpasoedev`.
- A API WEB principal fica em `/web/SursumDynamicQuery`.
- O limite atual de `pageSize` validado pela API e `500`.
- Para retornar 10.000 registros via curl, o exemplo sequencial faz 20 chamadas de 500 registros.
- Para volumes maiores, particionamento por chave indexada e preferivel a paginacao profunda.

## Estrutura principal criada

- `sursum/`: classes OOABL do motor, validacao, plano, execucao, fila e contexto.
- `rest/`: recursos/facades REST e WEB handler.
- `workers/`: programas de entrada para worker PASOE/CLIENT e benchmarks.
- `db/`: schema/deltas da fila async e banco local `sports2000`.
- `conf/pasoe/`: parametros de configuracao do PASOE local.
- `pasoe/sursum-pasoe-dev/`: instancia PASOE local criada para validacao.
- `examples/`: exemplos curl, JSON, pipeline e respostas.
- `docs/`: documentacao detalhada de arquitetura, API, fila, PASOE, benchmarks e troubleshooting.
- `.codex/context/`: contexto operacional para agentes Codex.
- `.codex/skills/sursum-openedge/`: skill local para operar este projeto.

## Classes principais

- `DynamicQueryRequestModel.cls`: DTO da consulta estruturada.
- `DynamicQueryRequestSerializer.cls`: serializacao/deserializacao JSON.
- `DynamicQueryValidationService.cls`: validacao de tabelas, campos, filtros, aliases e limites.
- `DynamicQueryPlanBuilder.cls`: montagem do plano de execucao.
- `DynamicMultiTableQueryService.cls`: orquestracao de validacao, plano e execucao.
- `DynamicQueryAsyncService.cls`: enqueue, status, cancelamento e resultado.
- `DynamicQueryJobRepository.cls`: persistencia e auditoria de jobs.
- `DynamicQueryWorkerService.cls`: consumo da fila e execucao de jobs.
- `DynamicQueryWorkerOptions.cls`: opcoes do worker.
- `DynamicQueryResultWriter.cls`: escrita de resultado JSON.
- `PasoeExecutionContext.cls`: captura de contexto PASOE/CLIENT.

## Endpoints WEB validados

Base:

```text
http://localhost:8890/web/SursumDynamicQuery
```

Endpoints:

```text
POST /query
POST /jobs/drain
GET  /jobs/{jobId}
GET  /jobs/{jobId}/result
GET  /benchmarks/customer-count
```

## Jobs async validados anteriormente

CLIENT:

```text
JOB-20260604-075908-321907
status=completed
recordsReturned=25
resultPath=D:\opencode\motor-progress\output\jobs\20260604\JOB-20260604-075908-321907.json
```

PASOE APSV:

```text
JOB-20260604-077322-321907
status=completed
executionMode=PASOE
lockedByMode=PASOE
lockedByWorker=pasoe-apsv-worker
recordsReturned=25
```

PASOE WEB:

```text
JOB-20260604-079881-321907
status=completed
executionMode=PASOE
lockedByMode=PASOE
lockedByWorker=pasoe-web-drain
recordsReturned=25
hasMore=true
resultPath=D:\opencode\motor-progress\output\jobs\20260604\JOB-20260604-079881-321907.json
```

## Benchmarks conhecidos

Carga adicionada:

```text
Customer total aproximado validado: 2.001.117
Registros inseridos por seed: 2.000.000
Primeiro novo CustNum: 2107
Ultimo novo CustNum: 2002106
Tempo de seed: 1.676.093 ms
```

Paginacao HTTP sync com `pageSize=100`, sem count total:

```text
page 1:     299 ms
page 10:     38 ms
page 100:    56 ms
page 1000:  237 ms
page 5000: 1000 ms
page 10000: 1961 ms
page 20000: 3914 ms
page 20012: 3956 ms, 18 records, hasMore=false
```

Count CLIENT/batch:

```text
FOR EACH NO-LOCK: 2.261 ms
PRESELECT:        2.108 ms
NUM-RESULTS:          0 ms
```

Count PASOE HTTP WEB:

```text
FOR EACH:     2.446 ms
PRESELECT:    2.304 ms
NUM-RESULTS:      0 ms
HTTP total:   5.070 ms
```

Count PASOE APSV / ON SERVER:

```text
FOR EACH:        2.537 ms
PRESELECT:       2.338 ms
NUM-RESULTS:         0 ms
total ON SERVER: 4.890 ms
```

## Exemplos curl criados

Sequencial 10.000 Customer:

```text
examples\curl-customer-10000.bat
output: examples\responses\customer-10000.json
tempo observado: aproximadamente 3.2 s
```

Paralelo por pagina:

```text
examples\curl-customer-10000-parallel.bat
examples\curl-customer-10000-parallel.ps1
output: examples\responses\customer-10000-parallel.json
MAX_PARALLEL=2
tempo observado: 5950 ms
```

Particionamento por chave:

```text
examples\curl-customer-10000-keyrange.bat
examples\curl-customer-10000-keyrange.ps1
output: examples\responses\customer-10000-keyrange.json
partitionField=CustNum
ranges=20
rangeSize=500
MAX_PARALLEL=4
tempo observado: 3445 ms
```

Pipeline:

```text
examples\customer-pipeline-example.md
examples\customer-pipeline-request.json
examples\curl-customer-pipeline.bat
```

Customer + Order com alias `custOrder`:

```text
examples\customer-custorder-example.md
examples\customer-custorder-response.json
```

## Git

Repositorio iniciado localmente e enviado para:

```text
https://github.com/sursum-git/motor-progress.git
branch: master
```

Commits conhecidos:

```text
30746a3 Initial dynamic query engine
4b9c3c4 Add project documentation
```


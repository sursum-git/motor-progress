# Contexto Async e Pipeline

## Async

O modo `async` usa fila persistida no banco.

Tabelas planejadas/criadas:

```text
SursumQueryJob
SursumQueryJobEvent
```

Arquivos de schema relacionados:

```text
db/sursum_async_queue.df
db/sursum_async_queue_jobstatus_delta.df
db/sursum_async_queue_json_fields_delta.df
```

Classes principais:

```text
sursum-api/sursum/DynamicQueryJobRepository.cls
sursum-api/sursum/DynamicQueryAsyncService.cls
sursum-api/sursum/DynamicQueryRequestSerializer.cls
sursum-api/sursum/DynamicQueryResultWriter.cls
sursum-api/sursum/DynamicQueryWorkerService.cls
sursum-api/sursum/DynamicQueryWorkerOptions.cls
```

## Modos de worker

```text
PASOE
CLIENT
```

Entradas:

```text
sursum-api/workers/RunDynamicQueryPasoeWorker.p
sursum-api/workers/RunDynamicQueryClientWorker.p
```

## Pipeline

Steps reconhecidos:

```text
source
join
select
filter
sort
limit
map
distinct
group
aggregate
output
```

## Pipeline atual

O pipeline atualmente combina:

- preparo da consulta;
- transformacoes pos-query basicas.

Operadores pos-query importantes:

- `map`: reprojeta/renomeia campos.
- `distinct`: remove duplicados.
- `group`: agrupa por campos.
- `aggregate`: calcula count, sum, min, max, avg.

## Resultado async

Resultados devem ser gravados em arquivo:

```text
output/jobs/YYYYMMDD/<jobId>.json
```

A tabela da fila guarda o caminho e metadados do resultado, nao o conteudo inteiro.

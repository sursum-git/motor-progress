# Contexto Async, Pipeline e Filas

Atualizado em 2026-06-18.

## Async de consultas

O motor de consulta possui suporte a execucao `sync`, `async` e `auto`.

Classes principais:

```text
sursum-api/sursum/DynamicQueryJobRepository.cls
sursum-api/sursum/DynamicQueryAsyncService.cls
sursum-api/sursum/DynamicQueryRequestSerializer.cls
sursum-api/sursum/DynamicQueryResultWriter.cls
sursum-api/sursum/DynamicQueryWorkerService.cls
sursum-api/sursum/DynamicQueryWorkerOptions.cls
```

Entradas:

```text
sursum-api/workers/RunDynamicQueryPasoeWorker.p
sursum-api/workers/RunDynamicQueryClientWorker.p
```

Endpoints:

```text
POST /jobs/drain
GET  /jobs/:jobId
GET  /jobs/:jobId/result
```

Resultados async sao gravados em arquivo:

```text
output/jobs/YYYYMMDD/<jobId>.json
```

## Pipeline de consulta

Steps reconhecidos no desenho do motor:

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

O pipeline combina:

- preparacao da consulta;
- transformacoes pos-query basicas;
- serializacao do resultado.

Operadores pos-query relevantes:

- `map`: reprojeta/renomeia campos.
- `distinct`: remove duplicados.
- `group`: agrupa por campos.
- `aggregate`: calcula count, sum, min, max, avg.

## Fila de atualizacao de metadados da UI

Separada da fila async de consultas. A manutencao de metadados usa SQLite pelo PHP:

```text
web/metadata-store.php
SQLite: web/sursum-conf/sursum.sqlite
```

Tabelas:

```text
metadata_sync_jobs
metadata_sync_items
```

Campos importantes:

- `include_relations`: atualiza joins OF.
- `include_view_as`: atualiza view-as.
- `existing_metadata_behavior`: `skip` ou `update`.
- `status`: `pending`, `running`, `done`, `error`, `cancelled`, `done_with_errors`.
- contadores de tabelas processadas, com erro e canceladas.

Tela:

```text
web/metadata-maintenance.html
```

Comportamento atual:

- Aba `Atualizacao em lote` cria uma fila por banco.
- Banco `Selecionar` nao cria fila; o usuario precisa escolher um banco especifico.
- Todos os switches principais comecam marcados, exceto `Apenas tabela informada`.
- Campo `Execucoes simultaneas` e numerico e inicia em `1`.
- O JavaScript respeita o limite de execucoes simultaneas ao processar itens pendentes.
- O comportamento para metadado existente pode ser `Desconsiderar` (`skip`) ou `Atualizar` (`update`).
- Botao `Cancelar pendentes` cancela todos os itens `pending` da fila atual.
- Cada item `pending` tambem tem botao de cancelar.
- Cada item `error` tem botao de reprocessar.
- Botao `Reprocessar tudo` reenfileira todos os itens com erro.
- O grid possui filtros visuais para mostrar pendentes e erros.

## Processamento de cada tabela na fila

Para cada tabela:

1. Marca item como `running`.
2. Se `include_relations` estiver ativo, chama:

```text
GET /metadata/relations/of?table=:table&database=:database
```

3. Grava joins retornados em `relation-store.php`.
4. Se `include_view_as` estiver ativo, busca campos da tabela.
5. Envia linhas com view-as para:

```text
POST /metadata/view-as/resolve
```

6. Grava view-as resolvido em `metadata-store.php`.
7. Marca item como `done` ou `error`, guardando mensagem detalhada.

## Regra de preservacao de dados manuais

- Join manual (`source=manual`) nao deve ser removido pelo processamento automatico OF.
- View-as manual e CSV sao globais por `tabela + campo`.
- Quando `existing_metadata_behavior=skip`, metadados ja salvos nao sao reprocessados.
- Quando `existing_metadata_behavior=update`, o processamento tenta atualizar os metadados existentes.

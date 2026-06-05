# Arquitetura

## Visao geral

O motor e uma camada OOABL que recebe uma consulta estruturada em JSON, valida todos os elementos contra metadados do banco e gera uma query ABL dinamica segura.

O fluxo principal e:

```text
JSON request
  -> DynamicQueryRequestSerializer
  -> DynamicQueryRequestModel
  -> DynamicQueryValidationService
  -> DynamicQueryPlanBuilder
  -> DynamicMultiTableQueryService
  -> resultado JSON ou fila async
```

## Componentes principais

| Classe/arquivo | Responsabilidade |
|---|---|
| `DynamicQueryRequestModel.cls` | DTO da consulta dinamica |
| `DynamicQueryRequestSerializer.cls` | Serializacao e desserializacao JSON |
| `DynamicMetadataService.cls` | Leitura de metadados de tabelas/campos |
| `DynamicQueryValidationService.cls` | Validacao de schema, campos, operadores, aliases e politicas |
| `DynamicQueryPlanBuilder.cls` | Montagem do plano executavel |
| `DynamicMultiTableQueryService.cls` | Orquestracao de validacao, plano, execucao sync e async |
| `DynamicQueryService.cls` | Execucao dinamica da consulta |
| `DynamicQueryAsyncService.cls` | Enfileiramento, status e cancelamento |
| `DynamicQueryJobRepository.cls` | Persistencia da fila e eventos |
| `DynamicQueryWorkerService.cls` | Processamento dos jobs pendentes |
| `DynamicQueryResultWriter.cls` | Escrita atomica do resultado JSON |
| `PasoeExecutionContext.cls` | Captura de contexto de execucao/auditoria |

## Fluxo sync

```text
POST /query
  execution = sync
  -> valida request
  -> monta plano
  -> executa query imediatamente
  -> retorna JSON com data
```

Resposta tipica:

```json
{
  "success": true,
  "execution": "sync",
  "status": "completed",
  "page": 1,
  "pageSize": 25,
  "recordsReturned": 25,
  "hasMore": true,
  "data": []
}
```

## Fluxo async

```text
POST /query
  execution = async
  -> valida request
  -> monta plano
  -> grava SursumQueryJob
  -> retorna jobId

POST /jobs/drain
  -> worker reclama jobs queued
  -> executa executeSyncNow
  -> grava arquivo JSON
  -> marca completed ou failed
```

## Pipeline inicial

O pipeline atual e de preparo de consulta. Ele foi criado para permitir evolucao futura sem quebrar o contrato.

Steps suportados no contrato inicial:

| Step | Finalidade |
|---|---|
| `source` | Declara origem/tabela |
| `join` | Declara relacionamento explicito |
| `select` | Define campos de saida |
| `filter` | Define condicoes estruturadas |
| `sort` | Define ordenacao |
| `limit` | Define paginacao/limite |
| `output` | Define forma de saida |

Nao ha suporte atual a `map`, `group`, `aggregate` ou transformacoes complexas.

## Seguranca

Regras de seguranca:

- tabelas e campos devem existir;
- campos bloqueados/sensiveis devem ser rejeitados;
- aliases sao obrigatorios em consultas multi-tabela;
- operadores devem ser suportados pelo tipo do campo;
- qualquer expressao livre deve ser rejeitada;
- toda consulta deve usar `NO-LOCK`;
- joins devem ser explicitos, sem inferencia automatica.

## Decisao sobre BOs legadas

`boConsDin.p` e `boMetaDados.p` ficam em `sursum/esbo` apenas como referencia.

O fluxo novo nao chama esses programas.

Motivo:

- `boConsDin.p` foi desenhado para uma tabela;
- a nova camada precisa suportar multi-tabela, fila e pipeline;
- OOABL facilita isolamento de validacao, plano, execucao e auditoria.


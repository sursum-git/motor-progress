# Fila async e workers

## Objetivo

O modo `async` evita que consultas potencialmente longas bloqueiem a chamada HTTP inicial.

No `async`, a API valida o request, gera o plano, grava um job em tabela e retorna `jobId`. O processamento fica para um worker `PASOE` ou `CLIENT`.

## Tabelas

Schema base:

| Arquivo | Finalidade |
|---|---|
| `db/sursum_async_queue.df` | Tabelas base da fila |
| `db/sursum_async_queue_jobstatus_delta.df` | Ajuste do campo de status |
| `db/sursum_async_queue_json_fields_delta.df` | Ajuste de campos JSON para validacao local |

Tabelas:

| Tabela | Finalidade |
|---|---|
| `SursumQueryJob` | Estado principal do job |
| `SursumQueryJobEvent` | Historico/auditoria de transicoes |

## Estados

| Estado | Descricao |
|---|---|
| `queued` | Job criado e aguardando worker |
| `running` | Job reclamado por um worker |
| `completed` | Resultado gerado com sucesso |
| `failed` | Erro definitivo |
| `cancelled` | Cancelado antes da execucao |

## Campos principais do job

| Campo | Descricao |
|---|---|
| `jobId` | Identificador unico |
| `jobStatus` | Estado atual |
| `executionMode` | `PASOE` ou `CLIENT` |
| `requestJson` | Request original normalizado |
| `planJson` | Plano validado/gerado |
| `requestContextJson` | Contexto de quem enfileirou |
| `workerContextJson` | Contexto de quem processou |
| `createdAt` | Criacao |
| `startedAt` | Inicio do processamento |
| `finishedAt` | Fim do processamento |
| `lockedByWorker` | Nome do worker |
| `lockedByMode` | Modo do worker |
| `attempts` | Tentativas |
| `maxAttempts` | Maximo de tentativas |
| `resultPath` | Caminho do JSON final |
| `recordsReturned` | Registros no resultado |
| `hasMore` | Indica se ha mais registros |
| `errorCode` | Codigo de erro |
| `errorMessage` | Mensagem resumida |
| `errorDetail` | Detalhe tecnico |

## Enqueue

Request:

```json
{
  "execution": "async",
  "page": 1,
  "pageSize": 25,
  "defaultBanco": "DICTDB",
  "sources": [
    { "nome": "Customer", "alias": "", "banco": "DICTDB", "campos": "CustNum,Name,City,State" }
  ],
  "joins": [],
  "select": [],
  "filters": [],
  "orderBy": [],
  "pipeline": []
}
```

Resposta:

```json
{
  "success": true,
  "execution": "async",
  "status": "queued",
  "jobId": "JOB-20260604-079881-321907"
}
```

## Worker PASOE

Endpoint:

```http
POST /web/SursumDynamicQuery/jobs/drain
```

Esse endpoint chama `DynamicQueryWorkerService` dentro do PASOE.

Configuracao padrao atual:

| Opcao | Valor |
|---|---|
| `executionMode` | `PASOE` |
| `workerName` | `pasoe-web-drain` |
| `batchSize` | `10` |
| `outputDirectory` | `D:\opencode\motor-progress\output\jobs` |

## Worker CLIENT

Programa:

```text
workers/RunDynamicQueryClientWorker.p
```

Exemplo de execucao:

```powershell
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b `
  -db 'D:\opencode\motor-progress\db\sports2000' -1 -ld DICTDB `
  -p 'workers\RunDynamicQueryClientWorker.p'
```

Use CLIENT para batch local ou ambientes onde o worker roda fora do PASOE.

## Claim transacional

O worker deve reclamar jobs com lock exclusivo e `NO-WAIT`.

Objetivo:

- permitir multiplos workers;
- impedir processamento duplicado;
- marcar `running` antes de executar;
- registrar contexto do worker.

## Resultado em arquivo

Diretorio:

```text
output/jobs/YYYYMMDD/<jobId>.json
```

Regra:

- escrever primeiro em arquivo temporario;
- renomear para caminho final;
- gravar `resultPath` no job;
- nao persistir o JSON completo na tabela principal.

## Retry e falha

Padrao:

| Campo | Valor inicial |
|---|---|
| `maxAttempts` | `3` |
| `attempts` | `0` |

Fluxo:

```text
queued
  -> running
  -> completed
```

ou:

```text
queued
  -> running
  -> failed
```

## Cancelamento

Somente jobs `queued` devem ser cancelaveis.

Jobs `running` exigem politica futura de interrupcao/timeout/heartbeat.


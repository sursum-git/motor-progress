# Contrato da API

## Endpoint principal

```http
POST /web/SursumDynamicQuery/query
```

Aceita `execution = sync | async | auto`.

## Request minimo para uma tabela

```json
{
  "execution": "sync",
  "page": 1,
  "pageSize": 25,
  "defaultBanco": "DICTDB",
  "sources": [
    {
      "nome": "Customer",
      "alias": "",
      "banco": "DICTDB",
      "campos": "CustNum,Name,City,State"
    }
  ],
  "joins": [],
  "select": [],
  "filters": [],
  "orderBy": [],
  "pipeline": []
}
```

## Campos principais

| Campo | Tipo | Obrigatorio | Descricao |
|---|---|---|---|
| `execution` | string | nao | `sync`, `async` ou `auto` |
| `page` | integer | nao | Numero da pagina, base 1 |
| `pageSize` | integer | nao | Quantidade de registros por pagina |
| `defaultBanco` | string | nao | Logical name padrao do banco |
| `sources` | array | sim | Tabelas usadas na consulta |
| `joins` | array | nao | Joins explicitos |
| `select` | array | nao | Campos selecionados no formato estruturado |
| `filters` | array | nao | Filtros estruturados |
| `orderBy` | array | nao | Ordenacao |
| `pipeline` | array | nao | Pipeline inicial de preparo |

## `sources`

Cada source representa uma tabela.

```json
{
  "nome": "Customer",
  "alias": "c",
  "banco": "DICTDB",
  "campos": "CustNum,Name,City"
}
```

Regras:

- `nome` deve existir no dicionario;
- `banco` pode ser omitido se `defaultBanco` estiver definido;
- `alias` e obrigatorio quando houver mais de uma tabela;
- `campos` pode ser usado como selecao rapida para uma tabela;
- campos ambiguos em multi-tabela devem ser rejeitados.

## `joins`

Exemplo conceitual:

```json
{
  "type": "INNER",
  "leftAlias": "c",
  "leftField": "CustNum",
  "rightAlias": "o",
  "rightField": "CustNum"
}
```

Regras:

- somente `INNER` e `LEFT` no ciclo atual;
- joins devem ser explicitos;
- nao ha inferencia automatica de relacionamento;
- campos do join devem existir;
- aliases devem existir em `sources`.

## `filters`

Exemplo:

```json
{
  "alias": "c",
  "field": "State",
  "operator": "eq",
  "value": "MA"
}
```

Operadores tipicos:

| Operador | Descricao |
|---|---|
| `eq` | Igual |
| `ne` | Diferente |
| `gt` | Maior que |
| `ge` | Maior ou igual |
| `lt` | Menor que |
| `le` | Menor ou igual |
| `contains` | Contem, apenas para campos texto |
| `startsWith` | Inicia com, apenas para campos texto |

Regras:

- operador deve ser valido para o tipo do campo;
- filtro com campo sensivel deve ser rejeitado;
- valor deve ser convertido/validado antes da query;
- nao aceitar fragments de `WHERE` livre.

## `orderBy`

Exemplo:

```json
{
  "alias": "c",
  "field": "CustNum",
  "direction": "ASC"
}
```

Regras:

- `direction` deve ser `ASC` ou `DESC`;
- campo deve existir;
- em multi-tabela, alias e obrigatorio.

## Resposta sync

```json
{
  "success": true,
  "execution": "sync",
  "status": "completed",
  "page": 1,
  "pageSize": 25,
  "recordsReturned": 25,
  "hasMore": true,
  "data": [
    {
      "CustNum": "1",
      "Name": "Lift Tours",
      "City": "Burlington",
      "State": "MA"
    }
  ]
}
```

## Resposta async

```json
{
  "success": true,
  "execution": "async",
  "status": "queued",
  "jobId": "JOB-20260604-079881-321907"
}
```

## Consultar status

```http
GET /web/SursumDynamicQuery/jobs/{jobId}
```

Resposta:

```json
{
  "success": true,
  "jobId": "JOB-20260604-079881-321907",
  "status": "completed",
  "executionMode": "PASOE",
  "lockedByMode": "PASOE",
  "lockedByWorker": "pasoe-web-drain",
  "recordsReturned": 25,
  "hasMore": true,
  "resultAvailable": true,
  "resultPath": "D:\\opencode\\motor-progress\\output\\jobs\\20260604\\JOB-20260604-079881-321907.json"
}
```

## Baixar resultado

```http
GET /web/SursumDynamicQuery/jobs/{jobId}/result
```

Retorna o JSON gravado em arquivo pelo worker.

## Acionar worker PASOE

```http
POST /web/SursumDynamicQuery/jobs/drain
```

Resposta:

```json
{
  "success": true,
  "workerMode": "PASOE",
  "workerName": "pasoe-web-drain",
  "processed": 1,
  "completed": 1,
  "failed": 0
}
```

## Erros padronizados

Formato:

```json
{
  "success": false,
  "error": {
    "code": "FIELD_NOT_FOUND",
    "message": "Campo nao encontrado",
    "details": "Customer.UnknownField"
  }
}
```

Codigos comuns:

| Codigo | Causa |
|---|---|
| `EMPTY_BODY` | Body JSON ausente |
| `TABLE_NOT_FOUND` | Tabela inexistente |
| `FIELD_NOT_FOUND` | Campo inexistente |
| `AMBIGUOUS_FIELD` | Campo sem alias em multi-tabela |
| `BLOCKED_FIELD` | Campo bloqueado/sensivel |
| `INVALID_OPERATOR` | Operador nao suportado |
| `JOIN_REQUIRED` | Consulta multi-tabela sem join seguro |
| `JOB_ID_REQUIRED` | Status/resultado sem jobId |
| `NOT_FOUND` | Endpoint nao encontrado |


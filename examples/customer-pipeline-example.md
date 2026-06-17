# Exemplo: Customer usando pipeline

Este exemplo usa o contrato `pipeline` para preparar uma consulta sobre a tabela `Customer`.

O pipeline atual e de preparacao de consulta. Ele aceita etapas como `source`, `select`, `filter`, `sort`, `limit` e `output`. Nao executa ainda transformacoes analiticas como `group`, `aggregate`, `distinct` ou `map`.

## Request sync

Endpoint:

```http
POST /web/SursumDynamicQuery/query
Content-Type: application/json
```

Payload:

```json
{
  "execution": "sync",
  "pipeline": [
    {
      "type": "source",
      "payload": "{\"nome\":\"Customer\",\"alias\":\"customer\",\"campos\":\"CustNum,Name,City,State\"}"
    },
    {
      "type": "select",
      "payload": "{\"fields\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"outputAlias\":\"codigo\"},{\"sourceAlias\":\"customer\",\"field\":\"Name\",\"outputAlias\":\"nome\"},{\"sourceAlias\":\"customer\",\"field\":\"City\",\"outputAlias\":\"cidade\"},{\"sourceAlias\":\"customer\",\"field\":\"State\",\"outputAlias\":\"estado\"}]}"
    },
    {
      "type": "filter",
      "payload": "{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"operator\":\">=\",\"value\":\"1\"}"
    },
    {
      "type": "sort",
      "payload": "{\"fields\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"direction\":\"ASC\"}]}"
    },
    {
      "type": "limit",
      "payload": "{\"page\":1,\"pageSize\":500}"
    },
    {
      "type": "output",
      "payload": "{\"format\":\"json\"}"
    }
  ]
}
```

## Response sync esperada

```json
{
  "success": true,
  "execution": "sync",
  "page": 1,
  "pageSize": 500,
  "recordsReturned": 500,
  "hasMore": true,
  "data": [
    {
      "codigo": 1,
      "nome": "Lift Tours",
      "cidade": "Boston",
      "estado": "MA"
    }
  ]
}
```

Os valores de dados sao ilustrativos. O resultado real depende do banco `sports2000` local.

## Request async

Para enfileirar o mesmo pipeline, altere apenas `execution`:

```json
{
  "execution": "async",
  "pipeline": [
    {
      "type": "source",
      "payload": "{\"nome\":\"Customer\",\"alias\":\"customer\",\"campos\":\"CustNum,Name,City,State\"}"
    },
    {
      "type": "select",
      "payload": "{\"fields\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"outputAlias\":\"codigo\"},{\"sourceAlias\":\"customer\",\"field\":\"Name\",\"outputAlias\":\"nome\"},{\"sourceAlias\":\"customer\",\"field\":\"City\",\"outputAlias\":\"cidade\"},{\"sourceAlias\":\"customer\",\"field\":\"State\",\"outputAlias\":\"estado\"}]}"
    },
    {
      "type": "filter",
      "payload": "{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"operator\":\">=\",\"value\":\"1\"}"
    },
    {
      "type": "sort",
      "payload": "{\"fields\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"direction\":\"ASC\"}]}"
    },
    {
      "type": "limit",
      "payload": "{\"page\":1,\"pageSize\":500}"
    },
    {
      "type": "output",
      "payload": "{\"format\":\"json\"}"
    }
  ]
}
```

Resposta esperada:

```json
{
  "success": true,
  "execution": "async",
  "status": "queued",
  "jobId": "JOB-20260605-123456-000001"
}
```

## Observacoes

- `payload` e uma string JSON porque o modelo atual armazena cada etapa como texto persistivel.
- O parser do pipeline deve transformar essas etapas nos mesmos objetos usados por `sources`, `select`, `filters`, `orderBy`, `page` e `pageSize`.
- Alias continua obrigatorio quando houver mais de uma fonte.
- Filtros continuam estruturados; nao existe `WHERE` livre.
- A consulta gerada deve continuar usando `NO-LOCK`.

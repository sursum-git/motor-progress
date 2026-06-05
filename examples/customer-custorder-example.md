# Exemplo: Customer + CustOrder

Este exemplo consulta dados de clientes e pedidos em uma unica chamada multi-tabela.

No banco `sports2000`, a tabela fisica de pedidos normalmente e `Order`. Como `Order` tambem e uma palavra reservada em varios contextos, o exemplo usa alias `custOrder` para deixar o contrato da API claro e evitar ambiguidade.

## Request

Endpoint:

```http
POST /web/SursumDynamicQuery/query
Content-Type: application/json
```

Payload:

```json
{
  "execution": "sync",
  "sources": [
    {
      "name": "Customer",
      "alias": "customer",
      "fields": [
        "CustNum",
        "Name",
        "City",
        "State"
      ]
    },
    {
      "name": "Order",
      "alias": "custOrder",
      "fields": [
        "OrderNum",
        "CustNum",
        "OrderDate",
        "PromiseDate"
      ]
    }
  ],
  "joins": [
    {
      "type": "INNER",
      "leftAlias": "customer",
      "leftField": "CustNum",
      "rightAlias": "custOrder",
      "rightField": "CustNum"
    }
  ],
  "select": [
    {
      "alias": "customer",
      "field": "CustNum",
      "as": "customerCustNum"
    },
    {
      "alias": "customer",
      "field": "Name",
      "as": "customerName"
    },
    {
      "alias": "customer",
      "field": "City",
      "as": "customerCity"
    },
    {
      "alias": "customer",
      "field": "State",
      "as": "customerState"
    },
    {
      "alias": "custOrder",
      "field": "OrderNum",
      "as": "orderNum"
    },
    {
      "alias": "custOrder",
      "field": "OrderDate",
      "as": "orderDate"
    },
    {
      "alias": "custOrder",
      "field": "PromiseDate",
      "as": "promiseDate"
    }
  ],
  "filters": [
    {
      "alias": "customer",
      "field": "CustNum",
      "operator": ">=",
      "value": 1
    }
  ],
  "orderBy": [
    {
      "alias": "customer",
      "field": "CustNum",
      "direction": "ASC"
    },
    {
      "alias": "custOrder",
      "field": "OrderNum",
      "direction": "ASC"
    }
  ],
  "page": 1,
  "pageSize": 25
}
```

## Response sync esperada

Formato esperado em caso de sucesso:

```json
{
  "success": true,
  "execution": "sync",
  "page": 1,
  "pageSize": 25,
  "recordsReturned": 25,
  "hasMore": true,
  "data": [
    {
      "customerCustNum": 1,
      "customerName": "Lift Tours",
      "customerCity": "Boston",
      "customerState": "MA",
      "orderNum": 1,
      "orderDate": "1998-01-20",
      "promiseDate": "1998-02-03"
    }
  ]
}
```

Os valores acima sao ilustrativos. O retorno real depende dos dados carregados no `sports2000`.

## Versao async

Para enfileirar a mesma consulta, altere somente o campo `execution`:

```json
{
  "execution": "async"
}
```

A API retorna um `jobId` e o worker grava o resultado em arquivo JSON:

```json
{
  "success": true,
  "execution": "async",
  "status": "queued",
  "jobId": "JOB-20260604-123456-000001"
}
```

Depois consulte:

```http
GET /web/SursumDynamicQuery/jobs/JOB-20260604-123456-000001
GET /web/SursumDynamicQuery/jobs/JOB-20260604-123456-000001/result
```

## Pipeline equivalente

O mesmo request tambem pode ser representado como pipeline de preparacao:

```json
{
  "execution": "sync",
  "pipeline": [
    {
      "step": "source",
      "name": "Customer",
      "alias": "customer",
      "fields": ["CustNum", "Name", "City", "State"]
    },
    {
      "step": "source",
      "name": "Order",
      "alias": "custOrder",
      "fields": ["OrderNum", "CustNum", "OrderDate", "PromiseDate"]
    },
    {
      "step": "join",
      "type": "INNER",
      "leftAlias": "customer",
      "leftField": "CustNum",
      "rightAlias": "custOrder",
      "rightField": "CustNum"
    },
    {
      "step": "select",
      "fields": [
        { "alias": "customer", "field": "CustNum", "as": "customerCustNum" },
        { "alias": "customer", "field": "Name", "as": "customerName" },
        { "alias": "customer", "field": "City", "as": "customerCity" },
        { "alias": "customer", "field": "State", "as": "customerState" },
        { "alias": "custOrder", "field": "OrderNum", "as": "orderNum" },
        { "alias": "custOrder", "field": "OrderDate", "as": "orderDate" },
        { "alias": "custOrder", "field": "PromiseDate", "as": "promiseDate" }
      ]
    },
    {
      "step": "sort",
      "fields": [
        { "alias": "customer", "field": "CustNum", "direction": "ASC" },
        { "alias": "custOrder", "field": "OrderNum", "direction": "ASC" }
      ]
    },
    {
      "step": "limit",
      "page": 1,
      "pageSize": 25
    },
    {
      "step": "output",
      "format": "json"
    }
  ]
}
```

## Regras importantes

- Use alias obrigatoriamente quando houver mais de uma tabela.
- Qualifique todos os campos em `select`, `filters` e `orderBy`.
- Nao envie `WHERE` livre; use somente filtros estruturados.
- O join entre `Customer.CustNum` e `Order.CustNum` deve ser explicito.
- A consulta deve continuar gerando leitura `NO-LOCK`.
- Para volumes grandes, prefira `execution = "async"` ou `execution = "auto"`.

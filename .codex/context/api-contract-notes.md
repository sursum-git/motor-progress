# Notas de contrato da API implementada

Este arquivo registra detalhes praticos do contrato JSON atualmente aceito pelo serializer.

## Endpoint principal

```text
POST http://localhost:8890/web/SursumDynamicQuery/query
```

## Nomes reais aceitos pelo serializer

Em `sources[]`:

```json
{
  "nome": "Customer",
  "alias": "customer",
  "campos": "CustNum,Name"
}
```

Tambem existe fallback para:

```json
{
  "tableName": "Customer"
}
```

Nao usar `sources[].name` no estado atual, pois gerou `INVALID_TABLE` com `table=`.

Em `select[]`:

```json
{
  "sourceAlias": "customer",
  "field": "CustNum",
  "outputAlias": "codigo"
}
```

Nao usar `alias` e `as` no estado atual para o request real da API.

Em `filters[]`:

```json
{
  "sourceAlias": "customer",
  "field": "CustNum",
  "operator": ">=",
  "value": "1"
}
```

Em `orderBy[]`:

```json
{
  "sourceAlias": "customer",
  "field": "CustNum",
  "direction": "ASC"
}
```

## Limite de pagina

O limite atual validado e:

```text
max pageSize = 500
```

Uma request com `pageSize=10000` retorna:

```json
{
  "success": false,
  "error": {
    "code": "PAGE_SIZE_EXCEEDED",
    "message": "pageSize fora do limite.",
    "details": "pageSize=10000, max=500"
  }
}
```

## Exemplo minimo Customer

```json
{
  "execution": "sync",
  "sources": [
    {
      "nome": "Customer",
      "alias": "customer",
      "campos": "CustNum,Name"
    }
  ],
  "select": [
    {
      "sourceAlias": "customer",
      "field": "CustNum",
      "outputAlias": "codigo"
    },
    {
      "sourceAlias": "customer",
      "field": "Name",
      "outputAlias": "nome"
    }
  ],
  "orderBy": [
    {
      "sourceAlias": "customer",
      "field": "CustNum",
      "direction": "ASC"
    }
  ],
  "page": 1,
  "pageSize": 500
}
```

## Pipeline

O modelo atual armazena cada step como:

```json
{
  "type": "source",
  "payload": "{\"nome\":\"Customer\",\"alias\":\"customer\",\"campos\":\"CustNum,Name\"}"
}
```

Observacoes:

- `payload` e uma string JSON persistivel.
- O parser deve transformar steps nos mesmos objetos de `sources`, `select`, `filters`, `orderBy`, `page` e `pageSize`.
- O pipeline atual e preparatorio.
- Ainda nao ha operadores analiticos complexos como `group`, `aggregate`, `distinct` ou `map`.


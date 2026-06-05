# Contrato JSON da consulta dinâmica multi-tabela (fase 1)

## Estrutura base

```json
{
  "sources": [
    {
      "tableName": "emitente",
      "tableAlias": "e",
      "tableBanco": "",
      "requestedFields": "cod_emitente,nome_emit,cidade"
    }
  ],
  "joins": [
    {
      "joinType": "INNER",
      "leftSource": "e",
      "leftField": "cod_emitente",
      "rightSource": "c",
      "rightField": "cod_emitente"
    }
  ],
  "select": [
    { "sourceAlias": "e", "fieldName": "cod_emitente", "outputAlias": "codigo" },
    { "sourceAlias": "c", "fieldName": "cidade" }
  ],
  "filters": [
    {
      "sourceAlias": "e",
      "fieldName": "nome_emit",
      "operator": "begins",
      "valueChar": "JOAO"
    }
  ],
  "orderBy": [
    { "sourceAlias": "e", "fieldName": "nome_emit", "direction": "asc" }
  ],
  "page": 1,
  "pageSize": 50,
  "execution": "auto",
  "pipeline": [
    { "stepType": "source" },
    { "stepType": "join" },
    { "stepType": "select" },
    { "stepType": "filter" },
    { "stepType": "sort" },
    { "stepType": "limit" },
    { "stepType": "output" }
  ],
  "pipelineVersion": "v1.0"
}
```

### Regras desta fase

- `sources` é obrigatório e deve ter ao menos 1 item.
- Com mais de 1 fonte, `tableAlias` é obrigatório em cada fonte.
- `select` e `filters` aceitam campo sem alias apenas quando houver uma única fonte.
- `joinType` válido: `INNER` ou `LEFT`.
- `operator` válido por tipo: `=, <>, >, >=, <, <=, between, begins, contains` conforme política de tipo.
- Campos e tabelas sensíveis são bloqueados antes do SQL.
- `execution = auto|sync|async` (no `async`, resposta com `jobId`).
- SQL/ABL livre não é aceito; apenas as estruturas acima.

## Resposta de erro padrão

```json
{
  "success": false,
  "error": {
    "code": "INVALID_FIELD",
    "message": "Campo de selecao inexistente.",
    "details": "e.nome_inexistente"
  }
}
```

## Resposta síncrona

```json
{
  "success": true,
  "execution": "sync",
  "status": "completed",
  "page": 1,
  "pageSize": 50,
  "recordsReturned": 10,
  "hasMore": false,
  "pipelineVersion": "v1.0",
  "data": []
}
```

## Resposta assíncrona

```json
{
  "success": true,
  "execution": "async",
  "status": "queued",
  "jobId": "JOB-20260603-154500"
}
```

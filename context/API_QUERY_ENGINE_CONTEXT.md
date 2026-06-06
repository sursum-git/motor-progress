# Contexto da API e Motor de Consulta

## Endpoint base

```text
http://localhost:8890/web/SursumDynamicQuery
```

## Endpoints principais

```text
GET  /metadata/databases
GET  /metadata/tables?database=TODOS
GET  /metadata/tables/{table}/fields?database={database}
POST /metadata/relations
GET  /metadata/relations/{left}/{right}
POST /query
POST /jobs/drain
GET  /jobs/{jobId}
GET  /jobs/{jobId}/result
```

## Metadados

Classe:

```text
sursum/DynamicMetadataService.cls
```

Pontos criticos:

- Deve usar o banco selecionado, nao `DICTDB` fixo.
- `getTablesJson()` usa buffers dinamicos em `{banco}._File`.
- `getFieldsJson()` usa buffers dinamicos em `{banco}._File` e `{banco}._Field`.
- `loadCampos()` tambem precisa usar buffers dinamicos, pois e usado pela validacao da consulta.

## Validacao

Classe:

```text
sursum/DynamicQueryValidationService.cls
```

Responsabilidades:

- Validar existencia de tabela no banco informado.
- Validar existencia dos campos.
- Validar operadores por tipo.
- Bloquear tabelas/campos sensiveis.
- Exigir alias em multi-fonte.
- Exigir join em multi-fonte, ou inferir somente quando houver um unico campo comum seguro.

## Query builder OO

Classe:

```text
sursum/DynamicQueryPlanBuilder.cls
```

Responsabilidades:

- Montar fontes.
- Montar filtros.
- Montar joins.
- Montar ordenacao.
- Gerar a query final para `QUERY-PREPARE`.

## Execucao

Classe:

```text
sursum/DynamicMultiTableQueryService.cls
```

Responsabilidades:

- Preparar plano.
- Criar buffers dinamicos.
- Executar `QUERY-PREPARE`.
- Aplicar paginacao.
- Gerar JSON de resposta.
- Aplicar pipeline pos-query basico.

## Erros esperados

Multiplas fontes sem join e muitos campos comuns:

```json
{
  "code": "JOIN_INFERENCE_AMBIGUOUS"
}
```

Tabela inexistente:

```json
{
  "code": "INVALID_TABLE"
}
```

Campo inexistente:

```json
{
  "code": "INVALID_FIELD"
}
```

## Exemplo ems2med com join explicito

```json
{
  "execution": "sync",
  "page": 1,
  "pageSize": 500,
  "sources": [
    { "nome": "ped-venda", "alias": "ped-venda", "banco": "ems2med" },
    { "nome": "ped-item", "alias": "ped-item", "banco": "ems2med" }
  ],
  "joins": [
    {
      "type": "INNER",
      "leftAlias": "ped-venda",
      "leftField": "nr-pedido",
      "rightAlias": "ped-item",
      "rightField": "nr-pedido"
    }
  ],
  "select": [
    { "sourceAlias": "ped-venda", "field": "nome-abrev", "outputAlias": "cliente" },
    { "sourceAlias": "ped-venda", "field": "vl-tot-ped", "outputAlias": "vl-tot-ped" }
  ],
  "filters": [
    { "sourceAlias": "ped-venda", "field": "cod-sit-ped", "operator": "=", "value": "1" }
  ],
  "orderBy": [
    { "sourceAlias": "ped-venda", "field": "nome-abrev", "direction": "ASC" }
  ]
}
```

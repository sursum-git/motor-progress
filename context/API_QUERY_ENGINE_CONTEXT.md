# Contexto da API e Motor de Consulta

Atualizado em 2026-06-18.

## Endpoint base

Ambiente atual de producao/homologacao interna:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
```

Exemplo MED:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

Fallback usado quando nao houver contexto completo:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

Historico local:

```text
http://localhost:8890/web/SursumDynamicQuery
```

## Endpoints expostos pelo WEB Handler

```text
GET  /web/SursumDynamicQuery
POST /web/SursumDynamicQuery/query
POST /web/SursumDynamicQuery/query-store
POST /web/SursumDynamicQuery/table-browse

GET  /web/SursumDynamicQuery/metadata/sync?include=banks,aliases,tables,fields,indices,view-as&database=:database&table=:table
GET  /web/SursumDynamicQuery/metadata/databases
GET  /web/SursumDynamicQuery/metadata/database-catalog
GET  /web/SursumDynamicQuery/metadata/databases/sync
GET  /web/SursumDynamicQuery/metadata/cache-status?database=:database
GET  /web/SursumDynamicQuery/metadata/tables?database=:database
GET  /web/SursumDynamicQuery/metadata/tables/:table/fields?database=:database
POST /web/SursumDynamicQuery/metadata/view-as/resolve
POST /web/SursumDynamicQuery/metadata/relations
GET  /web/SursumDynamicQuery/metadata/relations/:left/:right
GET  /web/SursumDynamicQuery/metadata/relations/of?table=:table&database=:database

POST /web/SursumDynamicQuery/jobs/drain
GET  /web/SursumDynamicQuery/jobs/:jobId
GET  /web/SursumDynamicQuery/jobs/:jobId/result

GET  /web/SursumDynamicQuery/diagnostics/runtime?waitSeconds=:seconds&label=:label
GET  /web/SursumDynamicQuery/count?database=:database&table=:table
GET  /web/SursumDynamicQuery/benchmarks/customer-count
```

## Contrato JSON base de consulta

```json
{
  "execution": "sync",
  "pipelineVersion": "",
  "page": 1,
  "pageSize": 500,
  "sources": [],
  "joins": [],
  "select": [],
  "filters": [],
  "orderBy": [],
  "pipeline": []
}
```

Nomes aceitos no contrato real:

- `sources[].nome`
- `sources[].alias`
- `sources[].banco`
- `sources[].campos`
- `select[].sourceAlias`
- `select[].field`
- `select[].outputAlias`
- `filters[].sourceAlias`
- `orderBy[].sourceAlias`

Limite validado:

```text
pageSize <= 500
```

## Metadados PASOE

Classe principal:

```text
sursum-api/sursum/DynamicMetadataService.cls
```

Pontos criticos:

- Deve usar o banco selecionado, nao `DICTDB` fixo.
- Tabelas usam buffers dinamicos em `{banco}._File`.
- Campos usam buffers dinamicos em `{banco}._File` e `{banco}._Field`.
- Campos devem filtrar por `_File-Recid`; varrer `_Field` inteiro e muito lento em `ems2med`.
- `metadata/sync` pode sincronizar bancos, aliases, tabelas, campos, indices e view-as.
- `metadata/database-catalog` e usado pela tela para carregar bancos sem forcar sync completo.

## View-as

Endpoint:

```text
POST /metadata/view-as/resolve
```

Payload usado pela UI:

```json
{
  "environment": {
    "servidor": "",
    "usuario": "",
    "senha": "",
    "arquivoPf": "",
    "arquivoAlias": ""
  },
  "rows": [
    {
      "field": "idi-situacao",
      "viewAs": "view-as radio-set horizontal radio-buttons {cxinc/i01cx373.i 02}"
    }
  ]
}
```

Regras atuais:

- Se ambiente tem SSH (`servidor` e `usuario`), PASOE chama `RunViewAsIncludeResolver.p` no host configurado.
- Se nao tem SSH, usa fallback compilado/local.
- `cxinc/i01cx373.i` tem fallback direto no handler para `Ativo,Inativo`, evitando o erro Progress 471 no PASOE.
- CSV de view-as e importado pelo PHP/SQLite com colunas `tabela`, `campo`, `lista de opcoes`.
- View-as salvo manualmente e global por `tabela + campo`, sem banco e sem empresa.

## Joins

Endpoint automatico:

```text
GET /metadata/relations/of?table=:table&database=:database
```

Persistencia da UI:

```text
web/relation-store.php
SQLite: table_relations
```

Regras:

- Joins manuais usam `source=manual`.
- Joins gerados por `OF` usam origem automatica e nao podem apagar joins manuais equivalentes.
- A tela permite incluir, alterar e excluir joins por janela.

## Erros esperados

```json
{ "code": "JOIN_INFERENCE_AMBIGUOUS" }
```

```json
{ "code": "INVALID_TABLE" }
```

```json
{ "code": "INVALID_FIELD" }
```

```json
{ "code": "PAGE_SIZE_EXCEEDED" }
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

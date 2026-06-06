# Contexto do Projeto - Sursum Dynamic Query

## Objetivo

O projeto implementa um motor OOABL para consultas dinamicas em OpenEdge, exposto por PASOE/WEB Handler e consumido por uma interface web com Kendo UI.

O foco atual e permitir que um analista construa consultas e pipelines por JSON, sem precisar recompilar programas ABL a cada extracao.

## Decisoes de arquitetura

- O fluxo novo usa classes OOABL.
- `boMetaDados.p` e `boConsDin.p` ficaram apenas como referencia historica.
- O motor atual nao deve executar ABL livre nem WHERE livre informado pelo usuario.
- A consulta deve ser estruturada por JSON/DSL.
- `NO-LOCK` deve permanecer obrigatorio nas consultas dinamicas.
- O PASOE local de validacao usa o servico `SursumDynamicQuery`.
- A interface web principal fica em `web/query-builder.html`.

## Componentes principais

- `rest/DynamicQueryWebHandler.cls`: entrada HTTP WEB do PASOE.
- `sursum/DynamicQueryRequestModel.cls`: modelo da requisicao JSON.
- `sursum/DynamicQueryValidationService.cls`: validacao de fontes, campos, filtros, aliases e joins.
- `sursum/DynamicQueryPlanBuilder.cls`: montagem da query dinamica segura.
- `sursum/DynamicMultiTableQueryService.cls`: orquestracao e execucao sync/async.
- `sursum/DynamicMetadataService.cls`: leitura de metadados dos bancos conectados.
- `web/query-builder.html`: construtor visual.
- `web/query-result.html`: renderizacao do resultado.

## Contrato JSON base

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

## Regras importantes

- Em consulta com mais de uma fonte, aliases sao obrigatorios.
- Tabelas com hifen sao validas no OpenEdge e devem ser aceitas.
- Campos com hifen sao validos e devem ser aceitos.
- Multiplas fontes sem join explicito so podem usar join inferido se houver exatamente um campo comum seguro.
- Se houver muitos campos comuns, a API deve retornar erro de join ambiguo.
- Bancos podem ter tabelas com o mesmo nome, entao `banco` faz parte da identidade da fonte.

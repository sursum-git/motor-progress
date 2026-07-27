# Contexto do Projeto - Sursum Dynamic Query

Atualizado em 2026-07-27.

## Objetivo

O projeto implementa um motor de consultas dinamicas para Progress/OpenEdge, exposto por PASOE WEB Handler e operado por uma interface web Kendo. O objetivo e permitir que o usuario monte consultas, navegue metadados, cadastre relacoes e mantenha view-as sem executar ABL/SQL livre informado pelo usuario.

O estado local deste repositorio e a linha canonica atual. O `master` remoto historico tinha estrutura anterior sem base comum com o repositorio local e deve ser substituido pelo local quando for necessario alinhar GitHub.

## Entrada da aplicacao

Base web usada hoje:

```text
http://php81.imatextil.com.br/motor-progress/
```

Shell principal:

```text
http://php81.imatextil.com.br/motor-progress/web/index.html
```

Paginas internas devem ser abertas preferencialmente pelo shell:

```text
http://php81.imatextil.com.br/motor-progress/web/index.html?page=metadata-maintenance.html
```

## Decisoes de arquitetura

- O fluxo novo usa classes OOABL em `sursum-api/sursum`.
- A estrutura canonica atual usa `sursum-api/` para Progress/OOABL, `web/` para PHP/HTML/JS, `sursum-conf/` para configuracao operacional, `tests/` para contratos e `scripts/` para deploy.
- `boMetaDados.p` e `boConsDin.p` ficam apenas como referencia historica.
- O motor nao deve executar ABL livre nem WHERE livre informado pelo usuario.
- A consulta e estruturada por JSON/DSL.
- `NO-LOCK` deve permanecer obrigatorio nas consultas dinamicas.
- Bancos, tabelas e campos com hifen sao validos.
- Em consultas com mais de uma fonte, aliases sao obrigatorios.
- Multiplas fontes exigem join explicito, salvo inferencia segura quando houver exatamente um campo comum.
- `banco + tabela` identifica tabela; tabelas de bancos diferentes podem ter o mesmo nome.
- Contexto funcional e persistencia operacional migraram para SQLite em `web/sursum-conf/sursum.sqlite`.
- Previews de JSON foram removidos da UI; JSON local e apenas fallback/migracao.
- `view-as` manual e global por `tabela + campo`, sem banco/empresa, porque os bancos por empresa devem ser equivalentes.
- Joins manuais nao devem ser apagados pelo processamento automatico de relacoes `OF`.

## Componentes principais

- `sursum-api/rest/DynamicQueryWebHandler.cls`: WEB Handler HTTP do PASOE.
- `DynamicQueryWebHandler.cls`: copia raiz do handler para PROPATHs que apontam direto para `sursum`.
- `sursum-api/sursum/DynamicQueryRequestModel.cls`: modelo da requisicao JSON.
- `sursum-api/sursum/DynamicQueryValidationService.cls`: validacao de fontes, campos, filtros, aliases e joins.
- `sursum-api/sursum/DynamicQueryPlanBuilder.cls`: montagem da query dinamica segura.
- `sursum-api/sursum/DynamicMultiTableQueryService.cls`: execucao sync/async.
- `sursum-api/sursum/DynamicMetadataService.cls`: leitura de metadados dos bancos conectados.
- `sursum-api/sursum/ViewAsIncludeResolver.p`: resolvedor compilado de includes de view-as.
- `sursum-api/sursum/RunViewAsIncludeResolver.p`: runner de view-as via SSH/compilador externo.
- `web/context-manager.js`: contexto cliente/ambiente/empresa.
- `web/context-store.php`: schema e persistencia SQLite do contexto.
- `web/metadata-store.php`: view-as manual/CSV e fila de atualizacao de metadados.
- `web/relation-store.php`: joins manuais e joins OF salvos em SQLite.
- `web/metadata-pasoe.php` e `web/pasoe-proxy.php`: proxy seguro para PASOE a partir do servidor web.
- `web/container-client.html`: exemplo especifico para consulta salva de container por `nr-container`.
- `web/saved-query-client.html`: cliente generico para executar consulta salva por `queryId`.
- `sursum-api/querys/pp-it-container-por-container.json`: consulta salva que filtra `espec.pp-it-container` por `nr-container`.
- `scripts/deploy_query_progress_192_168_0_39.sh`: deploy de `web/` para homologacao `query-progress`.

## Paginas principais

- `web/index.html`: shell com menu lateral, iframe e appbar de contexto.
- `web/context-selector.html`: seleciona cliente, ambiente e empresa.
- `web/client-config.html`: cadastro de clientes; botoes de linha abrem janelas maximizadas para ambientes e empresas.
- `web/table-browser.html`: navegador de metadados por banco/tabela, campos, indices, joins e dados.
- `web/metadata-maintenance.html`: atualizacao em lote, view-as manual/CSV e join manual.
- `web/query-builder.html`: construtor visual de consultas.
- `web/query-wizard-3steps.html`: consulta por tabela.
- `web/query-list.html`: consultas salvas.
- `web/query-result.html`: visualizacao de resultado.
- `web/container-client.html`: executa `pp-it-container-por-container` com `nr-container` vindo da URL.
- `web/saved-query-client.html`: executa consulta salva por id e repassa os demais parametros da URL em `parameters.querystring`.

## Contexto cliente/ambiente/empresa

Entidades persistidas no SQLite:

- `clients`
- `environments`
- `client_environment_links`
- `companies`
- `physical_databases`
- `aliases`
- `config_meta`

Ambiente contem:

- `pasoe_base_url`, preferencialmente com `{empresa}` no caminho.
- `auth_mode`, `authorization`, `company_id_mode`, `extra_query_params`.
- `servidor`, `usuario`, `senha`, `arquivo_pf`, `arquivo_alias` para resolvedor via SSH.

Empresa contem:

- `code`: codigo numerico da empresa, usado como `companyId` quando `company_id_mode=query`.
- `path_param`: token que substitui `{empresa}` no endpoint.

Exemplo de endpoint por ambiente:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
```

Exemplo resolvido para empresa MED:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

Fallback conhecido:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

## Estado recente importante

- PASOE `sursum-api` esta no servidor `192.168.0.111`.
- Paginas PHP/HTML de homologacao estao em `http://iol.imatextil.com.br/query-progress/`, publicadas no servidor `192.168.0.39` em `/var/www/clients/client1/web7/web/query-progress/`.
- O deploy de homologacao deve usar `scripts/deploy_query_progress_192_168_0_39.sh`; o script tambem corrige permissoes SQLite para grupo `www-data`.
- Exemplo validado: `saved-query-client.html?queryId=pp-it-container-por-container&nr-container=1650`.
- Runtime publicado em `/mnt/datasul/ERP/sursum` e via share Windows `\\192.168.0.137\erp\sursum`.
- Host Windows de compilacao: `192.168.0.42`, workspace `C:\opencode\motor-progress`, OpenEdge `C:\Progress_12\OE`.
- O endpoint `POST /metadata/view-as/resolve` foi validado em 2026-06-17 para `cxinc/i01cx373.i`, retornando `Ativo,Inativo`.
- O runner SSH de view-as inclui `C:\opencode\motor-progress\ems2` no PROPATH.
- O fallback sem SSH resolve diretamente `cxinc/i01cx373.i` para evitar erro Progress 471 no PASOE.
- Remote GitHub configurado: `https://github.com/sursum-git/motor-progress.git`. Para push com token, desabilitar credencial antiga com `git -c credential.helper= ...` quando necessario.

## Backlog registrado

- Registrar transacoes do backend com PID e contexto operacional.
- Reformular o registro de transacoes com notificacao por webhook.

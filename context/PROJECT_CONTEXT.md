# Contexto do Projeto - Sursum Dynamic Query

Atualizado em 2026-09-24.

Este arquivo e o ponto de partida recomendado para qualquer nova sessao Codex no projeto `motor-progress`, especialmente ao transferir o trabalho para Windows. Os demais arquivos da pasta `context/` detalham partes especificas:

- `context/API_QUERY_ENGINE_CONTEXT.md`: endpoints PASOE, contrato JSON, metadados, view-as e joins.
- `context/WEB_QUERY_BUILDER_CONTEXT.md`: shell web, paginas Kendo, contexto ativo, autenticacao e telas.
- `context/OPENEDGE_PASOE_CONTEXT.md`: configuracao OpenEdge/PASOE.
- `context/ASYNC_PIPELINE_CONTEXT.md`: fila async e workers.
- `context/DATABASE_CONTEXT.md`: bancos, metadados e SQLite.

## Objetivo

O projeto implementa um motor de consultas dinamicas para Progress/OpenEdge, exposto por PASOE WEB Handler e operado por uma interface web Kendo/PHP. O objetivo e permitir que o usuario monte consultas, navegue metadados, cadastre relacoes, mantenha view-as e execute consultas salvas sem executar ABL, SQL ou WHERE livre informado pelo usuario.

O estado local deste repositorio e a linha canonica atual. O `master` remoto historico tinha estrutura anterior sem base comum com o repositorio local e foi substituido pela estrutura local atual em 2026-07-27. Veja `docs/GIT_REMOTE_STATE.md`.

## Entradas da aplicacao

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

Homologacao publicada do pacote `query-progress`:

```text
http://iol.imatextil.com.br/query-progress/
```

Exemplo validado de consulta salva:

```text
http://iol.imatextil.com.br/query-progress/saved-query-client.html?queryId=pp-it-container-por-container&nr-container=1650
```

## Estrutura canonica

| Caminho | Finalidade |
|---|---|
| `sursum-api/sursum/` | Classes OOABL do motor de consulta, metadados, validacao, execucao, view-as e utilitarios |
| `sursum-api/rest/` | Fachadas REST/WEB Handler para PASOE |
| `sursum-api/workers/` | Entradas de worker CLIENT/PASOE, drain de fila e programas APSV auxiliares |
| `sursum-api/runners/` | Executores genericos por arquivo JSON |
| `sursum-api/querys/` | Consultas salvas operacionais em JSON |
| `web/` | Shell, paginas HTML/Kendo, JavaScript, CSS, PHP, autenticacao e proxies |
| `web/sursum-conf/` | Configuracao e SQLite usados pela publicacao web PHP |
| `sursum-conf/` | Configuracao operacional raiz e copia local de SQLite/configs |
| `conf-web-handler/` | Exemplos JSON usados pelo WEB Handler |
| `conf/pasoe/` | Referencia de configuracao da instancia PASOE |
| `conf/metadata/` | Metadados JSON legados/fallback |
| `conf/relations/` | Relacoes JSON legadas/fallback |
| `docs/` | Documentacao detalhada do projeto |
| `context/` | Resumos de contexto para Codex e transferencia de conhecimento |
| `tests/e2e/` | Contratos PHP e testes Playwright |
| `scripts/` | Scripts de deploy, correcao e reprocessamento |
| `db/` | Schemas `.df` e loaders da fila async, quando presentes no checkout |
| `ABL_Context/` | Material de apoio sobre sintaxe ABL/OOABL |
| `ems2/` | Includes TOTVS/Datasul usados por view-as e compilacao |
| `especificos/` | Fontes especificos IMA/TOTVS |

## Decisoes de arquitetura

- O fluxo novo usa classes OOABL em `sursum-api/sursum`.
- `boMetaDados.p` e `boConsDin.p` ficam apenas como referencia historica em `sursum-api/sursum/esbo`.
- A consulta e estruturada por JSON/DSL; nao aceitar SQL, ABL ou WHERE livre vindo do usuario.
- `NO-LOCK` deve permanecer obrigatorio nas consultas dinamicas.
- Bancos, tabelas e campos com hifen sao validos.
- Em consultas com mais de uma fonte, aliases sao obrigatorios.
- Multiplas fontes exigem join explicito, salvo inferencia segura quando houver exatamente um campo comum.
- `banco + tabela` identifica tabela; tabelas de bancos diferentes podem ter o mesmo nome.
- Contexto funcional, metadados, relacoes, logs e persistencia operacional migraram para SQLite em `web/sursum-conf/sursum.sqlite`.
- Previews de JSON foram removidos de fluxos operacionais; JSON local fica como fallback/migracao.
- `view-as` manual e global por `tabela + campo`, sem banco/empresa, porque os bancos por empresa devem ser equivalentes.
- Joins manuais nao devem ser apagados pelo processamento automatico de relacoes `OF`.
- Respostas HTTP de paginas operacionais devem ler texto antes de tentar JSON, para expor erros PHP/PASOE brutos sem quebrar com `Unexpected token '<'`.

## Componentes Progress/OOABL principais

- `sursum-api/rest/DynamicQueryWebHandler.cls`: WEB Handler HTTP do PASOE.
- `DynamicQueryWebHandler.cls`: copia raiz do handler para PROPATHs que apontam direto para `sursum`.
- `sursum-api/sursum/DynamicQueryRequestModel.cls`: modelo da requisicao JSON.
- `sursum-api/sursum/DynamicQueryRequestSerializer.cls`: serializacao/desserializacao.
- `sursum-api/sursum/DynamicQueryValidationService.cls`: validacao de fontes, campos, filtros, aliases, joins e politicas.
- `sursum-api/sursum/DynamicQueryPlanBuilder.cls`: montagem da query dinamica segura.
- `sursum-api/sursum/DynamicQueryService.cls`: execucao dinamica.
- `sursum-api/sursum/DynamicMultiTableQueryService.cls`: orquestracao sync/async e multi-tabela.
- `sursum-api/sursum/DynamicMetadataService.cls`: leitura de bancos, tabelas, campos, indices e metadados.
- `sursum-api/sursum/DynamicQueryAsyncService.cls`: enfileiramento/status/cancelamento.
- `sursum-api/sursum/DynamicQueryJobRepository.cls`: persistencia da fila async.
- `sursum-api/sursum/DynamicQueryWorkerService.cls`: processamento dos jobs.
- `sursum-api/sursum/DynamicQueryResultWriter.cls`: escrita atomica de resultado JSON.
- `sursum-api/sursum/PasoeExecutionContext.cls`: captura de contexto de execucao/auditoria.
- `sursum-api/sursum/ViewAsIncludeResolver.p`: resolvedor compilado de includes de view-as.
- `sursum-api/sursum/RunViewAsIncludeResolver.p`: runner de view-as via SSH/compilador externo.
- `sursum-api/runners/RunDynamicQueryFromJson.p`: runner batch por arquivo JSON.

## WEB Handler e endpoints

Endpoint base interno atual:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
```

Exemplo MED:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

Historico local:

```text
http://localhost:8890/web/SursumDynamicQuery
```

Endpoints importantes:

- `POST /query`: executa/enfileira consulta.
- `POST /query-store`: execucao de consulta salva.
- `POST /table-browse`: navegacao paginada de dados por tabela.
- `GET /metadata/databases`: bancos conectados.
- `GET /metadata/database-catalog`: catalogo de bancos para UI.
- `GET /metadata/sync`: sincronizacao de bancos, aliases, tabelas, campos, indices e view-as.
- `GET /metadata/cache-status`: status de cache por banco.
- `GET /metadata/tables`: tabelas por banco.
- `GET /metadata/tables/:table/fields`: campos por banco/tabela.
- `POST /metadata/view-as/resolve`: resolve includes de view-as.
- `POST /metadata/relations`: grava/resolve relacoes.
- `GET /metadata/relations/of`: relacoes `OF` por tabela.
- `POST /jobs/drain`: processa fila async no PASOE.
- `GET /jobs/:jobId`: status de job.
- `GET /jobs/:jobId/result`: resultado JSON de job.
- `GET /diagnostics/runtime`: diagnostico de runtime PASOE.
- `GET /count`: contagem por banco/tabela.
- `GET /benchmarks/customer-count`: benchmark de contagem.

## Camada web PHP/Kendo

Paginas principais:

- `web/index.html`: shell com menu lateral, iframe e appbar de contexto.
- `web/context-selector.html`: seleciona cliente, ambiente e empresa.
- `web/client-config.html`: cadastro de clientes, ambientes e empresas.
- `web/table-browser.html`: navegador de metadados por banco/tabela, campos, indices, joins e dados.
- `web/metadata-maintenance.html`: atualizacao em lote, view-as manual/CSV e join manual.
- `web/query-builder.html`: construtor visual de consultas.
- `web/query-wizard-3steps.html`: assistente de consulta por tabela.
- `web/query-list.html`: consultas salvas.
- `web/query-result.html`: visualizacao de resultado.
- `web/query-file-runner.html`: runner legado por arquivo JSON local.
- `web/saved-query-runner.html`: tela operacional para consultas salvas com parametros dinamicos.
- `web/container-client.html`: executa `pp-it-container-por-container` com `nr-container` na URL.
- `web/saved-query-client.html`: executa consulta salva por `queryId`, `id` ou `code`.
- `web/request-log.html`: consulta logs gravados pelo proxy PHP.
- `web/program-executor-client.html`: cliente de execucao de programas configurados.
- `web/json-object-analyzer.html`: analisador/inspector de JSON.
- `web/link-config.html`, `web/endpoint-config.html`, `web/relation-maintenance.html`, `web/view-as-maintenance.html`: telas auxiliares de configuracao/manutencao.

PHP/endpoints principais:

- `web/auth.php`: login LDAP/local e sessao.
- `web/context-store.php`: schema e persistencia SQLite de contexto.
- `web/metadata-store.php`: metadados, view-as manual/CSV e fila de carga.
- `web/relation-store.php`: joins manuais e joins OF salvos em SQLite.
- `web/metadata-pasoe.php`: proxy seguro para metadados PASOE.
- `web/pasoe-proxy.php`: proxy seguro para execucao PASOE, com log.
- `web/request-log-store.php`: leitura dos logs de requisicoes.
- `web/saved-query-store.php`: leitura/execucao de consultas salvas.
- `web/view-as-resolver.php`: resolucao auxiliar de view-as.

Assets e padroes:

- Kendo UI local em `web/vendor/kendo`.
- jQuery local em `web/vendor/jquery/jquery-4.0.0.min.js`.
- `web/ui-ready.css` e `web/ui-ready.js` controlam revelacao visual apos inicializacao Kendo.
- Grids usam `SursumGridLoading` e `kendo.ui.progress`.
- Paginas internas devem usar `SursumContext` em vez de recriar painel completo de contexto.

## Contexto cliente/ambiente/empresa

Persistencia principal:

```text
web/context-store.php
web/sursum-conf/sursum.sqlite
```

Entidades persistidas:

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

- `code`: codigo numerico usado como `companyId` quando `company_id_mode=query`.
- `path_param`: token que substitui `{empresa}` no endpoint.

Exemplo:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

## SQLite e dados operacionais

SQLite em uso:

```text
web/sursum-conf/sursum.sqlite
sursum-conf/sursum.sqlite
```

O SQLite guarda contexto, metadados, relacoes, view-as, logs de proxy, configuracoes e filas auxiliares da camada PHP. Em homologacao, `web/sursum-conf` precisa ser gravavel pelo usuario/grupo do PHP-FPM (`www-data`).

Arquivos `.sqlite`, `.sqlite-wal` e `.sqlite-shm` sao estado de runtime. Para uma nova instalacao Windows, copie apenas se quiser preservar o cadastro/metadados/logs atuais; para um ambiente limpo, deixe o sistema recriar ou importe seletivamente.

## Consultas salvas

Consultas versionadas:

- `sursum-api/querys/controle-preco-por-pedido-container.json`
- `sursum-api/querys/moeda-precos-atuais-por-container.json`
- `sursum-api/querys/pp-container-por-container.json`
- `sursum-api/querys/pp-it-container-por-container.json`
- `sursum-api/querys/tabelas-preco-por-container.json`

`saved-query-store.php` le JSONs de `sursum-api/querys` no repositorio local e de `web/sursum-querys` no servidor publicado.

## View-as

Fluxo atual:

- `field_view_as` preserva o texto original do Progress, inclusive includes como `{adinc/i03ad209.i 2}`.
- `field_view_as_options` guarda as opcoes resolvidas/editadas.
- O endpoint `POST /metadata/view-as/resolve` tenta resolver por SSH se o ambiente possui `servidor` e `usuario`.
- Sem SSH, usa fallback compilado/local.
- `cxinc/i01cx373.i` possui fallback direto para `Ativo,Inativo`, evitando erro Progress 471 no PASOE.
- Importacao CSV passa por PHP/SQLite.
- View-as manual e global por `tabela + campo`, sem banco/empresa.

Host Windows de compilacao/resolucao:

```text
192.168.0.42
C:\opencode\motor-progress
C:\Progress_12\OE
```

O runner SSH de view-as inclui `C:\opencode\motor-progress\ems2` no PROPATH.

## Joins

Persistencia principal:

```text
web/relation-store.php
SQLite: table_relations
```

Regras:

- Joins manuais usam `source=manual`.
- Joins gerados por `OF` usam origem automatica.
- Joins automaticos nao podem apagar joins manuais equivalentes.
- Relações diretas e invertidas duplicadas devem ser bloqueadas pela UI.
- Arquivos JSON em `conf/relations` sao legado/fallback.

## Deploy e ambientes

PASOE `sursum-api` esta no servidor:

```text
192.168.0.111
```

Homologacao web `query-progress`:

```text
Servidor: 192.168.0.39
Destino: /var/www/clients/client1/web7/web/query-progress/
URL: http://iol.imatextil.com.br/query-progress/
```

Script recomendado:

```bash
DEPLOY_PASSWORD='...' ./scripts/deploy_query_progress_192_168_0_39.sh
```

O script sincroniza `web/` e ajusta permissoes de `web/sursum-conf` para grupo `www-data`, pasta `2775` e SQLite `0664`.

Runtime publicado:

```text
/mnt/datasul/ERP/sursum
\\192.168.0.137\erp\sursum
```

## Windows local recomendado

Workspace sugerido:

```text
C:\opencode\motor-progress
```

OpenEdge:

```text
C:\Progress\OpenEdge\bin
C:\Progress_12\OE
```

Banco local de exemplo:

```text
C:\opencode\motor-progress\db\sports2000
```

PROPATH esperado:

```text
C:\opencode\motor-progress\sursum-api\sursum
C:\opencode\motor-progress\sursum-api\rest
C:\opencode\motor-progress\sursum-api\workers
C:\opencode\motor-progress\sursum-api\runners
C:\opencode\motor-progress\sursum-api\sursum\esp
C:\opencode\motor-progress
C:\Progress\OpenEdge\tty\netlib\OpenEdge.Net.pl
```

`C:\opencode\motor-progress` deve permanecer no `PROPATH` porque e a pasta pai de `sursum-api` e `conf-web-handler`.

Instancia PASOE local historica:

```text
sursumpasoedev
HTTP 8890
HTTPS/admin auxiliar 8891
shutdown 8892
jmx/admin auxiliar 8893
```

Modo local atual para banco:

```text
-db C:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB
```

Esse modo e single-user/direct access. O PASOE segura o banco; para compilar com `_progres -1`, pare o PASOE antes.

## Testes e validacao

Scripts NPM:

- `npm run mock:e2e`: sobe servidor mock Playwright.
- `npm run test:e2e`: roda Playwright.
- `npm run test:e2e:backend`: subset backend do query-store.
- `npm run test:e2e:pasoe`: testes PASOE backend.
- `npm run test:contract`: contrato PHP principal de query-store.
- `npm run test:all`: contrato PHP + Playwright.

Contratos PHP em `tests/e2e/` cobrem autenticacao, SQLite busy timeout, logs, query-store, saved-query-runner, view-as, relacoes, Kendo pt-BR, layout e analyzer JSON.

Testes Playwright em `tests/e2e/playwright/` cobrem `client-config`, `metadata-maintenance`, logs PASOE, program executor, query-store, query wizard e table browser.

Ao alterar fontes Progress (`.cls`, `.p`, `.w`, `.i`, `.df`), copiar para o host Windows de compilacao `192.168.0.42` e compilar conforme a regra operacional do projeto.

## Git e transferencia para Windows

Remote GitHub:

```text
https://github.com/sursum-git/motor-progress.git
```

O melhor caminho para transferir para Windows nao e copiar somente um arquivo de contexto. A melhor opcao e:

1. Garantir que o repositorio Linux esteja com tudo que deve ser preservado no Git.
2. Fazer `git clone` ou `git pull` no Windows em `C:\opencode\motor-progress`.
3. Copiar ou recriar apenas os arquivos de runtime/local que nao devem estar no Git, como bancos fisicos, credenciais, SQLite operacional, configs com senha e artefatos locais.
4. Abrir uma nova sessao Codex no Windows pedindo para ler `context/PROJECT_CONTEXT.md` primeiro.

Copiar a pasta `context/` ajuda muito para transferir conhecimento entre sessoes Codex, mas nao substitui o repositorio completo. Para contexto de conversa, copie estes arquivos junto com o clone:

- `context/PROJECT_CONTEXT.md`
- `context/API_QUERY_ENGINE_CONTEXT.md`
- `context/WEB_QUERY_BUILDER_CONTEXT.md`
- `context/OPENEDGE_PASOE_CONTEXT.md`
- `context/ASYNC_PIPELINE_CONTEXT.md`
- `context/DATABASE_CONTEXT.md`
- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/WEB_UI.md`
- `docs/SETUP_PASOE.md`
- `docs/API_CONTRACT.md`
- `docs/TROUBLESHOOTING.md`

Se for necessario preservar o estado operacional exato da UI, copie tambem `web/sursum-conf/sursum.sqlite` com seus arquivos WAL/SHM apos parar processos que possam escrever nele. Se a intencao for apenas desenvolver no Windows, prefira nao copiar logs/runtime e recriar o ambiente.

## Arquivos que exigem cuidado

Nao gravar tokens no projeto, `.git/config` ou URL do remote. A credencial global antiga pode interferir (`credential.helper=store`); quando usar token temporario, prefira Git com `git -c credential.helper= ...` e `GIT_ASKPASS` temporario.

Arquivos/configs potencialmente sensiveis:

- `web/sursum-conf/auth.json`
- `sursum-conf/auth.json`
- `sursum-conf/context.json`
- `web/sursum-conf/context.json`
- SQLites em `web/sursum-conf/` e `sursum-conf/`
- configs de ambiente com usuario/senha SSH/PASOE

Arquivos de runtime que normalmente nao precisam ir para Git:

- `*.sqlite`, `*.sqlite-wal`, `*.sqlite-shm`
- bancos Progress fisicos (`*.db`, `*.d1`, `*.d2`, `*.b1`, `*.b2`, `*.lg`, `*.lk`)
- logs, resultados temporarios e artefatos de teste.

## Estado recente importante

- PASOE interno atual usa `192.168.0.111:9911` com path por empresa, por exemplo `/med/web/SursumDynamicQuery`.
- Homologacao web publicada em `http://iol.imatextil.com.br/query-progress/`.
- Deploy homologacao deve usar `scripts/deploy_query_progress_192_168_0_39.sh`.
- `saved-query-client.html?queryId=pp-it-container-por-container&nr-container=1650` foi validado como exemplo operacional.
- Runtime publicado em `/mnt/datasul/ERP/sursum` e share `\\192.168.0.137\erp\sursum`.
- Host Windows de compilacao: `192.168.0.42`, workspace `C:\opencode\motor-progress`, OpenEdge `C:\Progress_12\OE`.
- Endpoint `POST /metadata/view-as/resolve` foi validado para `cxinc/i01cx373.i`, retornando `Ativo,Inativo`.
- O fallback sem SSH resolve diretamente `cxinc/i01cx373.i` para evitar erro Progress 471 no PASOE.
- UI usa shell `web/index.html`; paginas internas devem ser abertas pelo shell quando possivel.
- `tmp_patch_cons_item_cards.php` aparece como arquivo nao versionado no workspace atual; nao trate como parte canonica sem revisar.

## Backlog registrado

- Registrar transacoes do backend com PID e contexto operacional.
- Reformular o registro de transacoes com notificacao por webhook.
- Evoluir paginacao profunda de offset para cursor/keyset quando necessario.
- Avaliar `totalRecords` exato como opcional, cacheado ou assincrono para tabelas grandes.

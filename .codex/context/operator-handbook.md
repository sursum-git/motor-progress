# Handbook operacional do projeto

Este documento serve como guia de retomada, operacao e desenvolvimento do projeto em qualquer instalacao do Codex com OpenEdge/PASOE disponiveis.

## 1. O que e este projeto

Este repositório implementa um motor de consulta dinamica em Progress/OpenEdge com exposicao via PASOE/REST e uma UI web Kendo para operar o motor.

Os dois eixos principais sao:

- backend OOABL para validacao, plano, execucao, fila async e escrita de resultados
- frontend web para contexto, configuracao, metadados e consultas

## 2. Objetivo funcional

Permitir consultas estruturadas sem SQL/ABL livre, com:

- fontes e aliases
- joins explicitamente controlados
- filtros validados
- paginacao
- execucao `sync`, `async` e `auto`
- fila persistente
- resultado em JSON
- contexto operacional por cliente, ambiente e empresa

## 3. Mapa de pastas

### Backend

- `sursum/`: classes OOABL principais do motor
- `rest/`: handlers e facades REST/WEB
- `workers/`: workers e rotinas de apoio
- `examples/`: exemplos curl, payloads e respostas
- `docs/`: documentacao de arquitetura, API e troubleshooting

### Infra local

- `pasoe/sursum-pasoe-dev/`: instancia local do PASOE
- `db/`: bancos e artefatos locais de dados
- `conf/`: metadata, aliases, relations e configuracoes auxiliares

### Frontend

- `web/`: aplicacao Kendo

### Contexto Codex

- `.codex/context/`: contexto operacional e de continuidade
- `.codex/skills/sursum-openedge/`: skill local para operar este repositório

## 4. Arquivos de contexto que devem ser lidos primeiro

Ao retomar o projeto em outra maquina ou outra thread, ler nesta ordem:

1. `.codex/context/project-state.md`
2. `.codex/context/openedge-pasoe-operations.md`
3. `.codex/context/api-contract-notes.md`
4. `.codex/context/remote-bootstrap.md`
5. `.codex/context/operator-handbook.md`

## 5. Entrada principal da aplicacao web

Arquivo principal:

- `web/index.html`

Papel:

- menu lateral central
- iframe com paginas internas
- appbar com contexto atual
- link para alterar contexto
- abrir pagina atual ou itens em nova aba

## 6. Modelo funcional de contexto

O contexto atual da UI e centralizado em:

- `web/context-manager.js`

Ele persiste em `localStorage`:

- cliente atual
- ambiente atual
- empresa atual
- configuracao funcional

Estruturas principais:

- `clients`
- `environments`
- `companies`
- `selected`

## 7. Regra atual da UI

Regra que deve ser preservada:

- o menu central mostra `cliente / ambiente / empresa` no appbar
- paginas internas nao devem repetir esse resumo
- paginas de consulta devem expor principalmente a selecao de empresa
- mudanca de cliente/ambiente deve acontecer pela pagina de contexto

## 8. Paginas web importantes

### Contexto

- `web/context-selector.html`: define cliente, ambiente e empresa base

### Configuracao

- `web/client-config.html`: CRUD de clientes
- `web/endpoint-config.html`: CRUD de ambientes e empresas do ambiente
- `web/link-config.html`: vinculo cliente <-> ambiente

### Consulta

- `web/query-builder.html`: designer visual de consultas
- `web/query-wizard-3steps.html`: consulta por tabela
- `web/query-result.html`: execucao e visualizacao de resultado
- `web/query-list.html`: biblioteca de consultas salvas

### Metadados

- `web/table-browser.html`: navegador de metadados por banco/tabela
- `web/database-alias-config.html`: aliases
- `web/field-metadata-config.html`: campos/opcoes
- `web/metadata-storage-config.html`: configuracao de armazenamento

## 9. Backend: classes conceituais principais

- `DynamicQueryRequestModel.cls`
- `DynamicQueryRequestSerializer.cls`
- `DynamicQueryValidationService.cls`
- `DynamicQueryPlanBuilder.cls`
- `DynamicMultiTableQueryService.cls`
- `DynamicQueryAsyncService.cls`
- `DynamicQueryJobRepository.cls`
- `DynamicQueryWorkerService.cls`
- `DynamicQueryWorkerOptions.cls`
- `DynamicQueryResultWriter.cls`
- `PasoeExecutionContext.cls`

## 10. Contrato atual da API

Base:

- `http://localhost:8890/web/SursumDynamicQuery`

Endpoints principais:

- `POST /query`
- `POST /jobs/drain`
- `GET /jobs/{jobId}`
- `GET /jobs/{jobId}/result`

Formato que deve ser assumido:

- `sources[].nome`
- `sources[].alias`
- `sources[].campos`
- `select[].sourceAlias`
- `select[].field`
- `select[].outputAlias`
- `filters[].sourceAlias`
- `orderBy[].sourceAlias`

Restricao conhecida:

- `pageSize <= 500`

## 11. Estado operacional do PASOE

Instancia local padrao:

- `sursumpasoedev`

Bancos relevantes no ambiente atual:

- `sports2000`
- `ems2cad`
- `ems2med`
- `ems5`

Observacao critica:

- o ambiente local foi operado com bancos em `-1`
- se o PASOE estiver ativo segurando esses bancos em `-1`, rotinas `_progres.exe` concorrentes podem falhar

## 12. Fluxo de bootstrap em nova maquina

1. Clonar o repositorio.
2. Garantir OpenEdge e PASOE instalados.
3. Ajustar paths locais.
4. Revisar `pasoe/sursum-pasoe-dev/conf/openedge.properties`.
5. Revisar configuracoes de temp/JNA do PASOE.
6. Confirmar disponibilidade dos bancos locais necessarios.
7. Subir o PASOE.
8. Abrir `web/index.html`.
9. Configurar contexto em `web/context-selector.html`.

## 13. O que o Git leva e o que nao leva

### O Git leva

- fontes ABL
- fontes web
- docs
- skill local
- contexto Codex
- configuracoes textuais do repositorio

### O Git nao leva

- bancos locais
- `localStorage` do navegador
- instancia concreta do PASOE fora do repositorio
- permissoes de temp/JNA
- estado do sistema operacional local

## 14. Fluxo de desenvolvimento web

Quando mexer na UI:

1. considerar `web/index.html` como shell principal
2. preservar a regra de contexto no appbar
3. evitar duplicar cliente/ambiente nas paginas internas
4. manter a selecao de empresa quando a pagina for de consulta
5. usar `context-manager.js` para estado funcional
6. usar `menu-pages.json` para navegacao

## 15. Fluxo de desenvolvimento ABL

Quando mexer no backend:

1. identificar se a alteracao afeta serializer, validacao, plano, execucao ou fila
2. revisar impacto no contrato JSON
3. lembrar que `boConsDin.p` e `boMetaDados.p` nao sao o fluxo principal
4. se houver banco em `-1`, parar PASOE antes de compilar/rodar `_progres.exe`
5. depois de alteracao funcional relevante, compilar e reiniciar PASOE apenas quando necessario

## 16. Fluxo de troubleshooting rapido

### Se a UI nao refletir o contexto esperado

- revisar `web/context-manager.js`
- revisar `localStorage`
- revisar `web/context-selector.html`
- revisar appbar em `web/index.html`

### Se uma pagina de consulta mostrar contexto demais

- remover resumo de cliente/ambiente da pagina
- deixar somente empresa, se fizer sentido funcional
- confiar no appbar do menu central

### Se o PASOE nao listar bancos esperados

- revisar `openedge.properties`
- confirmar stop/start completo
- esperar o startup terminar antes de testar endpoint

### Se `_progres.exe` falhar dizendo que a base esta em `single-user`

- garantir que o PASOE foi parado
- nao rodar stop e `_progres.exe` em paralelo
- tentar novamente apos o stop concluir

### Se o load de `.d` falhar

- usar `dump-name` sem extensao `.d`
- apontar o diretorio corretamente
- se ocorrer `_File record not on file. (138)` com schema batendo, investigar o mecanismo de load e nao apenas nome/colunas

## 17. Diagnostico recente de `.d`

Validacoes ja feitas:

- `ad098` resolve para `emitente`
- `di154` resolve para `ped-item`
- `di159` resolve para `ped-venda`

Comparacao schema/arquivo:

- `ad098`: 204 posicoes exportaveis e 204 valores na linha
- `di154`: 165 posicoes exportaveis e 165 valores na linha
- `di159`: 214 posicoes exportaveis e 214 valores na linha

Conclusao atual:

- o erro de load nao e incompatibilidade basica de schema

## 18. Estado atual do versionamento

Remoto principal:

- `https://github.com/sursum-git/motor-progress.git`

Branch de trabalho atual conhecida:

- `master`

Importante:

- `db/` deve ser tratado como local e esta ignorado no `.gitignore`

## 19. Regras de continuidade para outra instalacao do Codex

Se outro Codex assumir:

- comecar pelos arquivos de contexto em `.codex/context/`
- nao assumir que `D:\opencode\motor-progress` existe na nova maquina
- adaptar comandos locais aos novos paths
- preservar a arquitetura e as decisoes de UX/contexto

## 20. Resumo operacional curto

Se for preciso retomar muito rapido:

- abrir `web/index.html`
- configurar contexto em `web/context-selector.html`
- usar `sursumpasoedev`
- lembrar do limite `pageSize <= 500`
- parar PASOE antes de rotinas `_progres.exe` em bancos `-1`
- tratar `db/` como local

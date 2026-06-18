# Contexto da Interface Web

Atualizado em 2026-06-18.

## Entrada e carregamento visual

Entrada principal:

```text
web/index.html
```

URL em uso:

```text
http://php81.imatextil.com.br/motor-progress/web/index.html
```

O shell usa menu lateral Kendo TreeView e carrega paginas em iframe via `?page=...`.

Padrao visual atual:

- Paginas carregam com `body.sursum-ui-pending`.
- `web/ui-ready.css` oculta a tela ate os widgets Kendo serem aplicados.
- `web/ui-ready.js` revela a pagina com `SursumUiReady`.
- Grids usam `SursumGridLoading` e `kendo.ui.progress` centralizado dentro do grid durante AJAX.

## Menu atual

Arquivos:

```text
menu-pages.json
web/menu-pages.json
```

Itens principais:

- Inicio: `context-selector.html`
- Consultas: `query-builder.html`, `query-wizard-3steps.html`, `query-list.html`, `query-result.html`, `query-file-runner.html`
- Metadados: `table-browser.html`, `metadata-maintenance.html`, `field-metadata-config.html`, `metadata-storage-config.html`, `database-alias-config.html`
- Logica: `logic-list.html`, `logic-builder.html`
- Configuracao: `client-config.html`

## Contexto

Modulo:

```text
web/context-manager.js
```

Persistencia principal:

```text
web/context-store.php
web/sursum-conf/sursum.sqlite
```

LocalStorage ainda existe como cache/fallback e para chaves legadas:

```text
sursumContextV4
sursumContextV3
sursumApiEndpoints
sursumSelectedClientId
sursumSelectedEnvironment
sursumSelectedCompanyId
```

O appbar do shell mostra cliente e ambiente. Paginas internas nao devem recriar um painel de contexto completo; devem usar `SursumContext`.

## Cadastro de clientes, ambientes e empresas

Pagina:

```text
web/client-config.html
```

Comportamento:

- Grid de clientes contem botao de linha `Ambientes`.
- O botao abre uma janela Kendo maximizada com os ambientes do cliente.
- A janela de ambientes tem botao `Novo ambiente` e botoes de linha `Alterar`, `Remover` e `Empresas`.
- Incluir/alterar ambiente abre janela Kendo maximizada.
- Empresas do ambiente tambem abrem em janela Kendo maximizada.
- O cadastro de empresa possui `name`, `code` e `pathParam`.

Campos de ambiente:

- nome
- URL base
- servidor SSH
- usuario SSH
- senha SSH
- arquivo PF
- arquivo alias

Regra de endpoint:

- URL base do ambiente pode conter `{empresa}`.
- `pathParam` da empresa substitui `{empresa}`.
- `code` da empresa e numerico e nao faz parte do path; pode ser enviado como query `companyId`.

## Table browser

Pagina:

```text
web/table-browser.html
```

Recursos:

- Empresa, banco e tabela.
- Botao com icone de busca ao lado do campo tabela abre janela com tabelas disponiveis.
- `Buscar Metadados` carrega a tabela escolhida.
- `Atualizar metadados` sincroniza metadados no PASOE conforme checks marcados.
- Checks padrao marcados: bancos, aliases, tabelas, campos, indices e view-as.
- Layout separa a busca da sincronizacao.
- Abas: Campos, Indices, Joins, Dados.
- Aba Joins possui `Atualizar joins OF` da tabela corrente.
- Aba Dados usa `/table-browse` para paginar registros por chave/cursor.

Observacao de UX:

- O campo banco ainda usa `TODOS` nessa pagina.
- Em `metadata-maintenance.html`, a opcao equivalente foi renomeada para `Selecionar`.

## Manutencao de metadados

Pagina:

```text
web/metadata-maintenance.html
```

Abas:

- Atualizacao em lote
- View-as manual
- Join manual

Atualizacao em lote:

- Switches estilo iPhone.
- `Execucoes simultaneas`, valor inicial `1`.
- `Metadado existente`: `Desconsiderar` ou `Atualizar`.
- Botoes: `Cancelar pendentes`, `Reprocessar tudo`, `Criar fila`, `Executar`, `Pausar`.
- Grid com status, mensagem, contadores de joins/view-as, cancelamento e reprocessamento por linha.
- Filtros para pendentes e erros.

View-as manual:

- Incluir e alterar em janela.
- Excluir por botao na linha do grid.
- Importar CSV.
- Datas do grid em formato brasileiro.

Join manual:

- Incluir e alterar em janela.
- Excluir por botao na linha do grid.

## Query builder

Arquivos:

```text
web/query-builder.html
web/query-builder.js
web/query-builder.css
```

Regras:

- Fontes exigem banco, tabela e alias.
- Busca de tabelas usa cache por banco.
- Relacoes entre fontes devem impedir mesma tabela dos dois lados.
- Duplicidade de relacao direta e invertida deve ser bloqueada.
- Dados de relacoes salvas vem do SQLite, nao de arquivos JSON.

## Autenticacao

Arquivos:

```text
web/auth.php
web/login.html
web/auth-guard.js
```

Modos:

- `ldap`
- `local`
- `ldap-local`

Configuracao:

```text
web/sursum-conf/auth.json
```

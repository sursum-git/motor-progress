# Contexto da Interface Web

## Paginas

Construtor visual:

```text
web/query-builder.html
web/query-builder.js
web/query-builder.css
```

Lista de consultas:

```text
web/query-list.html
web/query-list.js
```

Resultado:

```text
web/query-result.html
web/query-result.js
```

Cadastro de endpoints:

```text
web/endpoint-config.html
web/endpoint-config.js
```

## Bibliotecas

- Kendo UI local em `web/vendor/kendo`.
- jQuery local em `web/vendor/jquery/jquery-4.0.0.min.js`.
- Licenca Kendo aplicada por `web/vendor/kendo/kendo-license.js`.

## Wizard atual

Etapas:

```text
1. Metadados
2. Fontes
3. Selecao
4. Filtros
5. Ordenacao
6. Relacoes
7. Pipeline
8. JSON
```

## Fontes

Na etapa 2:

- Banco da fonte.
- Tabela.
- Alias.
- Botao `Buscar tabela`.
- Botao `Carregar tabela`.
- Botao `Adicionar fonte`.

Regras:

- Nao deve adicionar fonte sem banco.
- Nao deve adicionar tabela inexistente.
- A validacao usa os metadados carregados.

## Busca de tabelas

A janela de busca mostra:

```text
codigo da tabela
descricao
dump-name
banco
```

O cache em memoria e por banco:

```javascript
state.tableSearchCache[database]
```

Quando os metadados sao recarregados, esse cache deve ser limpo.

## Campos

Campos sao carregados ao selecionar/carregar tabela e ao avancar para etapas que dependem de campos.

Para tabelas grandes do `ems2med`, o endpoint de campos deve responder rapidamente porque o backend filtra por `_File-Recid`.

## Relacoes

Na etapa 6:

- Tabela esquerda e direita devem ser combos baseados nas fontes adicionadas.
- Ao selecionar uma tabela, o banco correspondente e preenchido.
- Nao deve permitir mesma tabela dos dois lados.
- Nao deve permitir relacao repetida.
- Relacao repetida invertida tambem deve ser bloqueada.

Exemplo bloqueado:

```text
ems2med.ped-venda x ems2med.ped-venda
```

Exemplo de duplicidade invertida:

```text
ped-venda.nr-pedido -> ped-item.nr-pedido
ped-item.nr-pedido -> ped-venda.nr-pedido
```

## Armazenamento atual

Parte da configuracao ainda usa `localStorage` como fallback:

```text
sursumCurrentQueryJson
sursumSavedQueries
sursumApiEndpoints
sursumSelectedCompany
sursumSelectedApiEndpoint
```

Direcao desejada:

- Dados devem migrar para arquivos.
- Consultas devem ser salvas por empresa/cliente.
- Endpoints devem ser cadastrados por empresa/cliente.

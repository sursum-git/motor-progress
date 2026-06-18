# Contexto de Sessao - Table Browser e Cursor/Keyset

Atualizado em 2026-06-18.

Este arquivo era uma nota de pendencia de 2026-06-12. A pendencia principal foi implementada.

## Estado atual

O endpoint existe:

```text
POST /web/SursumDynamicQuery/table-browse
```

A pagina tambem existe:

```text
web/table-browser.html
web/table-browser.js
```

A aba `Dados` permite:

- escolher campos exibidos;
- definir quantidade de registros;
- escolher ordem `ASC` ou `DESC`;
- carregar primeiros registros;
- carregar proximos registros;
- inverter ordem;
- exibir campos de chave/cursor;
- usar `nextCursor` retornado pelo backend.

## Contexto canonico

Para retomada, usar os arquivos:

```text
context/PROJECT_CONTEXT.md
context/API_QUERY_ENGINE_CONTEXT.md
context/OPENEDGE_PASOE_CONTEXT.md
context/ASYNC_PIPELINE_CONTEXT.md
context/WEB_QUERY_BUILDER_CONTEXT.md
context/DATABASE_CONTEXT.md
```

## Regras que continuam validas

- Nao usar contagem total como base do fluxo principal do navegador de tabelas.
- Usar navegacao incremental por cursor/keyset.
- Preferir indice primario ativo; se nao houver, usar indice unico ativo; se nao houver, usar indice ativo adequado.
- Para chave composta, cursor deve representar todos os campos da chave.
- `DynamicQueryWebHandler.cls` da raiz deve permanecer sincronizado com `sursum-api/rest/DynamicQueryWebHandler.cls`.
- Ao alterar fonte Progress, compilar em `192.168.0.42` e publicar `.r` no runtime antes de validar no PASOE.

## Backlog relacionado

- Ampliar testes automaticos do `table-browse` para chave composta e campos `extent`.
- Manter mensagens claras para chave ausente, tabela invalida, campo invalido e cursor incompleto.

# Contexto de Sessao - Table Browser com Cursor/Keyset

Data: 2026-06-12

## Objetivo pendente

Adaptar o backend e o frontend da pagina `table-browser` para navegar dados de uma tabela usando paginacao por cursor/keyset, sem depender de contagem total de registros.

Esta pendencia nao foi executada nesta sessao porque o executor de comandos local passou a falhar antes de iniciar qualquer processo, inclusive `pwd`, `bash`, `sh`, `sed` e `rg`, com erro:

```text
CreateProcess ... Rejected("Failed to create unified exec process: No such file or directory (os error 2)")
```

Sem acesso operacional ao workspace, nao foi possivel ler os arquivos atuais, editar com seguranca, rodar testes, compilar Progress ou testar no PASOE.

## Decisao tecnica

Nao usar paginacao baseada em numero da pagina nem contagem total para o fluxo principal do navegador de tabelas.

Usar navegacao incremental:

- carregar primeiros registros;
- carregar proximos registros;
- inverter ordem para ver os registros finais;
- exigir filtros quando o usuario precisar chegar a um ponto especifico da tabela.

O cursor deve ser formado pelos campos da chave/indice escolhido, incluindo todos os campos quando a chave for composta, como no caso da tabela `nota-fiscal`.

## Backend a implementar

Criar endpoint:

```http
POST /web/SursumDynamicQuery/table-browse
```

Payload sugerido:

```json
{
  "database": "ems2med",
  "table": "nota-fiscal",
  "pageSize": 50,
  "direction": "ASC",
  "fields": ["cod-estabel", "serie", "nr-nota-fis", "dt-emis-nota"],
  "cursor": {
    "cod-estabel": "101",
    "serie": "1",
    "nr-nota-fis": "000123456"
  }
}
```

Resposta sugerida:

```json
{
  "success": true,
  "database": "ems2med",
  "table": "nota-fiscal",
  "direction": "ASC",
  "pageSize": 50,
  "recordsReturned": 50,
  "hasMore": true,
  "keyFields": [
    {
      "name": "cod-estabel",
      "type": "character",
      "ascending": true
    }
  ],
  "fields": [
    {
      "name": "cod-estabel",
      "type": "character"
    }
  ],
  "data": [],
  "nextCursor": {
    "cod-estabel": "101",
    "serie": "1",
    "nr-nota-fis": "000123456"
  },
  "strategy": "KEYSET_CURSOR"
}
```

### Regras do backend

- Validar `database`, `table` e nomes de campos com a mesma regra de identificadores ja usada no projeto.
- Usar dicionario dinamico da base informada para descobrir campos e indices.
- Preferir indice primario ativo.
- Se nao houver primario, usar indice unico ativo.
- Se nao houver unico, usar primeiro indice ativo nao word-index.
- Se nao houver indice adequado, retornar erro claro, por exemplo `BROWSE_KEY_NOT_FOUND`.
- Para chave composta, o cursor deve conter todos os campos da chave.
- A condicao do cursor deve seguir a forma lexicografica:

```text
(k1 > v1)
OR (k1 = v1 AND k2 > v2)
OR (k1 = v1 AND k2 = v2 AND k3 > v3)
```

- Para direcao `DESC`, inverter operadores para `<`.
- Buscar `pageSize + 1` registros para determinar `hasMore`.
- Nao aplicar limite fixo antigo de 500 registros como limite global. O `pageSize` pode continuar limitado por seguranca, por exemplo 1 a 500 por requisicao.
- Tratar campos `extent`. O frontend deve poder solicitar um extent especifico de um campo.

## Frontend a implementar

Arquivo principal: `web/table-browser.js`

Pagina: `web/table-browser.html`

Adicionar na pagina `table-browser`:

- aba ou secao `Dados`;
- grid para dados retornados pelo backend;
- campo `pageSize`;
- seletor de direcao `ASC` / `DESC`;
- botao para carregar primeiros registros;
- botao para carregar proximos registros;
- botao para inverter ordem;
- exibicao discreta dos campos usados como chave/cursor;
- estado visual para `hasMore`.

Fluxo esperado:

1. Usuario seleciona uma tabela.
2. Frontend carrega metadados dos campos como hoje.
3. Usuario abre a aba de dados e clica em carregar.
4. Frontend chama `POST /table-browse` sem cursor.
5. Backend retorna dados e `nextCursor`.
6. Ao clicar em proximos, frontend envia o `nextCursor`.
7. Para ver registros finais, usuario inverte a ordem e carrega a primeira pagina em `DESC`.

## Suporte a extent

Foi solicitado implementar suporte a campos `extent` e verificar se o frontend precisa permitir selecionar um extent especifico.

Direcao recomendada:

- No backend, ao serializar campo extent, permitir referencia como:

```json
{
  "name": "campo",
  "extent": 1
}
```

ou uma forma textual compativel com o frontend, por exemplo `campo[1]`.

- No frontend, quando o metadado indicar extent maior que 0, permitir selecionar:
  - campo completo, se fizer sentido;
  - ou um item por posicao: `campo[1]`, `campo[2]`, etc.

## Situacao do backend atual antes da pendencia

Ja havia sido implementado anteriormente:

- endpoint `GET /web/SursumDynamicQuery/count`;
- contagem por `PRESELECT EACH <database>.<table> NO-LOCK` e `NUM-RESULTS`;
- retorno com tempos internos de abertura da query e `NUM-RESULTS`;
- compilacao e publicacao no ambiente Progress em sessao anterior.

Resultados observados:

- `ems2cad.emitente`: 39.527 registros, tempo interno aproximado 117 ms, HTTP aproximado 182 ms.
- `ems2med.ped-venda`: 287.293 registros, tempo interno aproximado 719 ms, HTTP aproximado 790 ms.
- `ems2med.nota-fiscal`: 244.804 registros, tempo interno aproximado 770 ms, HTTP aproximado 843 ms.
- `ems2med.ped-item`: contagem nao retornou em mais de 60 segundos.
- `espec.transacoes`: contagem nao retornou em 30 segundos.

Conclusao: contagem total pode ser aceitavel para algumas tabelas, mas nao deve ser base do fluxo principal do table-browser.

## Arquivos Progress relevantes

- `sursum-api/rest/DynamicQueryWebHandler.cls`
- `DynamicQueryWebHandler.cls`

Observacao importante:

- O handler raiz `DynamicQueryWebHandler.cls` precisa estar sincronizado com `sursum-api/rest/DynamicQueryWebHandler.cls`.
- O arquivo raiz deve ser publicado em `T:\sursum\DynamicQueryWebHandler.r`, porque o PASOE procura a classe no PROPATH sem subpasta.
- Evitar caminhos absolutos como `d:\...`; toda busca de arquivo deve usar `SEARCH()`.

## Skill obrigatoria para Progress

Sempre que criar ou alterar fontes Progress/OpenEdge neste projeto, usar a skill:

```text
sursum-progress-compile
```

Fluxo registrado:

- copiar fontes alterados para o host Windows `192.168.0.42`;
- compilar com OpenEdge no workspace `C:\opencode\motor-progress`;
- publicar `.r` em `T:\sursum`;
- validar logs de compilacao;
- testar endpoint no PASOE.

Dados conhecidos:

- host de compilacao: `192.168.0.42`;
- usuario: `tadeu.parreiras`;
- workspace: `C:\opencode\motor-progress`;
- compilador: `C:\Progress_12\OE\bin\_progres.exe`;
- banco local de compilacao: `C:\opencode\motor-progress\db\sports2000`;
- flags conhecidas: `-1 -ld DICTDB`;
- PASOE de teste informado: `https://192.168.0.111:9911/med/web/SursumDynamicQuery`.

Scripts existentes citados em sessoes anteriores:

- `temp/CompilePathFixAndRootHandler.p`
- `temp/CopyPathFixToTSursum.ps1`
- `temp/CopyCompiledRToTSursum.ps1`

## Testes necessarios apos implementar

Rodar:

```bash
node --check web/table-browser.js
npm run test:all
```

Compilar Progress via skill e validar log com erro zero.

Testes manuais/API no PASOE:

- `POST /table-browse` para `ems2cad.emitente`, `pageSize` pequeno, primeira pagina.
- `POST /table-browse` para `ems2cad.emitente` com `nextCursor`, segunda pagina sem duplicar o ultimo registro da primeira.
- `POST /table-browse` para `ems2med.nota-fiscal`, validando chave composta.
- `POST /table-browse` para `ems2med.nota-fiscal` em `DESC`.
- testar tabela invalida.
- testar campo invalido.
- testar cursor incompleto para chave composta e retornar erro claro.

## Roadmap ja solicitado para consultas salvas/workers

Registrar em documentacao permanente do projeto, se ainda nao estiver registrado:

- armazenamento de consultas salvas por codigo em JSON;
- status da consulta salva: `draft` e `ready`;
- filtros externos permitidos por consulta salva;
- seguranca futura por client, tokens, IPs permitidos, endpoints e permissoes;
- suporte futuro a consultas executadas por workers;
- client podera enviar webhook para receber aviso de termino;
- payload do webhook deve incluir:
  - identificador da execucao;
  - status;
  - inicio;
  - fim;
  - erro, quando houver;
  - informacoes adicionais;
  - conteudo do resultado da consulta;
- criar endpoint PASOE para o client buscar a situacao de uma execucao;
- endpoint de situacao deve retornar o mesmo conteudo enviado ao webhook.


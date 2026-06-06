# Interfaces web Kendo UI

O projeto possui paginas HTML estaticas para facilitar o uso por analistas.

Assets locais:

```text
web/vendor/kendo
web/vendor/jquery/jquery-4.0.0.min.js
```

Kendo UI foi copiado de:

```text
D:\opencode\adianti-kendo\kendo
```

jQuery 4.0.0 foi baixado do CDN oficial:

```text
https://code.jquery.com/jquery-4.0.0.min.js
```

## Query Builder / Designer

Arquivo:

```text
web/query-builder.html
```

Finalidade:

- montar requests simples;
- montar requests com fontes, campos, filtros e ordenacao;
- montar pipeline visualmente;
- gerar preview JSON;
- consultar metadados via API PASOE para listar tabelas e campos;
- selecionar o banco logico para navegar metadados;
- definir o banco logico em cada fonte da consulta, permitindo relacionar tabelas de bancos diferentes;
- salvar e reutilizar relacoes entre tabelas em arquivos JSON segregados por banco;
- enviar o JSON atual para a pagina separada de resultado.

Endpoint base padrao:

```text
http://localhost:8890/web/SursumDynamicQuery
```

Endpoints usados pelo designer:

```text
GET  /web/SursumDynamicQuery/metadata/databases
GET  /web/SursumDynamicQuery/metadata/cache-status?database=DICTDB
GET  /web/SursumDynamicQuery/metadata/tables?database=DICTDB
GET  /web/SursumDynamicQuery/metadata/tables/{table}/fields?database=DICTDB
POST /web/SursumDynamicQuery/metadata/relations
GET  /web/SursumDynamicQuery/metadata/relations/{left}/{right}?database=DICTDB
```

As relacoes sao salvas no servidor em:

```text
conf/relations/bancoA__tabelaA__bancoB__tabelaB.json
```

O nome dos bancos fica junto das tabelas para evitar colisao quando bancos diferentes possuem tabelas com o mesmo nome. Banco, tabelas e arquivo sao normalizados em minusculo. A ordem das pontas da relacao no nome do arquivo e alfabetica para permitir reutilizacao independente da ordem em que a relacao foi pesquisada.

Metadados carregados tambem sao salvos no servidor:

```text
conf/metadata/banco__tables.json
conf/metadata/banco__tabela__fields.json
```

Na entrada da pagina, o designer chama `metadata/cache-status`. Se nao existir cache de tabelas para o banco selecionado, a carga inicial e disparada automaticamente e o progresso aparece visualmente. O botao `Carregar metadados` passa a ser o comando de atualizacao, consultando novamente os bancos conectados e as tabelas do banco selecionado.

## Query Result

Arquivo:

```text
web/query-result.html
```

Finalidade:

- carregar a consulta enviada pelo designer via `localStorage`;
- selecionar um arquivo `.json` local;
- enviar o JSON para a API PASOE;
- exibir `response.data` em Grid Kendo UI.

Endpoint padrao:

```text
http://localhost:8890/web/SursumDynamicQuery/query
```

## Query File Runner legado

Arquivo:

```text
web/query-file-runner.html
```

Finalidade:

- selecionar um arquivo `.json` local;
- ler o conteudo do arquivo no navegador;
- permitir editar o preview;
- enviar o JSON para a API PASOE;
- exibir o resultado em Grid Kendo UI.

Observacao importante:

O navegador nao envia o caminho fisico real do arquivo por seguranca. A pagina envia o conteudo do arquivo JSON como body HTTP.

## Fluxo recomendado para analistas

1. Abrir `web/query-builder.html`.
2. Selecionar o banco logico de metadados no combo carregado a partir do PASOE, por exemplo `DICTDB`.
3. Selecionar o banco em cada fonte adicionada na consulta.
4. Carregar metadados pelo PASOE e montar a consulta.
5. Salvar relacoes reutilizaveis quando houver join recorrente, informando banco esquerdo e banco direito.
6. Clicar em `Abrir resultado` para enviar o JSON atual para `web/query-result.html`.
7. Executar contra PASOE pela pagina de resultado.
8. Se a extracao precisar rodar em batch, usar o mesmo JSON com `runners/RunDynamicQueryFromJson.p`.

## Relacao com runner batch

O mesmo JSON usado na pagina pode ser executado via batch:

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b `
  -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB `
  -p "D:\opencode\motor-progress\runners\RunDynamicQueryFromJson.p" `
  -param "request=D:\opencode\motor-progress\examples\extractions\customer-simple.json;output=D:\opencode\motor-progress\output\extracts\customer-simple-result.json"
```

## Limitacoes atuais

- A pagina depende do endpoint PASOE estar publicado e respondendo.
- Para abrir direto via `file://`, alguns navegadores podem restringir CORS dependendo da configuracao do PASOE.
- Se houver CORS, sirva a pasta `web/` por um servidor local simples ou publique os arquivos como conteudo estatico no PASOE.

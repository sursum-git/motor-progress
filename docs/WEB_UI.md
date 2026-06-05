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

## Query Builder

Arquivo:

```text
web/query-builder.html
```

Finalidade:

- montar requests simples;
- montar requests com fontes, campos, filtros e ordenacao;
- montar pipeline visualmente;
- gerar preview JSON;
- chamar a API PASOE;
- exibir `response.data` em Grid Kendo UI.

Endpoint padrao:

```text
http://localhost:8890/web/SursumDynamicQuery/query
```

## Query File Runner

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

1. Criar ou abrir um JSON de extracao.
2. Validar visualmente no preview.
3. Executar contra PASOE pela pagina `query-file-runner.html`.
4. Se a extracao precisar rodar em batch, usar o mesmo JSON com `runners/RunDynamicQueryFromJson.p`.

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

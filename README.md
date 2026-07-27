# Motor Progress - Dynamic Query API

Projeto ABL/OOABL para consulta dinamica segura em banco Progress/OpenEdge, com suporte a:

- consulta estruturada por JSON;
- multiplas tabelas com `JOIN` explicito;
- validacao de tabelas, campos, aliases e operadores;
- execucao sincronona (`sync`);
- fila assincrona persistida em banco (`async`);
- worker em `CLIENT` batch ou `PASOE`;
- resultado JSON em arquivo;
- runner generico que recebe arquivo JSON por parametro;
- interface web Kendo UI para desenhar consultas, navegar metadados, manter contexto e renderizar resultados;
- clientes HTML/PHP para executar consultas salvas via query string;
- middleware PHP com SQLite para contexto, autenticacao, metadados e proxy seguro para PASOE;
- endpoint HTTP WEB para validacao local no PASOE;
- benchmarks de paginacao e contagem em tabela grande.

## Objetivo

O objetivo e disponibilizar uma camada de consulta dinamica para API REST TOTVS/PASOE sem permitir SQL/ABL livre.

O request da API descreve fontes, campos, filtros, ordenacao, pagina e pipeline inicial. O motor transforma esse contrato em uma query ABL dinamica segura, sempre usando `NO-LOCK`.

## Decisoes importantes

- `boConsDin.p` e `boMetaDados.p` sao referencia historica, nao fazem parte do fluxo novo.
- O fluxo novo usa classes OOABL em `sursum-api/sursum/`.
- A estrutura local `sursum-api/`, `web/`, `sursum-conf/`, `tests/` e `scripts/` e a estrutura canonica do projeto.
- A API nao deve executar `WHERE`, SQL ou ABL livre vindo do usuario.
- `NO-LOCK` e obrigatorio nas consultas.
- Em chamadas paginadas, a resposta padrao usa `hasMore` em vez de `totalRecords`.
- `totalRecords` exato deve ser opcional, cacheado ou assincrono, porque contagem em Progress pode custar caro.
- Para paginas profundas, a direcao recomendada e migrar de offset para cursor/keyset pagination.
- O `master` remoto do GitHub foi substituido pela estrutura local atual em 2026-07-27; veja `docs/GIT_REMOTE_STATE.md`.

## Estrutura principal

| Caminho | Finalidade |
|---|---|
| `sursum-api/sursum/` | Classes OOABL do motor de consulta |
| `sursum-api/rest/` | Fachadas REST/WEB para PASOE |
| `sursum-api/workers/` | Entradas de worker CLIENT/PASOE e programas APSV auxiliares |
| `sursum-api/runners/` | Executores genericos por arquivo JSON |
| `web/` | Interfaces Kendo UI e assets locais |
| `web/sursum-conf/` | SQLite e arquivos operacionais usados pelo PHP publicado |
| `sursum-conf/` | Configuracao operacional raiz e consultas salvas |
| `scripts/` | Scripts de deploy e operacao |
| `tests/e2e/` | Contratos PHP e testes Playwright |
| `db/` | Schemas `.df` e loaders da fila async |
| `temp/` | Programas locais de validacao, benchmark e smoke test |
| `conf/pasoe/` | Referencia de configuracao da instancia PASOE local |
| `conf/relations/` | Relacoes reutilizaveis entre tabelas em JSON |
| `ABL_Context/` | Material de apoio sobre sintaxe ABL/OOABL |
| `docs/` | Documentacao detalhada do projeto |

## Inicio rapido

### 1. Compilar fontes principais

Com o PASOE parado, execute:

```powershell
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b `
  -db 'D:\opencode\motor-progress\db\sports2000' -1 -ld DICTDB `
  -p 'temp\ValidateSursumCurrent.p'
```

Sem saida no terminal significa compilacao sem erro.

### 2. Subir PASOE local

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' start -I sursumpasoedev
```

### 3. Criar uma consulta async via HTTP

```powershell
$body = @'
{
  "execution": "async",
  "page": 1,
  "pageSize": 25,
  "defaultBanco": "DICTDB",
  "sources": [
    { "nome": "Customer", "alias": "", "banco": "DICTDB", "campos": "CustNum,Name,City,State" }
  ],
  "joins": [],
  "select": [],
  "filters": [],
  "orderBy": [],
  "pipeline": []
}
'@

Invoke-RestMethod `
  -Method Post `
  -Uri 'http://localhost:8890/web/SursumDynamicQuery/query' `
  -ContentType 'application/json' `
  -Body $body
```

### 4. Processar fila no PASOE

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri 'http://localhost:8890/web/SursumDynamicQuery/jobs/drain'
```

## Documentacao detalhada

- [Arquitetura](docs/ARCHITECTURE.md)
- [Contrato da API](docs/API_CONTRACT.md)
- [Executor por arquivo JSON](docs/JSON_EXTRACTION_RUNNER.md)
- [Interfaces web Kendo UI](docs/WEB_UI.md)
- [Fila async e workers](docs/ASYNC_QUEUE.md)
- [Setup local e PASOE](docs/SETUP_PASOE.md)
- [Benchmarks e paginacao](docs/BENCHMARKS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Estado Git e remoto](docs/GIT_REMOTE_STATE.md)

## Extracoes por arquivo JSON

O fluxo recomendado para muitas extracoes e criar um arquivo `.json` por consulta/pipeline e executar o runner generico:

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b `
  -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB `
  -p "D:\opencode\motor-progress\sursum-api\runners\RunDynamicQueryFromJson.p" `
  -param "request=D:\opencode\motor-progress\examples\extractions\customer-simple.json;output=D:\opencode\motor-progress\output\extracts\customer-simple-result.json"
```

Assim uma nova extracao exige apenas um novo arquivo JSON, sem recompilar programa ABL especifico.

## Interfaces web

Paginas locais principais:

```text
web/index.html
web/context-selector.html
web/metadata-maintenance.html
web/query-builder.html
web/query-result.html
web/query-file-runner.html
web/container-client.html
web/saved-query-client.html
```

- `index.html`: shell principal com menu lateral e contexto ativo.
- `query-builder.html`: monta visualmente requests simples, multi-tabela e pipelines usando metadados do PASOE.
- `query-result.html`: executa a consulta enviada pelo designer ou por arquivo JSON e mostra o resultado em Grid Kendo UI.
- `query-file-runner.html`: pagina legada para ler um arquivo JSON, chamar a API PASOE e mostrar o resultado.
- `container-client.html`: exemplo especifico para executar a consulta salva `pp-it-container-por-container` usando `nr-container` na query string.
- `saved-query-client.html`: cliente generico para executar qualquer consulta salva por `queryId` e parametros de query string.

Exemplo publicado em homologacao:

```text
http://iol.imatextil.com.br/query-progress/saved-query-client.html?queryId=pp-it-container-por-container&nr-container=1650
```

## Deploy query-progress

Publicacao homologacao:

```bash
DEPLOY_PASSWORD='...' ./scripts/deploy_query_progress_192_168_0_39.sh
```

Destino padrao:

```text
suporte_ima@192.168.0.39:/var/www/clients/client1/web7/web/query-progress/
```

O script sincroniza `web/` e ajusta permissao de `sursum-conf` para o PHP-FPM conseguir escrever no SQLite.

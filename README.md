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
- interface web Kendo UI separada para desenhar consultas e renderizar resultados;
- endpoint HTTP WEB para validacao local no PASOE;
- benchmarks de paginacao e contagem em tabela grande.

## Objetivo

O objetivo e disponibilizar uma camada de consulta dinamica para API REST TOTVS/PASOE sem permitir SQL/ABL livre.

O request da API descreve fontes, campos, filtros, ordenacao, pagina e pipeline inicial. O motor transforma esse contrato em uma query ABL dinamica segura, sempre usando `NO-LOCK`.

## Decisoes importantes

- `boConsDin.p` e `boMetaDados.p` sao referencia historica, nao fazem parte do fluxo novo.
- O fluxo novo usa classes OOABL em `sursum/`.
- A API nao deve executar `WHERE`, SQL ou ABL livre vindo do usuario.
- `NO-LOCK` e obrigatorio nas consultas.
- Em chamadas paginadas, a resposta padrao usa `hasMore` em vez de `totalRecords`.
- `totalRecords` exato deve ser opcional, cacheado ou assincrono, porque contagem em Progress pode custar caro.
- Para paginas profundas, a direcao recomendada e migrar de offset para cursor/keyset pagination.

## Estrutura principal

| Caminho | Finalidade |
|---|---|
| `sursum/` | Classes OOABL do motor de consulta |
| `rest/` | Fachadas REST/WEB para PASOE |
| `workers/` | Entradas de worker CLIENT/PASOE e programas APSV auxiliares |
| `runners/` | Executores genericos por arquivo JSON |
| `web/` | Interfaces Kendo UI e assets locais |
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

## Extracoes por arquivo JSON

O fluxo recomendado para muitas extracoes e criar um arquivo `.json` por consulta/pipeline e executar o runner generico:

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b `
  -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB `
  -p "D:\opencode\motor-progress\runners\RunDynamicQueryFromJson.p" `
  -param "request=D:\opencode\motor-progress\examples\extractions\customer-simple.json;output=D:\opencode\motor-progress\output\extracts\customer-simple-result.json"
```

Assim uma nova extracao exige apenas um novo arquivo JSON, sem recompilar programa ABL especifico.

## Interfaces web

PÃ¡ginas locais:

```text
web/query-builder.html
web/query-result.html
web/query-file-runner.html
```

- `query-builder.html`: monta visualmente requests simples, multi-tabela e pipelines usando metadados do PASOE.
- `query-result.html`: executa a consulta enviada pelo designer ou por arquivo JSON e mostra o resultado em Grid Kendo UI.
- `query-file-runner.html`: pagina legada para ler um arquivo JSON, chamar a API PASOE e mostrar o resultado.


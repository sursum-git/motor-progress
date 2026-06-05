# Motor Progress - Dynamic Query API

Projeto ABL/OOABL para consulta dinamica segura em banco Progress/OpenEdge, com suporte a:

- consulta estruturada por JSON;
- multiplas tabelas com `JOIN` explicito;
- validacao de tabelas, campos, aliases e operadores;
- execucao sincronona (`sync`);
- fila assincrona persistida em banco (`async`);
- worker em `CLIENT` batch ou `PASOE`;
- resultado JSON em arquivo;
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
| `db/` | Schemas `.df` e loaders da fila async |
| `temp/` | Programas locais de validacao, benchmark e smoke test |
| `conf/pasoe/` | Referencia de configuracao da instancia PASOE local |
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
- [Fila async e workers](docs/ASYNC_QUEUE.md)
- [Setup local e PASOE](docs/SETUP_PASOE.md)
- [Benchmarks e paginacao](docs/BENCHMARKS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)


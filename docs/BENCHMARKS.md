# Benchmarks e paginacao

## Massa de dados

Foi criado programa para popular `Customer`:

```text
temp/SeedCustomer2M.p
```

Resultado observado:

| Item | Valor |
|---|---:|
| Registros adicionados | 2.000.000 |
| `CustNum` inicial novo | 2107 |
| `CustNum` final novo | 2002106 |
| Tempo de carga | 1.676.093 ms |
| Tempo aproximado | 27m56s |

Total posterior em `Customer`:

```text
2.001.117 registros
```

## Benchmark de paginacao HTTP

Endpoint:

```http
POST /web/SursumDynamicQuery/query
```

Request usado:

```json
{
  "execution": "sync",
  "page": 1,
  "pageSize": 100,
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
```

Resultados observados com `pageSize = 100`:

| Pagina | Tempo | Registros | `hasMore` |
|---:|---:|---:|---|
| 1 | 299 ms | 100 | true |
| 10 | 38 ms | 100 | true |
| 100 | 56 ms | 100 | true |
| 1000 | 237 ms | 100 | true |
| 5000 | 1000 ms | 100 | true |
| 10000 | 1961 ms | 100 | true |
| 20000 | 3914 ms | 100 | true |
| 20012 | 3956 ms | 18 | false |

## Interpretacao

A API nao faz `COUNT` no caminho padrao.

Mesmo assim, paginas profundas ficam mais lentas porque a paginacao atual e baseada em offset:

```text
page=20000&pageSize=100
```

Isso exige avancar no cursor ate a posicao desejada.

## Recomendacao de paginacao

Para grandes volumes, preferir cursor/keyset pagination.

Em vez de:

```json
{
  "page": 20000,
  "pageSize": 100
}
```

usar algo como:

```json
{
  "pageSize": 100,
  "cursor": {
    "CustNum": 2000988
  }
}
```

Query conceitual:

```abl
FOR EACH Customer NO-LOCK
  WHERE Customer.CustNum > piAfterCustNum
  BY Customer.CustNum:
```

Vantagem:

- tempo quase constante por pagina;
- nao precisa pular milhoes de registros;
- melhor para API stateless.

## Benchmark de contagem

Programas:

| Programa | Ambiente |
|---|---|
| `temp/BenchmarkCustomerCountMethods.p` | CLIENT/batch |
| `workers/BenchmarkCustomerCountOnServer.p` | PASOE via `ON SERVER` |
| `temp/RunBenchmarkCustomerCountOnServer.p` | Runner client APSV |
| `GET /web/SursumDynamicQuery/benchmarks/customer-count` | PASOE via HTTP WEB |

## CLIENT/batch

Resultado:

| Metodo | Resultado | Tempo |
|---|---:|---:|
| `FOR EACH Customer NO-LOCK` | 2.001.117 | 2.261 ms |
| `OPEN QUERY PRESELECT EACH Customer NO-LOCK` | 2.001.117 | 2.108 ms |
| `NUM-RESULTS("qCustomer")` | 2.001.117 | 0 ms |

## PASOE HTTP WEB

Resultado:

| Metodo | Resultado | Tempo interno |
|---|---:|---:|
| `FOR EACH Customer NO-LOCK` | 2.001.117 | 2.446 ms |
| `OPEN QUERY PRESELECT EACH Customer NO-LOCK` | 2.001.117 | 2.304 ms |
| `NUM-RESULTS("qBenchCustomer")` | 2.001.117 | 0 ms |
| Chamada HTTP completa | - | 5.070 ms |

## PASOE APSV / ON SERVER

Resultado:

| Metodo | Resultado | Tempo interno |
|---|---:|---:|
| `FOR EACH Customer NO-LOCK` | 2.001.117 | 2.537 ms |
| `OPEN QUERY PRESELECT EACH Customer NO-LOCK` | 2.001.117 | 2.338 ms |
| `NUM-RESULTS("qBenchCustomer")` | 2.001.117 | 0 ms |
| Chamada total `RUN ... ON SERVER` | - | 4.890 ms |

Rodada posterior restaurada em `-1`:

| Metodo | Tempo |
|---|---:|
| `FOR EACH` | 2.416 ms |
| `PRESELECT` | 2.238 ms |
| `NUM-RESULTS` | 0 ms |
| Chamada total `ON SERVER` | 4.670 ms |

## Conclusao sobre `PRESELECT + NUM-RESULTS`

`NUM-RESULTS` e instantaneo depois do `PRESELECT`.

O custo real esta aqui:

```abl
OPEN QUERY qBenchCustomer PRESELECT EACH Customer NO-LOCK.
```

Portanto:

- `PRESELECT + NUM-RESULTS` pode ser um pouco mais rapido que `FOR EACH`;
- ainda precisa montar o conjunto de resultados;
- em API stateless, pode ser caro fazer isso em toda requisicao;
- nao deve ser default para paginacao.

## Recomendacao sobre `totalRecords`

Contrato recomendado:

```json
{
  "recordsReturned": 100,
  "hasMore": true
}
```

Se precisar total:

```json
{
  "includeTotal": true
}
```

Politica recomendada:

- `includeTotal=false` por default;
- `includeTotal=true` pode acionar async/cache;
- evitar count exato no caminho sync padrao;
- cachear totais por tabela/plano/filtro quando fizer sentido.


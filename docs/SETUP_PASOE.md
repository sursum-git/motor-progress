# Setup local e PASOE

## Pre-requisitos

- Progress/OpenEdge instalado.
- Caminho usado no ambiente local:

```text
C:\Progress\OpenEdge\bin
```

- Workspace:

```text
D:\opencode\motor-progress
```

- Banco local:

```text
D:\opencode\motor-progress\db\sports2000
```

## Criar banco sports2000

O banco fisico local nao e versionado.

Arquivos fisicos ignorados:

```text
db/*.db
db/*.d1
db/*.d2
db/*.b1
db/*.b2
db/*.lg
db/*.lk
```

O arquivo `.st` pode ser versionado como referencia.

## Carregar schema da fila

Programas:

```text
db/LoadSursumAsyncQueue.p
db/LoadSursumAsyncQueueJobStatusDelta.p
db/LoadSursumAsyncQueueJsonFieldsDelta.p
```

Exemplo:

```powershell
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b `
  -db 'D:\opencode\motor-progress\db\sports2000' -1 -ld DICTDB `
  -p 'db\LoadSursumAsyncQueue.p'
```

## Compilar fontes

Com o PASOE parado:

```powershell
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b `
  -db 'D:\opencode\motor-progress\db\sports2000' -1 -ld DICTDB `
  -p 'temp\ValidateSursumCurrent.p'
```

Se nao houver saida, a compilacao passou.

## PASOE local

Instancia usada:

```text
sursumpasoedev
```

Portas configuradas:

| Porta | Uso |
|---:|---|
| `8890` | HTTP |
| `8891` | HTTPS/admin auxiliar |
| `8892` | shutdown |
| `8893` | jmx/admin auxiliar |

Criacao de referencia:

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' create `
  -p 8890 -P 8891 -s 8892 -j 8893 `
  -Z dev `
  -N sursumpasoedev `
  'D:\opencode\motor-progress\pasoe\sursum-pasoe-dev'
```

## Configuracao do banco no PASOE

Modo atual local:

```text
-db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB
```

Esse modo e `single-user/direct access`.

Consequencia:

- PASOE segura o banco;
- para compilar localmente com `_progres -1`, pare o PASOE antes;
- nao e representativo de producao multiusuario.

## Subir PASOE

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' start -I sursumpasoedev
```

## Parar PASOE

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' stop -I sursumpasoedev
```

O script pode emitir:

```text
Get-WmiObject : Acesso negado
```

Esse aviso foi observado no ambiente local e nao impediu o stop/start quando a mensagem principal indicou sucesso.

## PROPATH esperado

Itens importantes:

```text
D:\opencode\motor-progress\sursum
D:\opencode\motor-progress\rest
D:\opencode\motor-progress\workers
D:\opencode\motor-progress\sursum\esp
D:\opencode\motor-progress
C:\Progress\OpenEdge\tty\netlib\OpenEdge.Net.pl
```

`OpenEdge.Net.pl` e necessario para classes:

```text
OpenEdge.Web.WebResponse
OpenEdge.Web.WebResponseWriter
```

## Endpoints locais

| Endpoint | Finalidade |
|---|---|
| `POST /web/SursumDynamicQuery/query` | Executar/enfileirar consulta |
| `POST /web/SursumDynamicQuery/jobs/drain` | Rodar worker PASOE |
| `GET /web/SursumDynamicQuery/jobs/{jobId}` | Status do job |
| `GET /web/SursumDynamicQuery/jobs/{jobId}/result` | Resultado JSON |
| `GET /web/SursumDynamicQuery/benchmarks/customer-count` | Benchmark de contagem |

## APSV / ON SERVER

URL usada:

```text
http://localhost:8890/apsv
```

Runner de benchmark:

```text
temp/RunBenchmarkCustomerCountOnServer.p
```

Programa executado no PASOE:

```text
workers/BenchmarkCustomerCountOnServer.p
```

## Shared memory e TCP

Modo `single-user` atual:

```text
-db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB
```

Modo shared memory/self-service desejado:

```text
-db D:\opencode\motor-progress\db\sports2000 -ld DICTDB
```

Modo TCP desejado:

```text
-db D:\opencode\motor-progress\db\sports2000 -H localhost -S 9999 -ld DICTDB
```

Observacao:

Para benchmark estavel com shared memory/TCP, suba o banco como servico persistente via AdminServer/`dbman` ou processo controlado fora da sessao do terminal.

No ambiente local, `proserve` iniciado pela sessao do terminal nao foi estavel o suficiente para medir PASOE shared/TCP de forma confiavel.


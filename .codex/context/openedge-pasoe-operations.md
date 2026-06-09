# Operacao OpenEdge, bancos locais e PASOE

Este arquivo registra comandos e cuidados operacionais para o ambiente local.

## Paths importantes

Workspace:

```text
D:\opencode\motor-progress
```

OpenEdge:

```text
C:\Progress\OpenEdge\bin
```

Banco base de validacao historica:

```text
D:\opencode\motor-progress\db\sports2000
```

Outros bancos relevantes no ambiente atual:

```text
D:\opencode\motor-progress\db\ems2cad
D:\opencode\motor-progress\db\ems2med
D:\opencode\motor-progress\db\ems5
```

PASOE:

```text
alias: sursumpasoedev
path:  D:\opencode\motor-progress\pasoe\sursum-pasoe-dev
http:  http://localhost:8890
apsv:  http://localhost:8890/apsv
```

## Variaveis uteis para PowerShell

```powershell
$oeBin = "C:\Progress\OpenEdge\bin"
$repo = "D:\opencode\motor-progress"
$db = "D:\opencode\motor-progress\db\sports2000"
$pasoeName = "sursumpasoedev"
$pasoeDir = "D:\opencode\motor-progress\pasoe\sursum-pasoe-dev"
```

## Criar instancia PASOE local

Comando usado anteriormente:

```powershell
& "C:\Progress\OpenEdge\bin\pasman.bat" create -p 8890 -P 8891 -s 8892 -j 8893 -Z dev -N sursumpasoedev "D:\opencode\motor-progress\pasoe\sursum-pasoe-dev"
```

## Iniciar PASOE

```powershell
& "C:\Progress\OpenEdge\bin\pasman.bat" start -I sursumpasoedev
```

## Parar PASOE

```powershell
& "C:\Progress\OpenEdge\bin\pasman.bat" stop -I sursumpasoedev
```

## Configuracao de banco no PASOE

Configuracao conhecida em `openedge.properties`:

```text
agentStartupParam=-T "${catalina.base}/temp" -db D:\opencode\motor-progress\db\sports2000 -ld DICTDB -1 -db D:\opencode\motor-progress\db\ems2cad -ld ems2cad -1 -db D:\opencode\motor-progress\db\ems2med -ld ems2med -1 -db D:\opencode\motor-progress\db\ems5 -ld ems5 -1
```

Observacao:

- `-1` conecta single-user.
- Enquanto o PASOE estiver segurando esses bancos com `-1`, compilacoes e rotinas client conectando no mesmo banco podem falhar.
- Para compilar ou inspecionar localmente com `_progres.exe`, pare o PASOE antes.
- Nao misturar `proserve` nesses mesmos bancos enquanto o PASOE estiver configurado com `-1`.

## PROPATH esperado

PROPATH local/PASOE deve incluir:

```text
D:\opencode\motor-progress\sursum
D:\opencode\motor-progress\sursum\esp
D:\opencode\motor-progress
C:\Progress\OpenEdge\tty\netlib\OpenEdge.Net.pl
```

`OpenEdge.Net.pl` e necessario para `OpenEdge.Web.WebResponse` e `OpenEdge.Web.WebResponseWriter`.

## Compilar fontes com banco

Pare o PASOE se ele estiver usando `-1`.

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB -p "D:\opencode\motor-progress\temp\ValidateSursumCurrent.p"
```

## Rodar worker CLIENT

Exemplo generico:

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB -p "D:\opencode\motor-progress\workers\RunDynamicQueryClientWorker.p"
```

## Acionar worker PASOE via WEB

```powershell
curl.exe -sS -X POST "http://localhost:8890/web/SursumDynamicQuery/jobs/drain"
```

## Consultar status de job

```powershell
curl.exe -sS "http://localhost:8890/web/SursumDynamicQuery/jobs/JOB-ID-AQUI"
```

## Baixar resultado de job

```powershell
curl.exe -sS "http://localhost:8890/web/SursumDynamicQuery/jobs/JOB-ID-AQUI/result" -o "job-result.json"
```

## Executar exemplos curl

Sequencial 10.000 registros:

```powershell
.\examples\curl-customer-10000.bat
```

Paralelo por pagina:

```powershell
.\examples\curl-customer-10000-parallel.bat
```

Paralelo por faixa de chave:

```powershell
.\examples\curl-customer-10000-keyrange.bat
```

Pipeline:

```powershell
.\examples\curl-customer-pipeline.bat
```

## Logs PASOE

Diretorio:

```text
D:\opencode\motor-progress\pasoe\sursum-pasoe-dev\logs
```

Arquivos comuns:

```text
catalina.YYYY-MM-DD.log
localhost-access.YYYY-MM-DD.log
sursumpasoedev.agent.YYYY-MM-DD.log
```

## Troubleshooting rapido

Erro 500 ou resposta malformada:

- conferir se o handler usa `OpenEdge.Web.WebResponse` e `OpenEdge.Web.WebResponseWriter`;
- conferir `RETURN 0`;
- conferir `OpenEdge.Net.pl` no PROPATH.

Erro APSV 404:

- conferir adapter APSV;
- conferir se o PASOE subiu corretamente;
- conferir rotas e programa publicado.

Erro ao compilar com banco ocupado:

- se o PASOE usa `-1`, parar PASOE antes de compilar;
- se houver `_mprosrv` solto, encerrar via ferramenta administrativa adequada.

Erro ao abrir banco em `-1` logo apos parar o PASOE:

- confirmar que o `pasman stop` terminou antes de abrir `_progres.exe`;
- nao rodar `stop` e `_progres.exe` em paralelo;
- repetir a abertura depois do stop concluido.

Erro ao carregar `.d` com `prodict/load_d.p`:

- passar o `dump-name` sem a extensao `.d`;
- o diretorio deve apontar para a pasta onde o arquivo esta;
- se a rotina falhar com `_File record not on file. (138)` mesmo com `dump-name` correto e quantidade de colunas batendo, o problema nao e schema basico; investigar mecanismo de load, dicionario e encoding.

Erro `NO_RESPONSE`:

- revisar payload recebido;
- revisar logs do handler;
- validar se o JSON segue o contrato real: `sources[].nome`, `sources[].campos`, `select[].sourceAlias`, `select[].outputAlias`.

## Shared memory vs TCP

Estado restaurado conhecido:

```text
PASOE usando -db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB
```

Tentativas anteriores de subir `proserve` manualmente em sessao sandbox ficaram instaveis. Para benchmark real shared/TCP, usar AdminServer/dbman ou servico persistente, nao processo solto em shell efemero.

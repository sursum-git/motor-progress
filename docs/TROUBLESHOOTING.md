# Troubleshooting

## PASOE segura o banco

Sintoma:

```text
The database ... is in use in single-user mode. (263)
```

Causa:

PASOE esta configurado com:

```text
-db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB
```

Solucao:

Pare o PASOE antes de compilar ou executar batch local com `-1`.

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' stop -I sursumpasoedev
```

## Aviso de WMI ao parar PASOE

Sintoma:

```text
Get-WmiObject : Acesso negado
```

Observacao:

Esse aviso apareceu no ambiente local durante `pasman stop`.

Se tambem aparecer:

```text
PAS was stopped
```

entao o stop funcionou.

## HTTP 500 no WEB handler

Sintoma:

```text
POST /web/SursumDynamicQuery/query -> 500
```

Causas ja observadas:

- conflito de URI no arquivo `.handlers`;
- handler retornando codigo incorreto;
- uso de `OUTPUT TO "WEB"` em vez de `OpenEdge.Web.WebResponseWriter`;
- PROPATH sem `OpenEdge.Net.pl`.

Correcoes aplicadas:

- rotas separadas:

```text
/query
/jobs/drain
/jobs/{jobId}/result
/jobs/{jobId}
/benchmarks/customer-count
```

- escrita HTTP via:

```abl
USING OpenEdge.Web.WebResponse.
USING OpenEdge.Web.WebResponseWriter.
```

## Resposta `HTTP/1.1 1`

Sintoma:

```text
Unsupported HTTP/1 subversion in response
```

Causa:

`HandleRequest()` retornava `1`, e o adapter interpretava isso como status HTTP.

Correto:

```abl
RETURN 0.
```

com resposta escrita via `WebResponseWriter`.

## Erro `Unknown HTTP status code 200`

Sintoma:

PASOE retorna pagina de erro:

```text
200 - Unknown HTTP status code 200
```

Causa:

`HandleRequest()` retornava `200`.

Correto:

```abl
RETURN 0.
```

## Classe `OpenEdge.Web.WebResponse` nao encontrada

Sintoma:

```text
Could not find class or interface OpenEdge.Web.WebResponse. (12886)
```

Causa:

`OpenEdge.Net.pl` fora do PROPATH.

Solucao:

Adicionar:

```text
C:\Progress\OpenEdge\tty\netlib\OpenEdge.Net.pl
```

## APSV retorna 404

Sintoma:

```text
Unable to communicate with AIA.
The Web Server returned an HTTP status code of 404. (9328)
```

Causas possiveis:

- adapter APSV nao inicializou;
- agent falhou ao subir;
- banco indisponivel;
- erro Java/ESAM no startup;
- PASOE em estado parcial depois de falha.

Verificar:

```text
pasoe/sursum-pasoe-dev/logs/sursumpasoedev*.log
pasoe/sursum-pasoe-dev/logs/sursumpasoedev.agent*.log
pasoe/sursum-pasoe-dev/logs/localhost-access*.log
```

## Erro ESAM/JNA

Sintoma:

```text
Failed to create temporary file for /win32-x86-64/esamjava.dll library: Acesso negado
```

Impacto:

Pode impedir inicializacao correta de adapters REST/APSV.

Mitigacao local:

- garantir permissao de escrita no temp da instancia;
- iniciar PASOE com `TEMP` e `TMP` apontando para diretorio gravavel;
- limpar estado quebrado e reiniciar PASOE.

## `There is no server for database`

Sintoma:

```text
There is no server for database D:\opencode\motor-progress\db\sports2000. (1423)
```

Causa:

Conexao sem `-1` tentou acessar banco multi-user, mas nao havia broker ativo.

Solucoes:

- voltar para `-1` no ambiente local;
- ou iniciar banco como servico persistente;
- ou usar TCP com `-H/-S` para broker ativo.

## `proserve` nao fica ativo

Problema observado:

`proserve.bat` iniciado pela sessao do terminal pode terminar junto com a sessao de comando.

Recomendacao:

Para benchmark real shared memory/TCP, suba o banco como servico persistente via AdminServer/`dbman`, ou use um processo controlado fora da sessao transient do terminal.

## `proshut` negado

Sintoma:

```text
The shutdown request was denied...
```

Causa:

Shutdown remoto negado por permissao/usuario.

Em ambiente local de teste, se o processo `_mprosrv` ficou preso, pode ser necessario encerrar manualmente o processo para liberar o banco.

## Compilacao sem saida

Comando:

```powershell
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b `
  -db 'D:\opencode\motor-progress\db\sports2000' -1 -ld DICTDB `
  -p 'temp\ValidateSursumCurrent.p'
```

Se nao imprime nada, a compilacao passou.

## Logs uteis

| Arquivo | Uso |
|---|---|
| `sursumpasoedev.agent.YYYY-MM-DD.log` | Erros ABL/agent/conexao banco |
| `sursumpasoedev.YYYY-MM-DD.log` | Erros Tomcat/adapters |
| `localhost-access.YYYY-MM-DD.log` | Status HTTP das chamadas |
| `output/*.log` | Benchmarks e cargas locais |


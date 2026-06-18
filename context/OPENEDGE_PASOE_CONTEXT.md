# Contexto OpenEdge, Compilacao e PASOE

Atualizado em 2026-06-18.

## Ambientes conhecidos

### Servidor web

Workspace Linux:

```text
/var/www/clients/client1/web7/web/motor-progress
```

URL base:

```text
http://php81.imatextil.com.br/motor-progress/
```

### PASOE runtime

Servidor:

```text
192.168.0.111
```

Instancia:

```text
sursum-api
```

Endpoint por empresa:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
```

Exemplo MED:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

Runtime Linux:

```text
/mnt/datasul/ERP/sursum
```

Share Windows equivalente:

```text
\\192.168.0.137\erp\sursum
```

Regra operacional: quando for necessario reiniciar, reiniciar somente `sursum-api`. Nao mexer em outras instancias PASOE.

Comandos no servidor `192.168.0.111`:

```bash
/usr/dlc12/servers/pasoe/bin/tcman.sh stop -I sursum-api
/usr/dlc12/servers/pasoe/bin/tcman.sh start -I sursum-api
```

### Host de compilacao Progress

Servidor Windows:

```text
192.168.0.42
```

Workspace:

```text
C:\opencode\motor-progress
```

OpenEdge:

```text
C:\Progress_12\OE\bin\_progres.exe
```

Banco de validacao:

```text
C:\opencode\motor-progress\db\sports2000
```

Comando padrao validado:

```powershell
Set-Location C:\opencode\motor-progress
& C:\Progress_12\OE\bin\_progres.exe -b -db C:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB -p C:\opencode\motor-progress\temp\ValidateSursumCurrent.p
```

Resultado esperado: exit code 0 e sem saida no terminal.

## Publicacao de .r

Depois de alterar `.cls`, `.p`, `.w`, `.i` ou `.df`, copiar o fonte para `192.168.0.42`, compilar e publicar os `.r` gerados para o runtime.

Arquivos importantes publicados em duplicidade por causa do PROPATH:

```text
DynamicQueryWebHandler.cls/r
sursum-api/rest/DynamicQueryWebHandler.cls/r
rest/DynamicQueryWebHandler.cls/r
ViewAsIncludeResolver.p/r
sursum-api/sursum/ViewAsIncludeResolver.p/r
sursum-api/sursum/RunViewAsIncludeResolver.p/r
```

O handler nao tem package, entao `DynamicQueryWebHandler.cls/r` tambem precisa existir direto na raiz `sursum`.

## PROPATH relevante

Para o runtime e compilacao do resolvedor:

```text
sursum-api/sursum
sursum-api/rest
sursum-api/workers
sursum-api/runners
sursum-api/sursum/esp
ems2
raiz do workspace
OpenEdge.Net.pl
```

`ems2` e necessario para resolver includes como `cxinc/i01cx373.i`.

## View-as e erro Progress 471

O PASOE pode retornar:

```text
Esta versao de PROGRESS nao permite compilacao de programas fontes. (471)
```

Isso acontece quando uma chamada tenta compilar/expandir fonte em runtime. Para evitar esse caminho:

- `POST /metadata/view-as/resolve` tenta resolver via SSH quando o ambiente possui `servidor` e `usuario`.
- `RunViewAsIncludeResolver.p` executa no host onde ha compilador e PROPATH com `ems2`.
- O fallback local contem tratamento direto para `cxinc/i01cx373.i`, retornando `Ativo,Inativo`.
- `ViewAsIncludeResolver.p` tambem contem a entrada `cxinc/i01cx373.i`.

Validacao feita em 2026-06-17:

```json
{
  "field": "idi-situacao",
  "listExpression": "Ativo,Inativo",
  "options": [
    { "label": "Ativo", "value": "Ativo" },
    { "label": "Inativo", "value": "Inativo" }
  ]
}
```

## Diagnostico PASOE

Endpoint adicionado:

```text
GET /diagnostics/runtime?waitSeconds=:seconds&label=:label
```

Uso: verificar comportamento de agentes e concorrencia. Se quatro requisicoes simultaneas demorarem mais que uma a uma, investigar configuracao de agentes/sessoes do PASOE, nao apenas Java/Tomcat estar no ar.

## Local historico Windows

Contexto antigo ainda aparece em docs:

```text
D:\opencode\motor-progress
C:\Progress\OpenEdge
PASOE local sursumpasoedev em http://localhost:8890
```

Esses caminhos sao historicos de desenvolvimento local. Para o fluxo atual, priorizar `192.168.0.42` para compilacao e `192.168.0.111` para runtime PASOE.

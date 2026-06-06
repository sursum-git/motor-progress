# Contexto OpenEdge e PASOE

## Instalacao local

OpenEdge instalado em:

```text
C:\Progress\OpenEdge
```

Executaveis usados:

```text
C:\Progress\OpenEdge\bin\_progres.exe
C:\Progress\OpenEdge\bin\prodb.exe
C:\Progress\OpenEdge\bin\prostrct.bat
C:\Progress\OpenEdge\bin\pasman.bat
```

## PASOE local

Instancia:

```text
sursumpasoedev
```

Diretorio:

```text
D:\opencode\motor-progress\pasoe\sursum-pasoe-dev
```

Porta HTTP:

```text
8890
```

Endpoint base:

```text
http://localhost:8890/web/SursumDynamicQuery
```

## Configuracao principal

Arquivo:

```text
pasoe/sursum-pasoe-dev/conf/openedge.properties
```

Parametros atuais do agent:

```text
-T "${catalina.base}/temp" -db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB -db D:\opencode\motor-progress\db\ems2med -1 -ld ems2med
```

Observacao:

Como os bancos estao conectados com `-1`, `numInitialSessions` deve ficar em `1`. Se aumentar para mais sessoes, a segunda sessao falha porque o banco ja esta em uso single-user.

## Charset HTTP

O PASOE/ABL esta emitindo JSON em bytes Windows-1252 para textos de metadados com acentos.

Por isso o handler usa:

```http
Content-Type: application/json; charset=windows-1252
```

Isso evita mojibake na interface web ao exibir labels como:

```text
Acordos por pais
Dt Emissao
Dt Implantacao
```

## Comandos comuns

Parar:

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' stop -I sursumpasoedev
```

Subir:

```powershell
& 'C:\Progress\OpenEdge\bin\pasman.bat' start -I sursumpasoedev
```

Validar bancos conectados:

```powershell
Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8890/web/SursumDynamicQuery/metadata/databases'
```

Compilar fontes:

```powershell
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b -db 'D:\opencode\motor-progress\db\sports2000' -1 -ld DICTDB -p 'D:\opencode\motor-progress\temp\ValidateSursumCurrent.p'
```

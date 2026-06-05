# Executor generico por arquivo JSON

O projeto agora possui um runner ABL generico que recebe um arquivo JSON de request por parametro e grava o resultado em outro arquivo JSON.

Isso permite criar varias extracoes apenas criando arquivos `.json`, sem recompilar programas ABL para cada nova extracao.

## Runner

```text
runners/RunDynamicQueryFromJson.p
```

## Parametros

Formato recomendado:

```text
request=<arquivo-request-json>;output=<arquivo-resultado-json>
```

Formato alternativo:

```text
<arquivo-request-json>|<arquivo-resultado-json>
```

Se `output` nao for informado, o runner grava em:

```text
D:\opencode\motor-progress\output\extracts\<nome-request>-result.json
```

## Exemplo de execucao

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b `
  -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB `
  -p "D:\opencode\motor-progress\runners\RunDynamicQueryFromJson.p" `
  -param "request=D:\opencode\motor-progress\examples\extractions\customer-simple.json;output=D:\opencode\motor-progress\output\extracts\customer-simple-result.json"
```

## BAT de apoio

```text
examples/run-json-extraction.bat
```

Uso com valores padrao:

```bat
examples\run-json-extraction.bat
```

Uso informando request e output:

```bat
examples\run-json-extraction.bat D:\opencode\motor-progress\examples\extractions\customer-simple.json D:\opencode\motor-progress\output\extracts\customer-simple-result.json
```

## Exemplo simples

```text
examples/extractions/customer-simple.json
```

## Exemplo pipeline avancado

```text
examples/customer-pipeline-advanced-request.json
```

## Contrato

O JSON pode usar o mesmo contrato aceito pela API:

- `sources`
- `joins`
- `select`
- `filters`
- `orderBy`
- `page`
- `pageSize`
- `pipeline`

## Resultado

O arquivo de saida sempre contem JSON.

Sucesso:

```json
{
  "success": true,
  "execution": "sync",
  "status": "completed",
  "recordsReturned": 500,
  "data": []
}
```

Erro:

```json
{
  "success": false,
  "error": {
    "code": "RUNNER_ERROR",
    "message": "...",
    "details": "..."
  }
}
```

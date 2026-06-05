# Exemplo: pipeline avancado com map, distinct, group e aggregate

Este exemplo executa uma consulta em `Customer` e aplica transformacoes pos-query.

Arquivo de request:

```text
examples/customer-pipeline-advanced-request.json
```

Execucao HTTP/PASOE:

```bat
examples\curl-customer-pipeline-advanced.bat
```

Execucao client/batch usada para validacao:

```powershell
& "C:\Progress\OpenEdge\bin\_progres.exe" -b -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB -p "D:\opencode\motor-progress\temp\RunPipelineAdvancedClient.p"
```

Saida client validada:

```text
examples\responses\customer-pipeline-advanced-client-response.json
```

## Pipeline

O pipeline faz:

- `source`: le `Customer`.
- `select`: projeta `CustNum`, `Name`, `State`, `Balance`.
- `filter`: aplica `CustNum >= 1`.
- `sort`: ordena por `CustNum`.
- `limit`: limita a primeira pagina de 500 registros.
- `map`: renomeia campos para `codigo`, `cliente`, `uf`, `saldo`.
- `distinct`: remove duplicidade por `codigo`.
- `group`: agrupa por `uf`.
- `aggregate`: soma `saldo` por grupo em `saldoTotal`.
- `output`: retorna JSON.

## Resultado validado

Resumo observado na validacao client/batch:

```json
{
  "success": true,
  "recordsReturned": 81,
  "first": {
    "uf": "MA",
    "count": 9,
    "saldoTotal": 13074.06
  }
}
```

O total de grupos e valores pode mudar conforme o conteudo local do `sports2000`.

## Observacao PASOE

Durante esta validacao, a compilacao ABL passou e o motor executou corretamente em client/batch. O PASOE local subiu, mas o adapter WEB retornou `404` para `/web/SursumDynamicQuery/...`, indicando problema de publicacao/mapeamento do adapter, nao do motor de pipeline.

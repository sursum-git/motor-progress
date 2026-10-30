# Consultas assíncronas pela API externa

Destino exclusivo: sursum-api/MED/9911. A autenticação e as permissões por consulta são as mesmas da execução síncrona. Use `X-Sursum-Query-Token` em todas as chamadas. Obtenha um novo access token com o mesmo client_id/client_secret quando necessário; ele pode acompanhar jobs criados com o token anterior.

## Enviar

```bash
curl --request POST 'https://iol.imatextil.com.br/query-progress/api/query.php' \
  --header "X-Sursum-Query-Token: $TOKEN" \
  --header 'Content-Type: application/json' \
  --data '{"code":"saldo-estoque-por-referencia","execution":"async","page":1,"pageSize":100,"parameters":{"querystring":{"estabelecimento":"502","deposito":"ARM","item":"130062","referencia":"004"}}}'
```

A resposta HTTP202 contém `jobId`, `status`, `statusUrl` e `resultUrl`. Guarde o jobId. O envio valida a consulta e os filtros, mas o processamento acontece depois. A execução síncrona continua sendo o padrão quando execution é omitido.

Para exportar todo o conjunto filtrado, troque page/pageSize por `"paginate":false`. O job processa uma página ou o conjunto completo explicitamente solicitado; não percorre páginas automaticamente. Async não aceita paginationMode:cursor.

## Acompanhar e baixar

```bash
curl --get 'https://iol.imatextil.com.br/query-progress/api/jobs.php' \
  --header "X-Sursum-Query-Token: $TOKEN" \
  --data-urlencode "jobId=$JOB_ID"

curl --get 'https://iol.imatextil.com.br/query-progress/api/job-result.php' \
  --header "X-Sursum-Query-Token: $TOKEN" \
  --data-urlencode "jobId=$JOB_ID" --output resultado.json
```

Consulte o status periodicamente até `completed` ou `failed`; sugere-se intervalo de 10 segundos. `resultAvailable:true` indica resultado disponível. O download retorna o JSON da consulta como attachment. O worker verifica a fila a cada minuto e processa até 2 jobs por chamada; isso não garante conclusão em 1 minuto.

| Resposta | Significado |
|---|---|
| 401 | Token ausente, inválido ou expirado; obtenha outro token |
| 403 | Consumidor sem permissão atual para a consulta |
| 404 | Job inexistente ou pertencente a outro consumidor |
| 409 no download | Resultado ainda indisponível; confira o status, inclusive failed |
| 410 | Resultado expirado |
| 429 no envio | Quota de jobs/armazenamento atingida |

## Limites e operação

Até 5 jobs pendentes por consumidor, 1000 jobs armazenados globalmente, 64 MiB por resultado e 1 GiB global incluindo arquivos temporários e reservas de tentativas. Resultados disponíveis por 24 h desde o envio. Jobs terminais são removidos após 48 h; temporários órfãos são limpos por idade de calendário (aproximadamente 24–48 h), preservando a tentativa ativa. Leases de 2 h recuperam execução interrompida, até 3 tentativas. Não há cancelamento ou webhook nesta entrega.

A fila fica fora da raiz pública em `/dados/pasoe/sursum-api/conf/consumer-secrets/query-access-tokens.json.jobs` (diretório 0700 root, arquivos 640). A fila nativa de banco não é utilizada: o MED não possui seu schema. Nenhuma tabela foi criada. Resultados e metadata são publicados atomicamente, com trava de SO e identificação da tentativa para impedir conclusão de worker antigo.

Worker CLI privado em `/var/www/clients/client1/web7/private/sursum-query-worker/consumer-jobs-worker.php`, agendado por `/etc/cron.d/sursum-med-consumer-jobs` como www-data. A rota interna drain exige credencial administrativa e não é exposta pelo gateway externo. O worker pode disparar até dez drenos internos concorrentes; o plano da consulta limita as partições ativas. `worker-health.json` privado registra a última execução bem-sucedida; nenhuma credencial é armazenada no job. A administração web continua exclusiva de tadeu.parreiras com login e CSRF.

## Exportação paralela de movimentações de estoque

`movimentacoes-estoque` habilita exportação paralela apenas quando `execution` é `async`, `paginate` é `false` e `dataInicial` e `dataFinal` são informadas. O servidor quebra o intervalo em dias, no máximo 2.000 partições e dois workers simultâneos; o consumidor não escolhe workers, campos ou a quebra. Cada partição aceita no máximo 100.000 registros e 256 MiB serializados; a exportação final aceita até 10 GiB. Se qualquer teto de partição for atingido, o job falha sem download parcial: ajuste a estratégia de quebra no JSON da consulta (por exemplo, data mais outra chave indexada). Após concluir, o download por `jobId` é um attachment `application/x-ndjson` com `Content-Encoding: gzip`, disponível por 24 horas. A exportação é ordenada por data e `nr-trans`, mas não é snapshot transacional.

```json
{"code":"movimentacoes-estoque","execution":"async","paginate":false,"webhookDelivery":"manifest","parameters":{"querystring":{"dataInicial":"2021-01-01","dataFinal":"2025-12-31","estabelecimento":"502","deposito":"ARM"}}}
```

O status acrescenta `parallel.totalPartitions`, `completedPartitions`, `runningPartitions` e `failedPartitions`. Quando uma partição atinge teto, `parallel.lastFailureCode` informa a causa sanitizada (`PARALLEL_PARTITION_RECORD_LIMIT` ou `PARALLEL_PARTITION_BYTE_LIMIT`) e o job termina como `failed`. `webhookDelivery:manifest` envia JSON assinado com `jobId`, formato, tamanho, checksum, contagem e URL de download. `full` envia o gzip completo, com `Content-Type: application/x-ndjson`, `Content-Encoding: gzip` e HMAC sobre os bytes compactados. Ambos usam as retentativas e o `X-Sursum-Webhook-Id` existentes.

Swagger e coleção Postman são gerados a partir do catálogo atual. No Swagger, use execution:async e depois informe o jobId nos GETs. No Postman, a pasta Consultas assincronas inclui envio, acompanhamento e download, com renovação do token e captura de job_id. Um arquivo já importado no Postman precisa ser importado novamente para receber alterações do catálogo.



Validação final28/10/2026: compilação oficial OpenEdge12.2 com248checks em cada uma das quatro combinações UTF8/ISO8859-1×AMERICAN/EUROPEAN;263checksPHP e14scriptsPostman. Domínio externo, Swagger eNewman passaram41checks; PASOE direto passou9. Exportação assíncrona6939registros idêntica ao resultado síncrono; doisjobs da versãofinal concluídos na primeira tentativa. Acionamentoautomático do cron confirmado. Cinco consumidores temporários, tokens e novejobs próprios removidos; política operacional e configurações dos outrosPASOEs preservadas. Recibos privados em temp/consumer-async-20261028/final-verification.json.
# Webhook opcional por consulta

O consumidor pode cadastrar um destino HTTPS para cada `code` permitido em `/api/webhook.php`. O resultado do job continua recuperavel por `GET /api/job-result.php?jobId=...`; o webhook acrescenta entrega assincrona do mesmo JSON completo, com assinatura HMAC e retentativas. Consulte `docs/CONSUMO_EXTERNO_CONSULTAS.md` para o contrato, o segredo retornado uma unica vez e os cabecalhos de validacao.


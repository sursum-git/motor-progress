# Webhooks de resultados por consumidor

## Intenção

Manter o consumo ativo já publicado por `jobId` e permitir que uma integração, autenticada com o seu próprio token de consumidor, cadastre um webhook HTTPS distinto para cada consulta autorizada. O destino recebe o resultado JSON completo quando um job assíncrono daquela consulta terminar com sucesso. A alteração permanece exclusiva do `sursum-api/MED/9911`.

## Objetivos

- Preservar sem mudança `GET /api/jobs.php` e `GET /api/job-result.php`.
- Disponibilizar autoatendimento autenticado para consultar, cadastrar/rotacionar e remover o webhook do próprio consumidor, por consulta autorizada.
- Enviar o resultado completo, com entrega ao menos uma vez, assinatura verificável e proteção contra SSRF.
- Manter segredo de assinatura fora do catálogo público, dos logs e da resposta de listagem.

## Fora de escopo

- Webhooks de falha, cancelamento, progresso ou qualquer evento fora de `query.completed`.
- Múltiplos destinos para a mesma combinação de consumidor e consulta, webhooks em HTTP ou portas não padrão.
- Cancelamento de jobs, alteração das permissões por consulta ou mudança de outros PASOEs/IMA.

## Contrato externo

Cada configuração é identificada por `(consumerId, code)`: um consumidor pode manter destinos diferentes para `saldo-estoque-por-referencia` e para qualquer outra consulta que ele tenha permissão de executar.

`GET /api/webhook.php?code=<codigo-da-consulta>` devolve somente o estado e a URL do webhook daquela consulta para o consumidor autenticado.

`PUT /api/webhook.php` recebe exatamente `{"code":"saldo-estoque-por-referencia","url":"https://destino.example/webhooks/sursum"}`. Ele substitui o destino daquela consulta, cria uma nova chave de assinatura e a retorna uma única vez como `webhook_secret`. A chave anterior deixa de valer para jobs ainda não entregues daquela consulta.

`DELETE /api/webhook.php` recebe exatamente `{"code":"saldo-estoque-por-referencia"}` e remove o destino daquela consulta, impedindo entregas ainda pendentes. A identidade vem exclusivamente de `X-Sursum-Query-Token`; não existe parâmetro para escolher outro consumidor. Em todos os métodos, `code` precisa corresponder a uma consulta atualmente permitida para o consumidor.

Para uma conclusão bem-sucedida, o destino recebe:

```http
POST <url cadastrado>
Content-Type: application/json; charset=utf-8
User-Agent: Sursum-MED-Webhook/1.0
X-Sursum-Webhook-Event: query.completed
X-Sursum-Webhook-Id: JOB-YYYYMMDD-000000-000000
X-Sursum-Webhook-Timestamp: <epoch UTC>
X-Sursum-Webhook-Signature: v1=<HMAC-SHA256 hexadecimal de "timestamp.raw-body">
```

O corpo é exatamente o JSON completo que o mesmo consumidor obteria em `job-result.php`, incluindo `data`. A resposta `2xx` confirma a entrega. O recebedor deve deduplicar por `X-Sursum-Webhook-Id`, pois a entrega é ao menos uma vez.

## Segurança e persistência

O webhook só aceita HTTPS na porta 443, sem usuário/senha/fragmento, sem redirecionamentos e com validação normal de certificado TLS. Antes de cada entrega, o worker resolve o hostname e aceita somente endereço IPv4 público; loopback, link-local, multicast, ranges privados, CGNAT, documentação e destinos internos são recusados. O IP resolvido é fixado na conexão cURL com `CURLOPT_RESOLVE`, impedindo troca DNS entre validação e conexão.

A configuração visível ao consumidor contém código da consulta, URL, versão e estado, sem segredo. O segredo aleatório de 32 bytes, e o snapshot da versão daquele código associado ao job, ficam em armazenamento privado do MED; ele nunca é devolvido novamente, salvo na resposta do `PUT` que o criou. Cada tentativa verifica que o consumidor ainda está ativo, tem permissão atual para a consulta e mantém a mesma versão de webhook. Remover ou substituir o webhook impede as entregas pendentes da versão anterior daquela consulta.

O PASOE entrega ao worker privado apenas o corpo já assinado e metadados transitórios de uma tentativa sob lease. O worker PHP não persiste segredo de assinatura, não recebe token do consumidor, não aceita URL fornecida pelo cliente e informa o resultado da tentativa ao PASOE. Sem callback configurado, o resultado continua disponível somente pelo `jobId` até a expiração existente de 24 horas.

## Retentativas e operação

Cada job concluído recebe no máximo seis tentativas: imediata, depois de 1, 5, 15, 60 e 360 minutos, sempre dentro da retenção de 24 horas. Erros de rede, `408`, `429` e `5xx` são retentáveis; os demais `4xx` encerram a entrega como falha. Atrasos e estado de entrega ficam no registro privado do job. O worker usa o cron privado já existente, em lote limitado, e registra somente `jobId`, consumidor, código HTTP e classe de erro — nunca corpo, token ou segredo.

## Alternativas consideradas

1. Evento contendo apenas `jobId` e URL de download: mais leve, mas não atende ao pedido de entregar a resposta completa.
2. Resultado completo por webhook, com configuração por token do próprio consumidor e por consulta autorizada: escolhido. Mantém polling como alternativa, não exige credencial administrativa para a integração e permite validação criptográfica da origem.
3. Cadastro somente na página administrativa: menor superfície de API, mas não atende ao autoatendimento escolhido.

## Decisões de implementação

- Criar rotas externas fixas em `web/api/webhook.php` e gateway dedicado, com métodos GET, PUT e DELETE.
- Acrescentar serviço ABL de registro e entrega de webhooks; expandir a política de consumidor apenas para a rota fixa `consumer-webhooks`.
- Estender o job privado com estado de entrega, lease e versão de webhook, sem alterar a fila nativa ausente.
- Estender o worker CLI privado para reclamar uma entrega, receber corpo/assinatura do PASOE, realizar POST externo e confirmar a tentativa.
- Atualizar Swagger, coleção Postman, tela de tokens com orientação de autoatendimento e documentação de verificação HMAC.

## Aceite

Um consumidor com token válido consegue cadastrar um webhook diferente para cada consulta permitida e recebe o segredo uma vez por configuração. Um job com os quatro filtros de `saldo-estoque-por-referencia` continua baixável por `jobId` e também chega ao receptor HTTPS associado a esse código como JSON completo com assinatura válida. URL interna, HTTP, redirecionamento, token inválido, webhook de outro consumidor e consulta sem permissão são recusados. Falha temporária é reenviada; retorno 2xx encerra a entrega; URL removida impede pendências somente daquela consulta. Compilação OpenEdge 12.2, publicação e validação são restritas ao PASOE sursum/MED.

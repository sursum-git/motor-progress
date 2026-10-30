# Webhooks por consulta — consumidor externo, sursum/MED

> Aprovado pelo solicitante em 2026-10-28. Escopo exclusivo de `sursum-api/MED/9911` e do proxy externo `iol.imatextil.com.br/query-progress`.

## Resultado esperado

Preservar integralmente o polling já publicado por `jobId` (`/api/jobs.php` e `/api/job-result.php`) e acrescentar, para cada combinação de consumidor e consulta autorizada, um único webhook HTTPS que recebe o resultado integral de jobs assíncronos concluídos. A aplicação se autentica como já faz hoje: obtém token com `client_id` e `client_secret`, envia `X-Sursum-Query-Token`, e só administra sua própria configuração. O código da consulta é obrigatório na configuração; não há como escolher outro consumidor.

## Contrato público

- `GET /query-progress/api/webhook.php?code=saldo-estoque-por-referencia`: retorna estado, URL, versão e dados operacionais sem segredo.
- `PUT /query-progress/api/webhook.php`: aceita somente `{ "code": "...", "url": "https://host:443/path" }`; cria ou substitui a configuração daquele código e devolve `webhook_secret` somente nessa resposta.
- `DELETE /query-progress/api/webhook.php`: aceita somente `{ "code": "..." }`; remove a configuração daquele código e invalida suas entregas ainda pendentes.
- O receptor recebe `POST` com o JSON completo que seria baixado por `job-result.php` e cabeçalhos `X-Sursum-Webhook-Event: query.completed`, `X-Sursum-Webhook-Id`, `X-Sursum-Webhook-Timestamp` e `X-Sursum-Webhook-Signature: v1=<HMAC-SHA-256(timestamp.raw-body)>`.
- A entrega é ao menos uma vez. `2xx` confirma; a aplicação receptora deduplica por `X-Sursum-Webhook-Id` e valida a assinatura sobre os bytes recebidos.

## Persistência e fronteiras

- Criar `DynamicQueryConsumerWebhooks.cls` para validar os contratos, a permissão atual do consumidor para `code`, o HTTPS/porta 443 e a configuração por `(consumerId, code)`.
- Armazenar somente URL, estado e versão no catálogo de consumidores. Guardar o segredo aleatório e o snapshot de versão em um arquivo privado derivado de `accessTokenStore`, sob o diretório já protegido do MED; nunca exibir esse arquivo, incluí-lo no Swagger/Postman, nem enviá-lo a logs.
- Estender `DynamicQueryConsumerJobRepository.cls` para persistir uma entrega junto ao job concluído: consumidor, código, versão, estado, tentativas, próximo horário, lease e motivo sanitizado. O snapshot garante que uma troca ou remoção de webhook invalide entregas antigas ainda não iniciadas.
- Depois de `completeJob`, `DynamicQueryConsumerJobs.cls` cria a pendência somente se existe configuração válida para aquele consumidor e código. Jobs sem webhook continuam exatamente como hoje.
- Criar apenas rotas internas fixas do PASOE para o worker: reclamar entrega, obter o payload assinado em bytes e confirmar a tentativa. Nenhuma rota aceita URL, código, `jobId`, caminho ou destino escolhido pelo worker/cliente. O payload é assinado no PASOE com `MESSAGE-DIGEST('HMAC-SHA-256', ...)`; o worker recebe segredo nenhum.
- Estender `ops/consumer-jobs-worker.php` para, depois do drain de jobs, reclamar pequeno lote de entregas. Ele envia os bytes recebidos ao destino e devolve somente resultado sanitizado (`2xx`, `4xx` terminal, ou falha transitória). O worker não persiste token, URL, corpo ou segredo.

## Segurança

- Autorizar a rota fixa de autoatendimento em `DynamicQueryConsumerPolicy.cls` e `DynamicQueryClientCredentials.cls`, mantendo todas as demais rotas administrativas exclusivas de administrador. O handler `SecuredDynamicQueryWebHandler.cls` despacha a rota antes do motor de consulta e usa a identidade resolvida pelo token, nunca dados do corpo.
- Validar `code` contra a permissão atual em GET/PUT/DELETE. Token inválido ou expirado retorna 401; código de outro consumidor ou não permitido retorna 403; configurações inexistentes seguem contrato 404; formato inválido retorna 400.
- Rejeitar URL que não seja HTTPS, que não seja porta 443, que contenha usuário/senha, fragmento, IP literal ou host inválido. Antes de cada entrega, o worker resolve A record, aceita exclusivamente IPv4 público e fixa o IP na conexão com `CURLOPT_RESOLVE`. Rejeitar loopback, link-local, privada, CGNAT, documentação, multicast e ranges reservados. Desabilitar redirecionamentos e manter validação de certificado.
- Cada tentativa volta a validar que consumidor, permissão para a consulta e versão do webhook permanecem válidos. Remoção/rotação impede pendências da versão anterior.
- Usar seis tentativas: imediata, 1, 5, 15, 60 e 360 minutos. Retentar falha de rede, 408, 429 e 5xx; encerrar nos demais 4xx. Aplicar a retenção existente de 24 horas ao job e ao payload.

## Implementação e testes, em ordem

1. **Escrever testes que falham primeiro.**
   - Acrescentar `tests/security/consumer-webhook-gateway.test.php`: autenticação com token estático e de client credentials, isolamento por consumidor, corpo estrito, `code` obrigatório, 401/403/404, e bloqueio do caminho pelo proxy genérico.
   - Estender `tests/security/consumer-jobs-gateway.test.php` para as três rotas internas fixas e para evitar que valores de URL/destino/caminho sejam encaminhados pelo cliente.
   - Estender `tests/security/query-api-docs.test.php`, `tests/security/query-api-docs-postman.test.cjs` e `tests/security/query-consumers.test.cjs` com a especificação, coleção, HMAC e ausência de segredos em listagem/exportação.
   - Criar cobertura ABL em `tests/abl/` para contrato de autorização, configuração `(consumerId, code)`, snapshot/rotação, assinatura HMAC e estado de tentativa. Executar as novas suítes e registrar a falha antes da implementação.

2. **Construir o serviço no PASOE.**
   - Adicionar `sursum-api/sursum/DynamicQueryConsumerWebhooks.cls` e ampliar `DynamicQueryConsumerJobRepository.cls`/`DynamicQueryConsumerJobs.cls` para registro, claim, lease, leitura em bytes, assinatura, conclusão e limpeza de entrega.
   - Atualizar `sursum-api/sursum/DynamicQueryConsumerPolicy.cls`, `DynamicQueryClientCredentials.cls`, `DynamicQueryConsumerRegistry.cls` e `sursum-api/rest/SecuredDynamicQueryWebHandler.cls` somente para as rotas novas e a validação correspondente. Preservar o comportamento atual de query, token, consumidores, jobs e download.
   - Não compilar nem publicar `sursum-api/rest/DynamicQueryWebHandler.cls`; para compilação oficial usar a base publicada `integration-src/consumer-cursor/DynamicQueryWebHandler.cls`, conforme o contexto do projeto.

3. **Construir o proxy e o worker externos.**
   - Criar `web/api/webhook.php` e `web/consumer-webhook-gateway.php`, seguindo os gateways fixos existentes, com HTTPS obrigatório, limite de corpo, JSON UTF-8, token apenas em `X-Sursum-Query-Token` e nenhum alvo configurável pelo cliente.
   - Atualizar `ops/consumer-jobs-worker.php` com cliente interno de claim/payload/complete, timeouts pequenos, DNS+SSRF guard, `CURLOPT_RESOLVE`, entrega de bytes sem recodificação e classificação de resposta. Ajustar o agendamento já privado sem criar processo público.
   - Atualizar a página de tokens para orientar que o segredo retornado pelo `PUT` deve ser guardado pela aplicação e que cada consulta pode ter um destino distinto; a administração LDAP continua exclusiva de `tadeu.parreiras`.

4. **Atualizar documentação gerada e material de consumo.**
   - Atualizar `web/query-api-docs-lib.php`, `web/query-api-docs.js` e arquivos relacionados para incluir a tag Webhooks, os três endpoints, segurança, exemplos com `saldo-estoque-por-referencia`, formato de assinatura, retentativas e coexistência com polling.
   - A coleção Postman gerada deve ganhar uma pasta **Webhooks** com consultar, cadastrar/rotacionar e remover, reutilizando a renovação automática de token já existente. Não exportar `client_secret`, token nem `webhook_secret` preenchidos.
   - Atualizar `docs/CONSUMO_EXTERNO_CONSULTAS.md`, `docs/consumer-async-api.md`, `docs/DOCUMENTACAO_API_SWAGGER_POSTMAN.md` e `context/PROJECT_CONTEXT.md` com o contrato final, exemplos de verificação HMAC e a limitação exclusiva ao sursum/MED.

5. **Validar e publicar somente o alvo autorizado.**
   - Executar toda a suíte PHP/Node alterada, os quatro modos oficiais de compilação OpenEdge 12.2 e revisão estática antes da publicação.
   - Seguir `skills/motor-progress-publicar-pasoe/SKILL.md`: backup/hash, publicação seletiva, compilação no 192.168.0.42, deploy/reload somente no `sursum-api/MED/9911`, atualização do proxy/worker privado no host web e nenhuma alteração em IMA/outros PASOEs.
   - No PASOE real, criar um consumidor temporário autorizado para `saldo-estoque-por-referencia`, cadastrar o webhook para esse código, enviar job assíncrono com estabelecimento, depósito, item e referência, verificar status/download por `jobId`, corpo completo recebido, HMAC válido, deduplicação/2xx e limpeza. Verificar tentativa transitória controlada, remoção/rotação, consumidor estranho e código sem permissão. Remover consumidor, webhook, resultado, arquivos e receptor temporários ao término.

## Critérios de aceite

- Cada consumidor administra por API somente um webhook para cada consulta que lhe é permitida.
- Um job de `saldo-estoque-por-referencia` com os quatro filtros continua disponível ativamente por `jobId` e é entregue ao webhook desse código com resultado completo e assinatura verificável.
- Uma URL insegura, privada, redirecionada, token inválido, código não permitido, tentativa de administrar outro consumidor ou rota administrativa é recusada.
- Uma falha temporária é reenviada de modo controlado; 2xx encerra; a remoção ou rotação bloqueia pendências antigas.
- Swagger, interface interativa, coleção Postman e documentação textual descrevem o contrato real, sem expor segredos.

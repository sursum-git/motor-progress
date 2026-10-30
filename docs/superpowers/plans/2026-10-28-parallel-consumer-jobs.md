# Exportação paralela por definição de consulta — sursum/MED

## Escopo aprovado

Implementar exclusivamente em `sursum-api/MED/9911` uma capacidade opcional de exportação paralela. Cada consulta declara no seu JSON o bloco `asyncParallel`, com estratégia de quebra, campo indexado, geração de partições, máximo de workers, limite de partições e ordenação de consolidação. O consumidor solicita somente `execution: "async"` e, opcionalmente, `webhookDelivery: "full" | "manifest"`.

Consultas sem `asyncParallel` preservam o contrato atual. A configuração não permite campo, SQL, filtro interno, worker ou destino externo fornecido pelo consumidor.

## Implementação

1. Criar testes RED para validação estrita de `asyncParallel`: estratégias `date-day`, `value-list` e `range`; parâmetros declarados; campo indexado permitido; teto de partições; ordenação estável; rejeição de valores do request que tentem escolher partição/worker. Estender testes de gateway, ABL, Swagger e Postman para `webhookDelivery`, download de exportação e manifesto.
2. Criar `DynamicQueryConsumerParallelJobs.cls` para expandir o plano do job mestre em subjobs privados, controlar no máximo dez leases ativos, revalidar permissão antes de cada partição e registrar progresso agregado. Ampliar `DynamicQueryConsumerJobRepository.cls` com estado de partições, arquivos temporários, recuperação de lease e limpeza.
3. Ampliar `DynamicQueryConsumerJobs.cls` para despachar um job paralelo quando e somente quando a definição tiver `asyncParallel`; workers existentes executam uma partição por vez. Cada definição informa `maxPartitionRecords`, `maxPartitionBytes` e `maxResultBytes`; atingir um teto falha a partição sem truncamento. Após todas as partições, consolidar em ordenação declarada para um arquivo NDJSON gzip por streaming, com SHA-256, contagem e cota de 10 GiB/24h.
4. Estender download por `jobId` para escolher o contrato pela metadata interna: JSON comum preserva o retorno atual; exportação retorna attachment `application/x-ndjson` com `Content-Encoding: gzip`, tamanho, checksum e nome seguro. Nunca aceitar caminhos de arquivo fornecidos pelo cliente.
5. Integrar webhooks por job: `full` envia bytes gzip assinados e `manifest` envia JSON assinado com metadados e `resultUrl`; ambos dependem da configuração por consumidor/consulta e das permissões vigentes. O worker permanece privado, chamado somente pelo processo local e pelas rotas internas do PASOE.
6. Atualizar `web/consumer-query-gateway.php`, Swagger, Postman e documentação para aceitar somente `webhookDelivery`, explicar progresso paralelo, formatos de download, cotas e diferenças entre `full` e `manifest`.
7. Executar suites locais relevantes, compilação OpenEdge 12.2 em quatro combinações, publicar seletivamente fontes/.r e proxy/worker, recarregar somente sursum/MED e validar no PASOE real com uma consulta temporária paralela indexada. Verificar concorrência máxima, consolidação, download, `full`, `manifest`, revogação de permissão e limpeza.

## Critérios de aceite

- Somente consultas explicitamente configuradas no JSON executam paralelamente.
- O motor respeita chave indexada, teto de partições e dez workers, sem ROWID ou SQL do consumidor.
- A exportação grande é streamada como NDJSON gzip e não limitada a 64 MiB; aplica cota de 10 GiB e expira em 24 horas.
- `full` e `manifest` usam HMAC e preservam o polling/download autenticado por `jobId`.
- Swagger, Postman e documentação descrevem o contrato publicado; nenhum outro PASOE/IMA é alterado.

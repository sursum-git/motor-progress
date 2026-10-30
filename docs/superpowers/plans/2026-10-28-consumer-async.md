# Async externo — sursum/MED

Autorizado: enfileirar consulta salva por token de consumidor, acompanhar e baixar resultado, documentação e validação oficial/PASOE. Somente sursum-api/MED/9911; preservar consumidores, IMA e outros PASOEs.

Contrato: POST api/query.php com execution:"async" (omissão/sync preservam comportamento), filtros e paginação existentes. Async não combina com cursor nesta entrega. Resposta202 jobId/queued/statusUrl/resultUrl. GET api/jobs.php?jobId=... e GET api/job-result.php?jobId=..., cabeçalho X-Sursum-Query-Token. URLs finais fixas, nenhuma rota/destino/SQL do cliente. Download JSON attachment autenticado; pendente409; job inexistente/alheio404; permissão atual revogada403; token inválido401. Renovação de token do mesmo consumidor continua acesso.

Inspeção real: a fila nativa retorna QUEUE_SCHEMA_MISSING. Decisão: fila privada persistente sob accessTokenStore+'.jobs', sem DDL e sem modificar/consumir a fila nativa. Reutilizar o modelo materializado e serviço de consulta. Metadata de proprietário/query/mode criada somente no servidor. Nunca retornar requestJson/context/plan/paths/erros técnicos no status público. Validar identidade+permissão atual antes de executar e antes de status/download. Resultado privado Linux, nome derivado do jobId estrito; ignora caminhos fornecidos. Escritas atômicas, lock consultivo de SO liberado em crash, lease por tentativa com fencing para impedir conclusão de worker antigo, recuperação após2h/3tentativas. Até1000jobs armazenados e5pendentes por consumidor;1GiB de resultadosglobais/64MiB porresultado. Expiração24h, remoção arquivos após48h.

Worker dedicado acionado no servidor por CLI privado/agendamento de1minuto, sem liberar drain administrativo ao consumidor. Lotes limitados, concorrência protegida, quota de pendências por consumidor/global, resultado limitado64MiB e retenção documentada. Async processa uma página solicitada ou conjunto completo se paginate:false; não exporta automaticamente todas páginas. Sem webhook/interruptor de jobs running nesta entrega.

- [x] Inspecionar schema/runtime/fontes/worker e capturar backups/hash/configs. Usar fonte base exato de integration-src/consumer-cursor como ponto inicial; preservar mudanças alheias canônicas.
- [x] RED/GREEN PHP para enfileiramento/rotas/tipos/conflitos/URLs; ABL para proprietário/permissões/projeção/contrato. Implementar serviço de jobs e hooks restritos ao wrapper seguro.
- [x] Worker específico+armazenamento privado+quotas, sem afetar jobs legados. Swagger/Postman com202/poll/download e exemplos por consulta.
- [x] Oficial12.2 quatro codificações/culturas, revisão independente, publicação com guards, refresh só MED ocioso, instalação worker restrito.
- [x] PASOE/externo/Swagger/Postman: queued→completed→download,4filtros, página/full, novo token, consumidor alheio, permissão revogada, paths/SQL/admin recusados; limpar fixtures/arquivos/jobs próprios e preservar política. Atualizar contexto e recibos.

Observação técnica: o worker limpa os LONGCHARs entre os dois jobs do lote antes de reaplicar FIX-CODEPAGE; sem isso, OpenEdge retorna11683 no segundo job. A recuperação de tentativas evitava perda do job, mas gerava uma tentativa desnecessária. O cenário real com dois jobs no mesmo lote verifica ambos concluídos na primeira tentativa.


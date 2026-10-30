# Candidato publicado — paginação externa

Este arquivo é o fonte exato do DynamicQueryWebHandler compilado para a entrega de paginação externa em sursum/MED de27/10/2026. Deriva do fonte publicado antes da tarefa, acrescido somente do hook protegido de paginação, flag e chamada ao modo completo.

O fonte canônico sursum-api/rest/DynamicQueryWebHandler.cls contém também alterações locais anteriores de metadados de requisição ainda não publicadas, preservadas durante esta tarefa. Essas alterações anteriores apresentam erro de sintaxe na compilação12.2; não foram corrigidas nem incluídas nesta publicação. As adições de paginação estão presentes tanto no canônico quanto neste candidato. Não publicar o canônico inteiro sem reconciliar essa pendência alheia.

Fonte candidato SHA256: fde5b1c0192d66d4f4826753793c572a60896f1e71e33703f5d682a9959f1250

Compilar como DynamicQueryWebHandler.cls junto a DynamicMultiTableQueryService, DynamicQueryConsumerPagination, DynamicQueryConsumerPolicy, DynamicQueryClientCredentials, DynamicQueryConsumerRegistry e SecuredDynamicQueryWebHandler, com as dependências publicadas do projeto. Compilador oficial OpenEdge12.2.12 no192.168.0.42; runtime sursum-api/MED/9911. Hook padrão sem efeito, habilitado somente pelo wrapper seguro com roleconsumer. Não registrar o wrapper em outros PASOEs.

Recibos operacionais ignorados: temp/consumer-pagination-20261027. Guia de uso em docs/DOCUMENTACAO_API_SWAGGER_POSTMAN.md. O novo modo paginate:false não modifica o modelo/serializador compartilhado nem configurações de consulta salva.

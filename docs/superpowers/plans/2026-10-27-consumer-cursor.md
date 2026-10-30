# Cursor de consultas — sursum/MED

Pedido autorizado: opção de paginação por chave de ordenação única, com permissões atuais porconsulta, Swagger/Postman e navegação real. Preservar offset e paginate:false.

Contrato: raiz paginationMode=offset(default)|cursor, cursor opcional(stringvazia/omitida na primeira chamada), pageSize1..1000. Cursor não admite page nem paginate:false. Resposta de cursor tem paginationModecursor, page:null, pageSize, recordsReturned, hasMore, nextCursor(nullable), cursorExpiresIn900. Cada página continua exigindo token válido/permissão atual.

Ordenação: preservar ORDER BY materializado e completar com chaves de índices primários únicos de CADA buffer; semROWID. Fallback para outro índice único quando necessário, sempre metadados validados. Tipos escalares suportados; chave única desconhecida/extents/fonte repetida/LEFT ou pipelines de transformação(distinct/group/aggregate/having) recusados. Cinco consultas atuais de linhas elegíveis; tabelas-preco-por-container comdistinct mantém offset/full. Nenhuma definição operacional alterada.

Keyset: predicado lexicográfico com igualdade de prefixo e comparação da próxima chave, aplicado ao WHERE dinâmico antes de QUERY-OPEN; sem loop de descarte de offset. Literais gerados por tipo, nomes somente do plano validado. Nulos na ordenação seguem ABL(? alto); valores desconhecidos em chave única recusados. Semsnapshot: alterações da própria chave ainda podem mover linhas. Benefício físico depende do plano/índices.

Cursor assinado HMAC-SHA256, payload UTF8hex, verificaçãoantesdecode e comparação de assinatura completa; TTL900s. Vínculo porhash com consumidor(case-sensitive)/geração de credencial/código/modelo materializado+filtros/pageSize/metadados e ordenação. Chave dedicada256bits fora da raizpública: accessTokenStore+'.cursor.key', Linux600/parent700. Não reutilizar token/adminsecret; provisionar chave no servidor, sem copiar para chat/fontes/exports. Falha fechada503 se indisponível. Expiração/contexto adulterado400. Não manter query/handles/sessão entre chamadas.

Isolamento: hook protegido padrão delega execução atual; apenas wrapperseguro roleconsumer chama serviço executeCursor. Estado de cursor/flags limposFINALLY. Fontes compartilhadas não registram comportamento em outroPASOE; configurações/handlers/permissões intactos. Basecandidato derivado do fonte remoto atual para preservar alterações locais anteriores de metadados não publicadas.

- [x] RED/GREEN PHP: campos/tipos/conflitos, documentos e coleção; ABLhelper: vetoresHMAC, adulteração/TTL/binding, tipos/chaves/nulos/orderascdesc/seek comTT e múltiplosbuffers.
- [x] Serviço/builder/hook comseek, segurança porconsulta; Swagger/Postman com exemploscursor e variáveis de continuidade semcredenciais.
- [x] Oficial12.2quatroculturas/encodings, regressões offset/full/security; revisão independente antes de publicar.
- [x] Backups/hash/segredo privado/refreshsóMED; navegação real completa/duplicidades/última/vazia/replay/contexto/tokenrenovado/permissãonegada, Swagger/Postman/PASOEdireto. Limparfixtureprópria, registrar contexto/recibos/links.

Validação final: 209 checks ABL por combinação (UTF8/ISO8859-1 × AMERICAN/EUROPEAN), 214 PHP e11 Postman em VM. Swagger/OpenAPI e coleção importados pelos validadores oficiais; 12 requisições na coleção. Navegador LDAP/Newman35 checks e PASOE direto11. Saldo6939 registros em7 páginas de1000, mesmo multiconjunto da execução completa; token renovado/replay/negativos/permissão revogada/segredo rotacionado passaram. Primeiro erro negativo503 foi reproduzido no compilador e corrigido com CATCH escopado no novo fluxo; verificação do pipeline original acrescentada após constatar perda de distinct no modelo runtime. Hash da definição original e contagem de etapas agora também validados. Revisão independente sem P1/P2.

Limitações encontradas antes desta entrega: duas definições do catálogo web ausentes no armazenamento PASOE (moeda-precos-atuais-por-container, pp-container-por-container); pp-it-container-por-container recusada como incompatível no runtime; tabelas-preco-por-container recusada por distinct conforme contrato. Não publicar definições/índices para contornar. Consulte docs/PAGINACAO_CURSOR_CONSULTAS.md. Recibos privados em temp/consumer-cursor-20261027; não repetir publicadores ou fixtures concluídos.

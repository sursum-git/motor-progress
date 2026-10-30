# Paginação externa — sursum/MED

Pedido aprovado: page/pageSize opcionais na raiz do POST externo, limites e Swagger/Postman, navegação real entre páginas. Decisão: inteiros JSON, page1..1000000 e pageSize1..1000, sem coerção de texto/decimal/bool/null. Ausência mantém configuração salva com teto1000 aplicado ao consumidor. Sem override de definição/SQL/contexto/permissões. Metadados atuais page/pageSize/recordsReturned/hasMore preservados; paginação offset, sem snapshot/totalcount.

Isolamento: hook protegido padrão semefeito no DynamicQueryWebHandler; somente SecuredDynamicQueryWebHandler com roleconsumer aplica helper validado. Política consumer aceita somente os dois novos campos alémdecode/parameters; valida também PASOEdireto. Nenhum handler adicional registrado, nenhum outro contexto ativado. Fontebase compartilhada recebe apenas hooksemcomportamento para outros handlers/admins.

- [x] RED/GREEN contratosPHP gateway/docs eABLhelper/policy: tipos, faixas, omitteddefaults, capdefault, querypermission/bloqueiosanteriores.
- [x] Implementar hook/helper, APIexternal egeradorSwagger/Postman; snapshots/docs atualizados.
- [x] Compilar oficialOE12.2, suitesABL quatroencodings/culturas ePHP/JS/validators; revisãoindependente.
- [x] Publicar artefatos comguardashash/backups, recarregar somenteMEDocioso; verificar páginas1/2/última/vazia/erros/permissões emAPIexterna/PASOE. Removerfixtureprópria, preservarpolicy/configsdosdemais, registrarrecibos/contexto.

Ampliação autorizada pelo usuário: paginate:false desativa paginação e retorna conjuntofiltrado completo, page1/pageSizenull/hasMorefalse/paginatefalse. Limitesdegatewayexistentes permanecem. Implementação: serviço comexecuteUnpaged síncrono eflagprivadaresetada emFINALLY, acessível somente peloramo protegido consumer. Nenhuma alteração do modelo compartilhado/serializador. Hook aplicado apósdesserialização para respeitar defaultsnullable epipelinelimitsemprebordado.

Concluído: oficial12.2/172checks×4culturas/encodings; PHP201 ePostmanJS8; navegador28+PASOEdireto9, modo completo6939registros eúltimapágina7/939. Publicados14runtime+3web; refreshsóMED105/106; fixture/tokenremovidos/policy/configs preservados. Candidatoexato versionado em integration-src/consumer-pagination para preservar alteraçõeslocaisanteriores do canônico. Recibos temp/consumer-pagination-20261027.

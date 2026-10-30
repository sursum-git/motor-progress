# Swagger e Postman — implementação

**Objetivo:** documentar todas as consultas do catálogo publicado e permitir autenticar/informar filtros/executar/visualizar retorno, além de exportar coleçãoPostman2.1.
**Arquitetura:** endpointPHP autenticado geraOpenAPI3.0.3/Postman pelo catálogo real, sem SQL/fontes/bancos/segredos; SwaggerUI vendorizado localmente e página com client_credentials em memória. POSTquery.php único com schemas/exemplos porcode, sem inventar rotas. Execução exclusivamente tokenconsumer no destino público fixoMED; catálogo mantém loginLDAPexistente. SemmudançaABL/PASOE/admin/grants.
**Restrições:** sursum-api/MED9911 somente; administração de credenciais continua tadeu.parreiras. Nenhuma credencial emstorage/log/download. Downloads gerados com campos vazios para credenciais. Filtragem permaneceJSONparameters, referência cod-refer. Reusar caminho catálogo e precedência atuais; filtros duplicados de data viram um parâmetro lógico.

- [x] RED/GREEN PHP: catálogo, schemas, fontes/required/zeros,6consultas, respostas/erros, token/apiKey,Postman2.1comscriptscache900s semsegredos; sem caminhos administrativos/targets.
- [x] Página SwaggerUIlocal,formcredenciais/limpar,tryitout, renovaçãoemmemória eallowlistestrita dointerceptor; exemplos/coleção/OpenAPIpara download e menu.
- [x] ValidarOpenAPI/coleção comvalidators e executarcoleção viaNewman ouSDKoficial; browserreal executaautenticação/consulta4filtros/retorno/negação403, limpeza e download.
- [x] Publicar somenteweb,hash/backup e confirmarcatálogovivo; nenhuma recompilaçãoABL/recargaPASOE. Fixturesconsumertemporáriasremovidas, políticas/hash/admin/instânciaspreservadas. Revisãoindependente/documentação/contexto/links finais.

Validação concluída: 56 checks PHP + 8 Postman + 119 regressões de segurança; OpenAPI local/publicado e importação oficial SDK; navegador LDAP/Newman real24checks. Publicação web com backup/hash, consumidor efêmero removido, política e demais PASOEs preservados. Recibos ignorados temp/api-docs-20261027.

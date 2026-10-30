## Instancia padrao — determinacao de 25/09/2026

Determinacao de 27/10/2026: a politica de token por consumidor/permissao por consulta e protecao administrativa de DynamicQuery deve ser ativada **somente em sursum-api/MED/9911**. Nao aplicar nos demais PASOEs nem no contexto IMA. Classes compartilhadas nao autorizam registrar o handler seguro em outros destinos.

Administracao web de consumidores e tokens: acesso inicialmente exclusivo ao usuario LDAP `tadeu.parreiras`, conforme autorizacao expressa de 27/10/2026. Nao ampliar para todos os usuarios autenticados. Credenciais administrativas de servico sao protegidas contra alteracao pela pagina.

Rota externa `web/api/query.php`: recebe exclusivamente o token do consumidor, encaminhando somente POST de consulta salva ao destino fixo sursum-api/MED/9911. Nunca usar a credencial administrativa do proxy nesse gateway nem aceitar destino/contexto/rota arbitrarios do cliente. Administracao continua separada e protegida por login/CSRF.

Usar sempre a instancia sursum-api, contexto med, HTTPS 9911 (https://192.168.0.111:9911/med/web). Usar sursum-api-teste/9921 somente quando o usuario pedir explicitamente. Esta determinacao substitui as orientacoes anteriores deste documento que indicam a instancia de teste como padrao; registros de validacoes anteriores continuam historicos.

# Instrucoes do projeto motor-progress

Leia context/PROJECT_CONTEXT.md ao iniciar uma tarefa. Os fontes atuais pertencem a este checkout v2; nao alterar v1 nem o checkout antigo na pasta pai por engano.

## Publicacao e validacao obrigatorias

Por determinacao do usuario em 25/09/2026, toda alteracao nos fontes executaveis deve incluir compilacao compativel, publicacao e validacao no ambiente real antes da conclusao. Usar a skill [motor-progress-publicar-pasoe](skills/motor-progress-publicar-pasoe/SKILL.md), tambem invocavel como `$motor-progress-publicar-pasoe`. Se ela nao aparecer no catalogo da sessao, ler o SKILL.md indicado diretamente e seguir o procedimento.

A publicacao pertinente faz parte da tarefa autorizada: nao parar apenas nos testes locais nem pedir novamente permissao para o mesmo fluxo. Respeitar eventual instrucao explicita do usuario para nao publicar. Alteracoes exclusivamente documentais, de contexto ou de skills nao exigem publicar programas.

Compilar ABL no OpenEdge 12.2 do 192.168.0.42; publicar os artefatos pertinentes no 192.168.0.137; validar no PASOE 192.168.0.111, instancia sursum-api-teste, contexto med, HTTPS 9921. Outros ambientes exigem destino explicitamente definido. Nao usar o compilador local 12.8 para gerar os .r dessa publicacao. Ler a skill para os caminhos, dependencias, autenticacao e criterios de verificacao.

Nao persistir senhas no repositorio ou na skill. Informar bloqueios reais e distinguir compilacao, publicacao e validacao; nunca declarar validacao remota quando so houve testes locais.

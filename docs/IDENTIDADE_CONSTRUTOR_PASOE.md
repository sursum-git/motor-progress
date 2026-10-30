# Identidade do construtor nas execuções PASOE

Correção publicada e validada em 15/10/2026, instância `sursum-api`, contexto `med`.

## Comportamento

Para fontes com `responseContract=sursum-programs`, o cliente HTTP do backend envia `X-Sursum-User` e `X-Session-Id` a partir da sessão autenticada ativa, validada pelo token do construtor. Valores de usuário/sessão configurados na fonte são substituídos sem distinguir maiúsculas; valores fornecidos no payload ou no navegador não definem a identidade enviada. Não se encaminham senha ou token de login do construtor. A credencial específica da integração continua no cabeçalho próprio.

As fontes genéricas mantêm seu comportamento e não recebem automaticamente identidade interna. O cache de serviços Symfony foi atualizado após acrescentar a dependência do resolvedor de autenticação.

No Progress, a captura conserva as variáveis explícitas do ambiente e acrescenta os seguintes fallbacks:

- Agente: `agent-<ASID>`, obtido do parâmetro `-ASID` em `SESSION:STARTUP-PARAMETERS`. Valores inválidos não geram identidade inventada.
- Instância: nome do diretório apontado por `CATALINA_BASE`; o fallback incorreto para `DLC_DEFAULT` foi removido.
- PID e duração: captura anterior preservada.

Referências oficiais: [identificação do agente por ASID](https://progress.my.salesforce-sites.com/ProgressKB/articles/Knowledge/which-appserver-agent-is-executing-a-program), [variáveis Catalina no OpenEdge 12.2](https://docs.progress.com/bundle/pas-for-openedge-introduction-122/page/Catalina-environment-variables.html).

## Publicação

Compilador: OpenEdge 12.2.12 no Windows 192.168.0.42. Foram publicados `PasoeExecutionContext.{cls,r}` e a nova dependência `PasoeRuntimeIdentity.{cls,r}` na raiz `/mnt/datasul/ERP/sursum`. A versão implantada foi construída a partir do fonte publicado, com apenas os dois fallbacks novos; alterações locais preexistentes relativas a outros metadados de request foram preservadas no checkout e não incorporadas implicitamente à publicação.

Monitor: somente os campos/colunas de agente e instância foram acrescentados ao `app.js` publicado em `/dados/pasoe/sursum-api/webapps/med/pasoe-request-monitor`. Mudanças locais preexistentes de eventos não foram publicadas por este fluxo.

Hashes anteriores e novos foram conferidos. Backup: `/tmp/codex-pasoe-identity-20261015/backup-20261015T113511Z`. Nenhuma alteração de schema, autenticação global, PROPATH ou reinicialização da instância foi necessária. O acesso de validação continuou pelo túnel SSH para o conector 9910 da mesma instância; HTTPS9911 não foi revalidado nesta tarefa.

## Evidências

- Teste PHP antes da alteração: duas falhas específicas de identidade não propagada/cabeçalhos configurados aceitos. Após alteração, suíte relacionada aprovada: 26 testes, 109 assertions.
- Teste ABL antes da alteração: compilou no 12.2 e falhou por não obter instância de `CATALINA_BASE`. Após correção: compilação sem erros e 10 verificações de identidade aprovadas, incluindo paths Windows/Linux, ASID, entradas inválidas e identidade do usuário.
- Consulta autenticada real pelo PHP, com usuário falso no payload e no header do navegador: registro PASOE identificou `admin`.
- Execução real `EXE-20261015-030919-863783`: `userName=admin`, `pasoeAgent=agent-3`, `pasoeInstance=sursum-api`, `pasoePid=2118550`, duração20ms, statuscompleted. Processo do servidor conferido com ASID3 e CATALINA_BASE da instância.
- Monitor no Edge exibiu esses campos na consulta e nos detalhes, sem erro JavaScript. Captura privada: `.runtime/construtor-pg/pasoe-identidade-monitor.png`.
- Regressão do roteador publicado: oito casos aprovados. Consulta/autenticação/paginação/tradução de erro da integração empresas continuaram aprovadas. Monitor local de integridade:999 registros,0inválidos.
- Revisão de código independente: sem achados bloqueantes.

Os dados passam a ser preenchidos em **novas execuções**. Registros antigos não foram alterados. Os testes desta tarefa não modificaram empresas ou outros dados de negócio.

## Consulta

Abrir `http://127.0.0.1:19910/med/pasoe-request-monitor/index.html` com o túnel SSH ativo. No campo Base PASOE usar `/med/web/SursumDynamicQuery`, filtrar Endpoint por `empresas` e clicar Atualizar. Após a atualização do JavaScript, recarregar com Ctrl+F5.

Scripts de verificação: `tools/construtor-local/verify-pasoe-identity.cjs --require-runtime` e `verify-pasoe-monitor.cjs`. Evidências privadas: `pasoe-identity-evidence.json` e `pasoe-monitor-evidence.json`.

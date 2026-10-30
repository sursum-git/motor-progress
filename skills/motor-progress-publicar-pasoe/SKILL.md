---
name: motor-progress-publicar-pasoe
description: Use quando alterar fontes ABL/OOABL, includes, handlers ou configuracoes de runtime do projeto motor-progress e for preciso compilar no OpenEdge 12.2, publicar e validar pelo PASOE real. Tambem atende pedidos explicitos de publicacao desse projeto.
---

## Instancia padrao — determinacao de 25/09/2026

Usar sempre a instancia sursum-api, contexto med, HTTPS 9911 (https://192.168.0.111:9911/med/web). Usar sursum-api-teste/9921 somente quando o usuario pedir explicitamente. Esta determinacao substitui as orientacoes anteriores deste documento que indicam a instancia de teste como padrao; registros de validacoes anteriores continuam historicos.



# Publicar e validar Motor Progress

## Compromisso do projeto

O usuario determinou em 25/09/2026: apos modificar os fontes, compilar, publicar e testar no PASOE antes de considerar a tarefa concluida. Executar esse fluxo como parte da alteracao autorizada, sem pedir novamente confirmacao para a mesma publicacao. Teste local nao substitui validacao do artefato publicado. Se acesso, compilacao ou teste impedir a conclusao, informar exatamente o que ficou pendente.

A mudanca pode reunir varios arquivos e ajustes locais antes de uma publicacao coerente. Alteracoes exclusivamente em documentacao ou skills nao exigem publicar programas. Para mudancas web/PHP, consultar o destino web em context/PROJECT_CONTEXT.md; nao copiar esses arquivos para o compartilhamento ABL por analogia.

Localizar o checkout atual pela presenca de context/PROJECT_CONTEXT.md. Nesta maquina ele fica em D:/opencode/motor-progress/v2; v1 e o repositorio antigo na pasta pai nao sao o destino dos fontes atuais. Ler AGENTS.md e context/OPENEDGE_PASOE_CONTEXT.md do checkout. A copia versionada desta skill fica em skills/motor-progress-publicar-pasoe; mantê-la sincronizada com a instalacao pessoal ao editar a skill.

## Ambiente confirmado

| Funcao | Destino |
|---|---|
| Compilador | Windows 192.168.0.42, usuario tadeu.parreiras, C:\Progress_12\OE, OpenEdge 12.2.12 |
| Runtime | Linux 192.168.0.111, usuario root, /usr/dlc12, OpenEdge 12.2.17 |
| Publicacao principal | \\192.168.0.137\erp\sursum = /mnt/datasul/ERP/sursum no Linux |
| Programas http-api | \\192.168.0.137\erp\especificos\ems2\ima\http-api = /mnt/datasul/ERP/especificos/ems2/ima/http-api |
| Validacao padrao | Instancia /dados/pasoe/sursum-api-teste, contexto med, HTTPS 9921 |
| Base HTTP de teste | https://192.168.0.111:9921/med/web |

Confirmar versao e caminhos antes de publicar se o ambiente mudou. O OpenEdge local C:\Progress\OpenEdge e 12.8; nao publicar seus .r no runtime 12.2. A instalacao 12.2.17 no Linux tem licenca de execucao: tentar compilar fontes nela falha com erro 471. Compilar no Windows 192.168.0.42.

Usar acesso SSH/chave/gerenciador de credenciais ja autorizado. Se uma senha for fornecida na sessao, usa-la somente em memoria ou entrada oculta. Nao gravar senhas em skill, contexto, scripts, logs, argumentos de processo ou Git. Manter verificacao da chave SSH; confirmar divergencias, sem desabilitar a verificacao. Uma sessao interativa generica como root foi rejeitada pela revisao automatica; preferir operacoes limitadas com arquivos e comandos concretos de compilacao, publicacao e teste. Nao contornar rejeicoes de aprovacao.

## Procedimento

1. **Delimitar a entrega.** Inspecionar diff e dependencias. Montar manifesto fonte -> compilado -> destino; incluir dependentes de includes e classes alterados e preservar alteracoes alheias. Resolver a ordem efetiva do PROPATH para nao deixar um .r antigo sombreando o novo. Identificar os consumidores do compartilhamento: o destino de publicacao foi autorizado, mas arquivos compartilhados podem ser lidos por outras instancias mesmo sem reinicia-las; nao prometer isolamento de arquivos so por usar a porta de teste. Alteracao de .df requer avaliar dependencias; nao aplicar schema ou migracoes de banco implicitamente.
2. **Compilar no 12.2.** Transferir os fontes e testes relevantes para uma pasta temporaria isolada no usuario do compilador. Usar C:\Progress_12\OE\bin\_progres.exe e PROPATH/includes/aliases apropriados. Compilar com COMPILE ... SAVE NO-ERROR, registrar COMPILER:ERROR e ERROR-STATUS. O exit code sozinho nao prova compilacao correta: um runner ABL pode chamar QUIT apos falhar e sair com codigo zero. Nao reutilizar .r ou logs de uma tentativa anterior como evidencia da atual. Executar os testes ABL relacionados; usar a configuracao de bancos documentada apenas quando necessaria.
3. **Publicar os artefatos aprovados.** Transferir somente fontes, .r gerados pela compilacao 12.2 bem-sucedida e configuracoes pertinentes previstas no manifesto. Pode-se usar SFTP pelo 192.168.0.111 para escrever na montagem do compartilhamento do 192.168.0.137; confirmar o mapeamento com findmnt. Preservar uma copia dos arquivos existentes antes de substitui-los, verificar hashes apos a transferencia e evitar arquivos parcialmente escritos visiveis ao runtime. Para dependencias atualizadas em conjunto, preparar o lote em staging e usar troca coerente ou janela controlada de carga; substituicoes individuais nao garantem consistencia do lote. Mesclar registros de JSON/handlers preservando os existentes; nao substituir um catalogo operacional pelo exemplo do repositorio. Nao publicar fixtures dos testes ou todo o workspace.
4. **Carregar a alteracao.** Atualizar somente a instancia alvo. Para este fluxo, o alvo e sursum-api-teste/med (9921). A instancia sursum-api (9911) e outro ambiente, nao um fallback quando um teste falha. Preservar configuracoes e servicos das demais instancias. Se for necessario recarregar agentes ou reiniciar para eliminar cache de .r, usar os scripts da propria instancia de teste. Confirmar que ela parou antes de iniciar; nao usar kill amplo. A instancia possui tambem ima, portanto preferir recarga especifica quando disponivel e avisar quando o reinicio da instancia for necessario. Nao alterar autenticacao, PROPATH global ou schemas para fazer o teste passar.
5. **Testar pelo PASOE.** Esperar prontidao HTTP com prazo limitado: "Tomcat started" precede a abertura efetiva da porta. Depois executar a suite relacionada e confirmar status, headers e conteudo, inclusive acentos. Testes ignorados por variavel de ambiente ausente nao contam como validacao. Confirmar que o programa resolvido pelo PROPATH e o artefato desta entrega, com verificacao de caminho/cache e teste que distinga o comportamento alterado. Usar exemplos sem efeito de negocio; nao executar .p desconhecidos para apenas experimentar. Se o comportamento exigir efeitos de negocio e nao houver cenario seguro autorizado, informar que a validacao especifica permanece pendente e solicitar o cenario/dados necessarios, sem substituir a prova por echo ou fixture. Se falhar, analisar logs recentes da instancia med, corrigir a causa, recompilar, republicar e testar novamente. Em falha operacional, restaurar apenas os artefatos desta entrega quando necessario, preservando mudancas concorrentes; nao tentar outra instancia ou ampliar privilegios como atalho.
6. **Registrar o resultado.** Informar versao do compilador, destino, instancia/contexto/URL e resultado real dos testes. Se houver bloqueio, separar o que foi compilado, publicado e validado. Atualizar contexto/documentacao quando mudarem caminhos, procedimentos ou contratos. Nao incluir credenciais.

## Roteador JSON separado

Consultar docs/JSON_PROGRAM_ROUTER.md para o contrato. Mapeamento publicado confirmado:

| Fonte no checkout | Destino relativo a /mnt/datasul/ERP/sursum |
|---|---|
| sursum-api/sursum/JsonProgramRouter.cls | JsonProgramRouter.cls e JsonProgramRouter.r |
| sursum-api/rest/JsonProgramWebHandler.cls | JsonProgramWebHandler.cls e JsonProgramWebHandler.r |
| sursum-api/programs/JsonEcho.p | sursum-api/programs/JsonEcho.p e sursum-api/programs/JsonEcho.r |
| conf-web-handler/program-routes.json | conf-web-handler/program-routes.json (mesclar) |

O handler nao tem namespace; as classes sao encontradas na raiz sursum do PROPATH. O arquivo de registro fica em /dados/pasoe/sursum-api-teste/webapps/med/WEB-INF/adapters/web/ROOT/ROOT.handlers. Manter o handler padrao DynamicQueryWebHandler e acrescentar somente o mapeamento /SursumPrograms/{route:.*} -> JsonProgramWebHandler.

Os programas cadastrados usam caminhos relativos sursum-api/... ou especificos/ems2/ima/http-api/... e assinatura INPUT JsonObject, OUTPUT JsonObject. Para a segunda pasta, /mnt/datasul/ERP precisa constar no PROPATH. Preferir o .r correspondente; nao mover programas de negocio existentes entre as duas pastas.

No compilador 12.2, executar tests/abl/RunJsonProgramRouterTests.p na raiz do staging. Verificar temp/compile-json-router.txt sem erros e temp/json-router-test.txt terminando em PASS: all JSON route cases. O runner compila o roteador e testes; compilar tambem JsonProgramWebHandler.cls e JsonEcho.p com as entradas sursum-api/rest, sursum-api/sursum, raiz e o OpenEdge.Net.pl da instalacao 12.2. Para mudancas de encoding, testar CPINTERNAL padrao e UTF-8. O handler deve preservar bytes UTF-8 no corpo e na resposta: Write(LONGCHAR) pode converter pelo stream WebSpeed; a implementacao validada escreve MEMPTR.

Apos carregar os compilados, executar no checkout:

```powershell
$env:SURSUM_JSON_PROGRAM_BASE_URL = 'https://192.168.0.111:9921/med/web'
npx playwright test tests/e2e/playwright/pasoe-json-program-router-backend.spec.js --workers=1 --reporter=line
```

A suite validada possui oito casos. Se o escopo mudou, acrescentar teste que exercite a mudanca: o sucesso do echo nao prova outros programas. O teste ABL da pasta http-api usa fixture isolada, nao um programa de negocio do compartilhamento. Para o motor dinamico ou outros componentes, escolher suas suites especificas; nao reutilizar estes oito casos como comprovacao universal.

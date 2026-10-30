# Log manual nos programas ABL

O suporte reutiliza `ApiExecutionRepository` e `PasoeExecutionContext` do motor
Progress. Nos programas chamados pelo roteador `/SursumPrograms`, o handler
associa o contexto da execução atual antes de chamar o programa e o limpa no
`FINALLY`. Não é necessário receber executionId ou usuário do JSON.

## Uso

```abl
DEFINE VARIABLE oLog AS ApiExecutionRepository NO-UNDO.
DEFINE VARIABLE logAceito AS LOGICAL NO-UNDO.

oLog = NEW ApiExecutionRepository().

DO TRANSACTION ON ERROR UNDO, THROW:
    /* Validacoes e gravacoes do programa. */
    logAceito = oLog:logMessage("info", "Validacao de custo concluida").
END.

DELETE OBJECT oLog.
```

Em um programa real, colocar a exclusão de `oLog` no `FINALLY` do bloco que
possui o objeto. A chamada pode ser feita dentro ou fora do `DO TRANSACTION`.
Níveis disponíveis: `debug`, `info`, `warning`, `error` (sem diferenciar
maiúsculas/minúsculas). Registrar somente as mensagens desejadas pelo programa;
não há instrumentação automática de todas as regras.

`TRUE` significa que a mensagem foi aceita na fila da request. `FALSE` indica
ausência de contexto/execução, nível inválido, mensagem desconhecida ou maior
que4.000 caracteres. A aplicação não deve incluir credenciais nas mensagens.

## Gravação e consulta

A fila pertence à instância de `PasoeExecutionContext` e usa temp-table
`NO-UNDO`. Depois que o programa termina e a transação de negócio foi encerrada,
o handler chama `flushLogMessages(contexto)` para gravar os eventos na estrutura
existente **espec.sursum_req_pasoe_evento**. O registro da execução fica em
**espec.sursum_req_pasoe**. Os eventos têm status `log.info`, `log.warning` etc.,
mensagem, instante original e contexto do usuário/execução.

Por isso, uma mensagem aceita antes de um `UNDO` continua disponível para
gravação. A gravação dos logs ocorre fora da transação de negócio, sem alterar
o status da execução: o handler continua responsável por completed/failed.
Sem mensagens, não há gravação adicional de eventos manuais.

Consultar no [monitor PASOE](http://127.0.0.1:19910/med/pasoe-request-monitor/index.html),
selecionando a execução e seus eventos. API de consulta:
`GET /med/web/SursumDynamicQuery/executions/{executionId}/events?limit=100`.
Esse é o log do backend Progress; os logs da chamada PHP continuam no construtor.

`flushLogMessages` recusa execução dentro de uma transação ativa. Se a persistência
falhar ou o contexto serializado ultrapassar30.000 caracteres, retornaFALSE e
mantém a fila; o handler registra a falha no log do agente PASOE. Não transforma
uma falha de log em confirmação falsa nem altera o resultado de negócio.
O contexto não deve ser excluído pelo programa consumidor: pertence ao handler.

Programas executados fora desse roteador não recebem automaticamente `Current`.
Nesses casos, o chamador deve criar/iniciar a execução pelas classes existentes,
associar o contexto e realizar flush/limpeza ao terminar.

## Fontes e publicação

Canônicos:

- `D:/opencode/motor-progress/v2/sursum-api/sursum/PasoeExecutionContext.cls`
- `D:/opencode/motor-progress/v2/sursum-api/sursum/ApiExecutionRepository.cls`
- `D:/opencode/motor-progress/v2/sursum-api/rest/JsonProgramWebHandler.cls`

Fontes efetivamente publicados, com delta aplicado sobre baseline remoto:
`D:/opencode/conversao-sc/integration-src/program-log`. Alterações canônicas
preexistentes e ainda não publicadas foram preservadas e não entraram por
acidente nesta entrega. Testes em `tests/abl/program-log` no motor e na pasta
de integração deste workspace. A fixture de verificação é temporária e protegida,
usa somente temp-table para simular rollback e não altera dados de negócio.

Compilar no OpenEdge12.2 do .42, publicar somente os pares.cls/.r pertinentes e
validar no PASOE sursum-api/med. Após atualizar o handler, recarregar seu contexto
WEB med; procedimento suportado pela [documentação Progress12.2](https://docs.progress.com/bundle/pas-for-openedge-management-122/page/Deploy-web-handler-services.html).

Validação em15/10/2026: três classes e fixture compiladas no12.2 sem erro;
23 testes ABL passaram. No PASOE real, uma mensagem no caminho de sucesso,
duas no cenário com rollback de temp-table e nenhuma na chamada seguinte
foram conferidas nos eventos, com executionId/usuário corretos e Unicode.
O payload do cliente não escolhe a execução usada pelo logger. A fixture foi
protegida pelo token da integração existente e removida depois do teste.
Não houve gravação em tabelas de negócio. Oito regressões HTTP do roteador e
leitura dos quatro cadastros existentes passaram.

Artefatos e logs12.2: `.runtime/program-log-compiled-20261015`. Manifesto dos
seis arquivos permanentes: `.runtime/program-log-publish-20261015/active-manifest.json`.
Backup remoto: `/tmp/codex-program-log-20261015/backup-20261015T232621Z`.
Foi feita somente recarga WEB de med (`jmx refreshWeb -appname med -webappname med`),
sem reiniciar a instância e sem mudar o contexto ima. Evidência HTTP privada:
`.runtime/construtor-pg/program-log-evidence.json`. Na fixture, a leitura do
JSON de configuração exige FIX-CODEPAGE UTF-8 por causa do CPINTERNAL do PASOE;
o código de negócio e o contrato de autenticação não foram alterados.

## Consulta no formulário do construtor

A integração posterior acrescenta o botão Logs ao formulário e usa as consultas existentes admin.transacoes/admin.logs-transacoes. No contrato sursum-programs, X-Sursum-Execution-Id/X-Sursum-Log-Count correlacionam a execução; PHP importa mensagens manuais progress.log.* na transação local. Eventos permanecem também no Progress, inclusive após rollback. Instante original, usuário, agente, instância e PID disponíveis são preservados. Sem mensagens, não consulta eventos. Falha de consulta gera aviso seguro sem mudar negócio. Não representa transação distribuída.

Guia completo: D:/opencode/conversao-sc/docs/logs-no-formulario.md. Fontes mínimos atuais em integration-src/program-log-ui; manifestos atuais dos handlers em conversao-sc/.runtime/program-log-ui-publish-20261015 e events-utf8-publish-20261016. DynamicQueryWebHandler agora escreve bytes UTF-8 por MEMPTR para manter JSON válido com acentos. Compilado12.2/publicado/validado no PASOE. E2E real pelo botão passou em15/10/2026; fixture temporária removida após teste, sem registros de negócio de teste restantes.

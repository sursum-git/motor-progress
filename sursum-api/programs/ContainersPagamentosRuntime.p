/* Payment orchestration only: reuse financial/currency and fiscal services.
   Optional reader is a trusted test double; production always supplies ?. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phFiscalRules AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phFinancialRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phReader AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phBuffers AS HANDLE EXTENT 10 NO-UNDO.
DEFINE INPUT PARAMETER poFinancePolicy AS JsonObject NO-UNDO.
PROCEDURE RequireTransaction:
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_TRANSACTION_CONTEXT: pagamentos requerem transacao raiz.",1).
END PROCEDURE.
PROCEDURE ValidateTitle:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER titleId AS INTEGER NO-UNDO.
 DEFINE OUTPUT PARAMETER rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE programPath AS CHARACTER NO-UNDO.
 RUN RequireTransaction.
 IF NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("Container nao localizado.",1).
 requestValue=NEW JsonObject(). requestValue:Add("operation","get"). requestValue:Add("resource","pagamentos-disponiveis").
 requestValue:Add("container_id",master:BUFFER-FIELD("nr-container"):BUFFER-VALUE). requestValue:Add("id",titleId).
 IF VALID-HANDLE(phReader) THEN RUN ReadEligible IN phReader(requestValue,OUTPUT responseValue).
 ELSE DO:
  IF phReader<>? THEN UNDO, THROW NEW Progress.Lang.AppError("Adaptador privado indisponivel.",1).
  programPath=SEARCH("sursum-api/programs/ContainersPainelFinanceReadService.r").
  IF programPath=? THEN programPath=SEARCH("ContainersPainelFinanceReadService.r").
  IF programPath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de elegibilidade nao publicada.",1).
  RUN VALUE(programPath)(phBuffers[1],phBuffers[2],phBuffers[3],phBuffers[4],phBuffers[5],phBuffers[6],phBuffers[7],phBuffers[8],phBuffers[9],phBuffers[10],poFinancePolicy,requestValue,OUTPUT responseValue).
 END.
 IF NOT VALID-OBJECT(responseValue) OR NOT responseValue:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Titulo nao disponivel para associacao neste container.",1).
 rowValue=CAST(responseValue:GetJsonObject("data"):Clone(),JsonObject).
END PROCEDURE.
PROCEDURE ChangePayment:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE financial AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscal AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscalContext AS JsonObject NO-UNDO.
 DEFINE VARIABLE changes AS JsonArray NO-UNDO.
 DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF NOT VALID-HANDLE(phFinancialRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao financeira indisponivel.",1).
 IF contextValue:GetCharacter("operation")<>"associate" AND contextValue:GetCharacter("operation")<>"disassociate" THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao de vinculo invalida.",1).
 RUN RunFinancial IN phFinancialRuntime(master,contextValue,OUTPUT financial).
 IF NOT VALID-OBJECT(financial) OR NOT financial:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Rateios financeiros recusados.",1).
 changes=CAST(financial:GetJsonArray("changes"):Clone(),JsonArray). warnings=NEW JsonArray().
 DO n=1 TO financial:GetJsonArray("warnings"):Length:
  IF financial:GetJsonArray("warnings"):GetType(n)=JsonDataType:OBJECT THEN warnings:Add(financial:GetJsonArray("warnings"):GetJsonObject(n):GetCharacter("message")).
  ELSE warnings:Add(financial:GetJsonArray("warnings"):GetCharacter(n)).
 END.
 /* Legacy association runs taxes after financial allocation. Unlink does not. */
 IF contextValue:GetCharacter("operation")="associate" THEN DO:
  IF NOT VALID-HANDLE(phFiscalRules) THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao fiscal indisponivel.",1).
  fiscalContext=NEW JsonObject(). fiscalContext:Add("operation","update"). fiscalContext:Add("container_id",contextValue:GetInteger("container_id")).
  RUN OnUpdate IN phFiscalRules(master,fiscalContext,OUTPUT fiscal).
  IF NOT VALID-OBJECT(fiscal) OR NOT fiscal:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Sincronizacao fiscal recusada.",1).
  DO n=1 TO fiscal:GetJsonArray("changes"):Length: changes:Add(CAST(fiscal:GetJsonArray("changes"):GetJsonObject(n):Clone(),JsonObject)). END.
  IF fiscal:Has("warnings") THEN DO n=1 TO fiscal:GetJsonArray("warnings"):Length: warnings:Add(fiscal:GetJsonArray("warnings"):GetCharacter(n)). END.
 END.
 resultValue=NEW JsonObject(). resultValue:Add("success",TRUE). resultValue:Add("changes",changes). resultValue:Add("warnings",warnings).
END PROCEDURE.

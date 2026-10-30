/* Private persistent callbacks for ContainersCabecalhoRules.p. The public
   wrapper creates this procedure itself; there is no browser-selected policy,
   executionId, callback, path, sequence, database or query input.
   phCostReader=? in production. Tests supply a trusted procedure double. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phCostReader AS HANDLE NO-UNDO.
/* Each proof owns buffers until this persistent runtime is destroyed AFTER
   the root transaction. Never reuse/release a proof buffer before its effect. */
CREATE WIDGET-POOL.

FUNCTION MasterSnapshot RETURNS JsonObject (master AS HANDLE):
 DEFINE VARIABLE result AS JsonObject NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE textValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE intValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE numberValue AS DECIMAL DECIMALS 10 NO-UNDO.
 names="vl-dolar-compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar".
 result=NEW JsonObject().
 DO n=1 TO NUM-ENTRIES(names):
  fieldHandle=master:BUFFER-FIELD(ENTRY(n,names)).
  IF fieldHandle:EXTENT<>0 OR fieldHandle:BUFFER-VALUE=? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: campo de cotacao desconhecido.",1).
  CASE fieldHandle:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: textValue=fieldHandle:BUFFER-VALUE. result:Add(ENTRY(n,names),textValue). END.
   WHEN "INTEGER" THEN DO: intValue=fieldHandle:BUFFER-VALUE. result:Add(ENTRY(n,names),intValue). END.
   WHEN "DECIMAL" THEN DO: numberValue=fieldHandle:BUFFER-VALUE. result:Add(ENTRY(n,names),numberValue). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: tipo fisico de cotacao invalido.",1).
  END CASE.
 END.
 RETURN result.
END FUNCTION.
FUNCTION LastRate RETURNS DECIMAL (memory AS JsonObject, fieldName AS CHARACTER):
 DEFINE VARIABLE attempts AS JsonArray NO-UNDO.
 DEFINE VARIABLE attempt AS JsonObject NO-UNDO.
 DEFINE VARIABLE valueRate AS DECIMAL DECIMALS 10 NO-UNDO.
 IF NOT memory:Has(fieldName) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: historico de cotacao ausente.",1).
 IF memory:GetType(fieldName)<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: historico de cotacao invalido.",1).
 attempts=memory:GetJsonArray(fieldName).
 IF attempts:Length=0 OR attempts:GetType(attempts:Length)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: cotacao nao resolvida.",1).
 attempt=attempts:GetJsonObject(attempts:Length).
 IF NOT attempt:Has("value") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: valor de cotacao ausente.",1).
 IF attempt:GetType("value")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: cotacao deve ser numerica.",1).
 valueRate=attempt:GetDecimal("value").
 IF valueRate=? OR valueRate<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: cotacao positiva nao confirmada.",1).
 RETURN valueRate.
END FUNCTION.
PROCEDURE RequireTransaction:
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_TRANSACTION_CONTEXT: callback requer transacao raiz ativa.",1).
END PROCEDURE.
PROCEDURE NextCalculoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 valueId=DYNAMIC-NEXT-VALUE("seq_calcs_imp_container","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_SEQUENCE_UNAVAILABLE: sequencia fiscal indisponivel.",1).
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 valueId=DYNAMIC-NEXT-VALUE("seq_despesas_container","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_SEQUENCE_UNAVAILABLE: sequencia de despesa indisponivel.",1).
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE logger AS ApiExecutionRepository NO-UNDO.
 DEFINE VARIABLE accepted AS LOGICAL NO-UNDO.
 DO ON ERROR UNDO, THROW:
  IF NOT VALID-OBJECT(PasoeExecutionContext:Current) THEN RETURN.
  logger=NEW ApiExecutionRepository().
  accepted=logger:logMessage(levelName,messageText).
  /* Queue only. The authenticated handler owns flush and execution identity. */
  FINALLY: IF VALID-OBJECT(logger) THEN DELETE OBJECT logger NO-ERROR. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE CollectCalculationInputs:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER inputs AS JsonObject NO-UNDO.
 DEFINE VARIABLE request AS JsonObject NO-UNDO.
 DEFINE VARIABLE response AS JsonObject NO-UNDO.
 DEFINE VARIABLE calculation AS JsonObject NO-UNDO.
 DEFINE VARIABLE memory AS JsonObject NO-UNDO.
 DEFINE VARIABLE snapshotBefore AS JsonObject NO-UNDO.
 DEFINE VARIABLE snapshotAfter AS JsonObject NO-UNDO.
 DEFINE VARIABLE rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE row AS JsonObject NO-UNDO.
 DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE dollarPurchase AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE dollarDI AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
 DEFINE VARIABLE snapshotFields AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE beforeText AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE afterText AS LONGCHAR NO-UNDO.
 inputs=?.
 DO ON ERROR UNDO, THROW:
  RUN RequireTransaction.
  IF NOT VALID-HANDLE(master) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre indisponivel.",1).
  IF master:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: buffer mestre requerido.",1).
  IF NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre nao localizado.",1).
  containerId=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
  IF containerId=? OR containerId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: container invalido.",1).
  IF NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: mestre em uso.",1).
  snapshotBefore=MasterSnapshot(master).
  request=NEW JsonObject(). request:Add("operation","read"). request:Add("resource","cotacoes-fiscais"). request:Add("container_id",containerId). request:Add("moeda","real").
  /* Fiscal buscarDolar→buscarDolarMedio(container) keeps logSaldoNeg=false.
     The shared quote-only profile also supports the final deallocation and
     zero quantities, without fabricating an item or computing a unit cost. */
  IF VALID-HANDLE(phCostReader) THEN DO:
   IF phCostReader:TYPE<>"PROCEDURE" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: adaptador privado invalido.",1).
   IF LOOKUP("ReadContainerCost",phCostReader:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: callback privado ausente.",1).
   RUN ReadContainerCost IN phCostReader(request,OUTPUT response).
  END.
  ELSE DO:
   IF phCostReader<>? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: adaptador privado indisponivel.",1).
   servicePath=SEARCH("sursum-api/programs/ContainersCustoRead.r").
   IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: consulta de custo compilada ausente.",1).
   RUN VALUE(servicePath)(request,OUTPUT response).
  END.
  IF NOT VALID-OBJECT(response) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: retorno de custo ausente.",1).
  IF NOT response:Has("success") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: retorno de custo invalido.",1).
  IF response:GetType("success")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: retorno de custo invalido.",1).
  IF NOT response:GetLogical("success") THEN DO:
   IF response:Has("error") THEN DO:
    row=response:GetJsonObject("error").
    UNDO, THROW NEW Progress.Lang.AppError(row:GetCharacter("code") + ": " + row:GetCharacter("message"),1).
   END.
   UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: consulta de custo recusada.",1).
  END.
  IF NOT response:Has("data") OR NOT response:Has("calculation") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: calculo de custo ausente.",1).
  IF response:GetType("data")<>JsonDataType:ARRAY OR response:GetType("calculation")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: calculo de custo invalido.",1).
  rows=response:GetJsonArray("data").
  IF rows:Length=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: container sem calculo de custo.",1).
  DO n=1 TO rows:Length:
   row=rows:GetJsonObject(n).
   IF row:GetType("container_id")<>JsonDataType:NUMBER OR row:GetInteger("container_id")<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: calculo pertence a outro container.",1).
  END.
  calculation=response:GetJsonObject("calculation").
  IF calculation:GetCharacter("source")<>"calc_v1" OR calculation:GetCharacter("financial_source")<>"linked-payment-totals" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CALCULATION_INPUTS: origem de custo nao confirmada.",1).
  memory=calculation:GetJsonObject("memory").
  ASSIGN dollarPurchase=LastRate(memory,"compra_attempts") dollarDI=LastRate(memory,"di_attempts").
  IF NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre perdeu contexto.",1).
  IF master:BUFFER-FIELD("nr-container"):BUFFER-VALUE<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre mudou durante coleta.",1).
  snapshotAfter=MasterSnapshot(master). snapshotFields=snapshotBefore:GetNames().
  DO n=1 TO EXTENT(snapshotFields):
   ASSIGN beforeText=snapshotBefore:GetJsonText(snapshotFields[n]) afterText=snapshotAfter:GetJsonText(snapshotFields[n]).
   IF beforeText<>afterText THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_INPUT_STALE: cotacoes do mestre mudaram durante coleta.",1).
  END.
  inputs=NEW JsonObject(). inputs:Add("confirmed",TRUE). inputs:Add("source","container-cost-collector"). inputs:Add("container_id",containerId).
  inputs:Add("dolar_compra",dollarPurchase). inputs:Add("dolar_di",dollarDI). inputs:Add("container_snapshot",snapshotBefore).
  /* Snapshot ownership moves to the returned input object. */
  snapshotBefore=?.
  FINALLY:
   IF VALID-OBJECT(request) THEN DELETE OBJECT request NO-ERROR.
   IF VALID-OBJECT(response) THEN DELETE OBJECT response NO-ERROR.
   IF VALID-OBJECT(snapshotBefore) THEN DELETE OBJECT snapshotBefore NO-ERROR.
   IF VALID-OBJECT(snapshotAfter) THEN DELETE OBJECT snapshotAfter NO-ERROR.
  END FINALLY.
 END.
END PROCEDURE.

FUNCTION ProofId RETURNS INTEGER (bufferHandle AS HANDLE, fieldName AS CHARACTER):
 DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 IF NOT VALID-HANDLE(bufferHandle) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: buffer ausente.",1).
 IF bufferHandle:TYPE<>"BUFFER" OR NOT bufferHandle:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: registro ausente.",1).
 fieldHandle=bufferHandle:BUFFER-FIELD(fieldName).
 IF fieldHandle:DATA-TYPE<>"INTEGER" OR fieldHandle:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: chave fisica invalida.",1).
 valueId=fieldHandle:BUFFER-VALUE.
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: chave positiva obrigatoria.",1).
 RETURN valueId.
END FUNCTION.
PROCEDURE ProofFind:
 DEFINE INPUT PARAMETER bufferHandle AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER fieldName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE foundRow AS LOGICAL NO-UNDO.
 foundRow=bufferHandle:FIND-FIRST("WHERE " + bufferHandle:NAME + "." + fieldName + " = " + TRIM(STRING(valueId,"->>>>>>>>>9")),SHARE-LOCK,NO-WAIT) NO-ERROR.
 IF bufferHandle:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: vinculo de distribuicao em uso.",1).
 IF NOT foundRow OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: vinculo fisico nao localizado.",1).
END PROCEDURE.
PROCEDURE ValidateDistributionExpense:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER expense AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER proof AS JsonObject NO-UNDO.
 DEFINE VARIABLE ledger AS HANDLE NO-UNDO.
 DEFINE VARIABLE item AS HANDLE NO-UNDO.
 DEFINE VARIABLE cost AS HANDLE NO-UNDO.
 DEFINE VARIABLE version AS HANDLE NO-UNDO.
 DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
 DEFINE VARIABLE expenseId AS INTEGER NO-UNDO.
 DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
 DEFINE VARIABLE ledgerId AS INTEGER NO-UNDO.
 DEFINE VARIABLE costId AS INTEGER NO-UNDO.
 DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
 DEFINE VARIABLE movement AS INTEGER NO-UNDO.
 DEFINE VARIABLE backlink AS INTEGER NO-UNDO.
 DEFINE VARIABLE amountExpense AS DECIMAL NO-UNDO.
 DEFINE VARIABLE amountLedger AS DECIMAL NO-UNDO.
 proof=?.
 RUN RequireTransaction.
 ASSIGN containerId=ProofId(master,"nr-container") expenseId=ProofId(expense,"despesa_container_id").
 IF NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: mestre em uso.",1).
 IF NOT expense:FIND-BY-ROWID(expense:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: despesa em uso.",1).
 ASSIGN itemId=ProofId(expense,"item_container_id") ledgerId=ProofId(expense,"cta_corren_custo_distr_id").
 IF ProofId(expense,"container_id")<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: despesa de outro container.",1).
 /* The adapter is a server-owned handle supplied only by a trusted driver.
    Production fixes all four physical names here; no SQL/table reaches JSON. */
 IF VALID-HANDLE(phCostReader) THEN DO:
  IF phCostReader:TYPE<>"PROCEDURE" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: adaptador privado invalido.",1).
  IF LOOKUP("DistributionBuffers",phCostReader:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: buffers privados de prova ausentes.",1).
  RUN DistributionBuffers IN phCostReader(OUTPUT ledger,OUTPUT item,OUTPUT cost,OUTPUT version).
 END.
 ELSE DO:
  IF phCostReader<>? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: adaptador privado indisponivel.",1).
  CREATE BUFFER ledger FOR TABLE "espec.cta_corren_custo_distr".
  CREATE BUFFER item FOR TABLE "espec.itens_container".
  CREATE BUFFER cost FOR TABLE "espec.item_container_custos".
  CREATE BUFFER version FOR TABLE "espec.versoes_item_custo_container".
 END.
 RUN ProofFind(ledger,"cta_corren_custo_distr_id",ledgerId).
 RUN ProofFind(item,"item_container_id",itemId).
 IF ProofId(item,"container_id")<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: item de outro container.",1).
 ASSIGN movement=ledger:BUFFER-FIELD("cod_tipo_movto"):BUFFER-VALUE costId=ledger:BUFFER-FIELD("item_container_custo_id"):BUFFER-VALUE
  backlink=ledger:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE amountExpense=expense:BUFFER-FIELD("vl_prev"):BUFFER-VALUE amountLedger=ledger:BUFFER-FIELD("vl_lancto"):BUFFER-VALUE.
 IF backlink=? OR (backlink<>0 AND backlink<>expenseId) OR amountExpense=? OR amountLedger=? OR amountExpense<>amountLedger THEN
  UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: movimento diverge da despesa.",1).
 CASE movement:
  WHEN 4 THEN DO:
   IF costId<>0 OR costId=? OR ProofId(ledger,"item_container_id")<>itemId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: retorno sem vinculo direto exato.",1).
  END.
  WHEN 3 THEN DO:
   IF costId=? OR costId<=0 OR ledger:BUFFER-FIELD("item_container_id"):BUFFER-VALUE<>0 OR ledger:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=? THEN
    UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: custo de distribuicao invalido.",1).
   RUN ProofFind(cost,"item_container_custo_id",costId).
   IF ProofId(cost,"item_container_id")<>itemId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: custo de outro item.",1).
   versionId=ProofId(cost,"versao_id"). RUN ProofFind(version,"versao_id",versionId).
   IF ProofId(version,"container_id")<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: versao de outro container.",1).
  END.
  OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DISTRIBUTION_INVALID: tipo de movimento nao gerenciado.",1).
 END CASE.
 proof=NEW JsonObject(). proof:Add("confirmed",TRUE). proof:Add("container_id",containerId).
 proof:Add("despesa_container_id",expenseId). proof:Add("ledger_id",ledgerId).
 /* No BUFFER-RELEASE/DELETE here. Fixed physical proof records stay locked
    in this procedure's private pool until the root transaction has ended. */
END PROCEDURE.

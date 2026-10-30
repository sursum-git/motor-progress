/* One collection + one pure calculation, followed by atomic historical inserts.
   Nested callers MUST undo their root transaction when success=false. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersions AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersionItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemCosts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLabels AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phStockIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phStockMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phMovementsMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phInvoicesIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phInvoicesMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "ITEM_COST_INVALID_REQUEST".
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
DEFINE VARIABLE expectedId AS INTEGER NO-UNDO.
DEFINE VARIABLE newId AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE storagePairs AS CHARACTER NO-UNDO.
DEFINE VARIABLE storedName AS CHARACTER NO-UNDO.
DEFINE VARIABLE calculatedName AS CHARACTER NO-UNDO.
DEFINE VARIABLE bh AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE nestedValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE allowNested AS LOGICAL NO-UNDO.
DEFINE VARIABLE priority AS LOGICAL NO-UNDO.
DEFINE VARIABLE actor AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE mathPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE requestData AS JsonObject NO-UNDO.
DEFINE VARIABLE policyData AS JsonObject NO-UNDO.
DEFINE VARIABLE collected AS JsonObject NO-UNDO.
DEFINE VARIABLE mathResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE calculation AS JsonObject NO-UNDO.
DEFINE VARIABLE inputData AS JsonObject NO-UNDO.
DEFINE VARIABLE provenance AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DEFINE VARIABLE afterData AS JsonObject NO-UNDO.
DEFINE VARIABLE eventData AS JsonObject NO-UNDO.
DEFINE VARIABLE results AS JsonArray NO-UNDO.
DEFINE VARIABLE storedRows AS JsonArray NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE timestampValue AS DATETIME NO-UNDO.
DEFINE VARIABLE fieldNames AS CHARACTER NO-UNDO.
DEFINE VARIABLE costFields AS CHARACTER NO-UNDO.
DEFINE TEMP-TABLE ttPlan NO-UNDO FIELD id AS INTEGER FIELD snapshotId AS INTEGER FIELD position AS INTEGER FIELD beforeData AS CLASS Progress.Lang.Object
 INDEX pk IS UNIQUE PRIMARY id INDEX snapshotKey IS UNIQUE snapshotId.
{ContainersItemCustoPhysical.i}
ASSIGN bh[1]=phMaster bh[2]=phItems bh[3]=phPurchaseItems bh[4]=phVersions bh[5]=phVersionItems bh[6]=phItemCosts bh[7]=phNfs
 bh[8]=phLocations bh[9]=phLabels bh[10]=phStockIma bh[11]=phStockMed bh[12]=phMovementsMed bh[13]=phInvoicesIma bh[14]=phInvoicesMed.
nestedValue=TRANSACTION.
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,"operation,container_id,versao_id,expected_latest_version_id,log_priorizar_custo_previsto,request_id").
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao fechar obrigatoria.",1).
 IF COMPARE(poRequest:GetCharacter("operation"),"NE","fechar","RAW") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao nao suportada.",1).
 ASSIGN containerId=KeyId(poRequest,"container_id") versionId=KeyId(poRequest,"versao_id") expectedId=KeyId(poRequest,"expected_latest_version_id") priority=Flag(poRequest,"log_priorizar_custo_previsto").
 IF expectedId<>versionId THEN DO: failureCode="ITEM_COST_VERSION_CONFLICT". UNDO, THROW NEW Progress.Lang.AppError("Versao alvo deve ser a ultima esperada.",1). END.
 IF poRequest:Has("request_id") THEN IF poRequest:GetType("request_id")<>JsonDataType:STRING OR LENGTH(poRequest:GetCharacter("request_id"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Rastreio invalido.",1).
 failureCode="ITEM_COST_CONFIGURATION".
 RUN Closed(poPolicy,"actor,tipo_versao_valida_nf,allow_nested").
 IF poPolicy:GetType("actor")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Ator autenticado interno obrigatorio.",1).
 actor=poPolicy:GetCharacter("actor").
 IF TRIM(actor)="" OR LENGTH(actor)>30 THEN UNDO, THROW NEW Progress.Lang.AppError("Login deve caber no campo fisico cod_usuario (30).",1).
 IF NOT VALID-HANDLE(phRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("Runtime privado indisponivel.",1).
 IF phRuntime:TYPE<>"PROCEDURE" THEN UNDO, THROW NEW Progress.Lang.AppError("Runtime privado invalido.",1).
 IF LOOKUP("NextItemCustoId",phRuntime:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Provider da sequencia fixa indisponivel.",1).
 IF NOT VALID-HANDLE(phMaster) OR NOT VALID-HANDLE(phVersions) OR NOT VALID-HANDLE(phVersionItems) OR NOT VALID-HANDLE(phItemCosts) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffers de persistencia indisponiveis.",1).
 ASSIGN nestedValue=TRANSACTION allowNested=FALSE.
 IF poPolicy:Has("allow_nested") THEN allowNested=Flag(poPolicy,"allow_nested").
 failureCode="ITEM_COST_TRANSACTION_CONTEXT".
 IF nestedValue AND NOT allowNested THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao transacional privada nao autorizada.",1).
 failureCode="ITEM_COST_CONFIGURATION".
 servicePath=SEARCH("sursum-api/programs/ContainersItemCustoInputsService.r"). IF servicePath=? THEN servicePath=SEARCH("ContainersItemCustoInputsService.r").
 mathPath=SEARCH("sursum-api/programs/ContainersItemCustoCalculator.r"). IF mathPath=? THEN mathPath=SEARCH("ContainersItemCustoCalculator.r").
 IF servicePath=? OR mathPath=? THEN DO: failureCode="ITEM_COST_CONFIGURATION". UNDO, THROW NEW Progress.Lang.AppError("Coletor/calculador central compilado indisponivel.",1). END.
 requestData=NEW JsonObject(). requestData:Add("container_id",containerId). requestData:Add("versao_id",versionId). requestData:Add("log_priorizar_custo_previsto",priority).
 policyData=NEW JsonObject(). policyData:Add("tipo_versao_valida_nf",CAST(poPolicy:GetJsonArray("tipo_versao_valida_nf"):Clone(),JsonArray)).
 changes=NEW JsonArray(). storedRows=NEW JsonArray(). warnings=NEW JsonArray().
 fieldNames="item_container_custo_id,versao_id,item_container_id,item_custo_id".
 costFields="item_custo_id,dt_hr_custo,vl_unit_novo,dt_referencia,cod_tipo_custo,it_codigo,qt_estoque,qt_estoque_selecionado,qt_nf_mae,qt_etiq_container,vl_unit_anterior,cod_situacao,vl_unit_container,qt_container,cod_usuario".
 DO TRANSACTION ON ERROR UNDO, THROW:
  failureCode="ITEM_COST_CONTAINER_NOT_FOUND".
  IF NOT ReadFound(phMaster,phMaster:NAME + ".nr-container=" + NumText(containerId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container inexistente.",1).
  failureCode="ITEM_COST_VERSION_CONFLICT".
  IF NOT ReadFound(phVersions,phVersions:NAME + ".versao_id=" + NumText(versionId) + " AND " + phVersions:NAME + ".container_id=" + NumText(containerId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Versao nao pertence ao container.",1).
  RUN VALUE(servicePath)(phMaster,phItems,phPurchaseItems,phVersions,phVersionItems,phItemCosts,phNfs,phLocations,phLabels,phStockIma,phStockMed,phMovementsMed,phInvoicesIma,phInvoicesMed,TRUE,policyData,requestData,OUTPUT collected).
  IF NOT collected:GetLogical("success") THEN DO: poResponse=collected. UNDO, THROW NEW Progress.Lang.AppError("Coleta bloqueou fechamento.",1). END.
  ASSIGN inputData=collected:GetJsonObject("data"):GetJsonObject("input") provenance=collected:GetJsonObject("data"):GetJsonObject("provenance").
  RUN VALUE(mathPath)(inputData,OUTPUT mathResponse).
  IF NOT mathResponse:GetLogical("success") THEN DO: poResponse=mathResponse. UNDO, THROW NEW Progress.Lang.AppError("Calculo bloqueou o conjunto inteiro.",1). END.
  calculation=mathResponse:GetJsonObject("data"). results=calculation:GetJsonArray("items").
  failureCode="ITEM_COST_RESULT_MISMATCH".
  IF results:Length=0 OR results:Length<>inputData:GetJsonArray("items"):Length OR calculation:GetInteger("container_id")<>containerId OR calculation:GetInteger("versao_id")<>versionId THEN UNDO, THROW NEW Progress.Lang.AppError("Conjunto calculado incompleto ou fora do contexto.",1).
  DO n=1 TO results:Length:
   rowData=results:GetJsonObject(n). CREATE ttPlan.
   ASSIGN ttPlan.id=KeyId(rowData,"item_container_id") ttPlan.snapshotId=KeyId(rowData,"item_container_custo_id") ttPlan.position=n.
   IF rowData:GetInteger("container_id")<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("Resultado de outro container.",1).
   IF NOT ReadFound(phItems,phItems:NAME + ".item_container_id=" + NumText(ttPlan.id) + " AND " + phItems:NAME + ".container_id=" + NumText(containerId),SHARE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Item atual nao pertence ao conjunto.",1).
   IF IntField(phItems,"item_proc_compra_id")<>KeyId(rowData,"item_proc_compra_id") THEN UNDO, THROW NEW Progress.Lang.AppError("Pedido do item mudou durante coleta.",1).
   IF NOT ReadFound(phVersionItems,phVersionItems:NAME + ".item_container_custo_id=" + NumText(ttPlan.snapshotId) + " AND " + phVersionItems:NAME + ".versao_id=" + NumText(versionId) + " AND " + phVersionItems:NAME + ".item_container_id=" + NumText(ttPlan.id),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot calculado nao pertence ao par.",1).
   ttPlan.beforeData=PhysicalJson(phVersionItems,fieldNames).
  END.
  timestampValue=NOW.
  FOR EACH ttPlan BY ttPlan.id:
   rowData=results:GetJsonObject(ttPlan.position).
   failureCode="ITEM_COST_CALLBACK_FAILED". RUN NextItemCustoId IN phRuntime(OUTPUT newId).
   IF newId=? OR newId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia fixa retornou chave invalida.",1).
   failureCode="ITEM_COST_SEQUENCE_CONFLICT".
   IF ReadFound(phItemCosts,phItemCosts:NAME + ".item_custo_id=" + NumText(newId),SHARE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Chave de custo ja existe.",1).
   failureCode="ITEM_COST_PERSISTENCE_FAILED".
   IF NOT phItemCosts:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Criacao de custo recusada.",1).
   ASSIGN phItemCosts:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE=newId phItemCosts:BUFFER-FIELD("dt_hr_custo"):BUFFER-VALUE=timestampValue
    phItemCosts:BUFFER-FIELD("vl_unit_novo"):BUFFER-VALUE=rowData:GetDecimal("vl_unit_novo") phItemCosts:BUFFER-FIELD("dt_referencia"):BUFFER-VALUE=DATE(timestampValue)
    phItemCosts:BUFFER-FIELD("cod_tipo_custo"):BUFFER-VALUE=2 phItemCosts:BUFFER-FIELD("it_codigo"):BUFFER-VALUE=rowData:GetCharacter("it_codigo")
    phItemCosts:BUFFER-FIELD("qt_estoque"):BUFFER-VALUE=rowData:GetDecimal("qt_saldo_estoq") phItemCosts:BUFFER-FIELD("qt_estoque_selecionado"):BUFFER-VALUE=rowData:GetDecimal("qt_saldo_estoq")
    phItemCosts:BUFFER-FIELD("qt_nf_mae"):BUFFER-VALUE=rowData:GetDecimal("qt_nota_mae") phItemCosts:BUFFER-FIELD("qt_etiq_container"):BUFFER-VALUE=rowData:GetDecimal("qt_etiquetas_container")
    phItemCosts:BUFFER-FIELD("vl_unit_anterior"):BUFFER-VALUE=rowData:GetDecimal("vl_unit_atual") phItemCosts:BUFFER-FIELD("cod_situacao"):BUFFER-VALUE=2
    phItemCosts:BUFFER-FIELD("vl_unit_container"):BUFFER-VALUE=rowData:GetDecimal("vl_unit_container") phItemCosts:BUFFER-FIELD("qt_container"):BUFFER-VALUE=rowData:GetDecimal("qt_container")
    phItemCosts:BUFFER-FIELD("cod_usuario"):BUFFER-VALUE=actor.
   IF NOT phItemCosts:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Custo recusado por validacao fisica.",1).
   afterData=PhysicalJson(phItemCosts,costFields).
   RUN AddChange("item_custos","create",newId,NEW JsonObject(),afterData).
   snapshotData=NEW JsonObject(). snapshotData:Add("item_container_id",ttPlan.id). snapshotData:Add("item_container_custo_id",ttPlan.snapshotId). snapshotData:Add("item_custo_id",newId).
   snapshotData:Add("persisted",CAST(afterData:Clone(),JsonObject)). storedRows:Add(snapshotData).
   storagePairs="vl_unit_novo:vl_unit_novo,qt_estoque:qt_saldo_estoq,qt_estoque_selecionado:qt_saldo_estoq,qt_nf_mae:qt_nota_mae,qt_etiq_container:qt_etiquetas_container,vl_unit_anterior:vl_unit_atual,vl_unit_container:vl_unit_container,qt_container:qt_container".
   DO j=1 TO NUM-ENTRIES(storagePairs):
    ASSIGN storedName=ENTRY(1,ENTRY(j,storagePairs),":") calculatedName=ENTRY(2,ENTRY(j,storagePairs),":").
    IF afterData:GetDecimal(storedName)=rowData:GetDecimal(calculatedName) THEN NEXT.
    snapshotData=NEW JsonObject(). snapshotData:Add("code","ITEM_COST_STORAGE_ROUNDING"). snapshotData:Add("item_container_id",ttPlan.id).
    snapshotData:Add("field",storedName). snapshotData:Add("calculated",rowData:GetDecimal(calculatedName)). snapshotData:Add("persisted",afterData:GetDecimal(storedName)). warnings:Add(snapshotData).
   END.
   IF NOT ReadFound(phVersionItems,phVersionItems:NAME + ".item_container_custo_id=" + NumText(ttPlan.snapshotId) + " AND " + phVersionItems:NAME + ".versao_id=" + NumText(versionId) + " AND " + phVersionItems:NAME + ".item_container_id=" + NumText(ttPlan.id),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot mudou antes do vinculo.",1).
   IF IntField(phVersionItems,"item_custo_id")<>CAST(ttPlan.beforeData,JsonObject):GetInteger("item_custo_id") THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculo mudou durante fechamento.",1).
   phVersionItems:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE=newId.
   IF NOT phVersionItems:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculo do novo custo recusado.",1).
   RUN AddChange("item_container_custos","update",ttPlan.snapshotId,CAST(ttPlan.beforeData,JsonObject),PhysicalJson(phVersionItems,fieldNames)).
  END.
 END.
 data=NEW JsonObject(). data:Add("source","container-item-cost-close-v1"). data:Add("container_id",containerId). data:Add("versao_id",versionId).
 data:Add("items",storedRows). data:Add("calculation",CAST(calculation:Clone(),JsonObject)). data:Add("provenance",CAST(provenance:Clone(),JsonObject)). data:Add("warnings",warnings).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("committed",NOT nestedValue). poResponse:Add("data",data).
 audit=NEW JsonObject(). audit:Add("version",1). audit:Add("resource","container-item-cost"). audit:Add("operation","fechar"). audit:Add("recordId",containerId). audit:Add("actor",actor).
 audit:Add("warnings",CAST(warnings:Clone(),JsonArray)). audit:Add("provenance",CAST(provenance:Clone(),JsonObject)).
 audit:Add("source",IF nestedValue THEN "progress-transaction-pending" ELSE "progress-transaction"). audit:Add("changes",changes).
 IF poRequest:Has("request_id") THEN audit:Add("request_id",poRequest:GetCharacter("request_id")).
 IF nestedValue THEN DO: poResponse:Add("pendingChanges",CAST(changes:Clone(),JsonArray)). poResponse:Add("auditPending",audit). END.
 ELSE DO:
  poResponse:Add("audit",audit).
  IF LOOKUP("LogRule",phRuntime:INTERNAL-ENTRIES)>0 THEN RUN LogRule IN phRuntime("info","Fechamento unitario confirmado para container " + NumText(containerId)) NO-ERROR.
 END.
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) THEN DO:
   poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). err=NEW JsonObject(). err:Add("code",failureCode). err:Add("message",e:GetMessage(1)).
   err:Add("status",IF failureCode="ITEM_COST_CONTAINER_NOT_FOUND" THEN 404 ELSE IF failureCode="ITEM_COST_VERSION_CONFLICT" OR failureCode="ITEM_COST_BUSY" THEN 409 ELSE 422). poResponse:Add("error",err).
  END.
 END CATCH.
 FINALLY:
  IF NOT nestedValue THEN DO n=1 TO 14: IF VALID-HANDLE(bh[n]) THEN bh[n]:BUFFER-RELEASE() NO-ERROR. END.
 END FINALLY.
END.
PROCEDURE AddChange:
 DEFINE INPUT PARAMETER resourceName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER operationName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER recordId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER beforeValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER afterValue AS JsonObject NO-UNDO.
 eventData=NEW JsonObject(). eventData:Add("resource",resourceName). eventData:Add("operation",operationName). eventData:Add("recordId",recordId).
 eventData:Add("before",beforeValue). eventData:Add("after",afterValue). changes:Add(eventData).
END PROCEDURE.

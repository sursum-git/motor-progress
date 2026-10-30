/* Physical inputs only. Simulation NO-LOCK; closing SHARE NOWAIT inside its
   caller transaction. The pure calculator is deliberately not invoked here. */
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
DEFINE INPUT PARAMETER plForWrite AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "ITEM_COST_INPUT_INVALID".
DEFINE VARIABLE bh AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE lockMode AS INTEGER NO-UNDO.
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
DEFINE VARIABLE latestId AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseId AS INTEGER NO-UNDO.
DEFINE VARIABLE candidateId AS INTEGER NO-UNDO.
DEFINE VARIABLE previousId AS INTEGER NO-UNDO.
DEFINE VARIABLE previousUnit AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE eligible AS LOGICAL NO-UNDO.
DEFINE VARIABLE released AS LOGICAL NO-UNDO.
DEFINE VARIABLE stale AS LOGICAL NO-UNDO.
DEFINE VARIABLE priority AS LOGICAL NO-UNDO.
DEFINE VARIABLE versionType AS INTEGER NO-UNDO.
DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE qc AS HANDLE NO-UNDO.
DEFINE VARIABLE qv AS HANDLE NO-UNDO.
DEFINE VARIABLE qn AS HANDLE NO-UNDO.
DEFINE VARIABLE invoiceBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE dateValue AS DATE NO-UNDO.
DEFINE VARIABLE referenceDate AS DATE NO-UNDO INITIAL 01/01/2001.
DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE inputData AS JsonObject NO-UNDO.
DEFINE VARIABLE policyData AS JsonObject NO-UNDO.
DEFINE VARIABLE versionData AS JsonObject NO-UNDO.
DEFINE VARIABLE itemData AS JsonObject NO-UNDO.
DEFINE VARIABLE objectData AS JsonObject NO-UNDO.
DEFINE VARIABLE stock AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE provenance AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE items AS JsonArray NO-UNDO.
DEFINE VARIABLE invoices AS JsonArray NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE types AS JsonArray NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttSeen NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttLocation NO-UNDO FIELD establishment AS CHARACTER FIELD deposit AS CHARACTER INDEX pair IS UNIQUE PRIMARY establishment deposit.
{ContainersItemCustoPhysical.i}
ASSIGN bh[1]=phMaster bh[2]=phItems bh[3]=phPurchaseItems bh[4]=phVersions bh[5]=phVersionItems bh[6]=phItemCosts bh[7]=phNfs
 bh[8]=phLocations bh[9]=phLabels bh[10]=phStockIma bh[11]=phStockMed bh[12]=phMovementsMed bh[13]=phInvoicesIma bh[14]=phInvoicesMed.
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,"container_id,versao_id,log_priorizar_custo_previsto"). RUN Closed(poPolicy,"tipo_versao_valida_nf").
 ASSIGN containerId=KeyId(poRequest,"container_id") versionId=KeyId(poRequest,"versao_id") priority=Flag(poRequest,"log_priorizar_custo_previsto").
 types=poPolicy:GetJsonArray("tipo_versao_valida_nf").
 DO n=1 TO types:Length:
  IF types:GetType(n)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Tipos NF devem ser inteiros JSON, nao strings.",1).
  objectData=NEW JsonObject(). objectData:Add("id",types:GetDecimal(n)). candidateId=KeyId(objectData,"id"). DELETE OBJECT objectData.
 END.
 failureCode="ITEM_COST_CONFIGURATION".
 DO n=1 TO 14:
  IF NOT VALID-HANDLE(bh[n]) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer fixo ausente.",1).
  IF bh[n]:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer fixo invalido.",1).
 END.
 IF plForWrite=? THEN UNDO, THROW NEW Progress.Lang.AppError("Modo de coleta interno obrigatorio.",1).
 lockMode=IF plForWrite THEN SHARE-LOCK ELSE NO-LOCK.
 IF plForWrite AND NOT TRANSACTION THEN DO: failureCode="ITEM_COST_TRANSACTION_CONTEXT". UNDO, THROW NEW Progress.Lang.AppError("Coleta de fechamento exige transacao raiz ativa.",1). END.
 failureCode="ITEM_COST_CONTAINER_NOT_FOUND".
 IF NOT ReadFound(phMaster,phMaster:NAME + ".nr-container=" + NumText(containerId),IF plForWrite THEN EXCLUSIVE-LOCK ELSE NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container inexistente.",1).
 ASSIGN released=phMaster:BUFFER-FIELD("log_liberar_custo_realizado"):BUFFER-VALUE stale=phMaster:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE.
 IF released=? OR stale=? THEN DO: failureCode="ITEM_COST_INPUT_INCOMPLETE". UNDO, THROW NEW Progress.Lang.AppError("Flags de custo desconhecidas no mestre.",1). END.
 failureCode="ITEM_COST_VERSION_CONFLICT".
 q=QueryRows(phVersions,phVersions:NAME + ".container_id=" + NumText(containerId),"BY " + phVersions:NAME + ".versao_id DESCENDING",lockMode).
 IF NOT q:QUERY-OFF-END THEN latestId=IntField(phVersions,"versao_id").
 IF latestId<>versionId THEN UNDO, THROW NEW Progress.Lang.AppError("Versao alvo nao e a ultima deste container.",1).
 versionType=IntField(phVersions,"tipo_versao_id").
 IF IntField(phVersions,"ind_sit_versao")<>2 THEN DO: failureCode="ITEM_COST_VERSION_INCOMPLETE". UNDO, THROW NEW Progress.Lang.AppError("Versao alvo ainda incompleta.",1). END.
 RUN CloseQuery(INPUT-OUTPUT q).
 inputData=NEW JsonObject(). inputData:Add("confirmed",TRUE). inputData:Add("source","item-cost-inputs-v1"). inputData:Add("container_id",containerId).
 policyData=NEW JsonObject(). policyData:Add("log_liberar_custo_realizado",released). policyData:Add("log_priorizar_custo_previsto",priority).
 policyData:Add("tipo_versao_valida_nf",CAST(types:Clone(),JsonArray)). inputData:Add("policy",policyData).
 versionData=NEW JsonObject(). versionData:Add("versao_id",versionId). versionData:Add("tipo_versao_id",versionType). versionData:Add("log_versao_custo_desatualizada",stale). inputData:Add("version",versionData).
 failureCode="ITEM_COST_INPUT_INCOMPLETE". invoices=NEW JsonArray().
 q=QueryRows(phNfs,phNfs:NAME + ".container_id=" + NumText(containerId),"BY " + phNfs:NAME + ".estab BY " + phNfs:NAME + ".serie BY " + phNfs:NAME + ".documento",lockMode).
 DO WHILE NOT q:QUERY-OFF-END:
  IF SUBSTRING(TextField(phNfs,"nat_operacao"),1,1)="3" THEN DO:
   objectData=PhysicalJson(phNfs,"documento,serie,estab,nat_operacao,cod_emitente").
   invoiceBuffer=IF TextField(phNfs,"estab")="1" THEN phInvoicesIma ELSE phInvoicesMed.
   qn=QueryRows(invoiceBuffer,invoiceBuffer:NAME + ".cod-estabel=" + AblQuote(TextField(phNfs,"estab")) + " AND " + invoiceBuffer:NAME + ".serie=" + AblQuote(TextField(phNfs,"serie")) + " AND " + invoiceBuffer:NAME + ".nr-nota-fis=" + AblQuote(TextField(phNfs,"documento")),"",lockMode).
   IF qn:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Nota mae vinculada sem nota-fiscal ERP; nao e ausencia legitima de mae.",1).
   dateValue=invoiceBuffer:BUFFER-FIELD("dt-emis-nota"):BUFFER-VALUE.
   IF dateValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("Data da nota mae ERP desconhecida.",1).
   IF invoices:Length=0 THEN referenceDate=dateValue.
   objectData:Add("dt_emis_nota",dateValue). RUN NextRow(qn,invoiceBuffer,lockMode).
   IF NOT qn:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Nota mae ERP ambigua.",1).
   RUN CloseQuery(INPUT-OUTPUT qn). invoices:Add(objectData).
  END.
  RUN NextRow(q,phNfs,lockMode).
 END. RUN CloseQuery(INPUT-OUTPUT q). inputData:Add("nfs",invoices).
 q=QueryRows(phLocations,phLocations:NAME + ".cod_empresa=" + AblQuote("5"),"BY " + phLocations:NAME + ".local_estoq_portal_id",lockMode).
 DO WHILE NOT q:QUERY-OFF-END:
  FIND ttLocation WHERE ttLocation.establishment=TextField(phLocations,"cod_estab") AND ttLocation.deposit=TextField(phLocations,"cod_depos") NO-ERROR.
  IF NOT AVAILABLE ttLocation THEN DO: CREATE ttLocation. ASSIGN ttLocation.establishment=TextField(phLocations,"cod_estab") ttLocation.deposit=TextField(phLocations,"cod_depos"). END.
  RUN NextRow(q,phLocations,lockMode).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 items=NEW JsonArray(). q=QueryRows(phItems,phItems:NAME + ".container_id=" + NumText(containerId),"BY " + phItems:NAME + ".item_container_id",lockMode).
 DO WHILE NOT q:QUERY-OFF-END:
  ASSIGN itemId=IntField(phItems,"item_container_id") purchaseId=IntField(phItems,"item_proc_compra_id").
  IF itemId<=0 OR purchaseId<=0 OR CAN-FIND(ttSeen WHERE ttSeen.id=itemId) THEN UNDO, THROW NEW Progress.Lang.AppError("Item atual duplicado ou sem chave positiva.",1).
  CREATE ttSeen. ttSeen.id=itemId.
  IF NOT ReadFound(phPurchaseItems,phPurchaseItems:NAME + ".item_proc_compra_id=" + NumText(purchaseId),lockMode) THEN UNDO, THROW NEW Progress.Lang.AppError("Item do pedido nao localizado.",1).
  code=TextField(phPurchaseItems,"codigo_erp").
  itemData=NEW JsonObject(). itemData:Add("item_container_id",itemId). itemData:Add("item_proc_compra_id",purchaseId). itemData:Add("it_codigo",code).
  /* Latest cost: greatest eligible ID, never the current container's type2. */
  previousId=0. previousUnit=0.
  qc=QueryRows(phItemCosts,phItemCosts:NAME + ".it_codigo=" + AblQuote(code),"BY " + phItemCosts:NAME + ".item_custo_id DESCENDING",lockMode).
  DO WHILE NOT qc:QUERY-OFF-END:
   eligible=IntField(phItemCosts,"cod_tipo_custo")<>2. candidateId=IntField(phItemCosts,"item_custo_id").
   IF NOT eligible THEN DO:
    qv=QueryRows(phVersionItems,phVersionItems:NAME + ".item_custo_id=" + NumText(candidateId),"",lockMode).
    DO WHILE NOT qv:QUERY-OFF-END:
     IF ReadFound(phVersions,phVersions:NAME + ".versao_id=" + NumText(IntField(phVersionItems,"versao_id")),lockMode) THEN
      IF IntField(phVersions,"container_id")<>containerId THEN eligible=TRUE.
     RUN NextRow(qv,phVersionItems,lockMode).
    END. RUN CloseQuery(INPUT-OUTPUT qv).
   END.
   IF eligible THEN DO: ASSIGN previousId=candidateId previousUnit=NumField(phItemCosts,"vl_unit_novo"). LEAVE. END.
   RUN NextRow(qc,phItemCosts,lockMode).
  END. RUN CloseQuery(INPUT-OUTPUT qc).
  IF previousId=0 THEN itemData:AddNull("previous_cost").
  ELSE DO: objectData=NEW JsonObject(). objectData:Add("item_custo_id",previousId). objectData:Add("vl_unit_novo",previousUnit). itemData:Add("previous_cost",objectData). END.
  countRows=0. snapshotData=?.
  qc=QueryRows(phVersionItems,phVersionItems:NAME + ".versao_id=" + NumText(versionId) + " AND " + phVersionItems:NAME + ".item_container_id=" + NumText(itemId),"BY " + phVersionItems:NAME + ".item_container_custo_id",IF plForWrite THEN EXCLUSIVE-LOCK ELSE NO-LOCK).
  DO WHILE NOT qc:QUERY-OFF-END:
   IF IntField(phVersionItems,"item_custo_id")<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculo de custo anterior desconhecido ou invalido.",1).
   countRows=countRows + 1.
   snapshotData=PhysicalJson(phVersionItems,"item_container_custo_id,versao_id,item_container_id,vl_unit_prev,vl_unit_realiz,qt_alocada,qt_confirm_emb,qt_recebto_fisico").
   IF TextField(phVersionItems,"it_codigo")<>code THEN UNDO, THROW NEW Progress.Lang.AppError("Codigo ERP do snapshot difere do pedido atual; gere nova versao.",1).
   RUN NextRow(qc,phVersionItems,IF plForWrite THEN EXCLUSIVE-LOCK ELSE NO-LOCK).
  END. RUN CloseQuery(INPUT-OUTPUT qc).
  IF countRows>1 THEN DO: failureCode="ITEM_COST_INPUT_AMBIGUOUS". UNDO, THROW NEW Progress.Lang.AppError("Mais de um snapshot para o mesmo item/versao.",1). END.
  IF countRows=0 THEN itemData:AddNull("version_cost"). ELSE itemData:Add("version_cost",snapshotData).
  stock=NEW JsonObject().
  RUN StockAmount(phStockIma,TRUE,OUTPUT amount). stock:Add("ima",amount).
  RUN StockAmount(phStockMed,FALSE,OUTPUT amount). stock:Add("med",amount). itemData:Add("stock",stock).
  rows=NEW JsonArray(). qc=QueryRows(phMovementsMed,phMovementsMed:NAME + ".it-codigo=" + AblQuote(code) + " AND " + phMovementsMed:NAME + ".dt-trans < DATE(" + NumText(MONTH(referenceDate)) + "," + NumText(DAY(referenceDate)) + "," + NumText(YEAR(referenceDate)) + ")","BY " + phMovementsMed:NAME + ".nr-trans",lockMode).
  DO WHILE NOT qc:QUERY-OFF-END:
   dateValue=phMovementsMed:BUFFER-FIELD("dt-trans"):BUFFER-VALUE.
   IF dateValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("Movimento MED com data desconhecida.",1).
   objectData=NEW JsonObject(). objectData:Add("dt_trans",dateValue). objectData:Add("tipo_trans",IntField(phMovementsMed,"tipo-trans")). objectData:Add("quantidade",NumField(phMovementsMed,"quantidade")). rows:Add(objectData).
   RUN NextRow(qc,phMovementsMed,lockMode).
  END. RUN CloseQuery(INPUT-OUTPUT qc). itemData:Add("movimentos_med",rows).
  rows=NEW JsonArray(). qc=QueryRows(phLabels,phLabels:NAME + ".it-codigo=" + AblQuote(code) + " AND (" + phLabels:NAME + ".situacao=3 OR " + phLabels:NAME + ".situacao=4) AND " + phLabels:NAME + ".quantidade<>0","BY " + phLabels:NAME + ".cod-estabel BY " + phLabels:NAME + ".num-etiqueta",lockMode).
  DO WHILE NOT qc:QUERY-OFF-END:
   objectData=NEW JsonObject(). objectData:Add("nr_container",IntField(phLabels,"nr-container")). objectData:Add("situacao",IntField(phLabels,"situacao")). objectData:Add("quantidade",NumField(phLabels,"quantidade")). rows:Add(objectData).
   RUN NextRow(qc,phLabels,lockMode).
  END. RUN CloseQuery(INPUT-OUTPUT qc). itemData:Add("etiquetas",rows). items:Add(itemData).
  RUN NextRow(q,phItems,lockMode).
 END. RUN CloseQuery(INPUT-OUTPUT q). inputData:Add("items",items).
 /* Reject extra or foreign snapshot rows; missing rows remain null for the
    pure calculator to aggregate its full item diagnostics. */
 q=QueryRows(phVersionItems,phVersionItems:NAME + ".versao_id=" + NumText(versionId),"BY " + phVersionItems:NAME + ".item_container_custo_id",lockMode).
 DO WHILE NOT q:QUERY-OFF-END:
  IF NOT CAN-FIND(ttSeen WHERE ttSeen.id=IntField(phVersionItems,"item_container_id")) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot possui item fora do conjunto atual do container.",1).
  RUN NextRow(q,phVersionItems,lockMode).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 provenance=NEW JsonObject(). provenance:Add("source","item-cost-physical-collector-v1"). provenance:Add("container_id",containerId). provenance:Add("versao_id",versionId).
 provenance:Add("collected_at",NOW). provenance:Add("collection_count",1). provenance:Add("lock_mode",IF plForWrite THEN "SHARE-NOWAIT/master-exclusive" ELSE "NO-LOCK").
 provenance:Add("erp_consistency","Existing rows only; external inserts and other containers using the same ERP item are not serialized.").
 data=NEW JsonObject(). data:Add("input",inputData). data:Add("provenance",provenance). poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",data).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). err=NEW JsonObject(). err:Add("code",failureCode). err:Add("message",e:GetMessage(1)). err:Add("status",IF failureCode="ITEM_COST_CONTAINER_NOT_FOUND" THEN 404 ELSE IF failureCode="ITEM_COST_BUSY" OR failureCode="ITEM_COST_VERSION_CONFLICT" THEN 409 ELSE 422). poResponse:Add("error",err).
 END CATCH.
 FINALLY: RUN CloseQuery(INPUT-OUTPUT q). RUN CloseQuery(INPUT-OUTPUT qc). RUN CloseQuery(INPUT-OUTPUT qv). RUN CloseQuery(INPUT-OUTPUT qn). END FINALLY.
END.
PROCEDURE StockAmount:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ima AS LOGICAL NO-UNDO.
 DEFINE OUTPUT PARAMETER total AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE qs AS HANDLE NO-UNDO.
 DEFINE VARIABLE matchLocation AS LOGICAL NO-UNDO.
 qs=QueryRows(h,h:NAME + ".it-codigo=" + AblQuote(code) + (IF ima THEN " AND " + h:NAME + ".cod-estabel=" + AblQuote("1") ELSE ""),"",lockMode).
 DO WHILE NOT qs:QUERY-OFF-END:
  matchLocation=ima OR NOT CAN-FIND(FIRST ttLocation).
  IF NOT matchLocation THEN matchLocation=CAN-FIND(ttLocation WHERE ttLocation.establishment=TextField(h,"cod-estabel") AND ttLocation.deposit=TextField(h,"cod-depos")).
  IF matchLocation THEN total=total + NumField(h,"qtidade-atu").
  RUN NextRow(qs,h,lockMode).
 END.
 RUN CloseQuery(INPUT-OUTPUT qs).
 FINALLY: RUN CloseQuery(INPUT-OUTPUT qs). END FINALLY.
END PROCEDURE.

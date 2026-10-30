/* Expense commands compose the central fiscal service; no duplicate cost math. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTaxBases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRelations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCalcs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE oBatchExpected AS JsonObject NO-UNDO.
{sursum-api/includes/ContainerExpenseBatchSnapshot.i}
DEFINE TEMP-TABLE ttRow NO-UNDO
 FIELD ordinal AS INTEGER FIELD id AS INTEGER FIELD recordRow AS ROWID
 INDEX pk IS PRIMARY UNIQUE ordinal INDEX idIndex id.
DEFINE BUFFER bRow FOR ttRow.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cFailure AS CHARACTER NO-UNDO INITIAL "CONTAINER_EXPENSE_VALIDATION".
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cField AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFiscalProgram AS CHARACTER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE iCompany AS INTEGER NO-UNDO.
DEFINE VARIABLE iProtected AS INTEGER NO-UNDO.
DEFINE VARIABLE iTarget AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE iNew AS INTEGER NO-UNDO.
DEFINE VARIABLE lBatch AS LOGICAL NO-UNDO.
DEFINE VARIABLE lDelete AS LOGICAL NO-UNDO.
DEFINE VARIABLE lStale AS LOGICAL NO-UNDO.
DEFINE VARIABLE lNeedsFiscal AS LOGICAL NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE oRows AS JsonArray NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE oValues AS JsonObject NO-UNDO.
DEFINE VARIABLE oBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE oProposed AS JsonObject NO-UNDO.
DEFINE VARIABLE oAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE oMasterBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE oMasterAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE oAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE oActor AS JsonObject NO-UNDO.
DEFINE VARIABLE oInputs AS JsonObject NO-UNDO.
DEFINE VARIABLE oFiscalPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE oFiscalRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE oFiscalResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE aChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE aWarnings AS JsonArray NO-UNDO.
DEFINE VARIABLE aData AS JsonArray NO-UNDO.
DEFINE VARIABLE oValuesRows AS JsonObject EXTENT 200 NO-UNDO.
DEFINE VARIABLE oBeforeRows AS JsonObject EXTENT 200 NO-UNDO.
DEFINE VARIABLE oProposedRows AS JsonObject EXTENT 200 NO-UNDO.

FUNCTION Exact RETURNS LOGICAL (name AS CHARACTER,list AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 c=name. DO j=1 TO NUM-ENTRIES(list): IF c=ENTRY(j,list) THEN RETURN TRUE. END. RETURN FALSE.
END FUNCTION.
FUNCTION Id RETURNS INTEGER (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT o:Has(f) THEN RETURN ?.
 CASE o:GetType(f): WHEN JsonDataType:NUMBER THEN c=o:GetJsonText(f). WHEN JsonDataType:STRING THEN c=o:GetCharacter(f). OTHERWISE RETURN ?. END CASE.
 IF LENGTH(c)<1 OR LENGTH(c)>10 THEN RETURN ?.
 DO j=1 TO LENGTH(c): IF INDEX("0123456789",SUBSTRING(c,j,1))=0 THEN RETURN ?. END.
 d=DECIMAL(c). IF d<1 OR d>2147483647 THEN RETURN ?. RETURN INTEGER(d).
END FUNCTION.
FUNCTION RowId RETURNS INTEGER (o AS JsonObject):
 DEFINE VARIABLE a AS INTEGER NO-UNDO. DEFINE VARIABLE b AS INTEGER NO-UNDO.
 a=Id(o,"id"). b=Id(o,"despesa_container_id").
 IF (o:Has("id") AND a=?) OR (o:Has("despesa_container_id") AND b=?) THEN RETURN ?.
 IF a=? THEN a=b. IF b<>? AND a<>b THEN RETURN ?. RETURN a.
END FUNCTION.
FUNCTION Snapshot RETURNS JsonObject (h AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE name AS CHARACTER NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO. DEFINE VARIABLE iv AS INTEGER NO-UNDO. DEFINE VARIABLE iv64 AS INT64 NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE l AS LOGICAL NO-UNDO.
 DEFINE VARIABLE da AS DATE NO-UNDO. DEFINE VARIABLE dt AS DATETIME NO-UNDO. DEFINE VARIABLE dz AS DATETIME-TZ NO-UNDO.
 o=NEW JsonObject().
 DO j=1 TO h:NUM-FIELDS:
  f=h:BUFFER-FIELD(j). name=IF f:NAME="nr-container" THEN "container_id" ELSE REPLACE(f:NAME,"-","_").
  IF f:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Extent de snapshot nao previsto.",1).
  IF f:BUFFER-VALUE=? THEN o:AddNull(name).
  ELSE CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: c=f:BUFFER-VALUE. o:Add(name,c). END.
   WHEN "INTEGER" THEN DO: iv=f:BUFFER-VALUE. o:Add(name,iv). END.
   WHEN "INT64" THEN DO: iv64=f:BUFFER-VALUE. o:Add(name,iv64). END.
   WHEN "DECIMAL" THEN DO: d=f:BUFFER-VALUE. o:Add(name,d). END.
   WHEN "LOGICAL" THEN DO: l=f:BUFFER-VALUE. o:Add(name,l). END.
   WHEN "DATE" THEN DO: da=f:BUFFER-VALUE. o:Add(name,da). END.
   WHEN "DATETIME" THEN DO: dt=f:BUFFER-VALUE. o:Add(name,dt). END.
   WHEN "DATETIME-TZ" THEN DO: dz=f:BUFFER-VALUE. o:Add(name,dz). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo de snapshot nao previsto.",1).
  END CASE.
 END. RETURN o.
END FUNCTION.
FUNCTION UniqueRow RETURNS LOGICAL (h AS HANDLE,w AS CHARACTER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE rowValue AS ROWID NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(h).
  IF NOT q:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + w) THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF h:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("Referencia em uso.",1).
  IF q:QUERY-OFF-END THEN RETURN FALSE.
  rowValue=h:ROWID. q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF h:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("Referencia em uso.",1).
  IF NOT q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Referencia ambigua.",1).
  RETURN h:FIND-BY-ROWID(rowValue,SHARE-LOCK,NO-WAIT).
  FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
 END.
END FUNCTION.

DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError("Requisicao ausente.",1).
 EXTENT(cNames)=?. cNames=poRequest:GetNames().
 DO n=1 TO EXTENT(cNames): IF NOT Exact(cNames[n],"operation,container_id,id,despesa_container_id,values,rows") THEN UNDO, THROW NEW Progress.Lang.AppError("Campo externo nao permitido.",1). END.
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao invalida.",1).
 ASSIGN cOperation=poRequest:GetCharacter("operation") iContainer=Id(poRequest,"container_id").
 IF NOT Exact(cOperation,"create,update,delete,get,batch_update,batch_delete") OR iContainer=? THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao ou container invalido.",1).
 ASSIGN lBatch=Exact(cOperation,"batch_update,batch_delete") lDelete=Exact(cOperation,"delete,batch_delete")
  lNeedsFiscal=NOT lDelete OR cOperation="delete".
 IF lBatch THEN DO:
  IF poRequest:Has("id") OR poRequest:Has("despesa_container_id") OR poRequest:Has("values") OR poRequest:GetType("rows")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Lote invalido.",1).
  oRows=poRequest:GetJsonArray("rows"). IF oRows:Length<1 OR oRows:Length>200 THEN UNDO, THROW NEW Progress.Lang.AppError("Lote deve conter1a200linhas.",1).
 END.
 ELSE DO:
  IF poRequest:Has("rows") THEN UNDO, THROW NEW Progress.Lang.AppError("rows somente em lote.",1).
  oRows=NEW JsonArray(). oRow=NEW JsonObject().
  IF cOperation="create" THEN DO:
   IF poRequest:Has("id") OR poRequest:Has("despesa_container_id") THEN UNDO, THROW NEW Progress.Lang.AppError("ID gerado pelo servidor.",1).
  END.
  ELSE DO: iTarget=RowId(poRequest). IF iTarget=? THEN UNDO, THROW NEW Progress.Lang.AppError("ID de despesa necessario/consistente.",1). oRow:Add("id",iTarget). END.
  IF cOperation="create" OR cOperation="update" THEN DO:
   IF poRequest:GetType("values")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("values necessario.",1).
   oRow:Add("values",poRequest:GetJsonObject("values")).
  END.
  ELSE IF poRequest:Has("values") THEN UNDO, THROW NEW Progress.Lang.AppError("values nao permitido nesta operacao.",1).
  oRows:Add(oRow).
 END.

 DO n=1 TO oRows:Length:
  IF oRows:GetType(n)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Linha de lote invalida.",1).
  oRow=oRows:GetJsonObject(n). EXTENT(cNames)=?. cNames=oRow:GetNames().
  DO k=1 TO EXTENT(cNames): IF NOT Exact(cNames[k],"id,despesa_container_id,values") THEN UNDO, THROW NEW Progress.Lang.AppError("Campo de linha nao permitido.",1). END.
  CREATE ttRow. ttRow.ordinal=n.
  IF cOperation<>"create" THEN DO:
   ttRow.id=RowId(oRow). IF ttRow.id=? OR CAN-FIND(FIRST bRow WHERE bRow.id=ttRow.id AND bRow.ordinal<>n) THEN UNDO, THROW NEW Progress.Lang.AppError("ID ausente, divergente ou repetido.",1).
  END.
  IF NOT lDelete AND cOperation<>"get" THEN DO:
   IF oRow:GetType("values")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("values de linha necessario.",1).
   oValues=oRow:GetJsonObject("values"). RUN ValidateValues. oValuesRows[n]=oValues.
  END.
  ELSE IF oRow:Has("values") THEN UNDO, THROW NEW Progress.Lang.AppError("values nao permitido.",1).
 END.
 IF VALID-OBJECT(poPolicy) THEN IF poPolicy:Has("batch_expected_before") THEN DO:
  IF NOT lBatch OR poPolicy:GetType("batch_expected_before")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Expected images require private batch opt-in.",1).
  oBatchExpected=poPolicy:GetJsonObject("batch_expected_before"). EXTENT(cNames)=?. cNames=oBatchExpected:GetNames().
  IF EXTENT(cNames)<>oRows:Length THEN UNDO, THROW NEW Progress.Lang.AppError("Complete batch expected images required.",1).
  FOR EACH ttRow:
   cField=TRIM(STRING(ttRow.id,"->>>>>>>>>9")).
   IF NOT oBatchExpected:Has(cField) OR oBatchExpected:GetType(cField)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Expected row missing.",1).
   oRow=oBatchExpected:GetJsonObject(cField).
   IF NOT ExpenseBatchImageValid(oRow) THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid physical expected image.",1).
   IF oRow:GetInteger("despesa_container_id")<>ttRow.id OR oRow:GetInteger("container_id")<>iContainer THEN UNDO, THROW NEW Progress.Lang.AppError("Expected identity differs.",1).
  END.
 END.
 cFailure="CONTAINER_EXPENSE_CONFIGURATION".
 IF NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phEmpresas) OR NOT VALID-HANDLE(phDefs) OR NOT VALID-HANDLE(phLinks) OR NOT VALID-HANDLE(phExpenses) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffers fixos indisponiveis.",1).
 IF cOperation="get" THEN DO:
  lFound=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(iContainer),NO-LOCK) NO-ERROR.
  IF NOT lFound THEN DO: cFailure="CONTAINER_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1). END.
  lFound=phExpenses:FIND-FIRST("WHERE " + phExpenses:NAME + ".despesa_container_id=" + STRING(iTarget) + " AND " + phExpenses:NAME + ".container_id=" + STRING(iContainer),NO-LOCK) NO-ERROR.
  IF NOT lFound THEN DO: cFailure="CONTAINER_EXPENSE_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Despesa nao encontrada no container.",1). END.
  poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",Snapshot(phExpenses)). RETURN.
 END.
 cFailure="CONTAINER_TRANSACTION_CONTEXT".
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa requer transacao raiz propria.",1).
 cFailure="CONTAINER_IDENTITY_REQUIRED".
 IF NOT VALID-OBJECT(poPolicy) OR poPolicy:GetType("actor")<>JsonDataType:OBJECT OR poPolicy:GetType("usuario_id")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Autoria privada necessaria.",1).
 oActor=poPolicy:GetJsonObject("actor").
 IF oActor:GetType("login")<>JsonDataType:STRING OR TRIM(oActor:GetCharacter("login"))="" THEN UNDO, THROW NEW Progress.Lang.AppError("Login privado necessario.",1).
 IF LENGTH(oActor:GetCharacter("login"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Login privado invalido.",1).
 oRow=NEW JsonObject(). oRow:Add("login",oActor:GetCharacter("login")).
 IF oActor:Has("id") THEN DO:
  IF oActor:GetType("id")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("ID privado deve ser opaco.",1).
  oRow:Add("id",oActor:GetCharacter("id")).
 END.
 oActor=oRow.
 IF poPolicy:GetDecimal("usuario_id")<0 OR poPolicy:GetDecimal("usuario_id")>2147483647 OR poPolicy:GetDecimal("usuario_id")<>TRUNCATE(poPolicy:GetDecimal("usuario_id"),0) THEN UNDO, THROW NEW Progress.Lang.AppError("Usuario privado invalido.",1).
 cFailure="CONTAINER_EXPENSE_CONFIGURATION".
 IF poPolicy:GetType("despesa_distr_custo")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Parametro IMA direto nao confirmado.",1).
 IF poPolicy:GetDecimal("despesa_distr_custo")=? OR poPolicy:GetDecimal("despesa_distr_custo")<0 OR poPolicy:GetDecimal("despesa_distr_custo")>2147483647 OR poPolicy:GetDecimal("despesa_distr_custo")<>TRUNCATE(poPolicy:GetDecimal("despesa_distr_custo"),0) THEN UNDO, THROW NEW Progress.Lang.AppError("Parametro IMA invalido.",1).
 iProtected=poPolicy:GetInteger("despesa_distr_custo").
 IF lNeedsFiscal THEN DO:
  cFiscalProgram=SEARCH("sursum-api/programs/ContainersImpostosService.r"). IF cFiscalProgram=? THEN cFiscalProgram=SEARCH("ContainersImpostosService.r").
  IF cFiscalProgram=? OR NOT VALID-HANDLE(phRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal compilado/runtime indisponivel.",1).
  IF NOT Exact("NextCalculoId",phRuntime:INTERNAL-ENTRIES) OR NOT Exact("NextDespesaId",phRuntime:INTERNAL-ENTRIES) OR NOT Exact("CollectCalculationInputs",phRuntime:INTERNAL-ENTRIES) THEN UNDO, THROW NEW Progress.Lang.AppError("Callbacks reais indisponiveis.",1).
 END.
 ASSIGN aChanges=NEW JsonArray() aWarnings=NEW JsonArray() aData=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  cFailure="CONTAINER_BUSY".
  lFound=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(iContainer),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF NOT lFound THEN DO:
   IF NOT phContainer:LOCKED THEN cFailure="CONTAINER_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container ausente ou em uso.",1).
  END.
  oMasterBefore=Snapshot(phContainer). cPrefix=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
  IF VALID-OBJECT(oBatchExpected) THEN DO:
   cFailure="CONTAINER_EXPENSE_COMPANY".
   IF cPrefix=? OR NOT cPrefix BEGINS "5" THEN UNDO, THROW NEW Progress.Lang.AppError("Native expense batch requires locked MED owner.",1).
  END.
  cFailure="CONTAINER_EXPENSE_COMPANY".
  IF cPrefix=? OR LENGTH(cPrefix)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Estabelecimento invalido.",1).
  cPrefix=SUBSTRING(cPrefix,1,1). IF cPrefix<>"1" AND cPrefix<>"5" THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa ERP invalida.",1).
  IF NOT UniqueRow(phEmpresas,phEmpresas:NAME + ".cod_emp_ems2=" + cPrefix) THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa nao encontrada.",1).
  iCompany=phEmpresas:BUFFER-FIELD("empresa_id"):BUFFER-VALUE.
  /* Lock and validate the complete batch before the first business mutation. */
  FOR EACH ttRow BY ttRow.id:
   IF cOperation="create" THEN DO:
    oBefore=NEW JsonObject(). oProposed=NEW JsonObject().
    oProposed:Add("despesa_id",0). oProposed:Add("vl_prev",0). oProposed:Add("vl_base_imp",0). oProposed:Add("vl_negociado",0). oProposed:Add("perc_calc",0). oProposed:Add("log_manual",TRUE).
   END.
   ELSE DO:
    cFailure="CONTAINER_BUSY".
    lFound=phExpenses:FIND-FIRST("WHERE " + phExpenses:NAME + ".despesa_container_id=" + STRING(ttRow.id) + " AND " + phExpenses:NAME + ".container_id=" + STRING(iContainer),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
    IF NOT lFound THEN DO:
     IF NOT phExpenses:LOCKED THEN cFailure="CONTAINER_EXPENSE_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Despesa ausente neste container ou em uso.",1).
    END.
    ttRow.recordRow=phExpenses:ROWID. oBefore=Snapshot(phExpenses). oProposed=CAST(oBefore:Clone(),JsonObject).
   END.
   IF VALID-OBJECT(oBatchExpected) THEN DO:
    cFailure="CONTAINER_EXPENSE_CHANGED".
    IF NOT ExpenseBatchImageSame(oBefore,oBatchExpected:GetJsonObject(TRIM(STRING(ttRow.id,"->>>>>>>>>9")))) THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa alterada; recarregue o lote.",1).
   END.
   oBeforeRows[ttRow.ordinal]=oBefore.
   IF NOT lDelete THEN DO:
    oValues=oValuesRows[ttRow.ordinal]. EXTENT(cNames)=?. cNames=oValues:GetNames().
    DO n=1 TO EXTENT(cNames):
     cField=cNames[n].
     IF cField="log_manual" THEN oProposed:Set(cField,oValues:GetLogical(cField)).
     ELSE IF cField="despesa_id" THEN oProposed:Set(cField,oValues:GetInteger(cField)).
     ELSE oProposed:Set(cField,ROUND(oValues:GetDecimal(cField),2)).
    END.
   END.
   RUN ValidateProposed.
   oProposedRows[ttRow.ordinal]=oProposed.
   IF cOperation="update" THEN DO n=1 TO 4:
    cField=ENTRY(n,"vl_prev,vl_base_imp,perc_calc,vl_negociado"). IF oBefore:GetDecimal(cField)<>oProposed:GetDecimal(cField) THEN lStale=TRUE.
   END.
  END.
  lStale=lStale OR cOperation="create" OR lDelete OR lBatch.
  FOR EACH ttRow BY ttRow.ordinal:
   oBefore=oBeforeRows[ttRow.ordinal]. oProposed=oProposedRows[ttRow.ordinal].
   cFailure="CONTAINER_EXPENSE_PERSISTENCE".
   IF cOperation="create" THEN DO:
    RUN NextDespesaId IN phRuntime(OUTPUT iNew). IF iNew<=0 OR iNew=? THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia de despesa invalida.",1).
    lFound=phExpenses:FIND-FIRST("WHERE " + phExpenses:NAME + ".despesa_container_id=" + STRING(iNew),NO-LOCK) NO-ERROR.
    IF lFound THEN UNDO, THROW NEW Progress.Lang.AppError("ID de sequencia ja utilizado.",1).
    phExpenses:BUFFER-CREATE(). ttRow.id=iNew. iTarget=iNew.
    phExpenses:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE=iNew. phExpenses:BUFFER-FIELD("container_id"):BUFFER-VALUE=iContainer. phExpenses:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=0.
   END.
   ELSE IF NOT phExpenses:FIND-BY-ROWID(ttRow.recordRow,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("Linha mudou durante a transacao.",1).
   IF lDelete THEN DO:
    IF NOT phExpenses:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao recusada pelo banco.",1). oAfter=NEW JsonObject().
   END.
   ELSE DO:
    DO n=1 TO NUM-ENTRIES("despesa_id,vl_prev,vl_base_imp,vl_negociado,log_manual,perc_calc"):
     cField=ENTRY(n,"despesa_id,vl_prev,vl_base_imp,vl_negociado,log_manual,perc_calc").
     IF cField="log_manual" THEN phExpenses:BUFFER-FIELD(cField):BUFFER-VALUE=oProposed:GetLogical(cField).
     ELSE phExpenses:BUFFER-FIELD(cField):BUFFER-VALUE=oProposed:GetDecimal(cField).
    END.
    IF NOT phExpenses:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa recusada pelo banco.",1). oAfter=Snapshot(phExpenses).
   END.
   RUN AddEvent("despesas_container",IF lDelete THEN "delete" ELSE IF cOperation="create" THEN "create" ELSE "update",ttRow.id,oBefore,oAfter).
  END.
  IF lNeedsFiscal THEN RUN ApplyFiscal.
  IF lStale THEN DO:
   phContainer:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE.
   phContainer:BUFFER-FIELD("dt_hr_ult_alt_versao_custo"):BUFFER-VALUE=DATETIME(TODAY,MTIME).
   IF NOT phContainer:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Mestre recusou invalidacao de custo.",1).
  END.
  oMasterAfter=Snapshot(phContainer).
  /* Re-read final physical rows: fiscal rules can replace/delete a target. */
  FOR EACH ttRow BY ttRow.ordinal:
   lFound=phExpenses:FIND-FIRST("WHERE " + phExpenses:NAME + ".despesa_container_id=" + STRING(ttRow.id) + " AND " + phExpenses:NAME + ".container_id=" + STRING(iContainer),NO-LOCK) NO-ERROR.
   IF lFound THEN aData:Add(Snapshot(phExpenses)).
  END.
 END.
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE).
 IF lBatch THEN poResponse:Add("data",aData).
 ELSE IF aData:Length>0 THEN poResponse:Add("data",aData:GetJsonObject(1)).
 ELSE DO: poResponse:AddNull("data"). IF cOperation="update" THEN poResponse:Add("removedByRule",TRUE). END.
 oAudit=NEW JsonObject(). oAudit:Add("version",1). oAudit:Add("source","progress-transaction"). oAudit:Add("resource","container-despesas"). oAudit:Add("operation",cOperation).
 IF NOT lBatch THEN DO:
  oAudit:Add("recordId",iTarget). oAudit:Add("before",CAST(oBeforeRows[1]:Clone(),JsonObject)).
  IF aData:Length>0 THEN oAudit:Add("after",CAST(aData:GetJsonObject(1):Clone(),JsonObject)). ELSE oAudit:Add("after",NEW JsonObject()).
 END.
 oAudit:Add("container_id",iContainer). oRow=NEW JsonObject(). oRow:Add("before",oMasterBefore). oRow:Add("after",oMasterAfter). oAudit:Add("master",oRow).
 oAudit:Add("changes",aChanges). oAudit:Add("warnings",aWarnings). oAudit:Add("actor",oActor). poResponse:Add("audit",oAudit).
 IF VALID-HANDLE(phRuntime) THEN DO:
  IF Exact("LogRule",phRuntime:INTERNAL-ENTRIES) THEN RUN LogRule IN phRuntime("INFO","Despesas do container " + STRING(iContainer) + " confirmadas; operacao " + cOperation) NO-ERROR.
 END.
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). oRow=NEW JsonObject(). poResponse:Add("success",FALSE).
  oRow:Add("code",cFailure). oRow:Add("message",e:GetMessage(1)).
  oRow:Add("status",IF Exact(cFailure,"CONTAINER_NOT_FOUND,CONTAINER_EXPENSE_NOT_FOUND") THEN 404 ELSE IF Exact(cFailure,"CONTAINER_BUSY,CONTAINER_EXPENSE_PERSISTENCE,CONTAINER_TRANSACTION_CONTEXT,CONTAINER_EXPENSE_CHANGED") THEN 409 ELSE IF cFailure="CONTAINER_EXPENSE_CONFIGURATION" THEN 500 ELSE IF cFailure="CONTAINER_IDENTITY_REQUIRED" THEN 401 ELSE 422).
  poResponse:Add("error",oRow).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(phContainer) THEN phContainer:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phExpenses) THEN phExpenses:BUFFER-RELEASE() NO-ERROR.

 END FINALLY.
END.

PROCEDURE ValidateValues:
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE amount AS DECIMAL NO-UNDO.
 names=oValues:GetNames(). IF EXTENT(names)=? OR EXTENT(names)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Nenhum campo informado.",1).
 DO j=1 TO EXTENT(names):
  f=names[j]. IF NOT Exact(f,IF lBatch THEN "vl_prev,vl_base_imp,log_manual" ELSE "despesa_id,vl_prev,vl_base_imp,vl_negociado,log_manual,perc_calc") THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao editavel.",1).
  IF f="log_manual" THEN DO: IF oValues:GetType(f)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario.",1). END.
  ELSE DO:
   IF oValues:GetType(f)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Numero JSON necessario.",1).
   amount=oValues:GetDecimal(f). IF amount=? THEN UNDO, THROW NEW Progress.Lang.AppError("Valor desconhecido.",1).
   IF f="despesa_id" AND Id(oValues,f)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa deve ser ID inteiro positivo.",1).
   IF f="perc_calc" AND (amount<0 OR amount>100) THEN UNDO, THROW NEW Progress.Lang.AppError("Percentual deve estar entre0e100.",1).
  END.
 END.
 IF cOperation="create" AND NOT oValues:Has("despesa_id") THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa necessaria.",1).
END PROCEDURE.
/* The renderer echoes all editable fields, even fields derived for the target
   manual mode. A readonly echo is allowed only against this row's locked before
   image, never against the rounded proposal or another row/client snapshot. */
FUNCTION PersistedDerivedEcho RETURNS LOGICAL (fieldName AS CHARACTER):
 IF cOperation<>"update" THEN RETURN FALSE.
 IF NOT oBefore:Has(fieldName) THEN RETURN FALSE.
 IF oBefore:GetType(fieldName)<>JsonDataType:NUMBER THEN RETURN FALSE.
 RETURN oValues:GetDecimal(fieldName)=oBefore:GetDecimal(fieldName).
END FUNCTION.
PROCEDURE ValidateProposed:
 DEFINE VARIABLE expenseId AS INTEGER NO-UNDO. DEFINE VARIABLE manual AS LOGICAL NO-UNDO.
 DEFINE VARIABLE calculated AS LOGICAL NO-UNDO. DEFINE VARIABLE percentValue AS DECIMAL NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 expenseId=oProposed:GetInteger("despesa_id").
 cFailure="CONTAINER_EXPENSE_PROTECTED".
 IF cOperation<>"create" AND iProtected>0 AND (expenseId=iProtected OR oBefore:GetInteger("despesa_id")=iProtected) THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa de distribuicao de custo protegida.",1).
 cFailure="CONTAINER_EXPENSE_COMPANY".
 IF NOT UniqueRow(phDefs,phDefs:NAME + ".despesa_id=" + STRING(expenseId)) OR NOT UniqueRow(phLinks,phLinks:NAME + ".despesa_id=" + STRING(expenseId) + " AND " + phLinks:NAME + ".empresa_id=" + STRING(iCompany)) THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa sem vinculo unico a empresa do container.",1).
 IF lDelete THEN RETURN.
 cFailure="CONTAINER_EXPENSE_VALIDATION".
 ASSIGN manual=oProposed:GetLogical("log_manual") percentValue=oProposed:GetDecimal("perc_calc") calculated=phDefs:BUFFER-FIELD("log_calculada"):BUFFER-VALUE.
 IF manual=? OR percentValue=? OR calculated=? THEN UNDO, THROW NEW Progress.Lang.AppError("Regra manual/percentual desconhecida.",1).
 IF lBatch THEN DO:
  IF NOT manual AND percentValue=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Calculo nao manual exige percentual persistido.",1).
 END.
 ELSE DO:
  IF NOT calculated AND oValues:Has("log_manual") THEN DO:
   IF cOperation="create" AND NOT manual THEN UNDO, THROW NEW Progress.Lang.AppError("Manual e derivado para despesa nao calculada.",1).
   IF cOperation="update" AND manual<>oBefore:GetLogical("log_manual") THEN UNDO, THROW NEW Progress.Lang.AppError("Manual nao editavel nesta despesa.",1).
  END.
  IF manual THEN DO:
   IF oValues:Has("perc_calc") THEN IF oValues:GetDecimal("perc_calc")<>0 AND NOT PersistedDerivedEcho("perc_calc") THEN UNDO, THROW NEW Progress.Lang.AppError("Percentual de despesa manual nao editavel.",1).
   oProposed:Set("perc_calc",0).
  END.
  ELSE DO:
   IF oValues:Has("vl_prev") THEN IF oValues:GetDecimal("vl_prev")<>0 AND NOT PersistedDerivedEcho("vl_prev") THEN UNDO, THROW NEW Progress.Lang.AppError("Previsto automatico nao editavel.",1).
   oProposed:Set("vl_prev",0).
   IF percentValue=0 THEN DO: percentValue=phDefs:BUFFER-FIELD("perc_calculo"):BUFFER-VALUE. IF percentValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("Percentual padrao desconhecido.",1). oProposed:Set("perc_calc",percentValue). END.
  END.
  /* Individual form's uniqueness checks intentionally include item rows. */
  CREATE QUERY q. q:SET-BUFFERS(phExpenses).
  q:QUERY-PREPARE("FOR EACH " + phExpenses:NAME + " WHERE " + phExpenses:NAME + ".container_id=" + STRING(iContainer) + " AND " + phExpenses:NAME + ".despesa_id=" + STRING(expenseId) + " AND " + phExpenses:NAME + ".despesa_container_id<>" + STRING(ttRow.id)).
  q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF phExpenses:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa em uso.",1).
  IF NOT q:QUERY-OFF-END THEN DO: cFailure="CONTAINER_EXPENSE_EXISTS". UNDO, THROW NEW Progress.Lang.AppError("Outra linha da despesa existe neste container.",1). END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
 END.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END PROCEDURE.
PROCEDURE AddEvent:
 DEFINE INPUT PARAMETER resource AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER operationName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER recordId AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER before AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER after AS JsonObject NO-UNDO.
 DEFINE VARIABLE event AS JsonObject NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DO j=1 TO aChanges:Length:
  event=aChanges:GetJsonObject(j).
  IF event:GetCharacter("resource")=resource AND event:GetInteger("recordId")=recordId THEN DO:
   event:Set("after",CAST(after:Clone(),JsonObject)). RETURN.
  END.
 END.
 event=NEW JsonObject(). event:Add("resource",resource). event:Add("operation",operationName). event:Add("recordId",recordId).
 event:Add("before",CAST(before:Clone(),JsonObject)). event:Add("after",CAST(after:Clone(),JsonObject)). aChanges:Add(event).
END PROCEDURE.
PROCEDURE ApplyFiscal:
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE m AS INTEGER NO-UNDO. DEFINE VARIABLE event AS JsonObject NO-UNDO.
 cFailure="CONTAINER_EXPENSE_RULE_FAILED".
 RUN CollectCalculationInputs IN phRuntime(phContainer,OUTPUT oInputs).
 oFiscalPolicy=NEW JsonObject(). oFiscalPolicy:Add("usuario_id",poPolicy:GetInteger("usuario_id")). oFiscalPolicy:Add("actor",oActor:GetCharacter("login")).
 oFiscalPolicy:Add("despesa_distr_custo",iProtected).
 DO j=1 TO (IF cOperation="batch_update" THEN 1 ELSE 2):
  oFiscalRequest=NEW JsonObject(). oFiscalRequest:Add("operation",ENTRY(j,"sincronizar,atualizar_despesas_calculadas")). oFiscalRequest:Add("container_id",iContainer).
  RUN VALUE(cFiscalProgram)(phContainer,phEmpresas,phItems,phPurchaseItems,phPurchases,phDefs,phLinks,phTaxBases,phRelations,phCalcs,phExpenses,phRuntime,oFiscalPolicy,oInputs,oFiscalRequest,OUTPUT oFiscalResponse).
  IF NOT oFiscalResponse:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError(oFiscalResponse:GetJsonObject("error"):GetCharacter("code") + ": " + oFiscalResponse:GetJsonObject("error"):GetCharacter("message"),1).
  IF oFiscalResponse:Has("audit") OR oFiscalResponse:GetJsonObject("data"):GetLogical("committed") OR NOT oFiscalResponse:Has("pendingChanges") THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal nao confirmou composicao pendente.",1).
  DO m=1 TO oFiscalResponse:GetJsonArray("pendingChanges"):Length:
   event=oFiscalResponse:GetJsonArray("pendingChanges"):GetJsonObject(m).
   RUN AddEvent(event:GetCharacter("resource"),event:GetCharacter("operation"),event:GetInteger("recordId"),event:GetJsonObject("before"),event:GetJsonObject("after")).
  END.
  DO m=1 TO oFiscalResponse:GetJsonObject("data"):GetJsonArray("warnings"):Length: aWarnings:Add(oFiscalResponse:GetJsonObject("data"):GetJsonArray("warnings"):GetCharacter(m)). END.
 END.
END PROCEDURE.

/* Link lifecycle only. Currency, financial allocations and fiscal effects are
   trusted reusable participants; EMS5 titles are locked, never modified here. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTitles AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/ContainerTransactionAudit.i}
{sursum-api/includes/ContainerMaintenanceEffects.i}
{sursum-api/includes/ContainerBufferSibling.i}
{sursum-api/includes/ContainerPaymentIdentity.i}
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE titleId AS INTEGER NO-UNDO.
DEFINE VARIABLE operationName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE associationKey AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE titleEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO INITIAL "CONTAINER_PAYMENT_VALIDATION".
DEFINE VARIABLE statusValue AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE nestedValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
DEFINE VARIABLE allLinks AS HANDLE NO-UNDO.
DEFINE VARIABLE titleScan AS HANDLE NO-UNDO.
DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE masterBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE masterAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE eligibleValue AS JsonObject NO-UNDO.
DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
DEFINE VARIABLE effectsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE auditValue AS JsonObject NO-UNDO.
DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE masterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
DEFINE VARIABLE imageValue AS JsonObject NO-UNDO.
DEFINE VARIABLE changesValue AS JsonArray NO-UNDO.
DEFINE VARIABLE warningsValue AS JsonArray NO-UNDO.
DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
FUNCTION N RETURNS CHARACTER (valueId AS INTEGER): RETURN TRIM(STRING(valueId,"->>>>>>>>>9")). END FUNCTION.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER objectValue AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE nameText AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE x AS INTEGER NO-UNDO. DEFINE VARIABLE accepted AS LOGICAL NO-UNDO.
 IF NOT VALID-OBJECT(objectValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto JSON obrigatorio.",1).
 names=objectValue:GetNames().
 DO n=1 TO EXTENT(names):
  nameText=names[n]. accepted=FALSE.
  DO x=1 TO NUM-ENTRIES(allowed): IF nameText=ENTRY(x,allowed) THEN accepted=TRUE. END.
  IF NOT accepted THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao permitido: " + nameText,1).
 END.
END PROCEDURE.
FUNCTION Id RETURNS INTEGER (objectValue AS JsonObject,fieldName AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE amount AS DECIMAL NO-UNDO.
 IF NOT objectValue:Has(fieldName) THEN RETURN ?.
 CASE objectValue:GetType(fieldName):
  WHEN JsonDataType:NUMBER THEN rawValue=STRING(objectValue:GetJsonText(fieldName)).
  WHEN JsonDataType:STRING THEN rawValue=objectValue:GetCharacter(fieldName).
  OTHERWISE RETURN ?.
 END CASE.
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN RETURN ?.
 DO n=1 TO LENGTH(rawValue): IF INDEX("0123456789",SUBSTRING(rawValue,n,1))=0 THEN RETURN ?. END.
 amount=DECIMAL(rawValue). IF amount<1 OR amount>2147483647 THEN RETURN ?. RETURN INTEGER(amount).
END FUNCTION.
FUNCTION MatchesAssociationKey RETURNS LOGICAL ():
 DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE establishment AS CHARACTER NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(titleScan).
  IF NOT q:QUERY-PREPARE("FOR EACH " + titleScan:NAME + " WHERE num_id_tit_ap=" + N(titleId) + " NO-LOCK") THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de identidade invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST().
  DO WHILE NOT q:QUERY-OFF-END:
   establishment=titleScan:BUFFER-FIELD("cod_estab"):BUFFER-VALUE.
   IF ContainerPaymentKey(cid,establishment,titleId)=associationKey THEN RETURN TRUE.
   q:GET-NEXT().
  END.
  RETURN FALSE.
  FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. END FINALLY.
 END.
END FUNCTION.
PROCEDURE ValidateGlobalOwner:
 DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE countValue AS INTEGER NO-UNDO. DEFINE VARIABLE ownerValue AS INTEGER NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(allLinks).
  IF NOT q:QUERY-PREPARE("FOR EACH " + allLinks:NAME + " WHERE num_id_tit_ap=" + N(titleId)) THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa de dono invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF ERROR-STATUS:ERROR OR allLinks:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculos em uso.",1).
  DO WHILE NOT q:QUERY-OFF-END:
   countValue=countValue + 1. ownerValue=allLinks:BUFFER-FIELD("container_id"):BUFFER-VALUE.
   q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
   IF ERROR-STATUS:ERROR OR allLinks:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculos em uso.",1).
  END.
  IF operationName="create" AND countValue>0 THEN DO: codeValue="CONTAINER_PAYMENT_EXISTS". UNDO, THROW NEW Progress.Lang.AppError("Titulo ja associado a um container.",1). END.
  IF operationName="delete" AND (countValue<>1 OR ownerValue<>cid) THEN DO: codeValue="CONTAINER_PAYMENT_AMBIGUOUS". UNDO, THROW NEW Progress.Lang.AppError("Dono do titulo ausente ou ambiguo.",1). END.
  FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. END FINALLY.
 END.
END PROCEDURE.
FUNCTION Found RETURNS LOGICAL (bufferValue AS HANDLE,conditionText AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
 foundValue=bufferValue:FIND-FIRST("WHERE " + conditionText,lockMode,NO-WAIT) NO-ERROR.
 IF bufferValue:LOCKED THEN DO: codeValue="CONTAINER_PAYMENT_BUSY". statusValue=409. UNDO, THROW NEW Progress.Lang.AppError("Registro em uso.",1). END.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Falha de consulta nao equivale a ausencia.",1). END.
 RETURN foundValue.
END FUNCTION.
PROCEDURE ResolveTitle:
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE countValue AS INTEGER NO-UNDO. DEFINE VARIABLE rowValue AS ROWID NO-UNDO. DEFINE VARIABLE lockedValue AS LOGICAL NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(titleScan).
  IF NOT q:QUERY-PREPARE("FOR EACH " + titleScan:NAME + " WHERE num_id_tit_ap=" + N(titleId) + " NO-LOCK") THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa de titulo invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST().
  DO WHILE NOT q:QUERY-OFF-END: countValue=countValue + 1. rowValue=titleScan:ROWID. q:GET-NEXT(). END.
  IF countValue=0 THEN DO: codeValue="CONTAINER_PAYMENT_NOT_FOUND". statusValue=404. UNDO, THROW NEW Progress.Lang.AppError("Titulo nao localizado.",1). END.
  IF countValue<>1 THEN DO: codeValue="CONTAINER_PAYMENT_AMBIGUOUS". statusValue=422. UNDO, THROW NEW Progress.Lang.AppError("ID de titulo ambiguo entre estabelecimentos.",1). END.
  lockedValue=phTitles:FIND-BY-ROWID(rowValue,lockMode,NO-WAIT) NO-ERROR.
  IF NOT lockedValue OR ERROR-STATUS:ERROR OR phTitles:LOCKED THEN DO: codeValue="CONTAINER_PAYMENT_BUSY". statusValue=409. UNDO, THROW NEW Progress.Lang.AppError("Titulo em uso ou alterado durante consulta.",1). END.
  IF phTitles:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE<>titleId THEN UNDO, THROW NEW Progress.Lang.AppError("Titulo mudou durante consulta.",1).
  titleEstab=phTitles:BUFFER-FIELD("cod_estab"):BUFFER-VALUE.
  IF titleEstab=? OR titleEstab="" THEN UNDO, THROW NEW Progress.Lang.AppError("Estabelecimento do titulo ausente.",1).
  FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. END FINALLY.
 END.
END PROCEDURE.
FUNCTION LinkImage RETURNS JsonObject ():
 DEFINE VARIABLE image AS JsonObject NO-UNDO.
 image=ProcessSnapshot(phLinks,cid). image:Add("pagamento_key",associationKey). image:Add("cod_estab",titleEstab). RETURN image.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,"operation,container_id,id,pagamento_key,values").
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao obrigatoria.",1).
 operationName=poRequest:GetCharacter("operation"). cid=Id(poRequest,"container_id").
 IF (operationName<>"create" AND operationName<>"delete") OR cid=? THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao/container invalido.",1).
 IF operationName="create" THEN DO:
  IF poRequest:Has("id") OR poRequest:Has("pagamento_key") THEN UNDO, THROW NEW Progress.Lang.AppError("Identidade gerada pelo servidor.",1).
  RUN Closed(poRequest:GetJsonObject("values"),"num_id_tit_ap").
  titleId=Id(poRequest:GetJsonObject("values"),"num_id_tit_ap").
  IF titleId=? OR poRequest:GetJsonObject("values"):GetType("num_id_tit_ap")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Selecione um titulo inteiro positivo.",1).
 END.
 ELSE DO:
  IF poRequest:Has("values") THEN UNDO, THROW NEW Progress.Lang.AppError("Valores nao permitidos na desvinculacao.",1).
  associationKey=poRequest:GetCharacter("id").
  IF LENGTH(associationKey)<>66 OR SUBSTRING(associationKey,1,2)<>"p_" THEN UNDO, THROW NEW Progress.Lang.AppError("Chave de pagamento invalida.",1).
  DO j=3 TO 66: IF INDEX("0123456789ABCDEF",SUBSTRING(associationKey,j,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Chave de pagamento invalida.",1). END.
  IF poRequest:Has("pagamento_key") THEN IF poRequest:GetCharacter("pagamento_key")<>associationKey THEN UNDO, THROW NEW Progress.Lang.AppError("Alias da chave divergente.",1).
 END.
 nestedValue=TRANSACTION. statusValue=401. codeValue="CONTAINER_PAYMENT_IDENTITY_REQUIRED".
 actorValue=NEW JsonObject(). nameValue=poPolicy:GetJsonObject("actor"):GetCharacter("login").
 IF nameValue=? OR TRIM(nameValue)="" OR LENGTH(nameValue)>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Autoria autenticada obrigatoria.",1).
 actorValue:Add("login",nameValue).
 statusValue=409. codeValue="CONTAINER_PAYMENT_TRANSACTION_CONTEXT".
 IF poPolicy:Has("allow_nested") THEN IF poPolicy:GetType("allow_nested")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao privada exige booleano.",1).
 IF nestedValue THEN DO:
  IF NOT poPolicy:Has("allow_nested") THEN UNDO, THROW NEW Progress.Lang.AppError("Transacao raiz propria obrigatoria.",1).
  IF NOT poPolicy:GetLogical("allow_nested") THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao privada nao habilitada.",1).
 END.
 IF NOT VALID-HANDLE(phRuntime) OR LOOKUP("ChangePayment",phRuntime:INTERNAL-ENTRIES)=0 OR LOOKUP("ValidateTitle",phRuntime:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao de pagamentos indisponivel.",1).
 RUN ContainerCreateSiblingBuffer(phLinks,"bPaymentAllLinks",OUTPUT allLinks).
 RUN ContainerCreateSiblingBuffer(phTitles,"bPaymentTitleScan",OUTPUT titleScan).
 DO TRANSACTION ON ERROR UNDO, THROW:
  statusValue=404. codeValue="CONTAINER_NOT_FOUND".
  IF NOT Found(phMaster,phMaster:NAME + ".nr-container=" + N(cid),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1).
  masterBefore=ProcessSnapshot(phMaster,cid).
  IF operationName="delete" THEN DO:
   CREATE QUERY queryValue. queryValue:SET-BUFFERS(allLinks).
   IF NOT queryValue:QUERY-PREPARE("FOR EACH " + allLinks:NAME + " WHERE container_id=" + N(cid) + " NO-LOCK") THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa de vinculos invalida.",1).
   queryValue:QUERY-OPEN(). queryValue:GET-FIRST(). titleId=?.
   DO WHILE NOT queryValue:QUERY-OFF-END:
    titleId=allLinks:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
    IF MatchesAssociationKey() THEN LEAVE.
    titleId=?. queryValue:GET-NEXT().
   END.
   queryValue:QUERY-CLOSE(). DELETE OBJECT queryValue. queryValue=?.
   IF titleId=? THEN DO: codeValue="CONTAINER_PAYMENT_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Vinculo nao localizado neste container.",1). END.
  END.
  /* Global title mutex: no EMS5 field is assigned, created or deleted. */
  RUN ResolveTitle(EXCLUSIVE-LOCK).
  IF operationName="create" THEN associationKey=ContainerPaymentKey(cid,titleEstab,titleId).
  ELSE IF associationKey<>ContainerPaymentKey(cid,titleEstab,titleId) THEN UNDO, THROW NEW Progress.Lang.AppError("Chave do titulo mudou.",1).
  codeValue="CONTAINER_PAYMENT_EXISTS". statusValue=409.
  RUN ValidateGlobalOwner.
  IF operationName="create" THEN DO:
   codeValue="CONTAINER_PAYMENT_INELIGIBLE". statusValue=422.
   RUN ValidateTitle IN phRuntime(phMaster,titleId,OUTPUT eligibleValue).
   IF NOT VALID-OBJECT(eligibleValue) OR eligibleValue:GetInteger("num_id_tit_ap")<>titleId OR eligibleValue:GetCharacter("cod_estab")<>titleEstab OR eligibleValue:GetInteger("container_id")<>cid THEN UNDO, THROW NEW Progress.Lang.AppError("Titulo nao elegivel para este container.",1).
   IF eligibleValue:Has("pagamento_key") THEN DO:
    IF eligibleValue:GetCharacter("pagamento_key")<>associationKey THEN UNDO, THROW NEW Progress.Lang.AppError("Identidade da selecao divergente.",1).
   END.
   ELSE eligibleValue:Add("pagamento_key",associationKey).
   beforeValue=NEW JsonObject().
   IF NOT phLinks:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Criacao de vinculo recusada.",1).
   ASSIGN phLinks:BUFFER-FIELD("container_id"):BUFFER-VALUE=cid phLinks:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE=titleId.
   IF NOT phLinks:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculo recusado pelo banco.",1).
   afterValue=LinkImage().
  END.
  ELSE DO:
   codeValue="CONTAINER_PAYMENT_NOT_FOUND". statusValue=404.
   IF NOT Found(phLinks,phLinks:NAME + ".container_id=" + N(cid) + " AND num_id_tit_ap=" + N(titleId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculo nao localizado neste container.",1).
   beforeValue=LinkImage(). afterValue=NEW JsonObject().
  END.
  contextValue=NEW JsonObject(). contextValue:Add("operation",IF operationName="create" THEN "associate" ELSE "disassociate"). contextValue:Add("container_id",cid).
  imageValue=NEW JsonObject(). imageValue:Add("container_id",cid). imageValue:Add("num_id_tit_ap",titleId).
  contextValue:Add("before",IF operationName="create" THEN NEW JsonObject() ELSE CAST(imageValue:Clone(),JsonObject)).
  contextValue:Add("after",IF operationName="create" THEN CAST(imageValue:Clone(),JsonObject) ELSE NEW JsonObject()).
  codeValue="CONTAINER_PAYMENT_RULE_FAILED". statusValue=422.
  RUN ChangePayment IN phRuntime(phMaster,contextValue,OUTPUT effectsValue).
  RUN MaintenanceValidateEffects(effectsValue,cid,"itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp","",0,OUTPUT changesValue,OUTPUT warningsValue).
  IF operationName="delete" THEN DO:
   IF NOT Found(phLinks,phLinks:NAME + ".container_id=" + N(cid) + " AND num_id_tit_ap=" + N(titleId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Participante perdeu o vinculo original.",1).
   IF NOT phLinks:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Desvinculacao recusada pelo banco.",1).
  END.
  ELSE DO:
   IF NOT Found(phLinks,phLinks:NAME + ".container_id=" + N(cid) + " AND num_id_tit_ap=" + N(titleId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Participante removeu o vinculo.",1).
   afterValue=LinkImage().
  END.
  IF NOT Found(phMaster,phMaster:NAME + ".nr-container=" + N(cid),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Participante perdeu o mestre.",1).
  ASSIGN phMaster:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE phMaster:BUFFER-FIELD("dt_hr_ult_alt_versao_custo"):BUFFER-VALUE=DATETIME(TODAY,MTIME).
  IF NOT phMaster:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Mestre recusou invalidacao.",1).
  masterAfter=ProcessSnapshot(phMaster,cid).
 /* Build/validate the whole result before commit; only return after END. */
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("committed",NOT nestedValue).
 IF operationName="create" THEN DO:
  poResponse:Add("data",eligibleValue).
 END.
 masterValue=NEW JsonObject(). masterValue:Add("before",masterBefore). masterValue:Add("after",masterAfter).
 IF nestedValue THEN DO:
  poResponse:Add("pendingChanges",changesValue). poResponse:Add("pendingMaster",masterValue).
  eventValue=NEW JsonObject(). eventValue:Add("before",beforeValue). eventValue:Add("after",afterValue). poResponse:Add("pendingPayment",eventValue). poResponse:Add("warnings",warningsValue).
 END.
 ELSE DO:
  auditValue=NEW JsonObject(). auditValue:Add("version",1). auditValue:Add("source","progress-transaction"). auditValue:Add("resource","container-pagamentos"). auditValue:Add("operation",operationName).
  auditValue:Add("recordId",associationKey). auditValue:Add("container_id",cid). auditValue:Add("before",beforeValue). auditValue:Add("after",afterValue). auditValue:Add("master",masterValue).
  auditValue:Add("changes",changesValue). auditValue:Add("warnings",warningsValue). auditValue:Add("actor",actorValue). poResponse:Add("audit",auditValue).
 END.
 END.
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). eventValue=NEW JsonObject(). eventValue:Add("code",codeValue). eventValue:Add("message",err:GetMessage(1)). eventValue:Add("status",statusValue). poResponse:Add("success",FALSE). poResponse:Add("error",eventValue).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(queryValue) THEN DELETE OBJECT queryValue NO-ERROR.
 END FINALLY.
END.

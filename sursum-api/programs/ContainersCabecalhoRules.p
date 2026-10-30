/* Trusted persistent business provider. Caller owns the master transaction.
   No commits, external file deletion, or log flushes occur here. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
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
DEFINE INPUT PARAMETER phCommercial AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPermissions AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRepBalances AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscountLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAttachments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersions AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSupplierLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemCosts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE bh AS HANDLE EXTENT 24 NO-UNDO.
DEFINE VARIABLE aChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE aWarnings AS JsonArray NO-UNDO.
DEFINE TEMP-TABLE ttDelete NO-UNDO
 FIELD ordinal AS INTEGER FIELD hIndex AS INTEGER FIELD recordRow AS ROWID
 INDEX pk IS PRIMARY UNIQUE ordinal.
DEFINE VARIABLE deleteOrdinal AS INTEGER NO-UNDO.
DEFINE VARIABLE masterId AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE fiscalProgram AS CHARACTER NO-UNDO.

ASSIGN bh[1]=phEmpresas bh[2]=phItems bh[3]=phPurchaseItems bh[4]=phPurchases
 bh[5]=phDefs bh[6]=phLinks bh[7]=phTaxBases bh[8]=phRelations bh[9]=phCalcs
 bh[10]=phExpenses bh[11]=phCommercial bh[12]=phPermissions bh[13]=phRepBalances
 bh[14]=phNfs bh[15]=phDiscountLedger bh[16]=phAttachments bh[17]=phVersions
 bh[18]=phPayments bh[19]=phSupplierLedger bh[20]=phItemCosts.

FUNCTION HasRows RETURNS LOGICAL (h AS HANDLE,conditionText AS CHARACTER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(h).
  IF NOT q:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + conditionText) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_QUERY: consulta fixa invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF h:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: dependencia em uso.",1).
  IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_QUERY: falha ao ler dependencia.",1).
  RETURN NOT q:QUERY-OFF-END.
  FINALLY:
   IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
  END FINALLY.
 END.
END FUNCTION.
FUNCTION Snapshot RETURNS JsonObject (h AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE name AS CHARACTER NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE n64 AS INT64 NO-UNDO.
 DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE flag AS LOGICAL NO-UNDO.
 DEFINE VARIABLE da AS DATE NO-UNDO.
 DEFINE VARIABLE dm AS DATETIME NO-UNDO.
 DEFINE VARIABLE dz AS DATETIME-TZ NO-UNDO.
 o=NEW JsonObject().
 DO k=1 TO h:NUM-FIELDS:
  f=h:BUFFER-FIELD(k). name=REPLACE(f:NAME,"-","_").
  IF f:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_SCHEMA: extent nao previsto no snapshot.",1).
  IF f:BUFFER-VALUE=? THEN o:AddNull(name).
  ELSE CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: c=f:BUFFER-VALUE. o:Add(name,c). END.
   WHEN "INTEGER" THEN DO: n=f:BUFFER-VALUE. o:Add(name,n). END.
   WHEN "INT64" THEN DO: n64=f:BUFFER-VALUE. o:Add(name,n64). END.
   WHEN "DECIMAL" THEN DO: amount=f:BUFFER-VALUE. o:Add(name,amount). END.
   WHEN "LOGICAL" THEN DO: flag=f:BUFFER-VALUE. o:Add(name,flag). END.
   WHEN "DATE" THEN DO: da=f:BUFFER-VALUE. o:Add(name,da). END.
   WHEN "DATETIME" THEN DO: dm=f:BUFFER-VALUE. o:Add(name,dm). END.
   WHEN "DATETIME-TZ" THEN DO: dz=f:BUFFER-VALUE. o:Add(name,dz). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_SCHEMA: tipo nao previsto no snapshot.",1).
  END CASE.
 END.
 RETURN o.
END FUNCTION.
FUNCTION RuntimeReady RETURNS LOGICAL ():
 IF NOT VALID-HANDLE(phRuntime) THEN RETURN FALSE.
 IF phRuntime:TYPE<>"PROCEDURE" THEN RETURN FALSE.
 fiscalProgram=SEARCH("sursum-api/programs/ContainersImpostosService.r").
 IF fiscalProgram=? THEN fiscalProgram=SEARCH("ContainersImpostosService.r").
 IF fiscalProgram=? THEN RETURN FALSE.
 RETURN LOOKUP("CollectCalculationInputs",phRuntime:INTERNAL-ENTRIES)>0
  AND LOOKUP("NextCalculoId",phRuntime:INTERNAL-ENTRIES)>0
  AND LOOKUP("NextDespesaId",phRuntime:INTERNAL-ENTRIES)>0.
END FUNCTION.
/* Optional private extension. The original 20-buffer constructor remains the
   update/generation ABI; deletion requires these targets only for owned versions. */
PROCEDURE SetVersionDeleteTargets:
 DEFINE INPUT PARAMETER expenses AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER invoices AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER payments AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER discounts AS HANDLE NO-UNDO.
 ASSIGN bh[21]=expenses bh[22]=invoices bh[23]=payments bh[24]=discounts.
END PROCEDURE.
PROCEDURE GetCapabilities:
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE canUpdate AS LOGICAL NO-UNDO INITIAL TRUE.
 DEFINE VARIABLE canDelete AS LOGICAL NO-UNDO INITIAL TRUE.
 DO i=1 TO 20:
  IF NOT VALID-HANDLE(bh[i]) THEN DO:
   canDelete=FALSE. IF i<=10 THEN canUpdate=FALSE.
  END.
 END.
 result=NEW JsonObject(). result:Add("contract","container-rules-v1").
 result:Add("onUpdate",canUpdate AND RuntimeReady()). result:Add("beforeDelete",canDelete).
END PROCEDURE.
PROCEDURE CheckContext:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER operationName AS CHARACTER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_TRANSACTION_CONTEXT: provider requer transacao raiz ativa.",1).
 IF NOT VALID-HANDLE(master) OR NOT VALID-OBJECT(ctx) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: contexto ausente.",1).
 IF NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre nao bloqueado.",1).
 masterId=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
 IF masterId=? OR masterId<=0 OR ctx:GetType("container_id")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: identificador invalido.",1).
 IF ctx:GetInteger("container_id")<>masterId OR ctx:GetCharacter("operation")<>operationName THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: contexto divergente.",1).
 IF NOT VALID-OBJECT(poPolicy) OR poPolicy:GetType("actor")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_IDENTITY_REQUIRED: ator privado ausente.",1).
 IF poPolicy:GetJsonObject("actor"):GetCharacter("login")="" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_IDENTITY_REQUIRED: login privado ausente.",1).
 /* Reacquire/confirm the parent lock without changing the caller's buffer. */
 IF NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: mestre em uso.",1).
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE inputs AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscalPolicy AS JsonObject NO-UNDO.
 DEFINE VARIABLE req AS JsonObject NO-UNDO.
 DEFINE VARIABLE response AS JsonObject NO-UNDO.
 DEFINE VARIABLE opIndex AS INTEGER NO-UNDO.
 DEFINE VARIABLE managedId AS DECIMAL NO-UNDO.
 RUN CheckContext(master,ctx,"update").
 IF NOT RuntimeReady() THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: coletor/sequencias nao implementados.",1).
 aChanges=NEW JsonArray(). aWarnings=NEW JsonArray().
 RUN CollectCalculationInputs IN phRuntime(master,OUTPUT inputs).
 fiscalPolicy=NEW JsonObject(). fiscalPolicy:Add("usuario_id",poPolicy:GetInteger("usuario_id")). fiscalPolicy:Add("actor",poPolicy:GetJsonObject("actor"):GetCharacter("login")).
 IF poPolicy:Has("despesa_distr_custo") THEN DO:
  IF poPolicy:GetType("despesa_distr_custo")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONFIGURATION: parametro privado de distribuicao invalido.",1).
  managedId=poPolicy:GetDecimal("despesa_distr_custo").
  IF managedId=? OR managedId<0 OR managedId>2147483647 OR managedId<>TRUNCATE(managedId,0) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONFIGURATION: parametro privado de distribuicao invalido.",1).
  fiscalPolicy:Add("despesa_distr_custo",INTEGER(managedId)).
 END.
 DO opIndex=1 TO 2:
  req=NEW JsonObject(). req:Add("operation",ENTRY(opIndex,"sincronizar,atualizar_despesas_calculadas")). req:Add("container_id",masterId).
  RUN VALUE(fiscalProgram)(master,phEmpresas,phItems,phPurchaseItems,phPurchases,phDefs,phLinks,phTaxBases,phRelations,phCalcs,phExpenses,THIS-PROCEDURE,fiscalPolicy,inputs,req,OUTPUT response).
  IF NOT response:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError(response:GetJsonObject("error"):GetCharacter("code") + ": " + response:GetJsonObject("error"):GetCharacter("message"),1).
  IF response:Has("audit") OR response:GetJsonObject("data"):GetLogical("committed") OR NOT response:Has("pendingChanges") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_TRANSACTION: fiscal nao confirmou composicao pending.",1).
  RUN MergeChanges(response:GetJsonArray("pendingChanges")).
  IF response:GetJsonObject("data"):Has("warnings") THEN DO j=1 TO response:GetJsonObject("data"):GetJsonArray("warnings"):Length:
   aWarnings:Add(response:GetJsonObject("data"):GetJsonArray("warnings"):GetCharacter(j)).
  END.
 END.
 result=NEW JsonObject(). result:Add("success",TRUE). result:Add("changes",aChanges). result:Add("warnings",aWarnings).
END PROCEDURE.
PROCEDURE MergeChanges:
 DEFINE INPUT PARAMETER incoming AS JsonArray NO-UNDO.
 DEFINE VARIABLE event AS JsonObject NO-UNDO.
 DEFINE VARIABLE previous AS JsonObject NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE m AS INTEGER NO-UNDO.
 DEFINE VARIABLE found AS LOGICAL NO-UNDO.
 DO k=1 TO incoming:Length:
  event=incoming:GetJsonObject(k). found=FALSE.
  DO m=1 TO aChanges:Length:
   previous=aChanges:GetJsonObject(m).
   IF previous:GetCharacter("resource")=event:GetCharacter("resource") AND previous:GetJsonText("recordId")=event:GetJsonText("recordId") THEN DO:
    previous:Set("after",CAST(event:GetJsonObject("after"):Clone(),JsonObject)). found=TRUE. LEAVE.
   END.
  END.
  IF NOT found THEN aChanges:Add(CAST(event:Clone(),JsonObject)).
 END.
END PROCEDURE.
PROCEDURE BeforeDelete:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE scanIndex AS INTEGER NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 RUN CheckContext(master,ctx,"delete").
 DO i=1 TO 20: IF NOT VALID-HANDLE(bh[i]) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: buffer fixo de exclusao indisponivel.",1). END.
 /* Approved16/10: dependency checks precede compensation and every cascade. */
 IF HasRows(phCommercial,phCommercial:NAME + ".nr-container=" + STRING(masterId)) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_COMMERCIAL_DEPENDENCY: itens comerciais vinculados impedem exclusao.",1).
 IF HasRows(phPayments,phPayments:NAME + ".container_id=" + STRING(masterId)) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_PAYMENTS_LINKED: desvincule pagamentos antes de excluir.",1).
 DO scanIndex=1 TO 2:
  CREATE QUERY q.
  IF scanIndex=1 THEN q:SET-BUFFERS(phItems). ELSE q:SET-BUFFERS(phVersions).
  IF scanIndex=1 THEN q:QUERY-PREPARE("FOR EACH " + phItems:NAME + " WHERE " + phItems:NAME + ".container_id=" + STRING(masterId)).
  ELSE q:QUERY-PREPARE("FOR EACH " + phVersions:NAME + " WHERE " + phVersions:NAME + ".container_id=" + STRING(masterId)).
  q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  DO WHILE NOT q:QUERY-OFF-END:
   IF scanIndex=1 THEN DO:
    IF phItems:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: item em uso.",1).
    valueId=phItems:BUFFER-FIELD("item_container_id"):BUFFER-VALUE.
   END.
   ELSE DO:
    IF phVersions:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: versao em uso.",1).
    valueId=phVersions:BUFFER-FIELD("versao_id"):BUFFER-VALUE.
   END.
   IF valueId=? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: vinculo de custo desconhecido.",1).
   IF HasRows(phItemCosts,phItemCosts:NAME + "." + (IF scanIndex=1 THEN "item_container_id" ELSE "versao_id") + "=" + STRING(valueId)) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_COSTS_LINKED: desvincule custos antes de excluir.",1).
   q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
   IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_QUERY: falha na validacao de custos.",1).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
 END.
 aChanges=NEW JsonArray(). EMPTY TEMP-TABLE ttDelete. deleteOrdinal=0.
 /* With no linked payments, legacy estorno=true has no title iterations.
    Never invent compensating entries for unrelated/orphaned historical rows. */
 RUN PlanDelete(12,"pp_container_permissao","nr_container","", "nr_container,cod_repres,regiao_repres,tipo_repres").
 RUN PlanDelete(13,"pp_container_saldo_repres","nr_container","", "nr_container,cod_repres,regiao_repres,tipo_repres").
 RUN PlanDelete(2,"itens_container","container_id","item_container_id", "").
 RUN PlanDelete(10,"despesas_container","container_id","despesa_container_id", "").
 RUN PlanDelete(14,"nfs_container","container_id","", "container_id,documento,serie,estab,nat_operacao,cod_emitente").
 RUN PlanDelete(15,"cta_corren_desconto","container_id","cta_corren_desconto_id", "").
 RUN PlanDelete(16,"anexos_container","container_id","anexo_container_id", "").
 RUN PlanDelete(9,"calcs_imp_container","container_id","calc_imp_container_id", "").
 RUN PlanVersionSnapshots.
 RUN PlanDelete(17,"versoes_item_custo_container","container_id","versao_id", "").
 FOR EACH ttDelete BY ttDelete.ordinal:
  IF NOT bh[ttDelete.hIndex]:FIND-BY-ROWID(ttDelete.recordRow,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: filho alterado durante exclusao.",1).
  IF NOT bh[ttDelete.hIndex]:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_DELETE_REJECTED: banco recusou exclusao de filho.",1).
 END.
 result=NEW JsonObject(). result:Add("success",TRUE). result:Add("changes",aChanges).
 FINALLY:
  IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
 END FINALLY.
END PROCEDURE.
PROCEDURE PlanDelete:
 DEFINE INPUT PARAMETER hIndex AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER resource AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER parentField AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER idField AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER compositeFields AS CHARACTER NO-UNDO.
 RUN PlanDeleteFor(hIndex,resource,parentField,masterId,idField,compositeFields).
END PROCEDURE.
PROCEDURE PlanVersionSnapshots:
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(phVersions).
  IF NOT q:QUERY-PREPARE("FOR EACH " + phVersions:NAME + " WHERE " + phVersions:NAME + ".container_id=" + STRING(masterId) + " BY " + phVersions:NAME + ".versao_id") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_QUERY: consulta de versoes invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF phVersions:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: falha ao bloquear conjunto de versoes.",1).
  DO WHILE NOT q:QUERY-OFF-END:
   IF phVersions:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: versao em uso.",1).
   versionId=phVersions:BUFFER-FIELD("versao_id"):BUFFER-VALUE.
   IF versionId=? OR versionId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_SCHEMA: versao com chave invalida.",1).
   DO n=21 TO 24:
    IF NOT VALID-HANDLE(bh[n]) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: alvo fixo de exclusao de snapshot de versao indisponivel.",1).
    IF bh[n]:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: buffer fixo de snapshot necessario.",1).
   END.
   RUN PlanDeleteFor(21,"item_container_custo_despesas","versao_id",versionId,"","versao_id,despesa_id").
   RUN PlanDeleteFor(22,"item_container_custo_nfs","versao_id",versionId,"","versao_id,documento,serie,estab,nat_operacao,cod_emitente").
   RUN PlanDeleteFor(23,"item_container_custo_pgtos","versao_id",versionId,"","versao_id,num_id_tit_ap").
   RUN PlanDeleteFor(24,"item_container_custo_descontos","versao_id",versionId,"","versao_id,desconto_importacao_id").
   q:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
   IF phVersions:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: falha ao percorrer conjunto de versoes.",1).
  END.
  FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE PlanDeleteFor:
 DEFINE INPUT PARAMETER hIndex AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER resource AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER parentField AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER parentId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER idField AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER compositeFields AS CHARACTER NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE event AS JsonObject NO-UNDO.
 DEFINE VARIABLE before AS JsonObject NO-UNDO.
 DEFINE VARIABLE key AS JsonObject NO-UNDO.
 DEFINE VARIABLE keyArray AS JsonArray NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE ordering AS CHARACTER NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(bh[hIndex]).
  IF idField<>"" THEN ordering="BY " + bh[hIndex]:NAME + "." + idField.
  ELSE DO n=1 TO NUM-ENTRIES(compositeFields): ordering=ordering + " BY " + bh[hIndex]:NAME + "." + ENTRY(n,compositeFields). END.
  IF NOT q:QUERY-PREPARE("FOR EACH " + bh[hIndex]:NAME + " WHERE " + bh[hIndex]:NAME + "." + parentField + "=" + STRING(parentId) + " " + ordering) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_QUERY: consulta de filhos invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF bh[hIndex]:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: falha ao bloquear conjunto de filhos.",1).
  DO WHILE NOT q:QUERY-OFF-END:
   IF bh[hIndex]:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: filho em uso.",1).
   IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_QUERY: falha ao bloquear filho.",1).
   before=Snapshot(bh[hIndex]).
   IF hIndex>=21 THEN before:Add("container_id",masterId).
   event=NEW JsonObject(). event:Add("resource",resource). event:Add("operation","delete").
   IF idField<>"" THEN DO:
    idValue=bh[hIndex]:BUFFER-FIELD(idField):BUFFER-VALUE.
    IF idValue=? OR idValue<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_SCHEMA: PK de filho invalida.",1).
    event:Add("recordId",idValue).
   END.
   ELSE DO:
    key=NEW JsonObject(). keyArray=NEW JsonArray().
    DO n=1 TO NUM-ENTRIES(compositeFields):
     f=REPLACE(ENTRY(n,compositeFields),"-","_").
     CASE before:GetType(f):
      WHEN JsonDataType:STRING THEN DO: key:Add(f,before:GetCharacter(f)). keyArray:Add(before:GetCharacter(f)). END.
      WHEN JsonDataType:NUMBER THEN DO: key:Add(f,before:GetInteger(f)). keyArray:Add(before:GetInteger(f)). END.
      OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_SCHEMA: chave composta desconhecida.",1).
     END CASE.
    END.
    event:Add("recordId",IF hIndex>=21 THEN STRING(keyArray:GetJsonText()) ELSE STRING(key:GetJsonText())).
    DELETE OBJECT key. DELETE OBJECT keyArray.
   END.
   event:Add("before",before). event:Add("after",NEW JsonObject()). aChanges:Add(event).
   deleteOrdinal=deleteOrdinal + 1. CREATE ttDelete. ASSIGN ttDelete.ordinal=deleteOrdinal ttDelete.hIndex=hIndex ttDelete.recordRow=bh[hIndex]:ROWID.
   q:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
   IF bh[hIndex]:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: falha ao percorrer conjunto de filhos.",1).
  END.
  FINALLY:
   IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
  END FINALLY.
 END.
END PROCEDURE.
PROCEDURE NextCalculoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN NextCalculoId IN phRuntime(OUTPUT valueId).
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN NextDespesaId IN phRuntime(OUTPUT valueId).
END PROCEDURE.
PROCEDURE ValidateDistributionExpense:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER expense AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER proof AS JsonObject NO-UNDO.
 IF NOT VALID-HANDLE(phRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: prova fisica de distribuicao indisponivel.",1).
 IF LOOKUP("ValidateDistributionExpense",phRuntime:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: callback de prova fisica ausente.",1).
 RUN ValidateDistributionExpense IN phRuntime(master,expense,OUTPUT proof).
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(phRuntime) THEN DO:
  IF LOOKUP("LogRule",phRuntime:INTERNAL-ENTRIES)>0 THEN RUN LogRule IN phRuntime(levelName,messageText).
 END.
END PROCEDURE.

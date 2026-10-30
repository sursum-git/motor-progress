/* Real VersionRuntime + writer + distribution + cost pipeline. TT only. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 34 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 34 NO-UNDO.
DEFINE VARIABLE collectors AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE sources AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE targets AS HANDLE EXTENT 5 NO-UNDO.
DEFINE VARIABLE runtimeValue AS HANDLE NO-UNDO.
DEFINE VARIABLE oReq AS JsonObject NO-UNDO.
DEFINE VARIABLE oFin AS JsonObject NO-UNDO.
DEFINE VARIABLE oPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER EXTENT 8 NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE fiscalCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE contextCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE versionSequence AS INTEGER NO-UNDO.
DEFINE VARIABLE itemSequence AS INTEGER NO-UNDO.
DEFINE VARIABLE ledgerSequence AS INTEGER NO-UNDO.
DEFINE VARIABLE expenseSequence AS INTEGER NO-UNDO.
DEFINE VARIABLE thirdBlocked AS LOGICAL NO-UNDO.
DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO.
FUNCTION CountRows RETURNS INTEGER(n AS INTEGER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE countValue AS INTEGER NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(hb[n]). q:QUERY-PREPARE("FOR EACH " + hb[n]:NAME + " NO-LOCK"). q:QUERY-OPEN(). q:GET-FIRST().
 DO WHILE NOT q:QUERY-OFF-END: countValue=countValue + 1. q:GET-NEXT(). END. DELETE OBJECT q. RETURN countValue.
END FUNCTION.
&IF DEFINED(VERSION_COMPOSITION_MISSING_ACTUAL) > 0 &THEN
RUN Setup.
RUN Seed(2,'~{"item_container_id":2,"container_id":123,"item_proc_compra_id":2,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":0}').
RUN Seed(3,'~{"item_proc_compra_id":2,"proc_compra_id":1,"descricao":"TT absent ERP","codigo_erp":"ERP2","vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":120,"ind_distr_custo":1}').
RUN Invoke.
RUN Check(resultValue:GetLogical("success"),"missing actual remains null across both composition snapshots").
RUN Check(CountRows(15)=2,"missing actual does not fabricate zero or lose second snapshot").
&ELSE
RUN Setup.
RUN Invoke.
RUN Check(resultValue:GetLogical("success"),"root real composition commits").
RUN Check(CountRows(15)=2 AND CountRows(14)=2,"exactly two physical version snapshots").
RUN Check(fiscalCalls=2 AND versionSequence=1002,"same writer and fiscal callback used twice, never third").
RUN Check(CountRows(9)=1 AND CountRows(8)=3,"only first pass applies ledger and managed expense").
hb[14]:FIND-FIRST("WHERE " + hb[14]:NAME + ".versao_id=1001").
RUN Check(hb[14]:BUFFER-FIELD("vl_custo_distribuido"):BUFFER-VALUE=30,"first physical snapshot records central distribution").
hb[14]:FIND-FIRST("WHERE " + hb[14]:NAME + ".versao_id=1002").
RUN Check(hb[14]:BUFFER-FIELD("vl_custo_distribuido"):BUFFER-VALUE=0,"second version_check does not apply a second distribution").
RUN Check(resultValue:GetJsonObject("distribution"):GetJsonObject("followup"):GetLogical("committed")=FALSE,"inner writer never confirms commit").
RUN Check(NOT resultValue:GetJsonObject("distribution"):GetJsonObject("followup"):Has("audit"),"inner writer has only pending audit effects").
RUN Check(resultValue:GetJsonObject("audit"):GetJsonArray("changes"):Length>=4,"root audit aggregates physical distribution and followup").
RUN Check(resultValue:GetJsonObject("data"):GetInteger("versao_id")=1001,"outer data remains its own row after recursive buffer movement").
DO TRANSACTION:
 hb[1]:FIND-FIRST("WHERE " + hb[1]:NAME + ".nr-container=123",EXCLUSIVE-LOCK).
 oReq=NEW JsonObject(). oReq:Add("expected_latest_version_id",1002). oReq:Add("reason","outside-driver").
 RUN GenerateFollowupVersion IN runtimeValue(hb[1],oReq,OUTPUT oFin) NO-ERROR.
 RUN Check(ERROR-STATUS:ERROR AND versionSequence=1002,"followup cannot be invoked outside its active driver").
END.

RUN Setup. modeValue="unstable". RUN Invoke.
RUN Check(NOT resultValue:GetLogical("success"),"persistible delta in second pass rejects composition").
RUN Check(INDEX(STRING(resultValue:GetJsonText()),"UNSTABLE_DISTRIBUTION")>0,"instability has explicit diagnosis").
RUN Check(CountRows(15)=0 AND CountRows(14)=0 AND CountRows(9)=0 AND CountRows(8)=2,"second-pass failure undoes both versions, children, ledger and expense").
DO i=31 TO 34: RUN Check(CountRows(i)=0,"failure removes physical child kind " + STRING(i)). END.
hb[8]:FIND-FIRST("WHERE " + hb[8]:NAME + ".despesa_container_id=1"). RUN Check(hb[8]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=130,"second fiscal mutation is undone with distribution").
hb[1]:FIND-FIRST(). RUN Check(hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original" AND hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE,"rollback restores master and fiscal effect").
RUN Check(versionSequence=1002 AND fiscalCalls=2,"instability stops at two attempted snapshots").
RUN Check(NOT resultValue:Has("audit"),"failed root exposes no confirmed audit").
modeValue="". fiscalCalls=0. RUN Invoke.
RUN Check(resultValue:GetLogical("success") AND CountRows(15)=2 AND versionSequence=1004,"same Runtime recovers its private depth/active state after failed composition").

RUN Setup. hb[29]:FIND-FIRST(). hb[29]:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE=FALSE. hb[29]:BUFFER-RELEASE().
RUN Invoke.
RUN Check(resultValue:GetLogical("success") AND CountRows(15)=1 AND CountRows(9)=0,"combined status flag skips distribution before pool capture").
RUN Check(versionSequence=1001 AND fiscalCalls=1,"disabled status does not generate followup").

RUN Setup. policyValue:Set("enable_distribution",FALSE). RUN Invoke.
RUN Check(NOT resultValue:GetLogical("success") AND CountRows(15)=0 AND ledgerSequence=3000,"disabled private optin prevents distribution and all writes").
RUN Setup.
RUN Seed(2,'~{"item_container_id":2,"container_id":123,"item_proc_compra_id":2,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":0}').
RUN Seed(2,'~{"item_container_id":3,"container_id":123,"item_proc_compra_id":3,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":0}').
RUN Seed(3,'~{"item_proc_compra_id":2,"proc_compra_id":1,"descricao":"TT2","codigo_erp":"ERP2","vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":120,"ind_distr_custo":1}').
RUN Seed(3,'~{"item_proc_compra_id":3,"proc_compra_id":1,"descricao":"TT3","codigo_erp":"ERP3","vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":120,"ind_distr_custo":1}').
RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","it-codigo":"ERP2","sequencia":2,"quantidade":10,"preco-total":1000,"despesas":100,"val-cofins":40,"val-aliq-cofins":4,"valor-pis":20,"val-aliq-pis":2}').
RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","it-codigo":"ERP3","sequencia":3,"quantidade":10,"preco-total":1000,"despesas":100,"val-cofins":40,"val-aliq-cofins":4,"valor-pis":20,"val-aliq-pis":2}').
hb[8]:FIND-FIRST("WHERE " + hb[8]:NAME + ".despesa_container_id=1"). hb[8]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=110.01. hb[8]:BUFFER-RELEASE().
RUN Invoke.
RUN Check(resultValue:GetLogical("success") AND CountRows(15)=2 AND CountRows(14)=6,"subcent residual stabilizes three items within two snapshots").
RUN Check(CountRows(9)=3 AND versionSequence=1002,"residual does not emit a second ledger or third version").
hb[14]:FIND-FIRST("WHERE " + hb[14]:NAME + ".versao_id=1001"). RUN Check(hb[14]:BUFFER-FIELD("vl_custo_distribuido"):BUFFER-VALUE=3.34,"central persisted scale drives first snapshots").

RUN Setup. modeValue="limit". RUN Invoke.
RUN Check(resultValue:GetLogical("success") AND thirdBlocked,"reentrant attempt to generate third version is refused").
RUN Check(versionSequence=1002 AND CountRows(15)=2,"limit is enforced before a third sequence callback").

RUN Setup. modeValue="nested". policyValue:Add("allow_nested",TRUE).
ancestor: DO TRANSACTION:
 RUN Invoke.
 RUN Check(resultValue:GetLogical("success") AND NOT resultValue:GetLogical("committed") AND NOT resultValue:Has("audit"),"ambient owner receives pending changes only").
 RUN Check(CountRows(15)=2 AND resultValue:GetJsonArray("pendingChanges"):Length>=5,"both versions pending inside ancestor").
 UNDO ancestor,LEAVE ancestor.
END.
RUN Check(CountRows(15)=0 AND CountRows(14)=0 AND CountRows(9)=0 AND CountRows(8)=2,"ancestor rollback undoes successful full composition").
&ENDIF
OUTPUT TO VALUE("containers-version-composition-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks; all real helpers, undoable TT, private sequences." SKIP. OUTPUT CLOSE.
IF VALID-HANDLE(runtimeValue) THEN DELETE PROCEDURE runtimeValue.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 checks=checks + 1.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + (IF VALID-OBJECT(resultValue) AND resultValue:Has("error") THEN " error=" + resultValue:GetJsonObject("error"):GetCharacter("message") ELSE ""),1).
END PROCEDURE.

PROCEDURE Invoke:
 RUN ContainersVersionService.p(hb[1],hb[30],hb[15],hb[14],hb[31],hb[32],hb[33],hb[34],runtimeValue,policyValue,oReq,OUTPUT resultValue).
END PROCEDURE.
PROCEDURE GetVersionContext:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE financeValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE distributionValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE species AS JsonArray NO-UNDO.
 contextCalls=contextCalls + 1.
 contextValue=NEW JsonObject(). contextValue:Add("confirmed",TRUE). contextValue:Add("container_id",INTEGER(master:BUFFER-FIELD("nr-container"):BUFFER-VALUE)).
 contextValue:Add("cost_policy",CAST(oPolicy:Clone(),JsonObject)). financeValue=NEW JsonObject().
 species=NEW JsonArray(). species:Add("AF"). financeValue:Add("adiantamentos",species). species=NEW JsonArray(). species:Add("DI"). financeValue:Add("titulos",species). contextValue:Add("finance_policy",financeValue).
 distributionValue=NEW JsonObject(). distributionValue:Add("gerar_distr_custo",TRUE). distributionValue:Add("despesa_distr_custo",99). contextValue:Add("distribution_policy",distributionValue).
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE followupContext AS JsonObject NO-UNDO.
 DEFINE VARIABLE forbiddenResult AS JsonObject NO-UNDO.
 IF NOT TRANSACTION OR contextValue:GetInteger("container_id")<>123 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid fiscal context",1).
 fiscalCalls=fiscalCalls + 1. master:BUFFER-FIELD("narrativa"):BUFFER-VALUE="fiscal".
 IF fiscalCalls=2 AND modeValue="unstable" THEN DO: hb[8]:FIND-FIRST("WHERE " + hb[8]:NAME + ".despesa_container_id=1",EXCLUSIVE-LOCK). hb[8]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=140. END.
 IF fiscalCalls=2 AND modeValue="limit" THEN DO:
  followupContext=NEW JsonObject(). followupContext:Add("expected_latest_version_id",1001). followupContext:Add("reason","forbidden-third").
  RUN GenerateFollowupVersion IN runtimeValue(master,followupContext,OUTPUT forbiddenResult) NO-ERROR. thirdBlocked=ERROR-STATUS:ERROR.
 END.
 responseValue=NEW JsonObject(). responseValue:Add("success",TRUE). responseValue:Add("changes",NEW JsonArray()). responseValue:Add("warnings",NEW JsonArray()).
END PROCEDURE.
PROCEDURE NextVersionId: DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO. versionSequence=versionSequence + 1. valueId=versionSequence. END PROCEDURE.
PROCEDURE NextVersionItemId: DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO. itemSequence=itemSequence + 1. valueId=itemSequence. END PROCEDURE.
PROCEDURE NextDistribuicaoId: DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO. ledgerSequence=ledgerSequence + 1. valueId=ledgerSequence. END PROCEDURE.
PROCEDURE NextDespesaId: DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO. expenseSequence=expenseSequence + 1. valueId=expenseSequence. END PROCEDURE.
{ContainersVersionRuntimeFixture.i}
{ContainersVersionCompositionFixture.i}



/* Real undoable fixtures only. No business records. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE seq AS INTEGER NO-UNDO INITIAL 1000.
DEFINE VARIABLE quoteCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failQuotes AS LOGICAL NO-UNDO.
DEFINE VARIABLE logCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failLog AS LOGICAL NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE createdId AS INTEGER NO-UNDO.
FUNCTION CountRows RETURNS INTEGER (hIndex AS INTEGER) FORWARD.
RUN Fixture.
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100,"log_manual":true}}').
RUN Invoke.
RUN Check(result:GetLogical("success"),"individual create succeeds with real fiscal integration").
createdId=result:GetJsonObject("data"):GetInteger("despesa_container_id").
RUN Check(createdId=1001,"expense ID allocated by trusted fixed sequence callback").
RUN Check(result:GetJsonObject("data"):GetLogical("log_manual"),"manual flag typed boolean").
RUN Check(result:GetJsonObject("audit"):GetInteger("recordId")=1001,"individual audit recordId is expense PK").
RUN Check(result:GetJsonObject("audit"):GetJsonObject("after"):GetInteger("despesa_container_id")=1001,"individual audit has actual target snapshot").
RUN Check(NOT result:GetJsonObject("audit"):GetJsonObject("actor"):Has("extra"),"only normalized actor fields reach audit").
RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length>=3,"direct and fiscal snapshots committed together").
hb[11]:FIND-FIRST("WHERE fx11.despesa_id=40",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=10,"individual create updates calculated expense after taxes").
RUN Check(quoteCalls=1,"quotes collected under master transaction").
RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_EXISTS").
RUN Request('~{"operation":"update","container_id":123,"id":1001,"despesa_container_id":1001,"values":~{"vl_prev":200}}').
RUN Invoke. RUN Check(result:GetLogical("success"),"individual update with matching alias").
hb[11]:FIND-FIRST("WHERE fx11.despesa_id=40",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=20,"individual update invokes calculated expenses").
RUN Request('~{"operation":"batch_update","container_id":123,"rows":[~{"id":1001,"values":~{"vl_prev":300}}]}').
RUN Invoke. RUN Check(result:GetLogical("success"),"batch update succeeds").
hb[11]:FIND-FIRST("WHERE fx11.despesa_id=40",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=20,"batch update does not run calculated expenses").
RUN Request('~{"operation":"batch_update","container_id":123,"rows":[~{"id":1001,"values":~{"vl_prev":400}},~{"id":999,"values":~{"vl_prev":999}}]}').
RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_NOT_FOUND").
hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=1001",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=300,"batch missing row leaves all prior rows unchanged").
failQuotes=TRUE.
RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"vl_prev":555}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_RULE_FAILED").
hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=1001",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=300,"quote failure rolls back direct expense write"). failQuotes=FALSE.
RUN Request('~{"operation":"batch_delete","container_id":123,"rows":[~{"id":1001}]}').
i=quoteCalls. RUN Invoke. RUN Check(result:GetLogical("success"),"batch delete succeeds").
RUN Check(quoteCalls=i,"batch delete does not call fiscal or collector").
RUN Check(result:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"batch delete marks stale").
RUN Request('~{"operation":"get","container_id":123,"id":1001}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_NOT_FOUND").
hb[11]:FIND-FIRST("WHERE fx11.despesa_id=10",NO-LOCK). i=hb[11]:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE.
req=NEW JsonObject(). req:Add("operation","delete"). req:Add("container_id",123). req:Add("id",i). RUN Invoke.
RUN Check(result:GetLogical("success") AND result:IsNull("data"),"individual tax deletion returns no invented old-PK row").
RUN Check(result:GetJsonObject("audit"):GetInteger("recordId")=i,"recreated tax audit still targets deleted expense ID").
hb[11]:FIND-FIRST("WHERE fx11.despesa_id=10",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE<>i,"tax deletion may recreate expense under a fresh sequence ID").

RUN Fixture.
RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"log_manual":true,"perc_calc":99}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"batch_update","container_id":123,"rows":[~{"id":40,"values":~{"despesa_id":1}}]}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"batch_update","container_id":123,"rows":[~{"id":40,"values":~{"vl_prev":1}},~{"id":40,"values":~{"vl_prev":2}}]}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_prev":"1,25"}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"log_manual":"true"}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"update","container_id":124,"id":40,"values":~{"vl_base_imp":1}}'). RUN Invoke. RUN ErrorCode("CONTAINER_NOT_FOUND").
RUN Request('~{"operation":"delete","container_id":123,"id":99}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_PROTECTED").
RUN Request('~{"operation":"update","container_id":123,"id":40,"despesa_container_id":41,"values":~{"vl_base_imp":1}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":777,"vl_prev":1}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_COMPANY").
RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"container_id":124}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"batch_insert","container_id":123,"rows":[]}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Fixture.
hb[11]:FIND-FIRST("WHERE fx11.despesa_id=40",NO-LOCK). hb[11]:BUFFER-FIELD("perc_calc"):BUFFER-VALUE=0.
RUN Request('~{"operation":"batch_update","container_id":123,"rows":[~{"id":40,"values":~{"vl_base_imp":1}}]}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Fixture.
hb[6]:FIND-FIRST("WHERE fx6.despesa_id=40",NO-LOCK). hb[6]:BUFFER-FIELD("perc_calculo"):BUFFER-VALUE=?.
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":555}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_RULE_FAILED").
RUN Check(CountRows(10)=0 AND CountRows(11)=2,"second fiscal failure undoes direct insert plus calculation and tax insert").
RUN Fixture. failLog=TRUE.
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100.125}}'). RUN Invoke.
RUN Check(result:GetLogical("success"),"log queue failure cannot reverse committed business result").
RUN Check(result:GetJsonObject("data"):GetDecimal("vl_prev")=100.13,"currency rounds to dictionary2decimals in both cultures").
RUN Check(logCalls=1,"only confirmed root invokes log queue").
RUN Fixture.
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100}}'). RUN Invoke.
failQuotes=TRUE.
RUN Request('~{"operation":"batch_update","container_id":123,"rows":[~{"id":1001,"values":~{"vl_prev":600}},~{"id":40,"values":~{"vl_prev":700,"vl_base_imp":2}}]}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_RULE_FAILED").
hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=1001",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=100,"post-write batch failure restores first row").
hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=40",NO-LOCK).
RUN Check(hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=10 AND hb[11]:BUFFER-FIELD("vl_base_imp"):BUFFER-VALUE=0,"post-write batch failure restores second row and its base").
RUN Fixture.
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100}}'). RUN Invoke.
hb[1]:FIND-FIRST("WHERE fx1.nr-container=123",NO-LOCK). hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=FALSE. hb[1]:BUFFER-FIELD("dt_hr_ult_alt_versao_custo"):BUFFER-VALUE=?.
RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"vl_prev":100}}'). RUN Invoke.
RUN Check(result:GetLogical("success") AND NOT result:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"unchanged watched fields preserve current version flag").
RUN Check(result:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):IsNull("dt_hr_ult_alt_versao_custo"),"unchanged expense does not stamp invalidation timestamp").
RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"vl_base_imp":1}}'). RUN Invoke.
RUN Check(result:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"changed watched expense field marks stale").
RUN Check(NOT result:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):IsNull("dt_hr_ult_alt_versao_custo"),"changed watched field stamps datetime").
RUN Request('~{"operation":"get","container_id":123,"despesa_container_id":"1001"}'). RUN Invoke.
RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetInteger("despesa_container_id")=1001,"get accepts exact expense alias and string integer").
RUN Seed(11,'~{"despesa_container_id":500,"container_id":124,"despesa_id":1,"item_container_id":0}').
RUN Request('~{"operation":"delete","container_id":123,"id":500}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_NOT_FOUND").
RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"VL_PREV":1}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
DO TRANSACTION:
 RUN Request('~{"operation":"delete","container_id":123,"id":40}'). RUN Invoke. RUN ErrorCode("CONTAINER_TRANSACTION_CONTEXT").
END.
RUN Fixture. policy:Set("despesa_distr_custo",99.5).
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_CONFIGURATION").
RUN Check(INDEX(result:GetJsonObject("error"):GetCharacter("message"),"Parametro IMA invalido")>0,"fractional private parameter explicitly rejected before cast").
RUN Fixture.
RUN Seed(11,'~{"despesa_container_id":601,"container_id":123,"despesa_id":99,"item_container_id":1,"vl_prev":20,"cta_corren_custo_distr_id":5001,"log_manual":true}').
RUN Seed(11,'~{"despesa_container_id":602,"container_id":123,"despesa_id":99,"item_container_id":1,"vl_prev":-5,"cta_corren_custo_distr_id":5002,"log_manual":true}').
RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100}}'). RUN Invoke.
RUN Check(result:GetLogical("success"),"private managed-distribution ID reaches central fiscal composition").
RUN Check(hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=601",NO-LOCK) AND hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=20,"first historical managed movement retained").
RUN Check(hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=602",NO-LOCK) AND hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE= -5,"second managed movement retained without upsert").
RUN DerivedEchoTests.
DO i=1 TO 11: DELETE OBJECT ht[i]. END.
DELETE OBJECT parser.
OUTPUT TO VALUE("containers-despesas-crud-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP. OUTPUT CLOSE.

FUNCTION CountRows RETURNS INTEGER (hIndex AS INTEGER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE count AS INTEGER NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(hb[hIndex]). q:QUERY-PREPARE("FOR EACH " + hb[hIndex]:NAME + " NO-LOCK"). q:QUERY-OPEN(). q:GET-FIRST().
 DO WHILE NOT q:QUERY-OFF-END: count=count + 1. q:GET-NEXT(). END.
 q:QUERY-CLOSE(). DELETE OBJECT q. RETURN count.
END FUNCTION.
PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 checks=checks + 1. IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + c + " result=" + STRING(result:GetJsonText()),1).
END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 RUN Check(NOT result:GetLogical("success"),"failure " + code).
 RUN Check(result:GetJsonObject("error"):GetCharacter("code")=code,"error code " + code).
 RUN Check(result:GetJsonObject("error"):GetInteger("status")=(IF code="CONTAINER_NOT_FOUND" OR code="CONTAINER_EXPENSE_NOT_FOUND" THEN 404 ELSE IF code="CONTAINER_TRANSACTION_CONTEXT" THEN 409 ELSE IF code="CONTAINER_EXPENSE_CONFIGURATION" THEN 500 ELSE 422),"structured status " + code).
 RUN Check(NOT result:Has("audit"),"no confirmed audit on failure").
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER lc AS LONGCHAR NO-UNDO.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 req=CAST(parser:Parse(lc),JsonObject).
END PROCEDURE.
PROCEDURE AutomaticFixture:
 RUN Fixture.
 RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":1,"vl_prev":100}}'). RUN Invoke.
 IF NOT result:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Automatic fixture could not use central calculated expense",1).
END PROCEDURE.
PROCEDURE DerivedEchoTests:
 DEFINE VARIABLE sequenceBefore AS INTEGER NO-UNDO.
 /* Renderer submits all six editables, including the readonly derived value. */
 RUN AutomaticFixture.
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"despesa_id":40,"vl_prev":10,"vl_base_imp":0,"vl_negociado":0,"log_manual":false,"perc_calc":10}}'). RUN Invoke.
 RUN Check(result:GetLogical("success"),"unchanged full automatic form accepts exact persisted derived echo").
 RUN Check(result:GetJsonObject("data"):GetDecimal("vl_prev")=10 AND result:GetJsonObject("data"):GetDecimal("perc_calc")=10,"automatic echo is recalculated by central service").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"despesa_id":40,"vl_prev":10,"vl_base_imp":0,"vl_negociado":15,"log_manual":false,"perc_calc":20}}'). RUN Invoke.
 RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetDecimal("vl_prev")=10,"full form accepts editable changes and central policy determines final amount").
 RUN Check(result:GetJsonObject("audit"):GetJsonObject("before"):GetDecimal("vl_prev")=10 AND result:GetJsonObject("audit"):GetJsonObject("after"):GetDecimal("vl_prev")=10,"audit preserves locked old amount and actual central result").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_prev":10.004,"vl_negociado":99}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 RUN Check(hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=40",NO-LOCK) AND hb[11]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=10,"rounded near-echo is rejected and editable mutation does not persist").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_prev":21}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 /* Partial commands keep their existing contract, including explicit zero. */
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_negociado":18}}'). RUN Invoke.
 RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetDecimal("vl_prev")=10,"partial automatic update remains recalculated").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_prev":0}}'). RUN Invoke.
 RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetDecimal("vl_prev")=10,"explicit automatic zero still means recalculate centrally").
 /* Auto to manual: old percent is now readonly and must be ignored unchanged. */
 RUN AutomaticFixture.
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"despesa_id":40,"vl_prev":15,"vl_base_imp":0,"vl_negociado":0,"log_manual":true,"perc_calc":10}}'). RUN Invoke.
 RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetLogical("log_manual"),"auto to manual accepts full form with persisted percent echo").
 RUN Check(result:GetJsonObject("data"):GetDecimal("perc_calc")=0 AND result:GetJsonObject("data"):GetDecimal("vl_prev")=15,"manual transition ignores percent echo and keeps new editable amount").
 /* Manual to auto: old amount is now readonly; default percent is central. */
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"despesa_id":40,"vl_prev":15,"vl_base_imp":0,"vl_negociado":0,"log_manual":false,"perc_calc":0}}'). RUN Invoke.
 RUN Check(result:GetLogical("success") AND NOT result:GetJsonObject("data"):GetLogical("log_manual"),"manual to auto accepts full form with persisted amount echo").
 RUN Check(result:GetJsonObject("data"):GetDecimal("vl_prev")=10 AND result:GetJsonObject("data"):GetDecimal("perc_calc")=10,"automatic transition recalculates amount and uses definition default").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_prev":15,"log_manual":true,"perc_calc":11}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"vl_prev":11,"log_manual":false,"perc_calc":10}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 /* Existing manual rows can contain historical percent: exact echo only. */
 hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=40",NO-LOCK). hb[11]:BUFFER-FIELD("log_manual"):BUFFER-VALUE=TRUE. hb[11]:BUFFER-FIELD("perc_calc"):BUFFER-VALUE=7. hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=12. hb[11]:BUFFER-RELEASE().
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"despesa_id":40,"vl_prev":12,"vl_base_imp":0,"vl_negociado":0,"log_manual":true,"perc_calc":7}}'). RUN Invoke.
 RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetDecimal("perc_calc")=0,"exact legacy manual percent echo is ignored before normalization").
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"perc_calc":0.004}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 /* No create bypass, no readonly-manual bypass, no mutation on failed fiscal. */
 RUN Fixture. sequenceBefore=seq.
 RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":40,"vl_prev":10,"log_manual":false,"perc_calc":10}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 RUN Check(seq=sequenceBefore,"automatic create nonzero never consumes a sequence").
 RUN Request('~{"operation":"create","container_id":123,"values":~{"despesa_id":40,"vl_prev":0,"log_manual":true,"perc_calc":7}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 RUN Request('~{"operation":"update","container_id":123,"id":99,"values":~{"log_manual":false}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_PROTECTED").
 RUN AutomaticFixture.
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"despesa_id":1,"vl_prev":100,"vl_base_imp":0,"vl_negociado":0,"log_manual":false,"perc_calc":0}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_VALIDATION").
 failQuotes=TRUE.
 RUN Request('~{"operation":"update","container_id":123,"id":40,"values":~{"despesa_id":40,"vl_prev":10,"vl_base_imp":0,"vl_negociado":30,"log_manual":false,"perc_calc":20}}'). RUN Invoke. RUN ErrorCode("CONTAINER_EXPENSE_RULE_FAILED").
 RUN Check(hb[11]:FIND-FIRST("WHERE fx11.despesa_container_id=40",NO-LOCK) AND hb[11]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=10 AND hb[11]:BUFFER-FIELD("perc_calc"):BUFFER-VALUE=10 AND hb[11]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=10,"accepted echo and editable changes roll back together when fiscal fails").
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersDespesasCrudService.p(hb[1],hb[2],hb[3],hb[4],hb[5],hb[6],hb[7],hb[8],hb[9],hb[10],hb[11],THIS-PROCEDURE,policy,req,OUTPUT result).
END PROCEDURE.
PROCEDURE TableDef:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER cFields AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(ht[n]) THEN DELETE OBJECT ht[n].
 CREATE TEMP-TABLE ht[n]. ht[n]:UNDO=TRUE.
 DO j=1 TO NUM-ENTRIES(cFields): f=ENTRY(j,cFields). ht[n]:ADD-NEW-FIELD(ENTRY(1,f,":"),ENTRY(2,f,":"),INTEGER(ENTRY(3,f,":"))). END.
 ht[n]:TEMP-TABLE-PREPARE("fx" + STRING(n)). hb[n]=ht[n]:DEFAULT-BUFFER-HANDLE.
END PROCEDURE.
PROCEDURE Seed:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER lc AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 o=CAST(parser:Parse(lc),JsonObject). names=o:GetNames(). hb[n]:BUFFER-CREATE().
 DO j=1 TO EXTENT(names):
  f=hb[n]:BUFFER-FIELD(names[j]).
  CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN f:BUFFER-VALUE=o:GetCharacter(names[j]).
   WHEN "INTEGER" THEN f:BUFFER-VALUE=o:GetInteger(names[j]).
   WHEN "DECIMAL" THEN f:BUFFER-VALUE=o:GetDecimal(names[j]).
   WHEN "LOGICAL" THEN f:BUFFER-VALUE=o:GetLogical(names[j]).
  END CASE.
 END.
 DELETE OBJECT o.
END PROCEDURE.
PROCEDURE CollectCalculationInputs:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE VARIABLE snap AS JsonObject NO-UNDO. DEFINE VARIABLE f AS CHARACTER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL NO-UNDO. DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("quotes require master transaction",1).
 quoteCalls=quoteCalls + 1. IF failQuotes THEN UNDO, THROW NEW Progress.Lang.AppError("quotes unavailable",1).
 snap=NEW JsonObject().
 DO j=1 TO 6:
  f=ENTRY(j,"vl-dolar-compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar").
  IF master:BUFFER-FIELD(f):DATA-TYPE="CHARACTER" THEN DO: c=master:BUFFER-FIELD(f):BUFFER-VALUE. snap:Add(f,c). END.
  ELSE DO: d=master:BUFFER-FIELD(f):BUFFER-VALUE. snap:Add(f,d). END.
 END.
 o=NEW JsonObject(). o:Add("confirmed",TRUE). o:Add("source","container-cost-collector"). o:Add("container_id",123).
 o:Add("dolar_di",5). o:Add("dolar_compra",5). o:Add("container_snapshot",snap).
END PROCEDURE.
PROCEDURE NextCalculoId:
 DEFINE OUTPUT PARAMETER n AS INTEGER NO-UNDO. seq=seq + 1. n=seq.
END PROCEDURE.
PROCEDURE ValidateDistributionExpense:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER expense AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER proof AS JsonObject NO-UNDO.
 proof=NEW JsonObject(). proof:Add("confirmed",TRUE). proof:Add("container_id",INTEGER(master:BUFFER-FIELD("nr-container"):BUFFER-VALUE)).
 proof:Add("despesa_container_id",INTEGER(expense:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE)). proof:Add("ledger_id",INTEGER(expense:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE)).
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER n AS INTEGER NO-UNDO. seq=seq + 1. n=seq.
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("root log must be queued after commit",1).
 logCalls=logCalls + 1. IF failLog THEN UNDO, THROW NEW Progress.Lang.AppError("test queue unavailable",1).
END PROCEDURE.
PROCEDURE Fixture:
 RUN TableDef(1,"cod-estabel:character:0,nr-container:integer:0,num-pedido:integer:0,nome-ab-forn:character:0,cod-emit-forn:integer:0,comprador:character:0,narrativa:character:0,usuario:character:0,dt-compra:date:0,dt-prev-chegada:date:0,dt-recebimento:date:0,situacao:integer:0,char-1:character:0,dec-1:decimal:0,int-1:integer:0,log-1:logical:0,data-1:date:0,vlr-frete:decimal:0,vlr-seguro:decimal:0,vlr-despesas:decimal:0,exclusivo:logical:0,vl-dolar-venda:decimal:0,vl-dolar-compra:decimal:0,log_liberar_custo_realizado:logical:0,medidas_container:character:0,dt_prev_embarque:date:0,dt_real_embarque:date:0,ind_dt_embarque:integer:0,situacao_container_id:integer:0,ind_dt_prev_chegada:integer:0,log_pagto_final:logical:0,cod_agente_cargas:integer:0,cod_armador:integer:0,cod_tipo_calculo:integer:0,perc_custo:decimal:0,vl_dolar_di:decimal:0,log_gerar_saldo_a_pagar:logical:0,log_gerar_distr_custo:logical:0,ordem_busca_dolar_compra:character:0,ordem_busca_dolar_di:character:0,cod_tipo_proj_dolar:integer:0,vl_proj_dolar:decimal:0,log_versao_custo_desatualizada:logical:0,dt_hr_ult_alt_versao_custo:datetime:0,ptax:decimal:0,cod-depos:character:0,dt_prev_chegada_loja:date:0,estacao:integer:0,num_origem:integer:0,log_rota_indefinida:logical:0").
 RUN TableDef(2,"empresa_id:integer:0,nome:character:0,cod_emp_ems2:integer:0,cod_emp_ems5:integer:0").
 RUN TableDef(3,"item_container_id:integer:0,container_id:integer:0,item_proc_compra_id:integer:0,qt_alocada:decimal:0,qt_confirm_emb:decimal:0,qt_recbto_fisico:decimal:0,log_rec_doc_prazo_emb:logical:0,observacao:character:0,cod_tipo_calculo:integer:0,perc_custo:decimal:0,log_calc_icms:logical:0,log_calc_ipi:logical:0,perc_icms:decimal:0,perc_ipi:decimal:0,preco_liquida_ima:decimal:0").
 RUN TableDef(4,"item_proc_compra_id:integer:0,descricao:character:0,codigo_erp:character:0,qt_dias_producao:integer:0,vl_base_tributacao:decimal:0,unid_medida:character:0,proc_compra_id:integer:0,qt_comprada:decimal:0,vl_custo_dolar:decimal:0,composicao:character:0,peso:character:0,largura:character:0,rolo:character:0,dt_prev_envio_desenhos:date:0,dt_real_envio_desenhos:date:0,log_aprov_so_ld:logical:0,dt_prev_recbto_so_ld:date:0,dt_prev_aprov_so_ld:date:0,dt_real_aprov_so_ld:date:0,coloracao_id:integer:0,dt_maxima_producao:date:0,dt_mostruario:date:0,log_mostruario:logical:0,formato_amostra_id:integer:0,ind_producao_no_prazo:integer:0,ind_relat_semanal_producao:integer:0,ind_qualid_emb:integer:0,ind_laudo_antes_embarque:integer:0,ind_prod_conf_pi:integer:0,ind_rec_amostra_antes_emb:integer:0,ind_qt_conf_proforma:integer:0,ind_tamanho_pecas_correto:integer:0,observacao:character:0,dt_cheg_amostras_emb:date:0,dt_termino_producao:date:0,vl_cubagem:decimal:0,dt_recbto_laudo:date:0,dt_recbto_embalagem:date:0,dt_real_recbto_so_ld:date:0,dt_prev_termino_producao:date:0,qt_dias_calc_so_ld:integer:0,shrinkage:character:0,ind_distr_custo:integer:0,vl_negociado:decimal:0,item_estacao:integer:0,dt_item_certificacao:date:0").
 RUN TableDef(5,"proc_compra_id:integer:0,empresa_id:integer:0,qt_container:integer:0,cod_situacao:integer:0,cod_proc_fornec:character:0,qt_dias_translado:integer:0,cotacao_prevista:decimal:0,observacao:character:0,dt_registro:date:0,fornecedor_id:integer:0,dt_limite:date:0,log_facilid_contato_fornec:logical:0,log_considerar_previsao:logical:0,nr_container_original:character:0").
 RUN TableDef(6,"despesa_id:integer:0,descricao:character:0,log_imposto:integer:0,ordem:integer:0,log_calculada:logical:0,perc_calculo:decimal:0,log_vl_prod_base_calculo:logical:0,log_calc_por_item:logical:0,ind_imposto:integer:0").
 RUN TableDef(7,"empresa_despesa_id:integer:0,despesa_id:integer:0,empresa_id:integer:0,codigo_desp_erp:integer:0,vl_padrao:decimal:0,percentual:decimal:0,cod_nat_operacao:character:0,log_ativo:integer:0,perc_custo:integer:0,percentual_custo:decimal:0,despesa_custo_id:integer:0,log_custo:integer:0").
 RUN TableDef(8,"despesa_id:integer:0,imposto_id:integer:0,empresa_id:integer:0").
 RUN TableDef(9,"relac_desp_calculada_id:integer:0,despesa_id:integer:0,despesa_id_base:integer:0").
 RUN TableDef(10,"container_id:integer:0,dt_hr_calculo:datetime:0,usuario_id:integer:0,memoria_calculo:integer:0,calc_imp_container_id:integer:0,desc_memoria_calc:character:0").
 RUN TableDef(11,"despesa_container_id:integer:0,despesa_id:integer:0,vl_prev:decimal:0,container_id:integer:0,calc_imp_container_id:integer:0,vl_base_imp:decimal:0,vl_negociado:decimal:0,vl_proforma:decimal:0,cta_corren_custo_distr_id:integer:0,log_utilizado:logical:0,log_manual:logical:0,perc_calc:decimal:0,memoria_calculo:character:0,item_container_id:integer:0").
 seq=1000. quoteCalls=0. failQuotes=FALSE. logCalls=0. failLog=FALSE.
 policy=NEW JsonObject(). policy:Add("usuario_id",7). result=NEW JsonObject(). result:Add("login","test-actor"). result:Add("extra","must not leak"). policy:Add("actor",result). policy:Add("despesa_distr_custo",99).
 RUN Seed(1,'~{"nr-container":123,"cod-estabel":"501","vl-dolar-compra":5,"vl_dolar_di":5,"ordem_busca_dolar_compra":"2","ordem_busca_dolar_di":"4","cod_tipo_proj_dolar":1,"vl_proj_dolar":0,"log_versao_custo_desatualizada":false}').
 RUN Seed(2,'~{"empresa_id":1,"cod_emp_ems2":5}').
 RUN Seed(3,'~{"item_container_id":1,"container_id":123,"item_proc_compra_id":11,"qt_alocada":10,"qt_confirm_emb":10,"log_calc_ipi":false}').
 RUN Seed(4,'~{"item_proc_compra_id":11,"proc_compra_id":21,"vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":80}').
 RUN Seed(5,'~{"proc_compra_id":21}').
 RUN Seed(6,'~{"despesa_id":1,"log_imposto":0,"log_calculada":false}').
 RUN Seed(6,'~{"despesa_id":10,"ordem":1,"log_imposto":1,"log_calc_por_item":false,"log_calculada":false}').
 RUN Seed(6,'~{"despesa_id":40,"ordem":2,"log_imposto":0,"log_calculada":true,"perc_calculo":10}').
 RUN Seed(6,'~{"despesa_id":99,"log_imposto":0,"log_calculada":false}').
 RUN Seed(7,'~{"empresa_despesa_id":1,"empresa_id":1,"despesa_id":1,"log_ativo":1}').
 RUN Seed(7,'~{"empresa_despesa_id":10,"empresa_id":1,"despesa_id":10,"percentual":10,"despesa_custo_id":0,"log_ativo":1}').
 RUN Seed(7,'~{"empresa_despesa_id":40,"empresa_id":1,"despesa_id":40,"log_ativo":1}').
 RUN Seed(7,'~{"empresa_despesa_id":99,"empresa_id":1,"despesa_id":99,"log_ativo":1}').
 RUN Seed(9,'~{"despesa_id":40,"despesa_id_base":1}').
 RUN Seed(11,'~{"despesa_container_id":40,"container_id":123,"despesa_id":40,"vl_prev":0,"vl_proforma":0,"vl_negociado":0,"log_manual":false,"perc_calc":10,"item_container_id":0,"vl_base_imp":0}').
 RUN Seed(11,'~{"despesa_container_id":99,"container_id":123,"despesa_id":99,"vl_prev":0,"vl_proforma":0,"vl_negociado":0,"log_manual":true,"perc_calc":0,"item_container_id":0,"vl_base_imp":0}').
END PROCEDURE.

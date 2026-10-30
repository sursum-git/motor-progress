/* Actual payment-link transaction core, undoable TT only. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttMaster FIELD nr-container AS INTEGER FIELD cod-estabel AS CHARACTER
 FIELD log_versao_custo_desatualizada AS LOGICAL INITIAL FALSE FIELD dt_hr_ult_alt_versao_custo AS DATETIME INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttLinks FIELD num_id_tit_ap AS INTEGER FIELD container_id AS INTEGER
 FIELD vl_pago_em_dolar AS DECIMAL FIELD vl_pago_em_real AS DECIMAL FIELD vl_aprop_em_dolar AS DECIMAL
 FIELD vl_cotacao_dolar AS DECIMAL FIELD dt_pagto AS DATE INDEX pk IS UNIQUE PRIMARY num_id_tit_ap container_id.
DEFINE TEMP-TABLE ttTitles FIELD num_id_tit_ap AS INTEGER FIELD cod_estab AS CHARACTER INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap.
DEFINE TEMP-TABLE ttEffect FIELD id AS INTEGER FIELD container_id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE savedKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE changesCalled AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
RUN Fixture. RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"new payment association commits").
RUN Check(responseValue:GetLogical("committed") AND NOT TRANSACTION,"root audit follows actual commit").
savedKey=responseValue:GetJsonObject("data"):GetCharacter("pagamento_key").
RUN Check(LENGTH(savedKey)=66,"opaque immutable association key").
RUN Check(CAN-FIND(ttLinks WHERE ttLinks.num_id_tit_ap=7 AND ttLinks.container_id=123),"link persisted").
RUN Check(responseValue:GetJsonObject("audit"):GetCharacter("recordId")=savedKey,"audit uses UI association identity").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("actor"):GetCharacter("login")="payment-tester","authenticated actor retained").
FIND ttMaster WHERE ttMaster.nr-container=123. RUN Check(ttMaster.log_versao_custo_desatualizada,"association invalidates cost version"). RELEASE ttMaster.
RUN Invoke. RUN Check(NOT responseValue:GetLogical("success") AND responseValue:GetJsonObject("error"):GetInteger("status")=409,"duplicate rejected").
RUN Fixture. modeValue="eligibility-denied". RUN Invoke. RUN Check(NOT responseValue:GetLogical("success") AND NOT CAN-FIND(FIRST ttLinks),"ineligible title never linked").
RUN Fixture. modeValue="effect-failure". RUN Invoke. RUN Check(NOT responseValue:GetLogical("success") AND NOT responseValue:Has("audit"),"failed side effect has no committed audit").
RUN Check(NOT CAN-FIND(FIRST ttLinks) AND NOT CAN-FIND(FIRST ttEffect),"side effects and link rolled back together").
FIND FIRST ttMaster. RUN Check(NOT ttMaster.log_versao_custo_desatualizada,"master rolled back too"). RELEASE ttMaster.
RUN Fixture. CREATE ttLinks. ASSIGN ttLinks.num_id_tit_ap=7 ttLinks.container_id=999. RELEASE ttLinks. RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT CAN-FIND(ttLinks WHERE ttLinks.container_id=123),"global existing owner blocks association").
RUN Fixture. CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=7 ttTitles.cod_estab="501". RELEASE ttTitles. RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success"),"globally ambiguous title ID rejected").
RUN Fixture. RUN Invoke. savedKey=responseValue:GetJsonObject("data"):GetCharacter("pagamento_key").
requestValue=NEW JsonObject(). requestValue:Add("operation","delete"). requestValue:Add("container_id",999). requestValue:Add("id",savedKey). RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND CAN-FIND(FIRST ttLinks),"sibling context cannot unlink").
requestValue:Set("container_id",123). RUN Invoke.
RUN Check(responseValue:GetLogical("success") AND NOT CAN-FIND(FIRST ttLinks),"unlink removes only own association").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("before"):GetInteger("num_id_tit_ap")=7 AND STRING(responseValue:GetJsonObject("audit"):GetJsonObject("after"):GetJsonText())="~{~}","unlink preserves before and absent after").
RUN Check(changesCalled=2,"financial participant invoked once per accepted mutation").
RUN Fixture. RUN Invoke. savedKey=responseValue:GetJsonObject("data"):GetCharacter("pagamento_key").
CREATE ttLinks. ASSIGN ttLinks.num_id_tit_ap=6 ttLinks.container_id=123. RELEASE ttLinks.
requestValue=NEW JsonObject(). requestValue:Add("operation","delete"). requestValue:Add("container_id",123). requestValue:Add("id",savedKey). RUN Invoke.
RUN Check(responseValue:GetLogical("success") AND CAN-FIND(ttLinks WHERE ttLinks.num_id_tit_ap=6),"unrelated orphan title does not prevent valid unlink").
RUN Fixture. modeValue="malformed-effect". RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT CAN-FIND(FIRST ttLinks),"malformed provider audit rolls back before commit").
RUN Fixture. requestValue:GetJsonObject("values"):Add("Num_id_tit_ap",8). RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT CAN-FIND(FIRST ttLinks),"case variant of field cannot bypass closed request").
RUN Fixture. RUN Invoke. savedKey=responseValue:GetJsonObject("data"):GetCharacter("pagamento_key").
CREATE ttLinks. ASSIGN ttLinks.num_id_tit_ap=7 ttLinks.container_id=999. RELEASE ttLinks.
requestValue=NEW JsonObject(). requestValue:Add("operation","delete"). requestValue:Add("container_id",123). requestValue:Add("id",savedKey). RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND CAN-FIND(ttLinks WHERE ttLinks.container_id=123) AND CAN-FIND(ttLinks WHERE ttLinks.container_id=999),"multiple global owners block unlink before effects").
RUN Fixture. requestValue:GetJsonObject("values"):Add("vl_pago_em_real",999). RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT CAN-FIND(FIRST ttLinks),"browser cannot set payment money").
RUN Fixture. requestValue:Add("actor","forged"). RUN Invoke. RUN Check(NOT responseValue:GetLogical("success"),"unknown request identity rejected").
RUN Fixture. DO TRANSACTION ON ERROR UNDO, THROW: RUN Invoke. RUN Check(NOT responseValue:GetLogical("success"),"implicit nested root rejected"). END.
RUN Fixture. policyValue:Add("allow_nested",TRUE).
DO TRANSACTION ON ERROR UNDO, THROW: RUN Invoke. RUN Check(responseValue:GetLogical("success") AND NOT responseValue:GetLogical("committed") AND NOT responseValue:Has("audit"),"nested result never claims root commit"). UNDO, LEAVE. END.
RUN Check(NOT CAN-FIND(FIRST ttLinks),"outer rollback undoes composed association").
OUTPUT TO VALUE("containers-pagamentos-crud-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; undoable TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + " " + STRING(responseValue:GetJsonText()),1).
END PROCEDURE.
PROCEDURE Fixture:
 EMPTY TEMP-TABLE ttMaster. EMPTY TEMP-TABLE ttLinks. EMPTY TEMP-TABLE ttTitles. EMPTY TEMP-TABLE ttEffect.
 CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.cod-estabel="505". RELEASE ttMaster.
 CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=7 ttTitles.cod_estab="505". RELEASE ttTitles.
 modeValue="". changesCalled=0. parser=NEW ObjectModelParser().
 requestValue=CAST(parser:Parse('~{"operation":"create","container_id":123,"values":~{"num_id_tit_ap":7}}'),JsonObject).
 policyValue=CAST(parser:Parse('~{"actor":~{"login":"payment-tester"}}'),JsonObject). DELETE OBJECT parser.
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersPagamentosCrudService.p(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttLinks:HANDLE,INPUT BUFFER ttTitles:HANDLE,THIS-PROCEDURE,policyValue,requestValue,OUTPUT responseValue).
END PROCEDURE.
PROCEDURE ValidateTitle:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER titleId AS INTEGER NO-UNDO. DEFINE OUTPUT PARAMETER rowValue AS JsonObject NO-UNDO.
 IF NOT TRANSACTION OR modeValue="eligibility-denied" THEN UNDO, THROW NEW Progress.Lang.AppError("Title is not eligible",1).
 rowValue=NEW JsonObject(). rowValue:Add("num_id_tit_ap",titleId). rowValue:Add("cod_estab","505"). rowValue:Add("container_id",123).
END PROCEDURE.
PROCEDURE ChangePayment:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO. DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO.
 changesCalled=changesCalled + 1.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Participant requires transaction",1).
 /* Disassociation must run while the physical link still exists. */
 IF NOT CAN-FIND(ttLinks WHERE ttLinks.num_id_tit_ap=7 AND ttLinks.container_id=123) THEN UNDO, THROW NEW Progress.Lang.AppError("Expected live link during financial rules",1).
 IF modeValue="effect-failure" THEN DO: CREATE ttEffect. ASSIGN ttEffect.id=1 ttEffect.container_id=123. UNDO, THROW NEW Progress.Lang.AppError("Injected financial failure",1). END.
 resultValue=NEW JsonObject(). resultValue:Add("success",TRUE). resultValue:Add("changes",NEW JsonArray()). resultValue:Add("warnings",NEW JsonArray()).
 IF modeValue="malformed-effect" THEN DO:
  eventValue=NEW JsonObject(). eventValue:Add("resource","itens_container"). eventValue:Add("before",NEW JsonObject()).
  eventValue:Add("after",NEW JsonObject()). eventValue:GetJsonObject("after"):Add("container_id",123). resultValue:GetJsonArray("changes"):Add(eventValue).
 END.
END PROCEDURE.

/* Transactional item allocation with trusted effects provider. TT only. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItensCrudFixture.i}
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO.
DEFINE VARIABLE sequenceCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE afterCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE logCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE effectId AS INTEGER NO-UNDO.
DEFINE VARIABLE expectedNested AS LOGICAL NO-UNDO.
DEFINE VARIABLE savedAudit AS JsonObject NO-UNDO.
RUN Fixture. RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"allocation commits through real item core").
RUN Check(NOT TRANSACTION AND responseValue:GetLogical("committed"),"confirmed root response follows commit").
RUN Check(responseValue:GetJsonObject("data"):GetInteger("item_container_id")=1001,"new item ID comes from trusted callback").
RUN Check(responseValue:GetJsonObject("data"):GetDecimal("qt_alocada")=20,"allocation quantity persisted").
RUN Check(responseValue:GetJsonObject("audit"):GetInteger("recordId")=1001 AND responseValue:GetJsonObject("audit"):GetInteger("container_id")=123,"audit identifies item and immutable parent separately").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("actor"):GetCharacter("login")="item-tester" AND NOT responseValue:GetJsonObject("audit"):GetJsonObject("actor"):Has("extra"),"audit normalizes trusted actor").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=2,"main item and actual fiscal effect audited").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"allocation invalidates master version").
RUN Check(sequenceCalls=1 AND afterCalls=1 AND logCalls=1,"one ID and one effects callback then postcommit log").
FIND FIRST ttPurchases. FIND FIRST ttMaster.
RUN Check(ttPurchases.empresa_id=1 AND ttPurchases.fornecedor_id=888 AND ttMaster.cod-emit-forn=10,"cross-company supplier allocation remains allowed").
RELEASE ttPurchases. RELEASE ttMaster.
RUN AllocationTests. RUN InputTests. RUN EffectsTests. RUN DeleteTests. RUN NestedTests.
OUTPUT TO VALUE("containers-itens-crud-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; undoable TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 checks=checks + 1.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + " " + (IF VALID-OBJECT(responseValue) THEN STRING(responseValue:GetJsonText()) ELSE "no response"),1).
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER textValue AS LONGCHAR NO-UNDO.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 requestValue=CAST(parser:Parse(textValue),JsonObject).
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersItensCrudService.p(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttDiscounts:HANDLE,INPUT BUFFER ttItemCosts:HANDLE,INPUT BUFFER ttCommercial:HANDLE,THIS-PROCEDURE,policyValue,requestValue,OUTPUT responseValue).
END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 RUN Check(NOT responseValue:GetLogical("success"),"expected failure " + codeValue).
 RUN Check(responseValue:GetJsonObject("error"):GetCharacter("code")=codeValue,"structured error code " + codeValue).
 RUN Check(NOT responseValue:Has("audit") AND NOT responseValue:Has("pendingChanges"),"failure has no confirmed or pending audit").
END PROCEDURE.
PROCEDURE Fixture:
 EMPTY TEMP-TABLE ttMaster. EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttPurchaseItems. EMPTY TEMP-TABLE ttPurchases.
 EMPTY TEMP-TABLE ttDiscounts. EMPTY TEMP-TABLE ttItemCosts. EMPTY TEMP-TABLE ttCommercial. EMPTY TEMP-TABLE ttItemEffects.
 CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.cod-estabel="501" ttMaster.cod-emit-forn=10.
 RELEASE ttMaster.
 CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=21 ttPurchases.empresa_id=1 ttPurchases.fornecedor_id=888.
 RELEASE ttPurchases.
 CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=21 ttPurchaseItems.codigo_erp="ERP11" ttPurchaseItems.qt_comprada=100.
 RELEASE ttPurchaseItems.
 CREATE ttItems. ASSIGN ttItems.item_container_id=1 ttItems.container_id=999 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=60.
 RELEASE ttItems.
 ASSIGN modeValue="ok" sequenceValue=1000 sequenceCalls=0 afterCalls=0 logCalls=0 effectId=500 expectedNested=FALSE.
 policyValue=NEW JsonObject(). savedAudit=NEW JsonObject(). savedAudit:Add("login","item-tester"). savedAudit:Add("extra","drop"). policyValue:Add("actor",savedAudit).
 RUN Request('~{"operation":"create","container_id":123,"values":~{"item_proc_compra_id":11,"qt_alocada":20}}').
END PROCEDURE.
PROCEDURE GetCapabilities:
 DEFINE OUTPUT PARAMETER caps AS JsonObject NO-UNDO.
 caps=NEW JsonObject(). caps:Add("contract",IF modeValue="wrong-contract" THEN "unknown" ELSE "container-item-rules-v1").
 caps:Add("afterChange",modeValue<>"unsupported"). caps:Add("nextItemId",TRUE).
END PROCEDURE.
PROCEDURE NextItemId:
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Sequence requires root transaction",1).
 sequenceCalls=sequenceCalls + 1. sequenceValue=sequenceValue + 1.
 idValue=IF modeValue="bad-sequence" THEN 0 ELSE sequenceValue.
END PROCEDURE.
PROCEDURE AfterChange:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE changesValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION OR NOT master:AVAILABLE OR master:BUFFER-FIELD("nr-container"):BUFFER-VALUE<>123 THEN UNDO, THROW NEW Progress.Lang.AppError("Effects require actual locked parent",1).
 afterCalls=afterCalls + 1.
 IF ctx:GetCharacter("operation")="delete" THEN DO:
  idValue=ctx:GetJsonObject("before"):GetInteger("item_container_id").
  FIND ttItems WHERE ttItems.item_container_id=idValue NO-ERROR.
  IF AVAILABLE ttItems THEN UNDO, THROW NEW Progress.Lang.AppError("Delete callback ran before mutation",1).
 END.
 ELSE DO:
  idValue=ctx:GetJsonObject("after"):GetInteger("item_container_id").
  FIND ttItems WHERE ttItems.item_container_id=idValue.
  IF ttItems.qt_alocada<>ctx:GetJsonObject("after"):GetDecimal("qt_alocada") THEN UNDO, THROW NEW Progress.Lang.AppError("Callback must see actual mutated item",1).
 END.
 effectId=effectId + 1. CREATE ttItemEffects. ASSIGN ttItemEffects.calc_imp_container_id=effectId ttItemEffects.container_id=123 ttItemEffects.descricao="fiscal test". RELEASE ttItemEffects.
 IF modeValue="fail-after-write" THEN UNDO, THROW NEW Progress.Lang.AppError("Effects failed after persistent writes",1).
 changesValue=NEW JsonArray(). eventValue=NEW JsonObject(). rowValue=NEW JsonObject().
 eventValue:Add("resource",IF modeValue="unknown-resource" THEN "fornecedor" ELSE "calcs_imp_container"). eventValue:Add("operation","create"). eventValue:Add("recordId",effectId).
 rowValue:Add("calc_imp_container_id",effectId). rowValue:Add("container_id",IF modeValue="wrong-scope" THEN 999 ELSE 123).
 IF modeValue="nested-snapshot" THEN rowValue:Add("not_physical",NEW JsonObject()).
 eventValue:Add("before",NEW JsonObject()). eventValue:Add("after",rowValue). changesValue:Add(eventValue).
 IF modeValue="ipi" THEN DO:
  FIND ttItems WHERE ttItems.item_container_id=idValue.
  ttItems.perc_ipi=17.5.
  eventValue=NEW JsonObject(). eventValue:Add("resource","itens_container"). eventValue:Add("operation","update"). eventValue:Add("recordId",idValue).
  eventValue:Add("before",CAST(ctx:GetJsonObject("after"):Clone(),JsonObject)).
  rowValue=CAST(ctx:GetJsonObject("after"):Clone(),JsonObject). rowValue:Set("perc_ipi",17.5). eventValue:Add("after",rowValue). changesValue:Add(eventValue).
 END.
 IF modeValue="master" THEN master:BUFFER-FIELD("narrativa"):BUFFER-VALUE="effects-master".
 resultValue=NEW JsonObject(). resultValue:Add("success",modeValue<>"unconfirmed"). resultValue:Add("changes",changesValue).
 IF modeValue="early-audit" THEN resultValue:Add("audit",NEW JsonObject()).
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Confirmed log before root commit",1).
 logCalls=logCalls + 1.
 IF modeValue="fail-log" THEN UNDO, THROW NEW Progress.Lang.AppError("Queue unavailable after commit",1).
END PROCEDURE.
PROCEDURE AllocationTests:
 RUN Fixture. requestValue:GetJsonObject("values"):Set("qt_alocada",40.004). RUN Invoke.
 RUN Check(responseValue:GetLogical("success") AND responseValue:GetJsonObject("data"):GetDecimal("qt_alocada")=40,"allocation uses physical ROUND2 and all containers").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("qt_alocada",40.005). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_ALLOCATION_EXCEEDED").
 RUN Check(sequenceCalls=0 AND afterCalls=0,"over-allocation rejected before sequence or mutation").
 RUN Fixture. FIND FIRST ttItems. ttItems.qt_alocada=101. RELEASE ttItems. RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_ALLOCATION_EXCEEDED").
 RUN Fixture. RUN Invoke. RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_EXISTS").
 RUN Check(sequenceCalls=1,"duplicate allocation is conflict without hidden idempotence or ID consumption").
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"qt_alocada":41}}'). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_ALLOCATION_EXCEEDED").
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"qt_alocada":40,"qt_confirm_emb":70,"qt_recbto_fisico":80}}'). RUN Invoke.
 RUN Check(responseValue:GetLogical("success") AND responseValue:GetJsonObject("data"):GetDecimal("qt_confirm_emb")=70,"confirmed quantity may exceed allocated quantity").
 FIND FIRST ttPurchaseItems. ttPurchaseItems.qt_comprada=1. RELEASE ttPurchaseItems.
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"qt_alocada":30}}'). RUN Invoke.
 RUN Check(responseValue:GetLogical("success"),"decrease can repair historical over-allocation").
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"observacao":"same allocation"}}'). RUN Invoke.
 RUN Check(responseValue:GetLogical("success"),"unrelated update does not rerun positive-increment balance gate").
 FIND FIRST ttItems WHERE ttItems.item_container_id=1. RUN Check(ttItems.container_id=999 AND ttItems.qt_alocada=60,"foreign container allocation preserved"). RELEASE ttItems.
END PROCEDURE.
PROCEDURE InputTests:
 RUN Fixture. requestValue:Add("policy",NEW JsonObject()). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Add("container_id",999). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("item_proc_compra_id",11.5). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("item_proc_compra_id","11"). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("qt_alocada",-1). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("qt_alocada",0). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("qt_alocada",0.001). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Add("log_calc_ipi","true"). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Add("cod_tipo_calculo",1.5). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Set("item_proc_compra_id",2147483648). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:Set("container_id",2147483648). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Add("qt_disponivel",999). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. requestValue:GetJsonObject("values"):Add("preco_liquida_ima",1). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Fixture. FIND FIRST ttPurchaseItems. ttPurchaseItems.codigo_erp="". RELEASE ttPurchaseItems. RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_REFERENCE_INVALID").
 RUN Fixture. EMPTY TEMP-TABLE ttPurchases. RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_REFERENCE_INVALID").
 RUN Fixture. EMPTY TEMP-TABLE ttPurchaseItems. RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_REFERENCE_INVALID").
 RUN Fixture. RUN Invoke.
 RUN Request('~{"operation":"update","container_id":123,"id":"1001","item_container_id":1001,"values":~{"item_proc_compra_id":11,"observacao":"quote ~\" and apostrophe ' + CHR(39) + '"}}'). RUN Invoke.
 RUN Check(responseValue:GetLogical("success"),"matching immutable FK echo and exact ID alias accepted").
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"item_proc_compra_id":12}}'). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"item_container_id":1002,"values":~{"observacao":"x"}}'). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_VALIDATION").
 RUN Request('~{"operation":"get","container_id":999,"id":1001}'). RUN Invoke. RUN ErrorCode("CONTAINER_NOT_FOUND").
 RUN Request('~{"operation":"get","container_id":123,"id":1}'). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_NOT_FOUND").
 RUN Request('~{"operation":"get","container_id":123,"item_container_id":"1001"}'). RUN Invoke.
 RUN Check(responseValue:GetLogical("success") AND NOT responseValue:Has("audit"),"get reads own row without business effects audit").
END PROCEDURE.
PROCEDURE EffectsTests:
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DO n=1 TO 6:
  RUN Fixture. modeValue=ENTRY(n,"fail-after-write,unconfirmed,wrong-scope,unknown-resource,early-audit,nested-snapshot"). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_RULE_FAILED").
  FIND ttItems WHERE ttItems.item_container_id=1001 NO-ERROR. RUN Check(NOT AVAILABLE ttItems,"effects failure rolls main item back").
  FIND FIRST ttItemEffects NO-ERROR. RUN Check(NOT AVAILABLE ttItemEffects AND logCalls=0,"effects writes rolled back and no commit log").
 END.
 RUN Fixture. modeValue="ipi". RUN Invoke.
 RUN Check(responseValue:GetLogical("success") AND responseValue:GetJsonObject("data"):GetDecimal("perc_ipi")=17.5,"final data reread after central IPI mutation").
 RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=2 AND responseValue:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(1):GetJsonObject("after"):GetDecimal("perc_ipi")=17.5,"own IPI event coalesced into single actual final item image").
 RUN Fixture. modeValue="master". RUN Invoke.
 RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("before"):GetCharacter("narrativa")="" AND responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetCharacter("narrativa")="effects-master","master audit spans callback mutation").
 RUN Fixture. modeValue="bad-sequence". RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_SEQUENCE_INVALID").
 RUN Fixture. modeValue="wrong-contract". RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_RULE_UNAVAILABLE").
 RUN Check(sequenceCalls=0,"untrusted capabilities rejected before ID allocation").
 RUN Fixture. modeValue="fail-log". RUN Invoke.
 RUN Check(responseValue:GetLogical("success") AND responseValue:Has("audit"),"queue failure cannot disguise committed allocation as failure").
 RUN Fixture. RUN Invoke.
 FIND FIRST ttMaster. ASSIGN ttMaster.log_versao_custo_desatualizada=FALSE ttMaster.dt_hr_ult_alt_versao_custo=?. RELEASE ttMaster.
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"qt_alocada":20,"qt_confirm_emb":0,"observacao":"note"}}'). RUN Invoke.
 RUN Check(NOT responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"unmodified watched quantities preserve version flag").
 RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):IsNull("dt_hr_ult_alt_versao_custo"),"nonquantity update does not stamp stale time").
 RUN Request('~{"operation":"update","container_id":123,"id":1001,"values":~{"qt_confirm_emb":25}}'). RUN Invoke.
 RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"confirmed quantity change invalidates master").
END PROCEDURE.
PROCEDURE DeleteTests:
 RUN Fixture. RUN Invoke.
 CREATE ttDiscounts. ASSIGN ttDiscounts.desconto_importacao_id=1 ttDiscounts.item_container_id=1001. RELEASE ttDiscounts.
 RUN Request('~{"operation":"delete","container_id":123,"id":1001}'). RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_DEPENDENCY").
 EMPTY TEMP-TABLE ttDiscounts.
 CREATE ttItemCosts. ASSIGN ttItemCosts.item_container_custo_id=1 ttItemCosts.item_container_id=1001 ttItemCosts.versao_id=999. RELEASE ttItemCosts.
 RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_DEPENDENCY"). EMPTY TEMP-TABLE ttItemCosts.
 CREATE ttCommercial. ASSIGN ttCommercial.nr-container=123 ttCommercial.item_proc_compra_id=11. RELEASE ttCommercial.
 RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_DEPENDENCY"). EMPTY TEMP-TABLE ttCommercial.
 CREATE ttCommercial. ASSIGN ttCommercial.nr-container=999 ttCommercial.item_proc_compra_id=11. RELEASE ttCommercial.
 modeValue="fail-after-write". RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_RULE_FAILED").
 FIND ttItems WHERE ttItems.item_container_id=1001. RUN Check(AVAILABLE ttItems,"delete effects failure restores main item"). RELEASE ttItems.
 modeValue="ok". RUN Invoke.
 RUN Check(responseValue:GetLogical("success") AND STRING(responseValue:GetJsonObject("audit"):GetJsonObject("after"):GetJsonText())="~{~}","delete confirmed with empty actual after").
 FIND ttItems WHERE ttItems.item_container_id=1. RUN Check(ttItems.container_id=999,"delete preserves foreign item"). RELEASE ttItems.
 FIND FIRST ttCommercial. RUN Check(ttCommercial.nr-container=999,"foreign commercial reference does not block own delete"). RELEASE ttCommercial.
END PROCEDURE.
PROCEDURE NestedTests:
 RUN Fixture.
 DO TRANSACTION: RUN Invoke. RUN ErrorCode("CONTAINER_ITEM_TRANSACTION_CONTEXT"). END.
 RUN Fixture. policyValue:Add("allow_nested",TRUE). expectedNested=TRUE.
 nestedAllocation: DO TRANSACTION:
  RUN Invoke.
  RUN Check(responseValue:GetLogical("success") AND NOT responseValue:GetLogical("committed") AND NOT responseValue:Has("audit"),"explicit private composition returns pending effects only").
  RUN Check(responseValue:Has("pendingChanges") AND responseValue:Has("pendingMaster") AND logCalls=0,"nested response provides root owner snapshots and no confirmed log").
  UNDO nestedAllocation, LEAVE nestedAllocation.
 END.
 FIND ttItems WHERE ttItems.item_container_id=1001 NO-ERROR. RUN Check(NOT AVAILABLE ttItems,"ancestor rollback undoes nested allocation").
 FIND FIRST ttItemEffects NO-ERROR. RUN Check(NOT AVAILABLE ttItemEffects,"ancestor rollback undoes nested callback effect").
END PROCEDURE.

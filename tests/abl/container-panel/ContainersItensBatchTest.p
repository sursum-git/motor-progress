/* Transactional item allocation with trusted effects provider. TT only. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItensCrudFixture.i}
{sursum-api/includes/ContainerTransactionAudit.i}
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
SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
OUTPUT TO VALUE('allocation-batch-tests-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN BatchFixture. RUN Invoke.
 RUN Check(responseValue:GetLogical('success'),'batch service implemented').
 RUN Check(responseValue:GetLogical('committed') AND NOT TRANSACTION,'root owns commit').
 RUN Check(sequenceCalls=2 AND afterCalls=2 AND logCalls=0,'nested single service reused without premature log').
 FIND ttItems WHERE ttItems.item_container_id=1001. RUN Check(ttItems.item_proc_compra_id=11 AND ttItems.qt_alocada=40,'full remaining balance used for first item'). RELEASE ttItems.
 FIND ttItems WHERE ttItems.item_container_id=1002. RUN Check(ttItems.item_proc_compra_id=12 AND ttItems.qt_alocada=30,'second balance and deterministic sorted IDs'). RELEASE ttItems.
 RUN Check(responseValue:GetJsonObject('audit'):GetJsonArray('changes'):Length=4,'both item creates and actual child effects audited').
 RUN BatchFixture. modeValue='fail-second'. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success'),'second callback failure aborts entire batch'). RUN Check(NOT CAN-FIND(FIRST ttItems WHERE ttItems.container_id=123) AND NOT CAN-FIND(FIRST ttItemEffects),'all item/effect writes undone').
 RUN BatchFixture. RUN Request('~{"operation":"allocate","container_id":123,"item_ids":[11,999]}'). RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'invalid later reference fails before IDs').
 RUN BatchFixture. RUN Request('~{"operation":"allocate","container_id":123,"item_ids":[11,11]}'). RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'duplicates rejected before IDs').
 RUN BatchFixture. RUN Request('~{"operation":"allocate","container_id":123,"item_ids":[11.5]}'). RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'fraction ID rejected').
 RUN BatchFixture. FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=12. ttPurchaseItems.qt_comprada=0. RELEASE ttPurchaseItems. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'later empty balance rejects entire plan before IDs').
 RUN BatchFixture. requestValue:Add('qt_alocada',1). RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'client quantity not accepted').
 RUN BatchFixture. CREATE ttItems. ASSIGN ttItems.item_container_id=2 ttItems.container_id=123 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=1. RELEASE ttItems. RUN Invoke. RUN Check(responseValue:GetLogical('success') AND sequenceCalls=1,'existing pair skipped while allocating remaining requested items').
 RUN BatchFixture. modeValue='silent-prior'. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success'),'unreported prior item mutation must fail before commit'). RUN Check(NOT CAN-FIND(FIRST ttItems WHERE ttItems.container_id=123),'unreported mutation rolls back root').
 RUN BatchFixture. modeValue='warning'. RUN Invoke. RUN Check(responseValue:GetLogical('success'),'text warnings must preserve committed root'). RUN Check(responseValue:GetJsonObject('audit'):GetJsonArray('warnings'):Length=2,'warnings from both nested calls retained').
 RUN BatchFixture. modeValue='ipi'. RUN Invoke. RUN Check(responseValue:GetLogical('success'),'main item final physical fiscal image retained'). RUN Check(responseValue:GetJsonArray('allocated'):GetJsonObject(1):GetDecimal('perc_ipi')=17.5,'allocated rows reflect final fiscal effect').
 RUN BatchFixture. modeValue='prior-item'. RUN Invoke. RUN Check(responseValue:GetLogical('success'),'reported prior item fiscal update coalesces continuously'). RUN Check(responseValue:GetJsonArray('allocated'):GetJsonObject(1):GetDecimal('perc_ipi')=3,'final first row after second item rules').
 RUN BatchFixture. modeValue='bad-chain'. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success'),'discontinuous images cannot commit').
 RUN BatchFixture. RUN Request('~{"operation":"allocate","container_id":123,"item_ids":[11]}'). CREATE ttItems. ASSIGN ttItems.item_container_id=2 ttItems.container_id=123 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=1. RELEASE ttItems. RUN Invoke. RUN Check(responseValue:GetLogical('success') AND sequenceCalls=0 AND afterCalls=0,'all-existing batch is explicit no-op'). RUN Check(responseValue:GetJsonArray('skipped'):Length=1 AND responseValue:GetJsonArray('allocated'):Length=0,'no-op selection partition').
 RUN BatchFixture. requestValue:Set('container_id',9999). RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'missing parent before sequences').
 RUN BatchFixture. policyValue=NEW JsonObject(). RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'missing trusted actor before sequences').
 RUN BatchFixture. modeValue='unsupported'. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'unsupported provider never allocates').
 RUN BatchFixture. FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=12. ttPurchaseItems.codigo_erp=''. RELEASE ttPurchaseItems. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'later missing ERP before sequences').
 RUN BatchFixture. requestValue:Set('item_ids',NEW JsonArray()). DO effectId=1 TO 26: requestValue:GetJsonArray('item_ids'):Add(effectId). END. RUN Invoke. RUN Check(NOT responseValue:GetLogical('success') AND sequenceCalls=0,'26 IDs rejected before sequences').
 PUT UNFORMATTED 'PASS allocation batch checks=' checks ' NUMDBS=' NUM-DBS SKIP.
 CATCH err AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' err:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE BatchFixture:
 RUN Fixture.
 CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=12 ttPurchaseItems.proc_compra_id=21 ttPurchaseItems.codigo_erp='ERP12' ttPurchaseItems.qt_comprada=30. RELEASE ttPurchaseItems.
 RUN Request('~{"operation":"allocate","container_id":123,"item_ids":[12,11]}').
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 checks=checks + 1.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + " " + (IF VALID-OBJECT(responseValue) THEN STRING(responseValue:GetJsonText()) ELSE "no response"),1).
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER textValue AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE utfValue AS LONGCHAR NO-UNDO.
 FIX-CODEPAGE(utfValue)='UTF-8'. utfValue=textValue.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 requestValue=CAST(parser:Parse(utfValue),JsonObject).
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersItensBatchService.p(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttDiscounts:HANDLE,INPUT BUFFER ttItemCosts:HANDLE,INPUT BUFFER ttCommercial:HANDLE,THIS-PROCEDURE,policyValue,requestValue,OUTPUT responseValue).
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
 DEFINE VARIABLE beforeImage AS JsonObject NO-UNDO.
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
 IF modeValue="fail-after-write" OR (modeValue="fail-second" AND afterCalls=2) THEN UNDO, THROW NEW Progress.Lang.AppError("Effects failed after persistent writes",1).
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
 IF afterCalls=2 AND LOOKUP(modeValue,'silent-prior,prior-item,bad-chain')>0 THEN DO:
  FIND ttItems WHERE ttItems.item_container_id=1001.
  /* Snapshot the same physical buffer schema as the root. */
  RUN SnapshotItem(OUTPUT beforeImage).
  ttItems.perc_ipi=3.
  IF modeValue<>'silent-prior' THEN DO:
   eventValue=NEW JsonObject(). eventValue:Add('resource','itens_container'). eventValue:Add('operation','update'). eventValue:Add('recordId',1001).
   IF modeValue='bad-chain' THEN beforeImage:Set('perc_ipi',99).
   eventValue:Add('before',beforeImage). RUN SnapshotItem(OUTPUT rowValue). eventValue:Add('after',rowValue). changesValue:Add(eventValue).
  END.
  RELEASE ttItems.
 END.
 IF modeValue="master" THEN master:BUFFER-FIELD("narrativa"):BUFFER-VALUE="effects-master".
 resultValue=NEW JsonObject(). resultValue:Add("success",modeValue<>"unconfirmed"). resultValue:Add("changes",changesValue).
 IF modeValue='warning' THEN DO: rowValue=NEW JsonObject(). rowValue:Add('warnings',NEW JsonArray()). rowValue:GetJsonArray('warnings'):Add('Aviso do provider'). resultValue:Add('warnings',rowValue:GetJsonArray('warnings')). END.
 IF modeValue="early-audit" THEN resultValue:Add("audit",NEW JsonObject()).
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Confirmed log before root commit",1).
 logCalls=logCalls + 1.
 IF modeValue="fail-log" THEN UNDO, THROW NEW Progress.Lang.AppError("Queue unavailable after commit",1).
END PROCEDURE.

PROCEDURE SnapshotItem:
 DEFINE OUTPUT PARAMETER imageValue AS JsonObject NO-UNDO.
 imageValue=ProcessSnapshot(BUFFER ttItems:HANDLE,123).
END PROCEDURE.

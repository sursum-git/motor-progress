/* TT-only integration of collection, existing pure math and closing. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItemCustoPhysicalFixture.i}
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE inputData AS JsonObject NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE types AS JsonArray NO-UNDO.
DEFINE VARIABLE seqValue AS INTEGER NO-UNDO INITIAL 500.
DEFINE VARIABLE seqCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failAt AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE logCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE sourceBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE auditChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE snapshotBefore AS LONGCHAR NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
OUTPUT TO VALUE("containers-item-close-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 RUN Seed. RUN Collect(FALSE).
 RUN Check(response:GetLogical("success"),"physical complete inputs collected").
 inputData=response:GetJsonObject("data"):GetJsonObject("input").
 RUN Check(inputData:GetJsonArray("items"):Length=2,"all current items collected").
 RUN CloseCosts.
 RUN Check(response:GetLogical("success"),"all items close atomically using central calculator").
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=501.
 RUN Check(ttItemCosts.vl_unit_novo=18.89 AND ttItemCosts.cod_tipo_custo=2 AND ttItemCosts.cod_situacao=2,"exact legacy final unit and kind stored").
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71.
 RUN Check(ttVersionItems.item_custo_id=501,"snapshot links new item cost").
 RUN DetailedTests. RUN EdgeTests.
 PUT UNFORMATTED "PASS " checks " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED "FAIL after " checks ": " e:GetMessage(1) SKIP. IF VALID-OBJECT(response) THEN PUT UNFORMATTED STRING(response:GetJsonText()) SKIP. UNDO, THROW e. END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE Seed:
 DO TRANSACTION:
  EMPTY TEMP-TABLE ttMaster.
  EMPTY TEMP-TABLE ttItems.
  EMPTY TEMP-TABLE ttPurchaseItems.
  EMPTY TEMP-TABLE ttVersions.
  EMPTY TEMP-TABLE ttVersionItems.
  EMPTY TEMP-TABLE ttItemCosts.
  EMPTY TEMP-TABLE ttNfs.
  EMPTY TEMP-TABLE ttLocations.
  EMPTY TEMP-TABLE ttLabels.
  EMPTY TEMP-TABLE ttStockIma.
  EMPTY TEMP-TABLE ttStockMed.
  EMPTY TEMP-TABLE ttMovementsMed.
  EMPTY TEMP-TABLE ttInvoicesIma.
  EMPTY TEMP-TABLE ttInvoicesMed.
  CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.log_liberar_custo_realizado=TRUE.
  CREATE ttVersions. ASSIGN ttVersions.versao_id=7 ttVersions.container_id=123 ttVersions.tipo_versao_id=2 ttVersions.ind_sit_versao=2.
  DO n=1 TO 2:
   CREATE ttItems. ASSIGN ttItems.item_container_id=n ttItems.container_id=123 ttItems.item_proc_compra_id=10 + n.
   CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=10 + n ttPurchaseItems.codigo_erp="ERP" + STRING(n).
   CREATE ttVersionItems. ASSIGN ttVersionItems.item_container_custo_id=70 + n ttVersionItems.versao_id=7 ttVersionItems.item_container_id=n ttVersionItems.it_codigo="ERP" + STRING(n)
    ttVersionItems.vl_unit_prev=19 + n ttVersionItems.vl_unit_realiz=29 + n ttVersionItems.qt_alocada=IF n=1 THEN 100 ELSE 80 ttVersionItems.qt_confirm_emb=IF n=1 THEN 80 ELSE 0.
   CREATE ttItemCosts. ASSIGN ttItemCosts.item_custo_id=4 + n ttItemCosts.it_codigo="ERP" + STRING(n) ttItemCosts.cod_tipo_custo=1 ttItemCosts.vl_unit_novo=IF n=1 THEN 10 ELSE 12.
   CREATE ttStockIma. ASSIGN ttStockIma.it-codigo="ERP" + STRING(n) ttStockIma.cod-estabel="1" ttStockIma.cod-depos="A" ttStockIma.qtidade-atu=IF n=1 THEN 50 ELSE 10.
   CREATE ttStockMed. ASSIGN ttStockMed.it-codigo="ERP" + STRING(n) ttStockMed.cod-estabel="501" ttStockMed.cod-depos="A" ttStockMed.qtidade-atu=IF n=1 THEN 70 ELSE 20.
   CREATE ttMovementsMed. ASSIGN ttMovementsMed.nr-trans=n ttMovementsMed.it-codigo="ERP" + STRING(n) ttMovementsMed.dt-trans=DATE(9,1,2026) ttMovementsMed.tipo-trans=1 ttMovementsMed.quantidade=IF n=1 THEN 100 ELSE 30.
  END.
  CREATE ttLocations. ASSIGN ttLocations.local_estoq_portal_id=1 ttLocations.cod_empresa="5" ttLocations.cod_estab="501" ttLocations.cod_depos="A".
  CREATE ttNfs. ASSIGN ttNfs.container_id=123 ttNfs.documento="NF1" ttNfs.serie="A" ttNfs.estab="501" ttNfs.nat_operacao="3102" ttNfs.cod_emitente=10.
  CREATE ttInvoicesMed. ASSIGN ttInvoicesMed.cod-estabel="501" ttInvoicesMed.nr-nota-fis="NF1" ttInvoicesMed.serie="A" ttInvoicesMed.dt-emis-nota=DATE(10,1,2026).
  CREATE ttLabels. ASSIGN ttLabels.it-codigo="ERP1" ttLabels.nr-container=123 ttLabels.situacao=3 ttLabels.quantidade=20.
  CREATE ttLabels. ASSIGN ttLabels.it-codigo="ERP1" ttLabels.nr-container=999 ttLabels.situacao=4 ttLabels.quantidade=30.
 END.
 ASSIGN seqValue=500 seqCalls=0 failAt=0 logCalls=0.
 policy=NEW JsonObject(). policy:Add("actor","test-close"). types=NEW JsonArray(). types:Add(4). types:Add(5). policy:Add("tipo_versao_valida_nf",types).
 request=NEW JsonObject(). request:Add("operation","fechar"). request:Add("container_id",123). request:Add("versao_id",7). request:Add("expected_latest_version_id",7). request:Add("log_priorizar_custo_previsto",FALSE).
END PROCEDURE.
PROCEDURE Collect:
 DEFINE INPUT PARAMETER locking AS LOGICAL NO-UNDO.
 DEFINE VARIABLE p AS JsonObject NO-UNDO.
 DEFINE VARIABLE r AS JsonObject NO-UNDO.
 p=NEW JsonObject(). p:Add("tipo_versao_valida_nf",CAST(types:Clone(),JsonArray)).
 r=CAST(request:Clone(),JsonObject). r:Remove("operation"). r:Remove("expected_latest_version_id").
 RUN ContainersItemCustoInputsService.p(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttVersions:HANDLE,INPUT BUFFER ttVersionItems:HANDLE,INPUT BUFFER ttItemCosts:HANDLE,INPUT BUFFER ttNfs:HANDLE,INPUT BUFFER ttLocations:HANDLE,INPUT BUFFER ttLabels:HANDLE,INPUT BUFFER ttStockIma:HANDLE,INPUT BUFFER ttStockMed:HANDLE,INPUT BUFFER ttMovementsMed:HANDLE,INPUT BUFFER ttInvoicesIma:HANDLE,INPUT BUFFER ttInvoicesMed:HANDLE,locking,p,r,OUTPUT response).
END PROCEDURE.
PROCEDURE CloseCosts:
 RUN ContainersItemCustoCloseService.p(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttVersions:HANDLE,INPUT BUFFER ttVersionItems:HANDLE,INPUT BUFFER ttItemCosts:HANDLE,INPUT BUFFER ttNfs:HANDLE,INPUT BUFFER ttLocations:HANDLE,INPUT BUFFER ttLabels:HANDLE,INPUT BUFFER ttStockIma:HANDLE,INPUT BUFFER ttStockMed:HANDLE,INPUT BUFFER ttMovementsMed:HANDLE,INPUT BUFFER ttInvoicesIma:HANDLE,INPUT BUFFER ttInvoicesMed:HANDLE,THIS-PROCEDURE,policy,request,OUTPUT response).
END PROCEDURE.
PROCEDURE NextItemCustoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Sequence outside transaction",1).
 seqCalls=seqCalls + 1. IF failAt=seqCalls THEN UNDO, THROW NEW Progress.Lang.AppError("Injected sequence failure",1).
 seqValue=seqValue + 1. valueId=seqValue.
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(messageText,1).
 checks=checks + 1.
END PROCEDURE.

PROCEDURE ExpectFailure:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 RUN Check(NOT response:GetLogical("success"),"operation must fail").
 RUN Check(response:GetJsonObject("error"):GetCharacter("code")=code,"expected error " + code).
 RUN Check(NOT response:Has("audit") AND NOT response:Has("auditPending") AND NOT response:Has("pendingChanges"),"failure never claims audit or partial effects").
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 RUN Check(NOT TRANSACTION,"confirmed logger runs only after root commit").
 logCalls=logCalls + 1.
END PROCEDURE.
PROCEDURE DetailedTests:
 RUN Seed. RUN Collect(FALSE). RUN Check(seqCalls=0,"simulation collection never consumes ID").
 RUN Check(response:GetJsonObject("data"):GetJsonObject("provenance"):GetInteger("collection_count")=1,"one physical collection provenance").
 inputData=response:GetJsonObject("data"):GetJsonObject("input").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("stock"):GetDecimal("ima")=50,"IMA stock exact establishment1").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("stock"):GetDecimal("med")=70,"MED configured pair selected").
 CREATE ttStockIma. ASSIGN ttStockIma.it-codigo="ERP1" ttStockIma.cod-estabel="2" ttStockIma.cod-depos="A" ttStockIma.qtidade-atu=999.
 CREATE ttStockMed. ASSIGN ttStockMed.it-codigo="ERP1" ttStockMed.cod-estabel="999" ttStockMed.cod-depos="B" ttStockMed.qtidade-atu=333.
 RUN Collect(FALSE). inputData=response:GetJsonObject("data"):GetJsonObject("input").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("stock"):GetDecimal("ima")=50,"IMA other establishment excluded").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("stock"):GetDecimal("med")=70,"MED outside configured pairs excluded").
 EMPTY TEMP-TABLE ttLocations. RUN Collect(FALSE). inputData=response:GetJsonObject("data"):GetJsonObject("input").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("stock"):GetDecimal("med")=403,"without locations MED includes all locations as effective PHP, no invented prefix5").
 RUN Seed. RUN CloseCosts.
 RUN Check(response:GetLogical("committed") AND response:GetJsonObject("audit"):GetCharacter("source")="progress-transaction","standalone commit audit source").
 RUN Check(logCalls=1,"logger only after own commit").
 auditChanges=response:GetJsonObject("audit"):GetJsonArray("changes"). RUN Check(auditChanges:Length=4,"two inserts and two link updates audited").
 RUN Check(auditChanges:GetJsonObject(2):GetJsonObject("before"):GetInteger("item_custo_id")=0 AND auditChanges:GetJsonObject(2):GetJsonObject("after"):GetInteger("item_custo_id")=501,"link audit exact before and after").
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=501.
 RUN Check(ttItemCosts.qt_estoque=100 AND ttItemCosts.qt_estoque_selecionado=100 AND ttItemCosts.qt_nf_mae=80 AND ttItemCosts.qt_etiq_container=20,"all legacy stock quantities mapped").
 RUN Check(ttItemCosts.vl_unit_anterior=10 AND ttItemCosts.vl_unit_container=30 AND ttItemCosts.qt_container=80 AND ttItemCosts.cod_usuario="test-close","legacy prices quantity and actor mapped").
 RUN Check(ttItemCosts.dt_referencia=TODAY AND DATE(ttItemCosts.dt_hr_custo)=TODAY,"timestamp and current reference date server-owned").
 FIND ttVersions WHERE ttVersions.versao_id=7. RUN Check(ttVersions.ind_sit_versao=2,"closing does not change version generation state").
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"re-closing is permitted by legacy").
 RUN Check(CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=501) AND CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=503),"re-closing appends and preserves historical costs").
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. RUN Check(ttVersionItems.item_custo_id=503,"re-closing relinks current snapshot").
 auditChanges=response:GetJsonObject("audit"):GetJsonArray("changes").
 RUN Check(auditChanges:GetJsonObject(2):GetJsonObject("before"):GetInteger("item_custo_id")=501 AND auditChanges:GetJsonObject(2):GetJsonObject("after"):GetInteger("item_custo_id")=503,"re-close link audit preserves prior pointer").
 RUN Seed. failAt=2. RUN CloseCosts. RUN ExpectFailure("ITEM_COST_CALLBACK_FAILED").
 RUN Check(NOT CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=501),"second sequence failure undoes first insert").
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. RUN Check(ttVersionItems.item_custo_id=0,"second failure undoes first link").
 RUN Check(seqCalls=2 AND logCalls=0,"failed sequence counters survive rollback but no confirmed log").
 RUN Seed. FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=12. ttPurchaseItems.codigo_erp="".
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE"). RUN Check(seqCalls=0,"last invalid item blocks every write and ID call").
 RUN Seed. FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=72. DELETE ttVersionItems.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VALIDATION"). RUN Check(seqCalls=0,"missing last snapshot blocks complete batch without fallback0").
 RUN Seed. FIND ttMaster WHERE ttMaster.nr-container=123. ttMaster.log_versao_custo_desatualizada=TRUE.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VALIDATION"). RUN Check(seqCalls=0,"stale master cannot close").
 RUN Seed. CREATE ttVersions. ASSIGN ttVersions.versao_id=8 ttVersions.container_id=123 ttVersions.tipo_versao_id=2 ttVersions.ind_sit_versao=2.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VERSION_CONFLICT"). RUN Check(seqCalls=0,"newer version rejects stale expectation").
 RUN Seed. request:Set("expected_latest_version_id",6). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VERSION_CONFLICT").
 RUN Seed. request:Remove("expected_latest_version_id"). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INVALID_REQUEST").
 RUN Seed. request:Add("qt_erros",0). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INVALID_REQUEST").
 RUN Seed. request:Set("container_id",0). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INVALID_REQUEST").
 RUN Seed. request:Set("operation","Fechar"). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INVALID_REQUEST").
 RUN Seed. request:Set("log_priorizar_custo_previsto",TRUE). RUN CloseCosts. RUN Check(response:GetLogical("success"),"forecast priority is explicit boolean").
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=501. RUN Check(ttItemCosts.vl_unit_novo=14.44,"forecast preference uses same central math").
 RUN Seed. policy:Add("allow_nested",TRUE).
 DO TRANSACTION ON ERROR UNDO, THROW:
  FIND ttMaster WHERE ttMaster.nr-container=123. ttMaster.log_liberar_custo_realizado=FALSE.
  RUN CloseCosts.
  RUN Check(response:GetLogical("success") AND NOT response:GetLogical("committed"),"authorized nested closing returns uncommitted").
  RUN Check(response:Has("pendingChanges") AND response:Has("auditPending") AND NOT response:Has("audit"),"nested returns only pending audit").
  RUN Check(logCalls=0,"nested never queues confirmed logger").
  UNDO, LEAVE.
 END.
 RUN Check(NOT CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=501),"outer caller undo reverses inserted costs").
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. RUN Check(ttVersionItems.item_custo_id=0,"outer caller undo reverses snapshot pointer").
 FIND ttMaster WHERE ttMaster.nr-container=123. RUN Check(ttMaster.log_liberar_custo_realizado,"outer caller undo reverses its own header update").
 RUN Seed.
 DO TRANSACTION ON ERROR UNDO, THROW:
  FIND ttMaster WHERE ttMaster.nr-container=123. ttMaster.log_liberar_custo_realizado=FALSE.
  RUN CloseCosts. RUN ExpectFailure("ITEM_COST_TRANSACTION_CONTEXT"). UNDO, LEAVE.
 END.
 RUN Seed. policy:Add("allow_nested",TRUE). failAt=2.
 DO TRANSACTION ON ERROR UNDO, THROW:
  FIND ttMaster WHERE ttMaster.nr-container=123. ttMaster.log_liberar_custo_realizado=FALSE.
  RUN CloseCosts. RUN ExpectFailure("ITEM_COST_CALLBACK_FAILED"). UNDO, LEAVE.
 END.
 RUN Check(NOT CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=501),"nested failure and caller undo remain atomic").
 RUN Seed. RUN Collect(TRUE). RUN ExpectFailure("ITEM_COST_TRANSACTION_CONTEXT").
 RUN Seed. FIND ttInvoicesMed WHERE ttInvoicesMed.nr-nota-fis="NF1". DELETE ttInvoicesMed.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE"). RUN Check(seqCalls=0,"linked mother without ERP invoice blocks rather than default2001").
 RUN Seed. FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=72. ttVersionItems.item_container_id=999.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE"). RUN Check(seqCalls=0,"foreign extra snapshot cannot be included").
 RUN Seed. FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. ttVersionItems.item_custo_id=?.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE"). RUN Check(seqCalls=0,"unknown prior pointer must fail before sequence").
END PROCEDURE.

PROCEDURE EdgeTests:
 DEFINE VARIABLE unusualCode AS CHARACTER NO-UNDO.
 RUN Seed.
 CREATE ttVersions. ASSIGN ttVersions.versao_id=99 ttVersions.container_id=999 ttVersions.tipo_versao_id=2 ttVersions.ind_sit_versao=2.
 CREATE ttItemCosts. ASSIGN ttItemCosts.item_custo_id=100 ttItemCosts.it_codigo="ERP1" ttItemCosts.cod_tipo_custo=2 ttItemCosts.vl_unit_novo=99.
 CREATE ttVersionItems. ASSIGN ttVersionItems.item_container_custo_id=999 ttVersionItems.versao_id=99 ttVersionItems.item_container_id=999 ttVersionItems.item_custo_id=100.
 CREATE ttItemCosts. ASSIGN ttItemCosts.item_custo_id=101 ttItemCosts.it_codigo="ERP1" ttItemCosts.cod_tipo_custo=3 ttItemCosts.vl_unit_novo=12.
 CREATE ttItemCosts. ASSIGN ttItemCosts.item_custo_id=200 ttItemCosts.it_codigo="ERP1" ttItemCosts.cod_tipo_custo=2 ttItemCosts.vl_unit_novo=999.
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. ttVersionItems.item_custo_id=200.
 RUN Collect(FALSE). RUN Check(response:GetLogical("success"),"foreign global latest version does not change local latest").
 inputData=response:GetJsonObject("data"):GetJsonObject("input").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("previous_cost"):GetInteger("item_custo_id")=101,"greatest eligible previous ID across non2 and other-container type2").
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=101. DELETE ttItemCosts.
 RUN Collect(FALSE). inputData=response:GetJsonObject("data"):GetJsonObject("input").
 RUN Check(inputData:GetJsonArray("items"):GetJsonObject(1):GetJsonObject("previous_cost"):GetInteger("item_custo_id")=100,"other-container type2 is eligible and own-container type2 excluded").
 RUN Seed. FIND ttItemCosts WHERE ttItemCosts.item_custo_id=5. DELETE ttItemCosts.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VALIDATION"). RUN Check(seqCalls=0,"missing required previous cost never replaced by zero").
 RUN Seed. FIND ttItemCosts WHERE ttItemCosts.item_custo_id=5. DELETE ttItemCosts.
 FIND ttMovementsMed WHERE ttMovementsMed.it-codigo="ERP1". DELETE ttMovementsMed.
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. ttVersionItems.vl_unit_realiz=30.12345.
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"confirmed no prior movement allows absent previous cost").
 RUN Check(response:GetJsonObject("data"):GetJsonObject("calculation"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo")=30.12345,"central no-movement unit remains unrounded").
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=501. RUN Check(ttItemCosts.vl_unit_novo=30.12,"writer respects physical DECIMALS2 separately").
 RUN Check(response:GetJsonObject("data"):GetJsonArray("warnings"):GetJsonObject(1):GetCharacter("code")="ITEM_COST_STORAGE_ROUNDING","physical rounding is visible").
 RUN Seed. CREATE ttNfs. ASSIGN ttNfs.container_id=123 ttNfs.documento="NF2" ttNfs.serie="A" ttNfs.estab="501" ttNfs.nat_operacao="3102" ttNfs.cod_emitente=10.
 CREATE ttInvoicesMed. ASSIGN ttInvoicesMed.cod-estabel="501" ttInvoicesMed.nr-nota-fis="NF2" ttInvoicesMed.serie="A" ttInvoicesMed.dt-emis-nota=DATE(10,1,2026).
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"multiple mothers with same date keep central equivalent-date behavior").
 RUN Seed. CREATE ttNfs. ASSIGN ttNfs.container_id=123 ttNfs.documento="NF2" ttNfs.serie="A" ttNfs.estab="501" ttNfs.nat_operacao="3102" ttNfs.cod_emitente=10.
 CREATE ttInvoicesMed. ASSIGN ttInvoicesMed.cod-estabel="501" ttInvoicesMed.nr-nota-fis="NF2" ttInvoicesMed.serie="A" ttInvoicesMed.dt-emis-nota=DATE(10,2,2026).
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VALIDATION"). RUN Check(seqCalls=0,"ambiguous mother dates gate all inserts").
 RUN Seed. FIND ttNfs WHERE ttNfs.container_id=123. ttNfs.estab="1".
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE").
 CREATE ttInvoicesIma. ASSIGN ttInvoicesIma.cod-estabel="1" ttInvoicesIma.nr-nota-fis="NF1" ttInvoicesIma.serie="A" ttInvoicesIma.dt-emis-nota=DATE(10,1,2026).
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"mother exact establishment1 uses IMA physical note only").
 RUN Seed. EMPTY TEMP-TABLE ttNfs. RUN CloseCosts. RUN Check(response:GetLogical("success"),"no mother uses central documented default when version type permits").
 RUN Seed. EMPTY TEMP-TABLE ttNfs. FIND ttVersions WHERE ttVersions.versao_id=7. ttVersions.tipo_versao_id=4.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VALIDATION"). RUN Check(seqCalls=0,"private configured version type requires mother").
 RUN Seed. CREATE ttVersionItems. ASSIGN ttVersionItems.item_container_custo_id=73 ttVersionItems.versao_id=7 ttVersionItems.item_container_id=1 ttVersionItems.it_codigo="ERP1".
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_AMBIGUOUS"). RUN Check(seqCalls=0,"duplicate snapshot pair never chooses first").
 RUN Seed. EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttVersionItems.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VALIDATION"). RUN Check(seqCalls=0,"empty current item set has no fake cost").
 RUN Seed. FIND ttVersions WHERE ttVersions.versao_id=7. ttVersions.ind_sit_versao=1.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_VERSION_INCOMPLETE").
 RUN Seed. unusualCode="O'" + CHR(126) + CHR(34) + CHR(10) + "X".
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=11. ttPurchaseItems.codigo_erp=unusualCode.
 FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. ttVersionItems.it_codigo=unusualCode.
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=5. ttItemCosts.it_codigo=unusualCode.
 FOR EACH ttStockIma WHERE ttStockIma.it-codigo="ERP1": ttStockIma.it-codigo=unusualCode. END.
 FOR EACH ttStockMed WHERE ttStockMed.it-codigo="ERP1": ttStockMed.it-codigo=unusualCode. END.
 FOR EACH ttMovementsMed WHERE ttMovementsMed.it-codigo="ERP1": ttMovementsMed.it-codigo=unusualCode. END.
 FOR EACH ttLabels WHERE ttLabels.it-codigo="ERP1": ttLabels.it-codigo=unusualCode. END.
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"persisted keys with quote tilde doublequote newline are literals only").
 FIND ttItemCosts WHERE ttItemCosts.item_custo_id=501. RUN Check(ttItemCosts.it_codigo=unusualCode AND ttItemCosts.vl_unit_novo=18.89,"unusual ERP code stays exact across all physical queries").
 RUN Seed. types=NEW JsonArray(). types:Add("4"). policy:Set("tipo_versao_valida_nf",types).
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INVALID").
 RUN Seed. CREATE ttMovementsMed. ASSIGN ttMovementsMed.nr-trans=999 ttMovementsMed.it-codigo="ERP1" ttMovementsMed.dt-trans=DATE(11,1,2026) ttMovementsMed.tipo-trans=1 ttMovementsMed.quantidade=?.
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"future movement outside reference cutoff is not read as a used financial input").
 RUN Check(NOT AVAILABLE ttMaster AND NOT AVAILABLE ttItemCosts,"standalone closing releases its buffer scope after commit").

 RUN Seed. seqValue=4. RUN CloseCosts. RUN ExpectFailure("ITEM_COST_SEQUENCE_CONFLICT").
 RUN Check(seqCalls=1 AND logCalls=0,"sequence collision fails without deleting existing historical cost").
 RUN Check(CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=5),"sequence conflict preserves prior records").
 RUN Seed. CREATE ttItemCosts. ASSIGN ttItemCosts.item_custo_id=999999 ttItemCosts.it_codigo="UNRELATED" ttItemCosts.cod_tipo_custo=1 ttItemCosts.vl_unit_novo=1.
 RUN CloseCosts. RUN Check(response:GetLogical("success") AND CAN-FIND(ttItemCosts WHERE ttItemCosts.item_custo_id=501),"writer never derives next ID from unrelated global maximum").
 RUN Seed. policy:Set("actor",FILL("x",31)). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_CONFIGURATION"). RUN Check(seqCalls=0,"physical actor length validated before writes").
 RUN Seed. policy:Add("allow_nested","true"). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_CONFIGURATION").
 RUN Seed. request:Add("actor","browser actor"). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INVALID_REQUEST").
 RUN Seed. request:Set("container_id",999). RUN CloseCosts. RUN ExpectFailure("ITEM_COST_CONTAINER_NOT_FOUND").
 RUN Seed. FIND ttMaster WHERE ttMaster.nr-container=123. ttMaster.log_liberar_custo_realizado=?.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE").
 RUN Seed. FIND ttStockIma WHERE ttStockIma.it-codigo="ERP1". ttStockIma.qtidade-atu=?.
 RUN CloseCosts. RUN ExpectFailure("ITEM_COST_INPUT_INCOMPLETE"). RUN Check(seqCalls=0,"unknown selected ERP stock is not silently zero").
 RUN Seed. FIND ttNfs WHERE ttNfs.container_id=123. ttNfs.nat_operacao="2102". EMPTY TEMP-TABLE ttInvoicesMed.
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"non-mother NF does not require irrelevant ERP mother lookup").
 RUN Seed. FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71. ASSIGN ttVersionItems.qt_alocada=? ttVersionItems.qt_recebto_fisico=? ttVersionItems.vl_unit_prev=?.
 RUN CloseCosts. RUN Check(response:GetLogical("success"),"unused snapshot null components remain null and do not invent zero").

END PROCEDURE.



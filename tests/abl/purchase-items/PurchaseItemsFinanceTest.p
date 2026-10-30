/* Real undoable TT rows; only callbacks are trusted test doubles. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchaseItemsFinanceFixture.i}
DEFINE TEMP-TABLE ttTxn FIELD marker AS INTEGER.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE contextData AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeData AS JsonObject NO-UNDO.
DEFINE VARIABLE afterData AS JsonObject NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
DEFINE VARIABLE errorText AS CHARACTER NO-UNDO.
DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO.
DEFINE VARIABLE sequenceCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failAt AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE containerCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE orderCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE paymentMode AS INTEGER NO-UNDO.
DEFINE VARIABLE savedCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
FUNCTION ItemRow RETURNS JsonObject () FORWARD.
OUTPUT TO VALUE('purchase-item-finance-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed. RUN ItemContext('purchase-item-update'). RUN Invoke.
 RUN Check(NOT failed,'incremental financial update').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90),'history retained').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=3 AND ttLedger.item_proc_compra_id=11 AND ttLedger.vl_lancto=300),'obligation from negotiated quantity').
 RUN Check(response:GetJsonArray('changes'):Length=3,'one obligation and two payment allocations').
 savedCalls=sequenceCalls. RUN Invoke. RUN Check(NOT failed AND sequenceCalls=savedCalls,'repeat update converges').
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=11. ttPurchaseItems.vl_negociado=4.
 RUN Invoke. RUN Check(NOT failed AND CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=3 AND ttLedger.vl_lancto=100),'only obligation difference appended').
 response:WriteFile('purchase-item-finance-update-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Seed. RUN ItemContext('purchase-item-update'). CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=71 ttContainerPayments.num_id_tit_ap=600.
 RUN Invoke. RUN Check(NOT failed AND orderCalls=0 AND response:GetJsonArray('changes'):Length=1,'nonempty container title ineligible for order rateio').
 RUN Seed. RUN ItemContext('purchase-item-update'). FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=FALSE. RUN Invoke.
 RUN Check(NOT failed AND sequenceCalls=0 AND orderCalls=0,'disabled forecast preserves ledger').
 RUN Seed. RUN ItemContext('purchase-item-update'). failAt=2. RUN Invoke.
 RUN Check(failed AND CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90) AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),'late ledger failure full rollback').
 RUN Seed. RUN ItemContext('purchase-item-update'). RUN Invoke. RUN ItemContext('purchase-item-delete'). RUN Invoke.
 RUN Check(NOT failed AND CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=3 AND ttLedger.item_proc_compra_id=11 AND ttLedger.vl_lancto=-300),'delete reverses obligation').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90) AND CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=4 AND ttLedger.num_id_tit_ap=500 AND ttLedger.vl_lancto=40),'delete reverses even unlinked historical payment title').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=4 AND ttLedger.item_proc_compra_id=13 AND ttLedger.vl_lancto=-25),'delete rerates remaining item').
 response:WriteFile('purchase-item-finance-delete-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=11. DELETE ttPurchaseItems.
 FOR EACH ttItems WHERE ttItems.item_proc_compra_id=11: DELETE ttItems. END.
 RUN ItemContext('purchase-item-update'). contextData:Set('item_proc_compra_id',13). RUN Invoke.
 RUN Check(NOT failed,'maintenance after physical delete accepts fully settled missing-owner history').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90),'closed deleted-item ledger remains durable').
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=91 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=999 ttLedger.num_id_tit_ap=600 ttLedger.cod_tipo_movto=4 ttLedger.vl_lancto=-2.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=92 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=999 ttLedger.num_id_tit_ap=600 ttLedger.item_container_id=99 ttLedger.cod_tipo_movto=4 ttLedger.vl_lancto=2.
 savedCalls=sequenceCalls. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,'ITEMS_FINANCE_ORPHAN_BALANCE')>0 AND sequenceCalls=savedCalls,'global zero cannot hide nonzero orphan owner groups; no writes').
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=92. ttLedger.item_container_id=0. RUN Invoke.
 RUN Check(NOT failed AND sequenceCalls=savedCalls,'exactly settled orphan group is ignored without writing or deleting history').
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=92. ttLedger.fornecedor_id=22. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,'ITEMS_FINANCE_ORPHAN_BALANCE')>0 AND sequenceCalls=savedCalls,'orphan settlement never nets different suppliers').
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=92. ASSIGN ttLedger.fornecedor_id=11 ttLedger.num_id_tit_ap=500. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,'ITEMS_FINANCE_ORPHAN_BALANCE')>0 AND sequenceCalls=savedCalls,'orphan settlement never nets different titles').
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=92. ttLedger.num_id_tit_ap=600.
 CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=999 ttPurchaseItems.proc_compra_id=0. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,'ITEMS_FINANCE_DATA')>0 AND sequenceCalls=savedCalls,'existing malformed owner remains strict even with settled ledger').


 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' checks ': ' e:GetMessage(1) ' / ' errorText SKIP. END CATCH.
END. OUTPUT CLOSE.
PROCEDURE Seed:
 DO TRANSACTION:
  EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttPurchaseItems. EMPTY TEMP-TABLE ttPurchases. EMPTY TEMP-TABLE ttLedger.
  EMPTY TEMP-TABLE ttOrderPayments. EMPTY TEMP-TABLE ttContainerPayments. EMPTY TEMP-TABLE ttAllContainers.
  CREATE ttAllContainers. ASSIGN ttAllContainers.nr-container=71 ttAllContainers.cod-emit-forn=99.
  CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=101 ttPurchases.fornecedor_id=11 ttPurchases.log_considerar_previsao=TRUE.
  CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=102 ttPurchases.fornecedor_id=22 ttPurchases.log_considerar_previsao=TRUE.
  CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=101 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_custo_dolar=2 ttPurchaseItems.vl_negociado=3.
  CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=12 ttPurchaseItems.proc_compra_id=102 ttPurchaseItems.qt_comprada=200 ttPurchaseItems.vl_custo_dolar=3 ttPurchaseItems.vl_negociado=4.
  CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=13 ttPurchaseItems.proc_compra_id=101 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_custo_dolar=1 ttPurchaseItems.vl_negociado=1.
  CREATE ttItems. ASSIGN ttItems.item_container_id=1 ttItems.container_id=71 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=10.
  CREATE ttItems. ASSIGN ttItems.item_container_id=2 ttItems.container_id=71 ttItems.item_proc_compra_id=12 ttItems.qt_alocada=20.
  CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=71 ttContainerPayments.num_id_tit_ap=500.
  CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=101 ttOrderPayments.num_id_tit_ap=600.
  CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=90 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=11 ttLedger.num_id_tit_ap=500 ttLedger.cod_tipo_movto=4 ttLedger.vl_lancto=-40.
 END.
 ASSIGN sequenceValue=1000 sequenceCalls=0 failAt=0 containerCalls=0 orderCalls=0 paymentMode=0 failed=FALSE errorText="".
 policy=NEW JsonObject(). beforeData=NEW JsonObject(). beforeData:Add("login","test-finance"). policy:Add("actor",beforeData).
END PROCEDURE.
FUNCTION ItemRow RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=NEW JsonObject(). o:Add("item_container_id",ttItems.item_container_id). o:Add("container_id",ttItems.container_id).
 o:Add("item_proc_compra_id",ttItems.item_proc_compra_id). o:Add("qt_alocada",ttItems.qt_alocada). o:Add("qt_confirm_emb",ttItems.qt_confirm_emb). RETURN o.
END FUNCTION.
PROCEDURE ContextFor:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 FIND ttItems WHERE ttItems.item_container_id=1.
 beforeData=ItemRow(). afterData=ItemRow().
 contextData=NEW JsonObject(). contextData:Add("operation",op). contextData:Add("container_id",71).
 IF op="create" THEN contextData:AddNull("before"). ELSE contextData:Add("before",beforeData).
 IF op="delete" THEN contextData:AddNull("after"). ELSE contextData:Add("after",afterData).
END PROCEDURE.
PROCEDURE Invoke:
 failed=FALSE. errorText="". response=?.
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTxn. ttTxn.marker=1.
  RUN Finance.
  DELETE ttTxn.
  CATCH e AS Progress.Lang.Error: ASSIGN failed=TRUE errorText=e:GetMessage(1). END CATCH.
 END.
END PROCEDURE.
PROCEDURE Finance:
 RUN ContainersItensFinanceiroService.p(INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,
  INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,
  THIS-PROCEDURE,policy,contextData,OUTPUT response).
END PROCEDURE.
PROCEDURE NextLedgerId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Sequence outside root transaction",1).
 sequenceCalls=sequenceCalls + 1. IF failAt=sequenceCalls THEN UNDO, THROW NEW Progress.Lang.AppError("Injected sequence failure",1).
 sequenceValue=sequenceValue + 1. valueId=sequenceValue.
END PROCEDURE.
PROCEDURE CollectContainerPayments:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 containerCalls=containerCalls + 1.
 IF NOT TRANSACTION OR master:BUFFER-FIELD("nr-container"):BUFFER-VALUE<>71 THEN UNDO, THROW NEW Progress.Lang.AppError("Unexpected master context",1).
 rows=NEW JsonArray().
 FOR EACH ttContainerPayments WHERE ttContainerPayments.container_id=71 BY ttContainerPayments.num_id_tit_ap:
  o=NEW JsonObject(). o:Add("num_id_tit_ap",ttContainerPayments.num_id_tit_ap). o:Add("vl_dolar",80). o:Add("vl_real",400). rows:Add(o).
 END.
 IF paymentMode=1 THEN rows=NEW JsonArray().
 IF paymentMode=2 THEN rows:Add(o).
 IF paymentMode=3 THEN o:SetNull("vl_dolar").
END PROCEDURE.
PROCEDURE CollectOrderPayments:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE orderId AS INTEGER NO-UNDO.
 orderCalls=orderCalls + 1. orderId=purchase:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE.
 rows=NEW JsonArray().
 FOR EACH ttOrderPayments WHERE ttOrderPayments.proc_compra_id=orderId BY ttOrderPayments.num_id_tit_ap:
  o=NEW JsonObject(). o:Add("num_id_tit_ap",ttOrderPayments.num_id_tit_ap). o:Add("vl_dolar",100). o:Add("vl_real",500). rows:Add(o).
 END.
 IF paymentMode=4 THEN rows=NEW JsonArray().
 IF paymentMode=5 THEN rows:Add(o).
 IF paymentMode=6 THEN o:SetNull("vl_dolar").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(messageText,1).
 checks=checks + 1.
END PROCEDURE.

PROCEDURE ItemContext:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 contextData=NEW JsonObject(). contextData:Add('operation',op). contextData:Add('proc_compra_id',101). contextData:Add('item_proc_compra_id',11).
 contextData:Add('before',NEW JsonObject()). contextData:Add('after',NEW JsonObject()).
END PROCEDURE.

/* Real undoable TT rows; only callbacks are trusted test doubles. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItensFinanceiroFixture.i}
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
OUTPUT TO VALUE("containers-itens-financeiro-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 RUN Seed. RUN ContextFor("create"). RUN Invoke.
 RUN Check(NOT failed,"create financial lifecycle succeeds").
 RUN Check(response:GetLogical("success") AND response:GetJsonArray("changes"):Length=3,"create reverses type4 then allocates two type5 rows").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(ttLedger.cod_tipo_movto=4 AND ttLedger.cod_acao=1 AND ttLedger.vl_lancto=40 AND ttLedger.item_container_id=0,"legacy title type4 reversal action and sign").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1002.
 RUN Check(ttLedger.cod_tipo_movto=5 AND ttLedger.cod_acao=1 AND ttLedger.vl_lancto=-20 AND ttLedger.fornecedor_id=11,"first item payment allocation supplier and amount").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1003.
 RUN Check(ttLedger.cod_tipo_movto=5 AND ttLedger.vl_lancto=-60 AND ttLedger.fornecedor_id=22,"different supplier from master is supported").
 RUN Check(response:GetJsonArray("changes"):GetJsonObject(1):GetJsonObject("after"):GetInteger("container_id")=71 AND ttLedger.transacao_id=0,"synthetic origin and legacy transaction zero").
 RUN ContextFor("update"). FIND ttItems WHERE ttItems.item_container_id=1. ttItems.qt_confirm_emb=8.
 afterData=ItemRow(). contextData:Set("after",afterData). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=3,"update allocation and shipped difference").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1004.
 RUN Check(ttLedger.cod_tipo_movto=5 AND ttLedger.vl_lancto=-60,"aggregate shipped denominator preserved").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1005.
 RUN Check(ttLedger.vl_lancto=-240,"per-item allocated fallback preserved").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1006.
 RUN Check(ttLedger.cod_tipo_movto=10 AND ttLedger.vl_lancto=-6 AND ttLedger.cod_acao=2 AND ttLedger.num_id_tit_ap=0,"type10 exact sign action and title zero").
 RUN ContextFor("update"). savedCalls=sequenceCalls. RUN Invoke.
 RUN Check(NOT failed AND sequenceCalls=savedCalls AND response:GetJsonArray("changes"):Length=0,"repeat update has no financial delta").
 RUN ContextFor("update"). FIND ttItems WHERE ttItems.item_container_id=1. ttItems.qt_confirm_emb=10.
 contextData:Set("after",ItemRow()). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("warnings"):Length=1,"equal quantity preserves previous type10 with explicit warning").

 RUN Seed. RUN ContextFor("create"). contextData:Set("before",NEW JsonObject()). RUN Invoke.
 RUN ContextFor("delete"). contextData:Set("after",NEW JsonObject()). FIND ttItems WHERE ttItems.item_container_id=1. DELETE ttItems. RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=4,"delete rebalances remaining items reverses item and allocates order").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1004.
 RUN Check(ttLedger.cod_tipo_movto=5 AND ttLedger.vl_lancto=-20,"remaining item receives allocation delta").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1005.
 RUN Check(ttLedger.cod_tipo_movto=6 AND ttLedger.vl_lancto=20 AND ttLedger.cod_acao=3 AND ttLedger.item_container_id=1,"deleted item reversal type6").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1006.
 RUN Check(ttLedger.cod_tipo_movto=4 AND ttLedger.vl_lancto=-75 AND ttLedger.item_container_id=0,"order negotiated purchased weight first item").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1007.
 RUN Check(ttLedger.vl_lancto=-25 AND ttLedger.item_proc_compra_id=13,"order allocation includes item outside container").
 RUN Check(containerCalls=2 AND orderCalls=1,"callbacks collected once per relevant owner").

 RUN Seed. FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=FALSE.
 RUN ContextFor("delete"). FIND ttItems WHERE ttItems.item_container_id=1. DELETE ttItems. RUN Invoke.
 RUN Check(NOT failed AND orderCalls=0,"disabled order forecast skips rerateio").
 RUN Seed. CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=71 ttContainerPayments.num_id_tit_ap=600.
 RUN ContextFor("delete"). FIND ttItems WHERE ttItems.item_container_id=1. DELETE ttItems. RUN Invoke.
 RUN Check(NOT failed AND orderCalls=0,"order title associated with nonempty container is ineligible").

 RUN Seed. FOR EACH ttPurchaseItems WHERE ttPurchaseItems.proc_compra_id=101: ttPurchaseItems.vl_negociado=0. END.
 RUN ContextFor("delete"). FIND ttItems WHERE ttItems.item_container_id=1. DELETE ttItems. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_ZERO_WEIGHT")>0 AND sequenceCalls=0,"zero order weight fails before IDs or writes").
 RUN Check(NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"planning failure writes nothing").
 RUN Seed. FOR EACH ttPurchaseItems: ttPurchaseItems.vl_custo_dolar=0. END.
 RUN ContextFor("update"). RUN Invoke.
 RUN Check(NOT failed AND sequenceCalls=0,"zero proforma follows explicit legacy zero branch").

 RUN Seed. RUN ContextFor("create"). failAt=2. RUN Invoke.
 RUN Check(failed AND sequenceCalls=2,"injected failure after first ledger mutation propagates").
 RUN Check(NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000) AND CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90),"root transaction rolls back every appended ledger").
 RUN Seed. RUN ContextFor("create"). sequenceValue=89. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_SEQUENCE")>0,"sequence collision cannot overwrite historical row").
 DO i=1 TO 3:
  RUN Seed. paymentMode=i. RUN ContextFor("create"). RUN Invoke.
  RUN Check(failed AND sequenceCalls=0,"incomplete duplicate or unknown callback amount fails before persistence").
 END.
 RUN Seed. RUN ContextFor("update"). contextData:Set("container_id",72). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_CONTEXT")>0,"snapshot scope mismatch rejected").
 RUN Seed. CREATE ttAllContainers. ttAllContainers.nr-container=72.
 CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=72 ttContainerPayments.num_id_tit_ap=500.
 RUN ContextFor("create"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_AMBIGUOUS")>0 AND sequenceCalls=0,"container title cannot ambiguously belong to two containers").
 RUN Seed. CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=101 ttOrderPayments.num_id_tit_ap=500.
 CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=102 ttOrderPayments.num_id_tit_ap=500.
 RUN ContextFor("create"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_AMBIGUOUS")>0 AND sequenceCalls=0,"container title cannot ambiguously belong to two orders").
 RUN Seed. FOR EACH ttPurchaseItems: ttPurchaseItems.vl_custo_dolar=1. END.
 FIND ttItems WHERE ttItems.item_container_id=1. ttItems.qt_alocada=1.
 FIND ttItems WHERE ttItems.item_container_id=2. ttItems.qt_alocada=2.
 RUN ContextFor("update"). RUN Invoke.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(NOT failed AND ttLedger.vl_lancto=-26.67,"allocation rounds at cents before physical write").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1002.
 RUN Check(ttLedger.vl_lancto=-53.33,"complement retains legacy independent rounding").
 RUN ContextFor("update"). FIND ttItems WHERE ttItems.item_container_id=1. ttItems.qt_alocada=0.
 contextData:Set("after",ItemRow()). RUN Invoke.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1003.
 RUN Check(NOT failed AND ttLedger.vl_lancto=26.67 AND ttLedger.cod_acao=3,"negative allocation delta is positive reversal action3").
 RUN Seed. RUN ContextFor("delete"). RUN Invoke.
 RUN Check(failed AND sequenceCalls=0,"delete requires physically removed item").
 RUN Seed. beforeData=policy:GetJsonObject("actor"). beforeData:Set("login",FILL("a",128)).
 RUN ContextFor("create"). RUN Invoke.
 RUN Check(NOT failed,"authenticated private login128 accepted").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(LENGTH(ttLedger.login)=128,"authenticated private login128 preserved beyond display format").
 RUN Seed. beforeData=policy:GetJsonObject("actor"). beforeData:Set("login",FILL("a",129)).
 RUN ContextFor("create"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_CONTEXT")>0 AND sequenceCalls=0,"authenticated private login129 rejected before write").
 RUN Seed. RUN ContextFor("update").
 DO ON ERROR UNDO, THROW:
  RUN Finance.
  RUN Check(FALSE,"outside transaction must fail").
  CATCH e AS Progress.Lang.Error: RUN Check(INDEX(e:GetMessage(1),"ITEMS_FINANCE_TRANSACTION")>0,"requires caller root transaction"). END CATCH.
 END.
 RUN PaymentOperations.
 RUN PurchaseOperations.
 RUN ForecastOperations.
 PUT UNFORMATTED "PASS " checks " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED "FAIL after " checks ": " e:GetMessage(1) " / " errorText SKIP. OUTPUT CLOSE. UNDO, THROW e. END CATCH.
END.
OUTPUT CLOSE.
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

PROCEDURE LinkContext:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 contextData=NEW JsonObject(). contextData:Add("operation",op). contextData:Add("container_id",71).
 rowData=NEW JsonObject(). rowData:Add("container_id",71). rowData:Add("num_id_tit_ap",500).
 IF op="associate" THEN DO: contextData:Add("before",NEW JsonObject()). contextData:Add("after",rowData). END.
 ELSE DO: contextData:Add("before",rowData). contextData:Add("after",NEW JsonObject()). END.
END PROCEDURE.
PROCEDURE SeedPaymentHistory:
 CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=101 ttOrderPayments.num_id_tit_ap=500.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=91 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=11 ttLedger.item_container_id=1 ttLedger.num_id_tit_ap=500 ttLedger.cod_tipo_movto=5 ttLedger.vl_lancto=-20.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=92 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=11 ttLedger.item_container_id=1 ttLedger.num_id_tit_ap=500 ttLedger.cod_tipo_movto=6 ttLedger.vl_lancto=5.
 /* Item9 is historical/global and absent from the current container. */
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=93 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=11 ttLedger.item_container_id=9 ttLedger.num_id_tit_ap=500 ttLedger.cod_tipo_movto=5 ttLedger.vl_lancto=-7.
END PROCEDURE.
PROCEDURE PaymentOperations:
 RUN Seed. RUN LinkContext("associate"). RUN Invoke.
 RUN Check(NOT failed,"associate accepts already inserted closed link snapshot").
 RUN Check(response:GetJsonArray("changes"):Length=3,"associate reuses reversal4 then allocation5").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(ttLedger.cod_tipo_movto=4 AND ttLedger.vl_lancto=40,"associate reverses prior type4").
 RUN Check(containerCalls=1 AND orderCalls=0,"associate central currency callback once").
 RUN Seed. CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=71 ttContainerPayments.num_id_tit_ap=501.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=91 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=13 ttLedger.num_id_tit_ap=501 ttLedger.cod_tipo_movto=4 ttLedger.vl_lancto=-12.
 RUN LinkContext("associate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=6,"associate reverses ALL container titles and allocates ALL titles").
 RUN Seed. EMPTY TEMP-TABLE ttItems. RUN LinkContext("associate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=1,"associate empty container only reverses existing4, no invented allocation").
 RUN Seed. FOR EACH ttPurchaseItems: ttPurchaseItems.vl_custo_dolar=0. END.
 RUN LinkContext("associate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=1,"associate zero proforma uses existing zero target branch").
 RUN Seed. RUN SeedPaymentHistory. RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=6,"disassociate global5+6 reversal and forced4 of all order titles").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(ttLedger.cod_tipo_movto=5 AND ttLedger.vl_lancto=15 AND ttLedger.cod_acao=3 AND ttLedger.item_container_id=1,"disassociate reverses SUM5+6 using new5 action3").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1002.
 RUN Check(ttLedger.cod_tipo_movto=5 AND ttLedger.vl_lancto=7 AND ttLedger.item_container_id=9,"disassociate includes global historical item outside current container").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1003.
 RUN Check(ttLedger.cod_tipo_movto=4 AND ttLedger.num_id_tit_ap=500 AND ttLedger.vl_lancto=-35,"force4 ignores current nonempty container eligibility before link deletion").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1006.
 RUN Check(ttLedger.cod_tipo_movto=4 AND ttLedger.num_id_tit_ap=600 AND ttLedger.vl_lancto=-25,"force4 includes other order title and noncontainer purchase item").
 RUN Check(containerCalls=0 AND orderCalls=1 AND CAN-FIND(ttContainerPayments WHERE ttContainerPayments.container_id=71 AND ttContainerPayments.num_id_tit_ap=500),"disassociate never allocates/converts C nor deletes link itself").
 RUN Check(NOT response:Has("audit") AND NOT response:Has("committed"),"financial participant never confirms root transaction audit").
 RUN Seed. RUN SeedPaymentHistory. FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=FALSE.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=2 AND orderCalls=0,"disassociate respects disabled forecast but still reverses5+6").
 RUN Seed. EMPTY TEMP-TABLE ttItems. RUN SeedPaymentHistory. RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=6,"disassociate empty container retains global reversal and forced order allocation").
 RUN Seed. RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=0 AND orderCalls=0,"unlinked-to-order title with no history has no invented money").
 RUN Seed. RUN SeedPaymentHistory. FOR EACH ttPurchaseItems WHERE ttPurchaseItems.proc_compra_id=101: ttPurchaseItems.vl_negociado=0. END.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_ZERO_WEIGHT")>0 AND sequenceCalls=0,"disassociate zero order weights fails entire plan before IDs").
 RUN Seed. RUN SeedPaymentHistory. CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=102 ttOrderPayments.num_id_tit_ap=500.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_AMBIGUOUS")>0 AND sequenceCalls=0,"disassociate title with two orders rejected").
 RUN Seed. CREATE ttAllContainers. ttAllContainers.nr-container=72. CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=72 ttContainerPayments.num_id_tit_ap=500.
 RUN LinkContext("associate"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_AMBIGUOUS")>0 AND sequenceCalls=0,"associate title with two container owners rejected").
 RUN Seed. RUN LinkContext("associate"). contextData:GetJsonObject("after"):Add("policy",TRUE). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_CONTEXT")>0,"link snapshot fields strictly closed").
 RUN Seed. FIND ttContainerPayments WHERE ttContainerPayments.num_id_tit_ap=500. DELETE ttContainerPayments. RUN LinkContext("associate"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_CONTEXT")>0 AND sequenceCalls=0,"associate requires actual inserted physical link").
 RUN Seed. RUN LinkContext("disassociate"). FIND ttContainerPayments WHERE ttContainerPayments.num_id_tit_ap=500. DELETE ttContainerPayments. RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_CONTEXT")>0 AND sequenceCalls=0,"disassociate requires link still present before deletion").
 RUN Seed. RUN SeedPaymentHistory. failAt=2. RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(failed AND sequenceCalls=2 AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"disassociate rollback removes first appended reversal when second ID fails").
 RUN Seed. RUN LinkContext("associate"). failAt=2. RUN Invoke.
 RUN Check(failed AND sequenceCalls=2 AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"associate rollback removes first reversal when second ID fails").
 RUN Seed. RUN SeedPaymentHistory.
 CREATE ttAllContainers. ttAllContainers.nr-container=72.
 CREATE ttItems. ASSIGN ttItems.item_container_id=3 ttItems.container_id=72 ttItems.item_proc_compra_id=13 ttItems.qt_alocada=1.
 CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=72 ttContainerPayments.num_id_tit_ap=600.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=6,"forced rerateio includes other order title held by another nonempty container").
 RUN Seed. RUN SeedPaymentHistory.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=92. ttLedger.vl_lancto=30.
 RUN LinkContext("disassociate"). RUN Invoke.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(NOT failed AND ttLedger.vl_lancto=-10 AND ttLedger.cod_tipo_movto=5 AND ttLedger.cod_acao=3,"global5+6 positive sum reverses sign without changing fixed action3").
 RUN Seed. RUN SeedPaymentHistory.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=92. ttLedger.vl_lancto=20.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=5,"net zero5+6 group emits no spurious zero ledger").
 DO i=4 TO 6:
  RUN Seed. RUN SeedPaymentHistory. paymentMode=i. RUN LinkContext("disassociate"). RUN Invoke.
  RUN Check(failed AND sequenceCalls=0 AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"invalid order currency callback cannot partially persist reversal").
 END.
 RUN Seed. RUN SeedPaymentHistory. CREATE ttAllContainers. ttAllContainers.nr-container=72.
 CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=72 ttContainerPayments.num_id_tit_ap=500.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_AMBIGUOUS")>0 AND sequenceCalls=0,"disassociate title with two containers rejected before any planned effect").
 RUN Seed. RUN LinkContext("associate"). contextData:GetJsonObject("after"):Set("container_id",72). RUN Invoke.
 RUN Check(failed AND INDEX(errorText,"ITEMS_FINANCE_CONTEXT")>0 AND sequenceCalls=0,"link context cannot select another parent").
 RUN Seed. RUN LinkContext("associate"). contextData:GetJsonObject("before"):Add("num_id_tit_ap",500). RUN Invoke.
 RUN Check(failed AND sequenceCalls=0,"associate before must be absent").
 RUN Seed. RUN LinkContext("disassociate"). contextData:GetJsonObject("after"):Add("num_id_tit_ap",500). RUN Invoke.
 RUN Check(failed AND sequenceCalls=0,"disassociate after must be absent").
 RUN Seed. RUN LinkContext("associate"). contextData:GetJsonObject("after"):Set("num_id_tit_ap",500.5). RUN Invoke.
 RUN Check(failed AND sequenceCalls=0,"link IDs remain integral numeric values").
 RUN Seed. RUN SeedPaymentHistory. FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=?.
 RUN LinkContext("disassociate"). RUN Invoke.
 RUN Check(failed AND sequenceCalls=0,"unknown forecast flag cannot invent forced order allocation").
 RUN Seed. RUN LinkContext("associate"). FIND ttContainerPayments WHERE ttContainerPayments.num_id_tit_ap=500. DELETE ttContainerPayments. failAt=2.
 failed=FALSE.
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=71 ttContainerPayments.num_id_tit_ap=500.
  RUN Finance.
  CATCH e AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
 RUN Check(failed AND NOT CAN-FIND(ttContainerPayments WHERE ttContainerPayments.num_id_tit_ap=500) AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"caller transaction rolls back inserted link AND earlier ledger when participant fails").
 RUN Seed. RUN SeedPaymentHistory. RUN LinkContext("disassociate"). failed=FALSE.
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN Finance.
  FIND ttContainerPayments WHERE ttContainerPayments.num_id_tit_ap=500. DELETE ttContainerPayments.
  UNDO, THROW NEW Progress.Lang.AppError("Injected later root failure",1).
  CATCH e AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
 RUN Check(failed AND CAN-FIND(ttContainerPayments WHERE ttContainerPayments.num_id_tit_ap=500) AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"later root failure rolls back deassociated link AND every financial plan").
 RUN Seed. RUN SeedPaymentHistory.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=94 ttLedger.fornecedor_id=22 ttLedger.item_proc_compra_id=12 ttLedger.item_container_id=44 ttLedger.num_id_tit_ap=500 ttLedger.cod_tipo_movto=6 ttLedger.vl_lancto=6.
 RUN LinkContext("disassociate"). RUN Invoke.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1003.
 RUN Check(NOT failed AND response:GetJsonArray("changes"):Length=7 AND ttLedger.cod_tipo_movto=5 AND ttLedger.vl_lancto=-6 AND ttLedger.fornecedor_id=22 AND ttLedger.item_proc_compra_id=12 AND ttLedger.item_container_id=44,"GLOBAL unlink preserves other supplier purchase and historical item group").
 RUN Seed. RUN LinkContext("associate"). RUN Invoke. savedCalls=sequenceCalls. RUN Invoke.
 RUN Check(NOT failed AND sequenceCalls=savedCalls AND response:GetJsonArray("changes"):Length=0,"repeat associate financial plan has no duplicate zero deltas").
 RUN Seed. RUN SeedPaymentHistory. RUN LinkContext("disassociate"). RUN Invoke. savedCalls=sequenceCalls. RUN Invoke.
 RUN Check(NOT failed AND sequenceCalls=savedCalls AND response:GetJsonArray("changes"):Length=0,"repeat disassociate financial plan converges without duplicate deltas").
END PROCEDURE.

PROCEDURE OrderContext:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 contextData=NEW JsonObject(). contextData:Add("operation",op). contextData:Add("proc_compra_id",101).
 rowData=NEW JsonObject(). rowData:Add("proc_compra_id",101). rowData:Add("num_id_tit_ap",600).
 IF op="order-associate" THEN DO: contextData:Add("before",NEW JsonObject()). contextData:Add("after",rowData). END.
 ELSE DO: contextData:Add("before",rowData). contextData:Add("after",NEW JsonObject()). END.
END PROCEDURE.
PROCEDURE PurchaseOperations:
 RUN Seed. FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=FALSE.
 RUN OrderContext("order-associate"). RUN Invoke.
 RUN Check(NOT failed,"order-associate uses shared financial participant regardless forecast flag").
 RUN Check(response:GetJsonArray("changes"):Length=2 AND containerCalls=0 AND orderCalls=1,"only order type4 plans, single reused currency collection").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(ttLedger.cod_tipo_movto=4 AND ttLedger.vl_lancto=-75 AND ttLedger.login="test-finance","order allocation negotiated weight and authenticated actor").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1002.
 RUN Check(ttLedger.vl_lancto=-25 AND ttLedger.item_container_id=0,"order allocation includes unallocated item").
 rowData=response:GetJsonArray("changes"):GetJsonObject(1):GetJsonObject("after").
 RUN Check(rowData:GetInteger("proc_compra_id")=101 AND NOT rowData:Has("container_id"),"order audit scope without false container").
 savedCalls=sequenceCalls. RUN Invoke. RUN Check(NOT failed AND sequenceCalls=savedCalls,"order association allocation converges").
 RUN OrderContext("order-disassociate"). RUN Invoke.
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1003.
 RUN Check(NOT failed AND ttLedger.vl_lancto=75 AND ttLedger.cod_acao=3,"order disassociation reverses previous selected-title balance").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1004. RUN Check(ttLedger.vl_lancto=25,"order reversal all current items").
 RUN Seed. FOR EACH ttPurchaseItems WHERE ttPurchaseItems.proc_compra_id=101: ttPurchaseItems.vl_negociado=0. END.
 RUN OrderContext("order-associate"). RUN Invoke. RUN Check(failed AND sequenceCalls=0,"zero purchase weight rejected before any write").
 RUN Seed. RUN OrderContext("order-associate"). failAt=2. RUN Invoke.
 RUN Check(failed AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),"order root rollback removes first written ledger").
 RUN Seed. FIND ttOrderPayments WHERE ttOrderPayments.num_id_tit_ap=600. DELETE ttOrderPayments.
 RUN OrderContext("order-associate"). RUN Invoke. RUN Check(failed AND sequenceCalls=0,"financial participant requires physical order link").
 RUN Seed. RUN OrderContext("order-associate"). contextData:GetJsonObject("after"):Set("proc_compra_id",102). RUN Invoke.
 RUN Check(failed AND sequenceCalls=0,"order snapshot cannot target different parent").
END PROCEDURE.
PROCEDURE ForecastOperations:
 RUN Seed. contextData=NEW JsonObject(). contextData:Add('operation','order-enable'). contextData:Add('proc_compra_id',101). RUN Invoke.
 RUN Check(NOT failed,'order-enable reusable reconstruction succeeds'). response:WriteFile('purchase-order-finance-enable-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Check(NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90),'enable deletes only own old type>2 rows').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=3 AND ttLedger.item_proc_compra_id=11 AND ttLedger.vl_lancto=300),'obligation uses negotiated purchased weight').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=3 AND ttLedger.item_proc_compra_id=13 AND ttLedger.vl_lancto=100),'unallocated purchase item obligation included').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=5 AND ttLedger.item_proc_compra_id=12 AND ttLedger.fornecedor_id=22),'refresh related container includes cross-order item with real owner').
 RUN Check(response:GetJsonArray('changes'):GetJsonObject(1):GetCharacter('operation')='delete','physical delete is audited before reconstructed rows').
 RUN Seed. FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=FALSE. contextData=NEW JsonObject(). contextData:Add('operation','order-disable'). contextData:Add('proc_compra_id',101). RUN Invoke.
 RUN Check(NOT failed AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90) AND sequenceCalls=0,'disable only deletes own>2, no rerateio'). response:WriteFile('purchase-order-finance-disable-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Seed. contextData=NEW JsonObject(). contextData:Add('operation','order-enable'). contextData:Add('proc_compra_id',101). failAt=4. RUN Invoke.
 RUN Check(failed AND CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90) AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),'late enable error rolls back deletions and every generated row').
END PROCEDURE.
PROCEDURE RefreshOrderContainers:
 DEFINE INPUT PARAMETER orderId AS INTEGER NO-UNDO. DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE refreshContext AS JsonObject NO-UNDO.
 refreshContext=NEW JsonObject(). refreshContext:Add('operation','refresh-container'). refreshContext:Add('container_id',71).
 RUN ContainersItensFinanceiroService.p(INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,THIS-PROCEDURE,policy,refreshContext,OUTPUT result).
END PROCEDURE.



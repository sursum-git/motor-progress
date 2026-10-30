/* Internal adapter and undoable transaction marker only. No real sequences,
   business tables, HTTP credential or execution-log persistence is used. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttMaster NO-UNDO FIELD nr-container AS INTEGER
 FIELD vl-dolar-compra AS DECIMAL FIELD vl_dolar_di AS DECIMAL
 FIELD ordem_busca_dolar_compra AS CHARACTER FIELD ordem_busca_dolar_di AS CHARACTER
 FIELD cod_tipo_proj_dolar AS INTEGER FIELD vl_proj_dolar AS DECIMAL.
DEFINE TEMP-TABLE ttTxn FIELD marker AS INTEGER.
DEFINE TEMP-TABLE ttExpense NO-UNDO FIELD despesa_container_id AS INTEGER FIELD container_id AS INTEGER FIELD item_container_id AS INTEGER
 FIELD cta_corren_custo_distr_id AS INTEGER FIELD vl_prev AS DECIMAL.
DEFINE TEMP-TABLE ttLedger NO-UNDO FIELD cta_corren_custo_distr_id AS INTEGER FIELD cod_tipo_movto AS INTEGER
 FIELD item_container_id AS INTEGER FIELD item_container_custo_id AS INTEGER FIELD despesa_container_id AS INTEGER FIELD vl_lancto AS DECIMAL INDEX pk IS UNIQUE PRIMARY cta_corren_custo_distr_id.
DEFINE TEMP-TABLE ttItem NO-UNDO FIELD item_container_id AS INTEGER FIELD container_id AS INTEGER INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttCost NO-UNDO FIELD item_container_custo_id AS INTEGER FIELD item_container_id AS INTEGER FIELD versao_id AS INTEGER INDEX pk IS UNIQUE PRIMARY item_container_custo_id.
DEFINE TEMP-TABLE ttVersion NO-UNDO FIELD versao_id AS INTEGER FIELD container_id AS INTEGER INDEX pk IS UNIQUE PRIMARY versao_id.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE fakeMode AS CHARACTER NO-UNDO.
DEFINE VARIABLE lastResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
DEFINE VARIABLE errorText AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE observedId AS INTEGER NO-UNDO.
DEFINE VARIABLE mathInput AS JsonObject NO-UNDO.
DEFINE VARIABLE mathResult AS JsonObject NO-UNDO.
DEFINE VARIABLE dContrast AS DECIMAL NO-UNDO.
RUN ContainersCabecalhoRuntime.p PERSISTENT SET runtime(THIS-PROCEDURE).
parser=NEW ObjectModelParser().
CREATE ttMaster.
ASSIGN ttMaster.nr-container=123 ttMaster.vl-dolar-compra=5 ttMaster.vl_dolar_di=5
 ttMaster.ordem_busca_dolar_compra="3,2" ttMaster.ordem_busca_dolar_di="3,4" ttMaster.cod_tipo_proj_dolar=1 ttMaster.vl_proj_dolar=0.
OUTPUT TO VALUE("containers-cabecalho-runtime-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 /* The private callbacks must fail before consuming a real sequence here. */
 failed=FALSE.
 DO ON ERROR UNDO, THROW:
  RUN NextCalculoId IN runtime(OUTPUT observedId).
  CATCH err AS Progress.Lang.Error: ASSIGN failed=TRUE errorText=err:GetMessage(1). END CATCH.
 END.
 RUN Check(failed AND INDEX(errorText,"CONTAINER_TRANSACTION_CONTEXT")=1,"sequence callback requires caller transaction before any NEXT-VALUE").
 failed=FALSE.
 DO ON ERROR UNDO, THROW:
  RUN NextDespesaId IN runtime(OUTPUT observedId).
  CATCH err AS Progress.Lang.Error: ASSIGN failed=TRUE errorText=err:GetMessage(1). END CATCH.
 END.
 RUN Check(failed AND INDEX(errorText,"CONTAINER_TRANSACTION_CONTEXT")=1,"expense sequence callback also fails before consuming any NEXT-VALUE").
 failed=FALSE.
 DO ON ERROR UNDO, THROW:
  RUN CollectCalculationInputs IN runtime(INPUT BUFFER ttMaster:HANDLE,OUTPUT result).
  CATCH err AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
 RUN Check(failed,"collector requires outer transaction").
 fakeMode="valid". RUN Invoke.
 RUN Check(NOT failed,"collect succeeds under caller transaction").
 RUN Check(lastResource="cotacoes-fiscais","fiscal uses reusable quote inputs without requiring a costable item").
 RUN Check(result:GetLogical("confirmed") AND result:GetCharacter("source")="container-cost-collector","confirmed private source").
 RUN Check(result:GetInteger("container_id")=123,"source parent is exact master").
 RUN Check(result:GetDecimal("dolar_compra")=4.8 AND result:GetDecimal("dolar_di")=4.8,"priority3 fiscal rates come from unadjusted trace").
 RUN Check(result:GetJsonObject("container_snapshot"):GetDecimal("vl-dolar-compra")=5,"physical master rate is distinct from resolved rate").
 RUN Check(result:GetJsonObject("container_snapshot"):GetCharacter("ordem_busca_dolar_compra")="3,2","snapshot preserves raw priority list").
 /* Contrast invokes the actual pure calculator: comparatives add300 whereas
    fiscal buscarDolarMedio(container) uses the default logSaldoNeg=false. */
 RUN MathFixture(OUTPUT mathInput). mathInput:Set("mode","comparativos").
 RUN ContainersCustoCalculator.r(mathInput,OUTPUT mathResult).
 dContrast=mathResult:GetJsonObject("data"):GetDecimal("dolar_medio").
 RUN Check(dContrast=4.84615 AND dContrast<>result:GetDecimal("dolar_compra"),"comparative average would alter fiscal priority3").
 /* Read again, with a changed raw master; no cached snapshot/input. */
 ttMaster.vl-dolar-compra=6. fakeMode="valid". RUN Invoke.
 RUN Check(NOT failed AND result:GetJsonObject("container_snapshot"):GetDecimal("vl-dolar-compra")=6,"fresh header snapshot per callback").
 ttMaster.vl-dolar-compra=5.
 fakeMode="no-items". RUN Invoke.
 RUN Check(NOT failed AND result:GetDecimal("dolar_compra")=5 AND result:GetDecimal("dolar_di")=5,"last deallocation uses persisted rate fallbacks with zero items/payments").
 fakeMode="zero-quantity". RUN Invoke.
 RUN Check(NOT failed AND result:GetDecimal("dolar_compra")=4 AND result:GetDecimal("dolar_di")=4,"zero-quantity maintenance uses confirmed payment average without unit cost division").
 fakeMode="failure". RUN Invoke. RUN Check(failed AND NOT VALID-OBJECT(result),"reader failure propagates without confirmed inputs").
 fakeMode="wrong-parent". RUN Invoke. RUN Check(failed,"reader request source parent cannot change").
 fakeMode="bad-source". RUN Invoke. RUN Check(failed,"unknown calculation source rejected").
 fakeMode="bad-financial". RUN Invoke. RUN Check(failed,"unconfirmed financial origin rejected").
 fakeMode="empty". RUN Invoke. RUN Check(failed,"empty cost response does not invent rates").
 fakeMode="zero". RUN Invoke. RUN Check(failed,"last attempt zero rejected without using previous attempt").
 fakeMode="last-positive". RUN Invoke. RUN Check(NOT failed AND result:GetDecimal("dolar_compra")=6,"last attempt wins over earlier positive value").
 fakeMode="negative". RUN Invoke. RUN Check(failed,"negative rate rejected").
 fakeMode="string". RUN Invoke. RUN Check(failed,"numeric string rate rejected").
 fakeMode="missing". RUN Invoke. RUN Check(failed,"missing DI attempts rejected").
 fakeMode="stale". RUN Invoke. RUN Check(failed,"master mutation during reader call rejected").
 ttMaster.vl-dolar-compra=5.
 fakeMode="stale-parent". RUN Invoke. RUN Check(failed,"master identity cannot change during collection").
 ttMaster.nr-container=123.
 ttMaster.vl_dolar_di=?. fakeMode="valid". RUN Invoke. RUN Check(failed,"unknown physical rate cannot form confirmed snapshot").
 ttMaster.vl_dolar_di=5.
 fakeMode="parity". RUN Invoke. RUN Check(NOT failed AND result:GetDecimal("dolar_compra")=1,"explicit last parity is preserved as in pure calculator").
 RUN LogRule IN runtime("info","Fixture sem contexto autenticado nao persiste log.").
 RUN Check(TRUE,"manual logger outside request context is harmless").
 RUN DistributionTests.
 PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
 CATCH err AS Progress.Lang.Error: PUT UNFORMATTED "FAIL " err:GetMessage(1) SKIP. UNDO, THROW err. END CATCH.
 FINALLY: IF VALID-HANDLE(runtime) THEN DELETE PROCEDURE runtime. END FINALLY.
END.
OUTPUT CLOSE.
PROCEDURE Invoke:
 failed=FALSE. result=?.
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTxn. ttTxn.marker=1.
  RUN CollectCalculationInputs IN runtime(INPUT BUFFER ttMaster:HANDLE,OUTPUT result).
  DELETE ttTxn.
  CATCH err AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
END PROCEDURE.
PROCEDURE ReadContainerCost:
 DEFINE INPUT PARAMETER request AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER response AS JsonObject NO-UNDO.
 DEFINE VARIABLE calc AS JsonObject NO-UNDO.
 DEFINE VARIABLE memory AS JsonObject NO-UNDO.
 DEFINE VARIABLE row AS JsonObject NO-UNDO.
 DEFINE VARIABLE rows AS JsonArray NO-UNDO.
 lastResource=request:GetCharacter("resource").
 IF request:GetInteger("container_id")<>123 OR request:GetCharacter("operation")<>"read" OR request:GetCharacter("moeda")<>"real" THEN UNDO, THROW NEW Progress.Lang.AppError("Unexpected private request",1).
 IF fakeMode="failure" THEN DO:
  response=CAST(parser:Parse('~{"success":false,"error":~{"code":"COST_DATA_INCOMPLETE","message":"Fixture incompleta"}}'),JsonObject). RETURN.
 END.
 RUN MathFixture(OUTPUT mathInput). mathInput:Set("mode",IF lastResource="cotacoes-fiscais" THEN "fiscal_inputs" ELSE lastResource).
 IF fakeMode="no-items" THEN DO:
  mathInput:Set("items",NEW JsonArray()). mathInput:GetJsonObject("payments"):Set("real",0). mathInput:GetJsonObject("payments"):Set("dolar",0).
 END.
 IF fakeMode="zero-quantity" THEN DO:
  mathInput:GetJsonArray("items"):GetJsonObject(1):Set("qt_alocada",0). mathInput:GetJsonArray("items"):GetJsonObject(1):Set("qt_confirm_emb",0).
 END.
 RUN ContainersCustoCalculator.r(mathInput,OUTPUT mathResult).
 IF NOT mathResult:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Pure fixture failed",1).
 memory=CAST(mathResult:GetJsonObject("data"):GetJsonObject("memory"):Clone(),JsonObject).
 calc=NEW JsonObject(). calc:Add("source","calc_v1"). calc:Add("financial_source","linked-payment-totals"). calc:Add("memory",memory).
 row=NEW JsonObject(). row:Add("container_id",IF fakeMode="wrong-parent" THEN 124 ELSE 123). rows=NEW JsonArray(). rows:Add(row).
 response=NEW JsonObject(). response:Add("success",TRUE). response:Add("data",rows). response:Add("calculation",calc).
 CASE fakeMode:
  WHEN "bad-source" THEN calc:Set("source","invented").
  WHEN "bad-financial" THEN calc:Set("financial_source","filtered-grid").
  WHEN "empty" THEN response:Set("data",NEW JsonArray()).
  WHEN "zero" THEN DO:
   row=NEW JsonObject(). row:Add("priority",2). row:Add("value",0). row:Add("accepted",FALSE).
   memory:GetJsonArray("compra_attempts"):Add(row).
  END.
  WHEN "last-positive" THEN DO:
   row=NEW JsonObject(). row:Add("priority",2). row:Add("value",6). row:Add("accepted",TRUE).
   memory:GetJsonArray("compra_attempts"):Add(row).
  END.
  WHEN "negative" THEN memory:GetJsonArray("di_attempts"):GetJsonObject(1):Set("value",-1).
  WHEN "string" THEN memory:GetJsonArray("di_attempts"):GetJsonObject(1):Set("value","5").
  WHEN "missing" THEN memory:Remove("di_attempts").
  WHEN "stale" THEN ttMaster.vl-dolar-compra=9.
  WHEN "stale-parent" THEN ttMaster.nr-container=124.
  WHEN "parity" THEN DO:
   memory:GetJsonArray("compra_attempts"):GetJsonObject(1):Set("value",1).
   memory:GetJsonArray("compra_attempts"):GetJsonObject(1):Set("accepted",FALSE).
  END.
 END CASE.
END PROCEDURE.
PROCEDURE MathFixture:
 DEFINE OUTPUT PARAMETER inputData AS JsonObject NO-UNDO.
 inputData=CAST(parser:Parse('~{"mode":"rastro","currency":"real","calculationBasis":"current","container":~{"nr-container":123,"ordem_busca_dolar_compra":"3,2","ordem_busca_dolar_di":"3,4","cod_tipo_proj_dolar":1,"vl_proj_dolar":0,"vl-dolar-compra":5,"vl_dolar_di":5,"log_versao_custo_desatualizada":false},"quotation":~{"valor":5,"data":"2026-10-16"},"payments":~{"real":800,"dolar":200},"discounts":~{"credito_real":0,"credito_dolar":0,"total_real":0,"total_dolar":0},"expenses":~{"tributado":0,"proforma":0,"negociado":0},"items":[~{"item_container_id":1,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":0,"vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":120,"despesa_item":~{"tributado":0,"proforma":0,"negociado":0},"distribuicao_real":0,"desconto_real":0,"desconto_dolar":0,"erp_real":null}]}'),JsonObject).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(messageText,1).
 checks=checks + 1.
END PROCEDURE.

PROCEDURE DistributionBuffers:
 DEFINE OUTPUT PARAMETER ledger AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER item AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER cost AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER version AS HANDLE NO-UNDO.
 ASSIGN ledger=BUFFER ttLedger:HANDLE item=BUFFER ttItem:HANDLE cost=BUFFER ttCost:HANDLE version=BUFFER ttVersion:HANDLE.
END PROCEDURE.
PROCEDURE DistributionInvoke:
 failed=FALSE. result=?.
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTxn. ttTxn.marker=1.
  RUN ValidateDistributionExpense IN runtime(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttExpense:HANDLE,OUTPUT result).
  DELETE ttTxn.
  CATCH err AS Progress.Lang.Error: ASSIGN failed=TRUE errorText=err:GetMessage(1). END CATCH.
 END.
END PROCEDURE.
PROCEDURE DistributionTests:
 CREATE ttExpense. ASSIGN ttExpense.despesa_container_id=701 ttExpense.container_id=123 ttExpense.item_container_id=81 ttExpense.cta_corren_custo_distr_id=91 ttExpense.vl_prev=-10.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_custo_distr_id=91 ttLedger.cod_tipo_movto=4 ttLedger.item_container_id=81 ttLedger.vl_lancto=-10.
 CREATE ttItem. ASSIGN ttItem.item_container_id=81 ttItem.container_id=123.
 CREATE ttCost. ASSIGN ttCost.item_container_custo_id=101 ttCost.item_container_id=81 ttCost.versao_id=111.
 CREATE ttVersion. ASSIGN ttVersion.versao_id=111 ttVersion.container_id=123.
 RUN DistributionInvoke. RUN Check(NOT failed,"type4 direct item distribution confirmed").
 RUN Check(result:GetLogical("confirmed") AND result:GetInteger("container_id")=123 AND result:GetInteger("despesa_container_id")=701 AND result:GetInteger("ledger_id")=91,"distribution proof returns exact PK context").
 ASSIGN ttLedger.cod_tipo_movto=3 ttLedger.item_container_id=0 ttLedger.item_container_custo_id=101 ttLedger.vl_lancto=20 ttExpense.vl_prev=20.
 RUN DistributionInvoke. RUN Check(NOT failed,"type3 cost version owner confirmed without legacy empty backlink").
 ttVersion.container_id=999. RUN DistributionInvoke. RUN Check(failed,"foreign version owner rejected"). ttVersion.container_id=123.
 ttCost.item_container_id=82. RUN DistributionInvoke. RUN Check(failed,"cost item must match expense target"). ttCost.item_container_id=81.
 ttItem.container_id=999. RUN DistributionInvoke. RUN Check(failed,"foreign direct item rejected even with local version"). ttItem.container_id=123.
 ttLedger.cod_tipo_movto=2. RUN DistributionInvoke. RUN Check(failed,"other ledger movement types cannot justify duplicate"). ttLedger.cod_tipo_movto=3.
 ttLedger.item_container_id=81. RUN DistributionInvoke. RUN Check(failed,"mixed type3 links rejected"). ttLedger.item_container_id=0.
 ttExpense.vl_prev=21. RUN DistributionInvoke. RUN Check(failed,"amount must match ledger movement"). ttExpense.vl_prev=20.
 ttLedger.despesa_container_id=999. RUN DistributionInvoke. RUN Check(failed,"nonzero contradictory backlink rejected"). ttLedger.despesa_container_id=0.
 ttExpense.container_id=999. RUN DistributionInvoke. RUN Check(failed,"foreign expense parent rejected"). ttExpense.container_id=123.
 ttExpense.cta_corren_custo_distr_id=999. RUN DistributionInvoke. RUN Check(failed,"orphan ledger rejected"). ttExpense.cta_corren_custo_distr_id=91.
 ttCost.versao_id=999. RUN DistributionInvoke. RUN Check(failed,"orphan version rejected"). ttCost.versao_id=111.
 ttExpense.item_container_id=0. RUN DistributionInvoke. RUN Check(failed,"expense target item must be positive"). ttExpense.item_container_id=81.
 ttExpense.despesa_container_id=0. RUN DistributionInvoke. RUN Check(failed,"expense PK must be positive"). ttExpense.despesa_container_id=701.
 ttLedger.vl_lancto=?. RUN DistributionInvoke. RUN Check(failed,"unknown ledger amount rejected"). ttLedger.vl_lancto=20.
 ASSIGN ttLedger.cod_tipo_movto=4 ttLedger.item_container_id=81 ttLedger.item_container_custo_id=101.
 RUN DistributionInvoke. RUN Check(failed,"type4 mixed cost link rejected").
 ASSIGN ttLedger.cod_tipo_movto=3 ttLedger.item_container_id=0 ttLedger.item_container_custo_id=101.
 failed=FALSE.
 DO ON ERROR UNDO, THROW:
  RUN ValidateDistributionExpense IN runtime(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttExpense:HANDLE,OUTPUT result).
  CATCH err AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
 RUN Check(failed,"proof requires active root transaction").
END PROCEDURE.


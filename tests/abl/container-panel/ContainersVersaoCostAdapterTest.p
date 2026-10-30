/* Real collector fixtures shared with its own suite. No DB or sequence. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE oReq AS JsonObject NO-UNDO.
DEFINE VARIABLE oFin AS JsonObject NO-UNDO.
DEFINE VARIABLE oPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE rowReal AS JsonObject NO-UNDO.
DEFINE VARIABLE rowDollar AS JsonObject NO-UNDO.
DEFINE VARIABLE copiedInput AS JsonObject NO-UNDO.
DEFINE VARIABLE replay AS JsonObject NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE containerInput AS INTEGER NO-UNDO INITIAL 123.
RUN Fixture. oFin:Set("source","linked-payment-totals").
RUN Invoke.
RUN Check(result:GetLogical("success"),"private version snapshot succeeds").
data=result:GetJsonObject("data").
RUN Check(data:GetLogical("confirmed") AND data:GetCharacter("source")="container-version-cost-snapshot","confirmed computation has explicit private origin").
RUN Check(data:GetLogical("actual_complete"),"all realized components exist").
rowReal=data:GetJsonArray("items_real"):GetJsonObject(1). rowDollar=data:GetJsonArray("items_dolar"):GetJsonObject(1).
RUN Eq(rowReal:GetDecimal("vl_total_prev"),4130,"snapshot negotiated predicted BRL").
RUN Eq(rowReal:GetDecimal("vl_total_real"),1070,"snapshot actual BRL").
RUN Eq(rowDollar:GetDecimal("vl_total_prev"),826,"same snapshot predicted USD").
RUN Eq(rowDollar:GetDecimal("vl_total_real"),214,"same snapshot actual USD").
RUN Check(rowReal:GetInteger("item_container_id")=rowDollar:GetInteger("item_container_id"),"currency sets pair by item id").
RUN Check(NOT oPolicy:Has("calculation_profile") AND NOT oPolicy:Has("capture_input"),"adapter does not mutate caller policy").
RUN Check(data:GetJsonObject("input_snapshot"):GetCharacter("currency")="real","shared input remains real after USD clone").
RUN Check(data:GetJsonObject("input_snapshot"):GetCharacter("mode")="gerar_versao","trace clone does not mutate source generation mode").
/* Change all live fixture prices after capture. Pure replay must reproduce USD
   from captured inputs without returning to the source buffers. */
hb[3]:FIND-FIRST(). hb[3]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=999.
copiedInput=CAST(data:GetJsonObject("input_snapshot"):Clone(),JsonObject). copiedInput:Set("currency","dolar").
RUN ContainersCustoCalculator.r(copiedInput,OUTPUT replay).
RUN Eq(replay:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_total_prev"),826,"captured input replays after live buffers change").
RUN Fixture. oFin:Set("source","linked-payment-totals").
RUN Seed(9,'~{"cta_corren_custo_distr_id":1,"item_container_id":1,"cod_tipo_movto":4,"vl_lancto":100}').
RUN Invoke. data=result:GetJsonObject("data").
RUN Eq(data:GetJsonArray("items_real"):GetJsonObject(1):GetDecimal("vl_total_prev"),4130,"snapshot does not apply distribution movement").
RUN Eq(data:GetJsonArray("items_real"):GetJsonObject(1):GetDecimal("vl_total_prev_sem_distr_custo"),4130,"snapshot no-distribution secondary field").
/* Multiple independent ERP groups are matched by the persistent child id. */
RUN Fixture. oFin:Set("source","linked-payment-totals").
RUN Seed(2,'~{"item_container_id":7,"container_id":123,"item_proc_compra_id":2,"qt_alocada":20,"qt_confirm_emb":20,"qt_recbto_fisico":20}').
RUN Seed(3,'~{"item_proc_compra_id":2,"proc_compra_id":1,"descricao":"Item sete","codigo_erp":"ERP7","vl_base_tributacao":50,"vl_custo_dolar":45,"vl_negociado":40}').
RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","it-codigo":"ERP7","sequencia":2,"quantidade":20,"preco-total":1000,"despesas":20,"val-cofins":0,"val-aliq-cofins":0,"valor-pis":0,"val-aliq-pis":0}').
RUN Invoke. data=result:GetJsonObject("data").
RUN Check(data:GetJsonArray("items_real"):Length=2 AND data:GetJsonArray("items_dolar"):Length=2,"same complete child set in both currencies").
RUN Check(data:GetJsonArray("items_real"):GetJsonObject(2):GetInteger("item_container_id")=7 AND data:GetJsonArray("items_dolar"):GetJsonObject(2):GetInteger("item_container_id")=7,"persistent id remains aligned in normalized arrays").
RUN Eq(data:GetJsonArray("items_real"):GetJsonObject(2):GetDecimal("vl_total_real"),520,"last ERP group retained in version BRL").
RUN Eq(data:GetJsonArray("items_dolar"):GetJsonObject(2):GetDecimal("vl_total_real"),104,"last ERP group retained in version USD").
/* Header mean has a distinct default-false source from item cost mean. */
RUN Fixture. oFin:Set("source","linked-payment-totals").
oFin:GetJsonObject("payments"):Set("real",800).
hb[3]:FIND-FIRST(). hb[3]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=120.
hb[1]:FIND-FIRST(). hb[1]:BUFFER-FIELD("ordem_busca_dolar_compra"):BUFFER-VALUE="3,2".
hb[1]:BUFFER-FIELD("ordem_busca_dolar_di"):BUFFER-VALUE="3,4".
hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE.
RUN Invoke. data=result:GetJsonObject("data").
RUN Eq(data:GetJsonArray("items_real"):GetJsonObject(1):GetDecimal("dolar_medio"),4.84615,"version items preserve truthy negotiated adjustment").
RUN Eq(data:GetJsonObject("master_average"):GetDecimal("dolar_medio"),4.8,"version header uses default-false trace mean").
RUN Eq(data:GetJsonObject("master_average"):GetJsonObject("memory"):GetDecimal("ajuste_negociado_proforma"),0,"header mean records no negotiated adjustment").
RUN Check(result:GetLogical("success"),"generating a new version accepts currently stale previous version").
/* Missing ERP does not become a completed zero realized snapshot. */
RUN Fixture. oFin:Set("source","linked-payment-totals"). ht[16]:EMPTY-TEMP-TABLE(). ht[18]:EMPTY-TEMP-TABLE(). ht[19]:EMPTY-TEMP-TABLE().
RUN Invoke. data=result:GetJsonObject("data").
RUN Check(data:GetLogical("confirmed") AND NOT data:GetLogical("actual_complete"),"computation confirmed is independent from actual completeness").
RUN Check(data:GetJsonArray("items_real"):GetJsonObject(1):IsNull("vl_total_real") AND data:GetJsonArray("items_dolar"):GetJsonObject(1):IsNull("vl_total_real"),"both currencies retain unknown actual").
RUN Fixture. oFin:Set("source","linked-payment-totals"). ht[2]:EMPTY-TEMP-TABLE().
RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
RUN Fixture. oFin:Set("source","linked-payment-totals").
RUN Seed(2,'~{"item_container_id":2,"container_id":123,"item_proc_compra_id":1,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":10}').
RUN Invoke. RUN Code("COST_AMBIGUOUS_DATA").
RUN Fixture. oFin:Set("source","linked-payment-totals"). oFin:Set("container_id",124).
RUN Invoke. RUN Code("FINANCIAL_CONTEXT_MISMATCH").
RUN Fixture. oFin:Set("source","filtered-grid"). RUN Invoke. RUN Code("FINANCIAL_CONTEXT_MISMATCH").
containerInput=0. RUN Invoke. RUN Code("INVALID_REQUEST").
DO i=1 TO 25: IF VALID-HANDLE(ht[i]) THEN DELETE OBJECT ht[i]. END.
OUTPUT TO VALUE("containers-versao-cost-adapter-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP. OUTPUT CLOSE.
PROCEDURE Invoke:
 RUN ContainersVersaoCostAdapter.p(hb[1],hb[2],hb[3],hb[4],hb[5],hb[6],hb[7],hb[8],hb[9],hb[10],hb[11],hb[12],hb[13],hb[14],hb[15],hb[16],hb[17],hb[18],hb[19],hb[20],hb[21],hb[22],hb[23],hb[24],hb[25],oFin,oPolicy,containerInput,OUTPUT result).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(messageText,1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE Eq:
 DEFINE INPUT PARAMETER actual AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER expected AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 RUN Check(actual=expected,messageText + " actual=" + STRING(actual) + " expected=" + STRING(expected)).
END PROCEDURE.
PROCEDURE Code:
 DEFINE INPUT PARAMETER expected AS CHARACTER NO-UNDO.
 RUN Check(NOT result:GetLogical("success"),"version snapshot fails closed").
 RUN Check(result:GetJsonObject("error"):GetCharacter("code")=expected,"propagated collector error " + expected).
 RUN Check(NOT result:Has("data"),"no partial version snapshot on failure").
END PROCEDURE.
{ContainersCustoTestFixture.i}

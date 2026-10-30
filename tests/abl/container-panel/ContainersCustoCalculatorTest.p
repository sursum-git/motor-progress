/* Pure JSON fixtures. No DB connection; never publish this runner. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.

DEFINE VARIABLE oIn AS JsonObject NO-UNDO.
DEFINE VARIABLE oOut AS JsonObject NO-UNDO.
DEFINE VARIABLE oData AS JsonObject NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE oTemp AS JsonObject NO-UNDO.
DEFINE VARIABLE iChecks AS INTEGER NO-UNDO.


RUN Fixture(OUTPUT oIn).
RUN Invoke(oIn, OUTPUT oOut).
RUN Check(oOut:GetLogical("success"), "real items succeeds").
oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetDecimal("dolar_medio"),5,"weighted dollar").
oRow=oData:GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),5029.5,"allocated merchandise less item discount and weighted expenses").
RUN Eq(oRow:GetDecimal("vl_unit_prev"),502.95,"allocated unit denominator").
RUN Eq(oRow:GetDecimal("vl_total_real"),1160,"legacy actual cost includes both discount deductions").
RUN Eq(oRow:GetDecimal("vl_unit_real"),0,"unshipped actual unit stays zero").
oRow=oData:GetJsonArray("items"):GetJsonObject(2).
RUN Eq(oRow:GetDecimal("vl_total_prev"),5070,"second row isolated").
RUN Eq(oRow:GetDecimal("qt_saldo"),-20,"unreceived quantity balance").

/* A wrong cost type or silently enabling actual cost in comparatives breaks this. */
oIn:Set("mode","comparativos").
RUN Invoke(oIn, OUTPUT oOut).
oData=oOut:GetJsonObject("data").
oRow=oData:GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),4088.75,"comparatives negotiated basis").
RUN Eq(oRow:GetDecimal("vl_total_real"),0,"comparatives excludes actual cost lookup").

/* Internal generation differs from comparatives only in ERP realization;
   negotiated basis and explicit no-distribution behavior remain central. */
oIn:Set("mode","gerar_versao").
RUN Invoke(oIn,OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"internal version generation profile").
oRow=oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),4088.75,"version negotiated predicted cost").
RUN Eq(oRow:GetDecimal("vl_total_real"),1160,"version retains ERP realization").
RUN Eq(oRow:GetDecimal("vl_total_prev_sem_distr_custo"),4088.75,"version ignores distribution movement").
RUN Check(NOT oOut:GetJsonObject("data"):GetJsonObject("totals"):GetLogical("actual_complete"),"version missing ERP remains incomplete").
RUN Check(oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(2):IsNull("vl_total_real"),"version never coerces missing actual to zero").
oIn:Set("currency","dolar"). RUN Invoke(oIn,OUTPUT oOut).
oRow=oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),817.75,"version dollar prediction from same formula").
RUN Eq(oRow:GetDecimal("vl_total_real"),232,"version dollar realization").
oIn:Set("currency","real").

oIn:Set("mode","itens"). oIn:Set("currency","dolar").
RUN Invoke(oIn, OUTPUT oOut).
oRow=oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),1005.9,"dollar expenses converted once").

oIn:GetJsonObject("container"):Set("log_versao_custo_desatualizada",TRUE).
oIn:Set("calculationBasis","version").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"STALE_VERSION").
oIn:Set("calculationBasis","current").
RUN Invoke(oIn, OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"live calculation does not claim saved version is current").

/* Global shipped fallback differs from per-item shipped fallback in the PHP. */
RUN Fixture(OUTPUT oIn).
oIn:GetJsonArray("items"):GetJsonObject(2):Set("qt_confirm_emb",20).
RUN Invoke(oIn, OUTPUT oOut).
oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("total_tributado_dolar"),1000,"global aggregate shipped fallback").
oRow=oData:GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_desp_prev"),129,"per item numerator retains allocation").

RUN Fixture(OUTPUT oIn).
oIn:GetJsonArray("items"):GetJsonObject(1):Set("qt_alocada",0).
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"ZERO_DENOMINATOR").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("quotation"):Set("data","2026-02-30").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("payments"):Set("real","1.000,00").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("log_versao_custo_desatualizada","false").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:Set("mode","resumo").
RUN Invoke(oIn, OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"named currency resolves summary intent").
RUN Check(oOut:GetJsonObject("data"):GetJsonArray("warnings"):Length>0,"summary records original signature ambiguity").
oRow=oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),4929.5,"summary default includes negative distribution balance").
RUN Eq(oRow:GetDecimal("vl_total_prev_sem_distr_custo"),5029.5,"summary undistributed counterpart").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","1,2,3").
oIn:GetJsonObject("quotation"):Set("valor",1).
RUN Invoke(oIn, OUTPUT oOut).
RUN Eq(oOut:GetJsonObject("data"):GetDecimal("cotacao_saldo"),5,"legacy priority rejects parity one then chooses manual").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","1").
oIn:GetJsonObject("container"):Set("cod_tipo_proj_dolar",3).
oIn:GetJsonObject("container"):Set("vl_proj_dolar",10).
oIn:GetJsonObject("quotation"):Set("valor",4).
RUN Invoke(oIn, OUTPUT oOut).
RUN Eq(oOut:GetJsonObject("data"):GetDecimal("cotacao_saldo"),4.4,"percentage projection only latest quote").
RUN Check(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetJsonArray("compra_attempts"):Length=1,"structured dollar trace").

RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("vl-dolar-compra",3.00003).
oIn:GetJsonObject("payments"):Set("real",0). oIn:GetJsonObject("payments"):Set("dolar",0).
oIn:Set("currency","dolar").
RUN Invoke(oIn, OUTPUT oOut).
oRow=oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),1016.4997350026,"round output decimal ten without currency mask").
RUN Eq(oOut:GetJsonObject("data"):GetDecimal("dolar_medio"),3.00003,"dollar has five decimal places").
RUN Check(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetCharacter("cotacao_data")="2026-10-16","DATE stays ISO across cultures").
oRow=oOut:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(2).
RUN Check(oRow:IsNull("vl_total_real"),"missing ERP record never invents zero actual cost").
RUN Check(oOut:GetJsonObject("data"):GetJsonObject("totals"):IsNull("vl_total_real"),"incomplete actual total remains null").

/* Double subtraction is an observed legacy formula, explicitly traced in docs. */
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("discounts"):Set("credito_dolar",20).
oIn:GetJsonObject("discounts"):Set("total_dolar",10).
RUN Invoke(oIn, OUTPUT oOut).
oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("credito_real_convertido"),100,"credit uses paid average before saldo quote").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("desconto_real_convertido"),50,"discount uses paid average").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("vl_saldo_dolar"),1770,"saldo deducts credit discount and paid dollars").

RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("payments"):Set("dolar",2200). oIn:GetJsonObject("payments"):Set("real",11000).
RUN Invoke(oIn, OUTPUT oOut).
RUN Eq(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetDecimal("denominador_dolar_medio"),2200,"overpayment expands average denominator").
RUN Eq(oOut:GetJsonObject("data"):GetDecimal("dolar_medio"),5,"overpayment average").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonArray("items"):GetJsonObject(1):Set("vl_negociado",120).
RUN Invoke(oIn, OUTPUT oOut).
RUN Eq(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetDecimal("ajuste_negociado_proforma"),200,"truthy legacy cost-mode argument activates negotiated excess").
RUN Eq(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetDecimal("base_dolar_medio"),2200,"average basis includes only positive excess").

RUN Fixture(OUTPUT oIn).
oIn:GetJsonArray("items"):GetJsonObject(1):Set("vl_base_tributacao",0).
oIn:GetJsonArray("items"):GetJsonObject(2):Set("vl_base_tributacao",0).
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"ZERO_DENOMINATOR").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","2").
oIn:GetJsonObject("container"):Set("vl-dolar-compra",0).
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"MISSING_RATE").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("payments"):Remove("real"). oIn:GetJsonObject("payments"):AddNull("real").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonArray("items"):GetJsonObject(2):Set("item_container_id",1).
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","1,0").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Remove("vl_dolar_di").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","2").
oIn:GetJsonObject("container"):Remove("vl_proj_dolar").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Add("VL_DOLAR_DI",1).
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:Set("mode","ITENS").
RUN Invoke(oIn, OUTPUT oOut).
RUN ErrorCode(oOut,"INVALID_REQUEST").
RUN Fixture(OUTPUT oIn).
oIn:GetJsonObject("container"):Set("vl-dolar-compra",1).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","2").
oIn:GetJsonObject("payments"):Set("real",0). oIn:GetJsonObject("payments"):Set("dolar",0).
RUN Invoke(oIn, OUTPUT oOut).
RUN Eq(oOut:GetJsonObject("data"):GetDecimal("cotacao_saldo"),1,"exhausted explicit parity remains traceable real input").
RUN Check(oOut:GetJsonObject("data"):GetJsonArray("warnings"):Length>0,"legacy parity warning").
RUN Fixture(OUTPUT oIn).
oIn:Set("mode","rastro").
oIn:GetJsonArray("items"):GetJsonObject(1):Set("vl_negociado",0).
oIn:GetJsonArray("items"):GetJsonObject(2):Set("vl_negociado",0).
RUN Invoke(oIn, OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"dollar trace independent from negotiated cost and ERP actual lookup").
RUN Fixture(OUTPUT oIn).
oIn:Set("mode","rastro").
oIn:GetJsonArray("items"):GetJsonObject(1):Set("vl_negociado",120).
RUN Invoke(oIn, OUTPUT oOut).
RUN Eq(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetDecimal("ajuste_negociado_proforma"),0,"panel dollar trace direct call leaves logSaldoNeg default false").


/* Fiscal quotation inputs are independent from item/unit cost eligibility. */
RUN Fixture(OUTPUT oIn). oIn:Set("mode","fiscal_inputs"). oIn:Set("items",NEW JsonArray()).
oIn:GetJsonObject("payments"):Set("real",0). oIn:GetJsonObject("payments"):Set("dolar",0).
RUN Invoke(oIn,OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"fiscal empty container accepts zero base").
oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetDecimal("dolar_medio"),0,"fiscal empty mean unavailable instead of fabricated rate").
RUN Eq(oData:GetDecimal("dolar_compra"),5,"fiscal empty direct priority2 preserved").
RUN Eq(oData:GetDecimal("dolar_di"),4.8,"fiscal empty direct priority4 preserved").
RUN Check(oData:GetJsonArray("items"):Length=0,"fiscal creates no fake item").
RUN Eq(oData:GetJsonObject("totals"):GetDecimal("vl_total_prev"),0,"fiscal predicted total zero").
RUN Eq(oData:GetJsonObject("totals"):GetDecimal("vl_total_real"),0,"fiscal actual total zero without ERP item computation").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("denominador_dolar_medio"),0,"fiscal zero divisor recorded").
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","3,2").
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_di","3,4").
RUN Invoke(oIn,OUTPUT oOut). oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetDecimal("dolar_compra"),5,"fiscal unavailable mean falls through to manual priority2").
RUN Eq(oData:GetDecimal("dolar_di"),4.8,"fiscal unavailable mean falls through to priority4").
RUN Eq(oData:GetJsonObject("memory"):GetJsonArray("compra_attempts"):GetJsonObject(1):GetDecimal("value"),0,"fiscal trace preserves attempted mean zero").
RUN Check(oData:GetJsonObject("memory"):GetJsonArray("compra_attempts"):Length=2,"fiscal fallback traced by same Rate algorithm").
oIn:GetJsonObject("payments"):Set("real",1000). oIn:GetJsonObject("payments"):Set("dolar",200).
RUN Invoke(oIn,OUTPUT oOut). oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetDecimal("dolar_medio"),5,"fiscal positive payments with no merchandise use legacy expanded denominator").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("denominador_dolar_medio"),200,"fiscal overpayment divisor preserved at zero basis").
RUN Eq(oData:GetDecimal("dolar_compra"),5,"fiscal positive payment mean accepted as priority3").
RUN Check(oData:GetJsonArray("items"):Length=0,"fiscal paid empty container still has no fake item").
RUN Fixture(OUTPUT oIn). oIn:Set("mode","fiscal_inputs").
oIn:GetJsonArray("items"):GetJsonObject(1):Set("qt_alocada",0).
oIn:GetJsonArray("items"):GetJsonObject(2):Set("qt_alocada",0).
oIn:GetJsonArray("items"):GetJsonObject(1):Set("erp_real","not-an-ERP-cost-input").
RUN Invoke(oIn,OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"fiscal zero quantity ignores ERP unit-cost components").
RUN Eq(oOut:GetJsonObject("data"):GetJsonObject("memory"):GetDecimal("total_tributado_dolar"),0,"fiscal zero quantity yields zero basis").
oRow=oIn:GetJsonArray("items"):GetJsonObject(1).
oRow:Remove("qt_recbto_fisico"). oRow:Remove("erp_real"). oRow:Remove("despesa_item").
oRow:Remove("distribuicao_real"). oRow:Remove("desconto_real"). oRow:Remove("desconto_dolar").
RUN Invoke(oIn,OUTPUT oOut).
RUN Check(oOut:GetLogical("success"),"fiscal minimal item requires only aggregate quotation inputs").
RUN Fixture(OUTPUT oIn). oIn:Set("mode","fiscal_inputs").
oIn:GetJsonArray("items"):GetJsonObject(1):Set("vl_negociado",120).
RUN Invoke(oIn,OUTPUT oOut). oData=oOut:GetJsonObject("data").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("ajuste_negociado_proforma"),0,"fiscal same logSaldoNeg false as direct trace").
RUN Eq(oData:GetJsonObject("memory"):GetDecimal("base_dolar_medio"),2000,"fiscal positive base uses same trace average input").
RUN Eq(oData:GetDecimal("dolar_medio"),5,"fiscal positive base keeps existing average formula").
RUN Check(oData:GetJsonArray("items"):Length=0,"fiscal never computes item unit cost even with positive basis").
RUN Fixture(OUTPUT oIn). oIn:Set("mode","fiscal_inputs"). oIn:Set("items",NEW JsonArray()).
oIn:GetJsonObject("payments"):Set("real",0). oIn:GetJsonObject("payments"):Set("dolar",0).
oIn:GetJsonObject("container"):Set("ordem_busca_dolar_compra","3").
RUN Invoke(oIn,OUTPUT oOut). RUN ErrorCode(oOut,"MISSING_RATE").
oIn:Set("mode","itens"). RUN Invoke(oIn,OUTPUT oOut). RUN ErrorCode(oOut,"INVALID_REQUEST").

OUTPUT TO VALUE("containers-custo-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " iChecks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
OUTPUT CLOSE.

PROCEDURE Check:
 DEFINE INPUT PARAMETER lOk AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER cMessage AS CHARACTER NO-UNDO.
 iChecks=iChecks + 1.
 IF lOk<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + cMessage,1).
END PROCEDURE.
PROCEDURE Eq:
 DEFINE INPUT PARAMETER dActual AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER dExpected AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER cMessage AS CHARACTER NO-UNDO.
 RUN Check(dActual=dExpected,cMessage + " actual=" + STRING(dActual) + " expected=" + STRING(dExpected)).
END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER oResult AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER cExpected AS CHARACTER NO-UNDO.
 RUN Check(oResult:GetLogical("success")=FALSE,"failure envelope: " + cExpected).
 RUN Check(oResult:GetJsonObject("error"):GetCharacter("code")=cExpected,cExpected).
 RUN Check(NOT oResult:Has("data"),"no partial results on error").
END PROCEDURE.
PROCEDURE Fixture:
 DEFINE OUTPUT PARAMETER oFixture AS JsonObject NO-UNDO.
 DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
 DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
 lcJson='~{"mode":"itens","currency":"real","calculationBasis":"current",' +
 '"container":~{"nr-container":123,"ordem_busca_dolar_compra":"2,1","ordem_busca_dolar_di":"4,1","cod_tipo_proj_dolar":1,"vl_proj_dolar":0,"vl-dolar-compra":5,"vl_dolar_di":4.8,"log_versao_custo_desatualizada":false},' +
 '"quotation":~{"valor":4.9,"data":"2026-10-16"},"payments":~{"real":1000,"dolar":200},' +
 '"discounts":~{"credito_real":0,"credito_dolar":0,"total_real":0,"total_dolar":0},' +
 '"expenses":~{"tributado":100,"proforma":150,"negociado":200},"items":[' +
 '~{"item_container_id":1,"qt_alocada":10,"qt_confirm_emb":0,"qt_recbto_fisico":0,"vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":80,"despesa_item":~{"tributado":30,"proforma":30,"negociado":40},"distribuicao_real":100,"desconto_real":20,"desconto_dolar":10,"erp_real":~{"vl_custo":1000,"vl_desp":200,"perc_rateio":0.6}},' +
 '~{"item_container_id":2,"qt_alocada":20,"qt_confirm_emb":0,"qt_recbto_fisico":0,"vl_base_tributacao":50,"vl_custo_dolar":45,"vl_negociado":40,"despesa_item":~{"tributado":20,"proforma":20,"negociado":10},"distribuicao_real":0,"desconto_real":0,"desconto_dolar":0,"erp_real":null}]}'.
 oParser=NEW ObjectModelParser(). oFixture=CAST(oParser:Parse(lcJson),JsonObject).
 DELETE OBJECT oParser.
END PROCEDURE.

PROCEDURE Invoke:
 DEFINE INPUT PARAMETER oRequest AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER oResult AS JsonObject NO-UNDO.
 RUN ContainersCustoCalculator.p(oRequest, OUTPUT oResult) NO-ERROR.
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: calculator missing or failed: " + ERROR-STATUS:GET-MESSAGE(1),1).
END PROCEDURE.





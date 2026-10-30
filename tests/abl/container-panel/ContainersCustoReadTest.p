/* Real dynamic temp-table fixtures; no business DB required. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE oReq AS JsonObject NO-UNDO.
DEFINE VARIABLE oFin AS JsonObject NO-UNDO.
DEFINE VARIABLE oPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE oResult AS JsonObject NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE iChecks AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE hSaved AS HANDLE NO-UNDO.
DEFINE VARIABLE cStoredKey AS CHARACTER NO-UNDO.

RUN Fixture.
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"reads actual buffers and calculates items").
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),5130,"cost expenses filtered by company and log_custo").
RUN Eq(oRow:GetDecimal("vl_total_real"),1070,"single NF line membership at first list position and recoverable tax adjustment").
RUN Eq(oRow:GetDecimal("vl_unit_real"),107,"single line actual fraction is one not100").
RUN Check(oRow:GetCharacter("descricao")="Item um","description comes from confirmed purchase item").
RUN Check(oRow:GetCharacter("calculation_source")="calc_v1","row exposes calculation origin through itemsPath data").
RUN Check(INDEX(oRow:GetCharacter("calculation_warning"),"calc_v1")>0,"row exposes corrected ERP warning").
RUN Check(oRow:GetCharacter("quotation_date")="2026-10-16" AND oRow:GetCharacter("quotation_latest_date")="2026-10-16","row exposes selected and raw quotation dates").
RUN Check(oRow:IsNull("quotation_warning"),"row distinguishes no quotation fallback warning").
RUN Check(oResult:GetJsonObject("calculation"):GetCharacter("source")="calc_v1","explicit corrected collector origin").
RUN Check(oResult:GetJsonObject("calculation"):GetJsonArray("warnings"):Length>0,"corrected ERP grouping is disclosed").
RUN Check(NOT oResult:Has("input_snapshot"),"ordinary public items do not expose calculation inputs").

RUN Fixture.
oPolicy:Add("calculation_profile","version"). oPolicy:Add("capture_input",TRUE).
RUN Seed(9,'~{"cta_corren_custo_distr_id":1,"item_container_id":1,"cod_tipo_movto":4,"vl_lancto":100}').
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"private version profile succeeds using same collector").
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vl_total_prev"),4130,"version negotiated prediction").
RUN Eq(oRow:GetDecimal("vl_total_real"),1070,"version realized ERP remains enabled").
RUN Eq(oRow:GetDecimal("vl_total_prev_sem_distr_custo"),4130,"version disables distribution as source call").
RUN Check(oResult:GetJsonObject("input_snapshot"):GetCharacter("mode")="gerar_versao","captured input selects internal generation mode").
RUN Check(oResult:GetJsonObject("input_snapshot"):GetCharacter("calculationBasis")="current","generation does not claim an existing historical version").
oResult:GetJsonObject("input_snapshot"):GetJsonArray("items"):GetJsonObject(1):Set("vl_negociado",999).
RUN Eq(oRow:GetDecimal("vl_total_prev"),4130,"captured inputs are detached from calculated rows").
oReq:Set("resource","rastro"). RUN Invoke. RUN Code("COST_POLICY_INVALID").
RUN Fixture. oPolicy:Add("capture_input",TRUE). RUN Invoke. RUN Code("COST_POLICY_INVALID").
RUN Fixture. oPolicy:Add("calculation_profile","Version"). RUN Invoke. RUN Code("COST_POLICY_INVALID").
RUN Fixture. oPolicy:Add("calculation_profile","version"). oPolicy:Add("capture_input","true"). RUN Invoke. RUN Code("COST_POLICY_INVALID").
RUN Fixture. oReq:Add("calculation_profile","version"). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture. oReq:Add("capture_input",TRUE). RUN Invoke. RUN Code("INVALID_REQUEST").
DO i=1 TO 4:
 RUN Fixture. oReq:Set("resource",ENTRY(i,"itens,comparativos,resumo,rastro")). RUN Invoke.
 RUN Check(oResult:GetLogical("success") AND NOT oResult:Has("input_snapshot"),"ordinary resources never expose private input snapshot").
END.
RUN Fixture.

/* Valid empty children are different from an invalid calculation payload. */
RUN Fixture. ht[2]:EMPTY-TEMP-TABLE().
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"empty items read succeeds").
RUN Check(oResult:GetJsonArray("data"):Length=0,"empty items read returns no invented rows").
RUN Check(NOT oResult:Has("calculation"),"empty read has no confirmed calculation").
oReq:Set("operation","get"). oReq:Add("id",1). RUN Invoke. RUN Code("NOT_FOUND").
oReq:Set("resource","comparativos"). RUN Invoke. RUN Code("NOT_FOUND").
oReq:Set("operation","read"). oReq:Remove("id"). RUN Invoke.
RUN Check(oResult:GetLogical("success") AND oResult:GetJsonArray("data"):Length=0,"empty comparative read").
oReq:Set("resource","resumo"). RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
oReq:Set("resource","rastro"). RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
/* Empty grades do not depend on a document connection or calculator. */
oReq:Set("resource","itens"). hSaved=hb[18]. hb[18]=?. RUN Invoke.
RUN Check(oResult:GetLogical("success") AND oResult:GetJsonArray("data"):Length=0,"empty read before ERP dependency").
hb[18]=hSaved.

/* Aggregate ERP components cannot be assigned twice to distinct children. */
RUN Fixture.
RUN Seed(2,'~{"item_container_id":2,"container_id":123,"item_proc_compra_id":1,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":10}').
RUN Invoke. RUN Code("COST_AMBIGUOUS_DATA").
oReq:Set("resource","resumo"). RUN Invoke. RUN Code("COST_AMBIGUOUS_DATA").
/* An invoice-only item must not silently consume part of the denominator. */
RUN Fixture.
RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","it-codigo":"UNMAPPED","sequencia":2,"quantidade":10,"preco-total":1000,"despesas":100,"val-cofins":0,"val-aliq-cofins":0,"valor-pis":0,"val-aliq-pis":0}').
RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
oReq:Set("resource","resumo"). RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
RUN Fixture.

/* Final item must never disappear at a group boundary. */
RUN Seed(2,'~{"item_container_id":2,"container_id":123,"item_proc_compra_id":2,"qt_alocada":20,"qt_confirm_emb":20,"qt_recbto_fisico":20}').
RUN Seed(3,'~{"item_proc_compra_id":2,"proc_compra_id":1,"descricao":"Item dois","codigo_erp":"ERP2","vl_base_tributacao":50,"vl_custo_dolar":45,"vl_negociado":40}').
RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","it-codigo":"ERP2","sequencia":2,"quantidade":20,"preco-total":1000,"despesas":20,"val-cofins":0,"val-aliq-cofins":0,"valor-pis":0,"val-aliq-pis":0}').
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"multiple ERP items calculate").
RUN Check(oResult:GetJsonArray("data"):Length=2,"both final groups retained").
RUN Eq(oResult:GetJsonArray("data"):GetJsonObject(1):GetDecimal("vl_total_real"),570,"first item uses half payment and adjusted NF expenses").
RUN Eq(oResult:GetJsonArray("data"):GetJsonObject(2):GetDecimal("vl_total_real"),520,"last item accumulated before emission").
RUN Seed(16,'~{"container_id":123,"documento":"N2","serie":"A","estab":"5","nat_operacao":"5102","cod_emitente":10}').
RUN Seed(19,'~{"cod-estabel":"5","serie-docto":"A","nro-docto":"N2","nat-operacao":"5102","cod-emitente":10}').
RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N2","nat-operacao":"5102","it-codigo":"ERP1","sequencia":1,"quantidade":1,"preco-total":50,"despesas":9,"val-cofins":0,"val-aliq-cofins":0,"valor-pis":0,"val-aliq-pis":0}').
RUN Invoke.
RUN Eq(oResult:GetJsonArray("data"):GetJsonObject(1):GetDecimal("vl_total_real"),620,"nonmother merchandise becomes cost expense without adding its NF expense").

RUN Fixture.
oReq:Set("resource","resumo").
RUN Seed(17,'~{"nr-container":123,"nr-pedido":55,"cod-estabel":"5"}').
RUN Seed(22,'~{"nr-pedido":55,"cod-estabel":"5","nome-abrev":"C1","nr-pedcli":"P1","cod-sit-ped":1,"mo-codigo":3,"cod-priori":19}').
RUN Seed(23,'~{"nome-abrev":"C1","nr-pedcli":"P1","qt-pedida":2,"vl-preuni":100}').
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"summary includes confirmed sales").
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Eq(oRow:GetDecimal("vendas_prev_real"),1100,"legacy plus priority discount and sale dollar conversion").
RUN Check(oRow:GetCharacter("calculation_source")="calc_v1" AND LENGTH(oRow:GetCharacter("calculation_warning"))>0,"summary row exposes calculation warning").

RUN Fixture.
oReq:Set("resource","rastro").
hSaved=hb[18]. hb[18]=?.
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"dollar trace does not require ERP actual connection").
RUN Check(oResult:GetJsonArray("data"):GetJsonObject(1):GetCharacter("calculation_source")="calc_v1","trace row exposes calculation provenance").
hb[18]=hSaved.
RUN Fixture.
hSaved=hb[18]. hb[18]=?.
RUN Invoke.
RUN Code("COST_CONFIGURATION"). hb[18]=hSaved.
RUN Fixture.
oFin:Set("container_id",124). RUN Invoke. RUN Code("FINANCIAL_CONTEXT_MISMATCH").
RUN Fixture.
oReq:Add("payments",NEW JsonObject()). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Set("operation","delete"). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Set("container_id",124). RUN Invoke. RUN Code("NOT_FOUND").
RUN Fixture.
oReq:Set("operation","get"). oReq:Add("id",2). RUN Invoke. RUN Code("NOT_FOUND").
RUN Fixture.
hb[18]:FIND-FIRST() NO-ERROR.
hb[18]:BUFFER-FIELD("val-aliq-cofins"):BUFFER-VALUE=0.
RUN Invoke. RUN Code("ZERO_DENOMINATOR").
RUN Fixture.
oPolicy:Set("naturezas_nota_mae",""). RUN Invoke. RUN Code("COST_POLICY_INVALID").
RUN Fixture.
hb[3]:FIND-FIRST() NO-ERROR. hb[3]:BUFFER-FIELD("vl_base_tributacao"):BUFFER-VALUE=?.
RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
RUN Fixture.
RUN Seed(5,'~{"empresa_id":2,"cod_emp_ems2":5,"cod_emp_ems5":20}').
RUN Invoke. RUN Code("COST_AMBIGUOUS_DATA").
RUN Fixture.
oReq:Set("resource","comparativos").
hSaved=hb[18]. hb[18]=?.
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"negotiated comparative does not read actual ERP").
RUN Eq(oResult:GetJsonArray("data"):GetJsonObject(1):GetDecimal("vl_total_prev"),4130,"comparative uses negotiated price with confirmed expenses").
RUN Check(oResult:GetJsonArray("data"):GetJsonObject(1):GetCharacter("quotation_date")="2026-10-16","comparative row exposes quotation provenance").
hb[18]=hSaved.
RUN Seed(15,'~{"versao_id":10,"container_id":123,"ind_sit_versao":1}').
RUN Seed(15,'~{"versao_id":99,"container_id":999,"ind_sit_versao":1}').
RUN Seed(14,'~{"item_container_custo_id":1,"versao_id":10,"item_container_id":1,"vl_unit_prev":321,"vl_unit_realiz":234}').
RUN Invoke.
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Eq(oRow:GetInteger("ultima_versao_id"),10,"latest saved version scoped to current container").
RUN Eq(oRow:GetDecimal("vl_unit_prev_versao"),321,"stored comparative is read without replacing current calculation").
RUN Eq(oRow:GetDecimal("vl_unit_real_versao"),234,"stored actual comparative uses its own snapshot").
hb[14]:FIND-FIRST() NO-ERROR. hb[14]:BUFFER-FIELD("vl_unit_realiz"):BUFFER-VALUE=?.
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"comparative accepts previous version with legitimately missing actual cost").
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Check(oRow:IsNull("vl_unit_real_versao"),"historical actual remains JSONnull instead of invented zero").
RUN Eq(oRow:GetDecimal("vl_unit_prev_versao"),321,"known forecast history retained alongside missing actual").
RUN Eq(oRow:GetDecimal("vl_total_prev"),4130,"nullable historical actual does not change current cost math").
hb[14]:FIND-FIRST() NO-ERROR. hb[14]:BUFFER-FIELD("vl_unit_prev"):BUFFER-VALUE=?.
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"both nullable historical unit fields are display data").
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Check(oRow:IsNull("vl_unit_prev_versao") AND oRow:IsNull("vl_unit_real_versao"),"both historical unknowns preserve explicit nulls").
oReq:Set("operation","get"). oReq:Add("id",1). oReq:Add("item_container_id",1). RUN Invoke.
RUN Check(oResult:GetLogical("success") AND oResult:GetJsonObject("data"):IsNull("vl_unit_real_versao"),"comparative detail preserves null historical actual").
oReq:Set("resource","itens"). RUN Invoke.
RUN Check(oResult:GetLogical("success") AND oResult:GetJsonObject("data"):IsNull("vl_unit_prev_versao"),"item detail shares nullable history serialization").
hb[3]:FIND-FIRST() NO-ERROR. hb[3]:BUFFER-FIELD("vl_base_tributacao"):BUFFER-VALUE=?.
RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
RUN Fixture.
oReq:Add("RESOURCE","itens"). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
RUN Seed(13,'~{"hist_cotacao_bc_id":2,"serie":1,"data":"2026-10-16","valor":6,"log_ok":true,"log_manual":false}').
RUN Invoke. RUN Code("COST_AMBIGUOUS_DATA").
RUN Seed(13,'~{"hist_cotacao_bc_id":3,"serie":1,"data":"2026-10-17","valor":7,"log_ok":true,"log_manual":false}').
RUN Invoke. RUN Check(oResult:GetLogical("success"),"ambiguity on older date does not reject newer valid quote").
RUN Fixture.
RUN Seed(13,'~{"hist_cotacao_bc_id":2,"serie":1,"data":"2026-10-17","valor":9,"log_ok":false,"log_manual":false}').
RUN Invoke. RUN Check(oResult:GetLogical("success"),"latest invalid quotation falls back to last valid quotation").
oRow=oResult:GetJsonObject("calculation"):GetJsonObject("quotation_selection").
RUN Check(oRow:GetCharacter("latest_record_date")="2026-10-17","raw quotation maximum date is disclosed").
RUN Check(oRow:GetCharacter("selected_date")="2026-10-16","selected valid quotation date is disclosed").
RUN Eq(oRow:GetDecimal("selected_value"),5,"selected quotation raw value is disclosed").
RUN Check(oRow:GetJsonObject("warning"):GetCharacter("code")="LATEST_QUOTATION_INVALID_SKIPPED","structured warning explains invalid last record fallback").
oRow=oResult:GetJsonArray("data"):GetJsonObject(1).
RUN Check(oRow:GetCharacter("quotation_warning")="LATEST_QUOTATION_INVALID_SKIPPED","row keeps warning when top metadata is discarded").
RUN Check(oRow:GetCharacter("quotation_date")="2026-10-16" AND oRow:GetCharacter("quotation_latest_date")="2026-10-17","row distinguishes selected from latest invalid quotation date").
RUN Check(INDEX(oRow:GetCharacter("calculation_warning"),"LATEST_QUOTATION_INVALID_SKIPPED")>0 AND LENGTH(oRow:GetCharacter("calculation_warning"))<=4000,"row warning list is visible and bounded").
RUN Fixture.
RUN Seed(16,'~{"container_id":123,"documento":"N1","serie":"A","estab":"5","nat_operacao":"3102","cod_emitente":10}').
RUN Invoke. RUN Code("COST_AMBIGUOUS_DATA").
RUN Fixture.
hb[3]:FIND-FIRST() NO-ERROR. hb[3]:BUFFER-FIELD("codigo_erp"):BUFFER-VALUE="".
RUN Invoke. RUN Code("COST_DATA_INCOMPLETE").
RUN Fixture.
oReq:Set("operation","get"). oReq:Add("id",1). RUN Invoke.
RUN Check(oResult:GetLogical("success"),"get returns current container item").
RUN Eq(oResult:GetJsonObject("data"):GetInteger("item_container_id"),1,"get object matches item key").
RUN Check(oResult:GetJsonObject("data"):GetInteger("container_id")=123,"get keeps fixed container context").
oReq:Add("item_container_id",1). RUN Invoke.
RUN Check(oResult:GetLogical("success"),"frontend item alias matches id").
oReq:Set("resource","comparativos"). RUN Invoke.
RUN Check(oResult:GetLogical("success"),"frontend comparative item alias matches id").
oReq:Set("item_container_id",2). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Set("operation","get"). oReq:Set("resource","rastro"). oReq:Add("id",1). oReq:Add("rastro_id",1). RUN Invoke.
RUN Check(oResult:GetLogical("success"),"frontend trace alias matches id").
oReq:Set("rastro_id",2). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Set("operation","get"). oReq:Set("resource","resumo"). oReq:Add("id",123). RUN Invoke.
RUN Check(oResult:GetLogical("success"),"summary id is container primary key").
oReq:Set("id",1). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Add("item_container_id",1). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Set("operation","get"). oReq:Add("id",1). oReq:Add("rastro_id",1). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
oReq:Set("operation","get"). oReq:Add("id",1). oReq:Add("ITEM_CONTAINER_ID",1). RUN Invoke. RUN Code("INVALID_REQUEST").
RUN Fixture.
cStoredKey="NF" + CHR(39) + CHR(126) + "X" + CHR(34).
hb[16]:FIND-FIRST() NO-ERROR. hb[16]:BUFFER-FIELD("documento"):BUFFER-VALUE=cStoredKey.
hb[18]:FIND-FIRST() NO-ERROR. hb[18]:BUFFER-FIELD("nro-docto"):BUFFER-VALUE=cStoredKey.
hb[19]:FIND-FIRST() NO-ERROR. hb[19]:BUFFER-FIELD("nro-docto"):BUFFER-VALUE=cStoredKey.
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"stored apostrophe tilde double quote is literal in fixed ERP query").
RUN Eq(oResult:GetJsonArray("data"):GetJsonObject(1):GetDecimal("vl_total_real"),1070,"escaped stored NF key selects exact matching document").
RUN FiscalInputsTests.

DO i=1 TO 25: IF VALID-HANDLE(ht[i]) THEN DELETE OBJECT ht[i]. END.
OUTPUT TO VALUE("containers-custo-read-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " iChecks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
OUTPUT CLOSE.

PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 iChecks=iChecks + 1.
 IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + c,1).
END PROCEDURE.
PROCEDURE Eq:
 DEFINE INPUT PARAMETER d AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER e AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 RUN Check(d=e,c + " actual=" + STRING(d) + " expected=" + STRING(e)).
END PROCEDURE.
PROCEDURE Code:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 RUN Check(oResult:GetLogical("success")=FALSE,"failure " + c).
 RUN Check(oResult:GetJsonObject("error"):GetCharacter("code")=c,"error code " + c).
 RUN Check(NOT oResult:Has("data"),"no partial cost data").
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersCustoReadService.p(hb[1],hb[2],hb[3],hb[4],hb[5],hb[6],hb[7],hb[8],hb[9],hb[10],hb[11],hb[12],hb[13],hb[14],hb[15],hb[16],hb[17],hb[18],hb[19],hb[20],hb[21],hb[22],hb[23],hb[24],hb[25],oFin,oPolicy,oReq,OUTPUT oResult) NO-ERROR.
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL collector missing or failed: " + ERROR-STATUS:GET-MESSAGE(1),1).
END PROCEDURE.
PROCEDURE FiscalInputsTests:
 DEFINE VARIABLE traceMemory AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscalMemory AS JsonObject NO-UNDO.
 DEFINE VARIABLE rateNames AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 RUN Fixture. oReq:Set("resource","rastro").
 hb[1]:FIND-FIRST(). ASSIGN hb[1]:BUFFER-FIELD("ordem_busca_dolar_compra"):BUFFER-VALUE="3,2" hb[1]:BUFFER-FIELD("ordem_busca_dolar_di"):BUFFER-VALUE="3,4".
 oFin:GetJsonObject("payments"):Set("real",800). RUN Invoke.
 traceMemory=CAST(oResult:GetJsonObject("calculation"):GetJsonObject("memory"):Clone(),JsonObject).
 oReq:Set("resource","cotacoes-fiscais"). RUN Invoke.
 RUN Check(oResult:GetLogical("success"),"fiscal quotation resource uses central calculation").
 fiscalMemory=oResult:GetJsonObject("calculation"):GetJsonObject("memory").
 rateNames="compra_attempts,di_attempts,saldo_attempts".
 DO j=1 TO NUM-ENTRIES(rateNames):
  RUN Check(STRING(fiscalMemory:GetJsonArray(ENTRY(j,rateNames)):GetJsonText())=STRING(traceMemory:GetJsonArray(ENTRY(j,rateNames)):GetJsonText()),"fiscal rate attempts equal ordinary trace: " + ENTRY(j,rateNames)).
 END.
 RUN Check(oResult:GetJsonArray("data"):Length=12 AND oResult:GetJsonArray("data"):GetJsonObject(1):GetInteger("container_id")=123,"fiscal result retains trace shape and parent scope").
 RUN Check(oResult:GetJsonObject("calculation"):GetJsonArray("raw_erp"):Length=0 AND NOT oResult:Has("input_snapshot"),"fiscal result has no ERP realization or private snapshot").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais"). ht[2]:EMPTY-TEMP-TABLE().
 RUN Seed(2,'~{"item_container_id":99,"container_id":999,"item_proc_compra_id":999,"qt_alocada":999,"qt_confirm_emb":999,"qt_recbto_fisico":999}').
 /* All ERP and sales handles may be absent for this resource. */
 DO j=17 TO 25: hb[j]=?. END.
 RUN Invoke.
 RUN Check(oResult:GetLogical("success") AND oResult:Has("calculation"),"zero own items still calculates fiscal quotations without ERP or sales handles").
 RUN Check(oResult:GetJsonArray("data"):Length=12,"zero items never returns an uncalculated empty grade").
 RUN Eq(oResult:GetJsonObject("calculation"):GetJsonObject("memory"):GetDecimal("total_tributado_dolar"),0,"foreign items never enter fiscal quotation basis").
 oFin:GetJsonObject("payments"):Set("real",0). oFin:GetJsonObject("payments"):Set("dolar",0). RUN Invoke.
 RUN Check(oResult:GetLogical("success"),"zero own items and zero payments still use configured fiscal rates without fabricated item").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais").
 hb[2]:FIND-FIRST(). ASSIGN hb[2]:BUFFER-FIELD("qt_alocada"):BUFFER-VALUE=0 hb[2]:BUFFER-FIELD("qt_confirm_emb"):BUFFER-VALUE=0 hb[2]:BUFFER-FIELD("qt_recbto_fisico"):BUFFER-VALUE=0.
 RUN Invoke. RUN Check(oResult:GetLogical("success"),"zero quantity has no unit cost denominator in fiscal quotation mode").
 oReq:Set("operation","get"). oReq:Add("id",1). RUN Invoke. RUN Code("INVALID_REQUEST").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais"). oReq:Set("moeda","dolar"). RUN Invoke. RUN Code("INVALID_REQUEST").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais"). oReq:Add("policy",NEW JsonObject()). RUN Invoke. RUN Code("INVALID_REQUEST").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais"). oFin:Set("container_id",999). RUN Invoke. RUN Code("FINANCIAL_CONTEXT_MISMATCH").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais"). oPolicy:Add("calculation_profile","version"). RUN Invoke. RUN Code("COST_POLICY_INVALID").
 RUN Fixture. oReq:Set("resource","cotacoes-fiscais"). oPolicy:Add("capture_input",TRUE). RUN Invoke. RUN Code("COST_POLICY_INVALID").
 DELETE OBJECT traceMemory.
END PROCEDURE.
{ContainersCustoTestFixture.i}

/* Test-only provider; never publish. No database access. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO INITIAL "ok".
DEFINE VARIABLE seqVersion AS INTEGER NO-UNDO INITIAL 1000.
DEFINE VARIABLE seqItem AS INTEGER NO-UNDO INITIAL 2000.
DEFINE VARIABLE distributionCalls AS INTEGER NO-UNDO.
PROCEDURE SetMode:
 DEFINE INPUT PARAMETER modeInput AS CHARACTER NO-UNDO.
 modeValue=modeInput.
END PROCEDURE.
PROCEDURE GetStatus:
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 resultValue=NEW JsonObject(). resultValue:Add("confirmed",modeValue<>"distribution-untrusted"). resultValue:Add("distribution_enabled",TRUE).
END PROCEDURE.
PROCEDURE ApplyVersionDistribution:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER versionValue AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER mappings AS JsonArray NO-UNDO.
 DEFINE INPUT PARAMETER snapshotValue AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 distributionCalls=distributionCalls + 1.
 IF NOT TRANSACTION OR versionValue<>1001 OR mappings:Length<>1 OR mappings:GetJsonObject(1):GetInteger("item_container_id")<>11 OR mappings:GetJsonObject(1):GetInteger("item_container_custo_id")<>2001 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid persisted distribution mappings",1).
 master:BUFFER-FIELD("narrativa"):BUFFER-VALUE="distribution-effect".
 IF modeValue="distribution-fail" THEN UNDO, THROW NEW Progress.Lang.AppError("UNSTABLE_DISTRIBUTION",1).
 resultValue=NEW JsonObject(). resultValue:Add("success",TRUE). resultValue:Add("committed",FALSE). resultValue:Add("requiredNewSnapshot",FALSE). resultValue:Add("pendingChanges",NEW JsonArray()).
 eventValue=NEW JsonObject(). eventValue:Add("resource","cta_corren_custo_distr"). eventValue:Add("operation","create"). eventValue:Add("recordId",99). eventValue:Add("before",NEW JsonObject()). eventValue:Add("after",NEW JsonObject()). resultValue:GetJsonArray("pendingChanges"):Add(eventValue).
 IF modeValue="distribution-early-audit" THEN resultValue:Add("audit",NEW JsonObject()).
END PROCEDURE.
PROCEDURE GetDistributionCalls:
 DEFINE OUTPUT PARAMETER valueCount AS INTEGER NO-UNDO.
 valueCount=distributionCalls.
END PROCEDURE.
PROCEDURE NextVersionId:
 DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO.
 seqVersion=seqVersion + 1. id=seqVersion.
END PROCEDURE.
PROCEDURE NextVersionItemId:
 DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO.
 seqItem=seqItem + 1. id=seqItem.
END PROCEDURE.
PROCEDURE PrepareVersionFiscal:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal outside root transaction",1).
 master:BUFFER-FIELD("narrativa"):BUFFER-VALUE="fiscal".
 IF modeValue="fiscal-fail" THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal failed after write",1).
 result=NEW JsonObject(). result:Add("success",TRUE). result:Add("changes",NEW JsonArray()). result:Add("warnings",NEW JsonArray()).
 IF modeValue="invalid-audit" THEN result:GetJsonArray("changes"):Add(NEW JsonObject()).
 IF modeValue="invalid-warning" THEN result:GetJsonArray("warnings"):Add(NEW JsonObject()).
END PROCEDURE.
PROCEDURE CollectVersionSnapshot:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE reorderedRows AS JsonArray NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot outside root transaction",1).
 IF modeValue="collect-fail" THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot failed after fiscal",1).
 parser=NEW ObjectModelParser(). result=CAST(parser:Parse("~{~"confirmed~":true,~"container_id~":123,~"actual_complete~":true,~"cost~":~{~"confirmed~":true,~"source~":~"container-version-cost-snapshot~",~"container_id~":123,~"actual_complete~":true,~"calculation_profile~":~"version~",~"items_real~":[~{~"item_container_id~":11,~"codigo_erp~":~"ERP-11~",~"vl_desp_prev~":30,~"vl_desp_prev_sem_distr_custo~":0,~"vl_merc_prev~":100,~"vl_merc_real~":110,~"vl_desp_real~":20,~"vl_unit_prev~":13,~"vl_unit_real~":13,~"vl_desc_item~":0,~"vl_desc_container~":0,~"vl_total_real~":130,~"vl_total_prev~":130}],~"items_dolar~":[~{~"item_container_id~":11,~"vl_desp_prev~":6,~"vl_desp_prev_sem_distr_custo~":0,~"vl_merc_prev~":20,~"vl_merc_real~":22,~"vl_desp_real~":4,~"vl_unit_prev~":2.6,~"vl_unit_real~":2.6,~"vl_desc_item~":0,~"vl_desc_container~":0,~"vl_total_real~":26,~"vl_total_prev~":26}],~"input_snapshot~":~{~"items~":[~{~"item_container_id~":11,~"qt_alocada~":10,~"qt_confirm_emb~":10,~"qt_recbto_fisico~":0,~"vl_negociado~":20}]},~"master_average~":~{~"dolar_medio~":5,~"cotacao_saldo~":5,~"memory~":~{}},~"calculation~":~{~"warnings~":[]}},~"header~":~{~"vl_dolar_compra~":5,~"vl_desconto_utiliz_dolar~":0,~"vl_desconto_utiliz_real~":0,~"vl_dolar_di~":5,~"log_gerar_saldo_a_pagar~":false,~"log_gerar_distr_custo~":false,~"situacao_container_id~":1,~"desc_sit_container~":~"Teste~",~"cod_tipo_cotacao~":1,~"vl_cotacao~":5,~"data_ref_cotacao~":~"2026-10-16~",~"perc_fixo_container~":0,~"hist_dolar~":~"Origem teste~"},~"expenses~":[~{~"despesa_id~":1,~"vl_prev~":30,~"vl_negociado~":30,~"vl_proforma~":30,~"vl_base_imp~":100,~"calc_imp_container_id~":0,~"log_custo~":1}],~"nfs~":[~{~"documento~":~"123~",~"serie~":~"1~",~"estab~":~"1~",~"nat_operacao~":~"301~",~"cod_emitente~":10,~"vl_mercadoria~":110,~"vl_despesa~":20}],~"payments~":[~{~"num_id_tit_ap~":7,~"vl_real~":100,~"vl_dolar~":20}],~"discounts~":[~{~"desconto_importacao_id~":2,~"vl_autoriz_real~":0,~"vl_autoriz_dolar~":0,~"log_custo~":1}]}"),JsonObject). DELETE OBJECT parser.
 IF modeValue="wrong-context" THEN result:Set("container_id",999).
 IF modeValue="null-confirmed" THEN result:SetNull("confirmed").
 IF modeValue="null-complete" THEN DO: result:SetNull("actual_complete"). result:GetJsonObject("cost"):SetNull("actual_complete"). END.
 IF modeValue="null-distribution" THEN result:GetJsonObject("header"):SetNull("log_gerar_distr_custo").
 IF modeValue="wrong-cost-source" THEN result:GetJsonObject("cost"):Set("source","unconfirmed").
 IF modeValue BEGINS "distribution" THEN result:GetJsonObject("header"):Set("log_gerar_distr_custo",TRUE).
 IF modeValue="duplicate-item" THEN DO:
  result:GetJsonObject("cost"):GetJsonArray("items_real"):Add(CAST(result:GetJsonObject("cost"):GetJsonArray("items_real"):GetJsonObject(1):Clone(),JsonObject)).
  result:GetJsonObject("cost"):GetJsonArray("items_dolar"):Add(CAST(result:GetJsonObject("cost"):GetJsonArray("items_dolar"):GetJsonObject(1):Clone(),JsonObject)).
  result:GetJsonObject("cost"):GetJsonObject("input_snapshot"):GetJsonArray("items"):Add(CAST(result:GetJsonObject("cost"):GetJsonObject("input_snapshot"):GetJsonArray("items"):GetJsonObject(1):Clone(),JsonObject)).
 END.
 IF modeValue="unordered-items" THEN DO:
  rowValue=CAST(result:GetJsonObject("cost"):GetJsonArray("items_real"):GetJsonObject(1):Clone(),JsonObject).
  rowValue:Set("item_container_id",22). rowValue:Set("codigo_erp","ERP-22"). rowValue:Set("vl_unit_prev",26).
  result:GetJsonObject("cost"):GetJsonArray("items_real"):Add(rowValue).
  rowValue=CAST(result:GetJsonObject("cost"):GetJsonArray("items_dolar"):GetJsonObject(1):Clone(),JsonObject).
  rowValue:Set("item_container_id",22). rowValue:Set("vl_unit_prev",5.2).
  reorderedRows=NEW JsonArray(). reorderedRows:Add(rowValue). reorderedRows:Add(CAST(result:GetJsonObject("cost"):GetJsonArray("items_dolar"):GetJsonObject(1):Clone(),JsonObject)).
  result:GetJsonObject("cost"):Set("items_dolar",reorderedRows).
  rowValue=CAST(result:GetJsonObject("cost"):GetJsonObject("input_snapshot"):GetJsonArray("items"):GetJsonObject(1):Clone(),JsonObject).
  rowValue:Set("item_container_id",22). result:GetJsonObject("cost"):GetJsonObject("input_snapshot"):GetJsonArray("items"):Add(rowValue).
 END.
 IF modeValue="duplicate-expense" THEN result:GetJsonArray("expenses"):Add(CAST(result:GetJsonArray("expenses"):GetJsonObject(1):Clone(),JsonObject)).
 IF modeValue="bad-child" THEN result:GetJsonArray("payments"):GetJsonObject(1):Set("num_id_tit_ap",0).
 IF modeValue="unknown-field" THEN result:GetJsonObject("header"):Add("sql","forged").
 IF modeValue="real-null" THEN DO:
  result:Set("actual_complete",FALSE). result:GetJsonObject("cost"):Set("actual_complete",FALSE).
  result:GetJsonObject("cost"):GetJsonArray("items_real"):GetJsonObject(1):SetNull("vl_unit_real").
  result:GetJsonObject("cost"):GetJsonArray("items_dolar"):GetJsonObject(1):SetNull("vl_unit_real").
 END.
END PROCEDURE.


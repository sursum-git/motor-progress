/* Public sync action uses actual fiscal writer and preserves the legacy master. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE versionBuffers AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE fiscalBuffers AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE closeBuffers AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE seq AS INTEGER NO-UNDO.
DEFINE VARIABLE quoteCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failQuotes AS LOGICAL NO-UNDO.
DEFINE VARIABLE logCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failLog AS LOGICAL NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
RUN Fixture. RUN Invoke.
RUN Check(result:GetLogical("success") AND NOT TRANSACTION,"public sync commits real fiscal service").
RUN Check(result:GetJsonObject("audit"):GetCharacter("operation")="sincronizar","explicit operation preserved").
RUN Check(NOT result:GetJsonObject("audit"):GetJsonObject("before"):GetLogical("log_versao_custo_desatualizada"),"before is master locked before sync").
RUN Check(NOT result:GetJsonObject("audit"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"explicit sync preserves legacy master stale flag").
RUN Check(result:GetJsonObject("audit"):GetJsonObject("after"):IsNull("dt_hr_ult_alt_versao_custo"),"explicit sync does not invent master timestamp change").
RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length>=1,"actual fiscal effects audited").
RUN Check(quoteCalls=1 AND logCalls=1,"one trusted quote capture and confirmed post-commit log").
RUN Check(NOT result:GetJsonObject("audit"):GetJsonObject("actor"):Has("extra"),"public audit normalizes authenticated actor").
RUN Fixture. failQuotes=TRUE. RUN Invoke.
RUN Check(NOT result:GetLogical("success") AND NOT result:Has("audit"),"quote failure returns no confirmed audit").
hb[1]:FIND-FIRST(). RUN Check(NOT hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE,"failed sync does not invalidate master").
RUN Check(seq=1000 AND logCalls=0,"failed capture consumes no ID and queues no commit log").
OUTPUT TO VALUE("containers-processes-fiscal-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; actual fiscal TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Invoke:
 versionBuffers[1]=hb[1]. DO i=1 TO 11: fiscalBuffers[i]=hb[i]. END.
 req=NEW JsonObject(). req:Add("resource","impostos"). req:Add("operation","sincronizar"). req:Add("container_id",123).
 RUN ContainersProcessosService.p(versionBuffers,fiscalBuffers,closeBuffers,?,THIS-PROCEDURE,policy,?,req,OUTPUT result).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER textValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + textValue + " " + STRING(result:GetJsonText()),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE TableDef:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER cFields AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(ht[n]) THEN DELETE OBJECT ht[n].
 CREATE TEMP-TABLE ht[n]. ht[n]:UNDO=TRUE.
 DO j=1 TO NUM-ENTRIES(cFields): f=ENTRY(j,cFields). ht[n]:ADD-NEW-FIELD(ENTRY(1,f,":"),ENTRY(2,f,":"),INTEGER(ENTRY(3,f,":"))). END.
 ht[n]:TEMP-TABLE-PREPARE("fx" + STRING(n)). hb[n]=ht[n]:DEFAULT-BUFFER-HANDLE.
END PROCEDURE.
PROCEDURE Seed:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER lc AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 o=CAST(parser:Parse(lc),JsonObject). names=o:GetNames(). hb[n]:BUFFER-CREATE().
 DO j=1 TO EXTENT(names):
  f=hb[n]:BUFFER-FIELD(names[j]).
  CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN f:BUFFER-VALUE=o:GetCharacter(names[j]).
   WHEN "INTEGER" THEN f:BUFFER-VALUE=o:GetInteger(names[j]).
   WHEN "DECIMAL" THEN f:BUFFER-VALUE=o:GetDecimal(names[j]).
   WHEN "LOGICAL" THEN f:BUFFER-VALUE=o:GetLogical(names[j]).
  END CASE.
 END.
 DELETE OBJECT o.
END PROCEDURE.
PROCEDURE CollectCalculationInputs:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE VARIABLE snap AS JsonObject NO-UNDO. DEFINE VARIABLE f AS CHARACTER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL NO-UNDO. DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("quotes require master transaction",1).
 quoteCalls=quoteCalls + 1. IF failQuotes THEN UNDO, THROW NEW Progress.Lang.AppError("quotes unavailable",1).
 snap=NEW JsonObject().
 DO j=1 TO 6:
  f=ENTRY(j,"vl-dolar-compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar").
  IF master:BUFFER-FIELD(f):DATA-TYPE="CHARACTER" THEN DO: c=master:BUFFER-FIELD(f):BUFFER-VALUE. snap:Add(f,c). END.
  ELSE DO: d=master:BUFFER-FIELD(f):BUFFER-VALUE. snap:Add(f,d). END.
 END.
 o=NEW JsonObject(). o:Add("confirmed",TRUE). o:Add("source","container-cost-collector"). o:Add("container_id",123).
 o:Add("dolar_di",5). o:Add("dolar_compra",5). o:Add("container_snapshot",snap).
END PROCEDURE.
PROCEDURE NextCalculoId:
 DEFINE OUTPUT PARAMETER n AS INTEGER NO-UNDO. seq=seq + 1. n=seq.
END PROCEDURE.
PROCEDURE ValidateDistributionExpense:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER expense AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER proof AS JsonObject NO-UNDO.
 proof=NEW JsonObject(). proof:Add("confirmed",TRUE). proof:Add("container_id",INTEGER(master:BUFFER-FIELD("nr-container"):BUFFER-VALUE)).
 proof:Add("despesa_container_id",INTEGER(expense:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE)). proof:Add("ledger_id",INTEGER(expense:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE)).
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER n AS INTEGER NO-UNDO. seq=seq + 1. n=seq.
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("root log must be queued after commit",1).
 logCalls=logCalls + 1. IF failLog THEN UNDO, THROW NEW Progress.Lang.AppError("test queue unavailable",1).
END PROCEDURE.
PROCEDURE Fixture:
 RUN TableDef(1,"cod-estabel:character:0,nr-container:integer:0,num-pedido:integer:0,nome-ab-forn:character:0,cod-emit-forn:integer:0,comprador:character:0,narrativa:character:0,usuario:character:0,dt-compra:date:0,dt-prev-chegada:date:0,dt-recebimento:date:0,situacao:integer:0,char-1:character:0,dec-1:decimal:0,int-1:integer:0,log-1:logical:0,data-1:date:0,vlr-frete:decimal:0,vlr-seguro:decimal:0,vlr-despesas:decimal:0,exclusivo:logical:0,vl-dolar-venda:decimal:0,vl-dolar-compra:decimal:0,log_liberar_custo_realizado:logical:0,medidas_container:character:0,dt_prev_embarque:date:0,dt_real_embarque:date:0,ind_dt_embarque:integer:0,situacao_container_id:integer:0,ind_dt_prev_chegada:integer:0,log_pagto_final:logical:0,cod_agente_cargas:integer:0,cod_armador:integer:0,cod_tipo_calculo:integer:0,perc_custo:decimal:0,vl_dolar_di:decimal:0,log_gerar_saldo_a_pagar:logical:0,log_gerar_distr_custo:logical:0,ordem_busca_dolar_compra:character:0,ordem_busca_dolar_di:character:0,cod_tipo_proj_dolar:integer:0,vl_proj_dolar:decimal:0,log_versao_custo_desatualizada:logical:0,dt_hr_ult_alt_versao_custo:datetime:0,ptax:decimal:0,cod-depos:character:0,dt_prev_chegada_loja:date:0,estacao:integer:0,num_origem:integer:0,log_rota_indefinida:logical:0").
 RUN TableDef(2,"empresa_id:integer:0,nome:character:0,cod_emp_ems2:integer:0,cod_emp_ems5:integer:0").
 RUN TableDef(3,"item_container_id:integer:0,container_id:integer:0,item_proc_compra_id:integer:0,qt_alocada:decimal:0,qt_confirm_emb:decimal:0,qt_recbto_fisico:decimal:0,log_rec_doc_prazo_emb:logical:0,observacao:character:0,cod_tipo_calculo:integer:0,perc_custo:decimal:0,log_calc_icms:logical:0,log_calc_ipi:logical:0,perc_icms:decimal:0,perc_ipi:decimal:0,preco_liquida_ima:decimal:0").
 RUN TableDef(4,"item_proc_compra_id:integer:0,descricao:character:0,codigo_erp:character:0,qt_dias_producao:integer:0,vl_base_tributacao:decimal:0,unid_medida:character:0,proc_compra_id:integer:0,qt_comprada:decimal:0,vl_custo_dolar:decimal:0,composicao:character:0,peso:character:0,largura:character:0,rolo:character:0,dt_prev_envio_desenhos:date:0,dt_real_envio_desenhos:date:0,log_aprov_so_ld:logical:0,dt_prev_recbto_so_ld:date:0,dt_prev_aprov_so_ld:date:0,dt_real_aprov_so_ld:date:0,coloracao_id:integer:0,dt_maxima_producao:date:0,dt_mostruario:date:0,log_mostruario:logical:0,formato_amostra_id:integer:0,ind_producao_no_prazo:integer:0,ind_relat_semanal_producao:integer:0,ind_qualid_emb:integer:0,ind_laudo_antes_embarque:integer:0,ind_prod_conf_pi:integer:0,ind_rec_amostra_antes_emb:integer:0,ind_qt_conf_proforma:integer:0,ind_tamanho_pecas_correto:integer:0,observacao:character:0,dt_cheg_amostras_emb:date:0,dt_termino_producao:date:0,vl_cubagem:decimal:0,dt_recbto_laudo:date:0,dt_recbto_embalagem:date:0,dt_real_recbto_so_ld:date:0,dt_prev_termino_producao:date:0,qt_dias_calc_so_ld:integer:0,shrinkage:character:0,ind_distr_custo:integer:0,vl_negociado:decimal:0,item_estacao:integer:0,dt_item_certificacao:date:0").
 RUN TableDef(5,"proc_compra_id:integer:0,empresa_id:integer:0,qt_container:integer:0,cod_situacao:integer:0,cod_proc_fornec:character:0,qt_dias_translado:integer:0,cotacao_prevista:decimal:0,observacao:character:0,dt_registro:date:0,fornecedor_id:integer:0,dt_limite:date:0,log_facilid_contato_fornec:logical:0,log_considerar_previsao:logical:0,nr_container_original:character:0").
 RUN TableDef(6,"despesa_id:integer:0,descricao:character:0,log_imposto:integer:0,ordem:integer:0,log_calculada:logical:0,perc_calculo:decimal:0,log_vl_prod_base_calculo:logical:0,log_calc_por_item:logical:0,ind_imposto:integer:0").
 RUN TableDef(7,"empresa_despesa_id:integer:0,despesa_id:integer:0,empresa_id:integer:0,codigo_desp_erp:integer:0,vl_padrao:decimal:0,percentual:decimal:0,cod_nat_operacao:character:0,log_ativo:integer:0,perc_custo:integer:0,percentual_custo:decimal:0,despesa_custo_id:integer:0,log_custo:integer:0").
 RUN TableDef(8,"despesa_id:integer:0,imposto_id:integer:0,empresa_id:integer:0").
 RUN TableDef(9,"relac_desp_calculada_id:integer:0,despesa_id:integer:0,despesa_id_base:integer:0").
 RUN TableDef(10,"container_id:integer:0,dt_hr_calculo:datetime:0,usuario_id:integer:0,memoria_calculo:integer:0,calc_imp_container_id:integer:0,desc_memoria_calc:character:0").
 RUN TableDef(11,"despesa_container_id:integer:0,despesa_id:integer:0,vl_prev:decimal:0,container_id:integer:0,calc_imp_container_id:integer:0,vl_base_imp:decimal:0,vl_negociado:decimal:0,vl_proforma:decimal:0,cta_corren_custo_distr_id:integer:0,log_utilizado:logical:0,log_manual:logical:0,perc_calc:decimal:0,memoria_calculo:character:0,item_container_id:integer:0").
 seq=1000. quoteCalls=0. failQuotes=FALSE. logCalls=0. failLog=FALSE.
 policy=NEW JsonObject(). policy:Add("usuario_id",7). result=NEW JsonObject(). result:Add("login","test-actor"). result:Add("extra","must not leak"). policy:Add("actor",result). policy:Add("despesa_distr_custo",99).
 RUN Seed(1,'~{"nr-container":123,"cod-estabel":"501","vl-dolar-compra":5,"vl_dolar_di":5,"ordem_busca_dolar_compra":"2","ordem_busca_dolar_di":"4","cod_tipo_proj_dolar":1,"vl_proj_dolar":0,"log_versao_custo_desatualizada":false}').
 RUN Seed(2,'~{"empresa_id":1,"cod_emp_ems2":5}').
 RUN Seed(3,'~{"item_container_id":1,"container_id":123,"item_proc_compra_id":11,"qt_alocada":10,"qt_confirm_emb":10,"log_calc_ipi":false}').
 RUN Seed(4,'~{"item_proc_compra_id":11,"proc_compra_id":21,"vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":80}').
 RUN Seed(5,'~{"proc_compra_id":21}').
 RUN Seed(6,'~{"despesa_id":1,"log_imposto":0,"log_calculada":false}').
 RUN Seed(6,'~{"despesa_id":10,"ordem":1,"log_imposto":1,"log_calc_por_item":false,"log_calculada":false}').
 RUN Seed(6,'~{"despesa_id":40,"ordem":2,"log_imposto":0,"log_calculada":true,"perc_calculo":10}').
 RUN Seed(6,'~{"despesa_id":99,"log_imposto":0,"log_calculada":false}').
 RUN Seed(7,'~{"empresa_despesa_id":1,"empresa_id":1,"despesa_id":1,"log_ativo":1}').
 RUN Seed(7,'~{"empresa_despesa_id":10,"empresa_id":1,"despesa_id":10,"percentual":10,"despesa_custo_id":0,"log_ativo":1}').
 RUN Seed(7,'~{"empresa_despesa_id":40,"empresa_id":1,"despesa_id":40,"log_ativo":1}').
 RUN Seed(7,'~{"empresa_despesa_id":99,"empresa_id":1,"despesa_id":99,"log_ativo":1}').
 RUN Seed(9,'~{"despesa_id":40,"despesa_id_base":1}').
 RUN Seed(11,'~{"despesa_container_id":40,"container_id":123,"despesa_id":40,"vl_prev":0,"vl_proforma":0,"vl_negociado":0,"log_manual":false,"perc_calc":10,"item_container_id":0,"vl_base_imp":0}').
 RUN Seed(11,'~{"despesa_container_id":99,"container_id":123,"despesa_id":99,"vl_prev":0,"vl_proforma":0,"vl_negociado":0,"log_manual":true,"perc_calc":0,"item_container_id":0,"vl_base_imp":0}').
END PROCEDURE.

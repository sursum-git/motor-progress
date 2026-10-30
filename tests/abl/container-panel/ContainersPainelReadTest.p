/* Fixtures exclusively temp-tables; never publish this test. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttContainer NO-UNDO
  FIELD cod-estabel AS CHARACTER
  FIELD nr-container AS INTEGER
  FIELD num-pedido AS INTEGER
  FIELD nome-ab-forn AS CHARACTER
  FIELD cod-emit-forn AS INTEGER
  FIELD comprador AS CHARACTER
  FIELD narrativa AS CHARACTER
  FIELD usuario AS CHARACTER
  FIELD dt-compra AS DATE
  FIELD dt-prev-chegada AS DATE
  FIELD dt-recebimento AS DATE
  FIELD situacao AS INTEGER
  FIELD char-1 AS CHARACTER
  FIELD dec-1 AS DECIMAL DECIMALS 10
  FIELD int-1 AS INTEGER
  FIELD log-1 AS LOGICAL
  FIELD data-1 AS DATE
  FIELD vlr-frete AS DECIMAL DECIMALS 10
  FIELD vlr-seguro AS DECIMAL DECIMALS 10
  FIELD vlr-despesas AS DECIMAL DECIMALS 10
  FIELD exclusivo AS LOGICAL
  FIELD vl-dolar-venda AS DECIMAL DECIMALS 10
  FIELD vl-dolar-compra AS DECIMAL DECIMALS 10
  FIELD log_liberar_custo_realizado AS LOGICAL
  FIELD medidas_container AS CHARACTER
  FIELD dt_prev_embarque AS DATE
  FIELD dt_real_embarque AS DATE
  FIELD ind_dt_embarque AS INTEGER
  FIELD situacao_container_id AS INTEGER
  FIELD ind_dt_prev_chegada AS INTEGER
  FIELD log_pagto_final AS LOGICAL
  FIELD cod_agente_cargas AS INTEGER
  FIELD cod_armador AS INTEGER
  FIELD cod_tipo_calculo AS INTEGER
  FIELD perc_custo AS DECIMAL DECIMALS 10
  FIELD vl_dolar_di AS DECIMAL DECIMALS 10
  FIELD log_gerar_saldo_a_pagar AS LOGICAL
  FIELD log_gerar_distr_custo AS LOGICAL
  FIELD ordem_busca_dolar_compra AS CHARACTER
  FIELD ordem_busca_dolar_di AS CHARACTER
  FIELD cod_tipo_proj_dolar AS INTEGER
  FIELD vl_proj_dolar AS DECIMAL DECIMALS 10
  FIELD log_versao_custo_desatualizada AS LOGICAL
  FIELD dt_hr_ult_alt_versao_custo AS DATETIME
  FIELD ptax AS DECIMAL DECIMALS 10
  FIELD cod-depos AS CHARACTER
  FIELD dt_prev_chegada_loja AS DATE
  FIELD estacao AS INTEGER
  FIELD num_origem AS INTEGER
  FIELD log_rota_indefinida AS LOGICAL
  INDEX pk IS PRIMARY UNIQUE nr-container.
DEFINE TEMP-TABLE ttVersoes NO-UNDO
  FIELD versao_id AS INTEGER
  FIELD dt_hr_versao AS DATETIME-TZ
  FIELD cod_usuario AS CHARACTER
  FIELD descricao AS CHARACTER
  FIELD ind_sit_versao AS INTEGER
  FIELD vl_dolar_compra AS DECIMAL DECIMALS 10
  FIELD vl_desconto_utiliz_dolar AS DECIMAL DECIMALS 10
  FIELD vl_desconto_utiliz_real AS DECIMAL DECIMALS 10
  FIELD tipo_versao_id AS INTEGER
  FIELD container_id AS INTEGER
  FIELD vl_dolar_medio AS DECIMAL DECIMALS 10
  FIELD vl_dolar_di AS DECIMAL DECIMALS 10
  FIELD usuario_id AS INTEGER
  FIELD log_gerar_saldo_a_pagar AS LOGICAL
  FIELD log_gerar_distr_custo AS LOGICAL
  FIELD situacao_container_id AS INTEGER
  FIELD desc_sit_container AS CHARACTER
  FIELD cod_tipo_cotacao AS INTEGER
  FIELD vl_cotacao AS DECIMAL DECIMALS 10
  FIELD data_ref_cotacao AS DATE
  FIELD perc_fixo_container AS DECIMAL DECIMALS 10
  FIELD hist_dolar AS CHARACTER
  INDEX pk IS PRIMARY UNIQUE versao_id.
DEFINE TEMP-TABLE ttAnexos NO-UNDO
  FIELD anexo_container_id AS INTEGER
  FIELD container_id AS INTEGER
  FIELD item_container_id AS INTEGER
  FIELD descricao AS CHARACTER
  FIELD tipos_anexo_id AS INTEGER
  FIELD caminho_arquivo AS CHARACTER
  FIELD dt_hr_arquivo AS DATETIME
  INDEX pk IS PRIMARY UNIQUE anexo_container_id.
DEFINE TEMP-TABLE ttTiposAnexo NO-UNDO
  FIELD tipo_anexo_id AS INTEGER
  FIELD descricao AS CHARACTER
  INDEX pk IS PRIMARY UNIQUE tipo_anexo_id.
DEFINE TEMP-TABLE ttDespesasContainer NO-UNDO
  FIELD despesa_container_id AS INTEGER
  FIELD despesa_id AS INTEGER
  FIELD vl_prev AS DECIMAL DECIMALS 10
  FIELD container_id AS INTEGER
  FIELD calc_imp_container_id AS INTEGER
  FIELD vl_base_imp AS DECIMAL DECIMALS 10
  FIELD vl_negociado AS DECIMAL DECIMALS 10
  FIELD vl_proforma AS DECIMAL DECIMALS 10
  FIELD cta_corren_custo_distr_id AS INTEGER
  FIELD log_utilizado AS LOGICAL
  FIELD log_manual AS LOGICAL
  FIELD perc_calc AS DECIMAL DECIMALS 10
  FIELD memoria_calculo AS CHARACTER
  FIELD item_container_id AS INTEGER
  INDEX pk IS PRIMARY UNIQUE despesa_container_id.
DEFINE TEMP-TABLE ttEmpresasDespesa NO-UNDO
  FIELD empresa_despesa_id AS INTEGER
  FIELD despesa_id AS INTEGER
  FIELD empresa_id AS INTEGER
  FIELD codigo_desp_erp AS INTEGER
  FIELD vl_padrao AS DECIMAL DECIMALS 10
  FIELD percentual AS DECIMAL DECIMALS 10
  FIELD cod_nat_operacao AS CHARACTER
  FIELD log_ativo AS INTEGER
  FIELD perc_custo AS INTEGER
  FIELD percentual_custo AS DECIMAL DECIMALS 10
  FIELD despesa_custo_id AS INTEGER
  FIELD log_custo AS INTEGER
  INDEX pk IS PRIMARY UNIQUE empresa_despesa_id.
DEFINE TEMP-TABLE ttDespesas NO-UNDO
  FIELD despesa_id AS INTEGER
  FIELD descricao AS CHARACTER
  FIELD log_imposto AS INTEGER
  FIELD ordem AS INTEGER
  FIELD log_calculada AS LOGICAL
  FIELD perc_calculo AS DECIMAL DECIMALS 10
  FIELD log_vl_prod_base_calculo AS LOGICAL
  FIELD log_calc_por_item AS LOGICAL
  FIELD ind_imposto AS INTEGER
  INDEX pk IS PRIMARY UNIQUE despesa_id.
DEFINE TEMP-TABLE ttEmpresas NO-UNDO
  FIELD empresa_id AS INTEGER
  FIELD nome AS CHARACTER
  FIELD cod_emp_ems2 AS INTEGER
  FIELD cod_emp_ems5 AS INTEGER
  INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttItensContainer NO-UNDO
  FIELD item_container_id AS INTEGER
  FIELD container_id AS INTEGER
  FIELD item_proc_compra_id AS INTEGER
  FIELD qt_alocada AS DECIMAL DECIMALS 10
  FIELD qt_confirm_emb AS DECIMAL DECIMALS 10
  FIELD qt_recbto_fisico AS DECIMAL DECIMALS 10
  FIELD log_rec_doc_prazo_emb AS LOGICAL
  FIELD observacao AS CHARACTER
  FIELD cod_tipo_calculo AS INTEGER
  FIELD perc_custo AS DECIMAL DECIMALS 10
  FIELD log_calc_icms AS LOGICAL
  FIELD log_calc_ipi AS LOGICAL
  FIELD perc_icms AS DECIMAL DECIMALS 10
  FIELD perc_ipi AS DECIMAL DECIMALS 10
  FIELD preco_liquida_ima AS DECIMAL DECIMALS 10
  INDEX pk IS PRIMARY UNIQUE item_container_id.
DEFINE TEMP-TABLE ttItensProcCompra NO-UNDO
  FIELD item_proc_compra_id AS INTEGER
  FIELD descricao AS CHARACTER
  FIELD codigo_erp AS CHARACTER
  FIELD qt_dias_producao AS INTEGER
  FIELD vl_base_tributacao AS DECIMAL DECIMALS 10
  FIELD unid_medida AS CHARACTER
  FIELD proc_compra_id AS INTEGER
  FIELD qt_comprada AS DECIMAL DECIMALS 10
  FIELD vl_custo_dolar AS DECIMAL DECIMALS 10
  FIELD composicao AS CHARACTER
  FIELD peso AS CHARACTER
  FIELD largura AS CHARACTER
  FIELD rolo AS CHARACTER
  FIELD dt_prev_envio_desenhos AS DATE
  FIELD dt_real_envio_desenhos AS DATE
  FIELD log_aprov_so_ld AS LOGICAL
  FIELD dt_prev_recbto_so_ld AS DATE
  FIELD dt_prev_aprov_so_ld AS DATE
  FIELD dt_real_aprov_so_ld AS DATE
  FIELD coloracao_id AS INTEGER
  FIELD dt_maxima_producao AS DATE
  FIELD dt_mostruario AS DATE
  FIELD log_mostruario AS LOGICAL
  FIELD formato_amostra_id AS INTEGER
  FIELD ind_producao_no_prazo AS INTEGER
  FIELD ind_relat_semanal_producao AS INTEGER
  FIELD ind_qualid_emb AS INTEGER
  FIELD ind_laudo_antes_embarque AS INTEGER
  FIELD ind_prod_conf_pi AS INTEGER
  FIELD ind_rec_amostra_antes_emb AS INTEGER
  FIELD ind_qt_conf_proforma AS INTEGER
  FIELD ind_tamanho_pecas_correto AS INTEGER
  FIELD observacao AS CHARACTER
  FIELD dt_cheg_amostras_emb AS DATE
  FIELD dt_termino_producao AS DATE
  FIELD vl_cubagem AS DECIMAL DECIMALS 10
  FIELD dt_recbto_laudo AS DATE
  FIELD dt_recbto_embalagem AS DATE
  FIELD dt_real_recbto_so_ld AS DATE
  FIELD dt_prev_termino_producao AS DATE
  FIELD qt_dias_calc_so_ld AS INTEGER
  FIELD shrinkage AS CHARACTER
  FIELD ind_distr_custo AS INTEGER
  FIELD vl_negociado AS DECIMAL DECIMALS 10
  FIELD item_estacao AS INTEGER
  FIELD dt_item_certificacao AS DATE
  INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttProcsCompra NO-UNDO
  FIELD proc_compra_id AS INTEGER
  FIELD empresa_id AS INTEGER
  FIELD qt_container AS INTEGER
  FIELD cod_situacao AS INTEGER
  FIELD cod_proc_fornec AS CHARACTER
  FIELD qt_dias_translado AS INTEGER
  FIELD cotacao_prevista AS DECIMAL DECIMALS 10
  FIELD observacao AS CHARACTER
  FIELD dt_registro AS DATE
  FIELD fornecedor_id AS INTEGER
  FIELD dt_limite AS DATE
  FIELD log_facilid_contato_fornec AS LOGICAL
  FIELD log_considerar_previsao AS LOGICAL
  FIELD nr_container_original AS CHARACTER
  INDEX pk IS PRIMARY UNIQUE proc_compra_id.

DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cInvalid AS CHARACTER NO-UNDO.

OUTPUT TO VALUE("container-panel-read-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
  /* Every resource must validate master before looking for children. */
  DO i = 1 TO 5:
    cResource = ENTRY(i,"painel,versoes,anexos,despesas,itens").
    RUN NewRequest("read", cResource, 71, 0). RUN ExecuteRequest.
    RUN ExpectError("CONTAINER_NOT_FOUND",404).
  END.
  CREATE ttContainer. ASSIGN ttContainer.nr-container=71 ttContainer.cod-estabel="501"
    ttContainer.nome-ab-forn="Importação São José" ttContainer.vl-dolar-compra=5.12345
    ttContainer.dt-compra=DATE(10,16,2026) ttContainer.dt-prev-chegada=?
    ttContainer.exclusivo=TRUE ttContainer.dt_hr_ult_alt_versao_custo=DATETIME(10,16,2026,11,12,13).
  CREATE ttContainer. ASSIGN ttContainer.nr-container=72 ttContainer.cod-estabel="101".
  CREATE ttEmpresas. ASSIGN ttEmpresas.empresa_id=35 ttEmpresas.cod_emp_ems2=5 ttEmpresas.cod_emp_ems5=9.
  CREATE ttEmpresas. ASSIGN ttEmpresas.empresa_id=31 ttEmpresas.cod_emp_ems2=1.
  CREATE ttVersoes. ASSIGN ttVersoes.versao_id=9 ttVersoes.container_id=71 ttVersoes.descricao="Versão atual"
    ttVersoes.dt_hr_versao=DATETIME-TZ(10,16,2026,11,12,13,0,-180).
  CREATE ttVersoes. ASSIGN ttVersoes.versao_id=5 ttVersoes.container_id=71 ttVersoes.ind_sit_versao=2.
  CREATE ttVersoes. ASSIGN ttVersoes.versao_id=4 ttVersoes.container_id=72.
  CREATE ttAnexos. ASSIGN ttAnexos.anexo_container_id=5 ttAnexos.container_id=71
    ttAnexos.tipos_anexo_id=2 ttAnexos.caminho_arquivo="/privado/acervo/documento.pdf"
    ttAnexos.dt_hr_arquivo=DATETIME(10,16,2026,11,12,13).
  CREATE ttAnexos. ASSIGN ttAnexos.anexo_container_id=4 ttAnexos.container_id=72.
  CREATE ttTiposAnexo. ASSIGN ttTiposAnexo.tipo_anexo_id=2 ttTiposAnexo.descricao="Pró-Forma".
  CREATE ttDespesas. ASSIGN ttDespesas.despesa_id=2 ttDespesas.descricao="Frete São José" ttDespesas.ordem=10.
  CREATE ttEmpresasDespesa. ASSIGN ttEmpresasDespesa.empresa_despesa_id=100
    ttEmpresasDespesa.empresa_id=35 ttEmpresasDespesa.despesa_id=2 ttEmpresasDespesa.log_custo=1.
  CREATE ttEmpresasDespesa. ASSIGN ttEmpresasDespesa.empresa_despesa_id=101
    ttEmpresasDespesa.empresa_id=31 ttEmpresasDespesa.despesa_id=2 ttEmpresasDespesa.log_custo=0.
  CREATE ttDespesasContainer. ASSIGN ttDespesasContainer.despesa_container_id=5 ttDespesasContainer.container_id=71
    ttDespesasContainer.despesa_id=2 ttDespesasContainer.vl_prev=10.12345 ttDespesasContainer.vl_negociado=15.98765.
  CREATE ttDespesasContainer. ASSIGN ttDespesasContainer.despesa_container_id=4 ttDespesasContainer.container_id=72
    ttDespesasContainer.despesa_id=2.
  CREATE ttDespesasContainer. ASSIGN ttDespesasContainer.despesa_container_id=6 ttDespesasContainer.container_id=71
    ttDespesasContainer.despesa_id=999.
  CREATE ttItensContainer. ASSIGN ttItensContainer.item_container_id=5 ttItensContainer.container_id=71
    ttItensContainer.item_proc_compra_id=8 ttItensContainer.qt_alocada=12.75 ttItensContainer.qt_recbto_fisico=?
    ttItensContainer.observacao="texto <tag> & ação".
  CREATE ttItensContainer. ASSIGN ttItensContainer.item_container_id=4 ttItensContainer.container_id=72.
  CREATE ttItensProcCompra. ASSIGN ttItensProcCompra.item_proc_compra_id=8
    ttItensProcCompra.descricao="Tecido São José" ttItensProcCompra.codigo_erp="00123"
    ttItensProcCompra.unid_medida="MT" ttItensProcCompra.proc_compra_id=18.
  CREATE ttProcsCompra. ASSIGN ttProcsCompra.proc_compra_id=18 ttProcsCompra.cod_proc_fornec="PI-2026"
    ttProcsCompra.empresa_id=35 ttProcsCompra.fornecedor_id=51.

  RUN NewRequest("get","painel",71,0). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"master get successful").
  joRow=joResponse:GetJsonObject("data").
  RUN AssertTrue(joRow:GetInteger("container_id")=71 AND NOT joRow:Has("nr_container"),"master identity normalized").
  RUN AssertTrue(joRow:GetCharacter("cod_estabel")="501","establishment keeps characters").
  RUN AssertTrue(joRow:GetDecimal("vl_dolar_compra")=5.12345,"five decimal quote preserved").
  RUN AssertTrue(joRow:GetLogical("exclusivo"),"logical is JSON boolean").
  RUN AssertTrue(joRow:GetCharacter("dt_compra")="2026-10-16" AND joRow:IsNull("dt_prev_chegada"),"date ISO and unknown null").
  RUN AssertTrue(joRow:GetCharacter("nome_ab_forn")="Importação São José","UTF8 preserved").
  RUN AssertTrue(INDEX(joRow:GetCharacter("dt_hr_ult_alt_versao_custo"),"2026-10-16T11:12:13")=1,"datetime ISO").
  RUN CheckFields("cod_estabel,container_id,num_pedido,nome_ab_forn,cod_emit_forn,comprador,narrativa,usuario,dt_compra,dt_prev_chegada,dt_recebimento,situacao,char_1,dec_1,int_1,log_1,data_1,vlr_frete,vlr_seguro,vlr_despesas,exclusivo,vl_dolar_venda,vl_dolar_compra,log_liberar_custo_realizado,medidas_container,dt_prev_embarque,dt_real_embarque,ind_dt_embarque,situacao_container_id,ind_dt_prev_chegada,log_pagto_final,cod_agente_cargas,cod_armador,cod_tipo_calculo,perc_custo,vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar,log_versao_custo_desatualizada,dt_hr_ult_alt_versao_custo,ptax,cod_depos,dt_prev_chegada_loja,estacao,num_origem,log_rota_indefinida").

  DO i=2 TO 5:
    cResource=ENTRY(i,"painel,versoes,anexos,despesas,itens").
    RUN NewRequest("read",cResource,71,0). RUN ExecuteRequest.
    RUN AssertTrue(joResponse:GetLogical("success"),cResource + " read successful").
    jaRows=joResponse:GetJsonArray("data").
    RUN AssertTrue(jaRows:Length=(IF cResource="versoes" THEN 2 ELSE 1),cResource + " fixed master filter and joins").
    joRow=jaRows:GetJsonObject(1).
    RUN AssertTrue(joRow:GetInteger("container_id")=71,cResource + " parent included").
    CASE cResource:
      WHEN "versoes" THEN DO:
        RUN AssertTrue(joRow:GetInteger("versao_id")=5,"versions ordered PK ascending").
        RUN AssertTrue(joRow:GetCharacter("situacao_descricao")="Completo","version situation lookup").
        RUN CheckFields("versao_id,dt_hr_versao,cod_usuario,descricao,ind_sit_versao,vl_dolar_compra,vl_desconto_utiliz_dolar,vl_desconto_utiliz_real,tipo_versao_id,container_id,vl_dolar_medio,vl_dolar_di,usuario_id,log_gerar_saldo_a_pagar,log_gerar_distr_custo,situacao_container_id,desc_sit_container,cod_tipo_cotacao,vl_cotacao,data_ref_cotacao,perc_fixo_container,hist_dolar,situacao_descricao").
        joRow=jaRows:GetJsonObject(2).
        RUN AssertTrue(INDEX(joRow:GetCharacter("dt_hr_versao"),"2026-10-16T11:12:13")=1 AND INDEX(joRow:GetCharacter("dt_hr_versao"),"-03:00")>0,"datetime TZ offset preserved").
      END.
      WHEN "anexos" THEN DO:
        RUN AssertTrue(joRow:GetLogical("tem_arquivo") AND NOT joRow:Has("caminho_arquivo"),"storage path never exposed").
        RUN AssertTrue(joRow:GetCharacter("tipo_anexo_descricao")="Pró-Forma","attachment type lookup").
        RUN CheckFields("anexo_container_id,container_id,item_container_id,descricao,tipos_anexo_id,dt_hr_arquivo,tem_arquivo,tipo_anexo_descricao").
      END.
      WHEN "despesas" THEN DO:
        RUN AssertTrue(joRow:GetInteger("empresa_id")=35 AND joRow:GetInteger("log_custo")=1,"company mapping uses EMS2 code not EMS5 or ID").
        RUN AssertTrue(joRow:GetDecimal("vl_distr")=-5.8642 AND joRow:GetDecimal("vl_a_distr")=5.8642,"expense arithmetic keeps precision").
        RUN CheckFields("despesa_container_id,despesa_id,vl_prev,container_id,calc_imp_container_id,vl_base_imp,vl_negociado,vl_proforma,cta_corren_custo_distr_id,log_utilizado,log_manual,perc_calc,memoria_calculo,item_container_id,descricao,ordem,empresa_id,log_custo,vl_distr,vl_a_distr").
      END.
      WHEN "itens" THEN DO:
        RUN AssertTrue(joRow:GetCharacter("codigo_erp")="00123" AND joRow:GetCharacter("descricao_item")="Tecido São José","purchase item lookup preserves ERP code").
        RUN AssertTrue(joRow:GetInteger("proc_compra_id")=18 AND joRow:GetInteger("empresa_pedido_id")=35 AND joRow:GetInteger("fornecedor_id")=51,"purchase process lookup").
        RUN AssertTrue(joRow:GetDecimal("qt_alocada")=12.75 AND joRow:IsNull("qt_recbto_fisico"),"quantity decimal and null").
        RUN AssertTrue(joRow:GetCharacter("observacao")="texto <tag> & ação","text passed as data").
        RUN AssertTrue(NOT joRow:Has("vl_total_prev"),"unimplemented cost not fabricated").
        RUN CheckFields("item_container_id,container_id,item_proc_compra_id,qt_alocada,qt_confirm_emb,qt_recbto_fisico,log_rec_doc_prazo_emb,observacao,cod_tipo_calculo,perc_custo,log_calc_icms,log_calc_ipi,perc_icms,perc_ipi,preco_liquida_ima,descricao_item,codigo_erp,unid_medida,proc_compra_id,cod_proc_fornec,fornecedor_id,empresa_pedido_id").
      END.
    END CASE.
    RUN NewRequest("get",cResource,71,5). RUN ExecuteRequest.
    RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:GetJsonObject("data"):GetInteger("container_id")=71,cResource + " get shape").
    RUN NewRequest("get",cResource,71,4). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).
    RUN NewRequest("get",cResource,71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
    RUN NewRequest("read",cResource,999,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_NOT_FOUND",404).
  END.
  RUN NewRequest("get","itens",71,5). joRequest:Add("item_container_id",5). RUN ExecuteRequest. RUN AssertTrue(joResponse:GetLogical("success"),"native PK alias accepted").
  RUN NewRequest("get","itens",71,5). joRequest:Add("item_container_id",4). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN NewRequest("get","painel",71,72). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN NewRequest("read","painel",71,5). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN NewRequest("delete","itens",71,5). RUN ExecuteRequest. RUN ExpectError("CONTAINER_OPERATION_INVALID",422).
  RUN NewRequest("read","unknown",71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_RESOURCE_INVALID",422).
  RUN NewRequest("read","itens",71,0). joRequest:Add("table","pp-container"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  DO j=1 TO 11:
    cInvalid=ENTRY(j,"0,-1,2147483648,1.0,1e1,1 OR TRUE, 71,71 ,+,?,null").
    RUN NewRequest("read","itens",71,0). joRequest:Remove("container_id"). joRequest:Add("container_id",cInvalid).
    RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  END.
  RUN NewRequest("read","itens",71,0). joRequest:Remove("container_id"). joRequest:AddNull("container_id"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN NewRequest("read","itens",71,0). joRequest:Remove("container_id"). joRequest:Add("container_id",TRUE). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN NewRequest("READ","itens",71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_OPERATION_INVALID",422).
  RUN NewRequest("read","ITENS",71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_RESOURCE_INVALID",422).
  RUN NewRequest("read","itens",71,0). joRequest:Add("Container_id",71). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  CREATE ttContainer. ASSIGN ttContainer.nr-container=73 ttContainer.cod-estabel="701".
  DO i=1 TO 4:
    RUN NewRequest("read",ENTRY(i,"versoes,anexos,despesas,itens"),73,0). RUN ExecuteRequest.
    IF i=3 THEN RUN ExpectError("CONTAINER_COMPANY_CONTEXT",422).
    ELSE RUN AssertTrue(joResponse:GetJsonArray("data"):Length=0,"existing parent with no children returns empty array").
  END.
  FIND ttItensContainer WHERE ttItensContainer.item_container_id=5.
  ttItensContainer.item_proc_compra_id=999.
  RUN NewRequest("get","itens",71,5). RUN ExecuteRequest.
  joRow=joResponse:GetJsonObject("data").
  RUN AssertTrue(joRow:IsNull("descricao_item") AND joRow:IsNull("proc_compra_id") AND joRow:IsNull("fornecedor_id"),"missing lookups never reuse previous record").
  FIND ttItensContainer WHERE ttItensContainer.item_container_id=5. ttItensContainer.item_proc_compra_id=8.
  FIND ttAnexos WHERE ttAnexos.anexo_container_id=5.
  ASSIGN ttAnexos.caminho_arquivo=? ttAnexos.tipos_anexo_id=999.
  RUN NewRequest("get","anexos",71,5). RUN ExecuteRequest.
  joRow=joResponse:GetJsonObject("data").
  RUN AssertTrue(NOT joRow:GetLogical("tem_arquivo") AND joRow:IsNull("tipo_anexo_descricao"),"unknown path and missing attachment type").
  FIND ttDespesasContainer WHERE ttDespesasContainer.despesa_container_id=5.
  ttDespesasContainer.vl_negociado=5.
  RUN NewRequest("get","despesas",71,5). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetDecimal("vl_a_distr")=0,"negative expense distribution clamped to zero").
  FIND ttDespesasContainer WHERE ttDespesasContainer.despesa_container_id=5. ttDespesasContainer.vl_prev=?.
  RUN NewRequest("get","despesas",71,5). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):IsNull("vl_distr") AND joResponse:GetJsonObject("data"):IsNull("vl_a_distr"),"unknown expense value stays unknown").
  /* Zero is a valid EMS2 code when an actual unique company mapping exists. */
  FIND ttContainer WHERE ttContainer.nr-container=71. ttContainer.cod-estabel="001".
  FIND ttEmpresas WHERE ttEmpresas.empresa_id=35. ttEmpresas.cod_emp_ems2=0.
  RUN NewRequest("read","despesas",71,0). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:GetJsonArray("data"):Length=1,"zero EMS2 code maps explicitly").
  FIND ttEmpresas WHERE ttEmpresas.empresa_id=35. ttEmpresas.cod_emp_ems2=5.
  FIND ttContainer WHERE ttContainer.nr-container=71. ttContainer.cod-estabel="501".
  CREATE ttEmpresasDespesa. ASSIGN ttEmpresasDespesa.empresa_despesa_id=102
    ttEmpresasDespesa.empresa_id=35 ttEmpresasDespesa.despesa_id=2.
  RUN NewRequest("read","despesas",71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_COMPANY_CONTEXT",422).
  FIND ttEmpresasDespesa WHERE ttEmpresasDespesa.empresa_despesa_id=102. DELETE ttEmpresasDespesa.
  FIND ttContainer WHERE nr-container=71. ttContainer.cod-estabel="X01".
  RUN NewRequest("read","despesas",71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_COMPANY_CONTEXT",422).
  ttContainer.cod-estabel="501".
  CREATE ttEmpresas. ASSIGN ttEmpresas.empresa_id=99 ttEmpresas.cod_emp_ems2=5.
  RUN NewRequest("read","despesas",71,0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_COMPANY_CONTEXT",422).
  FIND ttEmpresas WHERE ttEmpresas.empresa_id=99. DELETE ttEmpresas.
  FIND ttItensContainer WHERE ttItensContainer.item_container_id=5. ttItensContainer.qt_alocada=99.99.
  RUN NewRequest("get","itens",71,5). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetDecimal("qt_alocada")=99.99,"read does not cache prior values").
  RUN AssertTrue(CAN-FIND(ttItensContainer WHERE ttItensContainer.item_container_id=4),"unrelated fixture preserved").
  PUT UNFORMATTED "PASS: " iPassed " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
  CATCH e AS Progress.Lang.Error:
    PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
    OUTPUT CLOSE.
    UNDO, THROW e.
  END CATCH.
END.
OUTPUT CLOSE.

PROCEDURE NewRequest:
  DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcResource AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piContainer AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER piId AS INTEGER NO-UNDO.
  IF VALID-OBJECT(joRequest) THEN DELETE OBJECT joRequest.
  IF VALID-OBJECT(joResponse) THEN DELETE OBJECT joResponse.
  joRequest=NEW JsonObject().
  joRequest:Add("operation",pcOperation). joRequest:Add("resource",pcResource).
  joRequest:Add("container_id",piContainer).
  IF piId<>0 THEN joRequest:Add("id",piId).
END PROCEDURE.
PROCEDURE ExecuteRequest:
  RUN ContainersPainelReadService.p (INPUT BUFFER ttContainer:HANDLE, INPUT BUFFER ttVersoes:HANDLE,
    INPUT BUFFER ttAnexos:HANDLE, INPUT BUFFER ttTiposAnexo:HANDLE, INPUT BUFFER ttDespesasContainer:HANDLE,
    INPUT BUFFER ttEmpresasDespesa:HANDLE, INPUT BUFFER ttDespesas:HANDLE, INPUT BUFFER ttEmpresas:HANDLE,
    INPUT BUFFER ttItensContainer:HANDLE, INPUT BUFFER ttItensProcCompra:HANDLE, INPUT BUFFER ttProcsCompra:HANDLE,
    joRequest, OUTPUT joResponse).
END PROCEDURE.
PROCEDURE AssertTrue:
  DEFINE INPUT PARAMETER plValue AS LOGICAL NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  IF plValue<>TRUE OR plValue=? THEN UNDO, THROW NEW Progress.Lang.AppError(pcMessage,0).
  iPassed=iPassed + 1.
END PROCEDURE.
PROCEDURE ExpectError:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  RUN AssertTrue(NOT joResponse:GetLogical("success"),"error must fail").
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetCharacter("code")=pcCode,"error code " + pcCode).
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetInteger("status")=piStatus,"error status").
  RUN AssertTrue(NOT joResponse:Has("data"),"error no data").
END PROCEDURE.
PROCEDURE CheckFields:
  DEFINE INPUT PARAMETER pcAllowed AS CHARACTER NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  EXTENT(cNames)=?.
  cNames=joRow:GetNames().
  RUN AssertTrue(EXTENT(cNames)=NUM-ENTRIES(pcAllowed),"exact field count").
  DO k=1 TO NUM-ENTRIES(pcAllowed):
    RUN AssertTrue(joRow:Has(ENTRY(k,pcAllowed)),"allowed field " + ENTRY(k,pcAllowed)).
  END.
END PROCEDURE.

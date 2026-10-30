/* Undoable TT definitions from checked physical schemas. Tests only. */
DEFINE TEMP-TABLE ttMaster
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
 FIELD dec-1 AS DECIMAL DECIMALS 8
 FIELD int-1 AS INTEGER
 FIELD log-1 AS LOGICAL INITIAL FALSE
 FIELD data-1 AS DATE
 FIELD vlr-frete AS DECIMAL DECIMALS 2
 FIELD vlr-seguro AS DECIMAL DECIMALS 2
 FIELD vlr-despesas AS DECIMAL DECIMALS 2
 FIELD exclusivo AS LOGICAL INITIAL FALSE
 FIELD vl-dolar-venda AS DECIMAL DECIMALS 5
 FIELD vl-dolar-compra AS DECIMAL DECIMALS 5
 FIELD log_liberar_custo_realizado AS LOGICAL INITIAL FALSE
 FIELD medidas_container AS CHARACTER
 FIELD dt_prev_embarque AS DATE
 FIELD dt_real_embarque AS DATE
 FIELD ind_dt_embarque AS INTEGER
 FIELD situacao_container_id AS INTEGER
 FIELD ind_dt_prev_chegada AS INTEGER
 FIELD log_pagto_final AS LOGICAL INITIAL FALSE
 FIELD cod_agente_cargas AS INTEGER
 FIELD cod_armador AS INTEGER
 FIELD cod_tipo_calculo AS INTEGER
 FIELD perc_custo AS DECIMAL DECIMALS 2
 FIELD vl_dolar_di AS DECIMAL DECIMALS 5
 FIELD log_gerar_saldo_a_pagar AS LOGICAL INITIAL TRUE
 FIELD log_gerar_distr_custo AS LOGICAL INITIAL TRUE
 FIELD ordem_busca_dolar_compra AS CHARACTER
 FIELD ordem_busca_dolar_di AS CHARACTER
 FIELD cod_tipo_proj_dolar AS INTEGER
 FIELD vl_proj_dolar AS DECIMAL DECIMALS 5
 FIELD log_versao_custo_desatualizada AS LOGICAL INITIAL TRUE
 FIELD dt_hr_ult_alt_versao_custo AS DATETIME
 FIELD ptax AS DECIMAL DECIMALS 5
 FIELD cod-depos AS CHARACTER
 FIELD dt_prev_chegada_loja AS DATE
 FIELD estacao AS INTEGER
 FIELD num_origem AS INTEGER
 FIELD log_rota_indefinida AS LOGICAL INITIAL FALSE
 INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttItems
 FIELD item_container_id AS INTEGER
 FIELD container_id AS INTEGER
 FIELD item_proc_compra_id AS INTEGER
 FIELD qt_alocada AS DECIMAL DECIMALS 2
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 2
 FIELD qt_recbto_fisico AS DECIMAL DECIMALS 2
 FIELD log_rec_doc_prazo_emb AS LOGICAL INITIAL TRUE
 FIELD observacao AS CHARACTER
 FIELD cod_tipo_calculo AS INTEGER
 FIELD perc_custo AS DECIMAL DECIMALS 2
 FIELD log_calc_icms AS LOGICAL INITIAL FALSE
 FIELD log_calc_ipi AS LOGICAL INITIAL TRUE
 FIELD perc_icms AS DECIMAL DECIMALS 2
 FIELD perc_ipi AS DECIMAL DECIMALS 2
 FIELD preco_liquida_ima AS DECIMAL DECIMALS 2
 INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttPurchaseItems
 FIELD item_proc_compra_id AS INTEGER
 FIELD descricao AS CHARACTER
 FIELD codigo_erp AS CHARACTER
 FIELD qt_dias_producao AS INTEGER
 FIELD vl_base_tributacao AS DECIMAL DECIMALS 5
 FIELD unid_medida AS CHARACTER
 FIELD proc_compra_id AS INTEGER
 FIELD qt_comprada AS DECIMAL DECIMALS 2
 FIELD vl_custo_dolar AS DECIMAL DECIMALS 10
 FIELD composicao AS CHARACTER
 FIELD peso AS CHARACTER
 FIELD largura AS CHARACTER
 FIELD rolo AS CHARACTER
 FIELD dt_prev_envio_desenhos AS DATE
 FIELD dt_real_envio_desenhos AS DATE
 FIELD log_aprov_so_ld AS LOGICAL INITIAL FALSE
 FIELD dt_prev_recbto_so_ld AS DATE
 FIELD dt_prev_aprov_so_ld AS DATE
 FIELD dt_real_aprov_so_ld AS DATE
 FIELD coloracao_id AS INTEGER
 FIELD dt_maxima_producao AS DATE
 FIELD dt_mostruario AS DATE
 FIELD log_mostruario AS LOGICAL INITIAL TRUE
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
 FIELD vl_cubagem AS DECIMAL DECIMALS 2
 FIELD dt_recbto_laudo AS DATE
 FIELD dt_recbto_embalagem AS DATE
 FIELD dt_real_recbto_so_ld AS DATE
 FIELD dt_prev_termino_producao AS DATE
 FIELD qt_dias_calc_so_ld AS INTEGER
 FIELD shrinkage AS CHARACTER
 FIELD ind_distr_custo AS INTEGER
 FIELD vl_negociado AS DECIMAL DECIMALS 5
 FIELD item_estacao AS INTEGER
 FIELD dt_item_certificacao AS DATE
 INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttPurchases
 FIELD proc_compra_id AS INTEGER
 FIELD empresa_id AS INTEGER
 FIELD qt_container AS INTEGER
 FIELD cod_situacao AS INTEGER
 FIELD cod_proc_fornec AS CHARACTER
 FIELD qt_dias_translado AS INTEGER
 FIELD cotacao_prevista AS DECIMAL DECIMALS 2
 FIELD observacao AS CHARACTER
 FIELD dt_registro AS DATE
 FIELD fornecedor_id AS INTEGER
 FIELD dt_limite AS DATE
 FIELD log_facilid_contato_fornec AS LOGICAL INITIAL TRUE
 FIELD log_considerar_previsao AS LOGICAL INITIAL TRUE
 FIELD nr_container_original AS CHARACTER
 INDEX pk IS UNIQUE PRIMARY proc_compra_id.
DEFINE TEMP-TABLE ttDiscounts
 FIELD desconto_importacao_id AS INTEGER
 FIELD motivo_desconto_id AS INTEGER
 FIELD descricao AS CHARACTER
 FIELD log_credito AS LOGICAL INITIAL FALSE
 FIELD vl_dolar AS DECIMAL DECIMALS 2
 FIELD vl_real AS DECIMAL DECIMALS 2
 FIELD vl_cotacao_dolar AS DECIMAL DECIMALS 2
 FIELD item_container_id AS INTEGER
 FIELD cod_tipo AS INTEGER
 FIELD fornecedor_id AS INTEGER
 FIELD vl_real_autorizado AS DECIMAL DECIMALS 2
 FIELD vl_dolar_autorizado AS DECIMAL DECIMALS 2
 FIELD dt_autorizacao AS DATE
 FIELD arquivo AS CHARACTER
 INDEX pk IS UNIQUE PRIMARY desconto_importacao_id.
DEFINE TEMP-TABLE ttItemCosts
 FIELD item_container_custo_id AS INTEGER
 FIELD vl_custo_prev_dolar AS DECIMAL DECIMALS 5
 FIELD qt_embarcada AS DECIMAL DECIMALS 2
 FIELD it_codigo AS CHARACTER
 FIELD item_custo_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD memoria_calculo AS CHARACTER
 FIELD vl_custo_prev_real AS DECIMAL DECIMALS 2
 FIELD vl_desp_prev_dolar AS DECIMAL DECIMALS 2
 FIELD vl_desp_prev_real AS DECIMAL DECIMALS 2
 FIELD vl_pago_dolar AS DECIMAL DECIMALS 2
 FIELD vl_pago_real AS DECIMAL DECIMALS 2
 FIELD qt_alocada AS DECIMAL DECIMALS 2
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 2
 FIELD qt_recebto_fisico AS DECIMAL DECIMALS 2
 FIELD vl_desp_realiz_real AS DECIMAL DECIMALS 2
 FIELD vl_desp_realiz_dolar AS DECIMAL DECIMALS 2
 FIELD vl_desconto_utiliz_dolar AS DECIMAL DECIMALS 2
 FIELD vl_desconto_utiliz_real AS CHARACTER
 FIELD vl_unit_prev AS DECIMAL DECIMALS 5
 FIELD vl_unit_realiz AS DECIMAL DECIMALS 5
 FIELD item_container_id AS INTEGER
 FIELD vl_unit_prev_dolar AS DECIMAL DECIMALS 5
 FIELD vl_unit_realiz_dolar AS DECIMAL DECIMALS 5
 FIELD vl_desp_prev_perc_fixo AS DECIMAL DECIMALS 2
 FIELD vl_custo_distribuido AS DECIMAL DECIMALS 2
 FIELD vl_negociado AS DECIMAL DECIMALS 5
 FIELD vl_saldo_a_pagar AS DECIMAL DECIMALS 2
 FIELD vl_desp_prev_real_sem_distr_cust AS DECIMAL DECIMALS 2
 FIELD vl_desp_prev_dolar_sem_distr_cus AS DECIMAL DECIMALS 2
 FIELD vl_distr_custo AS DECIMAL DECIMALS 2
 INDEX pk IS UNIQUE PRIMARY item_container_custo_id.
DEFINE TEMP-TABLE ttCommercial
 FIELD nr-container AS INTEGER
 FIELD it-comprado AS CHARACTER
 FIELD desc-item AS CHARACTER
 FIELD ref-comprada AS CHARACTER
 FIELD qt-pedida AS DECIMAL DECIMALS 2
 FIELD qt-vendida AS DECIMAL DECIMALS 2
 FIELD qt-recebida AS DECIMAL DECIMALS 2
 FIELD preco-compra AS DECIMAL DECIMALS 2
 FIELD it-codigo AS CHARACTER
 FIELD cod-refer AS CHARACTER
 FIELD char-1 AS CHARACTER
 FIELD dec-1 AS DECIMAL DECIMALS 8
 FIELD int-1 AS INTEGER
 FIELD log-1 AS LOGICAL INITIAL FALSE
 FIELD data-1 AS DATE
 FIELD preco-venda AS DECIMAL DECIMALS 2
 FIELD narrativa AS CHARACTER
 FIELD class-fiscal AS CHARACTER
 FIELD perc-dsp-venda AS DECIMAL DECIMALS 2
 FIELD mo-codigo AS INTEGER
 FIELD preco-vd-real AS DECIMAL DECIMALS 2
 FIELD preco-vd-dolar AS DECIMAL DECIMALS 2
 FIELD qt_faturada AS DECIMAL DECIMALS 2
 FIELD vl_preco_medio AS DECIMAL DECIMALS 2
 FIELD qt_prazo_medio AS INTEGER
 FIELD dt_hr_atu_fat AS DATETIME
 FIELD transacao_id_qt_fat AS INT64
 FIELD qt_devolvida AS DECIMAL DECIMALS 2
 FIELD preco_medio_atu AS DECIMAL DECIMALS 10
 FIELD preco_medio_meta AS DECIMAL DECIMALS 10
 FIELD item_proc_compra_id AS INTEGER
 FIELD cod_estab_definido AS CHARACTER
 INDEX pk IS PRIMARY nr-container.
DEFINE TEMP-TABLE ttItemEffects FIELD calc_imp_container_id AS INTEGER FIELD container_id AS INTEGER FIELD descricao AS CHARACTER INDEX pk IS UNIQUE PRIMARY calc_imp_container_id.

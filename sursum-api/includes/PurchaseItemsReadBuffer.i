DEFINE TEMP-TABLE ttPurchaseItemRead
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
 FIELD dt_prev_envio_desenhos AS DATE INITIAL ?
 FIELD dt_real_envio_desenhos AS DATE INITIAL ?
 FIELD log_aprov_so_ld AS LOGICAL
 FIELD dt_prev_recbto_so_ld AS DATE INITIAL ?
 FIELD dt_prev_aprov_so_ld AS DATE INITIAL ?
 FIELD dt_real_aprov_so_ld AS DATE INITIAL ?
 FIELD coloracao_id AS INTEGER
 FIELD dt_maxima_producao AS DATE INITIAL ?
 FIELD dt_mostruario AS DATE INITIAL ?
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
 FIELD dt_cheg_amostras_emb AS DATE INITIAL ?
 FIELD dt_termino_producao AS DATE INITIAL ?
 FIELD vl_cubagem AS DECIMAL DECIMALS 2
 FIELD dt_recbto_laudo AS DATE INITIAL ?
 FIELD dt_recbto_embalagem AS DATE INITIAL ?
 FIELD dt_real_recbto_so_ld AS DATE INITIAL ?
 FIELD dt_prev_termino_producao AS DATE INITIAL ?
 FIELD qt_dias_calc_so_ld AS INTEGER
 FIELD shrinkage AS CHARACTER
 FIELD ind_distr_custo AS INTEGER
 FIELD vl_negociado AS DECIMAL DECIMALS 5
 FIELD item_estacao AS INTEGER
 FIELD dt_item_certificacao AS DATE INITIAL ?
 FIELD calc_gm AS DECIMAL DECIMALS 10
 FIELD row_stamp AS CHARACTER
 FIELD qt_alocada AS DECIMAL DECIMALS 10
 FIELD qt_saldo AS DECIMAL DECIMALS 10
 INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.

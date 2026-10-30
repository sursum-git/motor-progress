DEFINE TEMP-TABLE ttVersionComparison NO-UNDO
 FIELD container_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD item_container_custo_id AS INTEGER
 FIELD item_container_id AS INTEGER
 FIELD codigo_erp AS CHARACTER
 FIELD descricao AS CHARACTER
 FIELD qt_alocada AS DECIMAL DECIMALS 10
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 10
 FIELD vl_custo_prev AS DECIMAL DECIMALS 10
 FIELD vl_desp_prev AS DECIMAL DECIMALS 10
 FIELD vl_tot_prev AS DECIMAL DECIMALS 10
 FIELD vl_unit_prev AS DECIMAL DECIMALS 10
 FIELD vl_desp_prev_sem_distr_custo AS DECIMAL DECIMALS 10
 FIELD vl_tot_sem_distr_custo AS DECIMAL DECIMALS 10
 FIELD vl_unit_sem_distr_custo AS DECIMAL DECIMALS 10
 FIELD vl_desp_prev_perc_fixo AS DECIMAL DECIMALS 10
 FIELD vl_tot_perc_fixo AS DECIMAL DECIMALS 10
 FIELD vl_unit_perc_fixo AS DECIMAL DECIMALS 10
 FIELD projection_error AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE item_container_custo_id.

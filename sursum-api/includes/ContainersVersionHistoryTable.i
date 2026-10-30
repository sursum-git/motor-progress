DEFINE TEMP-TABLE ttVersionHistory NO-UNDO
 FIELD container_id AS INTEGER
 FIELD item_container_custo_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD item_container_id AS INTEGER
 FIELD it_codigo AS CHARACTER
 FIELD item_custo_id AS INTEGER
 FIELD memoria_calculo AS CHARACTER
 FIELD vl_desp_prev_real AS DECIMAL DECIMALS 10
 FIELD vl_custo_prev_real AS DECIMAL DECIMALS 10
 FIELD vl_pago_real AS DECIMAL DECIMALS 10
 FIELD qt_alocada AS DECIMAL DECIMALS 10
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 10
 FIELD qt_recebto_fisico AS DECIMAL DECIMALS 10
 FIELD vl_desp_realiz_real AS DECIMAL DECIMALS 10
 FIELD vl_unit_prev AS DECIMAL DECIMALS 10
 FIELD vl_unit_realiz AS DECIMAL DECIMALS 10
 FIELD vl_desp_prev_dolar AS DECIMAL DECIMALS 10
 FIELD vl_custo_prev_dolar AS DECIMAL DECIMALS 10
 FIELD vl_pago_dolar AS DECIMAL DECIMALS 10
 FIELD vl_desp_realiz_dolar AS DECIMAL DECIMALS 10
 FIELD vl_desconto_utiliz_dolar AS DECIMAL DECIMALS 10
 FIELD vl_unit_prev_dolar AS DECIMAL DECIMALS 10
 FIELD vl_unit_realiz_dolar AS DECIMAL DECIMALS 10
 FIELD vl_custo_distribuido AS DECIMAL DECIMALS 10
 FIELD vl_negociado AS DECIMAL DECIMALS 10
 FIELD vl_desp_prev_real_sem_distr_cust AS DECIMAL DECIMALS 10
 FIELD vl_desp_prev_dolar_sem_distr_cus AS DECIMAL DECIMALS 10
 FIELD qt_embarcada AS DECIMAL DECIMALS 10
 FIELD vl_desconto_utiliz_real AS CHARACTER
 FIELD item_descricao_atual AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE item_container_custo_id.

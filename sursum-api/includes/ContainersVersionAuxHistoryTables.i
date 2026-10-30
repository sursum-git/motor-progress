DEFINE TEMP-TABLE ttVersionHistoryPayments NO-UNDO
 FIELD container_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD num_id_tit_ap AS INTEGER
 FIELD vl_real AS DECIMAL DECIMALS 10
 FIELD vl_dolar AS DECIMAL DECIMALS 10
 INDEX pk IS PRIMARY UNIQUE versao_id num_id_tit_ap.

DEFINE TEMP-TABLE ttVersionHistoryNfs NO-UNDO
 FIELD container_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD documento AS CHARACTER
 FIELD serie AS CHARACTER
 FIELD estab AS CHARACTER
 FIELD nat_operacao AS CHARACTER
 FIELD cod_emitente AS INTEGER
 FIELD vl_mercadoria AS DECIMAL DECIMALS 10
 FIELD vl_despesa AS DECIMAL DECIMALS 10
 FIELD emitente_nome_abrev_atual AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE versao_id documento serie estab nat_operacao cod_emitente.

DEFINE TEMP-TABLE ttVersionHistoryDiscounts NO-UNDO
 FIELD container_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD desconto_importacao_id AS INTEGER
 FIELD vl_autoriz_real AS DECIMAL DECIMALS 10
 FIELD vl_autoriz_dolar AS DECIMAL DECIMALS 10
 FIELD log_custo AS INTEGER
 INDEX pk IS PRIMARY UNIQUE versao_id desconto_importacao_id.

DEFINE TEMP-TABLE ttVersionHistoryExpenses NO-UNDO
 FIELD container_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD despesa_id AS INTEGER
 FIELD vl_prev AS DECIMAL DECIMALS 10
 FIELD vl_base_imp AS DECIMAL DECIMALS 10
 FIELD vl_negociado AS DECIMAL DECIMALS 10
 FIELD log_custo AS INTEGER
 FIELD despesa_descricao_atual AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE versao_id despesa_id.

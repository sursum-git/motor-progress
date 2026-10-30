DEFINE TEMP-TABLE ttImportDiscountsRead NO-UNDO
 FIELD desconto_importacao_id AS INTEGER
 FIELD motivo_desconto_id AS INTEGER
 FIELD descricao AS CHARACTER
 FIELD log_credito AS LOGICAL
 FIELD vl_dolar AS DECIMAL DECIMALS 2
 FIELD vl_real AS DECIMAL DECIMALS 2
 FIELD vl_cotacao_dolar AS DECIMAL DECIMALS 2
 FIELD item_container_id AS INTEGER
 FIELD cod_tipo AS INTEGER
 FIELD fornecedor_id AS INTEGER
 FIELD vl_real_autorizado AS DECIMAL DECIMALS 2
 FIELD vl_dolar_autorizado AS DECIMAL DECIMALS 2
 FIELD dt_autorizacao AS DATE
 FIELD vl_utiliz AS DECIMAL DECIMALS 10
 FIELD vl_utiliz_detalhe AS DECIMAL DECIMALS 10
 FIELD vl_saldo AS DECIMAL DECIMALS 10
 FIELD item_codigo_erp_atual AS CHARACTER INITIAL ?
 FIELD item_descricao_atual AS CHARACTER INITIAL ?
 FIELD fornecedor_nome_abrev_atual AS CHARACTER INITIAL ?
 FIELD motivo_descricao_atual AS CHARACTER INITIAL ?
 INDEX pk IS UNIQUE PRIMARY desconto_importacao_id.
DEFINE TEMP-TABLE ttImportDiscountLedgerRead NO-UNDO
 FIELD cta_corren_desconto_id AS INTEGER
 FIELD desconto_importacao_id AS INTEGER
 FIELD container_id AS INTEGER
 FIELD valor_utilizado AS DECIMAL DECIMALS 2
 FIELD data AS DATE
 FIELD cod_usuario AS DATE
 INDEX pk IS UNIQUE PRIMARY desconto_importacao_id cta_corren_desconto_id.

DEFINE TEMP-TABLE ttCostDistributionLedger NO-UNDO
 FIELD cta_corren_custo_distr_id AS INTEGER
 FIELD data AS DATE
 FIELD historico AS CHARACTER
 FIELD vl_lancto AS DECIMAL DECIMALS 2
 FIELD login AS CHARACTER
 FIELD item_container_custo_id AS INTEGER
 FIELD item_container_id AS INTEGER
 FIELD cod_tipo_movto AS INTEGER
 INDEX pk IS UNIQUE PRIMARY item_container_id cta_corren_custo_distr_id.

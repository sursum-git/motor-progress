/* Test-only undoable projections from the real dictionaries. */
DEFINE TEMP-TABLE ttItems
 FIELD item_container_id AS INTEGER
 FIELD container_id AS INTEGER
 FIELD item_proc_compra_id AS INTEGER
 FIELD qt_alocada AS DECIMAL DECIMALS 2
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 2
 INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttPurchaseItems
 FIELD item_proc_compra_id AS INTEGER
 FIELD proc_compra_id AS INTEGER
 FIELD qt_comprada AS DECIMAL DECIMALS 2
 FIELD vl_custo_dolar AS DECIMAL DECIMALS 10
 FIELD vl_negociado AS DECIMAL DECIMALS 5
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
 FIELD log_facilid_contato_fornec AS LOGICAL
 FIELD log_considerar_previsao AS LOGICAL
 FIELD nr_container_original AS CHARACTER
 INDEX pk IS UNIQUE PRIMARY proc_compra_id.
DEFINE TEMP-TABLE ttLedger
 FIELD cta_corren_fornec_imp_id AS INTEGER
 FIELD fornecedor_id AS INTEGER
 FIELD data AS DATE
 FIELD historico AS CHARACTER
 FIELD cod_tipo_movto AS INTEGER
 FIELD vl_lancto AS DECIMAL DECIMALS 2
 FIELD cod_acao AS INTEGER
 FIELD login AS CHARACTER
 FIELD data_hora AS DATETIME
 FIELD num_id_tit_ap AS INTEGER
 FIELD item_proc_compra_id AS INTEGER
 FIELD item_container_id AS INTEGER
 FIELD transacao_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY cta_corren_fornec_imp_id.
DEFINE TEMP-TABLE ttOrderPayments
 FIELD num_id_tit_ap AS INTEGER
 FIELD proc_compra_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY num_id_tit_ap proc_compra_id.
DEFINE TEMP-TABLE ttContainerPayments
 FIELD num_id_tit_ap AS INTEGER
 FIELD container_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY num_id_tit_ap container_id.
DEFINE TEMP-TABLE ttAllContainers
 FIELD nr-container AS INTEGER
 FIELD cod-emit-forn AS INTEGER
 INDEX pk IS UNIQUE PRIMARY nr-container.


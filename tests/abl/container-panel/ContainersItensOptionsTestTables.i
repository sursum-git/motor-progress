/* TT only: extra decimal precision exercises ROUND2 after the global sum. */
DEFINE TEMP-TABLE ttMaster NO-UNDO FIELD nr-container AS INTEGER FIELD cod-estabel AS CHARACTER INDEX pk IS PRIMARY UNIQUE nr-container.
DEFINE TEMP-TABLE ttItems NO-UNDO FIELD item_container_id AS INTEGER FIELD container_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD qt_alocada AS DECIMAL DECIMALS 10 INDEX pk IS PRIMARY UNIQUE item_container_id.
DEFINE TEMP-TABLE ttPurchaseItems NO-UNDO FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD codigo_erp AS CHARACTER FIELD descricao AS CHARACTER FIELD qt_comprada AS DECIMAL DECIMALS 10 INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttPurchases NO-UNDO FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD fornecedor_id AS INTEGER INDEX pk IS PRIMARY UNIQUE proc_compra_id.

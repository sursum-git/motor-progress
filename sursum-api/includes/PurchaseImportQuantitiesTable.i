DEFINE TEMP-TABLE ttQuantityRead NO-UNDO
 FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD item_container_id AS INTEGER FIELD container_id AS INTEGER
 FIELD cod_situacao AS INTEGER FIELD pedido_fornec AS CHARACTER FIELD codigo_erp AS CHARACTER FIELD desc_item_fornec AS CHARACTER
 FIELD qt_comprada_final AS DECIMAL DECIMALS 10 FIELD vl_comprada_final AS DECIMAL DECIMALS 10 FIELD qt_rec_final AS DECIMAL DECIMALS 10 FIELD vl_rec_final AS DECIMAL DECIMALS 10
 FIELD desc_situacao_container AS CHARACTER FIELD nr_container AS CHARACTER FIELD situacao_container AS INTEGER FIELD dt_registro AS DATE FIELD dt_recebimento AS DATE FIELD dt_prev_chegada AS DATE
 FIELD qt_comprada AS DECIMAL DECIMALS 10 FIELD vl_negociado AS DECIMAL DECIMALS 10 FIELD qt_confirmada_embarque AS DECIMAL DECIMALS 10 FIELD qt_recbto_fisico AS DECIMAL DECIMALS 10
 FIELD dt_termino_producao AS DATE FIELD dt_prev_termino_producao AS DATE FIELD dt_maxima_producao AS DATE
 INDEX pk IS PRIMARY UNIQUE proc_compra_id item_proc_compra_id item_container_id.

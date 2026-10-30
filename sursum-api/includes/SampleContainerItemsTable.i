DEFINE TEMP-TABLE ttSampleContainerItems NO-UNDO
 FIELD item_container_id AS INTEGER INITIAL ?
 FIELD codigo_erp AS CHARACTER INITIAL ?
 FIELD descricao AS CHARACTER INITIAL ?
 FIELD container_id AS INTEGER INITIAL ?
 INDEX pk IS UNIQUE PRIMARY item_container_id.

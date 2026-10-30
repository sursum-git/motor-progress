/* Shared physical header image and optimistic stamp. No business rules here. */
FUNCTION PurchaseOrderFields RETURNS CHARACTER():
 RETURN 'proc_compra_id,empresa_id,qt_container,cod_situacao,cod_proc_fornec,qt_dias_translado,cotacao_prevista,observacao,dt_registro,fornecedor_id,dt_limite,log_facilid_contato_fornec,log_considerar_previsao,nr_container_original'.
END FUNCTION.
FUNCTION PurchaseOrderSnapshot RETURNS JsonObject(h AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO.
 o=NEW JsonObject().
 DO i=1 TO NUM-ENTRIES(PurchaseOrderFields()):
  f=h:BUFFER-FIELD(ENTRY(i,PurchaseOrderFields())).
  IF f:BUFFER-VALUE=? THEN o:AddNull(f:NAME).
  ELSE CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN o:Add(f:NAME,STRING(f:BUFFER-VALUE)).
   WHEN 'INTEGER' THEN o:Add(f:NAME,INTEGER(f:BUFFER-VALUE)).
   WHEN 'DECIMAL' THEN o:Add(f:NAME,DECIMAL(f:BUFFER-VALUE)).
   WHEN 'LOGICAL' THEN o:Add(f:NAME,LOGICAL(f:BUFFER-VALUE)).
   WHEN 'DATE' THEN o:Add(f:NAME,ISO-DATE(DATE(f:BUFFER-VALUE))).
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError('Tipo inesperado no cabecalho do pedido.',1).
  END CASE.
 END. RETURN o.
END FUNCTION.
FUNCTION PurchaseOrderStamp RETURNS CHARACTER(o AS JsonObject):
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO. DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
 o:Write(textValue,FALSE). hashValue=HEX-ENCODE(MESSAGE-DIGEST('SHA-256',textValue)). RETURN CAPS(hashValue).
END FUNCTION.
FUNCTION PurchaseOrderData RETURNS JsonObject(h AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. o=PurchaseOrderSnapshot(h). o:Add('row_stamp',PurchaseOrderStamp(o)). RETURN o.
END FUNCTION.

/* The physical order may differ in legacy rows. Preserve it; expose actual
   ownership separately in the audit and as the native contextual DTO order. */
FUNCTION AttachmentFields RETURNS CHARACTER():
 RETURN 'anexo_proc_compra_id,proc_compra_id,item_proc_compra_id,descricao,tipos_anexo_id,caminho_arquivo,dt_hr_arquivo'.
END FUNCTION.
FUNCTION AttachmentId RETURNS INTEGER(o AS JsonObject,n AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF NOT o:Has(n) THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade obrigatoria.',1).
 IF o:GetType(n)=JsonDataType:STRING THEN rawValue=o:GetCharacter(n).
 ELSE IF o:GetType(n)=JsonDataType:NUMBER THEN rawValue=STRING(o:GetJsonText(n)).
 ELSE UNDO, THROW NEW Progress.Lang.AppError('Identidade inteira obrigatoria.',1).
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 OR SUBSTRING(rawValue,1,1)='0' THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade positiva invalida.',1).
 DO k=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade inteira invalida.',1). END.
 IF DECIMAL(rawValue)>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade fora da faixa.',1).
 RETURN INTEGER(rawValue).
END FUNCTION.
FUNCTION AttachmentSnapshot RETURNS JsonObject(h AS HANDLE,pid AS INTEGER):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 o=NEW JsonObject().
 DO k=1 TO NUM-ENTRIES(AttachmentFields()):
  f=h:BUFFER-FIELD(ENTRY(k,AttachmentFields())).
  IF f:BUFFER-VALUE=? THEN o:AddNull(f:NAME).
  ELSE CASE f:DATA-TYPE:
   WHEN 'DATETIME' THEN o:Add(f:NAME,ISO-DATE(DATETIME(f:BUFFER-VALUE))).
   WHEN 'CHARACTER' THEN o:Add(f:NAME,STRING(f:BUFFER-VALUE)).
   WHEN 'INTEGER' THEN o:Add(f:NAME,INTEGER(f:BUFFER-VALUE)).
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError('Schema de anexos inesperado.',1).
  END CASE.
 END.
 o:Add('owner_proc_compra_id',pid). RETURN o.
END FUNCTION.
FUNCTION AttachmentStamp RETURNS CHARACTER(o AS JsonObject):
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
 o:Write(textValue,FALSE). hashValue=HEX-ENCODE(MESSAGE-DIGEST('SHA-256',textValue)). RETURN CAPS(hashValue).
END FUNCTION.
FUNCTION AttachmentData RETURNS JsonObject(h AS HANDLE,pid AS INTEGER,typeName AS CHARACTER):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE v AS INTEGER NO-UNDO.
 o=AttachmentSnapshot(h,pid). o:Add('row_stamp',AttachmentStamp(o)). v=h:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
 o:Remove('proc_compra_id'). o:Remove('owner_proc_compra_id').
 IF v=? THEN o:AddNull('proc_compra_id_registro'). ELSE o:Add('proc_compra_id_registro',v).
 o:Add('proc_compra_id',pid). o:Add('tipo_anexo_descricao',IF typeName=? THEN '' ELSE typeName). o:AddNull('arquivo_upload'). RETURN o.
END FUNCTION.

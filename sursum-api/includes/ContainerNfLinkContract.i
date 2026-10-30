/* Shared physical identity, snapshot and optimistic stamp for container/NF links. */
FUNCTION ContainerNfLinkRecordId RETURNS CHARACTER (bufferValue AS HANDLE):
 RETURN STRING(CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",STRING(bufferValue:BUFFER-FIELD("container_id"):BUFFER-VALUE) + CHR(1)
  + STRING(bufferValue:BUFFER-FIELD("documento"):BUFFER-VALUE) + CHR(1) + STRING(bufferValue:BUFFER-FIELD("serie"):BUFFER-VALUE) + CHR(1)
  + STRING(bufferValue:BUFFER-FIELD("estab"):BUFFER-VALUE) + CHR(1) + STRING(bufferValue:BUFFER-FIELD("nat_operacao"):BUFFER-VALUE) + CHR(1)
  + STRING(bufferValue:BUFFER-FIELD("cod_emitente"):BUFFER-VALUE))))).
END FUNCTION.
FUNCTION ContainerNfLinkSnapshot RETURNS JsonObject (bufferValue AS HANDLE):
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 rowValue=NEW JsonObject().
 rowValue:Add("container_id",bufferValue:BUFFER-FIELD("container_id"):BUFFER-VALUE).
 rowValue:Add("documento",bufferValue:BUFFER-FIELD("documento"):BUFFER-VALUE).
 rowValue:Add("serie",bufferValue:BUFFER-FIELD("serie"):BUFFER-VALUE).
 rowValue:Add("estab",bufferValue:BUFFER-FIELD("estab"):BUFFER-VALUE).
 rowValue:Add("nat_operacao",bufferValue:BUFFER-FIELD("nat_operacao"):BUFFER-VALUE).
 rowValue:Add("cod_emitente",bufferValue:BUFFER-FIELD("cod_emitente"):BUFFER-VALUE).
 RETURN rowValue.
END FUNCTION.
FUNCTION ContainerNfLinkStamp RETURNS CHARACTER (bufferValue AS HANDLE,cid AS INTEGER):
 DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
 DEFINE VARIABLE canonicalValue AS LONGCHAR NO-UNDO.
 CREATE QUERY queryValue.
 queryValue:SET-BUFFERS(bufferValue).
 IF NOT queryValue:QUERY-PREPARE("FOR EACH " + bufferValue:NAME + " WHERE " + bufferValue:NAME + ".container_id = " + STRING(cid)
   + " BY " + bufferValue:NAME + ".documento BY " + bufferValue:NAME + ".serie BY " + bufferValue:NAME + ".estab BY " + bufferValue:NAME + ".nat_operacao BY " + bufferValue:NAME + ".cod_emitente") THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de notas indisponivel.",1).
 queryValue:QUERY-OPEN(). queryValue:GET-FIRST().
 DO WHILE NOT queryValue:QUERY-OFF-END:
  canonicalValue=canonicalValue + ContainerNfLinkRecordId(bufferValue) + CHR(30).
  queryValue:GET-NEXT().
 END.
 queryValue:QUERY-CLOSE(). DELETE OBJECT queryValue.
 RETURN STRING(CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",canonicalValue)))).
END FUNCTION.

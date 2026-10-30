/* Recurso fechado: equivalencias da etapa1, nao altera itens/saldos. */
USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER requestJSON AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER responseJSON AS JsonObject NO-UNDO.
DEFINE VARIABLE hData AS HANDLE NO-UNDO.
DEFINE VARIABLE queryHandle AS HANDLE NO-UNDO.
DEFINE VARIABLE operationCode AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE destination AS CHARACTER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE found AS LOGICAL NO-UNDO.
DEFINE VARIABLE beforeRow AS JsonObject NO-UNDO.
DEFINE VARIABLE afterRow AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER CASE-SENSITIVE NO-UNDO.
{esbo/termosPesquisaEstoque.i}
FUNCTION findFailed RETURNS LOGICAL ():
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 DO i = 1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(i) <> 565 THEN RETURN TRUE.
 END.
 RETURN FALSE.
END FUNCTION.
FUNCTION stateJSON RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE rawText AS LONGCHAR NO-UNDO.
 o = NEW JsonObject().
 o:Add("termo_digitado",STRING(hData:BUFFER-FIELD("termo_digitado"):BUFFER-VALUE)).
 o:Add("termo_pesquisa",STRING(hData:BUFFER-FIELD("termo_pesquisa"):BUFFER-VALUE)).
 o:Add("ativo",LOGICAL(hData:BUFFER-FIELD("ativo"):BUFFER-VALUE)).
 FIX-CODEPAGE(rawText) = "UTF-8". o:Write(rawText,FALSE).
 o:Add("row_stamp",CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",rawText)))).
 RETURN o.
END FUNCTION.
FUNCTION keyWhere RETURNS CHARACTER ():
 RETURN "WHERE " + hData:NAME + ".termo_digitado = " + QUOTER(keyValue).
END FUNCTION.
FUNCTION textValue RETURNS CHARACTER (propertyName AS CHARACTER, limitSize AS INTEGER):
 DEFINE VARIABLE v AS CHARACTER NO-UNDO.
 IF NOT requestJSON:Has(propertyName) THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
 IF requestJSON:GetType(propertyName) <> JsonDataType:STRING THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
 v = termoBuscaNormalizado(requestJSON:GetCharacter(propertyName),limitSize).
 IF v = ? THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
 RETURN v.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 responseJSON = NEW JsonObject().
 IF NOT VALID-HANDLE(phData) OR NOT VALID-OBJECT(requestJSON) THEN RUN fail("ESTOQUE_TERMO_CONFIGURATION",503).
 CREATE BUFFER hData FOR TABLE phData.
 IF NOT requestJSON:Has("operation") THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
 IF requestJSON:GetType("operation") <> JsonDataType:STRING THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
 operationCode = requestJSON:GetCharacter("operation").
 IF LOOKUP(operationCode,"read,get,create,update,delete") = 0 THEN RUN fail("ESTOQUE_TERMO_OPERATION",422).
 names = requestJSON:GetNames().
 DO k = 1 TO EXTENT(names):
  IF LOOKUP(names[k],"operation,id,termo_digitado,digitado,termo_pesquisa,ativo,row_stamp") = 0 THEN RUN fail("ESTOQUE_TERMO_FIELD",422).
  IF operationCode = "read" AND names[k] <> "operation" THEN RUN fail("ESTOQUE_TERMO_FIELD",422).
  IF operationCode = "get" AND LOOKUP(names[k],"operation,id,termo_digitado") = 0 THEN RUN fail("ESTOQUE_TERMO_FIELD",422).
 END.
 IF operationCode = "read" THEN DO:
  CREATE QUERY queryHandle. queryHandle:SET-BUFFERS(hData).
  IF NOT queryHandle:QUERY-PREPARE("FOR EACH " + hData:NAME + " NO-LOCK BY " + hData:NAME + ".termo_digitado") THEN RUN fail("ESTOQUE_TERMO_CONFIGURATION",503).
  queryHandle:QUERY-OPEN(). queryHandle:GET-FIRST(NO-LOCK). rows = NEW JsonArray().
  DO WHILE NOT queryHandle:QUERY-OFF-END:
   rows:Add(stateJSON()). queryHandle:GET-NEXT(NO-LOCK).
  END.
  responseJSON:Add("success",TRUE). responseJSON:Add("data",rows). RETURN.
 END.
 IF operationCode = "create" THEN DO:
  IF requestJSON:Has("id") THEN RUN fail("ESTOQUE_TERMO_KEY",422).
  keyValue = textValue("digitado",50).
 END.
 ELSE DO:
  keyValue = textValue("id",50).
  IF requestJSON:GetCharacter("id") <> keyValue THEN RUN fail("ESTOQUE_TERMO_KEY",422).
 END.
 IF requestJSON:Has("termo_digitado") THEN
  IF textValue("termo_digitado",50) <> keyValue THEN RUN fail("ESTOQUE_TERMO_KEY",422).
 IF operationCode <> "create" AND requestJSON:Has("digitado") THEN
  IF textValue("digitado",50) <> keyValue THEN RUN fail("ESTOQUE_TERMO_KEY",422).
 IF operationCode = "get" THEN DO:
  found = hData:FIND-FIRST(keyWhere(),NO-LOCK) NO-ERROR.
  IF findFailed() THEN RUN fail("ESTOQUE_TERMO_PERSISTENCE",409).
  IF NOT found THEN RUN fail("ESTOQUE_TERMO_NOT_FOUND",404).
  responseJSON:Add("success",TRUE). responseJSON:Add("data",stateJSON()). RETURN.
 END.
 IF operationCode = "create" OR operationCode = "update" THEN DO:
  IF operationCode = "create" OR requestJSON:Has("termo_pesquisa") THEN destination = textValue("termo_pesquisa",100).
  IF requestJSON:Has("ativo") THEN
   IF requestJSON:GetType("ativo") <> JsonDataType:BOOLEAN THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
 END.
 IF operationCode <> "create" THEN DO:
  IF NOT requestJSON:Has("row_stamp") THEN RUN fail("ESTOQUE_TERMO_ORIGINAL_REQUIRED",422).
  IF requestJSON:GetType("row_stamp") <> JsonDataType:STRING THEN RUN fail("ESTOQUE_TERMO_ORIGINAL_REQUIRED",422).
  stamp = requestJSON:GetCharacter("row_stamp").
  IF LENGTH(stamp) <> 64 THEN RUN fail("ESTOQUE_TERMO_ORIGINAL_REQUIRED",422).
 END.
 IF TRANSACTION THEN RUN fail("ESTOQUE_TERMO_EXTERNAL_TRANSACTION",409).
 DO TRANSACTION ON ERROR UNDO, THROW:
  found = hData:FIND-FIRST(keyWhere(),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF hData:LOCKED THEN RUN fail("ESTOQUE_TERMO_BUSY",409).
  IF findFailed() THEN RUN fail("ESTOQUE_TERMO_PERSISTENCE",409).
  IF operationCode = "create" THEN DO:
   IF found THEN RUN fail("ESTOQUE_TERMO_DUPLICATE",409).
   IF NOT hData:BUFFER-CREATE() THEN RUN fail("ESTOQUE_TERMO_PERSISTENCE",409).
   ASSIGN hData:BUFFER-FIELD("termo_digitado"):BUFFER-VALUE = keyValue
    hData:BUFFER-FIELD("ativo"):BUFFER-VALUE = TRUE.
   beforeRow = NEW JsonObject().
  END.
  ELSE DO:
   IF NOT found THEN RUN fail("ESTOQUE_TERMO_NOT_FOUND",404).
   beforeRow = stateJSON().
   IF beforeRow:GetCharacter("row_stamp") <> stamp THEN RUN fail("ESTOQUE_TERMO_CHANGED",409).
  END.
  IF operationCode = "delete" THEN DO:
   IF NOT hData:BUFFER-DELETE() THEN RUN fail("ESTOQUE_TERMO_PERSISTENCE",409).
   afterRow = NEW JsonObject().
  END.
  ELSE DO:
   IF operationCode = "create" OR requestJSON:Has("termo_pesquisa") THEN hData:BUFFER-FIELD("termo_pesquisa"):BUFFER-VALUE = destination.
   IF requestJSON:Has("ativo") THEN hData:BUFFER-FIELD("ativo"):BUFFER-VALUE = requestJSON:GetLogical("ativo").
   IF STRING(hData:BUFFER-FIELD("termo_pesquisa"):BUFFER-VALUE) = keyValue THEN RUN fail("ESTOQUE_TERMO_VALIDATION",422).
   IF NOT hData:BUFFER-VALIDATE() THEN RUN fail("ESTOQUE_TERMO_PERSISTENCE",409).
   afterRow = stateJSON().
  END.
 END.
 responseJSON:Add("success",TRUE).
 IF operationCode <> "delete" THEN responseJSON:Add("data",afterRow).
 audit = NEW JsonObject(). audit:Add("version",1). audit:Add("source","progress-transaction").
 audit:Add("resource","estoque_termos"). audit:Add("operation",operationCode). audit:Add("recordId",keyValue).
 audit:Add("before",beforeRow). audit:Add("after",afterRow). responseJSON:Add("audit",audit).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(responseJSON) THEN responseJSON = NEW JsonObject().
  IF NOT responseJSON:Has("error") THEN RUN errorResponse("ESTOQUE_TERMO_PERSISTENCE",409).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(queryHandle) THEN DELETE OBJECT queryHandle NO-ERROR.
  IF VALID-HANDLE(hData) THEN DO: hData:BUFFER-RELEASE() NO-ERROR. DELETE OBJECT hData NO-ERROR. END.
 END FINALLY.
END.
PROCEDURE errorResponse:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 responseJSON = NEW JsonObject(). err = NEW JsonObject().
 err:Add("code",code). err:Add("status",statusCode).
 err:Add("message","Equivalencia invalida, alterada ou indisponivel. Recarregue o cadastro.").
 responseJSON:Add("success",FALSE). responseJSON:Add("error",err).
END PROCEDURE.
PROCEDURE fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN errorResponse(code,statusCode). UNDO, THROW NEW Progress.Lang.AppError(code,0).
END PROCEDURE.

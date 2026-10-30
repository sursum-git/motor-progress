/* Consulta privada. Handle e recurso definidos pelo wrapper, nunca pelo cliente. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE clause AS CHARACTER NO-UNDO.
DEFINE VARIABLE textId AS CHARACTER NO-UNDO.
DEFINE VARIABLE idValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE keyName AS CHARACTER NO-UNDO.
DEFINE VARIABLE keyIndex AS INTEGER NO-UNDO.
DEFINE VARIABLE parsedId AS DECIMAL NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE dt AS DATE NO-UNDO.
FUNCTION RowJson RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE physical AS CHARACTER NO-UNDO.
 DEFINE VARIABLE jsonName AS CHARACTER NO-UNDO.
 o = NEW JsonObject().
 o:Add("cod_emitente",INTEGER(b:BUFFER-FIELD("cod-emitente"):BUFFER-VALUE)).
 DO j = 1 TO 2:
  physical = ENTRY(j,"nome-abrev,nome-emit"). jsonName = ENTRY(j,"nome_abrev,nome_emit").
  IF b:BUFFER-FIELD(physical):BUFFER-VALUE = ? THEN o:AddNull(jsonName).
  ELSE o:Add(jsonName,STRING(b:BUFFER-FIELD(physical):BUFFER-VALUE)).
 END.
 IF pcResource = "fornecedores_estrangeiros" THEN DO:
  dt = b:BUFFER-FIELD("data-implant"):BUFFER-VALUE.
  IF dt = ? THEN o:AddNull("data_implant").
  ELSE o:Add("data_implant",STRING(YEAR(dt),"9999") + "-" + STRING(MONTH(dt),"99") + "-" + STRING(DAY(dt),"99")).
 END.
 RETURN o.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF pcResource <> "fornecedores" AND pcResource <> "fornecedores_estrangeiros" THEN RUN Fail("CIW_FORNECEDOR_RESOURCE_INVALID",422).
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
 IF NOT poRequest:Has("operation") THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
 IF poRequest:GetType("operation") <> JsonDataType:STRING THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
 op = poRequest:GetCharacter("operation").
 IF op <> "read" AND op <> "get" THEN RUN Fail("CIW_FORNECEDOR_READ_ONLY",405).
 names = poRequest:GetNames().
 DO i = 1 TO EXTENT(names):
  IF LOOKUP(names[i],"operation,id,cod_emitente") = 0 THEN RUN Fail("CIW_FORNECEDOR_FIELD_INVALID",422).
 END.
 IF op = "get" THEN DO:
  IF NOT poRequest:Has("id") OR poRequest:IsNull("id") THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
  DO keyIndex = 1 TO 2:
   keyName = ENTRY(keyIndex,"id,cod_emitente").
   IF keyIndex = 2 AND NOT poRequest:Has(keyName) THEN NEXT.
   IF poRequest:IsNull(keyName) THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
   CASE poRequest:GetType(keyName):
   WHEN JsonDataType:STRING THEN textId = poRequest:GetCharacter(keyName).
   WHEN JsonDataType:NUMBER THEN textId = poRequest:GetJsonText(keyName).
   OTHERWISE RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
  END CASE.
  IF LENGTH(textId) < 1 OR LENGTH(textId) > 10 THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
  DO i = 1 TO LENGTH(textId):
   IF INDEX("0123456789",SUBSTRING(textId,i,1)) = 0 THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
  END.
   parsedId = DECIMAL(textId).
   IF parsedId > 2147483647 THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
   IF keyIndex = 1 THEN idValue = parsedId.
   ELSE IF idValue <> parsedId THEN RUN Fail("CIW_FORNECEDOR_VALIDATION",422).
  END.
 END.
 IF NOT VALID-HANDLE(phData) THEN UNDO, THROW NEW Progress.Lang.AppError("Origem ausente",0).
 CREATE BUFFER b FOR TABLE phData BUFFER-NAME "bCiwFornecedorRead".
 clause = IF pcResource = "fornecedores" THEN "identific = 2" ELSE "cod-gr-forn = 2".
 IF op = "get" THEN clause = clause + " AND cod-emitente = " + TRIM(STRING(INTEGER(idValue))).
 CREATE QUERY q. q:SET-BUFFERS(b).
 IF NOT q:QUERY-PREPARE("FOR EACH " + b:NAME + " WHERE " + clause + " NO-LOCK BY cod-emitente") THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
 IF NOT q:QUERY-OPEN() THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
 q:GET-FIRST(NO-LOCK). rows = NEW JsonArray().
 DO WHILE NOT q:QUERY-OFF-END:
  rowData = RowJson(). rows:Add(rowData). q:GET-NEXT(NO-LOCK).
 END.
 IF op = "get" AND rows:Length = 0 THEN RUN Fail("CIW_FORNECEDOR_NOT_FOUND",404).
 poResponse = NEW JsonObject(). poResponse:Add("success",TRUE).
 IF op = "get" THEN poResponse:Add("data",rows:GetJsonObject(1)).
 ELSE DO: poResponse:Add("data",rows). poResponse:Add("total",rows:Length). END.
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) THEN RUN ErrorResponse("CIW_FORNECEDOR_UNAVAILABLE",503).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(b) THEN DELETE OBJECT b NO-ERROR.
 END FINALLY.
END.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse = NEW JsonObject(). err = NEW JsonObject().
 err:Add("code",code). err:Add("status",statusCode). err:Add("message","Consulta invalida ou indisponivel.").
 poResponse:Add("success",FALSE). poResponse:Add("error",err).
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN ErrorResponse(code,statusCode). UNDO, THROW NEW Progress.Lang.AppError(code,0).
END.

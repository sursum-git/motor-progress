/* Leitura fechada. Handle confiavel do wrapper; nenhum nome de tabela do cliente. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE seen AS JsonObject NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE keyName AS CHARACTER NO-UNDO.
DEFINE VARIABLE keyValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE aliasValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE fieldList AS CHARACTER NO-UNDO.
DEFINE VARIABLE jsonList AS CHARACTER NO-UNDO.
DEFINE VARIABLE clause AS CHARACTER NO-UNDO.
DEFINE VARIABLE orderClause AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
FUNCTION ParseTransportKey RETURNS CHARACTER (nameValue AS CHARACTER):
 DEFINE VARIABLE v AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF poRequest:IsNull(nameValue) OR poRequest:GetType(nameValue) <> JsonDataType:STRING THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
 v = poRequest:GetCharacter(nameValue).
 IF pcResource = "itens" THEN DO:
  IF LENGTH(v) < 1 OR LENGTH(v) > 128 THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
  DO n = 1 TO LENGTH(v):
   IF ASC(SUBSTRING(v,n,1)) < 32 OR ASC(SUBSTRING(v,n,1)) = 127 THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
  END.
 END.
 ELSE DO:
  IF LENGTH(v) <> 64 THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
  v = CAPS(v).
  DO n = 1 TO LENGTH(v):
   IF INDEX("0123456789ABCDEF",SUBSTRING(v,n,1)) = 0 THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
  END.
 END.
 RETURN v.
END FUNCTION.
FUNCTION RowJson RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE j AS CHARACTER NO-UNDO.
 DEFINE VARIABLE lc AS LONGCHAR NO-UNDO.
 o = NEW JsonObject().
 DO n = 1 TO NUM-ENTRIES(fieldList):
  f = b:BUFFER-FIELD(ENTRY(n,fieldList)). j = ENTRY(n,jsonList).
  IF f:BUFFER-VALUE = ? THEN o:AddNull(j).
  ELSE IF f:DATA-TYPE = "INTEGER" THEN o:Add(j,INTEGER(f:BUFFER-VALUE)).
  ELSE o:Add(j,STRING(f:BUFFER-VALUE)).
 END.
 IF pcResource = "representantes_ativos" THEN DO:
  FIX-CODEPAGE(lc) = "UTF-8".
  IF NOT o:Write(lc,FALSE) THEN UNDO, THROW NEW Progress.Lang.AppError("Projecao indisponivel",0).
  o:Add("representante_key",CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",lc)))).
 END.
 RETURN o.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 CASE pcResource:
  WHEN "itens" THEN ASSIGN keyName="it_codigo" fieldList="it-codigo,desc-item" jsonList="it_codigo,descricao"
   clause="ge-codigo >= 50 AND ge-codigo <= 60" orderClause=" BY it-codigo".
  WHEN "representantes_ativos" THEN ASSIGN keyName="representante_key" fieldList="cdn_repres,nom_pessoa,nom_abrev" jsonList=fieldList
   clause="dat_desligto = ?" orderClause=" BY cdn_repres BY nom_pessoa BY nom_abrev".
  OTHERWISE RUN Fail("CIW_REFERENCIA_RESOURCE_INVALID",422).
 END CASE.
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
 IF NOT poRequest:Has("operation") THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
 IF poRequest:GetType("operation") <> JsonDataType:STRING THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
 op = poRequest:GetCharacter("operation").
 IF op <> "read" AND op <> "get" THEN RUN Fail("CIW_REFERENCIA_READ_ONLY",405).
 names = poRequest:GetNames().
 DO i = 1 TO EXTENT(names):
  IF names[i] <> "operation" AND names[i] <> "id" AND names[i] <> keyName THEN RUN Fail("CIW_REFERENCIA_FIELD_INVALID",422).
 END.
 IF op = "get" THEN DO:
  IF NOT poRequest:Has("id") THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
  keyValue = ParseTransportKey("id").
  IF poRequest:Has(keyName) THEN DO:
   aliasValue = ParseTransportKey(keyName).
   IF NOT COMPARE(keyValue,"=",aliasValue,"RAW") THEN RUN Fail("CIW_REFERENCIA_VALIDATION",422).
  END.
  IF pcResource = "itens" THEN clause = clause + " AND it-codigo = " + QUOTER(keyValue).
 END.
 IF NOT VALID-HANDLE(phData) THEN UNDO, THROW NEW Progress.Lang.AppError("Origem ausente",0).
 CREATE BUFFER b FOR TABLE phData BUFFER-NAME "bCiwReferenciaRead".
 CREATE QUERY q. q:SET-BUFFERS(b).
 IF NOT q:QUERY-PREPARE("FOR EACH " + b:NAME + " WHERE " + clause + " NO-LOCK" + orderClause) THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
 IF NOT q:QUERY-OPEN() THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
 q:GET-FIRST(NO-LOCK). rows = NEW JsonArray(). seen = NEW JsonObject().
 DO WHILE NOT q:QUERY-OFF-END:
  rowData = RowJson().
  IF pcResource = "representantes_ativos" THEN DO:
   aliasValue = rowData:GetCharacter(keyName).
   IF seen:Has(aliasValue) THEN DO: DELETE OBJECT rowData. q:GET-NEXT(NO-LOCK). NEXT. END.
   seen:Add(aliasValue,TRUE).
   IF op = "get" AND aliasValue <> keyValue THEN DO: DELETE OBJECT rowData. q:GET-NEXT(NO-LOCK). NEXT. END.
  END.
  rows:Add(rowData). q:GET-NEXT(NO-LOCK).
 END.
 IF op = "get" AND rows:Length = 0 THEN RUN Fail("CIW_REFERENCIA_NOT_FOUND",404).
 poResponse = NEW JsonObject(). poResponse:Add("success",TRUE).
 IF op = "get" THEN poResponse:Add("data",rows:GetJsonObject(1)).
 ELSE DO: poResponse:Add("data",rows). poResponse:Add("total",rows:Length). END.
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) THEN RUN ErrorResponse("CIW_REFERENCIA_UNAVAILABLE",503).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(b) THEN DELETE OBJECT b NO-ERROR.
  IF VALID-OBJECT(seen) THEN DELETE OBJECT seen.
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




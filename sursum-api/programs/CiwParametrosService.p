/* Editor administrativo de im-param. Nao participa da leitura de parametros das APIs. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hData AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE found AS LOGICAL NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE numValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE beforeRow AS JsonObject NO-UNDO.
DEFINE VARIABLE afterRow AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.

FUNCTION FindFailed RETURNS LOGICAL ():
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DO k=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(k)<>565 THEN RETURN TRUE.
 END.
 RETURN FALSE.
END FUNCTION.
FUNCTION KeyText RETURNS CHARACTER (o AS JsonObject, keyName AS CHARACTER):
 DEFINE VARIABLE v AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF NOT o:Has(keyName) OR o:GetType(keyName)<>JsonDataType:STRING THEN RUN Fail("CIW_PARAM_VALIDATION",422).
 v=o:GetCharacter(keyName).
 IF v=? OR TRIM(v)="" OR LENGTH(v)>50 THEN RUN Fail("CIW_PARAM_VALIDATION",422).
 DO k=1 TO LENGTH(v):
  IF ASC(SUBSTRING(v,k,1))<32 OR ASC(SUBSTRING(v,k,1))=127 THEN RUN Fail("CIW_PARAM_VALIDATION",422).
 END.
 RETURN v.
END FUNCTION.
FUNCTION StateJson RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE physicalName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE jsonName AS CHARACTER NO-UNDO.
 o=NEW JsonObject().
 DO k=1 TO 4:
  physicalName=ENTRY(k,"cod-param,val-param,tp-param,agrup_im_param_id").
  jsonName=ENTRY(k,"cod_param,val_param,tp_param,agrup_im_param_id").
  IF hData:BUFFER-FIELD(physicalName):BUFFER-VALUE=? THEN o:AddNull(jsonName).
  ELSE IF k<=2 THEN o:Add(jsonName,STRING(hData:BUFFER-FIELD(physicalName):BUFFER-VALUE)).
  ELSE o:Add(jsonName,INTEGER(hData:BUFFER-FIELD(physicalName):BUFFER-VALUE)).
 END.
 FIX-CODEPAGE(textValue)="UTF-8". o:Write(textValue,FALSE).
 o:Add("row_stamp",CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",textValue)))).
 RETURN o.
END FUNCTION.
FUNCTION WhereKey RETURNS CHARACTER ():
 RETURN "WHERE " + hData:NAME + ".cod-param = " + QUOTER(codeValue).
END FUNCTION.

DO ON ERROR UNDO, THROW:
 poResponse=NEW JsonObject().
 IF NOT VALID-HANDLE(phData) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail("CIW_PARAM_CONFIGURATION",503).
 CREATE BUFFER hData FOR TABLE phData.
 IF NOT poRequest:Has("operation") OR poRequest:GetType("operation")<>JsonDataType:STRING THEN RUN Fail("CIW_PARAM_VALIDATION",422).
 op=poRequest:GetCharacter("operation").
 IF LOOKUP(op,"read,get,create,update,delete")=0 THEN RUN Fail("CIW_PARAM_OPERATION_INVALID",422).
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  IF LOOKUP(names[n],"operation,id,cod_param,codigo,val_param,tp_param,row_stamp")=0 THEN RUN Fail("CIW_PARAM_FIELD_INVALID",422).
  IF op="read" AND names[n]<>"operation" THEN RUN Fail("CIW_PARAM_FIELD_INVALID",422).
  IF op="get" AND LOOKUP(names[n],"operation,id,cod_param")=0 THEN RUN Fail("CIW_PARAM_FIELD_INVALID",422).
 END.
 IF op="read" THEN DO:
  CREATE QUERY q. q:SET-BUFFERS(hData).
  IF NOT q:QUERY-PREPARE("FOR EACH " + hData:NAME + " NO-LOCK BY " + hData:NAME + ".cod-param") THEN RUN Fail("CIW_PARAM_CONFIGURATION",503).
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK). rows=NEW JsonArray().
  DO WHILE NOT q:QUERY-OFF-END:
   rows:Add(StateJson()). q:GET-NEXT(NO-LOCK).
  END.
  poResponse:Add("success",TRUE). poResponse:Add("data",rows). RETURN.
 END.
 IF op="create" THEN DO:
  codeValue=KeyText(poRequest,"codigo").
  IF codeValue<>TRIM(codeValue) OR poRequest:Has("id") THEN RUN Fail("CIW_PARAM_VALIDATION",422).
  IF poRequest:Has("row_stamp") THEN IF NOT poRequest:IsNull("row_stamp") AND poRequest:GetCharacter("row_stamp")<>"" THEN RUN Fail("CIW_PARAM_VALIDATION",422).
 END.
 ELSE codeValue=KeyText(poRequest,"id").
 IF poRequest:Has("cod_param") AND NOT poRequest:IsNull("cod_param") THEN
  IF poRequest:GetType("cod_param")<>JsonDataType:STRING OR poRequest:GetCharacter("cod_param")<>codeValue THEN RUN Fail("CIW_PARAM_KEY_IMMUTABLE",422).
 IF op<>"create" AND poRequest:Has("codigo") THEN
  IF KeyText(poRequest,"codigo")<>codeValue THEN RUN Fail("CIW_PARAM_KEY_IMMUTABLE",422).
 IF op="get" THEN DO:
  found=hData:FIND-FIRST(WhereKey(),NO-LOCK) NO-ERROR.
  IF FindFailed() THEN RUN Fail("CIW_PARAM_PERSISTENCE_REJECTED",409).
  IF NOT found THEN RUN Fail("CIW_PARAM_NOT_FOUND",404).
  poResponse:Add("success",TRUE). poResponse:Add("data",StateJson()). RETURN.
 END.
 IF op="create" OR op="update" THEN DO:
  IF poRequest:Has("val_param") AND NOT poRequest:IsNull("val_param") THEN
   IF poRequest:GetType("val_param")<>JsonDataType:STRING OR LENGTH(poRequest:GetCharacter("val_param"))>500 THEN RUN Fail("CIW_PARAM_VALIDATION",422).
  IF op="create" AND NOT poRequest:Has("tp_param") THEN RUN Fail("CIW_PARAM_VALIDATION",422).
  IF poRequest:Has("tp_param") THEN DO:
   IF poRequest:GetType("tp_param")<>JsonDataType:NUMBER THEN RUN Fail("CIW_PARAM_VALIDATION",422).
   numValue=poRequest:GetDecimal("tp_param").
   IF numValue<0 OR numValue>5 OR TRUNCATE(numValue,0)<>numValue THEN RUN Fail("CIW_PARAM_VALIDATION",422).
  END.
 END.
 IF op<>"create" THEN DO:
  IF NOT poRequest:Has("row_stamp") OR poRequest:GetType("row_stamp")<>JsonDataType:STRING THEN RUN Fail("CIW_PARAM_ORIGINAL_REQUIRED",422).
  stamp=poRequest:GetCharacter("row_stamp").
  IF LENGTH(stamp)<>64 THEN RUN Fail("CIW_PARAM_ORIGINAL_REQUIRED",422).
  DO n=1 TO 64: IF INDEX("0123456789ABCDEF",SUBSTRING(stamp,n,1))=0 THEN RUN Fail("CIW_PARAM_ORIGINAL_REQUIRED",422). END.
 END.
 DO TRANSACTION ON ERROR UNDO, THROW:
  found=hData:FIND-FIRST(WhereKey(),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF hData:LOCKED THEN RUN Fail("CIW_PARAM_BUSY",409).
  IF FindFailed() THEN RUN Fail("CIW_PARAM_PERSISTENCE_REJECTED",409).
  IF op="create" THEN DO:
   IF found THEN RUN Fail("CIW_PARAM_DUPLICATE",409).
   IF NOT hData:BUFFER-CREATE() THEN RUN Fail("CIW_PARAM_PERSISTENCE_REJECTED",409).
   hData:BUFFER-FIELD("cod-param"):BUFFER-VALUE=codeValue. beforeRow=NEW JsonObject().
  END.
  ELSE DO:
   IF NOT found THEN RUN Fail("CIW_PARAM_NOT_FOUND",404).
   IF NOT COMPARE(STRING(hData:BUFFER-FIELD("cod-param"):BUFFER-VALUE),"EQ",codeValue,"RAW") THEN RUN Fail("CIW_PARAM_KEY_IMMUTABLE",422).
   beforeRow=StateJson().
   IF beforeRow:GetCharacter("row_stamp")<>stamp THEN RUN Fail("CIW_PARAM_CHANGED",409).
  END.
  IF op="delete" THEN DO:
   IF NOT hData:BUFFER-DELETE() THEN RUN Fail("CIW_PARAM_PERSISTENCE_REJECTED",409).
   afterRow=NEW JsonObject().
  END.
  ELSE DO:
   IF poRequest:Has("val_param") THEN hData:BUFFER-FIELD("val-param"):BUFFER-VALUE=IF poRequest:IsNull("val_param") THEN ? ELSE poRequest:GetCharacter("val_param").
   IF poRequest:Has("tp_param") THEN hData:BUFFER-FIELD("tp-param"):BUFFER-VALUE=poRequest:GetInteger("tp_param").
   IF NOT hData:BUFFER-VALIDATE() THEN RUN Fail("CIW_PARAM_PERSISTENCE_REJECTED",409).
   afterRow=StateJson().
  END.
 END.
 poResponse:Add("success",TRUE).
 IF op<>"delete" THEN poResponse:Add("data",afterRow).
 audit=NEW JsonObject(). audit:Add("version",1). audit:Add("source","progress-transaction").
 audit:Add("resource","im_param"). audit:Add("operation",op). audit:Add("recordId",codeValue).
 audit:Add("before",beforeRow). audit:Add("after",afterRow). poResponse:Add("audit",audit).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has("error") THEN RUN ErrorResponse("CIW_PARAM_PERSISTENCE_REJECTED",409).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(hData) THEN DO: hData:BUFFER-RELEASE() NO-ERROR. DELETE OBJECT hData NO-ERROR. END.
 END FINALLY.
END.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add("code",code). err:Add("status",statusCode).
 err:Add("message","Parametro invalido, alterado ou indisponivel. Recarregue antes de tentar novamente.").
 poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN ErrorResponse(code,statusCode). UNDO,THROW NEW Progress.Lang.AppError(code,0).
END PROCEDURE.

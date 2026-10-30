/* Motor privado para cadastros fixos. Nomes/handles/definicao sao do wrapper,
   nunca da requisicao HTTP. Nenhuma regra de custos e implementada aqui. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phReference1 AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phReference2 AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdentity AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poDefinition AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttChange NO-UNDO
 FIELD lineNo AS INTEGER FIELD clientId AS CHARACTER CASE-SENSITIVE
 FIELD op AS CHARACTER CASE-SENSITIVE FIELD recordId AS INTEGER
 INDEX ordem IS PRIMARY UNIQUE lineNo INDEX client IS UNIQUE clientId.
DEFINE VARIABLE hData AS HANDLE NO-UNDO.
DEFINE VARIABLE hReference AS HANDLE NO-UNDO.
DEFINE VARIABLE hField AS HANDLE NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
DEFINE VARIABLE jaChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE jaResults AS JsonArray NO-UNDO.
DEFINE VARIABLE jaAudit AS JsonArray NO-UNDO.
DEFINE VARIABLE joField AS JsonObject NO-UNDO.
DEFINE VARIABLE joChange AS JsonObject NO-UNDO.
DEFINE VARIABLE joValues AS JsonObject NO-UNDO.
DEFINE VARIABLE joOriginal AS JsonObject NO-UNDO.
DEFINE VARIABLE joBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE joAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE joSingle AS JsonObject NO-UNDO.
DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER NO-UNDO.
DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAllowed AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cType AS CHARACTER NO-UNDO.
DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE iLine AS INTEGER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iNext AS INTEGER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE lBatch AS LOGICAL NO-UNDO.

FUNCTION FindFailed RETURNS LOGICAL ():
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DO n = 1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN RETURN TRUE.
 END.
 RETURN FALSE.
END FUNCTION.
FUNCTION ValidName RETURNS LOGICAL (v AS CHARACTER):
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF v=? OR v="" OR LENGTH(v)>80 THEN RETURN FALSE.
 DO n = 1 TO LENGTH(v):
  IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(v,n,1))=0 THEN RETURN FALSE.
 END.
 RETURN TRUE.
END FUNCTION.
FUNCTION ReadNamedId RETURNS INTEGER (o AS JsonObject,keyName AS CHARACTER):
 DEFINE VARIABLE t AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE valueId AS DECIMAL NO-UNDO.
 IF NOT o:Has(keyName) OR o:IsNull(keyName) THEN RUN Fail("CIW_CADASTRO_VALIDATION","Informe o ID inteiro positivo.",422).
 IF o:GetType(keyName)=JsonDataType:STRING THEN t=o:GetCharacter(keyName).
 ELSE IF o:GetType(keyName)=JsonDataType:NUMBER THEN t=o:GetJsonText(keyName).
 ELSE RUN Fail("CIW_CADASTRO_VALIDATION","ID invalido.",422).
 IF t=? OR LENGTH(t)=0 OR LENGTH(t)>10 THEN RUN Fail("CIW_CADASTRO_VALIDATION","ID invalido.",422).
 DO n = 1 TO LENGTH(t):
  IF INDEX("0123456789",SUBSTRING(t,n,1))=0 THEN RUN Fail("CIW_CADASTRO_VALIDATION","ID invalido.",422).
 END.
 valueId=DECIMAL(t).
 IF valueId<1 OR valueId>2147483647 THEN RUN Fail("CIW_CADASTRO_VALIDATION","ID fora do limite.",422).
 RETURN INTEGER(valueId).
END FUNCTION.
FUNCTION ReadId RETURNS INTEGER (o AS JsonObject): RETURN ReadNamedId(o,"id"). END FUNCTION.
FUNCTION RecordJson RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE keyName AS CHARACTER NO-UNDO.
 o=NEW JsonObject().
 o:Add(cKey,INTEGER(hData:BUFFER-FIELD(cKey):BUFFER-VALUE)).
 DO n = 1 TO jaFields:Length:
  keyName=jaFields:GetJsonObject(n):GetCharacter("name"). f=hData:BUFFER-FIELD(keyName).
  IF f:BUFFER-VALUE=? THEN o:AddNull(keyName).
  ELSE CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN o:Add(keyName,STRING(f:BUFFER-VALUE)).
   WHEN "INTEGER" THEN o:Add(keyName,INTEGER(f:BUFFER-VALUE)).
   WHEN "LOGICAL" THEN o:Add(keyName,LOGICAL(f:BUFFER-VALUE)).
  END CASE.
 END.
 RETURN o.
END FUNCTION.
FUNCTION SameOriginal RETURNS LOGICAL (o AS JsonObject):
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE keyName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE currentText AS CHARACTER NO-UNDO.
 DO n = 1 TO jaFields:Length:
  keyName=jaFields:GetJsonObject(n):GetCharacter("name"). f=hData:BUFFER-FIELD(keyName).
  IF f:BUFFER-VALUE=? THEN DO: IF NOT o:IsNull(keyName) THEN RETURN FALSE. END.
  ELSE DO:
   IF o:IsNull(keyName) THEN RETURN FALSE.
   CASE f:DATA-TYPE:
    WHEN "CHARACTER" THEN DO:
     currentText=STRING(f:BUFFER-VALUE).
     IF LENGTH(currentText,"RAW")<>LENGTH(o:GetCharacter(keyName),"RAW") OR NOT COMPARE(currentText,"EQ",o:GetCharacter(keyName),"RAW") THEN RETURN FALSE.
    END.
    WHEN "INTEGER" THEN IF INTEGER(f:BUFFER-VALUE)<>o:GetInteger(keyName) THEN RETURN FALSE.
    WHEN "LOGICAL" THEN IF LOGICAL(f:BUFFER-VALUE)<>o:GetLogical(keyName) THEN RETURN FALSE.
   END CASE.
  END.
 END.
 RETURN TRUE.
END FUNCTION.
PROCEDURE ValidateValues:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER allRequired AS LOGICAL NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldIndex AS INTEGER NO-UNDO.
 DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE descriptor AS JsonObject NO-UNDO.
 DEFINE VARIABLE numberValue AS DECIMAL NO-UNDO.
 DEFINE VARIABLE allowedText AS CHARACTER NO-UNDO. DEFINE VARIABLE charIndex AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN RUN Fail("CIW_CADASTRO_VALIDATION","Dados obrigatorios.",422).
 EXTENT(names)=?. names=o:GetNames().
 DO n = 1 TO EXTENT(names):
  IF LOOKUP(names[n],cAllowed)=0 THEN RUN Fail("CIW_CADASTRO_FIELD_INVALID","Campo nao permitido.",422).
 END.
 DO fieldIndex = 1 TO jaFields:Length:
  descriptor=jaFields:GetJsonObject(fieldIndex). nameValue=descriptor:GetCharacter("name").
  IF NOT o:Has(nameValue) THEN DO:
   IF allRequired THEN RUN Fail("CIW_CADASTRO_VALIDATION","Estado original deve conter todos os campos editaveis.",422).
   NEXT.
  END.
  IF o:IsNull(nameValue) THEN NEXT.
  CASE descriptor:GetCharacter("type"):
   WHEN "character" THEN DO:
    IF o:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail("CIW_CADASTRO_VALIDATION","Texto invalido.",422).
    IF LENGTH(o:GetCharacter(nameValue))>descriptor:GetInteger("maxLength") THEN RUN Fail("CIW_CADASTRO_VALIDATION","Texto excede o limite.",422).
    IF NOT allRequired AND descriptor:Has("allowedCharacters") THEN DO:
     allowedText=descriptor:GetCharacter("allowedCharacters").
     DO charIndex=1 TO LENGTH(o:GetCharacter(nameValue)):
      IF INDEX(allowedText,SUBSTRING(o:GetCharacter(nameValue),charIndex,1))=0 THEN RUN Fail("CIW_CADASTRO_VALIDATION","Caracter nao permitido.",422).
     END.
    END.
   END.
   WHEN "logical" THEN IF o:GetType(nameValue)<>JsonDataType:BOOLEAN THEN RUN Fail("CIW_CADASTRO_VALIDATION","Indicador deve ser verdadeiro ou falso.",422).
   WHEN "integer" THEN DO:
    IF o:GetType(nameValue)<>JsonDataType:NUMBER THEN RUN Fail("CIW_CADASTRO_VALIDATION","Numero inteiro obrigatorio.",422).
    numberValue=o:GetDecimal(nameValue).
    IF numberValue<-2147483648 OR numberValue>2147483647 OR TRUNCATE(numberValue,0)<>numberValue THEN RUN Fail("CIW_CADASTRO_VALIDATION","Numero inteiro fora do limite.",422).
    IF descriptor:Has("binaryFlag") THEN IF descriptor:GetLogical("binaryFlag") AND numberValue<>0 AND numberValue<>1 THEN RUN Fail("CIW_CADASTRO_VALIDATION","Indicador deve ser zero ou um.",422).
   END.
  END CASE.
 END.
END PROCEDURE.
PROCEDURE ReadAll:
 CREATE QUERY hQuery. hQuery:SET-BUFFERS(hData).
 IF NOT hQuery:QUERY-PREPARE("FOR EACH " + hData:NAME + " NO-LOCK BY " + cKey) THEN UNDO,THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
 hQuery:QUERY-OPEN(). hQuery:GET-FIRST(NO-LOCK). jaRows=NEW JsonArray().
 DO WHILE NOT hQuery:QUERY-OFF-END:
  jaRows:Add(RecordJson()). hQuery:GET-NEXT(NO-LOCK).
 END.
 hQuery:QUERY-CLOSE(). DELETE OBJECT hQuery.
 poResponse:Add("data",jaRows).
END PROCEDURE.
PROCEDURE CheckDependencies:
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE ref AS HANDLE NO-UNDO.
 DEFINE VARIABLE found AS LOGICAL NO-UNDO.
 DO n = 1 TO 2:
  ref=IF n=1 THEN phReference1 ELSE phReference2.
  IF NOT VALID-HANDLE(ref) THEN NEXT.
  found=ref:FIND-FIRST("WHERE " + ref:NAME + "." + cKey + " = " + TRIM(STRING(iId)),SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF ref:LOCKED THEN RUN Fail("CIW_CADASTRO_BUSY","Dependencia em uso.",409).
  IF FindFailed() THEN UNDO,THROW NEW Progress.Lang.AppError("Leitura de dependencia falhou",0).
  IF found THEN RUN Fail("CIW_CADASTRO_DEPENDENCY","Registro possui vinculos e nao pode ser excluido.",409).
 END.
END PROCEDURE.

DO ON ERROR UNDO, THROW:
 poResponse=NEW JsonObject().
 IF NOT VALID-HANDLE(phData) OR NOT VALID-OBJECT(poDefinition) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Cadastro indisponivel.",503).
 cResource=poDefinition:GetCharacter("resource"). cKey=poDefinition:GetCharacter("primaryKey"). jaFields=poDefinition:GetJsonArray("fields").
 IF NOT ValidName(cResource) OR NOT ValidName(cKey) OR jaFields:Length=0 OR jaFields:Length>12 THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Definicao invalida.",503).
 CREATE BUFFER hData FOR TABLE phData.
 hField=hData:BUFFER-FIELD(cKey).
 IF hField:DATA-TYPE<>"INTEGER" OR hField:EXTENT<>0 THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Chave incompativel.",503).
 DO i = 1 TO jaFields:Length:
  joField=jaFields:GetJsonObject(i). cName=joField:GetCharacter("name"). cType=joField:GetCharacter("type").
  IF NOT ValidName(cName) OR cName=cKey OR LOOKUP(cName,cAllowed)>0 OR LOOKUP(cType,"character,integer,logical")=0 THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Campo incompativel.",503).
  hField=hData:BUFFER-FIELD(cName).
  IF CAPS(cType)<>hField:DATA-TYPE OR hField:EXTENT<>0 THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Tipo fisico incompativel.",503).
  cAllowed=cAllowed + (IF cAllowed="" THEN "" ELSE ",") + cName.
 END.
 EXTENT(cNames)=?. cNames=poRequest:GetNames().
 DO i = 1 TO EXTENT(cNames):
  IF LOOKUP(cNames[i],"operation,id,original,changes," + cAllowed + (IF cKey="id" THEN "" ELSE "," + cKey))=0 THEN RUN Fail("CIW_CADASTRO_FIELD_INVALID","Campo nao permitido na requisicao.",422).
 END.
 IF NOT poRequest:Has("operation") OR poRequest:GetType("operation")<>JsonDataType:STRING THEN RUN Fail("CIW_CADASTRO_OPERATION_INVALID","Operacao obrigatoria.",422).
 cOperation=poRequest:GetCharacter("operation").
 IF LOOKUP(cOperation,"read,get,create,update,delete,batch")=0 THEN RUN Fail("CIW_CADASTRO_OPERATION_INVALID","Operacao invalida.",422).
 IF cKey<>"id" AND poRequest:Has(cKey) THEN DO:
  IF cOperation="create" THEN RUN Fail("CIW_CADASTRO_ID_IMMUTABLE","ID e gerado pelo servidor.",422).
  IF LOOKUP(cOperation,"get,update,delete")=0 THEN RUN Fail("CIW_CADASTRO_FIELD_INVALID","Alias indisponivel nesta operacao.",422).
  IF NOT poRequest:Has("id") OR ReadNamedId(poRequest,cKey)<>ReadId(poRequest) THEN RUN Fail("CIW_CADASTRO_ID_IMMUTABLE","Identidade divergente.",422).
 END.
 IF cOperation="read" THEN DO: RUN ReadAll. poResponse:Add("success",TRUE). RETURN. END.
 IF cOperation="get" THEN DO:
  iId=ReadId(poRequest). lFound=hData:FIND-FIRST("WHERE " + hData:NAME + "." + cKey + " = " + TRIM(STRING(iId)),NO-LOCK) NO-ERROR.
  IF FindFailed() THEN UNDO,THROW NEW Progress.Lang.AppError("Leitura recusada",0).
  IF NOT lFound THEN RUN Fail("CIW_CADASTRO_NOT_FOUND","Registro nao encontrado.",404).
  poResponse:Add("success",TRUE). poResponse:Add("data",RecordJson()). RETURN.
 END.
 lBatch=cOperation="batch".
 IF lBatch THEN DO:
  IF NOT poRequest:Has("changes") OR poRequest:GetType("changes")<>JsonDataType:ARRAY THEN RUN Fail("CIW_CADASTRO_VALIDATION","Lote obrigatorio.",422).
  jaChanges=poRequest:GetJsonArray("changes").
 END.
 ELSE DO:
  jaChanges=NEW JsonArray(). joChange=NEW JsonObject(). joChange:Add("operation",cOperation). joChange:Add("clientId","single").
  IF poRequest:Has("id") THEN DO:
   IF cOperation="create" THEN RUN Fail("CIW_CADASTRO_ID_IMMUTABLE","ID e gerado pelo servidor.",422).
   joChange:Add("id",ReadId(poRequest)).
  END.
  IF poRequest:Has("original") THEN joChange:Add("original",poRequest:GetJsonObject("original")).
  IF cOperation<>"delete" THEN DO:
   joValues=CAST(poRequest:Clone(),JsonObject).
   joValues:Remove("operation"). IF joValues:Has("id") THEN joValues:Remove("id"). IF joValues:Has("original") THEN joValues:Remove("original").
   IF cKey<>"id" AND joValues:Has(cKey) THEN joValues:Remove(cKey).
   joChange:Add("data",joValues).
  END.
  jaChanges:Add(joChange).
 END.
 IF jaChanges:Length<1 OR jaChanges:Length>200 THEN RUN Fail("CIW_CADASTRO_VALIDATION","Lote deve ter de1a200linhas.",422).
 DO i = 1 TO jaChanges:Length:
  iLine=i.
  IF jaChanges:GetType(i)<>JsonDataType:OBJECT THEN RUN Fail("CIW_CADASTRO_VALIDATION","Linha invalida.",422).
  joChange=jaChanges:GetJsonObject(i). EXTENT(cNames)=?. cNames=joChange:GetNames().
  DO j = 1 TO EXTENT(cNames): IF LOOKUP(cNames[j],"operation,clientId,id,data,original")=0 THEN RUN Fail("CIW_CADASTRO_FIELD_INVALID","Campo de linha invalido.",422). END.
  IF NOT joChange:Has("clientId") OR joChange:GetType("clientId")<>JsonDataType:STRING THEN RUN Fail("CIW_CADASTRO_VALIDATION","clientId obrigatorio.",422).
  cText=joChange:GetCharacter("clientId").
  IF LENGTH(cText)<1 OR LENGTH(cText)>160 OR CAN-FIND(FIRST ttChange WHERE ttChange.clientId=cText) THEN RUN Fail("CIW_CADASTRO_VALIDATION","clientId invalido ou repetido.",422).
  IF NOT joChange:Has("operation") OR joChange:GetType("operation")<>JsonDataType:STRING THEN RUN Fail("CIW_CADASTRO_OPERATION_INVALID","Operacao de linha invalida.",422).
  CREATE ttChange. ASSIGN ttChange.lineNo=i ttChange.clientId=cText ttChange.op=joChange:GetCharacter("operation").
  IF LOOKUP(ttChange.op,"create,update,delete")=0 THEN RUN Fail("CIW_CADASTRO_OPERATION_INVALID","Operacao de linha invalida.",422).
  IF ttChange.op="create" THEN DO:
   IF joChange:Has("id") OR joChange:Has("original") THEN RUN Fail("CIW_CADASTRO_ID_IMMUTABLE","Inclusao nao recebe ID ou original.",422).
  END.
  ELSE DO:
   ttChange.recordId=ReadId(joChange).
   IF CAN-FIND(FIRST ttChange WHERE ttChange.lineNo<i AND ttChange.op<>"create" AND ttChange.recordId=ReadId(joChange)) THEN RUN Fail("CIW_CADASTRO_VALIDATION","Registro repetido no lote.",422).
   IF NOT joChange:Has("original") OR joChange:GetType("original")<>JsonDataType:OBJECT THEN RUN Fail("CIW_CADASTRO_VALIDATION","Estado original obrigatorio.",422).
   RUN ValidateValues(joChange:GetJsonObject("original"),TRUE).
  END.
  IF ttChange.op<>"delete" THEN DO:
   IF NOT joChange:Has("data") OR joChange:GetType("data")<>JsonDataType:OBJECT THEN RUN Fail("CIW_CADASTRO_VALIDATION","Dados obrigatorios.",422).
   RUN ValidateValues(joChange:GetJsonObject("data"),FALSE).
  END.
  ELSE IF joChange:Has("data") THEN RUN Fail("CIW_CADASTRO_FIELD_INVALID","Exclusao nao recebe dados de alteracao.",422).
 END.
 jaResults=NEW JsonArray(). jaAudit=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  IF cResource="formatos_amostra" AND CAN-FIND(FIRST ttChange WHERE ttChange.op="create") AND NOT VALID-HANDLE(phIdentity) THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Provider de identidade obrigatorio.",503).
  IF CAN-FIND(FIRST ttChange WHERE ttChange.op="create") AND NOT VALID-HANDLE(phIdentity) THEN DO:
   lFound=hData:FIND-LAST("",EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
   IF hData:LOCKED THEN RUN Fail("CIW_CADASTRO_BUSY","Outra inclusao esta em andamento.",409).
   IF FindFailed() THEN UNDO,THROW NEW Progress.Lang.AppError("Chave indisponivel",0).
   iNext=IF lFound THEN hData:BUFFER-FIELD(cKey):BUFFER-VALUE ELSE 0.
   IF iNext=? THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Chave desconhecida.",503).
   IF iNext<0 THEN iNext=0.
  END.
  FOR EACH ttChange BY ttChange.lineNo:
   iLine=ttChange.lineNo. joChange=jaChanges:GetJsonObject(iLine).
   IF ttChange.op="create" THEN DO:
    IF VALID-HANDLE(phIdentity) THEN DO:
     iNext=?. RUN NextCadastroId IN phIdentity(cResource,OUTPUT iNext) NO-ERROR.
     IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES>0 OR iNext=? OR iNext<1 THEN RUN Fail("CIW_CADASTRO_SEQUENCE","Identidade indisponivel.",503).
     lFound=hData:FIND-FIRST("WHERE " + hData:NAME + "." + cKey + " = " + TRIM(STRING(iNext)),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
     IF hData:LOCKED THEN RUN Fail("CIW_CADASTRO_BUSY","Identidade em uso.",409).
     IF FindFailed() THEN RUN Fail("CIW_CADASTRO_CONFIGURATION","Leitura de identidade indisponivel.",503).
     IF lFound THEN RUN Fail("CIW_CADASTRO_ID_COLLISION","Identidade ja utilizada; sequencia nao alterada automaticamente.",409).
    END.
    ELSE DO:
     IF iNext>=2147483647 THEN RUN Fail("CIW_CADASTRO_ID_LIMIT","Limite de chaves atingido.",409).
     iNext=iNext + 1.
    END.
    IF NOT hData:BUFFER-CREATE() THEN UNDO,THROW NEW Progress.Lang.AppError("Inclusao recusada",0).
    hData:BUFFER-FIELD(cKey):BUFFER-VALUE=iNext. ttChange.recordId=iNext. joBefore=NEW JsonObject().
   END.
   ELSE DO:
    iId=ttChange.recordId.
    lFound=hData:FIND-FIRST("WHERE " + hData:NAME + "." + cKey + " = " + TRIM(STRING(iId)),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
    IF hData:LOCKED THEN RUN Fail("CIW_CADASTRO_BUSY","Registro em uso.",409).
    IF FindFailed() THEN UNDO,THROW NEW Progress.Lang.AppError("Leitura sob lock recusada",0).
    IF NOT lFound THEN RUN Fail("CIW_CADASTRO_NOT_FOUND","Registro nao encontrado.",404).
    IF NOT SameOriginal(joChange:GetJsonObject("original")) THEN RUN Fail("CIW_CADASTRO_CHANGED","Registro alterado por outro usuario. Recarregue.",409).
    joBefore=RecordJson().
   END.
   iId=ttChange.recordId.
   IF ttChange.op="delete" THEN DO:
    RUN CheckDependencies.
    IF NOT hData:BUFFER-DELETE() THEN UNDO,THROW NEW Progress.Lang.AppError("Exclusao recusada",0).
    joAfter=NEW JsonObject().
   END.
   ELSE DO:
    joValues=joChange:GetJsonObject("data").
    DO k = 1 TO jaFields:Length:
     joField=jaFields:GetJsonObject(k). cName=joField:GetCharacter("name").
     IF NOT joValues:Has(cName) THEN DO:
      IF ttChange.op="create" AND joField:Has("default") AND joField:GetCharacter("type")="logical" THEN hData:BUFFER-FIELD(cName):BUFFER-VALUE=joField:GetLogical("default").
      NEXT.
     END.
     hField=hData:BUFFER-FIELD(cName).
     IF joValues:IsNull(cName) THEN hField:BUFFER-VALUE=?.
     ELSE CASE joField:GetCharacter("type"):
      WHEN "character" THEN hField:BUFFER-VALUE=joValues:GetCharacter(cName).
      WHEN "integer" THEN hField:BUFFER-VALUE=joValues:GetInteger(cName).
      WHEN "logical" THEN hField:BUFFER-VALUE=joValues:GetLogical(cName).
     END CASE.
    END.
    IF NOT hData:BUFFER-VALIDATE() THEN UNDO,THROW NEW Progress.Lang.AppError("Gravacao recusada",0).
    joAfter=RecordJson(). IF NOT lBatch THEN joSingle=joAfter.
   END.
   joItem=NEW JsonObject(). joItem:Add("clientId",ttChange.clientId). joItem:Add("operation",ttChange.op). joItem:Add("id",iId). jaResults:Add(joItem).
   joItem=NEW JsonObject(). joItem:Add("clientId",ttChange.clientId). joItem:Add("operation",ttChange.op). joItem:Add("recordId",iId). joItem:Add("before",joBefore). joItem:Add("after",joAfter). jaAudit:Add(joItem).
  END.
  IF lBatch THEN RUN ReadAll.
 END.
 poResponse:Add("success",TRUE).
 IF lBatch THEN poResponse:Add("results",jaResults).
 ELSE IF cOperation<>"delete" THEN poResponse:Add("data",joSingle).
 joAudit=NEW JsonObject(). joAudit:Add("version",1). joAudit:Add("source","progress-transaction"). joAudit:Add("resource",cResource). joAudit:Add("operation",cOperation).
 IF lBatch THEN joAudit:Add("changes",jaAudit).
 ELSE DO: joAudit:Add("recordId",iId). joAudit:Add("before",joBefore). joAudit:Add("after",joAfter). END.
 poResponse:Add("audit",joAudit).
 CATCH e AS Progress.Lang.Error:
  IF NOT poResponse:Has("error") THEN RUN BuildError("CIW_CADASTRO_PERSISTENCE_REJECTED","Operacao recusada. Nenhuma linha do lote confirmada.",409).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hQuery) THEN DELETE OBJECT hQuery NO-ERROR.
  IF VALID-HANDLE(hData) THEN DO: hData:BUFFER-RELEASE() NO-ERROR. DELETE OBJECT hData NO-ERROR. END.
  IF VALID-HANDLE(phReference1) THEN phReference1:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phReference2) THEN phReference2:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE BuildError:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add("code",codeValue). err:Add("status",statusValue).
 err:Add("message",(IF iLine>0 THEN "Linha " + TRIM(STRING(iLine)) + ": " ELSE "") + messageValue).
 poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN BuildError(codeValue,messageValue,statusValue).
 UNDO,THROW NEW Progress.Lang.AppError(codeValue,0).
END PROCEDURE.

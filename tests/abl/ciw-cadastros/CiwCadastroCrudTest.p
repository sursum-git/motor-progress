BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttData FIELD id AS INTEGER FIELD descricao AS CHARACTER FIELD ativo AS LOGICAL FIELD ordem AS INTEGER INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttReference FIELD id AS INTEGER.
DEFINE VARIABLE joDefinition AS JsonObject NO-UNDO.
DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE resp AS JsonObject NO-UNDO.
DEFINE VARIABLE joOriginal AS JsonObject NO-UNDO.
DEFINE VARIABLE jaChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE joChange AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE idCreated AS INTEGER NO-UNDO.
DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
OUTPUT TO VALUE("ciw-cadastro-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 servicePath=SEARCH("CiwCadastroCrudService.p"). RUN Check(servicePath<>?,"service must exist").
 joDefinition=NEW JsonObject(). joDefinition:Add("resource","test_cadastro"). joDefinition:Add("primaryKey","id").
 jaFields=NEW JsonArray(). joItem=NEW JsonObject(). joItem:Add("name","descricao"). joItem:Add("type","character"). joItem:Add("maxLength",50). jaFields:Add(joItem).
 joItem=NEW JsonObject(). joItem:Add("name","ativo"). joItem:Add("type","logical"). jaFields:Add(joItem). joDefinition:Add("fields",jaFields).
 RUN SetRequest("read"). RUN ExecuteService. RUN Success.
 RUN Check(resp:GetJsonArray("data"):Length=0,"empty list").
 RUN SetRequest("create"). req:Add("descricao","CODEx-Ação"). req:Add("ativo",TRUE). RUN ExecuteService. RUN Success.
 idCreated=resp:GetJsonObject("data"):GetInteger("id"). RUN Check(idCreated=1,"generated key").
 RUN Check(NOT resp:GetJsonObject("audit"):GetJsonObject("before"):Has("id"),"create before empty").
 RUN Check(resp:GetJsonObject("data"):GetLogical("ativo"),"logical JSON").
 RUN SetRequest("get"). req:Add("id",idCreated). RUN ExecuteService. RUN Success.
 RUN Check(resp:GetJsonObject("data"):GetCharacter("descricao")="CODEx-Ação","Unicode").
 RUN SetRequest("update"). req:Add("id",idCreated). req:Add("descricao","stale"). joOriginal=NEW JsonObject(). joOriginal:Add("descricao","wrong"). joOriginal:Add("ativo",TRUE). req:Add("original",joOriginal).
 RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_CHANGED",409).
 RUN SetRequest("update"). req:Add("id",idCreated). req:Add("descricao","CODEx-Updated"). joOriginal=NEW JsonObject(). joOriginal:Add("descricao","CODEx-Ação"). joOriginal:Add("ativo",TRUE). req:Add("original",joOriginal).
 RUN ExecuteService. RUN Success. RUN Check(resp:GetJsonObject("data"):GetCharacter("descricao")="CODEx-Updated","updated").
 RUN SetRequest("create"). req:Add("descricao",FILL("á",51)). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_VALIDATION",422).
 RUN SetRequest("create"). req:Add("descricao","x"). req:Add("ativo",1). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_VALIDATION",422).
 RUN SetRequest("create"). req:Add("id",100). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_ID_IMMUTABLE",422).
 RUN SetRequest("create"). req:Add("sql","DROP TABLE"). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_FIELD_INVALID",422).
 RUN SetRequest("delete"). req:Add("id",idCreated). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_VALIDATION",422).
 RUN AddReference(idCreated).
 RUN DeleteRequest(idCreated,"CODEx-Updated",TRUE). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_DEPENDENCY",409).
 RUN ClearReference.
 /* Primeira linha altera; segunda falha. Ambas devem ser desfeitas. */
 RUN SetRequest("batch"). jaChanges=NEW JsonArray().
 joChange=NEW JsonObject(). joChange:Add("operation","update"). joChange:Add("clientId","u1"). joChange:Add("id",idCreated).
 joItem=NEW JsonObject(). joItem:Add("descricao","SHOULD_ROLLBACK"). joChange:Add("data",joItem).
 joOriginal=NEW JsonObject(). joOriginal:Add("descricao","CODEx-Updated"). joOriginal:Add("ativo",TRUE). joChange:Add("original",joOriginal). jaChanges:Add(joChange).
 joChange=NEW JsonObject(). joChange:Add("operation","delete"). joChange:Add("clientId","d2"). joChange:Add("id",2147483647).
 joOriginal=NEW JsonObject(). joOriginal:Add("descricao","missing"). joOriginal:Add("ativo",TRUE). joChange:Add("original",joOriginal). jaChanges:Add(joChange). req:Add("changes",jaChanges).
 RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_NOT_FOUND",404).
 RUN Check(NOT resp:Has("audit"),"failure has no confirmed audit").
 RUN SetRequest("get"). req:Add("id",idCreated). RUN ExecuteService. RUN Success.
 RUN Check(resp:GetJsonObject("data"):GetCharacter("descricao")="CODEx-Updated","rollback restored previous line").
 RUN DeleteRequest(idCreated,"CODEx-Updated",TRUE). RUN ExecuteService. RUN Success.
 RUN SetRequest("create"). req:AddNull("descricao"). req:AddNull("ativo"). RUN ExecuteService. RUN Success.
 RUN Check(resp:GetJsonObject("data"):IsNull("descricao") AND resp:GetJsonObject("data"):IsNull("ativo"),"nullable fields").
 RUN SetRequest("read"). RUN ExecuteService. RUN Success. RUN Check(resp:GetJsonArray("data"):Length=1,"read count").
 RUN SetRequest("batch"). jaChanges=NEW JsonArray().
 joChange=NEW JsonObject(). joChange:Add("operation","create"). joChange:Add("clientId","a"). joItem=NEW JsonObject(). joItem:Add("descricao","CODEx-B"). joItem:Add("ativo",TRUE). joChange:Add("data",joItem). jaChanges:Add(joChange).
 joChange=NEW JsonObject(). joChange:Add("operation","create"). joChange:Add("clientId","b"). joItem=NEW JsonObject(). joItem:Add("descricao","CODEx-C"). joItem:Add("ativo",FALSE). joChange:Add("data",joItem). jaChanges:Add(joChange). req:Add("changes",jaChanges).
 RUN ExecuteService. RUN Success. RUN Check(resp:GetJsonArray("results"):Length=2,"batch create results").
 RUN Check(resp:GetJsonArray("results"):GetJsonObject(1):GetInteger("id")=2 AND resp:GetJsonArray("results"):GetJsonObject(2):GetInteger("id")=3,"distinct generated keys").
 RUN SetRequest("batch"). jaChanges=NEW JsonArray().
 joChange=NEW JsonObject(). joChange:Add("operation","update"). joChange:Add("clientId","u"). joChange:Add("id",2). joItem=NEW JsonObject(). joItem:Add("descricao","CODEx-B2"). joChange:Add("data",joItem). joOriginal=NEW JsonObject(). joOriginal:Add("descricao","CODEx-B"). joOriginal:Add("ativo",TRUE). joChange:Add("original",joOriginal). jaChanges:Add(joChange).
 joChange=NEW JsonObject(). joChange:Add("operation","delete"). joChange:Add("clientId","d"). joChange:Add("id",3). joOriginal=NEW JsonObject(). joOriginal:Add("descricao","CODEx-C"). joOriginal:Add("ativo",FALSE). joChange:Add("original",joOriginal). jaChanges:Add(joChange).
 joChange=NEW JsonObject(). joChange:Add("operation","create"). joChange:Add("clientId","c"). joItem=NEW JsonObject(). joItem:Add("descricao","CODEx-D"). joChange:Add("data",joItem). jaChanges:Add(joChange). req:Add("changes",jaChanges).
 RUN ExecuteService. RUN Success. RUN Check(resp:GetJsonArray("results"):Length=3,"mixed batch"). RUN Check(resp:GetJsonObject("audit"):GetJsonArray("changes"):Length=3,"one confirmed snapshot per line").
 RUN SetRequest("batch"). req:Add("changes",NEW JsonArray()). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_VALIDATION",422).
 /* Indicador fisico inteiro de motivos_desconto preserva0/1, nao vira logical. */
 joItem=NEW JsonObject(). joItem:Add("name","ordem"). joItem:Add("type","integer"). joItem:Add("binaryFlag",TRUE). jaFields:Add(joItem).
 RUN SetRequest("create"). req:Add("ordem",2). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_VALIDATION",422).
 RUN SetRequest("create"). req:Add("ordem",0.5). RUN ExecuteService. RUN ErrorCode("CIW_CADASTRO_VALIDATION",422).
 RUN SetRequest("create"). req:Add("ordem",1). req:Add("descricao","CODEx-Integer"). RUN ExecuteService. RUN Success.
 RUN Check(resp:GetJsonObject("data"):GetInteger("ordem")=1,"integer field").
 PUT UNFORMATTED "PASS " checks " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE SetRequest:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 req=NEW JsonObject(). req:Add("operation",op).
END PROCEDURE.
PROCEDURE ExecuteService:
 IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
 RUN VALUE(servicePath)(INPUT BUFFER ttData:HANDLE,INPUT BUFFER ttReference:HANDLE,INPUT ?,INPUT joDefinition,INPUT req,OUTPUT resp).
END PROCEDURE.
PROCEDURE AddReference:
 DEFINE INPUT PARAMETER idValue AS INTEGER NO-UNDO.
 CREATE ttReference. ttReference.id=idValue. RELEASE ttReference.
END PROCEDURE.
PROCEDURE ClearReference:
 EMPTY TEMP-TABLE ttReference.
END PROCEDURE.
PROCEDURE DeleteRequest:
 DEFINE INPUT PARAMETER idValue AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER descr AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER active AS LOGICAL NO-UNDO.
 RUN SetRequest("delete"). req:Add("id",idValue). joOriginal=NEW JsonObject(). joOriginal:Add("descricao",descr). joOriginal:Add("ativo",active). req:Add("original",joOriginal).
END PROCEDURE.
PROCEDURE Success:
 RUN Check(resp:GetLogical("success"),"success").
END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 RUN Check(NOT resp:GetLogical("success"),"denied").
 IF resp:GetJsonObject("error"):GetCharacter("code")<>c THEN PUT UNFORMATTED "Expected " c " got " resp:GetJsonObject("error"):GetCharacter("code") " " resp:GetJsonObject("error"):GetCharacter("message") SKIP.
 RUN Check(resp:GetJsonObject("error"):GetCharacter("code")=c,c).
 RUN Check(resp:GetJsonObject("error"):GetInteger("status")=s,"status").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError(labelText,0).
 checks = checks + 1.
END PROCEDURE.

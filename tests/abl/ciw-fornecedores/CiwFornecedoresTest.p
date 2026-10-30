BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttEmit FIELD cod-emitente AS INTEGER FIELD nome-abrev AS CHARACTER
 FIELD nome-emit AS CHARACTER FIELD identific AS INTEGER FIELD cod-gr-forn AS INTEGER
 FIELD data-implant AS DATE INDEX pk IS PRIMARY UNIQUE cod-emitente.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER NO-UNDO INITIAL "fornecedores".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
OUTPUT TO VALUE("fornecedores-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 CREATE ttEmit. ASSIGN cod-emitente=3 nome-abrev="Terceiro" nome-emit="Ação d'água" identific=2 cod-gr-forn=1 data-implant=DATE(10,20,2026).
 CREATE ttEmit. ASSIGN cod-emitente=1 nome-abrev="Primeiro" nome-emit="Estrangeiro" identific=1 cod-gr-forn=2 data-implant=?.
 CREATE ttEmit. ASSIGN cod-emitente=2 nome-abrev="Ambos" nome-emit="Ambos" identific=2 cod-gr-forn=2 data-implant=DATE(1,2,2026).
 RELEASE ttEmit.
 RUN NewReq("read"). RUN CallService. RUN Check(res:GetLogical("success"),"read sucesso").
 RUN Check(res:GetJsonArray("data"):Length=2,"apenas identific2").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(1):GetInteger("cod_emitente")=2,"ordem codigo").
 RUN Check(NOT res:GetJsonArray("data"):GetJsonObject(1):Has("data_implant"),"projecao comum").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(2):GetCharacter("nome_emit")="Ação d'água","acentos").
 RUN NewReq("get"). req:Add("id",1). RUN CallService. RUN Err("CIW_FORNECEDOR_NOT_FOUND").
 resourceName="fornecedores_estrangeiros".
 RUN NewReq("read"). RUN CallService. RUN Check(res:GetJsonArray("data"):Length=2,"grupo2 independente identific").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(1):IsNull("data_implant"),"data desconhecida").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(2):GetCharacter("data_implant")="2026-01-02","data ISO independente cultura").
 RUN NewReq("get"). req:Add("id","1"). RUN CallService. RUN Check(res:GetJsonObject("data"):GetInteger("cod_emitente")=1,"get string inteiro").
 RUN NewReq("get"). req:Add("id","1"). req:Add("cod_emitente",1). RUN CallService. RUN Check(res:GetLogical("success"),"detalhe contrato Builder com alias").
 RUN NewReq("get"). req:Add("id",1). req:Add("cod_emitente",2). RUN CallService. RUN Err("CIW_FORNECEDOR_VALIDATION").
 RUN NewReq("get"). req:Add("id",3). RUN CallService. RUN Err("CIW_FORNECEDOR_NOT_FOUND").
 RUN NewReq("get"). req:Add("id",1.5). RUN CallService. RUN Err("CIW_FORNECEDOR_VALIDATION").
 RUN NewReq("get"). req:Add("id","1 OR TRUE"). RUN CallService. RUN Err("CIW_FORNECEDOR_VALIDATION").
 RUN NewReq("read"). req:Add("sql","DELETE"). RUN CallService. RUN Err("CIW_FORNECEDOR_FIELD_INVALID").
 RUN NewReq("delete"). req:Add("id",1). RUN CallService. RUN Err("CIW_FORNECEDOR_READ_ONLY").
 resourceName="emitente". RUN NewReq("read"). RUN CallService. RUN Err("CIW_FORNECEDOR_RESOURCE_INVALID").
 RUN Check(CAN-FIND(FIRST ttEmit WHERE cod-emitente=1),"sem mutacoes").
 EMPTY TEMP-TABLE ttEmit.
 PUT UNFORMATTED "PASS " n " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE.
QUIT.
PROCEDURE NewReq:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 IF VALID-OBJECT(res) THEN DELETE OBJECT res.
 req=NEW JsonObject(). req:Add("operation",op).
END.
PROCEDURE CallService:
 RUN CiwFornecedoresService.p(INPUT BUFFER ttEmit:HANDLE,INPUT resourceName,INPUT req,OUTPUT res).
END.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 IF ok<>TRUE THEN UNDO,THROW NEW Progress.Lang.AppError(labelText,0).
 n = n + 1.
END.
PROCEDURE Err:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 RUN Check(NOT res:GetLogical("success"),"erro esperado").
 RUN Check(res:GetJsonObject("error"):GetCharacter("code")=code,code).
END.


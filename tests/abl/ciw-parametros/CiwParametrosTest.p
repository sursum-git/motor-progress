BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
/* TT undoable: nunca conectar este teste a banco operacional. */
DEFINE TEMP-TABLE ttParam FIELD cod-param AS CHARACTER FIELD val-param AS CHARACTER
 FIELD tp-param AS INTEGER FIELD agrup_im_param_id AS INTEGER
 INDEX pk IS PRIMARY UNIQUE cod-param.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE oldStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO INITIAL "CODEx-a'ção".
OUTPUT TO VALUE("parametros-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 RUN Check(SEARCH("CiwParametrosService.p")<>?,"Servico deve existir").
 RUN NewRequest("create"). req:Add("codigo",codeValue). req:Add("val_param","Ação"). req:Add("tp_param",1). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject("data"):GetCharacter("cod_param")=codeValue,"chave textual preservada").
 RUN Check(res:GetJsonObject("audit"):GetCharacter("recordId")=codeValue,"auditoria tem chave textual").
 RUN Check(NOT res:GetJsonObject("audit"):GetJsonObject("before"):Has("cod_param"),"inclusao antes vazio").
 stamp=res:GetJsonObject("data"):GetCharacter("row_stamp"). RUN Check(LENGTH(stamp)=64,"hash do estado").
 RUN NewRequest("get"). req:Add("id",codeValue). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject("data"):GetCharacter("val_param")="Ação","get com apostrofo e acento").
 RUN NewRequest("update"). req:Add("id",LC(codeValue)). req:Add("row_stamp",stamp). req:Add("val_param","codigo nao canonico"). RUN CallService. RUN Err("CIW_PARAM_KEY_IMMUTABLE",422).
 RUN NewRequest("create"). req:Add("codigo",LC(codeValue)). req:Add("val_param","x"). req:Add("tp_param",1). RUN CallService. RUN Err("CIW_PARAM_DUPLICATE",409).
 RUN NewRequest("update"). req:Add("id",codeValue). req:Add("val_param","sem stamp"). RUN CallService. RUN Err("CIW_PARAM_ORIGINAL_REQUIRED",422).
 RUN NewRequest("update"). req:Add("id",codeValue). req:Add("row_stamp",stamp). req:Add("codigo","CODEx-outra"). RUN CallService. RUN Err("CIW_PARAM_KEY_IMMUTABLE",422).
 RUN NewRequest("update"). req:Add("id",codeValue). req:Add("row_stamp",stamp). req:Add("val_param",FILL("á",501)). RUN CallService. RUN Err("CIW_PARAM_VALIDATION",422).
 RUN NewRequest("update"). req:Add("id",codeValue). req:Add("row_stamp",stamp). req:Add("val_param","nao confirmar"). req:Add("tp_param",1.2). RUN CallService. RUN Err("CIW_PARAM_VALIDATION",422).
 FIND ttParam WHERE ttParam.cod-param=codeValue. RUN Check(ttParam.val-param="Ação","falha preserva valor").
 ttParam.agrup_im_param_id=17. RELEASE ttParam.
 RUN NewRequest("update"). req:Add("id",codeValue). req:Add("row_stamp",stamp). req:Add("val_param","conflito"). RUN CallService. RUN Err("CIW_PARAM_CHANGED",409).
 RUN NewRequest("get"). req:Add("id",codeValue). RUN CallService. RUN Success. stamp=res:GetJsonObject("data"):GetCharacter("row_stamp"). oldStamp=stamp.
 RUN NewRequest("update"). req:Add("id",codeValue). req:Add("row_stamp",stamp). req:Add("val_param","Atualizado"). req:Add("tp_param",2). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject("data"):GetCharacter("row_stamp")<>oldStamp,"hash muda ao atualizar"). stamp=res:GetJsonObject("data"):GetCharacter("row_stamp").
 FIND ttParam WHERE ttParam.cod-param=codeValue NO-LOCK. RUN Check(ttParam.agrup_im_param_id=17,"grupo nao editavel preservado"). RELEASE ttParam.
 RUN NewRequest("delete"). req:Add("id",codeValue). req:Add("row_stamp",oldStamp). RUN CallService. RUN Err("CIW_PARAM_CHANGED",409).
 RUN NewRequest("create"). req:Add("codigo","CODEx-excesso"). req:Add("tp_param",6). RUN CallService. RUN Err("CIW_PARAM_VALIDATION",422).
 RUN NewRequest("create"). req:Add("codigo","CODEx-campo"). req:Add("tp_param",1). req:Add("agrup_im_param_id",8). RUN CallService. RUN Err("CIW_PARAM_FIELD_INVALID",422).
 RUN NewRequest("create"). req:Add("codigo","CODEx-null"). req:AddNull("val_param"). req:Add("tp_param",0). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject("data"):IsNull("val_param"),"null preservado").
 RUN NewRequest("read"). RUN CallService. RUN Success. RUN Check(res:GetJsonArray("data"):Length=2,"leitura dos dois registros").
 RUN NewRequest("delete"). req:Add("id",codeValue). req:Add("row_stamp",stamp). RUN CallService. RUN Success.
 RUN Check(NOT res:GetJsonObject("audit"):GetJsonObject("after"):Has("cod_param"),"exclusao depois vazio").
 RUN NewRequest("get"). req:Add("id",codeValue). RUN CallService. RUN Err("CIW_PARAM_NOT_FOUND",404).
 RUN NewRequest("get"). req:Add("id",1). RUN CallService. RUN Err("CIW_PARAM_VALIDATION",422).
 RUN NewRequest("read"). req:Add("sql","x"). RUN CallService. RUN Err("CIW_PARAM_FIELD_INVALID",422).
 EMPTY TEMP-TABLE ttParam.
 PUT UNFORMATTED "PASS " n " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE.
QUIT.
PROCEDURE NewRequest:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 req=NEW JsonObject(). req:Add("operation",op).
END PROCEDURE.
PROCEDURE CallService:
 IF VALID-OBJECT(res) THEN DELETE OBJECT res.
 RUN CiwParametrosService.p(INPUT BUFFER ttParam:HANDLE,INPUT req,OUTPUT res).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 n=n + 1.
END PROCEDURE.
PROCEDURE Success:
 RUN Check(res:Has("success") AND res:GetLogical("success"),"sucesso esperado").
END PROCEDURE.
PROCEDURE Err:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN Check(res:Has("error"),"erro esperado " + code).
 RUN Check(res:GetJsonObject("error"):GetCharacter("code")=code,"codigo " + code).
 RUN Check(res:GetJsonObject("error"):GetInteger("status")=statusCode,"status esperado").
 RUN Check(NOT res:Has("audit"),"falha sem auditoria confirmada").
END PROCEDURE.

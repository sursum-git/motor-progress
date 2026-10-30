BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttItem FIELD it-codigo AS CHARACTER FIELD desc-item AS CHARACTER FIELD ge-codigo AS INTEGER
 INDEX pk IS PRIMARY UNIQUE it-codigo.
DEFINE TEMP-TABLE ttRep FIELD cdn_repres AS INTEGER FIELD nom_pessoa AS CHARACTER FIELD nom_abrev AS CHARACTER FIELD dat_desligto AS DATE
 INDEX pk IS PRIMARY cdn_repres.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER NO-UNDO INITIAL "itens".
DEFINE VARIABLE tableHandle AS HANDLE NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE repKey AS CHARACTER NO-UNDO.
OUTPUT TO VALUE("referencias-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 CREATE ttItem. ASSIGN it-codigo="A'50" desc-item="Ação d'água" ge-codigo=50.
 CREATE ttItem. ASSIGN it-codigo="B60" desc-item=? ge-codigo=60.
 CREATE ttItem. ASSIGN it-codigo="X49" desc-item="fora" ge-codigo=49.
 CREATE ttItem. ASSIGN it-codigo="Y61" desc-item="fora" ge-codigo=61.
 RELEASE ttItem.
 tableHandle=BUFFER ttItem:HANDLE.
 RUN NewReq("read"). RUN CallService. RUN Check(res:GetLogical("success"),"read itens").
 RUN Check(res:GetJsonArray("data"):Length=2,"limites inclusivos50/60 excluem49/61").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(1):GetCharacter("it_codigo")="A'50","ordem codigo").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(1):GetCharacter("descricao")="Ação d'água","acentos").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(2):IsNull("descricao"),"null preservado").
 RUN NewReq("get"). req:Add("id","A'50"). req:Add("it_codigo","A'50"). RUN CallService. RUN Check(res:GetJsonObject("data"):GetCharacter("it_codigo")="A'50","apostrofo e alias Builder").
 RUN NewReq("get"). req:Add("id","A'50"). req:Add("it_codigo","B60"). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id","X49"). RUN CallService. RUN Err("CIW_REFERENCIA_NOT_FOUND").
 RUN NewReq("get"). req:Add("id","A'50' OR TRUE OR it-codigo = 'X49"). RUN CallService. RUN Err("CIW_REFERENCIA_NOT_FOUND").
 RUN NewReq("get"). req:Add("id",50). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id",""). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id",CHR(10)). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("read"). req:Add("sql","x"). RUN CallService. RUN Err("CIW_REFERENCIA_FIELD_INVALID").
 RUN NewReq("update"). req:Add("id","A'50"). RUN CallService. RUN Err("CIW_REFERENCIA_READ_ONLY").
 CREATE ttRep. ASSIGN cdn_repres=3 nom_pessoa="Desligado" nom_abrev="X" dat_desligto=DATE(10,20,2026).
 CREATE ttRep. ASSIGN cdn_repres=2 nom_pessoa="João" nom_abrev="J" dat_desligto=?.
 CREATE ttRep. ASSIGN cdn_repres=0 nom_pessoa="Zero" nom_abrev=? dat_desligto=?.
 CREATE ttRep. ASSIGN cdn_repres=2 nom_pessoa="João" nom_abrev="J" dat_desligto=?.
 CREATE ttRep. ASSIGN cdn_repres=2 nom_pessoa="Outro nome" nom_abrev="O" dat_desligto=?.
 RELEASE ttRep.
 ASSIGN tableHandle=BUFFER ttRep:HANDLE resourceName="representantes_ativos".
 RUN NewReq("read"). RUN CallService. RUN Check(res:GetJsonArray("data"):Length=3,"ativos DISTINCT preserva nomes diferentes no mesmo codigo").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(1):GetInteger("cdn_repres")=0,"zero e chave valida").
 RUN Check(res:GetJsonArray("data"):GetJsonObject(1):IsNull("nom_abrev"),"null representante").
 repKey=res:GetJsonArray("data"):GetJsonObject(2):GetCharacter("representante_key").
 RUN Check(repKey="94B404667F8A74467B79D3B58BE4BB6583AAC84D56649E8AF0CDC782EF273A23","hash UTF8 estavel da projecao com acento").
 RUN Check(repKey<>res:GetJsonArray("data"):GetJsonObject(3):GetCharacter("representante_key"),"mesmo codigo nomes diferentes tem identidades distintas").
 RUN NewReq("get"). req:Add("id",repKey). req:Add("representante_key",repKey). RUN CallService. RUN Check(res:GetJsonObject("data"):GetCharacter("nom_pessoa")="João","get representante contrato Builder").
 RUN NewReq("get"). req:Add("id",FILL("F",64)). RUN CallService. RUN Err("CIW_REFERENCIA_NOT_FOUND").
 RUN NewReq("get"). req:Add("id",2.4). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id",-1). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id","2147483648"). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id",repKey). req:Add("representante_key",FILL("0",64)). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("get"). req:Add("id",TRUE). RUN CallService. RUN Err("CIW_REFERENCIA_VALIDATION").
 RUN NewReq("read"). req:Add("table","ttRep"). RUN CallService. RUN Err("CIW_REFERENCIA_FIELD_INVALID").
 RUN NewReq("delete"). req:Add("id",2). RUN CallService. RUN Err("CIW_REFERENCIA_READ_ONLY").
 resourceName="item". RUN NewReq("read"). RUN CallService. RUN Err("CIW_REFERENCIA_RESOURCE_INVALID").
 RUN Check(CAN-FIND(FIRST ttRep WHERE cdn_repres=2),"sem escrita").
 EMPTY TEMP-TABLE ttRep. resourceName="representantes_ativos".
 RUN NewReq("read"). RUN CallService. RUN Check(res:GetJsonArray("data"):Length=0,"lista vazia").
 EMPTY TEMP-TABLE ttItem.
 PUT UNFORMATTED "PASS " n " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED "FAIL after " n " checks: " e:GetMessage(1) SKIP. IF VALID-OBJECT(res) THEN res:WriteFile("referencias-test-failure.json",TRUE). END CATCH.
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
 RUN CiwReferenciasService.p(INPUT tableHandle,INPUT resourceName,INPUT req,OUTPUT res).
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


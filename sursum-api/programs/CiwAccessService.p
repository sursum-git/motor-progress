/* Autorizacao IMA por chamada. Handles e policy sao exclusivamente privados. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phUser AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phMember AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phGrant AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poIdentity AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hu AS HANDLE NO-UNDO.
DEFINE VARIABLE hm AS HANDLE NO-UNDO.
DEFINE VARIABLE hg AS HANDLE NO-UNDO.
DEFINE VARIABLE qu AS HANDLE NO-UNDO.
DEFINE VARIABLE qm AS HANDLE NO-UNDO.
DEFINE VARIABLE qg AS HANDLE NO-UNDO.
DEFINE VARIABLE cLogin AS CHARACTER NO-UNDO.
DEFINE VARIABLE cProvider AS CHARACTER NO-UNDO.
DEFINE VARIABLE cApp AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFlag AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTypes AS CHARACTER NO-UNDO.
DEFINE VARIABLE h AS HANDLE NO-UNDO.
DEFINE VARIABLE f AS HANDLE NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE iMatches AS INTEGER NO-UNDO.
DEFINE VARIABLE lSource AS LOGICAL NO-UNDO.
DEFINE VARIABLE lAccess AS LOGICAL NO-UNDO.
DEFINE VARIABLE lAction AS LOGICAL NO-UNDO.
DEFINE VARIABLE lActive AS LOGICAL NO-UNDO.
DEFINE VARIABLE lValidAction AS LOGICAL NO-UNDO.
DEFINE VARIABLE oSources AS JsonArray NO-UNDO.
DEFINE VARIABLE oData AS JsonArray NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE oError AS JsonObject NO-UNDO.
DEFINE VARIABLE identityResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE identityService AS CHARACTER NO-UNDO.

FUNCTION Exact RETURNS LOGICAL (a AS CHARACTER,b AS CHARACTER):
 IF a=? OR b=? THEN RETURN FALSE.
 RETURN LENGTH(a,"RAW")=LENGTH(b,"RAW") AND COMPARE(a,"EQ",b,"RAW").
END FUNCTION.
FUNCTION TextValue RETURNS CHARACTER (o AS JsonObject,k AS CHARACTER):
 IF NOT VALID-OBJECT(o) THEN RETURN ?.
 IF NOT o:Has(k) THEN RETURN ?.
 IF o:GetType(k)<>JsonDataType:STRING THEN RETURN ?.
 RETURN o:GetCharacter(k).
END FUNCTION.
FUNCTION Required RETURNS LOGICAL (v AS CHARACTER):
 IF v=? THEN RETURN FALSE.
 RETURN LENGTH(TRIM(v))>0.
END FUNCTION.

DO ON ERROR UNDO, THROW:
 cLogin=TextValue(poIdentity,"login"). cProvider=TextValue(poIdentity,"auth_provider").
 IF NOT Required(cLogin) OR NOT Required(cProvider) OR NOT Required(TextValue(poIdentity,"session_id")) THEN DO:
  RUN Deny("CIW_IDENTITY_REQUIRED",401). RETURN.
 END.
 IF NOT VALID-OBJECT(poPolicy) THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
 IF NOT poPolicy:Has("allowed_auth_providers") THEN DO: RUN Deny("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
 IF poPolicy:GetType("allowed_auth_providers")<>JsonDataType:ARRAY THEN DO: RUN Deny("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
 oSources=poPolicy:GetJsonArray("allowed_auth_providers").
 DO n=1 TO oSources:Length:
  IF oSources:GetType(n)<>JsonDataType:STRING THEN DO: RUN Deny("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
  IF NOT Required(oSources:GetCharacter(n)) THEN DO: RUN Deny("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
  IF Exact(cProvider,oSources:GetCharacter(n)) THEN lSource=TRUE.
 END.
 IF NOT lSource THEN DO: RUN Deny("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
 cApp=TextValue(poPolicy,"legacy_application"). cAction=TextValue(poPolicy,"action").
 IF NOT Required(cApp) THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
 DO n=1 TO 7:
  IF Exact(cAction,ENTRY(n,"read,get,create,update,delete,export,print")) THEN lValidAction=TRUE.
 END.
 IF NOT lValidAction THEN DO: RUN Deny("CIW_ACCESS_INVALID_REQUEST",400). RETURN. END.
 CASE cAction:
  WHEN "read" THEN cFlag="".
  WHEN "get" THEN cFlag="".
  WHEN "create" THEN cFlag="insercao_permitida".
  WHEN "update" THEN cFlag="alteracao_permitida".
  WHEN "delete" THEN cFlag="exclusao_permitida".
  WHEN "export" THEN cFlag="exportacao_permitida".
  WHEN "print" THEN cFlag="impressao_permitida".
  OTHERWISE DO: RUN Deny("CIW_ACCESS_INVALID_REQUEST",400). RETURN. END.
 END CASE.
 IF cAction=? THEN DO: RUN Deny("CIW_ACCESS_INVALID_REQUEST",400). RETURN. END.
 /* Validar todos os campos antes de ler; nunca usar um nome do cliente. */
 DO j=1 TO 3:
  h=IF j=1 THEN phUser ELSE IF j=2 THEN phMember ELSE phGrant.
  IF NOT VALID-HANDLE(h) THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
  IF h:TYPE<>"BUFFER" THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
  cFields=IF j=1 THEN "Login,ativo,id,usuario,tp-usuario" ELSE IF j=2 THEN "login_usuario,cod_grupo"
   ELSE "cod_grupo,nome_aplicacao,acesso_permitido,insercao_permitida,alteracao_permitida,exclusao_permitida,exportacao_permitida,impressao_permitida".
  cTypes=IF j=1 THEN "CHARACTER,LOGICAL,INTEGER,CHARACTER,INTEGER" ELSE IF j=2 THEN "CHARACTER,INTEGER"
   ELSE "INTEGER,CHARACTER,CHARACTER,CHARACTER,CHARACTER,CHARACTER,CHARACTER,CHARACTER".
  DO n=1 TO NUM-ENTRIES(cFields):
   f=h:BUFFER-FIELD(ENTRY(n,cFields)) NO-ERROR.
   IF NOT VALID-HANDLE(f) THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
   IF f:DATA-TYPE<>ENTRY(n,cTypes) OR f:EXTENT<>0 THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
  END.
 END.
 identityService=SEARCH("sursum-api/programs/CiwIdentityService.r").
 IF identityService=? THEN identityService=SEARCH("CiwIdentityService.p").
 IF identityService=? THEN DO: RUN Deny("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
 RUN VALUE(identityService)(INPUT phUser,INPUT poIdentity,INPUT poPolicy,OUTPUT identityResponse).
 IF NOT identityResponse:GetLogical("success") THEN DO:
  poResponse=identityResponse. identityResponse=?. RETURN.
 END.
 oRow=CAST(identityResponse:GetJsonArray("data"):GetJsonObject(1):Clone(),JsonObject).
 CREATE BUFFER hm FOR TABLE phMember.
 CREATE BUFFER hg FOR TABLE phGrant.
 CREATE QUERY qm. qm:SET-BUFFERS(hm).
 qm:QUERY-PREPARE("FOR EACH " + hm:NAME + " WHERE CAPS(login_usuario) = " + QUOTER(CAPS(cLogin)) + " NO-LOCK").
 qm:QUERY-OPEN(). qm:GET-FIRST(NO-LOCK).
 CREATE QUERY qg. qg:SET-BUFFERS(hg).
 DO WHILE NOT qm:QUERY-OFF-END:
  IF Exact(CAPS(hm:BUFFER-FIELD("login_usuario"):BUFFER-VALUE),CAPS(cLogin)) AND hm:BUFFER-FIELD("cod_grupo"):BUFFER-VALUE<>? THEN DO:
   qg:QUERY-PREPARE("FOR EACH " + hg:NAME + " WHERE cod_grupo = " + STRING(hm:BUFFER-FIELD("cod_grupo"):BUFFER-VALUE,"->>>>>>>>>9") + " NO-LOCK").
   qg:QUERY-OPEN(). qg:GET-FIRST(NO-LOCK).
   DO WHILE NOT qg:QUERY-OFF-END:
    IF Exact(hg:BUFFER-FIELD("nome_aplicacao"):BUFFER-VALUE,cApp) THEN DO:
     IF Exact(hg:BUFFER-FIELD("acesso_permitido"):BUFFER-VALUE,"Y") THEN lAccess=TRUE.
     IF cFlag<>"" THEN IF Exact(hg:BUFFER-FIELD(cFlag):BUFFER-VALUE,"Y") THEN lAction=TRUE.
    END.
    qg:GET-NEXT(NO-LOCK).
   END.
   qg:QUERY-CLOSE().
  END.
  qm:GET-NEXT(NO-LOCK).
 END.
 IF NOT lAccess OR (cFlag<>"" AND NOT lAction) THEN DO: RUN Deny("CIW_ACCESS_DENIED",403). RETURN. END.
 oRow:Add("legacy_application",cApp). oRow:Add("action",cAction). oRow:Add("allowed",TRUE).
 oData=NEW JsonArray(). oData:Add(oRow).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",oData).
 CATCH e AS Progress.Lang.Error:
  RUN Deny("CIW_ACCESS_CONFIGURATION",500).
 END CATCH.
 FINALLY:
  IF VALID-OBJECT(identityResponse) THEN DELETE OBJECT identityResponse.
  IF VALID-HANDLE(qu) THEN DELETE OBJECT qu.
  IF VALID-HANDLE(qm) THEN DELETE OBJECT qm.
  IF VALID-HANDLE(qg) THEN DELETE OBJECT qg.
  IF VALID-HANDLE(hu) THEN DELETE OBJECT hu.
  IF VALID-HANDLE(hm) THEN DELETE OBJECT hm.
  IF VALID-HANDLE(hg) THEN DELETE OBJECT hg.
  /* JSON filho pertence ao envelope de saida; nao apagar sucesso. */
  IF VALID-OBJECT(oRow) AND NOT VALID-OBJECT(oData) THEN DELETE OBJECT oRow.
 END FINALLY.
END.
PROCEDURE AddAttribute:
 DEFINE INPUT PARAMETER k AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER hf AS HANDLE NO-UNDO.
 IF hf:BUFFER-VALUE=? THEN oRow:AddNull(k).
 ELSE IF hf:DATA-TYPE="INTEGER" THEN oRow:Add(k,INTEGER(hf:BUFFER-VALUE)).
 ELSE oRow:Add(k,STRING(hf:BUFFER-VALUE)).
END PROCEDURE.
PROCEDURE Deny:
 DEFINE INPUT PARAMETER cCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER iStatus AS INTEGER NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 oError=NEW JsonObject(). oError:Add("code",cCode). oError:Add("status",iStatus).
 oError:Add("message","Solicitacao nao autorizada ou configuracao indisponivel.").
 poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). poResponse:Add("error",oError).
END PROCEDURE.

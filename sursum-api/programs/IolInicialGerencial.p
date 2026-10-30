/* Authenticated readonly IOL dashboard entry. No identity from body and no business writes. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLogin AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTables AS CHARACTER NO-UNDO INITIAL "espec.user-web,espec.usuarios_grupos,ems2cad.repres,espec.cm-hierarquia,espec.cm-ext-repres,espec.fats_repres,espec.transacoes,espec.metas_repres,espec.metas_gerencial,espec.metas_geral,espec.peds_web,ems2med.ped-venda,ems2med.ped-repre,ems2med.nota-fiscal,ems2med.natur-oper,ems2med.devol-cli,ems2med.docum-est,ems5.dia_calend_glob,espec.restrs_clientes_usuario,espec.repres_restr_cliente_usuario".
DEFINE VARIABLE cError AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEngine AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAggregateProgram AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE namesArray AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE configData AS JsonObject NO-UNDO.
DEFINE VARIABLE scopeData AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DEFINE VARIABLE resultData AS JsonObject NO-UNDO.
DEFINE VARIABLE phSources AS HANDLE EXTENT 20 NO-UNDO.
{sursum-api/includes/parametros_ima.i}
DO ON ERROR UNDO, THROW:
 cToken=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_IOL_GERENCIAL_TOKEN") NO-ERROR.
 IF cToken=? THEN cToken="".
 IF LENGTH(cToken)<32 OR LENGTH(cToken)>128 THEN DO: RUN Fail("IOL_AUTH_REQUIRED",401). RETURN. END.
 cConfig=SEARCH("sursum-conf/iol-gerencial-api.json").
 IF cConfig=? THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_CONFIGURATION",1).
 parser=NEW ObjectModelParser(). configData=CAST(parser:ParseFile(cConfig),JsonObject).
 IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cToken)))<>CAPS(configData:GetCharacter("tokenSha256")) THEN DO:
  RUN Fail("IOL_AUTH_REQUIRED",401). RETURN.
 END.
 /* Integration secret is server-side. This header is rebuilt by RuntimeExternalJsonClient from the active session. */
 cLogin=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_SURSUM_USER") NO-ERROR.
 IF cLogin=? OR cLogin="" THEN DO: RUN Fail("IOL_IDENTITY_REQUIRED",403). RETURN. END.
 namesArray=poRequest:GetNames().
 DO i=1 TO EXTENT(namesArray):
  IF LOOKUP(namesArray[i],"operation,resource")=0 THEN DO: RUN Fail("IOL_REQUEST_INVALID",422). RETURN. END.
 END.
 IF NOT poRequest:Has("operation") OR NOT poRequest:Has("resource") THEN DO: RUN Fail("IOL_REQUEST_INVALID",422). RETURN. END.
 IF poRequest:GetType("operation")<>JsonDataType:STRING OR poRequest:GetType("resource")<>JsonDataType:STRING THEN DO: RUN Fail("IOL_REQUEST_INVALID",422). RETURN. END.
 IF poRequest:GetCharacter("operation")<>"read" THEN DO: RUN Fail("IOL_READ_ONLY",405). RETURN. END.
 cResource=poRequest:GetCharacter("resource").
 IF LOOKUP(cResource,"resumo,vendedores,painel")=0 THEN DO: RUN Fail("IOL_RESOURCE_INVALID",422). RETURN. END.
 DO i=1 TO 20:
  CREATE BUFFER phSources[i] FOR TABLE ENTRY(i,cTables) BUFFER-NAME ("bIol" + STRING(i)).
 END.
 RUN VALUE(SEARCH("sursum-api/programs/iol-gerencial-20261019-v5/IolGerencialIdentityService.r"))(cLogin,phSources,OUTPUT scopeData).
 scopeData:Add("calendar_code",buscarParametroIma("calend_global","fiscal")).
 cAggregateProgram=SEARCH("sursum-api/programs/iol-gerencial-20261019-v5/IolGerencialAggregate128.r").
 RUN VALUE(SEARCH("sursum-api/programs/iol-gerencial-20261019-v5/IolGerencialEnginePolicy.r"))
  (buscarParametroIma("iol_gerencial_engine","12.2"),PROVERSION,DBRESTRICTIONS("espec"),cAggregateProgram<>?,OUTPUT cEngine).
 IF cEngine="12.8" THEN scopeData:Add("_aggregate_program",cAggregateProgram).
 LOG-MANAGER:WRITE-MESSAGE("engine=" + cEngine + " runtime=" + PROVERSION,"IOL_ENGINE").
 RUN VALUE(SEARCH("sursum-api/programs/iol-gerencial-20261019-v5/IolGerencialCollector.r"))(scopeData,TODAY,phSources,OUTPUT snapshotData).
 RUN VALUE(SEARCH("sursum-api/programs/iol-gerencial-20261019-v5/IolGerencialCalculator.r"))(snapshotData,OUTPUT resultData).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE).
 IF cResource="painel" THEN poResponse:Add("data",resultData).
 ELSE poResponse:Add("data",resultData:GetJsonArray(cResource)).
 CATCH e AS Progress.Lang.Error:
  cError=e:GetMessage(1).
  CASE cError:
   WHEN "IOL_IDENTITY_REQUIRED" OR WHEN "IOL_IDENTITY_INVALID" OR WHEN "IOL_IDENTITY_INACTIVE" OR WHEN "IOL_FORBIDDEN" THEN RUN Fail(cError,403).
   WHEN "IOL_HIERARCHY_INVALID" OR WHEN "IOL_CALENDAR_INVALID" OR WHEN "IOL_DATA_INVALID" OR WHEN "IOL_DISCOUNT_INVALID" THEN RUN Fail(cError,422).
   WHEN "IOL_ENGINE_INVALID" OR WHEN "IOL_ENGINE_UNAVAILABLE" THEN RUN Fail(cError,503).
   OTHERWISE RUN Fail("IOL_CONFIGURATION",500).
  END CASE.
 END CATCH.
 FINALLY:
  DO i=1 TO 20: IF VALID-HANDLE(phSources[i]) THEN DELETE OBJECT phSources[i] NO-ERROR. END.
  IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
  IF VALID-OBJECT(configData) THEN DELETE OBJECT configData.
  IF VALID-OBJECT(scopeData) THEN DELETE OBJECT scopeData.
  IF VALID-OBJECT(snapshotData) THEN DELETE OBJECT snapshotData.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE errorData AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorData=NEW JsonObject().
 errorData:Add("code",codeValue). errorData:Add("status",statusValue).
 errorData:Add("message",IF statusValue=503 THEN "Motor IOL configurado invalido ou indisponivel. Verifique iol_gerencial_engine e a migracao do Progress." ELSE IF statusValue=403 THEN "Usuario sem acesso ao painel IMA." ELSE IF statusValue=401 THEN "Credencial de integracao invalida." ELSE IF statusValue=500 THEN "Painel gerencial indisponivel. Verifique a integracao." ELSE "Nao foi possivel consultar os indicadores com a configuracao atual.").
 poResponse:Add("success",FALSE). poResponse:Add("error",errorData).
END PROCEDURE.

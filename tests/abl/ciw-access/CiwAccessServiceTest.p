/* Testes apenas em temp-tables; nenhum usuario/grupo de negocio e alterado. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttUser
    FIELD Login AS CHARACTER FIELD ativo AS LOGICAL FIELD id AS INTEGER
    FIELD usuario AS CHARACTER FIELD tp-usuario AS INTEGER.
DEFINE TEMP-TABLE ttMember
    FIELD login_usuario AS CHARACTER FIELD cod_grupo AS INTEGER.
DEFINE TEMP-TABLE ttGrant
    FIELD cod_grupo AS INTEGER FIELD nome_aplicacao AS CHARACTER
    FIELD acesso_permitido AS CHARACTER FIELD insercao_permitida AS CHARACTER
    FIELD alteracao_permitida AS CHARACTER FIELD exclusao_permitida AS CHARACTER
    FIELD exportacao_permitida AS CHARACTER FIELD impressao_permitida AS CHARACTER.
DEFINE VARIABLE identity AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE providers AS JsonArray NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE passed AS INTEGER NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLog AS CHARACTER NO-UNDO.

cLog = "ciw-access-tests-" + SESSION:NUMERIC-FORMAT + ".log".
OUTPUT TO VALUE(cLog).
DO ON ERROR UNDO, THROW:
    cService = SEARCH("CiwAccessService.p").
    RUN Check(cService <> ?, "CiwAccessService ainda nao implementado").

    RUN ResetFixture.
    RUN ExecuteService.
    RUN ExpectSuccess.
    rowData = response:GetJsonArray("data"):GetJsonObject(1).
    RUN Check(rowData:GetCharacter("login") = "CIW_TEST_USER", "login IMA retornado").
    RUN Check(rowData:GetInteger("ima_user_id") = 101, "id legado nao e PG").
    RUN Check(rowData:GetCharacter("legacy_application") = "grid_pub_coloracoes", "aplicacao registrada").
    RUN Check(NOT rowData:Has("senha") AND NOT rowData:Has("email"), "nenhum dado desnecessario").

    RUN ResetFixture. identity:Remove("login"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_REQUIRED",401).
    RUN ResetFixture. identity:Remove("session_id"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_REQUIRED",401).
    RUN ResetFixture. identity:Remove("auth_provider"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_REQUIRED",401).
    RUN ResetFixture. identity:Set("auth_provider","local"). RUN ExecuteService. RUN ExpectError("CIW_AUTH_SOURCE_DENIED",403).
    RUN ResetFixture. providers=NEW JsonArray(). policy:Set("allowed_auth_providers",providers).
    RUN ExecuteService. RUN ExpectError("CIW_AUTH_SOURCE_DENIED",403).
    RUN ResetFixture. identity:Set("login","UNKNOWN_TEST_USER"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_NOT_LINKED",403).
    RUN ResetFixture. FIND FIRST ttUser. ttUser.ativo=FALSE. RELEASE ttUser.
    RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_INACTIVE",403).
    RUN ResetFixture. FIND FIRST ttUser. ttUser.ativo=?. RELEASE ttUser.
    RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_INACTIVE",403).
    RUN ResetFixture.
    CREATE ttUser. ASSIGN ttUser.Login="ciw_test_user" ttUser.ativo=TRUE ttUser.id=102. RELEASE ttUser.
    RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_AMBIGUOUS",409).

    RUN ResetFixture. FOR EACH ttMember: DELETE ttMember. END.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN ResetFixture. FOR EACH ttGrant: DELETE ttGrant. END.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN ResetFixture. FIND FIRST ttMember. ttMember.login_usuario="OTHER_TEST_USER". RELEASE ttMember.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN ResetFixture. FIND FIRST ttGrant. ttGrant.nome_aplicacao="other_app". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN ResetFixture. FIND FIRST ttGrant. ttGrant.nome_aplicacao="GRID_PUB_COLORACOES". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN ResetFixture. FIND FIRST ttGrant. ttGrant.acesso_permitido="y". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN ResetFixture. FIND FIRST ttGrant. ttGrant.acesso_permitido=?. RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).

    RUN ResetFixture. policy:Set("legacy_application","form_pub_coloracoes"). policy:Set("action","create").
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN AddGrant(1,"form_pub_coloracoes","Y","N","N","N","N","N").
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    FIND FIRST ttGrant WHERE ttGrant.nome_aplicacao="form_pub_coloracoes".
    ttGrant.insercao_permitida="Y". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectSuccess.
    policy:Set("action","update"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    FIND FIRST ttGrant WHERE ttGrant.nome_aplicacao="form_pub_coloracoes".
    ttGrant.alteracao_permitida="Y". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectSuccess.
    policy:Set("action","delete"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    FIND FIRST ttGrant WHERE ttGrant.nome_aplicacao="form_pub_coloracoes".
    ttGrant.exclusao_permitida="Y". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectSuccess.
    policy:Set("action","get"). RUN ExecuteService. RUN ExpectSuccess.

    RUN ResetFixture. policy:Set("action","export"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    FIND FIRST ttGrant. ttGrant.exportacao_permitida="Y". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectSuccess.
    policy:Set("action","print"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    FIND FIRST ttGrant. ttGrant.impressao_permitida="Y". RELEASE ttGrant.
    RUN ExecuteService. RUN ExpectSuccess.

    RUN ResetFixture. policy:Set("action","create"). policy:Set("legacy_application","form_pub_coloracoes").
    RUN AddGrant(1,"form_pub_coloracoes","Y","N","N","N","N","N").
    CREATE ttMember. ASSIGN ttMember.login_usuario="CIW_TEST_USER" ttMember.cod_grupo=2. RELEASE ttMember.
    RUN AddGrant(2,"form_pub_coloracoes","N","Y","N","N","N","N").
    RUN ExecuteService. RUN ExpectSuccess.
    FOR EACH ttMember WHERE ttMember.cod_grupo=2: DELETE ttMember. END.
    RUN ExecuteService. RUN ExpectError("CIW_ACCESS_DENIED",403).
    RUN Check(CAN-FIND(ttGrant WHERE ttGrant.cod_grupo=2),"nenhum grant apagado pelo servico").
    RUN Check(CAN-FIND(ttUser WHERE ttUser.id=101),"usuario preservado pelo servico").

    RUN ResetFixture. policy:Set("action","unknown"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_INVALID_REQUEST",400).
    RUN ResetFixture. policy:Remove("legacy_application"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_CONFIGURATION",500).
    RUN ResetFixture. identity:Set("login","ciw_test_user"). RUN ExecuteService. RUN ExpectSuccess.
    RUN ResetFixture. policy:Set("action","READ"). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_INVALID_REQUEST",400).
    RUN ResetFixture. policy:Set("action","read "). RUN ExecuteService. RUN ExpectError("CIW_ACCESS_INVALID_REQUEST",400).
    RUN ResetFixture. FIND FIRST ttUser. ASSIGN ttUser.id=? ttUser.usuario=? ttUser.tp-usuario=?. RELEASE ttUser.
    RUN ExecuteService. RUN ExpectSuccess.
    rowData=response:GetJsonArray("data"):GetJsonObject(1).
    RUN Check(rowData:IsNull("ima_user_id") AND rowData:IsNull("usuario") AND rowData:IsNull("tp_usuario"),"atributos desconhecidos sao null").
    PUT UNFORMATTED "PASS " passed " checks " SESSION:NUMERIC-FORMAT SKIP.
    CATCH e AS Progress.Lang.Error:
        PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(response) THEN DELETE OBJECT response.
        IF VALID-OBJECT(identity) THEN DELETE OBJECT identity.
        IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
        IF VALID-OBJECT(providers) THEN DELETE OBJECT providers.
    END FINALLY.
END.
OUTPUT CLOSE.

PROCEDURE ResetFixture:
    FOR EACH ttUser: DELETE ttUser. END.
    FOR EACH ttMember: DELETE ttMember. END.
    FOR EACH ttGrant: DELETE ttGrant. END.
    IF VALID-OBJECT(identity) THEN DELETE OBJECT identity.
    IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
    IF VALID-OBJECT(providers) THEN DELETE OBJECT providers.
    identity=NEW JsonObject(). policy=NEW JsonObject(). providers=NEW JsonArray().
    identity:Add("login","CIW_TEST_USER"). identity:Add("session_id","CIW_TEST_SESSION").
    identity:Add("auth_provider","ima-ldap"). providers:Add("ima-ldap").
    policy:Add("allowed_auth_providers",providers).
    policy:Add("legacy_application","grid_pub_coloracoes"). policy:Add("action","read").
    CREATE ttUser. ASSIGN ttUser.Login="CIW_TEST_USER" ttUser.ativo=TRUE ttUser.id=101
        ttUser.usuario="CIW_TEST_ERP" ttUser.tp-usuario=2. RELEASE ttUser.
    CREATE ttMember. ASSIGN ttMember.login_usuario="CIW_TEST_USER" ttMember.cod_grupo=1. RELEASE ttMember.
    RUN AddGrant(1,"grid_pub_coloracoes","Y","N","N","N","N","N").
END PROCEDURE.

PROCEDURE AddGrant:
    DEFINE INPUT PARAMETER grp AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER app AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER accessFlag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER insertFlag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER updateFlag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER deleteFlag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER exportFlag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER printFlag AS CHARACTER NO-UNDO.
    CREATE ttGrant.
    ASSIGN ttGrant.cod_grupo=grp ttGrant.nome_aplicacao=app
        ttGrant.acesso_permitido=accessFlag ttGrant.insercao_permitida=insertFlag
        ttGrant.alteracao_permitida=updateFlag ttGrant.exclusao_permitida=deleteFlag
        ttGrant.exportacao_permitida=exportFlag ttGrant.impressao_permitida=printFlag.
    RELEASE ttGrant.
END PROCEDURE.

PROCEDURE ExecuteService:
    IF VALID-OBJECT(response) THEN DELETE OBJECT response.
    RUN VALUE(cService)(INPUT BUFFER ttUser:HANDLE,INPUT BUFFER ttMember:HANDLE,
        INPUT BUFFER ttGrant:HANDLE,INPUT identity,INPUT policy,OUTPUT response).
END PROCEDURE.
PROCEDURE ExpectSuccess:
    RUN Check(VALID-OBJECT(response),"resposta presente").
    RUN Check(response:GetLogical("success"),"sucesso esperado").
    RUN Check(response:GetJsonArray("data"):Length=1,"uma identidade autorizada").
    rowData=response:GetJsonArray("data"):GetJsonObject(1).
    RUN Check(rowData:GetLogical("allowed"),"acao autorizada explicitamente").
END PROCEDURE.
PROCEDURE ExpectError:
    DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
    RUN Check(VALID-OBJECT(response),"resposta de erro presente").
    RUN Check(NOT response:GetLogical("success"),"falha esperada").
    RUN Check(response:GetJsonObject("error"):GetCharacter("code")=code,"codigo " + code).
    RUN Check(response:GetJsonObject("error"):GetInteger("status")=statusCode,"status de erro correto").
END PROCEDURE.
PROCEDURE Check:
    DEFINE INPUT PARAMETER condition AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER description AS CHARACTER NO-UNDO.
    IF condition = ? OR NOT condition THEN UNDO, THROW NEW Progress.Lang.AppError(description,0).
    passed = passed + 1.
END PROCEDURE.

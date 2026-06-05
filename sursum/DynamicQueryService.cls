/*
Fachada OO de compatibilidade para chamadas simples.
Consultas sao encaminhadas ao motor OO atual.
*/

USING Progress.Json.ObjectModel.JsonObject.

CLASS DynamicQueryService:

    DEFINE PRIVATE VARIABLE oMultiService AS DynamicMultiTableQueryService NO-UNDO.
    DEFINE PRIVATE VARIABLE cTabela AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cCampos AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cCondicao AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cInner AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cBanco AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cComando AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE joResultado AS JsonObject NO-UNDO.

    CONSTRUCTOR PUBLIC DynamicQueryService():
        ASSIGN oMultiService = NEW DynamicMultiTableQueryService().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC DynamicQueryService():
        IF VALID-OBJECT(oMultiService) THEN
            DELETE OBJECT oMultiService.
        IF VALID-OBJECT(joResultado) THEN
            DELETE OBJECT joResultado.
    END DESTRUCTOR.

    METHOD PUBLIC VOID iniciarBos():
    END METHOD.

    METHOD PUBLIC VOID finalizarBos():
    END METHOD.

    METHOD PUBLIC VOID limparTTs():
        ASSIGN cTabela = ""
               cCampos = ""
               cCondicao = ""
               cInner = ""
               cComando = "".
        IF VALID-OBJECT(joResultado) THEN
            DELETE OBJECT joResultado.
        ASSIGN joResultado = ?.
    END METHOD.

    METHOD PUBLIC VOID setDadosConsulta(
        INPUT pcTabelas  AS CHARACTER,
        INPUT pcCampos   AS CHARACTER,
        INPUT pcCondicao AS CHARACTER,
        INPUT pcInner    AS CHARACTER):

        ASSIGN cTabela   = pcTabelas
               cCampos   = pcCampos
               cCondicao = pcCondicao
               cInner    = pcInner.
    END METHOD.

    METHOD PUBLIC VOID execConsulta(INPUT pcTipoRetorno AS CHARACTER):
        IF NUM-ENTRIES(cTabela) > 1 THEN DO:
            ASSIGN joResultado = THIS-OBJECT:buildError(
                "UNSUPPORTED_LEGACY_CALL",
                "DynamicQueryService aceita apenas uma tabela. Use DynamicMultiTableQueryService para multi-tabela.",
                cTabela
            ).
            RETURN.
        END.

        IF cCondicao <> "" OR cInner <> "" THEN DO:
            ASSIGN joResultado = THIS-OBJECT:buildError(
                "UNSUPPORTED_LEGACY_CALL",
                "Condicao textual e inner textual nao sao aceitos no motor OO.",
                "Use DynamicQueryRequestModel com filters e joins estruturados."
            ).
            RETURN.
        END.

        ASSIGN cComando = "DynamicMultiTableQueryService.executeSingleTable".
        ASSIGN joResultado = oMultiService:executeSingleTable(cTabela, cCampos, cBanco, 1, 500, "sync").
    END METHOD.

    METHOD PUBLIC CHARACTER getComando():
        RETURN cComando.
    END METHOD.

    METHOD PUBLIC HANDLE getResultado():
        RETURN ?.
    END METHOD.

    METHOD PUBLIC JsonObject getResultadoJson():
        IF NOT VALID-OBJECT(joResultado) THEN
            ASSIGN joResultado = THIS-OBJECT:buildError("NO_RESULT", "Consulta ainda nao executada.", "").
        RETURN joResultado.
    END METHOD.

    METHOD PUBLIC VOID setNomeArqCsv(INPUT pcArqCsv AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID setArqInsertSqlite(INPUT pcArqSqlite AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID setListaCamposTabela(
        INPUT pcTabela AS CHARACTER,
        INPUT pcCampos AS CHARACTER):

        ASSIGN cTabela = pcTabela
               cCampos = pcCampos.
    END METHOD.

    METHOD PUBLIC VOID setCondicaoTabela(
        INPUT pcTabela  AS CHARACTER,
        INPUT pcCondicao AS CHARACTER):

        ASSIGN cTabela = pcTabela
               cCondicao = pcCondicao.
    END METHOD.

    METHOD PUBLIC VOID setBancoTabela(
        INPUT pcTabela  AS CHARACTER,
        INPUT pcBanco   AS CHARACTER):

        ASSIGN cTabela = pcTabela
               cBanco = pcBanco.
    END METHOD.

    METHOD PUBLIC CHARACTER getComandoAtual():
        RETURN THIS-OBJECT:getComando().
    END METHOD.

    METHOD PUBLIC JsonObject executarEObterJson(
        INPUT pcTabelas  AS CHARACTER,
        INPUT pcCampos   AS CHARACTER,
        INPUT pcCondicao AS CHARACTER,
        INPUT pcInner    AS CHARACTER):

        THIS-OBJECT:limparTTs().
        THIS-OBJECT:setDadosConsulta(pcTabelas, pcCampos, pcCondicao, pcInner).
        THIS-OBJECT:execConsulta("json").
        RETURN THIS-OBJECT:getResultadoJson().
    END METHOD.

    METHOD PUBLIC HANDLE executarEObterHandle(
        INPUT pcTabelas  AS CHARACTER,
        INPUT pcCampos   AS CHARACTER,
        INPUT pcCondicao AS CHARACTER,
        INPUT pcInner    AS CHARACTER):

        RETURN ?.
    END METHOD.

    METHOD PRIVATE JsonObject buildError(
        INPUT pcCode AS CHARACTER,
        INPUT pcMessage AS CHARACTER,
        INPUT pcDetails AS CHARACTER):

        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               joErr = NEW JsonObject().
        joErr:Add("code", pcCode).
        joErr:Add("message", pcMessage).
        joErr:Add("details", pcDetails).
        joRet:Add("success", FALSE).
        joRet:Add("error", joErr).
        RETURN joRet.
    END METHOD.

END CLASS.

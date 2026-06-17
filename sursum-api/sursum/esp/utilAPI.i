{utp/ut-api.i}

DEFINE TEMP-TABLE ttRetorno
    FIELD codigo    AS INT
    FIELD descricao AS CHAR .

{esp/ttChave.i}


DEFINE VARIABLE jObIn AS JsonObject  NO-UNDO .


{esbo/boMsg.i}
             
PROCEDURE setJsonInput:
  
  DEFINE INPUT  PARAMETER pji AS jsonObject   NO-UNDO.
  ASSIGN jObIn = pji .


END PROCEDURE.

PROCEDURE getQueryParam:
    DEFINE INPUT  PARAMETER parametro   AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cValor      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE oRequestParser      AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oQueryParams        AS JsonObject NO-UNDO.
    oRequestParser = NEW JsonAPIRequestParser(jObIn).
    oQueryParams = oRequestParser:getQueryParams().
    ASSIGN cValor = JsonAPIUtils:getPropertyJsonObject(oQueryParams, parametro).

    

END PROCEDURE.

PROCEDURE getPayLoad: // corpo da mensagem
    DEFINE OUTPUT PARAMETER corpo      AS jsonObject   NO-UNDO.
    DEFINE VARIABLE oRequestParser      AS JsonAPIRequestParser NO-UNDO.
    oRequestParser = NEW JsonAPIRequestParser(JsonInput).
    corpo = oRequestParser:getPayLoad().
END PROCEDURE.


PROCEDURE criarTTRetorno:
    DEFINE INPUT  PARAMETER pDescricao   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCodigo      AS INTEGER     NO-UNDO.
    CREATE ttRetorno.
    ASSIGN ttRetorno.codigo     = pCodigo
           ttRetorno.descricao  = pDescricao.


END PROCEDURE.

PROCEDURE criarTTChave:
    DEFINE INPUT  PARAMETER pChave   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pValor   AS CHARACTER   NO-UNDO.
    CREATE ttChave.
    ASSIGN ttchave.chave        = pChave
           ttChave.valor        = pvalor.


END PROCEDURE.




PROCEDURE retJsontt:
    DEFINE INPUT-OUTPUT PARAM jsonOutput    AS JsonObject NO-UNDO.
    DEFINE INPUT  PARAMETER  handleTT       AS HANDLE      NO-UNDO.
    DEFINE VARIABLE aJsonArray              AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oJsonObject             AS JsonObject NO-UNDO.

    ASSIGN aJsonArray = NEW JsonArray().
    ASSIGN oJsonObject = NEW jsonObject().
    ASSIGN oJsonObject = JsonAPIUtils:convertTempTableToJsonObject(handleTT).
    aJsonArray:ADD(oJsonObject).
    ASSIGN jsonOutput = JsonAPIResponseBuilder:ok(aJsonArray, false).



END PROCEDURE.



PROCEDURE retJsontt2:
    DEFINE INPUT-OUTPUT PARAM jsonOutput        AS JsonObject NO-UNDO.
    DEFINE INPUT  PARAMETER   handleTT          AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER   pTipoRetorno      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER   pCodigo           AS INTEGER     NO-UNDO.
    DEFINE VARIABLE aJsonArray                  AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oJsonObject                 AS JsonObject NO-UNDO.

    ASSIGN aJsonArray = NEW JsonArray().
    ASSIGN oJsonObject = NEW jsonObject().
    ASSIGN oJsonObject = JsonAPIUtils:convertTempTableToJsonObject(handleTT).
    aJsonArray:ADD(oJsonObject).
    aJsonArray:writeFile('c:\temp\jsonRetJsonTT2_' + STRING(TIME) + '.txt').
    
    CASE pTipoRetorno:
        WHEN 'ok' THEN DO:
            ASSIGN jsonOutput = JsonAPIResponseBuilder:ok(aJsonArray, false).
        END.
        WHEN 'aviso' THEN DO:
           ASSIGN jsonOutput = JsonAPIResponseBuilder:asWARNING(aJsonArray:getJsonObject(1),handleTT ).
        END.
        WHEN 'erro' THEN DO:
           //ASSIGN jsonOutput = JsonAPIResponseBuilder:asError(aJsonArray, pCodigo).
            jsonOutput:ADD('status',pCodigo).
            jsonOutput:ADD('payload',oJsonObject).

        END.
        WHEN 'vazio' THEN DO:
           ASSIGN jsonOutput = JsonAPIResponseBuilder:EMPTY(pCodigo).
        END.

    END CASE.
    jsonOutput:writeFile('c:\temp\jsonOUTPUTRetJsonTT2_' + STRING(TIME) + '.txt').

END PROCEDURE.


PROCEDURE convTtChave2TTError:


//{method/dbotterr.i}


END PROCEDURE.

PROCEDURE inserirMsgTTRet:
    DEFINE INPUT  PARAMETER pHandle AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER cTipo   AS CHARACTER   NO-UNDO.
    RUN getTTMsg IN pHandle(cTipo,OUTPUT TABLE ttMsg).
    FOR EACH ttMsg:
         RUN criarTTRetorno(ttMsg.tipo  + '-' +  ttMsg.descricao ,ttMsg.cod ).  
    END.



END PROCEDURE.





PROCEDURE convJson2Char:
    // necess rio que o programa que utilizara este procedimento tenha definid USING Progress.Json.ObjectModel.*.
    DEFINE INPUT  PARAMETER pJson AS jsonobject   NO-UNDO.
    DEFINE OUTPUT PARAMETER cJson AS CHARACTER    NO-UNDO.
    DEFINE VARIABLE lcJson        AS LONGCHAR      NO-UNDO.

    ASSIGN lcJson   = pJson:GetJsonText()
           cJson    = lcJson .


END PROCEDURE.

PROCEDURE convJson2LongChar:
    // necess rio que o programa que utilizara este procedimento tenha definid USING Progress.Json.ObjectModel.*.
    DEFINE INPUT  PARAMETER pJson  AS jsonObject   NO-UNDO.
    DEFINE OUTPUT PARAMETER lcJson AS LONGCHAR     NO-UNDO.
    

    ASSIGN lcJson   = pJson:GetJsonText()
            .


END PROCEDURE.



PROCEDURE saveJson2File:
    // necess rio que o programa que utilizara este procedimento tenha definid USING Progress.Json.ObjectModel.*.
    DEFINE INPUT PARAMETER pjson        AS jsonobject   NO-UNDO.
    DEFINE INPUT  PARAMETER pArquivo    AS CHARACTER   NO-UNDO.

    pJson:writeFile(pArquivo).




END PROCEDURE.

PROCEDURE convFileJson2JsonObject:
//converte um arquivo json  em um objeto json.
DEFINE INPUT  PARAMETER pArquivo AS CHARACTER    NO-UNDO.
DEFINE OUTPUT PARAMETER obj      AS jsonobject   NO-UNDO.

DEFINE VARIABLE oParser      AS ObjectModelParser NO-UNDO.
oParser = NEW ObjectModelParser().
obj = CAST(oParser:ParseFile(pArquivo), JsonObject). 


END PROCEDURE.



PROCEDURE convLongChar2JsonObject:

    DEFINE INPUT  PARAMETER pLc      AS LONGCHAR     NO-UNDO.
    DEFINE OUTPUT PARAMETER obj      AS jsonobject   NO-UNDO.

    DEFINE VARIABLE oParser      AS ObjectModelParser NO-UNDO.
    oParser = NEW ObjectModelParser().
    ASSIGN pLc  = CODEPAGE-CONVERT(pLc, "UTF-8":U)
           obj  = CAST(oParser:Parse(pLc), JsonObject).

END PROCEDURE.

PROCEDURE convLongChar2File:

    DEFINE INPUT  PARAMETER pLc         AS LONGCHAR   NO-UNDO.
    DEFINE INPUT  PARAMETER cArquivo    AS CHARACTER   NO-UNDO.
    

    COPY-LOB plc TO FILE cArquivo.


END PROCEDURE.

PROCEDURE convFileToJson:
    DEFINE INPUT  PARAMETER cArquivo    AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER oJsonObject AS jsonObject  NO-UNDO.

    DEFINE VARIABLE oParser      AS ObjectModelParser NO-UNDO.

     IF SEARCH(cArquivo) <> ? THEN DO:
        oParser        = NEW ObjectModelParser().
        oJsonObject    = NEW jsonObject().
        oJsonObject    = CAST(oParser:ParseFile(cArquivo), JsonObject).
     END.
     

END PROCEDURE.


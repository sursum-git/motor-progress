USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.ObjectModelParser.

DEFINE INPUT  PARAMETER poRequest  AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE oModel  AS JsonConstruct    NO-UNDO.
DEFINE VARIABLE joRoot  AS JsonObject        NO-UNDO.
DEFINE VARIABLE jaRows  AS JsonArray         NO-UNDO.
DEFINE VARIABLE lcJson  AS LONGCHAR          NO-UNDO.
DEFINE VARIABLE cJson   AS CHARACTER         NO-UNDO.
DEFINE VARIABLE iSeq    AS INTEGER           NO-UNDO.
DEFINE VARIABLE cTargetCodepage AS CHARACTER NO-UNDO INITIAL "ISO8859-1".
DEFINE VARIABLE lEscapeUnicodeOutput AS LOGICAL NO-UNDO.

FUNCTION sanitizarJsonUnicodeIso RETURNS CHARACTER (INPUT pcJson AS CHARACTER) FORWARD.

DEFINE TEMP-TABLE ttJsonTag NO-UNDO
    FIELD id       AS INTEGER
    FIELD parentId AS INTEGER
    FIELD nivel    AS INTEGER
    FIELD nome     AS CHARACTER
    FIELD caminho  AS CHARACTER
    FIELD tipo     AS CHARACTER
    FIELD indice   AS INTEGER
    FIELD valor    AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE id
    INDEX idxCaminho caminho.

ASSIGN poResponse = NEW JsonObject().

DO ON ERROR UNDO, LEAVE:
    IF VALID-OBJECT(poRequest) AND poRequest:Has("jsonText") AND NOT poRequest:IsNull("jsonText") THEN
        ASSIGN lcJson = poRequest:GetLongchar("jsonText") NO-ERROR.
    IF VALID-OBJECT(poRequest) AND poRequest:Has("targetCodepage") AND NOT poRequest:IsNull("targetCodepage") THEN
        ASSIGN cTargetCodepage = poRequest:GetCharacter("targetCodepage") NO-ERROR.
    IF VALID-OBJECT(poRequest) AND poRequest:Has("escapeUnicodeOutput") AND NOT poRequest:IsNull("escapeUnicodeOutput") THEN
        ASSIGN lEscapeUnicodeOutput = poRequest:GetLogical("escapeUnicodeOutput") NO-ERROR.
    IF cTargetCodepage = ? OR cTargetCodepage = "" THEN
        ASSIGN cTargetCodepage = "ISO8859-1".

    IF lcJson = ? OR lcJson = "" THEN DO:
        poResponse:Add("success", FALSE).
        poResponse:Add("error", "Informe parameters.jsonText com um objeto JSON").
        RETURN.
    END.

    ASSIGN cJson   = sanitizarJsonUnicodeIso(STRING(lcJson))
           oParser = NEW ObjectModelParser()
           oModel  = oParser:Parse(cJson)
           joRoot  = CAST(oModel, JsonObject) NO-ERROR.

    IF NOT VALID-OBJECT(joRoot) THEN DO:
        poResponse:Add("success", FALSE).
        poResponse:Add("error", "jsonText deve conter um JsonObject na raiz").
        RETURN.
    END.

    RUN analisarObjeto(INPUT joRoot, INPUT "", INPUT 0, INPUT 0).

    RUN buildRecordsJson(OUTPUT jaRows).
    poResponse:Add("success", TRUE).
    poResponse:Add("records", jaRows).
    RETURN.
END.

IF ERROR-STATUS:ERROR THEN DO:
    IF NOT VALID-OBJECT(poResponse) THEN
        ASSIGN poResponse = NEW JsonObject().
    poResponse:Add("success", FALSE) NO-ERROR.
    poResponse:Add("error", ERROR-STATUS:GET-MESSAGE(1)) NO-ERROR.
END.

FUNCTION sanitizarJsonUnicodeIso RETURNS CHARACTER (INPUT pcJson AS CHARACTER):
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHex AS CHARACTER NO-UNDO INITIAL "0123456789abcdefABCDEF".
    DEFINE VARIABLE cEsc AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDigit AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iDigit AS INTEGER NO-UNDO.
    DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
    DEFINE VARIABLE iNibble AS INTEGER NO-UNDO.

    IF pcJson = ? OR pcJson = "" THEN
        RETURN pcJson.

    ASSIGN iPos = 1.
    DO WHILE iPos <= LENGTH(pcJson):
        IF iPos <= LENGTH(pcJson) - 5
           AND SUBSTRING(pcJson, iPos, 2) = "\u" THEN DO:
            ASSIGN cEsc = SUBSTRING(pcJson, iPos + 2, 4)
                   iValue = 0.
            DO iDigit = 1 TO 4:
                ASSIGN cDigit = SUBSTRING(cEsc, iDigit, 1)
                       iNibble = INDEX(cHex, cDigit).
                IF iNibble = 0 THEN
                    LEAVE.
                IF iNibble > 16 THEN
                    ASSIGN iNibble = iNibble - 6.
                ASSIGN iValue = (iValue * 16) + iNibble - 1.
            END.

            IF iDigit = 5 THEN DO:
                IF iValue > 255 OR (iValue >= 128 AND iValue <= 159) THEN DO:
                    CASE iValue:
                        WHEN 8211 THEN ASSIGN cRet = cRet + "-".
                        WHEN 8212 THEN ASSIGN cRet = cRet + "-".
                        WHEN 8216 THEN ASSIGN cRet = cRet + "'".
                        WHEN 8217 THEN ASSIGN cRet = cRet + "'".
                        WHEN 8220 THEN ASSIGN cRet = cRet + "'".
                        WHEN 8221 THEN ASSIGN cRet = cRet + "'".
                        WHEN 8230 THEN ASSIGN cRet = cRet + "...".
                        OTHERWISE ASSIGN cRet = cRet + " ".
                    END CASE.
                END.
                ELSE
                    ASSIGN cRet = cRet + SUBSTRING(pcJson, iPos, 6).
                ASSIGN iPos = iPos + 6.
                NEXT.
            END.
        END.

        ASSIGN cRet = cRet + SUBSTRING(pcJson, iPos, 1)
               iPos = iPos + 1.
    END.

    RETURN cRet.
END FUNCTION.

FUNCTION normalizarTexto RETURNS CHARACTER (INPUT pcTexto AS CHARACTER):
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.

    IF pcTexto = ? THEN
        RETURN "".

    IF CAPS(cTargetCodepage) = CAPS(SESSION:CPINTERNAL) THEN
        RETURN pcTexto.

    ASSIGN cRet = CODEPAGE-CONVERT(pcTexto, cTargetCodepage) NO-ERROR.
    IF ERROR-STATUS:ERROR OR cRet = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN pcTexto.
    END.

    RETURN cRet.
END FUNCTION.

FUNCTION textoSaidaJson RETURNS CHARACTER (INPUT pcTexto AS CHARACTER):
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHex AS CHARACTER NO-UNDO INITIAL "0123456789abcdef".
    DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iCode AS INTEGER NO-UNDO.
    DEFINE VARIABLE iNibble AS INTEGER NO-UNDO.

    IF pcTexto = ? THEN
        RETURN "".
    IF NOT lEscapeUnicodeOutput THEN
        RETURN pcTexto.

    DO iPos = 1 TO LENGTH(pcTexto):
        ASSIGN cChar = SUBSTRING(pcTexto, iPos, 1)
               iCode = ASC(cChar) NO-ERROR.
        IF ERROR-STATUS:ERROR OR iCode = ? THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            ASSIGN cRet = cRet + cChar.
            NEXT.
        END.

        IF iCode > 126 THEN DO:
            ASSIGN cRet = cRet + "\u"
                   iNibble = TRUNCATE(iCode / 4096, 0)
                   cRet = cRet + SUBSTRING(cHex, iNibble + 1, 1)
                   iCode = iCode MODULO 4096
                   iNibble = TRUNCATE(iCode / 256, 0)
                   cRet = cRet + SUBSTRING(cHex, iNibble + 1, 1)
                   iCode = iCode MODULO 256
                   iNibble = TRUNCATE(iCode / 16, 0)
                   cRet = cRet + SUBSTRING(cHex, iNibble + 1, 1)
                   iNibble = iCode MODULO 16
                   cRet = cRet + SUBSTRING(cHex, iNibble + 1, 1).
        END.
        ELSE
            ASSIGN cRet = cRet + cChar.
    END.

    RETURN cRet.
END FUNCTION.

FUNCTION valorJsonObject RETURNS CHARACTER (INPUT poObject AS JsonObject, INPUT pcName AS CHARACTER):
    DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcValue AS LONGCHAR NO-UNDO.

    ASSIGN cValue = poObject:GetCharacter(pcName) NO-ERROR.
    IF NOT ERROR-STATUS:ERROR AND cValue <> ? THEN
        RETURN normalizarTexto(cValue).

    ERROR-STATUS:ERROR = FALSE.
    ASSIGN lcValue = poObject:GetJsonText(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR OR lcValue = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN "".
    END.

    RETURN normalizarTexto(STRING(lcValue)).
END FUNCTION.

FUNCTION valorJsonArray RETURNS CHARACTER (INPUT poArray AS JsonArray, INPUT piItem AS INTEGER):
    DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcValue AS LONGCHAR NO-UNDO.

    ASSIGN cValue = poArray:GetCharacter(piItem) NO-ERROR.
    IF NOT ERROR-STATUS:ERROR AND cValue <> ? THEN
        RETURN normalizarTexto(cValue).

    ERROR-STATUS:ERROR = FALSE.
    ASSIGN lcValue = poArray:GetJsonText(piItem) NO-ERROR.
    IF ERROR-STATUS:ERROR OR lcValue = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN "".
    END.

    RETURN normalizarTexto(STRING(lcValue)).
END FUNCTION.

PROCEDURE analisarObjeto:
    DEFINE INPUT PARAMETER poObject  AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER pcPath    AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAMETER piNivel   AS INTEGER    NO-UNDO.
    DEFINE INPUT PARAMETER piParent  AS INTEGER    NO-UNDO.

    DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
    DEFINE VARIABLE cName  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPath  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iItem  AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iId    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE joNext AS JsonObject NO-UNDO.
    DEFINE VARIABLE jaNext AS JsonArray  NO-UNDO.

    IF NOT VALID-OBJECT(poObject) THEN
        RETURN.

    ASSIGN cNames = poObject:GetNames() NO-ERROR.

    DO iItem = 1 TO EXTENT(cNames):
        ASSIGN cName = normalizarTexto(cNames[iItem])
               cPath = IF pcPath = "" THEN cName ELSE pcPath + "." + cName
               joNext = ?
               jaNext = ?.

        ASSIGN joNext = poObject:GetJsonObject(cNames[iItem]) NO-ERROR.
        IF VALID-OBJECT(joNext) THEN DO:
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "object", INPUT 0, INPUT "", OUTPUT iId).
            RUN analisarObjeto(INPUT joNext, INPUT cPath, INPUT piNivel + 1, INPUT iId).
            NEXT.
        END.

        ASSIGN jaNext = poObject:GetJsonArray(cNames[iItem]) NO-ERROR.
        IF VALID-OBJECT(jaNext) THEN DO:
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "array", INPUT 0, INPUT "", OUTPUT iId).
            RUN analisarArray(INPUT jaNext, INPUT cName, INPUT cPath, INPUT piNivel + 1, INPUT iId).
            NEXT.
        END.

        IF poObject:IsNull(cNames[iItem]) THEN
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "null", INPUT 0, INPUT "", OUTPUT iId).
        ELSE DO:
            ASSIGN cValor = valorJsonObject(poObject, cNames[iItem]).
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "value", INPUT 0, INPUT cValor, OUTPUT iId).
        END.
    END.
END PROCEDURE.

PROCEDURE analisarArray:
    DEFINE INPUT PARAMETER poArray  AS JsonArray  NO-UNDO.
    DEFINE INPUT PARAMETER pcName   AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAMETER pcPath   AS CHARACTER  NO-UNDO.
    DEFINE INPUT PARAMETER piNivel  AS INTEGER    NO-UNDO.
    DEFINE INPUT PARAMETER piParent AS INTEGER    NO-UNDO.

    DEFINE VARIABLE iItem  AS INTEGER    NO-UNDO.
    DEFINE VARIABLE iId    AS INTEGER    NO-UNDO.
    DEFINE VARIABLE cName  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cPath  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cValor AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE joNext AS JsonObject NO-UNDO.
    DEFINE VARIABLE jaNext AS JsonArray  NO-UNDO.

    IF NOT VALID-OBJECT(poArray) THEN
        RETURN.

    DO iItem = 1 TO poArray:Length:
        ASSIGN cName = pcName + "[" + STRING(iItem) + "]"
               cPath = pcPath + "[" + STRING(iItem) + "]"
               joNext = ?
               jaNext = ?.

        ASSIGN joNext = poArray:GetJsonObject(iItem) NO-ERROR.
        IF VALID-OBJECT(joNext) THEN DO:
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "object", INPUT iItem, INPUT "", OUTPUT iId).
            RUN analisarObjeto(INPUT joNext, INPUT cPath, INPUT piNivel + 1, INPUT iId).
            NEXT.
        END.

        ASSIGN jaNext = poArray:GetJsonArray(iItem) NO-ERROR.
        IF VALID-OBJECT(jaNext) THEN DO:
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "array", INPUT iItem, INPUT "", OUTPUT iId).
            RUN analisarArray(INPUT jaNext, INPUT pcName, INPUT cPath, INPUT piNivel + 1, INPUT iId).
            NEXT.
        END.

        IF poArray:IsNull(iItem) THEN
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "null", INPUT iItem, INPUT "", OUTPUT iId).
        ELSE DO:
            ASSIGN cValor = valorJsonArray(poArray, iItem).
            RUN criarRegistro(INPUT piParent, INPUT piNivel + 1, INPUT cName, INPUT cPath, INPUT "value", INPUT iItem, INPUT cValor, OUTPUT iId).
        END.
    END.
END PROCEDURE.

PROCEDURE criarRegistro:
    DEFINE INPUT  PARAMETER piParent AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER piNivel  AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER pcNome   AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcPath   AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcTipo   AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER piIndice AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER pcValor  AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER piId     AS INTEGER   NO-UNDO.

    ASSIGN iSeq = iSeq + 1
           piId = iSeq.

    CREATE ttJsonTag.
    ASSIGN ttJsonTag.id       = iSeq
           ttJsonTag.parentId = piParent
           ttJsonTag.nivel    = piNivel
           ttJsonTag.nome     = pcNome
           ttJsonTag.caminho  = pcPath
           ttJsonTag.tipo     = pcTipo
           ttJsonTag.indice   = piIndice
           ttJsonTag.valor    = pcValor.
END PROCEDURE.

PROCEDURE buildRecordsJson:
    DEFINE OUTPUT PARAMETER poRecords AS JsonArray NO-UNDO.
    DEFINE VARIABLE joRecord  AS JsonObject NO-UNDO.

    ASSIGN poRecords = NEW JsonArray().

    FOR EACH ttJsonTag BY ttJsonTag.id:
        ASSIGN joRecord = NEW JsonObject().
        joRecord:Add("id", ttJsonTag.id).
        joRecord:Add("parentId", ttJsonTag.parentId).
        joRecord:Add("nivel", ttJsonTag.nivel).
        joRecord:Add("nome", textoSaidaJson(ttJsonTag.nome)).
        joRecord:Add("caminho", textoSaidaJson(ttJsonTag.caminho)).
        joRecord:Add("tipo", ttJsonTag.tipo).
        joRecord:Add("indice", ttJsonTag.indice).
        joRecord:Add("valor", textoSaidaJson(ttJsonTag.valor)).
        poRecords:Add(joRecord).
    END.
END PROCEDURE.

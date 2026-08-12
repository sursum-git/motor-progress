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

DEFINE TEMP-TABLE ttJsonDestino NO-UNDO
    FIELD destino     AS CHARACTER
    FIELD tableHandle AS HANDLE
    FIELD nivel       AS INTEGER
    FIELD caminhoBase AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE destino.

DEFINE TEMP-TABLE ttJsonDePara NO-UNDO
    FIELD destino      AS CHARACTER
    FIELD campoTabela  AS CHARACTER
    FIELD tagJson      AS CHARACTER
    FIELD obrigatorio  AS LOGICAL
    FIELD valorDefault AS CHARACTER
    INDEX idxDestino destino.

DEFINE TEMP-TABLE ttJsonErro NO-UNDO
    FIELD destino     AS CHARACTER
    FIELD campoTabela AS CHARACTER
    FIELD tagJson     AS CHARACTER
    FIELD caminho     AS CHARACTER
    FIELD mensagem    AS CHARACTER.

DEFINE INPUT  PARAMETER TABLE FOR ttJsonTag.
DEFINE INPUT  PARAMETER TABLE FOR ttJsonDestino.
DEFINE INPUT  PARAMETER TABLE FOR ttJsonDePara.
DEFINE OUTPUT PARAMETER TABLE FOR ttJsonErro.

DEFINE BUFFER bAnchor FOR ttJsonTag.
DEFINE BUFFER bBuscaTag FOR ttJsonTag.

IF NOT CAN-FIND(FIRST ttJsonTag) THEN
    RUN registrarErro(
        INPUT "",
        INPUT "",
        INPUT "",
        INPUT "",
        INPUT "Nenhuma tag recebida em ttJsonTag"
    ).

FUNCTION caminhoNormalizado RETURNS CHARACTER (INPUT pcCaminho AS CHARACTER) FORWARD.
FUNCTION caminhoPai RETURNS CHARACTER (INPUT pcCaminho AS CHARACTER) FORWARD.
FUNCTION existeCaminhoExato RETURNS LOGICAL (INPUT pcCaminho AS CHARACTER) FORWARD.
FUNCTION decimalJson RETURNS DECIMAL (INPUT pcValor AS CHARACTER) FORWARD.
FUNCTION valorMapeado RETURNS CHARACTER (
    INPUT piAnchorId AS INTEGER,
    INPUT pcAnchorPath AS CHARACTER,
    INPUT piAnchorIndice AS INTEGER,
    INPUT pcTagJson AS CHARACTER,
    OUTPUT pcCaminho AS CHARACTER,
    OUTPUT plEncontrou AS LOGICAL
) FORWARD.

FOR EACH ttJsonDestino:
    DEFINE VARIABLE hTabela AS HANDLE NO-UNDO.
    DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
    DEFINE VARIABLE cBaseNormalizado AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iAnchors AS INTEGER NO-UNDO.

    ASSIGN hTabela = ttJsonDestino.tableHandle
           cBaseNormalizado = caminhoNormalizado(ttJsonDestino.caminhoBase).

    IF NOT VALID-HANDLE(hTabela) THEN DO:
        RUN registrarErro(
            INPUT ttJsonDestino.destino,
            INPUT "",
            INPUT "",
            INPUT ttJsonDestino.caminhoBase,
            INPUT "Handle da temp-table destino invalido"
        ).
        NEXT.
    END.

    ASSIGN hBuffer = hTabela:DEFAULT-BUFFER-HANDLE NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hBuffer) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RUN registrarErro(
            INPUT ttJsonDestino.destino,
            INPUT "",
            INPUT "",
            INPUT ttJsonDestino.caminhoBase,
            INPUT "Nao foi possivel obter o buffer da temp-table destino"
        ).
        NEXT.
    END.

    FOR EACH bAnchor
        WHERE bAnchor.nivel = ttJsonDestino.nivel
        BY bAnchor.id:
        IF caminhoNormalizado(bAnchor.caminho) <> cBaseNormalizado THEN
            NEXT.

        ASSIGN iAnchors = iAnchors + 1.

        hBuffer:BUFFER-CREATE() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            RUN registrarErro(
                INPUT ttJsonDestino.destino,
                INPUT "",
                INPUT "",
                INPUT bAnchor.caminho,
                INPUT "Nao foi possivel criar registro na temp-table destino: " + ERROR-STATUS:GET-MESSAGE(1)
            ).
            ERROR-STATUS:ERROR = FALSE.
            NEXT.
        END.

        FOR EACH ttJsonDePara
            WHERE ttJsonDePara.destino = ttJsonDestino.destino:
            DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
            DEFINE VARIABLE cCaminhoValor AS CHARACTER NO-UNDO.
            DEFINE VARIABLE lEncontrou AS LOGICAL NO-UNDO.

            ASSIGN cValor = valorMapeado(
                       INPUT bAnchor.id,
                       INPUT bAnchor.caminho,
                       INPUT bAnchor.indice,
                       INPUT ttJsonDePara.tagJson,
                       OUTPUT cCaminhoValor,
                       OUTPUT lEncontrou
                   ).

            IF NOT lEncontrou THEN DO:
                IF ttJsonDePara.valorDefault <> ? AND ttJsonDePara.valorDefault <> "" THEN DO:
                    ASSIGN cValor = ttJsonDePara.valorDefault
                           cCaminhoValor = bAnchor.caminho.
                END.
                ELSE DO:
                    IF ttJsonDePara.obrigatorio THEN
                        RUN registrarErro(
                            INPUT ttJsonDestino.destino,
                            INPUT ttJsonDePara.campoTabela,
                            INPUT ttJsonDePara.tagJson,
                            INPUT bAnchor.caminho,
                            INPUT "Tag obrigatoria nao encontrada"
                        ).
                    NEXT.
                END.
            END.

            RUN setCampoBuffer(
                INPUT ttJsonDestino.destino,
                INPUT hBuffer,
                INPUT ttJsonDePara.campoTabela,
                INPUT ttJsonDePara.tagJson,
                INPUT cCaminhoValor,
                INPUT cValor
            ).
        END.
    END.

    IF iAnchors = 0 THEN
        RUN registrarErro(
            INPUT ttJsonDestino.destino,
            INPUT "",
            INPUT "",
            INPUT ttJsonDestino.caminhoBase,
            INPUT "Nenhuma ancora encontrada para nivel " + STRING(ttJsonDestino.nivel) + " e caminho " + cBaseNormalizado
        ).
END.

FUNCTION caminhoNormalizado RETURNS CHARACTER (INPUT pcCaminho AS CHARACTER):
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
    DEFINE VARIABLE lDentroIndice AS LOGICAL NO-UNDO.

    IF pcCaminho = ? THEN
        RETURN "".

    DO iPos = 1 TO LENGTH(pcCaminho):
        ASSIGN cChar = SUBSTRING(pcCaminho, iPos, 1).

        IF cChar = "[" THEN DO:
            ASSIGN cRet = cRet + "[]"
                   lDentroIndice = TRUE.
            NEXT.
        END.

        IF lDentroIndice THEN DO:
            IF cChar = "]" THEN
                ASSIGN lDentroIndice = FALSE.
            NEXT.
        END.

        ASSIGN cRet = cRet + cChar.
    END.

    RETURN cRet.
END FUNCTION.

FUNCTION caminhoPai RETURNS CHARACTER (INPUT pcCaminho AS CHARACTER):
    DEFINE VARIABLE iPos AS INTEGER NO-UNDO.

    IF pcCaminho = ? OR pcCaminho = "" THEN
        RETURN "".

    DO iPos = LENGTH(pcCaminho) TO 1 BY -1:
        IF SUBSTRING(pcCaminho, iPos, 1) = "." THEN
            RETURN SUBSTRING(pcCaminho, 1, iPos - 1).
    END.

    RETURN "".
END FUNCTION.

FUNCTION existeCaminhoExato RETURNS LOGICAL (INPUT pcCaminho AS CHARACTER):
    FIND FIRST bBuscaTag
        WHERE bBuscaTag.caminho = pcCaminho
        NO-ERROR.

    RETURN AVAILABLE bBuscaTag.
END FUNCTION.

FUNCTION decimalJson RETURNS DECIMAL (INPUT pcValor AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
    DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.

    ASSIGN cValor = pcValor.

    IF cValor = ? OR cValor = "" THEN
        RETURN ?.

    DO iPos = 1 TO LENGTH(cValor):
        ASSIGN cChar = SUBSTRING(cValor, iPos, 1).
        IF INDEX("0123456789.,+-", cChar) = 0 THEN
            RETURN ?.
    END.

    IF SESSION:NUMERIC-FORMAT = "EUROPEAN"
       AND INDEX(cValor, ".") > 0
       AND INDEX(cValor, ",") = 0 THEN
        ASSIGN cValor = REPLACE(cValor, ".", ",").

    RETURN DECIMAL(cValor).
END FUNCTION.

FUNCTION valorMapeado RETURNS CHARACTER (
    INPUT piAnchorId AS INTEGER,
    INPUT pcAnchorPath AS CHARACTER,
    INPUT piAnchorIndice AS INTEGER,
    INPUT pcTagJson AS CHARACTER,
    OUTPUT pcCaminho AS CHARACTER,
    OUTPUT plEncontrou AS LOGICAL
):
    DEFINE VARIABLE cTag AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAnchor AS CHARACTER NO-UNDO.

    ASSIGN cTag = IF pcTagJson = ? THEN "" ELSE pcTagJson
           cAnchor = pcAnchorPath
           pcCaminho = ""
           plEncontrou = FALSE.

    IF cTag = "$indice" THEN DO:
        ASSIGN pcCaminho = pcAnchorPath
               plEncontrou = TRUE.
        RETURN STRING(piAnchorIndice).
    END.

    DO WHILE SUBSTRING(cTag, 1, 3) = "../":
        ASSIGN cAnchor = caminhoPai(cAnchor)
               cTag = SUBSTRING(cTag, 4).
    END.

    IF SUBSTRING(cTag, 1, 1) = "/" THEN
        ASSIGN cPath = SUBSTRING(cTag, 2).
    ELSE IF existeCaminhoExato(cTag) THEN
        ASSIGN cPath = cTag.
    ELSE IF cAnchor = "" THEN
        ASSIGN cPath = cTag.
    ELSE
        ASSIGN cPath = cAnchor + "." + cTag.

    FIND FIRST bBuscaTag
        WHERE bBuscaTag.caminho = cPath
          AND (bBuscaTag.tipo = "value" OR bBuscaTag.tipo = "null")
        NO-ERROR.

    IF AVAILABLE bBuscaTag THEN DO:
        ASSIGN pcCaminho = bBuscaTag.caminho
               plEncontrou = TRUE.
        RETURN bBuscaTag.valor.
    END.

    FIND FIRST bBuscaTag
        WHERE bBuscaTag.parentId = piAnchorId
          AND bBuscaTag.nome = cTag
          AND (bBuscaTag.tipo = "value" OR bBuscaTag.tipo = "null")
        NO-ERROR.

    IF AVAILABLE bBuscaTag THEN DO:
        ASSIGN pcCaminho = bBuscaTag.caminho
               plEncontrou = TRUE.
        RETURN bBuscaTag.valor.
    END.

    ASSIGN pcCaminho = cPath.
    RETURN "".
END FUNCTION.

PROCEDURE setCampoBuffer:
    DEFINE INPUT PARAMETER pcDestino AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER phBuffer AS HANDLE NO-UNDO.
    DEFINE INPUT PARAMETER pcCampo AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcTag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcCaminho AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcValor AS CHARACTER NO-UNDO.

    DEFINE VARIABLE hCampo AS HANDLE NO-UNDO.
    DEFINE VARIABLE dValor AS DECIMAL NO-UNDO.

    ASSIGN hCampo = phBuffer:BUFFER-FIELD(pcCampo) NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hCampo) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RUN registrarErro(
            INPUT pcDestino,
            INPUT pcCampo,
            INPUT pcTag,
            INPUT pcCaminho,
            INPUT "Campo nao encontrado na temp-table destino"
        ).
        RETURN.
    END.

    CASE hCampo:DATA-TYPE:
        WHEN "integer" THEN
            hCampo:BUFFER-VALUE = INTEGER(pcValor) NO-ERROR.
        WHEN "int64" THEN
            hCampo:BUFFER-VALUE = INT64(pcValor) NO-ERROR.
        WHEN "decimal" THEN DO:
            ASSIGN dValor = decimalJson(pcValor) NO-ERROR.
            IF dValor = ? AND pcValor <> ? AND pcValor <> "" THEN DO:
                RUN registrarErro(
                    INPUT pcDestino,
                    INPUT pcCampo,
                    INPUT pcTag,
                    INPUT pcCaminho,
                    INPUT "Erro ao converter valor '" + pcValor + "' para decimal"
                ).
                RETURN.
            END.
            ELSE IF NOT ERROR-STATUS:ERROR THEN
                hCampo:BUFFER-VALUE = dValor NO-ERROR.
        END.
        WHEN "logical" THEN
            hCampo:BUFFER-VALUE = LOGICAL(pcValor) NO-ERROR.
        WHEN "date" THEN
            hCampo:BUFFER-VALUE = DATE(pcValor) NO-ERROR.
        WHEN "datetime" THEN
            hCampo:BUFFER-VALUE = DATETIME(pcValor) NO-ERROR.
        WHEN "datetime-tz" THEN
            hCampo:BUFFER-VALUE = DATETIME-TZ(pcValor) NO-ERROR.
        WHEN "rowid" THEN
            hCampo:BUFFER-VALUE = TO-ROWID(pcValor) NO-ERROR.
        OTHERWISE
            hCampo:BUFFER-VALUE = pcValor NO-ERROR.
    END CASE.

    IF ERROR-STATUS:ERROR THEN DO:
        RUN registrarErro(
            INPUT pcDestino,
            INPUT pcCampo,
            INPUT pcTag,
            INPUT pcCaminho,
            INPUT "Erro ao converter valor '" + pcValor + "' para " + hCampo:DATA-TYPE + ": " + ERROR-STATUS:GET-MESSAGE(1)
        ).
        ERROR-STATUS:ERROR = FALSE.
    END.
END PROCEDURE.

PROCEDURE registrarErro:
    DEFINE INPUT PARAMETER pcDestino AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcCampo AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcTag AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcCaminho AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

    CREATE ttJsonErro.
    ASSIGN ttJsonErro.destino     = pcDestino
           ttJsonErro.campoTabela = pcCampo
           ttJsonErro.tagJson     = pcTag
           ttJsonErro.caminho     = pcCaminho
           ttJsonErro.mensagem    = pcMensagem.
END PROCEDURE.

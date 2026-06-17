/*
Catalogo OO de metadados baseado no dicionario Progress.
Nao executa fonte procedural legado.
*/

USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.

CLASS DynamicMetadataService:
    {esbo/boMetaDados.i}

    DEFINE PRIVATE VARIABLE cTabela AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cBanco  AS CHARACTER NO-UNDO INIT "DICTDB".
    DEFINE PRIVATE VARIABLE cBancoExibicao AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cCampos AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cTipoRetCpExtent AS CHARACTER NO-UNDO INIT "unico".
    DEFINE PRIVATE VARIABLE cCaracterOri AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cCaracterSub AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE lSubstCaracter AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE lRetCampos AS LOGICAL NO-UNDO INIT TRUE.
    DEFINE PRIVATE VARIABLE lRetIndices AS LOGICAL NO-UNDO INIT TRUE.
    DEFINE PRIVATE VARIABLE lRetCpsIndice AS LOGICAL NO-UNDO INIT TRUE.

    CONSTRUCTOR PUBLIC DynamicMetadataService():
    END CONSTRUCTOR.

    METHOD PUBLIC VOID setTabela(INPUT pcTabela AS CHARACTER):
        ASSIGN cTabela = pcTabela.
    END METHOD.

    METHOD PUBLIC VOID setBanco(INPUT pcBanco AS CHARACTER):
        IF pcBanco <> "" AND pcBanco <> ? THEN
            ASSIGN cBanco = pcBanco.
    END METHOD.

    METHOD PUBLIC VOID setBancoExibicao(INPUT pcBanco AS CHARACTER):
        IF pcBanco <> "" AND pcBanco <> ? THEN
            ASSIGN cBancoExibicao = pcBanco.
    END METHOD.

    METHOD PUBLIC VOID setCampos(INPUT pcCampos AS CHARACTER):
        ASSIGN cCampos = pcCampos.
    END METHOD.

    METHOD PUBLIC VOID setTipoRetCpExtent(INPUT pcTipo AS CHARACTER):
        ASSIGN cTipoRetCpExtent = pcTipo.
    END METHOD.

    METHOD PUBLIC VOID setCaracterSubst(INPUT pcOrig AS CHARACTER, INPUT pcSub AS CHARACTER):
        ASSIGN cCaracterOri = pcOrig
               cCaracterSub = pcSub
               lSubstCaracter = TRUE.
    END METHOD.

    METHOD PUBLIC VOID setRetCampos(INPUT plog AS LOGICAL):
        ASSIGN lRetCampos = plog.
    END METHOD.

    METHOD PUBLIC VOID setRetIndices(INPUT plog AS LOGICAL):
        ASSIGN lRetIndices = plog.
    END METHOD.

    METHOD PUBLIC VOID setRetCpsIndice(INPUT plog AS LOGICAL):
        ASSIGN lRetCpsIndice = plog.
    END METHOD.

    METHOD PUBLIC VOID resetCache():
        EMPTY TEMP-TABLE ttCampos.
        EMPTY TEMP-TABLE ttIndices.
        EMPTY TEMP-TABLE ttCpsInd.
    END METHOD.

    METHOD PUBLIC VOID carregarCampos(
        INPUT pcTabela AS CHARACTER,
        INPUT pcCampos AS CHARACTER):

        ASSIGN cTabela = pcTabela
               cCampos = pcCampos.
        THIS-OBJECT:loadCampos().
    END METHOD.

    METHOD PUBLIC VOID carregarIndices(INPUT pcTabela AS CHARACTER):
        ASSIGN cTabela = pcTabela.
        THIS-OBJECT:loadIndices().
    END METHOD.

    METHOD PUBLIC VOID getCampos(OUTPUT TABLE ttCampos):
    END METHOD.

    METHOD PUBLIC VOID getIndices(
        OUTPUT TABLE ttIndices,
        OUTPUT TABLE ttCpsInd):
    END METHOD.

    METHOD PUBLIC VOID getDadosTabela(
        INPUT pcTabela AS CHARACTER,
        INPUT pcCampos AS CHARACTER,
        OUTPUT TABLE ttCampos,
        OUTPUT TABLE ttIndices,
        OUTPUT TABLE ttCpsInd):

        THIS-OBJECT:carregarCampos(pcTabela, pcCampos).
        THIS-OBJECT:carregarIndices(pcTabela).
    END METHOD.

    METHOD PUBLIC JsonArray getTablesJson(INPUT pcFilter AS CHARACTER):
        DEFINE VARIABLE jaTables AS JsonArray NO-UNDO.
        DEFINE VARIABLE joTable AS JsonObject NO-UNDO.
        DEFINE VARIABLE cFilter AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE hLastChange AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.

        ASSIGN jaTables = NEW JsonArray()
               cFilter = LC(TRIM(pcFilter)).

        CREATE BUFFER hFile FOR TABLE cBanco + "._File" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) THEN
            RETURN jaTables.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hFile).
        ASSIGN cPrepare = "FOR EACH " + cBanco + "._File NO-LOCK WHERE "
                        + cBanco + "._File._File-Name <> " + QUOTER("") + " AND "
                        + "SUBSTRING(" + cBanco + "._File._File-Name,1,1) <> " + QUOTER("_")
                        + " BY " + cBanco + "._File._File-Name".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hFile NO-ERROR.
            RETURN jaTables.
        END.

        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN
                LEAVE.

            IF cFilter <> "" AND INDEX(LC(STRING(hFile:BUFFER-FIELD("_File-Name"):BUFFER-VALUE)), cFilter) = 0 THEN
                NEXT.

            ASSIGN joTable = NEW JsonObject().
            joTable:Add("name", THIS-OBJECT:safeJsonChar(STRING(hFile:BUFFER-FIELD("_File-Name"):BUFFER-VALUE))).
            joTable:Add("database", THIS-OBJECT:getBancoTb()).
            joTable:Add("displayName", THIS-OBJECT:getBancoTb() + "." + THIS-OBJECT:safeJsonChar(STRING(hFile:BUFFER-FIELD("_File-Name"):BUFFER-VALUE))).
            joTable:Add("label", IF hFile:BUFFER-FIELD("_File-Label"):BUFFER-VALUE = ? THEN "" ELSE THIS-OBJECT:safeJsonChar(STRING(hFile:BUFFER-FIELD("_File-Label"):BUFFER-VALUE))).
            joTable:Add("dumpName", IF hFile:BUFFER-FIELD("_Dump-Name"):BUFFER-VALUE = ? THEN "" ELSE THIS-OBJECT:safeJsonChar(STRING(hFile:BUFFER-FIELD("_Dump-Name"):BUFFER-VALUE))).
            ASSIGN hLastChange = hFile:BUFFER-FIELD("_Last-Change") NO-ERROR.
            IF VALID-HANDLE(hLastChange) THEN
                joTable:Add("lastUpdate", IF hLastChange:BUFFER-VALUE = ? THEN "" ELSE STRING(hLastChange:BUFFER-VALUE)).
            ELSE
                joTable:Add("lastUpdate", "").
            jaTables:Add(joTable).
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hFile NO-ERROR.

        RETURN jaTables.
    END METHOD.

    METHOD PRIVATE CHARACTER safeJsonChar(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iChar AS INTEGER NO-UNDO.
        DEFINE VARIABLE iAsc AS INTEGER NO-UNDO.

        IF pcValue = ? THEN
            RETURN "".

        DO iChar = 1 TO LENGTH(pcValue):
            ASSIGN cChar = SUBSTRING(pcValue, iChar, 1) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                NEXT.
            END.

            ASSIGN iAsc = ASC(cChar) NO-ERROR.
            IF ERROR-STATUS:ERROR OR iAsc = ? THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                NEXT.
            END.

            IF iAsc < 32 OR iAsc > 126 THEN
                ASSIGN cOut = cOut + " ".
            ELSE
                ASSIGN cOut = cOut + cChar.
        END.

        RETURN cOut.
    END METHOD.

    METHOD PUBLIC JsonArray getFieldsJson(INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE joField AS JsonObject NO-UNDO.
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cListaIndices AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cViewAs AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cListExpression AS CHARACTER NO-UNDO.
        DEFINE VARIABLE jaOptions AS JsonArray NO-UNDO.
        DEFINE VARIABLE rFile AS RECID NO-UNDO.

        ASSIGN jaFields = NEW JsonArray().

        CREATE BUFFER hFile FOR TABLE cBanco + "._File" NO-ERROR.
        CREATE BUFFER hField FOR TABLE cBanco + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) OR NOT VALID-HANDLE(hField) THEN DO:
            IF VALID-HANDLE(hFile) THEN DELETE OBJECT hFile NO-ERROR.
            IF VALID-HANDLE(hField) THEN DELETE OBJECT hField NO-ERROR.
            RETURN jaFields.
        END.

        hFile:FIND-FIRST("WHERE _File-Name = " + QUOTER(pcTable), NO-LOCK) NO-ERROR.
        IF NOT hFile:AVAILABLE THEN DO:
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN jaFields.
        END.

        ASSIGN rFile = hFile:RECID.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hField).
        ASSIGN cPrepare = "FOR EACH " + cBanco + "._Field NO-LOCK "
                        + "WHERE " + cBanco + "._Field._File-Recid = " + STRING(rFile) + " "
                        + "BY " + cBanco + "._Field._Order".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN jaFields.
        END.

        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN
                LEAVE.
            IF hField:RECID <> ? AND hField:BUFFER-FIELD("_File-Recid"):BUFFER-VALUE <> rFile THEN
                NEXT.

            ASSIGN cListaIndices = THIS-OBJECT:getDynamicIndexListForField(hField:RECID)
                   cViewAs = IF hField:BUFFER-FIELD("_View-As"):BUFFER-VALUE = ? THEN "" ELSE STRING(hField:BUFFER-FIELD("_View-As"):BUFFER-VALUE)
                   cListExpression = ""
                   jaOptions = NEW JsonArray()
                   joField = NEW JsonObject().

            DO ON ERROR UNDO, LEAVE ON STOP UNDO, LEAVE:
                ASSIGN cListExpression = THIS-OBJECT:extractViewAsList(cViewAs)
                       jaOptions = THIS-OBJECT:parseViewAsOptions(cListExpression).
            END.
            IF NOT VALID-OBJECT(jaOptions) THEN
                ASSIGN jaOptions = NEW JsonArray().
            joField:Add("name", STRING(hField:BUFFER-FIELD("_Field-Name"):BUFFER-VALUE)).
            joField:Add("database", THIS-OBJECT:getBancoTb()).
            joField:Add("type", THIS-OBJECT:normalizeDataType(STRING(hField:BUFFER-FIELD("_Data-Type"):BUFFER-VALUE))).
            joField:Add("label", IF hField:BUFFER-FIELD("_Label"):BUFFER-VALUE = ? THEN "" ELSE STRING(hField:BUFFER-FIELD("_Label"):BUFFER-VALUE)).
            joField:Add("format", IF hField:BUFFER-FIELD("_Format"):BUFFER-VALUE = ? THEN "" ELSE STRING(hField:BUFFER-FIELD("_Format"):BUFFER-VALUE)).
            joField:Add("viewAs", cViewAs).
            joField:Add("listExpression", cListExpression).
            joField:Add("options", jaOptions).
            joField:Add("mandatory", LOGICAL(hField:BUFFER-FIELD("_Mandatory"):BUFFER-VALUE)).
            joField:Add("extent", INTEGER(hField:BUFFER-FIELD("_Extent"):BUFFER-VALUE)).
            joField:Add("indices", cListaIndices).
            jaFields:Add(joField).
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hFile NO-ERROR.
        DELETE OBJECT hField NO-ERROR.

        RETURN jaFields.
    END METHOD.

    METHOD PUBLIC CHARACTER getBancoTb():
        IF cBancoExibicao <> "" THEN
            RETURN cBancoExibicao.
        IF cBanco <> "" THEN
            RETURN cBanco.
        IF LDBNAME("DICTDB") <> ? THEN
            RETURN "DICTDB".
        RETURN "".
    END METHOD.

    METHOD PUBLIC VOID getNomeCampo(
        INPUT pRecid AS RECID,
        OUTPUT pcNome AS CHARACTER):

        ASSIGN pcNome = "".
        FIND FIRST DICTDB._Field
             WHERE RECID(DICTDB._Field) = pRecid
             NO-LOCK NO-ERROR.
        IF AVAILABLE DICTDB._Field THEN
            ASSIGN pcNome = DICTDB._Field._Field-Name.
    END METHOD.

    METHOD PUBLIC INTEGER getQtdCamposTabela():
        DEFINE VARIABLE iQt AS INTEGER NO-UNDO.
        FOR EACH ttCampos:
            ASSIGN iQt = iQt + 1.
        END.
        RETURN iQt.
    END METHOD.

    METHOD PRIVATE VOID loadCampos():
        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        DEFINE VARIABLE cListaIndices AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rFile AS RECID NO-UNDO.

        EMPTY TEMP-TABLE ttCampos.
        IF cTabela = "" OR NOT lRetCampos THEN
            RETURN.

        CREATE BUFFER hFile FOR TABLE cBanco + "._File" NO-ERROR.
        CREATE BUFFER hField FOR TABLE cBanco + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) OR NOT VALID-HANDLE(hField) THEN DO:
            IF VALID-HANDLE(hFile) THEN DELETE OBJECT hFile NO-ERROR.
            IF VALID-HANDLE(hField) THEN DELETE OBJECT hField NO-ERROR.
            RETURN.
        END.

        hFile:FIND-FIRST("WHERE _File-Name = " + QUOTER(cTabela), NO-LOCK) NO-ERROR.
        IF NOT hFile:AVAILABLE THEN DO:
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN.
        END.

        ASSIGN rFile = hFile:RECID.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hField).
        ASSIGN cPrepare = "FOR EACH " + cBanco + "._Field NO-LOCK "
                        + "WHERE " + cBanco + "._Field._File-Recid = " + STRING(rFile) + " "
                        + "BY " + cBanco + "._Field._Order".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN.
        END.

        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN
                LEAVE.

            IF cCampos <> "" AND NOT CAN-DO(cCampos, STRING(hField:BUFFER-FIELD("_Field-Name"):BUFFER-VALUE)) THEN
                NEXT.

            ASSIGN iOrd = iOrd + 1
                   cListaIndices = THIS-OBJECT:getIndexListForField(hField:RECID).

            CREATE ttCampos.
            ASSIGN ttCampos.id          = hField:RECID
                   ttCampos.ordem       = iOrd
                   ttCampos.nome        = THIS-OBJECT:substCaracter(STRING(hField:BUFFER-FIELD("_Field-Name"):BUFFER-VALUE))
                   ttCampos.tipo        = THIS-OBJECT:normalizeDataType(STRING(hField:BUFFER-FIELD("_Data-Type"):BUFFER-VALUE))
                   ttCampos.formato     = STRING(hField:BUFFER-FIELD("_Format"):BUFFER-VALUE)
                   ttCampos.labelCampo  = STRING(hField:BUFFER-FIELD("_Label"):BUFFER-VALUE)
                   ttCampos.extensao    = INTEGER(hField:BUFFER-FIELD("_Extent"):BUFFER-VALUE)
                   ttCampos.qtDecimais  = INTEGER(hField:BUFFER-FIELD("_Decimals"):BUFFER-VALUE)
                   ttCampos.obrigatorio = LOGICAL(hField:BUFFER-FIELD("_Mandatory"):BUFFER-VALUE)
                   ttCampos.indices     = cListaIndices
                   ttCampos.lista       = STRING(hField:BUFFER-FIELD("_Valexp"):BUFFER-VALUE)
                   ttCampos.numRecid    = hField:RECID
                   ttCampos.tabela      = STRING(hFile:BUFFER-FIELD("_File-Name"):BUFFER-VALUE)
                   ttCampos.banco       = THIS-OBJECT:getBancoTb().
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hFile NO-ERROR.
        DELETE OBJECT hField NO-ERROR.
    END METHOD.

    METHOD PRIVATE VOID loadIndices():
        DEFINE VARIABLE iId AS INTEGER NO-UNDO.
        DEFINE VARIABLE iCp AS INTEGER NO-UNDO.

        EMPTY TEMP-TABLE ttIndices.
        EMPTY TEMP-TABLE ttCpsInd.
        IF cTabela = "" OR NOT lRetIndices THEN
            RETURN.

        FIND FIRST DICTDB._File
             WHERE DICTDB._File._File-Name = cTabela
             NO-LOCK NO-ERROR.
        IF NOT AVAILABLE DICTDB._File THEN
            RETURN.

        FOR EACH DICTDB._Index
            WHERE DICTDB._Index._File-recid = RECID(DICTDB._File)
            NO-LOCK BY DICTDB._Index._Idx-num:

            ASSIGN iId = iId + 1.
            CREATE ttIndices.
            ASSIGN ttIndices.id         = iId
                   ttIndices.recidFile  = RECID(DICTDB._File)
                   ttIndices.nome       = DICTDB._Index._Index-Name
                   ttIndices.logPrimario = RECID(DICTDB._Index) = DICTDB._File._Prime-Index
                   ttIndices.logUnico   = DICTDB._Index._Unique
                   ttIndices.logAtivo   = DICTDB._Index._Active
                   ttIndices.wordIdx    = INTEGER(DICTDB._Index._Wordidx)
                   ttIndices.idxCRC     = DICTDB._Index._Idx-num
                   ttIndices.recidIndex = RECID(DICTDB._Index).

            IF NOT lRetCpsIndice THEN
                NEXT.

            FOR EACH DICTDB._Index-Field
                WHERE DICTDB._Index-Field._Index-recid = RECID(DICTDB._Index)
                NO-LOCK BY DICTDB._Index-Field._Index-Seq:

                FIND FIRST DICTDB._Field
                     WHERE RECID(DICTDB._Field) = DICTDB._Index-Field._Field-recid
                     NO-LOCK NO-ERROR.
                IF NOT AVAILABLE DICTDB._Field THEN
                    NEXT.

                ASSIGN iCp = iCp + 1.
                CREATE ttCpsInd.
                ASSIGN ttCpsInd.id           = iCp
                       ttCpsInd.idIndice     = iId
                       ttCpsInd.indexSeq     = DICTDB._Index-Field._Index-Seq
                       ttCpsInd.fieldRecid   = RECID(DICTDB._Field)
                       ttCpsInd.logUnsorted  = FALSE
                       ttCpsInd.logAscending = DICTDB._Index-Field._Ascending
                       ttCpsInd.logAbbreviate = DICTDB._Index-Field._Abbreviate
                       ttCpsInd.indexRecid   = RECID(DICTDB._Index)
                       ttCpsInd.nome         = DICTDB._Field._Field-Name
                       ttCpsInd.tipo         = THIS-OBJECT:normalizeDataType(DICTDB._Field._Data-Type).
            END.
        END.
    END METHOD.

    METHOD PRIVATE CHARACTER getIndexListForField(INPUT prField AS RECID):
        DEFINE VARIABLE cLista AS CHARACTER NO-UNDO.

        FOR EACH DICTDB._Index-Field
            WHERE DICTDB._Index-Field._Field-recid = prField
            NO-LOCK:

            FIND FIRST DICTDB._Index
                 WHERE RECID(DICTDB._Index) = DICTDB._Index-Field._Index-recid
                 NO-LOCK NO-ERROR.
            IF AVAILABLE DICTDB._Index THEN DO:
                IF cLista = "" THEN
                    ASSIGN cLista = DICTDB._Index._Index-Name.
                ELSE
                    ASSIGN cLista = cLista + "," + DICTDB._Index._Index-Name.
            END.
        END.

        RETURN cLista.
    END METHOD.

    METHOD PRIVATE CHARACTER getDynamicIndexListForField(INPUT prField AS RECID):
        DEFINE VARIABLE hIndexField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hIndex AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLista AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cIndexName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rIndex AS RECID NO-UNDO.

        CREATE BUFFER hIndexField FOR TABLE cBanco + "._Index-Field" NO-ERROR.
        CREATE BUFFER hIndex FOR TABLE cBanco + "._Index" NO-ERROR.
        IF NOT VALID-HANDLE(hIndexField) OR NOT VALID-HANDLE(hIndex) THEN DO:
            IF VALID-HANDLE(hIndexField) THEN DELETE OBJECT hIndexField NO-ERROR.
            IF VALID-HANDLE(hIndex) THEN DELETE OBJECT hIndex NO-ERROR.
            RETURN "".
        END.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hIndexField).
        ASSIGN cPrepare = "FOR EACH " + cBanco + "._Index-Field NO-LOCK "
                        + "WHERE " + cBanco + "._Index-Field._Field-recid = " + STRING(prField) + " "
                        + "BY " + cBanco + "._Index-Field._Index-Seq".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hIndexField NO-ERROR.
            DELETE OBJECT hIndex NO-ERROR.
            RETURN "".
        END.

        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN
                LEAVE.

            ASSIGN rIndex = hIndexField:BUFFER-FIELD("_Index-recid"):BUFFER-VALUE.
            hIndex:FIND-FIRST("WHERE RECID(" + cBanco + "._Index) = " + STRING(rIndex), NO-LOCK) NO-ERROR.
            IF NOT hIndex:AVAILABLE THEN
                NEXT.

            ASSIGN cIndexName = STRING(hIndex:BUFFER-FIELD("_Index-Name"):BUFFER-VALUE).
            IF cIndexName = "" OR CAN-DO(cLista, cIndexName) THEN
                NEXT.

            IF cLista = "" THEN
                ASSIGN cLista = cIndexName.
            ELSE
                ASSIGN cLista = cLista + "," + cIndexName.
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hIndexField NO-ERROR.
        DELETE OBJECT hIndex NO-ERROR.

        RETURN cLista.
    END METHOD.

    METHOD PRIVATE CHARACTER extractViewAsList(INPUT pcViewAs AS CHARACTER):
        DEFINE VARIABLE cRetorno AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lTemInclude AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lTemLista AS LOGICAL NO-UNDO.
        DEFINE VARIABLE iCont AS INTEGER NO-UNDO.
        DEFINE VARIABLE cListaFinal AS CHARACTER NO-UNDO.

        IF pcViewAs = ? OR TRIM(pcViewAs) = "" THEN
            RETURN "".

        IF INDEX(cBanco, "ems5") = 0 THEN DO:
            ASSIGN lTemInclude = INDEX(pcViewAs, ".i") > 0
                               AND (INDEX(pcViewAs, "02") > 0 OR INDEX(pcViewAs, "2") > 0).

            IF lTemInclude THEN DO:
                ASSIGN cInclude = ENTRY(2, pcViewAs, "~{")
                       cInclude = ENTRY(1, cInclude, ".i")
                       cInclude = cInclude + ".i 3".

                ASSIGN cRetorno = THIS-OBJECT:resolveCompiledViewAsInclude(cInclude).
            END.
            ELSE
                ASSIGN cRetorno = pcViewAs.
        END.
        ELSE DO:
            ASSIGN lTemLista = INDEX(LC(pcViewAs), "list-item") > 0.
            IF lTemLista THEN DO:
                ASSIGN cRetorno = ENTRY(1, pcViewAs, "/")
                       cRetorno = REPLACE(cRetorno, ENTRY(1, cRetorno, '"'), "")
                       cRetorno = REPLACE(cRetorno, '"', "").

                REPEAT iCont = 1 TO NUM-ENTRIES(cRetorno):
                    IF cListaFinal = "" THEN
                        ASSIGN cListaFinal = ENTRY(iCont, cRetorno).
                    ELSE
                        ASSIGN cListaFinal = cListaFinal + "," + ENTRY(iCont, cRetorno).
                END.
                ASSIGN cRetorno = cListaFinal.
            END.
            ELSE
                ASSIGN cRetorno = pcViewAs.
        END.

        ASSIGN cRetorno = THIS-OBJECT:normalizeListExpression(cRetorno).

        IF INDEX(LC(cRetorno), "toggle-box") > 0 THEN
            ASSIGN cRetorno = "".
        IF INDEX(LC(cRetorno), "editor") > 0 THEN
            ASSIGN cRetorno = "".
        IF cRetorno = ? OR cRetorno = "?" THEN
            ASSIGN cRetorno = "".

        RETURN cRetorno.
    END METHOD.

    METHOD PRIVATE CHARACTER resolveCompiledViewAsInclude(INPUT pcInclude AS CHARACTER):
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeListExpression(INPUT pcText AS CHARACTER):
        DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLower AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPos AS INTEGER NO-UNDO.

        IF pcText = ? THEN
            RETURN "".

        ASSIGN cText = TRIM(pcText)
               cLower = LC(cText).

        ASSIGN iPos = INDEX(cLower, "radio-buttons").
        IF iPos > 0 THEN
            ASSIGN cText = TRIM(SUBSTRING(cText, iPos + LENGTH("radio-buttons"))).
        ELSE DO:
            ASSIGN iPos = INDEX(cLower, "list-items").
            IF iPos = 0 THEN
                ASSIGN iPos = INDEX(cLower, "list-item").
            IF iPos > 0 THEN
                ASSIGN cText = TRIM(SUBSTRING(cText, iPos + LENGTH("list-items"))).
        END.

        IF LENGTH(cText) >= 2 AND SUBSTRING(cText, 1, 1) = "~{" AND SUBSTRING(cText, LENGTH(cText), 1) = "}" THEN
            RETURN "".

        RETURN TRIM(cText).
    END METHOD.

    METHOD PRIVATE JsonArray parseViewAsOptions(INPUT pcList AS CHARACTER):
        DEFINE VARIABLE jaOptions AS JsonArray NO-UNDO.
        DEFINE VARIABLE joOption AS JsonObject NO-UNDO.
        DEFINE VARIABLE iCont AS INTEGER NO-UNDO.
        DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.
        DEFINE VARIABLE cLabel AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN jaOptions = NEW JsonArray().

        IF pcList = ? OR TRIM(pcList) = "" THEN
            RETURN jaOptions.

        ASSIGN iTotal = NUM-ENTRIES(pcList).
        IF iTotal MODULO 2 <> 0 THEN DO:
            DO iCont = 1 TO iTotal:
                ASSIGN cLabel = THIS-OBJECT:cleanOptionToken(ENTRY(iCont, pcList)).
                IF cLabel = "" THEN
                    NEXT.

                ASSIGN joOption = NEW JsonObject().
                joOption:Add("label", cLabel).
                joOption:Add("value", cLabel).
                jaOptions:Add(joOption).
            END.
            RETURN jaOptions.
        END.

        DO iCont = 1 TO iTotal BY 2:
            ASSIGN cLabel = THIS-OBJECT:cleanOptionToken(ENTRY(iCont, pcList))
                   cValue = IF iCont + 1 <= iTotal
                            THEN THIS-OBJECT:cleanOptionToken(ENTRY(iCont + 1, pcList))
                            ELSE cLabel.

            IF cLabel = "" AND cValue = "" THEN
                NEXT.

            ASSIGN joOption = NEW JsonObject().
            joOption:Add("label", cLabel).
            joOption:Add("value", cValue).
            jaOptions:Add(joOption).
        END.

        RETURN jaOptions.
    END METHOD.

    METHOD PRIVATE CHARACTER cleanOptionToken(INPUT pcToken AS CHARACTER):
        DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.

        IF pcToken = ? THEN
            RETURN "".

        ASSIGN cToken = TRIM(pcToken)
               cToken = REPLACE(cToken, "~"", "")
               cToken = REPLACE(cToken, "'", "")
               cToken = REPLACE(cToken, "/", "")
               cToken = TRIM(cToken).

        RETURN cToken.
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeDataType(INPUT pcType AS CHARACTER):
        CASE LC(pcType):
            WHEN "char" THEN RETURN "character".
            WHEN "character" THEN RETURN "character".
            WHEN "int" THEN RETURN "integer".
            WHEN "integer" THEN RETURN "integer".
            WHEN "int64" THEN RETURN "int64".
            WHEN "dec" THEN RETURN "decimal".
            WHEN "decimal" THEN RETURN "decimal".
            WHEN "date" THEN RETURN "date".
            WHEN "datetime" THEN RETURN "datetime".
            WHEN "datetime-tz" THEN RETURN "datetime".
            WHEN "logical" THEN RETURN "logical".
            OTHERWISE RETURN LC(pcType).
        END CASE.
    END METHOD.

    METHOD PRIVATE CHARACTER substCaracter(INPUT pcTexto AS CHARACTER):
        IF lSubstCaracter THEN
            RETURN REPLACE(pcTexto, cCaracterOri, cCaracterSub).
        RETURN pcTexto.
    END METHOD.

END CLASS.

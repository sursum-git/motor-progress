/*
Catalogo OO de metadados baseado no dicionario Progress.
Nao executa fonte procedural legado.
*/

CLASS DynamicMetadataService:
    {esbo/boMetaDados.i}

    DEFINE PRIVATE VARIABLE cTabela AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cBanco  AS CHARACTER NO-UNDO INIT "DICTDB".
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

    METHOD PUBLIC CHARACTER getBancoTb():
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

        EMPTY TEMP-TABLE ttCampos.
        IF cTabela = "" OR NOT lRetCampos THEN
            RETURN.

        FIND FIRST DICTDB._File
             WHERE DICTDB._File._File-Name = cTabela
             NO-LOCK NO-ERROR.
        IF NOT AVAILABLE DICTDB._File THEN
            RETURN.

        FOR EACH DICTDB._Field OF DICTDB._File NO-LOCK BY DICTDB._Field._Order:
            IF cCampos <> "" AND NOT CAN-DO(cCampos, DICTDB._Field._Field-Name) THEN
                NEXT.

            ASSIGN iOrd = iOrd + 1
                   cListaIndices = THIS-OBJECT:getIndexListForField(RECID(DICTDB._Field)).

            CREATE ttCampos.
            ASSIGN ttCampos.id          = RECID(DICTDB._Field)
                   ttCampos.ordem       = iOrd
                   ttCampos.nome        = THIS-OBJECT:substCaracter(DICTDB._Field._Field-Name)
                   ttCampos.tipo        = THIS-OBJECT:normalizeDataType(DICTDB._Field._Data-Type)
                   ttCampos.formato     = DICTDB._Field._Format
                   ttCampos.labelCampo  = DICTDB._Field._Label
                   ttCampos.extensao    = DICTDB._Field._Extent
                   ttCampos.qtDecimais  = DICTDB._Field._Decimals
                   ttCampos.obrigatorio = DICTDB._Field._Mandatory
                   ttCampos.indices     = cListaIndices
                   ttCampos.lista       = DICTDB._Field._Valexp
                   ttCampos.numRecid    = RECID(DICTDB._Field)
                   ttCampos.tabela      = DICTDB._File._File-Name
                   ttCampos.banco       = THIS-OBJECT:getBancoTb().
        END.
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

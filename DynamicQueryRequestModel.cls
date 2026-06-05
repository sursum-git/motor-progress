/*
Request model para consulta dinâmica multi-tabela.
Estrutura orientada para DSL estruturada (sem WHERE/ABL livres).
*/

CLASS DynamicQueryRequestModel:

    DEFINE PRIVATE VARIABLE cExecution AS CHARACTER NO-UNDO INIT "auto".
    DEFINE PRIVATE VARIABLE iPage      AS INTEGER   NO-UNDO INIT 1.
    DEFINE PRIVATE VARIABLE iPageSize  AS INTEGER   NO-UNDO INIT 50.
    DEFINE PRIVATE VARIABLE cDb       AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cPipelineVer AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cRawRequest AS LONGCHAR NO-UNDO.

    DEFINE PRIVATE TEMP-TABLE ttSource NO-UNDO
        FIELD sourceOrder    AS INTEGER
        FIELD tableName      AS CHARACTER
        FIELD tableAlias     AS CHARACTER
        FIELD tableBanco     AS CHARACTER
        FIELD requestedFields AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttJoin NO-UNDO
        FIELD joinOrder      AS INTEGER
        FIELD joinType       AS CHARACTER  /* INNER | LEFT */
        FIELD leftSource     AS CHARACTER
        FIELD leftField      AS CHARACTER
        FIELD rightSource    AS CHARACTER
        FIELD rightField     AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttSelect NO-UNDO
        FIELD selectOrder    AS INTEGER
        FIELD sourceAlias    AS CHARACTER
        FIELD fieldName      AS CHARACTER
        FIELD outputAlias    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttFilter NO-UNDO
        FIELD filterOrder    AS INTEGER
        FIELD sourceAlias    AS CHARACTER
        FIELD fieldName      AS CHARACTER
        FIELD operator       AS CHARACTER
        FIELD valueChar      AS CHARACTER
        FIELD valueToChar    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttOrderBy NO-UNDO
        FIELD orderOrder     AS INTEGER
        FIELD sourceAlias    AS CHARACTER
        FIELD fieldName      AS CHARACTER
        FIELD direction      AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPipelineStep NO-UNDO
        FIELD stepOrder      AS INTEGER
        FIELD stepType       AS CHARACTER
        FIELD stepPayload    AS CHARACTER
        FIELD stepRaw        AS CHARACTER.

    CONSTRUCTOR PUBLIC DynamicQueryRequestModel():
        EMPTY TEMP-TABLE ttSource.
        EMPTY TEMP-TABLE ttJoin.
        EMPTY TEMP-TABLE ttSelect.
        EMPTY TEMP-TABLE ttFilter.
        EMPTY TEMP-TABLE ttOrderBy.
        EMPTY TEMP-TABLE ttPipelineStep.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID clear():
        EMPTY TEMP-TABLE ttSource.
        EMPTY TEMP-TABLE ttJoin.
        EMPTY TEMP-TABLE ttSelect.
        EMPTY TEMP-TABLE ttFilter.
        EMPTY TEMP-TABLE ttOrderBy.
        EMPTY TEMP-TABLE ttPipelineStep.
        ASSIGN iPage = 1.
        ASSIGN iPageSize = 50.
        ASSIGN cExecution = "auto".
        ASSIGN cDb = "".
        ASSIGN cPipelineVer = "".
        ASSIGN cRawRequest = "".
    END METHOD.

    METHOD PUBLIC VOID setExecution(INPUT pcExecution AS CHARACTER):
        ASSIGN cExecution = pcExecution.
    END METHOD.

    METHOD PUBLIC CHARACTER getExecution():
        RETURN cExecution.
    END METHOD.

    METHOD PUBLIC VOID setPagination(INPUT piPage AS INTEGER, INPUT piPageSize AS INTEGER):
        IF piPage > 0 THEN
            ASSIGN iPage = piPage.
        IF piPageSize > 0 THEN
            ASSIGN iPageSize = piPageSize.
    END METHOD.

    METHOD PUBLIC INTEGER getPage():
        RETURN iPage.
    END METHOD.

    METHOD PUBLIC INTEGER getPageSize():
        RETURN iPageSize.
    END METHOD.

    METHOD PUBLIC LOGICAL isMultiSource():
        RETURN THIS-OBJECT:getSourceCount() > 1.
    END METHOD.

    METHOD PUBLIC LOGICAL hasExecutionAsync():
        RETURN LCASE(cExecution) = "async".
    END METHOD.

    METHOD PUBLIC VOID setDefaultBanco(INPUT pcBanco AS CHARACTER):
        ASSIGN cDb = pcBanco.
    END METHOD.

    METHOD PUBLIC CHARACTER getDefaultBanco():
        RETURN cDb.
    END METHOD.

    METHOD PUBLIC VOID setPipelineVersion(INPUT pcVersion AS CHARACTER):
        ASSIGN cPipelineVer = pcVersion.
    END METHOD.

    METHOD PUBLIC CHARACTER getPipelineVersion():
        RETURN cPipelineVer.
    END METHOD.

    METHOD PUBLIC VOID setRawRequest(INPUT pcRawRequest AS LONGCHAR):
        ASSIGN cRawRequest = pcRawRequest.
    END METHOD.

    METHOD PUBLIC LONGCHAR getRawRequest():
        RETURN cRawRequest.
    END METHOD.

    METHOD PUBLIC VOID addSource(
        INPUT pcTableName AS CHARACTER,
        INPUT pcAlias     AS CHARACTER,
        INPUT pcBanco     AS CHARACTER,
        INPUT pcCampos    AS CHARACTER):

        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        ASSIGN iOrd = 1.
        FOR EACH ttSource:
            ASSIGN iOrd = iOrd + 1.
        END.

        CREATE ttSource.
        ASSIGN ttSource.sourceOrder    = iOrd
               ttSource.tableName      = pcTableName
               ttSource.tableAlias     = pcAlias
               ttSource.tableBanco     = IF pcBanco <> '' THEN pcBanco ELSE cDb
               ttSource.requestedFields = pcCampos.
    END METHOD.

    METHOD PUBLIC VOID addJoin(
        INPUT pcType      AS CHARACTER,
        INPUT pcLeftAlias AS CHARACTER,
        INPUT pcLeftField AS CHARACTER,
        INPUT pcRightAlias AS CHARACTER,
        INPUT pcRightField AS CHARACTER):

        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        ASSIGN iOrd = 1.
        FOR EACH ttJoin:
            ASSIGN iOrd = iOrd + 1.
        END.

        CREATE ttJoin.
        ASSIGN ttJoin.joinOrder   = iOrd
               ttJoin.joinType    = pcType
               ttJoin.leftSource  = pcLeftAlias
               ttJoin.leftField   = pcLeftField
               ttJoin.rightSource = pcRightAlias
               ttJoin.rightField  = pcRightField.
    END METHOD.

    METHOD PUBLIC VOID addSelectField(
        INPUT pcSourceAlias AS CHARACTER,
        INPUT pcFieldName   AS CHARACTER,
        INPUT pcOutputAlias AS CHARACTER):

        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        ASSIGN iOrd = 1.
        FOR EACH ttSelect:
            ASSIGN iOrd = iOrd + 1.
        END.

        CREATE ttSelect.
        ASSIGN ttSelect.selectOrder = iOrd
               ttSelect.sourceAlias = pcSourceAlias
               ttSelect.fieldName   = pcFieldName
               ttSelect.outputAlias = pcOutputAlias.
    END METHOD.

    METHOD PUBLIC VOID addFilter(
        INPUT pcSourceAlias AS CHARACTER,
        INPUT pcFieldName   AS CHARACTER,
        INPUT pcOperator    AS CHARACTER,
        INPUT pcValue       AS CHARACTER,
        INPUT pcValueTo     AS CHARACTER):

        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        ASSIGN iOrd = 1.
        FOR EACH ttFilter:
            ASSIGN iOrd = iOrd + 1.
        END.

        CREATE ttFilter.
        ASSIGN ttFilter.filterOrder = iOrd
               ttFilter.sourceAlias = pcSourceAlias
               ttFilter.fieldName   = pcFieldName
               ttFilter.operator    = pcOperator
               ttFilter.valueChar   = pcValue
               ttFilter.valueToChar = pcValueTo.
    END METHOD.

    METHOD PUBLIC VOID addOrder(
        INPUT pcSourceAlias AS CHARACTER,
        INPUT pcFieldName   AS CHARACTER,
        INPUT pcDirection   AS CHARACTER):

        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        ASSIGN iOrd = 1.
        FOR EACH ttOrderBy:
            ASSIGN iOrd = iOrd + 1.
        END.

        CREATE ttOrderBy.
        ASSIGN ttOrderBy.orderOrder = iOrd
               ttOrderBy.sourceAlias = pcSourceAlias
               ttOrderBy.fieldName   = pcFieldName
               ttOrderBy.direction  = IF pcDirection = "" THEN "asc" ELSE pcDirection.
    END METHOD.

    METHOD PUBLIC VOID addPipelineStep(
        INPUT pcStepType AS CHARACTER,
        INPUT pcStepPayload AS CHARACTER,
        INPUT pcStepRaw AS CHARACTER):

        DEFINE VARIABLE iOrd AS INTEGER NO-UNDO.
        ASSIGN iOrd = 1.
        FOR EACH ttPipelineStep:
            ASSIGN iOrd = iOrd + 1.
        END.

        CREATE ttPipelineStep.
        ASSIGN ttPipelineStep.stepOrder   = iOrd
               ttPipelineStep.stepType    = pcStepType
               ttPipelineStep.stepPayload = pcStepPayload
               ttPipelineStep.stepRaw     = pcStepRaw.
    END METHOD.

    METHOD PUBLIC INTEGER getSourceCount():
        DEFINE VARIABLE iQtd AS INTEGER NO-UNDO.
        FOR EACH ttSource:
            ASSIGN iQtd = iQtd + 1.
        END.
        RETURN iQtd.
    END METHOD.

    METHOD PUBLIC VOID getSources(OUTPUT TABLE FOR ttSource poSource):
        EMPTY TEMP-TABLE poSource.
        FOR EACH ttSource:
            CREATE poSource.
            BUFFER-COPY ttSource TO poSource.
        END.
    END METHOD.

    METHOD PUBLIC VOID getJoins(OUTPUT TABLE FOR ttJoin poJoin):
        EMPTY TEMP-TABLE poJoin.
        FOR EACH ttJoin:
            CREATE poJoin.
            BUFFER-COPY ttJoin TO poJoin.
        END.
    END METHOD.

    METHOD PUBLIC VOID getSelects(OUTPUT TABLE FOR ttSelect poSelect):
        EMPTY TEMP-TABLE poSelect.
        FOR EACH ttSelect:
            CREATE poSelect.
            BUFFER-COPY ttSelect TO poSelect.
        END.
    END METHOD.

    METHOD PUBLIC VOID getFilters(OUTPUT TABLE FOR ttFilter poFilter):
        EMPTY TEMP-TABLE poFilter.
        FOR EACH ttFilter:
            CREATE poFilter.
            BUFFER-COPY ttFilter TO poFilter.
        END.
    END METHOD.

    METHOD PUBLIC VOID getOrders(OUTPUT TABLE FOR ttOrderBy poOrder):
        EMPTY TEMP-TABLE poOrder.
        FOR EACH ttOrderBy:
            CREATE poOrder.
            BUFFER-COPY ttOrderBy TO poOrder.
        END.
    END METHOD.

    METHOD PUBLIC VOID getPipelineSteps(OUTPUT TABLE FOR ttPipelineStep poStep):
        EMPTY TEMP-TABLE poStep.
        FOR EACH ttPipelineStep:
            CREATE poStep.
            BUFFER-COPY ttPipelineStep TO poStep.
        END.
    END METHOD.

    METHOD PUBLIC VOID addLegacySingleSource(
        INPUT pcTableName AS CHARACTER,
        INPUT pcBanco AS CHARACTER,
        INPUT pcCampos AS CHARACTER):

        DEFINE VARIABLE cAlias AS CHARACTER NO-UNDO.
        ASSIGN cAlias = "".
        EMPTY TEMP-TABLE ttSource.
        THIS-OBJECT:addSource(pcTableName, cAlias, pcBanco, pcCampos).
    END METHOD.

END CLASS.

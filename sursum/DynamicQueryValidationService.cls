/*
Validação da DSL de consulta dinâmica multi-tabela.
Regras:
  - Fonte e campo existentes no dicionário (via boMetaDados).
  - Bloqueio de tabela e campo por padrão.
  - Sem SQL/ABL livre e sem identificadores inseguros.
  - Operador compatível com tipo e paginação com limite.
*/

CLASS DynamicQueryValidationService:
    {esbo/ttCampos.i}

    DEFINE PRIVATE VARIABLE oMeta AS DynamicMetadataService NO-UNDO.
    DEFINE PRIVATE VARIABLE iMaxPageSize AS INTEGER NO-UNDO INIT 500.
    DEFINE PRIVATE VARIABLE cBlockedTablePatterns AS CHARACTER NO-UNDO INIT "_*,*sys*,*dba*".
    DEFINE PRIVATE VARIABLE cBlockedFieldPatterns AS CHARACTER NO-UNDO INIT "*senha*,*password*,*token*,*secret*,*hash*,*api_key*".
    DEFINE PRIVATE VARIABLE cForbiddenTokens AS CHARACTER NO-UNDO INIT ";,'""(){}[]\`~!@\#$%^&+=".
    DEFINE PRIVATE VARIABLE cAllowedJoinTypes AS CHARACTER NO-UNDO INIT "inner,left".
    DEFINE PRIVATE VARIABLE cAllowedPipeline AS CHARACTER NO-UNDO INIT "source,join,select,filter,sort,limit,output".
    DEFINE PRIVATE VARIABLE iMinPage AS INTEGER NO-UNDO INIT 1.
    DEFINE PRIVATE VARIABLE iMinPageSize AS INTEGER NO-UNDO INIT 1.

    DEFINE PRIVATE TEMP-TABLE ttAliasMap NO-UNDO
        FIELD sourceAlias AS CHARACTER
        FIELD tableName   AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttResolvedField NO-UNDO
        FIELD sourceAlias AS CHARACTER
        FIELD tableName   AS CHARACTER
        FIELD fieldName   AS CHARACTER
        FIELD dataType    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttReqSource NO-UNDO
        FIELD sourceOrder    AS INTEGER
        FIELD tableName      AS CHARACTER
        FIELD tableAlias     AS CHARACTER
        FIELD tableBanco     AS CHARACTER
        FIELD requestedFields AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttReqJoin NO-UNDO
        FIELD joinOrder      AS INTEGER
        FIELD joinType       AS CHARACTER
        FIELD leftSource     AS CHARACTER
        FIELD leftField      AS CHARACTER
        FIELD rightSource    AS CHARACTER
        FIELD rightField     AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttReqSelect NO-UNDO
        FIELD selectOrder    AS INTEGER
        FIELD sourceAlias    AS CHARACTER
        FIELD fieldName      AS CHARACTER
        FIELD outputAlias    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttReqFilter NO-UNDO
        FIELD filterOrder    AS INTEGER
        FIELD sourceAlias    AS CHARACTER
        FIELD fieldName      AS CHARACTER
        FIELD operator       AS CHARACTER
        FIELD valueChar      AS CHARACTER
        FIELD valueToChar    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttReqOrder NO-UNDO
        FIELD orderOrder     AS INTEGER
        FIELD sourceAlias    AS CHARACTER
        FIELD fieldName      AS CHARACTER
        FIELD direction      AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttReqStep NO-UNDO
        FIELD stepOrder      AS INTEGER
        FIELD stepType       AS CHARACTER
        FIELD stepPayload    AS CHARACTER
        FIELD stepRaw        AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttMeta LIKE ttCampos.

    DEFINE PRIVATE VARIABLE lValidated AS LOGICAL NO-UNDO.

    CONSTRUCTOR PUBLIC DynamicQueryValidationService():
        ASSIGN oMeta = NEW DynamicMetadataService().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC DynamicQueryValidationService():
        IF VALID-OBJECT(oMeta) THEN
            DELETE OBJECT oMeta.
    END DESTRUCTOR.

    METHOD PUBLIC LOGICAL validate(
        INPUT  poRequest        AS DynamicQueryRequestModel,
        OUTPUT pcErrorCode      AS CHARACTER,
        OUTPUT pcErrorMessage   AS CHARACTER,
        OUTPUT pcErrorDetail    AS CHARACTER):

        DEFINE VARIABLE iPage       AS INTEGER NO-UNDO.
        DEFINE VARIABLE iPageSize   AS INTEGER NO-UNDO.
        DEFINE VARIABLE iSourceCnt  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cAlias      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRawField   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cType       AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lNoAlias     AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lHasJoin              AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lHasRequestedSelect   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE cStepType   AS CHARACTER NO-UNDO.

        ASSIGN iPage     = poRequest:getPage()
               iPageSize = poRequest:getPageSize()
               iSourceCnt = 0.

        EMPTY TEMP-TABLE ttReqSource.
        EMPTY TEMP-TABLE ttReqJoin.
        EMPTY TEMP-TABLE ttReqSelect.
        EMPTY TEMP-TABLE ttReqFilter.
        EMPTY TEMP-TABLE ttReqOrder.
        EMPTY TEMP-TABLE ttReqStep.
        EMPTY TEMP-TABLE ttMeta.
        EMPTY TEMP-TABLE ttAliasMap.
        EMPTY TEMP-TABLE ttResolvedField.

        IF iPage < iMinPage THEN DO:
            ASSIGN pcErrorCode = "INVALID_PAGE"
                   pcErrorMessage = "page invalido."
                   pcErrorDetail = "page=" + STRING(iPage).
            ASSIGN lValidated = NO.
            RETURN NO.
        END.

        IF iPageSize < iMinPageSize OR iPageSize > iMaxPageSize THEN DO:
            ASSIGN pcErrorCode = "PAGE_SIZE_EXCEEDED"
                   pcErrorMessage = "pageSize fora do limite."
                   pcErrorDetail = "pageSize=" + STRING(iPageSize) + ", max=" + STRING(iMaxPageSize).
            ASSIGN lValidated = NO.
            RETURN NO.
        END.

        poRequest:getSources(OUTPUT TABLE ttReqSource).
        IF NOT CAN-FIND(FIRST ttReqSource) THEN DO:
            ASSIGN pcErrorCode = "INVALID_TABLE"
                   pcErrorMessage = "Nenhuma fonte informada."
                   pcErrorDetail = "sources[] vazio".
            ASSIGN lValidated = NO.
            RETURN NO.
        END.

        FOR EACH ttReqSource:
            ASSIGN iSourceCnt = iSourceCnt + 1.
        END.
        ASSIGN lNoAlias = (iSourceCnt > 1).

        FOR EACH ttReqSource:
            ASSIGN cAlias = ttReqSource.tableAlias.
            ASSIGN cTable = ttReqSource.tableName.

            IF cTable = "" OR NOT THIS-OBJECT:isIdentifierSafe(cTable) THEN DO:
                ASSIGN pcErrorCode = "INVALID_TABLE"
                       pcErrorMessage = "Identificador de tabela invalido."
                       pcErrorDetail = "table=" + cTable.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF THIS-OBJECT:isTableBlocked(cTable) THEN DO:
                ASSIGN pcErrorCode = "BLOCKED_TABLE"
                       pcErrorMessage = "Tabela bloqueada por politica."
                       pcErrorDetail = "table=" + cTable.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF cAlias = "" THEN
                ASSIGN cAlias = cTable.
            ELSE
                IF THIS-OBJECT:isIdentifierSafe(cAlias) = NO THEN DO:
                    ASSIGN pcErrorCode = "INVALID_TABLE"
                           pcErrorMessage = "Identificador de alias invalido."
                           pcErrorDetail = "alias=" + cAlias.
                    ASSIGN lValidated = NO.
                    RETURN NO.
                END.

            IF CAN-FIND(FIRST ttAliasMap WHERE sourceAlias = cAlias) THEN DO:
                ASSIGN pcErrorCode = "INVALID_TABLE"
                       pcErrorMessage = "Alias duplicado."
                       pcErrorDetail = "alias=" + cAlias.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF lNoAlias AND ttReqSource.tableAlias = "" THEN DO:
                ASSIGN pcErrorCode = "INVALID_TABLE"
                       pcErrorMessage = "Alias obrigatorio com multiplas fontes."
                       pcErrorDetail = "table=" + cTable.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            oMeta:carregarCampos(cTable, "").
            oMeta:getCampos(OUTPUT TABLE ttMeta).
            IF NOT CAN-FIND(FIRST ttMeta) THEN DO:
                ASSIGN pcErrorCode = "INVALID_TABLE"
                       pcErrorMessage = "Tabela nao encontrada."
                       pcErrorDetail = "table=" + cTable.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            CREATE ttAliasMap.
            ASSIGN ttAliasMap.sourceAlias = cAlias
                   ttAliasMap.tableName   = cTable.

            FOR EACH ttMeta:
                CREATE ttResolvedField.
                ASSIGN ttResolvedField.sourceAlias = cAlias
                       ttResolvedField.tableName = cTable
                       ttResolvedField.fieldName = ttMeta.nome
                       ttResolvedField.dataType = ttMeta.tipo.
            END.

            IF ttReqSource.requestedFields <> "" THEN DO:
                THIS-OBJECT:validateRequestedFields(cAlias, ttReqSource.requestedFields, OUTPUT pcErrorCode, OUTPUT pcErrorMessage, OUTPUT pcErrorDetail).
                IF pcErrorCode <> "" THEN DO:
                    ASSIGN lValidated = NO.
                    RETURN NO.
                END.
                ASSIGN lHasRequestedSelect = YES.
            END.
        END.

        poRequest:getJoins(OUTPUT TABLE ttReqJoin).
        FOR EACH ttReqJoin:
            ASSIGN lHasJoin = YES.
            IF NOT THIS-OBJECT:isAllowedJoinType(ttReqJoin.joinType) THEN DO:
                ASSIGN pcErrorCode = "INVALID_OPERATOR"
                       pcErrorMessage = "Tipo de join invalido."
                       pcErrorDetail = "joinType=" + ttReqJoin.joinType.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF NOT THIS-OBJECT:aliasExists(ttReqJoin.leftSource) OR NOT THIS-OBJECT:aliasExists(ttReqJoin.rightSource) THEN DO:
                ASSIGN pcErrorCode = "INVALID_TABLE"
                       pcErrorMessage = "Alias inexistente em join."
                       pcErrorDetail = ttReqJoin.leftSource + "/" + ttReqJoin.rightSource.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF THIS-OBJECT:resolveFieldType(ttReqJoin.leftSource, ttReqJoin.leftField) = "" THEN DO:
                ASSIGN pcErrorCode = "INVALID_FIELD"
                       pcErrorMessage = "Campo de join invalido."
                       pcErrorDetail = ttReqJoin.leftSource + "." + ttReqJoin.leftField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF THIS-OBJECT:resolveFieldType(ttReqJoin.rightSource, ttReqJoin.rightField) = "" THEN DO:
                ASSIGN pcErrorCode = "INVALID_FIELD"
                       pcErrorMessage = "Campo de join invalido."
                       pcErrorDetail = ttReqJoin.rightSource + "." + ttReqJoin.rightField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.
        END.

        IF iSourceCnt > 1 AND lHasJoin = NO THEN DO:
            ASSIGN pcErrorCode = "INVALID_QUERY"
                   pcErrorMessage = "Consulta com multiplas fontes exige join."
                   pcErrorDetail = "sources=" + STRING(iSourceCnt).
            ASSIGN lValidated = NO.
            RETURN NO.
        END.

        poRequest:getSelects(OUTPUT TABLE ttReqSelect).
        IF NOT CAN-FIND(FIRST ttReqSelect) AND lHasRequestedSelect = NO THEN DO:
            ASSIGN pcErrorCode = "INVALID_FIELD"
                   pcErrorMessage = "Nenhum campo de selecao informado."
                   pcErrorDetail = "Informe select ou campos da fonte.".
            ASSIGN lValidated = NO.
            RETURN NO.
        END.

        FOR EACH ttReqSelect:
            ASSIGN cRawField = ttReqSelect.fieldName.
            IF (THIS-OBJECT:resolveFieldType(ttReqSelect.sourceAlias, cRawField) = "") THEN DO:
                ASSIGN pcErrorCode = "INVALID_FIELD"
                       pcErrorMessage = "Campo de selecao inexistente."
                       pcErrorDetail = ttReqSelect.sourceAlias + "." + cRawField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            ASSIGN cType = THIS-OBJECT:resolveFieldType(ttReqSelect.sourceAlias, cRawField).
            IF THIS-OBJECT:isFieldBlocked(cType, cRawField) THEN DO:
                ASSIGN pcErrorCode = "BLOCKED_FIELD"
                       pcErrorMessage = "Campo bloqueado."
                       pcErrorDetail = "field=" + cRawField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.
        END.

        poRequest:getFilters(OUTPUT TABLE ttReqFilter).
        FOR EACH ttReqFilter:
            ASSIGN cRawField = ttReqFilter.fieldName.
            ASSIGN cType = THIS-OBJECT:resolveFieldType(ttReqFilter.sourceAlias, cRawField).
            IF cType = "" THEN DO:
                ASSIGN pcErrorCode = "INVALID_FIELD"
                       pcErrorMessage = "Campo de filtro inexistente."
                       pcErrorDetail = ttReqFilter.sourceAlias + "." + cRawField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF THIS-OBJECT:isFieldBlocked(cType, cRawField) THEN DO:
                ASSIGN pcErrorCode = "BLOCKED_FIELD"
                       pcErrorMessage = "Campo bloqueado."
                       pcErrorDetail = "field=" + cRawField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF NOT THIS-OBJECT:isOperatorAllowed(cType, ttReqFilter.operator) THEN DO:
                ASSIGN pcErrorCode = "INVALID_OPERATOR"
                       pcErrorMessage = "Operador nao permitido."
                       pcErrorDetail = cType + "/" + ttReqFilter.operator.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            IF LC(ttReqFilter.operator) = "between" AND (ttReqFilter.valueToChar = "" OR ttReqFilter.valueToChar = ?) THEN DO:
                ASSIGN pcErrorCode = "INVALID_FILTER"
                       pcErrorMessage = "between exige valor final."
                       pcErrorDetail = ttReqFilter.sourceAlias + "." + cRawField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.
        END.

        poRequest:getOrders(OUTPUT TABLE ttReqOrder).
        FOR EACH ttReqOrder:
            IF NOT CAN-DO("asc,desc", LC(ttReqOrder.direction)) THEN DO:
                ASSIGN pcErrorCode = "INVALID_FILTER"
                       pcErrorMessage = "Direcao invalida."
                       pcErrorDetail = ttReqOrder.direction.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.

            ASSIGN cRawField = ttReqOrder.fieldName.
            IF THIS-OBJECT:resolveFieldType(ttReqOrder.sourceAlias, cRawField) = "" THEN DO:
                ASSIGN pcErrorCode = "INVALID_FIELD"
                       pcErrorMessage = "Campo de ordenacao inexistente."
                       pcErrorDetail = ttReqOrder.sourceAlias + "." + cRawField.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.
        END.

        poRequest:getPipelineSteps(OUTPUT TABLE ttReqStep).
        FOR EACH ttReqStep:
            ASSIGN cStepType = LC(ttReqStep.stepType).
            IF CAN-DO(cAllowedPipeline, cStepType) = NO THEN DO:
                ASSIGN pcErrorCode = "INVALID_FILTER"
                       pcErrorMessage = "Step de pipeline desconhecido."
                       pcErrorDetail = cStepType.
                ASSIGN lValidated = NO.
                RETURN NO.
            END.
        END.

        ASSIGN pcErrorCode = "" pcErrorMessage = "" pcErrorDetail = "".
        ASSIGN lValidated = YES.
        RETURN YES.
    END METHOD.

    METHOD PUBLIC VOID getResolvedFields(OUTPUT TABLE ttResolvedField):
    END METHOD.

    METHOD PUBLIC CHARACTER resolveFieldType(
        INPUT pcSourceAlias AS CHARACTER,
        INPUT pcFieldRef    AS CHARACTER):
        DEFINE VARIABLE cAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iCnt AS INTEGER NO-UNDO.

        THIS-OBJECT:splitFieldRef(pcFieldRef, OUTPUT cAlias, OUTPUT cField).
        IF cAlias = "" THEN
            ASSIGN cAlias = pcSourceAlias.

        IF cAlias = "" THEN DO:
            FOR EACH ttAliasMap:
                ASSIGN iCnt = iCnt + 1.
            END.
            IF iCnt = 1 THEN
                FIND FIRST ttAliasMap NO-ERROR.
            ELSE
                RETURN "".
        END.

        FIND FIRST ttAliasMap
            WHERE ttAliasMap.sourceAlias = cAlias
            NO-ERROR.
        IF NOT AVAILABLE ttAliasMap THEN
            RETURN "".

        FIND FIRST ttResolvedField
            WHERE ttResolvedField.sourceAlias = ttAliasMap.sourceAlias
              AND ttResolvedField.fieldName = cField
            NO-ERROR.
        IF AVAILABLE ttResolvedField THEN
            RETURN ttResolvedField.dataType.
        RETURN "".
    END METHOD.

    METHOD PRIVATE VOID validateRequestedFields(
        INPUT pcSourceAlias  AS CHARACTER,
        INPUT pcRawFields    AS CHARACTER,
        OUTPUT pcErrorCode      AS CHARACTER,
        OUTPUT pcErrorMessage   AS CHARACTER,
        OUTPUT pcErrorDetail    AS CHARACTER):
        DEFINE VARIABLE iCont AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.

        IF pcRawFields = "" THEN RETURN.
        REPEAT iCont = 1 TO NUM-ENTRIES(pcRawFields, ","):
            ASSIGN cField = ENTRY(iCont, pcRawFields, ",").
            ASSIGN cField = TRIM(REPLACE(cField, " ", "")).
            ASSIGN cType = THIS-OBJECT:resolveFieldType(pcSourceAlias, cField).
            IF cType = "" THEN DO:
                ASSIGN pcErrorCode = "INVALID_FIELD"
                       pcErrorMessage = "Campo pedido inexistente na fonte."
                       pcErrorDetail = pcSourceAlias + "." + cField.
                RETURN.
            END.
            IF THIS-OBJECT:isFieldBlocked(cType, cField) THEN DO:
                ASSIGN pcErrorCode = "BLOCKED_FIELD"
                       pcErrorMessage = "Campo bloqueado."
                       pcErrorDetail = "field=" + cField.
                RETURN.
            END.
        END.

        ASSIGN pcErrorCode = "" pcErrorMessage = "" pcErrorDetail = "".
    END METHOD.

    METHOD PRIVATE LOGICAL aliasExists(INPUT pcAlias AS CHARACTER):
        IF pcAlias = "" THEN
            RETURN NO.
        RETURN CAN-FIND(FIRST ttAliasMap WHERE sourceAlias = pcAlias).
    END METHOD.

    METHOD PRIVATE LOGICAL isAllowedJoinType(INPUT pcType AS CHARACTER):
        DEFINE VARIABLE cJoinType AS CHARACTER NO-UNDO.
        ASSIGN cJoinType = LC(TRIM(pcType)).
        IF cJoinType = "" THEN ASSIGN cJoinType = "inner".
        RETURN CAN-DO(cAllowedJoinTypes, cJoinType).
    END METHOD.

    METHOD PRIVATE LOGICAL isIdentifierSafe(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE iToken AS INTEGER NO-UNDO.
        DEFINE VARIABLE cBad  AS CHARACTER NO-UNDO.
        IF pcValue = "" THEN RETURN NO.
        IF INDEX(pcValue, " ") > 0 THEN RETURN NO.

        DO iToken = 1 TO LENGTH(cForbiddenTokens):
            ASSIGN cBad = SUBSTRING(cForbiddenTokens, iToken, 1).
            IF INDEX(pcValue, cBad) > 0 THEN RETURN NO.
        END.

        IF INDEX(pcValue, "--") > 0 THEN RETURN NO.
        RETURN YES.
    END METHOD.

    METHOD PRIVATE LOGICAL isTableBlocked(INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE iCont AS INTEGER NO-UNDO.
        DEFINE VARIABLE cPattern AS CHARACTER NO-UNDO.
        DO iCont = 1 TO NUM-ENTRIES(cBlockedTablePatterns, ","):
            ASSIGN cPattern = TRIM(ENTRY(iCont,cBlockedTablePatterns,",")).
            IF cPattern <> "" AND THIS-OBJECT:matchPattern(pcTable, cPattern) THEN
                RETURN YES.
        END.
        RETURN NO.
    END METHOD.

    METHOD PRIVATE LOGICAL isFieldBlocked(INPUT pcType AS CHARACTER, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE iCont AS INTEGER NO-UNDO.
        DEFINE VARIABLE cPattern AS CHARACTER NO-UNDO.
        ASSIGN pcField = LC(pcField).
        DO iCont = 1 TO NUM-ENTRIES(cBlockedFieldPatterns, ","):
            ASSIGN cPattern = TRIM(ENTRY(iCont,cBlockedFieldPatterns,",")).
            IF cPattern = "" THEN NEXT.
            IF THIS-OBJECT:matchPattern(pcField, cPattern) THEN
                RETURN YES.
        END.
        RETURN NO.
    END METHOD.

    METHOD PRIVATE LOGICAL matchPattern(INPUT pcValue AS CHARACTER, INPUT pcPattern AS CHARACTER):
        DEFINE VARIABLE cVal AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPat AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLen AS INTEGER NO-UNDO.
        IF pcPattern = "" THEN RETURN NO.

        ASSIGN cVal = LC(TRIM(pcValue))
               cPat = LC(TRIM(pcPattern))
               iLen = LENGTH(cPat).

        IF cPat = "*" THEN RETURN YES.

        IF SUBSTRING(cPat, 1, 1) = "*" AND SUBSTRING(cPat, iLen, 1) = "*" THEN
            RETURN INDEX(cVal, SUBSTRING(cPat, 2, iLen - 2)) > 0.

        IF SUBSTRING(cPat, 1, 1) = "*" THEN
            RETURN SUBSTRING(cVal, MAX(1, LENGTH(cVal) - iLen + 2), iLen - 1) = SUBSTRING(cPat, 2).

        IF SUBSTRING(cPat, iLen, 1) = "*" THEN
            RETURN SUBSTRING(cVal, 1, iLen - 1) = SUBSTRING(cPat, 1, iLen - 1).

        RETURN cVal = cPat.
    END METHOD.

    METHOD PRIVATE LOGICAL isOperatorAllowed(INPUT pcType AS CHARACTER, INPUT pcOperator AS CHARACTER):
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOp  AS CHARACTER NO-UNDO.
        ASSIGN cType = LC(pcType).
        ASSIGN cOp = LC(TRIM(pcOperator)).
        IF cOp = "" THEN RETURN NO.

        CASE cType:
            WHEN "character" THEN
                RETURN CAN-DO("=,<>,begins,contains", cOp).
            WHEN "integer" THEN
                RETURN CAN-DO("=,<>,>,>=,<,<=,between", cOp).
            WHEN "int64" THEN
                RETURN CAN-DO("=,<>,>,>=,<,<=,between", cOp).
            WHEN "decimal" THEN
                RETURN CAN-DO("=,<>,>,>=,<,<=,between", cOp).
            WHEN "date" THEN
                RETURN CAN-DO("=,<>,>,>=,<,<=,between", cOp).
            WHEN "datetime" THEN
                RETURN CAN-DO("=,<>,>,>=,<,<=,between", cOp).
            WHEN "logical" THEN
                RETURN cOp = "=".
            OTHERWISE
                RETURN NO.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID splitFieldRef(
        INPUT  pcFieldRef AS CHARACTER,
        OUTPUT pcSourceAlias AS CHARACTER,
        OUTPUT pcFieldName   AS CHARACTER):
        IF INDEX(pcFieldRef, ".") > 0 THEN DO:
            ASSIGN pcSourceAlias = ENTRY(1, pcFieldRef, ".")
                   pcFieldName  = ENTRY(2, pcFieldRef, ".").
        END.
        ELSE DO:
            ASSIGN pcSourceAlias = ""
                   pcFieldName  = pcFieldRef.
        END.
    END METHOD.

    METHOD PUBLIC INTEGER getMaxPageSize():
        RETURN iMaxPageSize.
    END METHOD.

    METHOD PUBLIC VOID setMaxPageSize(INPUT piValue AS INTEGER):
        IF piValue > 0 THEN
            ASSIGN iMaxPageSize = piValue.
    END METHOD.

    METHOD PUBLIC CHARACTER getBlockedTablePatterns():
        RETURN cBlockedTablePatterns.
    END METHOD.

    METHOD PUBLIC VOID setBlockedTablePatterns(INPUT pcPatterns AS CHARACTER):
        ASSIGN cBlockedTablePatterns = pcPatterns.
    END METHOD.

    METHOD PUBLIC CHARACTER getBlockedFieldPatterns():
        RETURN cBlockedFieldPatterns.
    END METHOD.

    METHOD PUBLIC VOID setBlockedFieldPatterns(INPUT pcPatterns AS CHARACTER):
        ASSIGN cBlockedFieldPatterns = pcPatterns.
    END METHOD.

END CLASS.

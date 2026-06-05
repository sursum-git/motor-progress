/*
Transforma o request validado em uma estrutura de execução:
- fontes com alias/tabela
- filtros e joins compilados como cláusulas seguras
- ordenação e projeção já prontas para Query-PREPARE
*/

CLASS DynamicQueryPlanBuilder:

    DEFINE PRIVATE VARIABLE cFromClause  AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cWhereClause AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cOrderClause AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cSelectClause AS CHARACTER NO-UNDO.

    DEFINE PRIVATE TEMP-TABLE ttSourceMap NO-UNDO
        FIELD requestAlias AS CHARACTER
        FIELD sourceAlias  AS CHARACTER
        FIELD tableName    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanSource NO-UNDO
        FIELD sourceOrder AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceBanco AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanSelect NO-UNDO
        FIELD fieldOrder  AS INTEGER
        FIELD outputAlias AS CHARACTER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceField AS CHARACTER
        FIELD dataType    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanFilter NO-UNDO
        FIELD filterOrder AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceField AS CHARACTER
        FIELD operator    AS CHARACTER
        FIELD valueChar   AS CHARACTER
        FIELD valueToChar AS CHARACTER
        FIELD dataType    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanJoin NO-UNDO
        FIELD joinOrder  AS INTEGER
        FIELD joinType   AS CHARACTER
        FIELD leftAlias  AS CHARACTER
        FIELD leftField  AS CHARACTER
        FIELD rightAlias AS CHARACTER
        FIELD rightField AS CHARACTER
        FIELD leftTable  AS CHARACTER
        FIELD rightTable AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanOrder NO-UNDO
        FIELD orderOrder  AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceField AS CHARACTER
        FIELD direction   AS CHARACTER.

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

    METHOD PUBLIC VOID build(INPUT poRequest AS DynamicQueryRequestModel, INPUT TABLE ttResolvedField):
        DEFINE VARIABLE cAlias   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cBanco   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cField   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOut     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cExpr    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOrder   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPos     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cLeftAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLeftTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRightAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRightTable AS CHARACTER NO-UNDO.

        EMPTY TEMP-TABLE ttReqSource.
        EMPTY TEMP-TABLE ttReqJoin.
        EMPTY TEMP-TABLE ttReqSelect.
        EMPTY TEMP-TABLE ttReqFilter.
        EMPTY TEMP-TABLE ttReqOrder.
        EMPTY TEMP-TABLE ttSourceMap.
        EMPTY TEMP-TABLE ttPlanSource.
        EMPTY TEMP-TABLE ttPlanSelect.
        EMPTY TEMP-TABLE ttPlanFilter.
        EMPTY TEMP-TABLE ttPlanJoin.
        EMPTY TEMP-TABLE ttPlanOrder.
        ASSIGN cFromClause = ""
               cWhereClause = ""
               cOrderClause = ""
               cSelectClause = "".

        poRequest:getSources(OUTPUT TABLE ttReqSource).
        FOR EACH ttReqSource:
            ASSIGN cAlias = IF TRIM(ttReqSource.tableAlias) = "" THEN ttReqSource.tableName ELSE ttReqSource.tableAlias
                   cTable = ttReqSource.tableName
                   cBanco = ttReqSource.tableBanco.
            CREATE ttPlanSource.
            ASSIGN ttPlanSource.sourceOrder = ttReqSource.sourceOrder
                   ttPlanSource.sourceAlias = cAlias
                   ttPlanSource.sourceTable = cTable
                   ttPlanSource.sourceBanco = cBanco.

            CREATE ttSourceMap.
            ASSIGN ttSourceMap.requestAlias = ttReqSource.tableAlias
                   ttSourceMap.sourceAlias  = cAlias
                   ttSourceMap.tableName    = cTable.

            IF cFromClause = "" THEN
                ASSIGN cFromClause = "FOR EACH " + THIS-OBJECT:getSourceExpression(cAlias, cTable, cBanco) + " NO-LOCK".
            ELSE
                ASSIGN cFromClause = cFromClause + ", EACH " + THIS-OBJECT:getSourceExpression(cAlias, cTable, cBanco) + " NO-LOCK".
        END.

        poRequest:getSelects(OUTPUT TABLE ttReqSelect).
        IF NOT CAN-FIND(FIRST ttReqSelect) THEN DO:
            FOR EACH ttReqSource:
                IF ttReqSource.requestedFields <> "" THEN DO:
                    REPEAT iPos = 1 TO NUM-ENTRIES(ttReqSource.requestedFields, ","):
                        ASSIGN cField = TRIM(ENTRY(iPos, ttReqSource.requestedFields, ",")).
                        IF cField = "" THEN NEXT.
                        ASSIGN cAlias = IF ttReqSource.tableAlias = "" THEN ttReqSource.tableName ELSE ttReqSource.tableAlias.
                        THIS-OBJECT:addSelectField(
                            cAlias,
                            cField,
                            cField
                        ).
                    END.
                END.
            END.
        END.
        ELSE DO:
        FOR EACH ttReqSelect:
            ASSIGN cAlias = ttReqSelect.sourceAlias.
            IF cAlias = "" THEN DO:
                FIND FIRST ttSourceMap NO-ERROR.
                IF AVAILABLE ttSourceMap THEN
                        ASSIGN cAlias = ttSourceMap.sourceAlias.
            END.
            ASSIGN cField = THIS-OBJECT:getUnqualifiedField(ttReqSelect.fieldName).
            ASSIGN cOut = IF ttReqSelect.outputAlias = "" THEN cField ELSE ttReqSelect.outputAlias.
            THIS-OBJECT:addSelectField(
                cAlias,
                cField,
                cOut
            ).
        END.
        END.
        IF cSelectClause = "" THEN
            ASSIGN cSelectClause = "*".

        poRequest:getFilters(OUTPUT TABLE ttReqFilter).
        FOR EACH ttReqFilter:
            ASSIGN cAlias = ttReqFilter.sourceAlias.
            IF cAlias = "" THEN DO:
                FIND FIRST ttSourceMap NO-ERROR.
                IF AVAILABLE ttSourceMap THEN ASSIGN cAlias = ttSourceMap.sourceAlias.
            END.
            ASSIGN cField = THIS-OBJECT:getUnqualifiedField(ttReqFilter.fieldName).
            FIND FIRST ttSourceMap WHERE ttSourceMap.sourceAlias = cAlias NO-ERROR.
            IF AVAILABLE ttSourceMap THEN DO:
                CREATE ttPlanFilter.
                ASSIGN ttPlanFilter.filterOrder = ttReqFilter.filterOrder
                       ttPlanFilter.sourceAlias = cAlias
                       ttPlanFilter.sourceTable = ttSourceMap.tableName
                       ttPlanFilter.sourceField = cField
                       ttPlanFilter.operator = ttReqFilter.operator
                       ttPlanFilter.valueChar = ttReqFilter.valueChar
                       ttPlanFilter.valueToChar = ttReqFilter.valueToChar.
                FIND FIRST ttResolvedField
                    WHERE ttResolvedField.sourceAlias = cAlias
                      AND ttResolvedField.fieldName = cField
                    NO-ERROR.
                IF AVAILABLE ttResolvedField THEN
                    ASSIGN ttPlanFilter.dataType = ttResolvedField.dataType.
                ASSIGN cExpr = THIS-OBJECT:buildFilterClause(
                    ttSourceMap.tableName,
                    cField,
                    ttReqFilter.operator,
                    ttReqFilter.valueChar,
                    ttReqFilter.valueToChar,
                    ttPlanFilter.dataType
                ).
                IF cExpr <> "" THEN DO:
                    IF cWhereClause = "" THEN
                        ASSIGN cWhereClause = cExpr.
                    ELSE
                        ASSIGN cWhereClause = cWhereClause + " AND " + cExpr.
                END.
            END.
        END.

        poRequest:getJoins(OUTPUT TABLE ttReqJoin).
        FOR EACH ttReqJoin:
            FIND FIRST ttSourceMap WHERE ttSourceMap.requestAlias = ttReqJoin.leftSource OR ttSourceMap.sourceAlias = ttReqJoin.leftSource NO-ERROR.
            IF NOT AVAILABLE ttSourceMap THEN NEXT.
            ASSIGN cLeftAlias = ttSourceMap.sourceAlias
                   cLeftTable = ttSourceMap.tableName.

            FIND FIRST ttSourceMap WHERE ttSourceMap.requestAlias = ttReqJoin.rightSource OR ttSourceMap.sourceAlias = ttReqJoin.rightSource NO-ERROR.
            IF NOT AVAILABLE ttSourceMap THEN NEXT.
            ASSIGN cRightAlias = ttSourceMap.sourceAlias
                   cRightTable = ttSourceMap.tableName.

            CREATE ttPlanJoin.
            ASSIGN ttPlanJoin.joinOrder = ttReqJoin.joinOrder
                   ttPlanJoin.joinType = ttReqJoin.joinType
                   ttPlanJoin.leftAlias = cLeftAlias
                   ttPlanJoin.leftField = ttReqJoin.leftField
                   ttPlanJoin.rightAlias = cRightAlias
                   ttPlanJoin.rightField = ttReqJoin.rightField
                   ttPlanJoin.leftTable = cLeftTable
                   ttPlanJoin.rightTable = cRightTable.

            ASSIGN cExpr = THIS-OBJECT:qualifyField(cLeftTable, ttReqJoin.leftField)
                        + " = "
                        + THIS-OBJECT:qualifyField(cRightTable, ttReqJoin.rightField).
            IF cWhereClause = "" THEN
                ASSIGN cWhereClause = cExpr.
            ELSE
                ASSIGN cWhereClause = cWhereClause + " AND " + cExpr.
        END.

        poRequest:getOrders(OUTPUT TABLE ttReqOrder).
        FOR EACH ttReqOrder:
            ASSIGN cAlias = ttReqOrder.sourceAlias.
            IF cAlias = "" THEN DO:
                FIND FIRST ttSourceMap NO-ERROR.
                IF AVAILABLE ttSourceMap THEN ASSIGN cAlias = ttSourceMap.sourceAlias.
            END.
            ASSIGN cOrder = THIS-OBJECT:getUnqualifiedField(ttReqOrder.fieldName).
            FIND FIRST ttSourceMap WHERE ttSourceMap.sourceAlias = cAlias NO-ERROR.
            IF NOT AVAILABLE ttSourceMap THEN NEXT.
            ASSIGN cField = cOrder.
            CREATE ttPlanOrder.
            ASSIGN ttPlanOrder.orderOrder = ttReqOrder.orderOrder
                   ttPlanOrder.sourceAlias = cAlias
                   ttPlanOrder.sourceTable = ttSourceMap.tableName
                   ttPlanOrder.sourceField = cField
                   ttPlanOrder.direction = THIS-OBJECT:normalizeDirection(ttReqOrder.direction).
            IF cOrderClause = "" THEN
                ASSIGN cOrderClause = THIS-OBJECT:buildOrderExpression(ttPlanOrder.sourceTable, cField, ttPlanOrder.direction).
            ELSE
                ASSIGN cOrderClause = cOrderClause + " BY " + THIS-OBJECT:buildOrderExpression(ttPlanOrder.sourceTable, cField, ttPlanOrder.direction).
        END.
    END METHOD.

    METHOD PRIVATE VOID addSelectField(
        INPUT pcSourceAlias AS CHARACTER,
        INPUT pcField      AS CHARACTER,
        INPUT pcAliasOut   AS CHARACTER):

        DEFINE VARIABLE cType  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPos AS INTEGER NO-UNDO.

        FIND FIRST ttResolvedField
            WHERE ttResolvedField.sourceAlias = pcSourceAlias
              AND ttResolvedField.fieldName = pcField
            NO-ERROR.
        IF AVAILABLE ttResolvedField THEN
            ASSIGN cType = ttResolvedField.dataType.
        ELSE
            ASSIGN cType = "".

        FIND FIRST ttPlanSelect WHERE outputAlias = pcAliasOut NO-ERROR.
        IF AVAILABLE ttPlanSelect THEN
            ASSIGN iPos = ttPlanSelect.fieldOrder + 1.

        FIND FIRST ttSourceMap WHERE ttSourceMap.sourceAlias = pcSourceAlias NO-ERROR.
        ASSIGN cTable = IF AVAILABLE ttSourceMap THEN ttSourceMap.tableName ELSE "".
        IF cTable = "" THEN
            RETURN.

        FOR EACH ttPlanSelect:
            ASSIGN iPos = MAX(iPos, ttPlanSelect.fieldOrder).
        END.

        CREATE ttPlanSelect.
        ASSIGN ttPlanSelect.fieldOrder  = iPos + 1.
        ASSIGN ttPlanSelect.outputAlias = pcAliasOut
               ttPlanSelect.sourceAlias = pcSourceAlias
               ttPlanSelect.sourceTable = cTable
               ttPlanSelect.sourceField = pcField
               ttPlanSelect.dataType    = cType.

        ASSIGN cSelectClause = IF cSelectClause = "" THEN
                    THIS-OBJECT:qualifyField(cTable, pcField) + " AS " + pcAliasOut
               ELSE
                    cSelectClause + "," + THIS-OBJECT:qualifyField(cTable, pcField) + " AS " + pcAliasOut.
    END METHOD.

    METHOD PRIVATE CHARACTER getSourceExpression(
        INPUT pcAlias  AS CHARACTER,
        INPUT pcTable  AS CHARACTER,
        INPUT pcBanco  AS CHARACTER):
        DEFINE VARIABLE cSourceExpr AS CHARACTER NO-UNDO.
        ASSIGN cSourceExpr = IF pcBanco = "" THEN pcTable ELSE pcBanco + "." + pcTable.
        RETURN cSourceExpr.
    END METHOD.

    METHOD PRIVATE CHARACTER qualifyField(INPUT pcTable AS CHARACTER, INPUT pcField AS CHARACTER):
        RETURN pcTable + "." + pcField.
    END METHOD.

    METHOD PRIVATE CHARACTER getUnqualifiedField(INPUT pcValue AS CHARACTER):
        IF INDEX(pcValue, ".") > 0 THEN
            RETURN ENTRY(2, pcValue, ".").
        RETURN TRIM(pcValue).
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeDirection(INPUT pcDirection AS CHARACTER):
        IF LC(TRIM(pcDirection)) = "desc" THEN
            RETURN "DESCENDING".
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER buildOrderExpression(INPUT pcTable AS CHARACTER, INPUT pcField AS CHARACTER, INPUT pcDirection AS CHARACTER):
        DEFINE VARIABLE cExpr AS CHARACTER NO-UNDO.
        ASSIGN cExpr = THIS-OBJECT:qualifyField(pcTable, pcField).
        IF pcDirection <> "" THEN
            ASSIGN cExpr = cExpr + " " + pcDirection.
        RETURN cExpr.
    END METHOD.

    METHOD PRIVATE CHARACTER buildFilterClause(
        INPUT pcTable AS CHARACTER,
        INPUT pcField AS CHARACTER,
        INPUT pcOperator AS CHARACTER,
        INPUT pcValue AS CHARACTER,
        INPUT pcValueTo AS CHARACTER,
        INPUT pcType AS CHARACTER):
        DEFINE VARIABLE cOp AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cL  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cR  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cExpr AS CHARACTER NO-UNDO.
        ASSIGN cOp = LC(TRIM(pcOperator))
               cL = THIS-OBJECT:formatLiteral(pcType, pcValue)
               cR = THIS-OBJECT:formatLiteral(pcType, pcValueTo).

        CASE cOp:
            WHEN "between" THEN
                ASSIGN cExpr = THIS-OBJECT:qualifyField(pcTable, pcField) + " BETWEEN " + cL + " AND " + cR.
            WHEN "begins" THEN
                ASSIGN cExpr = THIS-OBJECT:qualifyField(pcTable, pcField) + " BEGINS " + cL.
            WHEN "contains" THEN
                ASSIGN cExpr = "INDEX(" + THIS-OBJECT:qualifyField(pcTable, pcField) + "," + cL + ",1) > 0".
            OTHERWISE
                ASSIGN cExpr = THIS-OBJECT:qualifyField(pcTable, pcField) + " " + pcOperator + " " + cL.
        END CASE.
        RETURN cExpr.
    END METHOD.

    METHOD PRIVATE CHARACTER formatLiteral(INPUT pcType AS CHARACTER, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cVal  AS CHARACTER NO-UNDO.
        ASSIGN cType = LC(pcType)
               cVal  = IF pcValue = ? THEN "" ELSE TRIM(pcValue).
        IF cVal = "" THEN RETURN "NULL".
        CASE cType:
            WHEN "integer" THEN RETURN cVal.
            WHEN "int64" THEN RETURN cVal.
            WHEN "decimal" THEN RETURN cVal.
            WHEN "logical" THEN DO:
                IF LC(cVal) = "true" OR cVal = "1" OR LC(cVal) = "yes" THEN
                    RETURN "TRUE".
                RETURN "FALSE".
            END.
            WHEN "date" THEN RETURN "'" + REPLACE(cVal, "'", "''") + "'".
            WHEN "datetime" THEN RETURN "'" + REPLACE(cVal, "'", "''") + "'".
            OTHERWISE RETURN "'" + REPLACE(cVal, "'", "''") + "'".
        END CASE.
    END METHOD.

    METHOD PUBLIC CHARACTER getQuery():
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        ASSIGN cQuery = cFromClause.
        IF cWhereClause <> "" THEN
            ASSIGN cQuery = cQuery + " WHERE " + cWhereClause.
        IF cOrderClause <> "" THEN
            ASSIGN cQuery = cQuery + " BY " + cOrderClause.
        RETURN cQuery.
    END METHOD.

    METHOD PUBLIC CHARACTER getSelectClause():
        RETURN cSelectClause.
    END METHOD.

    METHOD PUBLIC CHARACTER getWhereClause():
        RETURN cWhereClause.
    END METHOD.

    METHOD PUBLIC INTEGER getSourceCount():
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
        FOR EACH ttPlanSource:
            ASSIGN iCount = iCount + 1.
        END.
        RETURN iCount.
    END METHOD.

    METHOD PUBLIC VOID getSources(OUTPUT TABLE ttPlanSource):
    END METHOD.

    METHOD PUBLIC VOID getSelectPlan(OUTPUT TABLE ttPlanSelect):
    END METHOD.

    METHOD PUBLIC VOID getFiltersPlan(OUTPUT TABLE ttPlanFilter):
    END METHOD.

    METHOD PUBLIC VOID getJoinPlan(OUTPUT TABLE ttPlanJoin):
    END METHOD.

    METHOD PUBLIC VOID getOrderPlan(OUTPUT TABLE ttPlanOrder):
    END METHOD.

END CLASS.

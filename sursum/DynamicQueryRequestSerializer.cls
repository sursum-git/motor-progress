/*
Serializa e desserializa DynamicQueryRequestModel para JSON estruturado.
Usado para persistir requests assincronas sem expor ABL/WHERE livre.
*/

USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.ObjectModelParser.

CLASS DynamicQueryRequestSerializer:

    DEFINE PRIVATE TEMP-TABLE ttSource NO-UNDO
        FIELD sourceOrder     AS INTEGER
        FIELD tableName       AS CHARACTER
        FIELD tableAlias      AS CHARACTER
        FIELD tableBanco      AS CHARACTER
        FIELD requestedFields AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttJoin NO-UNDO
        FIELD joinOrder   AS INTEGER
        FIELD joinType    AS CHARACTER
        FIELD leftSource  AS CHARACTER
        FIELD leftField   AS CHARACTER
        FIELD rightSource AS CHARACTER
        FIELD rightField  AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttSelect NO-UNDO
        FIELD selectOrder AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD fieldName   AS CHARACTER
        FIELD outputAlias AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttFilter NO-UNDO
        FIELD filterOrder AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD fieldName   AS CHARACTER
        FIELD operator    AS CHARACTER
        FIELD valueChar   AS CHARACTER
        FIELD valueToChar AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttOrderBy NO-UNDO
        FIELD orderOrder  AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD fieldName   AS CHARACTER
        FIELD direction   AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPipelineStep NO-UNDO
        FIELD stepOrder   AS INTEGER
        FIELD stepType    AS CHARACTER
        FIELD stepPayload AS CHARACTER
        FIELD stepRaw     AS CHARACTER.

    METHOD PUBLIC JsonObject toJsonObject(INPUT poRequest AS DynamicQueryRequestModel):
        DEFINE VARIABLE joRoot AS JsonObject NO-UNDO.
        DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaItems AS JsonArray NO-UNDO.

        ASSIGN joRoot = NEW JsonObject().
        joRoot:Add("version", "1").
        joRoot:Add("execution", poRequest:getExecution()).
        joRoot:Add("page", poRequest:getPage()).
        joRoot:Add("pageSize", poRequest:getPageSize()).
        joRoot:Add("defaultBanco", poRequest:getDefaultBanco()).
        joRoot:Add("pipelineVersion", poRequest:getPipelineVersion()).
        joRoot:Add("rawRequest", poRequest:getRawRequest()).

        EMPTY TEMP-TABLE ttSource.
        poRequest:getSources(OUTPUT TABLE ttSource).
        ASSIGN jaItems = NEW JsonArray().
        FOR EACH ttSource BY ttSource.sourceOrder:
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("order", ttSource.sourceOrder).
            joItem:Add("nome", ttSource.tableName).
            joItem:Add("alias", ttSource.tableAlias).
            joItem:Add("banco", ttSource.tableBanco).
            joItem:Add("campos", ttSource.requestedFields).
            jaItems:Add(joItem).
        END.
        joRoot:Add("sources", jaItems).

        EMPTY TEMP-TABLE ttJoin.
        poRequest:getJoins(OUTPUT TABLE ttJoin).
        ASSIGN jaItems = NEW JsonArray().
        FOR EACH ttJoin BY ttJoin.joinOrder:
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("order", ttJoin.joinOrder).
            joItem:Add("type", ttJoin.joinType).
            joItem:Add("leftAlias", ttJoin.leftSource).
            joItem:Add("leftField", ttJoin.leftField).
            joItem:Add("rightAlias", ttJoin.rightSource).
            joItem:Add("rightField", ttJoin.rightField).
            jaItems:Add(joItem).
        END.
        joRoot:Add("joins", jaItems).

        EMPTY TEMP-TABLE ttSelect.
        poRequest:getSelects(OUTPUT TABLE ttSelect).
        ASSIGN jaItems = NEW JsonArray().
        FOR EACH ttSelect BY ttSelect.selectOrder:
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("order", ttSelect.selectOrder).
            joItem:Add("sourceAlias", ttSelect.sourceAlias).
            joItem:Add("field", ttSelect.fieldName).
            joItem:Add("outputAlias", ttSelect.outputAlias).
            jaItems:Add(joItem).
        END.
        joRoot:Add("select", jaItems).

        EMPTY TEMP-TABLE ttFilter.
        poRequest:getFilters(OUTPUT TABLE ttFilter).
        ASSIGN jaItems = NEW JsonArray().
        FOR EACH ttFilter BY ttFilter.filterOrder:
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("order", ttFilter.filterOrder).
            joItem:Add("sourceAlias", ttFilter.sourceAlias).
            joItem:Add("field", ttFilter.fieldName).
            joItem:Add("operator", ttFilter.operator).
            joItem:Add("value", ttFilter.valueChar).
            joItem:Add("valueTo", ttFilter.valueToChar).
            jaItems:Add(joItem).
        END.
        joRoot:Add("filters", jaItems).

        EMPTY TEMP-TABLE ttOrderBy.
        poRequest:getOrders(OUTPUT TABLE ttOrderBy).
        ASSIGN jaItems = NEW JsonArray().
        FOR EACH ttOrderBy BY ttOrderBy.orderOrder:
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("order", ttOrderBy.orderOrder).
            joItem:Add("sourceAlias", ttOrderBy.sourceAlias).
            joItem:Add("field", ttOrderBy.fieldName).
            joItem:Add("direction", ttOrderBy.direction).
            jaItems:Add(joItem).
        END.
        joRoot:Add("orderBy", jaItems).

        EMPTY TEMP-TABLE ttPipelineStep.
        poRequest:getPipelineSteps(OUTPUT TABLE ttPipelineStep).
        ASSIGN jaItems = NEW JsonArray().
        FOR EACH ttPipelineStep BY ttPipelineStep.stepOrder:
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("order", ttPipelineStep.stepOrder).
            joItem:Add("type", ttPipelineStep.stepType).
            joItem:Add("payload", ttPipelineStep.stepPayload).
            joItem:Add("raw", ttPipelineStep.stepRaw).
            jaItems:Add(joItem).
        END.
        joRoot:Add("pipeline", jaItems).

        RETURN joRoot.
    END METHOD.

    METHOD PUBLIC LONGCHAR toLongchar(INPUT poRequest AS DynamicQueryRequestModel):
        DEFINE VARIABLE joRoot AS JsonObject NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        ASSIGN joRoot = THIS-OBJECT:toJsonObject(poRequest).
        joRoot:Write(lcJson, TRUE).
        DELETE OBJECT joRoot NO-ERROR.
        RETURN lcJson.
    END METHOD.

    METHOD PUBLIC DynamicQueryRequestModel fromLongchar(INPUT pcJson AS LONGCHAR):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joRoot AS JsonObject NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.

        ASSIGN oParser = NEW ObjectModelParser().
        ASSIGN cJson = STRING(pcJson) NO-ERROR.
        ASSIGN oConstruct = oParser:Parse(cJson).
        ASSIGN joRoot = CAST(oConstruct, JsonObject).
        ASSIGN oRequest = THIS-OBJECT:fromJsonObject(joRoot).
        DELETE OBJECT oParser NO-ERROR.
        RETURN oRequest.
    END METHOD.

    METHOD PUBLIC DynamicQueryRequestModel fromJsonObject(INPUT poRoot AS JsonObject):
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE jaItems AS JsonArray NO-UNDO.
        DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
        DEFINE VARIABLE iItem AS INTEGER NO-UNDO.

        ASSIGN oRequest = NEW DynamicQueryRequestModel().
        oRequest:setExecution(THIS-OBJECT:getChar(poRoot, "execution")).
        oRequest:setPagination(THIS-OBJECT:getInt(poRoot, "page", 1), THIS-OBJECT:getInt(poRoot, "pageSize", 50)).
        oRequest:setDefaultBanco(THIS-OBJECT:getChar(poRoot, "defaultBanco")).
        oRequest:setPipelineVersion(THIS-OBJECT:getChar(poRoot, "pipelineVersion")).
        oRequest:setRawRequest(THIS-OBJECT:getLongchar(poRoot, "rawRequest")).

        IF poRoot:Has("sources") THEN DO:
            ASSIGN jaItems = poRoot:GetJsonArray("sources").
            DO iItem = 1 TO jaItems:Length:
                ASSIGN joItem = jaItems:GetJsonObject(iItem).
                oRequest:addSource(
                    THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getChar(joItem, "nome"), THIS-OBJECT:getChar(joItem, "tableName")),
                    THIS-OBJECT:getChar(joItem, "alias"),
                    THIS-OBJECT:getChar(joItem, "banco"),
                    THIS-OBJECT:getChar(joItem, "campos")
                ).
            END.
        END.

        IF poRoot:Has("joins") THEN DO:
            ASSIGN jaItems = poRoot:GetJsonArray("joins").
            DO iItem = 1 TO jaItems:Length:
                ASSIGN joItem = jaItems:GetJsonObject(iItem).
                oRequest:addJoin(
                    THIS-OBJECT:getChar(joItem, "type"),
                    THIS-OBJECT:getChar(joItem, "leftAlias"),
                    THIS-OBJECT:getChar(joItem, "leftField"),
                    THIS-OBJECT:getChar(joItem, "rightAlias"),
                    THIS-OBJECT:getChar(joItem, "rightField")
                ).
            END.
        END.

        IF poRoot:Has("select") THEN DO:
            ASSIGN jaItems = poRoot:GetJsonArray("select").
            DO iItem = 1 TO jaItems:Length:
                ASSIGN joItem = jaItems:GetJsonObject(iItem).
                oRequest:addSelectField(
                    THIS-OBJECT:getChar(joItem, "sourceAlias"),
                    THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getChar(joItem, "field"), THIS-OBJECT:getChar(joItem, "fieldName")),
                    THIS-OBJECT:getChar(joItem, "outputAlias")
                ).
            END.
        END.

        IF poRoot:Has("filters") THEN DO:
            ASSIGN jaItems = poRoot:GetJsonArray("filters").
            DO iItem = 1 TO jaItems:Length:
                ASSIGN joItem = jaItems:GetJsonObject(iItem).
                oRequest:addFilter(
                    THIS-OBJECT:getChar(joItem, "sourceAlias"),
                    THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getChar(joItem, "field"), THIS-OBJECT:getChar(joItem, "fieldName")),
                    THIS-OBJECT:getChar(joItem, "operator"),
                    THIS-OBJECT:getChar(joItem, "value"),
                    THIS-OBJECT:getChar(joItem, "valueTo")
                ).
            END.
        END.

        IF poRoot:Has("orderBy") THEN DO:
            ASSIGN jaItems = poRoot:GetJsonArray("orderBy").
            DO iItem = 1 TO jaItems:Length:
                ASSIGN joItem = jaItems:GetJsonObject(iItem).
                oRequest:addOrder(
                    THIS-OBJECT:getChar(joItem, "sourceAlias"),
                    THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getChar(joItem, "field"), THIS-OBJECT:getChar(joItem, "fieldName")),
                    THIS-OBJECT:getChar(joItem, "direction")
                ).
            END.
        END.

        IF poRoot:Has("pipeline") THEN DO:
            ASSIGN jaItems = poRoot:GetJsonArray("pipeline").
            DO iItem = 1 TO jaItems:Length:
                ASSIGN joItem = jaItems:GetJsonObject(iItem).
                oRequest:addPipelineStep(
                    THIS-OBJECT:getChar(joItem, "type"),
                    THIS-OBJECT:getChar(joItem, "payload"),
                    THIS-OBJECT:getChar(joItem, "raw")
                ).
            END.
        END.

        RETURN oRequest.
    END METHOD.

    METHOD PUBLIC LONGCHAR contextToLongchar(INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE joContext AS JsonObject NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF NOT VALID-OBJECT(poContext) THEN
            RETURN "".

        ASSIGN joContext = poContext:toJson().
        joContext:Write(lcJson, TRUE).
        DELETE OBJECT joContext NO-ERROR.
        RETURN lcJson.
    END METHOD.

    METHOD PRIVATE CHARACTER getChar(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        IF NOT poJson:Has(pcName) THEN
            RETURN "".
        IF poJson:IsNull(pcName) THEN
            RETURN "".
        ASSIGN cValue = poJson:GetCharacter(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN "".
        RETURN cValue.
    END METHOD.

    METHOD PRIVATE LONGCHAR getLongchar(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE lcValue AS LONGCHAR NO-UNDO.
        IF NOT poJson:Has(pcName) THEN
            RETURN "".
        IF poJson:IsNull(pcName) THEN
            RETURN "".
        ASSIGN lcValue = poJson:GetLongchar(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            ASSIGN lcValue = THIS-OBJECT:getChar(poJson, pcName).
        RETURN lcValue.
    END METHOD.

    METHOD PRIVATE INTEGER getInt(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER, INPUT piDefault AS INTEGER):
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
        IF NOT poJson:Has(pcName) THEN
            RETURN piDefault.
        IF poJson:IsNull(pcName) THEN
            RETURN piDefault.
        ASSIGN iValue = poJson:GetInteger(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN piDefault.
        RETURN iValue.
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN
            RETURN pcA.
        IF pcB <> "" AND pcB <> ? THEN
            RETURN pcB.
        RETURN "".
    END METHOD.

END CLASS.

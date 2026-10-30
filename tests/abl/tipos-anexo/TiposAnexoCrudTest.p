BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttTipos
    FIELD tipo_anexo_id AS INTEGER FIELD descricao AS CHARACTER
    INDEX primario IS PRIMARY UNIQUE tipo_anexo_id.
DEFINE TEMP-TABLE ttContainer FIELD tipos_anexo_id AS INTEGER.
DEFINE TEMP-TABLE ttCompra FIELD tipos_anexo_id AS INTEGER.
DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE jaChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE joChange AS JsonObject NO-UNDO.
DEFINE VARIABLE joData AS JsonObject NO-UNDO.
DEFINE VARIABLE joOld AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE jaAuditChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE joAuditChange AS JsonObject NO-UNDO.
DEFINE VARIABLE cProForma AS CHARACTER NO-UNDO INITIAL "2".
DEFINE VARIABLE lConfigured AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.
DEFINE VARIABLE iBatchItem AS INTEGER NO-UNDO.
OUTPUT TO "tipos-anexo-tests.log".
DO ON ERROR UNDO, THROW:
    IF SEARCH("TiposAnexoCrudService.p") = ? THEN
        UNDO, THROW NEW Progress.Lang.AppError("Servico tipos anexo ainda nao implementado", 0).
    CREATE ttTipos. ASSIGN ttTipos.tipo_anexo_id = 1 ttTipos.descricao = "Um". VALIDATE ttTipos.
    CREATE ttTipos. ASSIGN ttTipos.tipo_anexo_id = 2 ttTipos.descricao = "Dois". VALIDATE ttTipos.
    CREATE ttTipos. ASSIGN ttTipos.tipo_anexo_id = 3 ttTipos.descricao = "Tres". VALIDATE ttTipos.
    RELEASE ttTipos.

    RUN NewBatch.
    RUN AddChange("update", "u1", 1, "São José", "Um").
    RUN AddChange("create", "n1", 0, FILL("ã", 100), "").
    RUN AddChange("create", "n2", 0, "Outro", "").
    RUN AddChange("delete", "d1", 3, "", "Tres").
    RUN ExecuteRequest.
    RUN Check(joResponse:GetLogical("success"), "lote misto confirmado").
    RUN Check(joResponse:GetJsonArray("data"):Length = 4, "lista final completa").
    FIND ttTipos WHERE ttTipos.tipo_anexo_id = 1 NO-LOCK.
    RUN Check(ttTipos.descricao = "São José", "alteracao unicode"). RELEASE ttTipos.
    FIND ttTipos WHERE ttTipos.tipo_anexo_id = 4 NO-LOCK.
    RUN Check(LENGTH(ttTipos.descricao) = 100, "100 caracteres aceitos"). RELEASE ttTipos.
    RUN Check(CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 5), "IDs distintos gerados").
    RUN Check(NOT CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 3), "exclusao aplicada").
    RUN ExpectAudit("batch").
    jaAuditChanges = joAudit:GetJsonArray("changes").
    RUN Check(jaAuditChanges:Length = 4, "auditoria contem todas as linhas confirmadas").
    joAuditChange = jaAuditChanges:GetJsonObject(1).
    RUN Check(joAuditChange:GetCharacter("clientId") = "u1", "auditoria conserva ordem e clientId da linha").
    RUN Check(joAuditChange:GetCharacter("operation") = "update" AND joAuditChange:GetInteger("recordId") = 1, "auditoria update identifica registro").
    RUN ExpectRecord(joAuditChange:GetJsonObject("before"), 1, "Um").
    RUN ExpectRecord(joAuditChange:GetJsonObject("after"), 1, "São José").
    joAuditChange = jaAuditChanges:GetJsonObject(2).
    RUN Check(joAuditChange:GetCharacter("clientId") = "n1" AND joAuditChange:GetInteger("recordId") = 4, "auditoria inclusao usa ID alocado").
    RUN Check(joAuditChange:GetCharacter("operation") = "create" AND NOT joAuditChange:GetJsonObject("before"):Has("tipo_anexo_id"), "inclusao nao inventa anterior").
    RUN ExpectRecord(joAuditChange:GetJsonObject("after"), 4, FILL("ã", 100)).
    joAuditChange = jaAuditChanges:GetJsonObject(3).
    RUN Check(joAuditChange:GetCharacter("clientId") = "n2" AND joAuditChange:GetInteger("recordId") = 5, "segunda inclusao possui snapshot proprio").
    RUN ExpectRecord(joAuditChange:GetJsonObject("after"), 5, "Outro").
    joAuditChange = jaAuditChanges:GetJsonObject(4).
    RUN Check(joAuditChange:GetCharacter("clientId") = "d1" AND joAuditChange:GetCharacter("operation") = "delete", "auditoria identifica exclusao do lote").
    RUN ExpectRecord(joAuditChange:GetJsonObject("before"), 3, "Tres").
    RUN Check(NOT joAuditChange:GetJsonObject("after"):Has("tipo_anexo_id"), "exclusao nao inventa posterior").

    RUN NewBatch.
    RUN AddChange("update", "u1", 1, "Nao confirmar", "São José").
    RUN AddChange("create", "n1", 0, "Nao confirmar", "").
    RUN AddChange("delete", "d1", 999, "", "ausente").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_NOT_FOUND").
    FIND ttTipos WHERE ttTipos.tipo_anexo_id = 1 NO-LOCK.
    RUN Check(ttTipos.descricao = "São José", "rollback da alteracao anterior"). RELEASE ttTipos.
    RUN Check(NOT CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 6), "rollback da inclusao anterior").

    RUN NewBatch. RUN AddChange("delete", "d1", 2, "", "Dois").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_PROFORMA_IN_USE").
    RUN Check(CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 2), "proforma preservado").
    CREATE ttContainer. ttContainer.tipos_anexo_id = 1. VALIDATE ttContainer. RELEASE ttContainer.
    RUN NewBatch. RUN AddChange("create", "n1", 0, "rollback vinculo", "").
    RUN AddChange("delete", "d1", 1, "", "São José"). RUN ExecuteRequest.
    RUN ExpectError("TIPO_ANEXO_IN_USE").
    RUN Check(NOT CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 6), "rollback por dependencia").
    FOR EACH ttContainer: DELETE ttContainer. END.
    CREATE ttCompra. ttCompra.tipos_anexo_id = 1. VALIDATE ttCompra. RELEASE ttCompra.
    RUN NewBatch. RUN AddChange("delete", "d1", 1, "", "São José"). RUN ExecuteRequest.
    RUN ExpectError("TIPO_ANEXO_IN_USE").
    FOR EACH ttCompra: DELETE ttCompra. END.

    lConfigured = FALSE.
    RUN NewBatch. RUN AddChange("delete", "d1", 1, "", "São José"). RUN ExecuteRequest.
    RUN ExpectError("TIPO_ANEXO_PROFORMA_CONFIGURATION").
    lConfigured = TRUE.
    RUN NewBatch. RUN AddChange("update", "u1", 1, "desatualizado", "antigo"). RUN ExecuteRequest.
    RUN ExpectError("TIPO_ANEXO_CHANGED").
    RUN NewBatch. RUN AddChange("update", "u1", 1, "desatualizado", "SÃO JOSÉ"). RUN ExecuteRequest.
    RUN ExpectError("TIPO_ANEXO_CHANGED").
    RUN NewBatch. RUN AddChange("update", "u1", 1, "desatualizado", "São José "). RUN ExecuteRequest.
    RUN ExpectError("TIPO_ANEXO_CHANGED").
    RUN NewBatch. RUN AddChange("update", "u1", 1, "novo", "São José").
    joChange:Remove("original"). RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. RUN AddChange("create", "n1", 0, FILL("x", 101), "").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. RUN AddChange("create", "n1", 0, "PK", ""). joChange:Add("id", 100).
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_ID_IMMUTABLE").
    RUN NewBatch. RUN AddChange("create", "n1", 0, "campo", ""). joData:Add("sql", "nao executar").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_FIELD_INVALID").
    RUN NewBatch. RUN AddChange("create", "dup", 0, "um", ""). RUN AddChange("create", "dup", 0, "dois", "").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. RUN AddChange("create", "nao permitido", 0, "um", "").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. RUN AddChange("update", "u1", 1, "um", "São José"). RUN AddChange("delete", "d1", 1, "", "São José").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. RUN AddChange("delete", "d1", 1, "", "São José"). joChange:Remove("id"). joChange:Add("id", 1.5).
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch. joRequest:Remove("operation"). joRequest:Add("operation", "sql").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_OPERATION_INVALID").
    joRequest = NEW JsonObject(). joRequest:Add("operation", "read"). RUN ExecuteRequest.
    RUN Check(joResponse:GetLogical("success") AND joResponse:GetJsonArray("data"):Length = 4, "consulta preservada apos erros").
    RUN Check(NOT joResponse:Has("audit"), "consulta nao publica auditoria de escrita").
    joRequest = NEW JsonObject(). joRequest:Add("operation", "update"). joRequest:Add("id", 1.5). joRequest:Add("descricao", "nao alterar").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    joRequest = NEW JsonObject(). joRequest:Add("operation", "get"). joRequest:Add("id", 1).
    RUN ExecuteRequest. RUN Check(joResponse:GetJsonObject("data"):GetCharacter("descricao") = "São José", "detalhe preservado").
    RUN Check(NOT joResponse:Has("audit"), "detalhe nao publica auditoria de escrita").

    joRequest = NEW JsonObject(). joRequest:Add("operation", "create"). joRequest:Add("descricao", "Anterior real").
    RUN ExecuteRequest. RUN ExpectAudit("create").
    RUN Check(joAudit:GetInteger("recordId") = 6 AND NOT joAudit:GetJsonObject("before"):Has("tipo_anexo_id"), "single inclusao identifica ID gerado e anterior vazio").
    RUN ExpectRecord(joAudit:GetJsonObject("after"), 6, "Anterior real").
    joRequest = NEW JsonObject(). joRequest:Add("operation", "update"). joRequest:Add("id", 6). joRequest:AddNull("descricao").
    RUN ExecuteRequest. RUN ExpectAudit("update").
    RUN Check(joAudit:GetInteger("recordId") = 6, "single update identifica registro").
    RUN ExpectRecord(joAudit:GetJsonObject("before"), 6, "Anterior real").
    RUN ExpectRecord(joAudit:GetJsonObject("after"), 6, ?).
    joRequest = NEW JsonObject(). joRequest:Add("operation", "delete"). joRequest:Add("id", 6).
    RUN ExecuteRequest. RUN ExpectAudit("delete").
    RUN Check(joAudit:GetInteger("recordId") = 6, "single delete identifica registro").
    RUN ExpectRecord(joAudit:GetJsonObject("before"), 6, ?).
    RUN Check(NOT joAudit:GetJsonObject("after"):Has("tipo_anexo_id"), "single delete posterior vazio").

    RUN NewBatch. RUN AddChange("create", "null-create", 0, ?, "").
    RUN ExecuteRequest. RUN ExpectAudit("batch").
    joAuditChange = joAudit:GetJsonArray("changes"):GetJsonObject(1).
    RUN ExpectRecord(joAuditChange:GetJsonObject("after"), 6, ?).
    RUN NewBatch. RUN AddChange("update", "null-update", 6, "", ?).
    RUN ExecuteRequest. RUN ExpectAudit("batch").
    joAuditChange = joAudit:GetJsonArray("changes"):GetJsonObject(1).
    RUN ExpectRecord(joAuditChange:GetJsonObject("before"), 6, ?).
    RUN ExpectRecord(joAuditChange:GetJsonObject("after"), 6, "").
    RUN NewBatch. RUN AddChange("delete", "empty-delete", 6, "", "").
    RUN ExecuteRequest. RUN ExpectAudit("batch").
    joAuditChange = joAudit:GetJsonArray("changes"):GetJsonObject(1).
    RUN ExpectRecord(joAuditChange:GetJsonObject("before"), 6, "").
    RUN Check(NOT CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 6), "registros adicionais de auditoria removidos").

    RUN NewBatch.
    DO iBatchItem = 1 TO 101:
        RUN AddChange("create", "over-" + TRIM(STRING(iBatchItem)), 0, "Limite", "").
    END.
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_VALIDATION").
    RUN NewBatch.
    DO iBatchItem = 1 TO 99:
        RUN AddChange("create", "rollback-" + TRIM(STRING(iBatchItem)), 0, "Nao confirmar limite", "").
    END.
    RUN AddChange("delete", "rollback-last", 999, "", "ausente").
    RUN ExecuteRequest. RUN ExpectError("TIPO_ANEXO_NOT_FOUND").
    RUN Check(NOT CAN-FIND(ttTipos WHERE ttTipos.tipo_anexo_id = 6), "erro na linha 100 desfaz 99 inclusoes sem auditoria").
    RUN NewBatch.
    DO iBatchItem = 1 TO 100:
        RUN AddChange("create", "limit-" + TRIM(STRING(iBatchItem)), 0, "Lote limite", "").
    END.
    RUN ExecuteRequest. RUN ExpectAudit("batch").
    jaAuditChanges = joAudit:GetJsonArray("changes").
    RUN Check(jaAuditChanges:Length = 100 AND joResponse:GetJsonArray("results"):Length = 100, "100 linhas confirmadas recebem 100 snapshots").
    RUN ExpectRecord(jaAuditChanges:GetJsonObject(1):GetJsonObject("after"), 6, "Lote limite").
    RUN ExpectRecord(jaAuditChanges:GetJsonObject(100):GetJsonObject("after"), 105, "Lote limite").
    RUN NewBatch.
    DO iBatchItem = 1 TO 100:
        RUN AddChange("delete", "clean-" + TRIM(STRING(iBatchItem)), iBatchItem + 5, "", "Lote limite").
    END.
    RUN ExecuteRequest. RUN ExpectAudit("batch").
    RUN Check(joResponse:GetJsonArray("data"):Length = 4, "limpeza do lote limite conserva fixture original").
    PUT UNFORMATTED "PASS: " iPassed " verificacoes CRUD multirow" SKIP.
    CATCH e AS Progress.Lang.Error:
        PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
        IF VALID-OBJECT(joResponse) AND joResponse:Has("error") THEN
            PUT UNFORMATTED joResponse:GetJsonObject("error"):GetCharacter("code") " "
                joResponse:GetJsonObject("error"):GetCharacter("message") SKIP.
    END CATCH.
END.
OUTPUT CLOSE.
QUIT.
PROCEDURE NewBatch:
    joRequest = NEW JsonObject(). joRequest:Add("operation", "batch").
    jaChanges = NEW JsonArray(). joRequest:Add("changes", jaChanges).
END PROCEDURE.
PROCEDURE AddChange:
    DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcClient AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piId AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcValue AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcOriginal AS CHARACTER NO-UNDO.
    joChange = NEW JsonObject(). joChange:Add("operation", pcOperation). joChange:Add("clientId", pcClient).
    IF pcOperation <> "create" THEN joChange:Add("id", piId).
    IF pcOperation <> "delete" THEN DO:
        joData = NEW JsonObject().
        IF pcValue = ? THEN joData:AddNull("descricao"). ELSE joData:Add("descricao", pcValue).
        joChange:Add("data", joData).
    END.
    IF pcOperation <> "create" THEN DO:
        joOld = NEW JsonObject().
        IF pcOriginal = ? THEN joOld:AddNull("descricao"). ELSE joOld:Add("descricao", pcOriginal).
        joChange:Add("original", joOld).
    END.
    jaChanges:Add(joChange).
END PROCEDURE.
PROCEDURE ExecuteRequest:
    RUN TiposAnexoCrudService.p (INPUT BUFFER ttTipos:HANDLE, INPUT BUFFER ttContainer:HANDLE,
        INPUT BUFFER ttCompra:HANDLE, INPUT cProForma, INPUT lConfigured, INPUT joRequest, OUTPUT joResponse).
END PROCEDURE.
PROCEDURE Check:
    DEFINE INPUT PARAMETER plOk AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
    IF plOk <> TRUE OR plOk = ? THEN UNDO, THROW NEW Progress.Lang.AppError(pcLabel, 0).
    iPassed = iPassed + 1.
END PROCEDURE.
PROCEDURE ExpectError:
    DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
    RUN Check(joResponse:Has("error"), "erro esperado " + pcCode).
    RUN Check(joResponse:GetJsonObject("error"):GetCharacter("code") = pcCode,
        "codigo esperado " + pcCode + " recebido " + joResponse:GetJsonObject("error"):GetCharacter("code")).
    RUN Check(NOT joResponse:Has("audit"), "falha nao publica auditoria de lote confirmado").
END PROCEDURE.
PROCEDURE ExpectAudit:
    DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
    RUN Check(joResponse:GetLogical("success"), "operacao auditada confirmada").
    RUN Check(joResponse:Has("audit"), "resposta confirmada inclui snapshot transacional").
    joAudit = joResponse:GetJsonObject("audit").
    RUN Check(joAudit:GetInteger("version") = 1 AND joAudit:GetCharacter("source") = "progress-transaction", "auditoria declara procedencia transacional").
    RUN Check(joAudit:GetCharacter("resource") = "tipos_anexo" AND joAudit:GetCharacter("operation") = pcOperation, "auditoria vincula recurso e operacao").
END PROCEDURE.
PROCEDURE ExpectRecord:
    DEFINE INPUT PARAMETER poRecord AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER piId AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcDescription AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cActual AS CHARACTER CASE-SENSITIVE NO-UNDO.
    RUN Check(poRecord:GetInteger("tipo_anexo_id") = piId, "snapshot contem chave real do registro").
    IF pcDescription = ? THEN RUN Check(poRecord:IsNull("descricao"), "snapshot preserva descricao null").
    ELSE DO:
        RUN Check(NOT poRecord:IsNull("descricao"), "snapshot distingue texto de null").
        cActual = poRecord:GetCharacter("descricao").
        RUN Check(cActual = pcDescription AND LENGTH(cActual) = LENGTH(pcDescription), "snapshot preserva texto exato do buffer").
    END.
END PROCEDURE.

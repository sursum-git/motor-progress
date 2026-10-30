/* Servico transacional. Buffers fixos fornecidos pelo wrapper; cliente nao escolhe tabelas. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompra AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcTipoProForma AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER plProFormaConfigured AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttChange NO-UNDO
    FIELD lineNo AS INTEGER FIELD clientId AS CHARACTER CASE-SENSITIVE
    FIELD op AS CHARACTER FIELD recordId AS INTEGER
    FIELD descricao AS CHARACTER FIELD hasOriginal AS LOGICAL FIELD original AS CHARACTER
    INDEX ordem IS PRIMARY UNIQUE lineNo INDEX cliente IS UNIQUE clientId.
DEFINE VARIABLE cOperation AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE iClientChar AS INTEGER NO-UNDO.
DEFINE VARIABLE iLine AS INTEGER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iNextId AS INTEGER NO-UNDO.
DEFINE VARIABLE iProForma AS INTEGER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE lBatch AS LOGICAL NO-UNDO.
DEFINE VARIABLE lWrites AS LOGICAL NO-UNDO.
DEFINE VARIABLE jaChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE joChange AS JsonObject NO-UNDO.
DEFINE VARIABLE joData AS JsonObject NO-UNDO.
DEFINE VARIABLE joOld AS JsonObject NO-UNDO.
DEFINE VARIABLE jaResults AS JsonArray NO-UNDO.
DEFINE VARIABLE joResult AS JsonObject NO-UNDO.
DEFINE VARIABLE joSingle AS JsonObject NO-UNDO.
DEFINE VARIABLE joBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE joAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE jaAuditChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE joAuditChange AS JsonObject NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.

FUNCTION FindFailed RETURNS LOGICAL ():
    DEFINE VARIABLE k AS INTEGER NO-UNDO.
    DO k = 1 TO ERROR-STATUS:NUM-MESSAGES:
        IF ERROR-STATUS:GET-NUMBER(k) <> 565 THEN RETURN TRUE.
    END.
    RETURN FALSE.
END FUNCTION.

FUNCTION ReadId RETURNS INTEGER (INPUT poObject AS JsonObject, INPUT pcName AS CHARACTER):
    DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
    DEFINE VARIABLE k AS INTEGER NO-UNDO.
    DEFINE VARIABLE dNumber AS DECIMAL NO-UNDO.
    IF NOT poObject:Has(pcName) OR poObject:IsNull(pcName) THEN DO:
        RUN Fail("TIPO_ANEXO_VALIDATION", "Informe um ID inteiro positivo.", 422).
    END.
    IF poObject:GetType(pcName) = JsonDataType:STRING THEN cText = TRIM(poObject:GetCharacter(pcName)).
    ELSE IF poObject:GetType(pcName) = JsonDataType:NUMBER THEN cText = poObject:GetJsonText(pcName).
    ELSE cText = "invalido".
    IF LENGTH(cText) = 0 OR LENGTH(cText) > 10 THEN
        RUN Fail("TIPO_ANEXO_VALIDATION", "ID inteiro invalido.", 422).
    DO k = 1 TO LENGTH(cText):
        IF INDEX("0123456789", SUBSTRING(cText, k, 1)) = 0 THEN
            RUN Fail("TIPO_ANEXO_VALIDATION", "ID inteiro invalido.", 422).
    END.
    dNumber = DECIMAL(cText).
    IF dNumber < 1 OR dNumber > 2147483647 THEN
        RUN Fail("TIPO_ANEXO_VALIDATION", "ID fora do limite permitido.", 422).
    RETURN INTEGER(dNumber).
END FUNCTION.

FUNCTION ReadDescription RETURNS CHARACTER (INPUT poObject AS JsonObject):
    DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFields AS CHARACTER EXTENT NO-UNDO.
    DEFINE VARIABLE k AS INTEGER NO-UNDO.
    cFields = poObject:GetNames().
    DO k = 1 TO EXTENT(cFields):
        IF cFields[k] <> "descricao" THEN RUN Fail("TIPO_ANEXO_FIELD_INVALID", "Campo nao permitido.", 422).
    END.
    IF NOT poObject:Has("descricao") THEN RETURN "".
    IF poObject:IsNull("descricao") THEN RETURN ?.
    IF poObject:GetType("descricao") <> JsonDataType:STRING THEN
        RUN Fail("TIPO_ANEXO_VALIDATION", "Descricao deve ser texto.", 422).
    cText = poObject:GetCharacter("descricao").
    IF LENGTH(cText) > 100 THEN RUN Fail("TIPO_ANEXO_VALIDATION", "Descricao deve ter ate 100 caracteres.", 422).
    RETURN cText.
END FUNCTION.

FUNCTION RecordJson RETURNS JsonObject ():
    DEFINE VARIABLE jo AS JsonObject NO-UNDO.
    DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
    jo = NEW JsonObject().
    iValue = phData:BUFFER-FIELD("tipo_anexo_id"):BUFFER-VALUE.
    IF iValue = ? THEN jo:AddNull("tipo_anexo_id"). ELSE jo:Add("tipo_anexo_id", iValue).
    cValue = phData:BUFFER-FIELD("descricao"):BUFFER-VALUE.
    IF cValue = ? THEN jo:AddNull("descricao"). ELSE jo:Add("descricao", cValue).
    RETURN jo.
END FUNCTION.

FUNCTION SameOriginal RETURNS LOGICAL (INPUT pcExpected AS CHARACTER):
    DEFINE VARIABLE cCurrent AS CHARACTER CASE-SENSITIVE NO-UNDO.
    cCurrent = phData:BUFFER-FIELD("descricao"):BUFFER-VALUE.
    IF cCurrent = ? AND pcExpected = ? THEN RETURN TRUE.
    IF cCurrent = ? OR pcExpected = ? THEN RETURN FALSE.
    RETURN cCurrent = pcExpected AND LENGTH(cCurrent) = LENGTH(pcExpected).
END FUNCTION.

PROCEDURE CheckDependencies:
    DEFINE VARIABLE hDependent AS HANDLE NO-UNDO.
    DEFINE VARIABLE k AS INTEGER NO-UNDO.
    DEFINE VARIABLE cParam AS CHARACTER NO-UNDO.
    IF plProFormaConfigured <> TRUE OR plProFormaConfigured = ? THEN
        RUN Fail("TIPO_ANEXO_PROFORMA_CONFIGURATION", "Regra de Pro-Forma ainda nao configurada. Exclusao bloqueada.", 503).
    cParam = TRIM(pcTipoProForma).
    IF cParam = ? OR LENGTH(cParam) = 0 OR LENGTH(cParam) > 10 THEN
        RUN Fail("TIPO_ANEXO_PROFORMA_CONFIGURATION", "Parametro de Pro-Forma invalido. Exclusao bloqueada.", 503).
    DO k = 1 TO LENGTH(cParam):
        IF INDEX("0123456789", SUBSTRING(cParam, k, 1)) = 0 THEN
            RUN Fail("TIPO_ANEXO_PROFORMA_CONFIGURATION", "Parametro de Pro-Forma invalido. Exclusao bloqueada.", 503).
    END.
    iProForma = INTEGER(cParam) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RUN Fail("TIPO_ANEXO_PROFORMA_CONFIGURATION", "Parametro de Pro-Forma fora do limite.", 503).
    IF iProForma = ttChange.recordId THEN
        RUN Fail("TIPO_ANEXO_PROFORMA_IN_USE", "Tipo de anexo configurado para Pro-Forma nao pode ser excluido.", 409).
    DO k = 1 TO 2:
        hDependent = IF k = 1 THEN phContainer ELSE phCompra.
        IF NOT VALID-HANDLE(hDependent) THEN RUN Fail("TIPO_ANEXO_CONFIGURATION", "Dependencias nao configuradas.", 500).
        lFound = hDependent:FIND-FIRST("WHERE " + hDependent:NAME + ".tipos_anexo_id = " + TRIM(STRING(ttChange.recordId)), NO-LOCK) NO-ERROR.
        IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao verificar dependencias", 0).
        IF lFound THEN RUN Fail("TIPO_ANEXO_IN_USE", IF k = 1 THEN
            "Tipo de anexo possui anexos de Container associados." ELSE
            "Tipo de anexo possui anexos de processo de compra associados.", 409).
    END.
END PROCEDURE.

PROCEDURE ReadAll:
    DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
    jaRows = NEW JsonArray().
    CREATE QUERY hQuery.
    hQuery:SET-BUFFERS(phData).
    hQuery:QUERY-PREPARE("FOR EACH " + phData:NAME + " NO-LOCK BY " + phData:NAME + ".tipo_anexo_id").
    hQuery:QUERY-OPEN(). hQuery:GET-FIRST().
    DO WHILE NOT hQuery:QUERY-OFF-END:
        jaRows:Add(RecordJson()). hQuery:GET-NEXT().
    END.
    hQuery:QUERY-CLOSE(). DELETE OBJECT hQuery.
    poResponse:Add("data", jaRows).
END PROCEDURE.

DO ON ERROR UNDO, THROW:
    poResponse = NEW JsonObject().
    IF NOT VALID-HANDLE(phData) OR NOT VALID-OBJECT(poRequest) THEN
        RUN Fail("TIPO_ANEXO_CONFIGURATION", "API de tipos de anexo indisponivel.", 500).
    EXTENT(cNames) = ?.
    cNames = poRequest:GetNames().
    DO i = 1 TO EXTENT(cNames):
        IF LOOKUP(cNames[i], "operation,id,descricao,changes,original") = 0 THEN
            RUN Fail("TIPO_ANEXO_FIELD_INVALID", "Campo nao permitido na requisicao.", 422).
    END.
    IF NOT poRequest:Has("operation") OR poRequest:GetType("operation") <> JsonDataType:STRING THEN
        RUN Fail("TIPO_ANEXO_OPERATION_INVALID", "Informe a operacao.", 422).
    cOperation = poRequest:GetCharacter("operation").
    IF LOOKUP(cOperation, "read,get,create,update,delete,batch") = 0 THEN
        RUN Fail("TIPO_ANEXO_OPERATION_INVALID", "Operacao invalida.", 422).
    IF cOperation = "read" THEN DO:
        poResponse:Add("success", TRUE). RUN ReadAll. RETURN.
    END.
    IF cOperation = "get" THEN DO:
        iId = ReadId(poRequest, "id").
        lFound = phData:FIND-FIRST("WHERE " + phData:NAME + ".tipo_anexo_id = " + TRIM(STRING(iId)), NO-LOCK) NO-ERROR.
        IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na leitura", 0).
        IF NOT lFound THEN RUN Fail("TIPO_ANEXO_NOT_FOUND", "Tipo de anexo nao encontrado.", 404).
        poResponse:Add("success", TRUE). poResponse:Add("data", RecordJson()). RETURN.
    END.
    lBatch = cOperation = "batch".
    IF lBatch THEN DO:
        IF NOT poRequest:Has("changes") OR poRequest:GetType("changes") <> JsonDataType:ARRAY THEN
            RUN Fail("TIPO_ANEXO_VALIDATION", "Informe a lista de alteracoes.", 422).
        jaChanges = poRequest:GetJsonArray("changes").
    END.
    ELSE DO:
        jaChanges = NEW JsonArray(). joChange = NEW JsonObject().
        joChange:Add("operation", cOperation). joChange:Add("clientId", "single").
        IF poRequest:Has("id") THEN DO:
            IF cOperation = "create" THEN RUN Fail("TIPO_ANEXO_ID_IMMUTABLE", "ID e gerado pelo servidor.", 422).
            joChange:Add("id", ReadId(poRequest, "id")).
        END.
        IF cOperation <> "delete" THEN DO:
            joData = NEW JsonObject().
            IF poRequest:Has("descricao") THEN DO:
                IF poRequest:IsNull("descricao") THEN joData:AddNull("descricao").
                ELSE IF poRequest:GetType("descricao") = JsonDataType:STRING THEN joData:Add("descricao", poRequest:GetCharacter("descricao")).
                ELSE RUN Fail("TIPO_ANEXO_VALIDATION", "Descricao deve ser texto.", 422).
            END.
            joChange:Add("data", joData).
        END.
        IF poRequest:Has("original") AND poRequest:GetType("original") = JsonDataType:OBJECT THEN
            joChange:Add("original", poRequest:GetJsonObject("original")).
        jaChanges:Add(joChange).
    END.
    IF jaChanges:Length < 1 OR jaChanges:Length > 100 THEN
        RUN Fail("TIPO_ANEXO_VALIDATION", "O lote deve conter de 1 a 100 alteracoes.", 422).

    /* Preflight completo: nenhum registro e alterado antes de validar o lote. */
    DO iLine = 1 TO jaChanges:Length:
        IF jaChanges:GetType(iLine) <> JsonDataType:OBJECT THEN RUN Fail("TIPO_ANEXO_VALIDATION", "Linha deve ser um objeto.", 422).
        joChange = jaChanges:GetJsonObject(iLine).
        EXTENT(cNames) = ?.
        cNames = joChange:GetNames().
        DO j = 1 TO EXTENT(cNames):
            IF LOOKUP(cNames[j], "operation,clientId,id,data,original") = 0 THEN
                RUN Fail("TIPO_ANEXO_FIELD_INVALID", "Campo nao permitido na linha.", 422).
        END.
        IF NOT joChange:Has("clientId") OR joChange:GetType("clientId") <> JsonDataType:STRING THEN
            RUN Fail("TIPO_ANEXO_VALIDATION", "Identificador da linha obrigatorio.", 422).
        IF LENGTH(joChange:GetCharacter("clientId")) < 1 OR LENGTH(joChange:GetCharacter("clientId")) > 160 THEN
            RUN Fail("TIPO_ANEXO_VALIDATION", "Identificador da linha invalido.", 422).
        DO iClientChar = 1 TO LENGTH(joChange:GetCharacter("clientId")):
            IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:-", SUBSTRING(joChange:GetCharacter("clientId"), iClientChar, 1)) = 0 THEN
                RUN Fail("TIPO_ANEXO_VALIDATION", "Identificador da linha invalido.", 422).
        END.
        IF CAN-FIND(FIRST ttChange WHERE ttChange.clientId = joChange:GetCharacter("clientId")) THEN
            RUN Fail("TIPO_ANEXO_VALIDATION", "Identificador da linha repetido.", 422).
        CREATE ttChange. ASSIGN ttChange.lineNo = iLine ttChange.clientId = joChange:GetCharacter("clientId").
        IF NOT joChange:Has("operation") OR joChange:GetType("operation") <> JsonDataType:STRING THEN
            RUN Fail("TIPO_ANEXO_OPERATION_INVALID", "Operacao da linha invalida.", 422).
        ttChange.op = joChange:GetCharacter("operation").
        IF LOOKUP(ttChange.op, "create,update,delete") = 0 THEN RUN Fail("TIPO_ANEXO_OPERATION_INVALID", "Operacao da linha invalida.", 422).
        IF ttChange.op = "create" THEN DO:
            IF joChange:Has("id") THEN RUN Fail("TIPO_ANEXO_ID_IMMUTABLE", "ID e gerado pelo servidor.", 422).
            IF joChange:Has("original") THEN RUN Fail("TIPO_ANEXO_VALIDATION", "Inclusao nao recebe estado original.", 422).
        END.
        ELSE DO:
            ttChange.recordId = ReadId(joChange, "id").
            IF CAN-FIND(FIRST ttChange WHERE ttChange.lineNo < iLine AND ttChange.op <> "create" AND ttChange.recordId = ReadId(joChange, "id")) THEN
                RUN Fail("TIPO_ANEXO_VALIDATION", "Mesmo registro aparece mais de uma vez no lote.", 422).
            IF lBatch AND (NOT joChange:Has("original") OR joChange:GetType("original") <> JsonDataType:OBJECT) THEN
                RUN Fail("TIPO_ANEXO_VALIDATION", "Informe o estado original da linha.", 422).
            IF joChange:Has("original") THEN DO:
                IF joChange:GetType("original") <> JsonDataType:OBJECT THEN RUN Fail("TIPO_ANEXO_VALIDATION", "Estado original invalido.", 422).
                joOld = joChange:GetJsonObject("original").
                IF NOT joOld:Has("descricao") THEN RUN Fail("TIPO_ANEXO_VALIDATION", "Descricao original obrigatoria.", 422).
                ttChange.original = ReadDescription(joOld). ttChange.hasOriginal = TRUE.
            END.
        END.
        IF ttChange.op <> "delete" THEN DO:
            IF NOT joChange:Has("data") OR joChange:GetType("data") <> JsonDataType:OBJECT THEN
                RUN Fail("TIPO_ANEXO_VALIDATION", "Dados da linha obrigatorios.", 422).
            joData = joChange:GetJsonObject("data").
            IF ttChange.op = "update" AND NOT joData:Has("descricao") THEN
                RUN Fail("TIPO_ANEXO_VALIDATION", "Informe a descricao alterada.", 422).
            ttChange.descricao = ReadDescription(joData).
        END.
        ELSE IF joChange:Has("data") THEN RUN Fail("TIPO_ANEXO_VALIDATION", "Exclusao nao recebe dados para alteracao.", 422).
        VALIDATE ttChange.
    END.

    jaResults = NEW JsonArray().
    jaAuditChanges = NEW JsonArray().
    DO TRANSACTION ON ERROR UNDO, THROW:
        /* Serializa inclusoes pela ultima chave. Indice unico cobre tabela vazia. */
        IF CAN-FIND(FIRST ttChange WHERE ttChange.op = "create") THEN DO:
            lFound = phData:FIND-LAST("", EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF phData:LOCKED THEN RUN Fail("TIPO_ANEXO_BUSY", "Outra inclusao esta em andamento. Tente novamente.", 409).
            IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na geracao do ID", 0).
            iNextId = IF lFound THEN phData:BUFFER-FIELD("tipo_anexo_id"):BUFFER-VALUE ELSE 0.
            IF iNextId = ? THEN RUN Fail("TIPO_ANEXO_CONFIGURATION", "Ultimo ID desconhecido.", 500).
        END.
        FOR EACH ttChange BY ttChange.lineNo:
            iLine = ttChange.lineNo.
            IF ttChange.op = "create" THEN DO:
                joBefore = NEW JsonObject().
                IF iNextId >= 2147483647 THEN RUN Fail("TIPO_ANEXO_ID_LIMIT", "Limite de IDs atingido.", 409).
                iNextId = iNextId + 1.
                IF NOT phData:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Inclusao recusada", 0).
                phData:BUFFER-FIELD("tipo_anexo_id"):BUFFER-VALUE = iNextId.
                ttChange.recordId = iNextId.
            END.
            ELSE DO:
                lFound = phData:FIND-FIRST("WHERE " + phData:NAME + ".tipo_anexo_id = " + TRIM(STRING(ttChange.recordId)), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
                IF phData:LOCKED THEN RUN Fail("TIPO_ANEXO_BUSY", "Registro em uso. Tente novamente.", 409).
                IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na leitura para gravacao", 0).
                IF NOT lFound THEN RUN Fail("TIPO_ANEXO_NOT_FOUND", "Tipo de anexo nao encontrado.", 404).
                IF ttChange.hasOriginal AND NOT SameOriginal(ttChange.original) THEN
                    RUN Fail("TIPO_ANEXO_CHANGED", "Registro alterado por outro usuario. Recarregue antes de salvar.", 409).
                /* O anterior vem do buffer protegido pelo lock, nunca do browser. */
                joBefore = RecordJson().
            END.
            IF ttChange.op = "delete" THEN DO:
                joAfter = NEW JsonObject().
                RUN CheckDependencies.
                IF NOT phData:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao recusada", 0).
            END.
            ELSE DO:
                phData:BUFFER-FIELD("descricao"):BUFFER-VALUE = ttChange.descricao.
                IF NOT phData:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Gravacao recusada", 0).
                joAfter = RecordJson().
                IF NOT lBatch THEN joSingle = joAfter.
            END.
            joResult = NEW JsonObject(). joResult:Add("clientId", ttChange.clientId).
            joResult:Add("operation", ttChange.op). joResult:Add("id", ttChange.recordId). jaResults:Add(joResult).
            iId = ttChange.recordId.
            IF lBatch THEN DO:
                joAuditChange = NEW JsonObject().
                joAuditChange:Add("clientId", ttChange.clientId).
                joAuditChange:Add("operation", ttChange.op).
                joAuditChange:Add("recordId", ttChange.recordId).
                joAuditChange:Add("before", joBefore).
                joAuditChange:Add("after", joAfter).
                jaAuditChanges:Add(joAuditChange).
            END.
        END.
        /* Monta a lista ainda dentro da transacao; erro de leitura tambem desfaz o lote. */
        IF lBatch THEN RUN ReadAll.
    END.
    poResponse:Add("success", TRUE).
    IF lBatch THEN DO:
        poResponse:Add("results", jaResults).
    END.
    ELSE IF cOperation <> "delete" THEN poResponse:Add("data", joSingle).
    /* So publicar snapshots depois de confirmar a transacao inteira. */
    joAudit = NEW JsonObject().
    joAudit:Add("version", 1).
    joAudit:Add("source", "progress-transaction").
    joAudit:Add("resource", "tipos_anexo").
    joAudit:Add("operation", cOperation).
    IF lBatch THEN joAudit:Add("changes", jaAuditChanges).
    ELSE DO:
        joAudit:Add("recordId", iId).
        joAudit:Add("before", joBefore).
        joAudit:Add("after", joAfter).
    END.
    poResponse:Add("audit", joAudit).
    CATCH e AS Progress.Lang.Error:
        IF NOT poResponse:Has("error") THEN
            RUN BuildError("TIPO_ANEXO_PERSISTENCE_REJECTED", "Operacao recusada pelo banco. Nenhuma alteracao do lote confirmada.", 409).
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hQuery) THEN DO:
            hQuery:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hQuery NO-ERROR.
        END.
        IF VALID-HANDLE(phData) THEN phData:BUFFER-RELEASE() NO-ERROR.
        IF VALID-HANDLE(phContainer) THEN phContainer:BUFFER-RELEASE() NO-ERROR.
        IF VALID-HANDLE(phCompra) THEN phCompra:BUFFER-RELEASE() NO-ERROR.
    END FINALLY.
END.

PROCEDURE BuildError:
    DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
    DEFINE VARIABLE joError AS JsonObject NO-UNDO.
    DEFINE VARIABLE joDetails AS JsonObject NO-UNDO.
    poResponse = NEW JsonObject(). joError = NEW JsonObject().
    poResponse:Add("success", FALSE). joError:Add("code", pcCode).
    joError:Add("message", (IF iLine > 0 THEN "Linha " + TRIM(STRING(iLine)) + ": " ELSE "") + pcMessage).
    joError:Add("status", piStatus).
    joDetails = NEW JsonObject(). joDetails:Add("line", iLine). joError:Add("details", joDetails).
    poResponse:Add("error", joError).
END PROCEDURE.
PROCEDURE Fail:
    DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
    RUN BuildError(pcCode, pcMessage, piStatus).
    UNDO, THROW NEW Progress.Lang.AppError(pcCode, 0).
END PROCEDURE.

/* Servico interno: o wrapper fornece o buffer fixo; JSON nunca escolhe tabela. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cNome AS CHARACTER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iOtherId AS INTEGER NO-UNDO.
DEFINE VARIABLE iEms2 AS INTEGER NO-UNDO.
DEFINE VARIABLE iEms5 AS INTEGER NO-UNDO.
DEFINE VARIABLE iNextId AS INTEGER NO-UNDO.
DEFINE VARIABLE iName AS INTEGER NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
DEFINE VARIABLE joBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE joResult AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.

FUNCTION FindFailed RETURNS LOGICAL ():
  DEFINE VARIABLE iMessage AS INTEGER NO-UNDO.
  DO iMessage = 1 TO ERROR-STATUS:NUM-MESSAGES:
    /* 565 e o resultado normal de FIND FIRST/LAST sem registro. */
    IF ERROR-STATUS:GET-NUMBER(iMessage) <> 565 THEN RETURN TRUE.
  END.
  RETURN FALSE.
END FUNCTION.

FUNCTION ReadInteger RETURNS INTEGER (pcName AS CHARACTER, plRequired AS LOGICAL):
  DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iChar AS INTEGER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  IF NOT poRequest:Has(pcName) OR poRequest:IsNull(pcName) THEN DO:
    IF plRequired THEN RUN Fail("EMPRESA_VALIDATION", "Informe um ID inteiro.", 422).
    RETURN IF plRequired THEN ? ELSE 0.
  END.
  IF poRequest:GetType(pcName) = JsonDataType:STRING THEN cText = TRIM(poRequest:GetCharacter(pcName)).
  ELSE IF poRequest:GetType(pcName) = JsonDataType:NUMBER THEN cText = poRequest:GetJsonText(pcName).
  ELSE cText = "invalido".
  IF cText = "" AND NOT plRequired THEN RETURN 0.
  IF cText = "" OR LENGTH(cText) > 11 OR cText = "-" THEN DO:
    RUN Fail("EMPRESA_VALIDATION", "Valor inteiro invalido em " + pcName + ".", 422).
    RETURN ?.
  END.
  DO iChar = 1 TO LENGTH(cText):
    IF iChar = 1 AND SUBSTRING(cText, 1, 1) = "-" THEN NEXT.
    IF INDEX("0123456789", SUBSTRING(cText, iChar, 1)) = 0 THEN DO:
      RUN Fail("EMPRESA_VALIDATION", "Valor inteiro invalido em " + pcName + ".", 422).
      RETURN ?.
    END.
  END.
  dValue = DECIMAL(cText).
  IF dValue < -2147483648 OR dValue > 2147483647 THEN DO:
    RUN Fail("EMPRESA_VALIDATION", "Inteiro fora do limite em " + pcName + ".", 422).
    RETURN ?.
  END.
  RETURN INTEGER(dValue).
END FUNCTION.

FUNCTION RecordJson RETURNS JsonObject ():
  DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
  DEFINE VARIABLE iField AS INTEGER NO-UNDO.
  DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
  joRow = NEW JsonObject().
  DO iField = 1 TO 4:
    cField = ENTRY(iField, "empresa_id,nome,cod_emp_ems2,cod_emp_ems5").
    IF phData:BUFFER-FIELD(cField):BUFFER-VALUE = ? THEN joRow:AddNull(cField).
    ELSE IF cField = "nome" THEN DO:
      cValue = phData:BUFFER-FIELD(cField):BUFFER-VALUE.
      joRow:Add(cField, cValue).
    END.
    ELSE DO:
      iValue = phData:BUFFER-FIELD(cField):BUFFER-VALUE.
      joRow:Add(cField, iValue).
    END.
  END.
  RETURN joRow.
END FUNCTION.

FUNCTION CanDeleteEmpresa RETURNS LOGICAL (piId AS INTEGER):
  DEFINE VARIABLE hDependent AS HANDLE NO-UNDO.
  DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iTable AS INTEGER NO-UNDO.
  DEFINE VARIABLE lRelated AS LOGICAL NO-UNDO.
  /* Vinculos confirmados no dicionario espec, todos por empresa_id. */
  IF phData:DBNAME = "espec" THEN DO iTable = 1 TO 3:
    cTable = ENTRY(iTable, "despesas_impostos,empresas_despesa,procs_compra").
    DO ON ERROR UNDO, THROW:
      CREATE BUFFER hDependent FOR TABLE ("espec." + cTable) BUFFER-NAME "bEmpresaDependente".
      lRelated = hDependent:FIND-FIRST("WHERE bEmpresaDependente.empresa_id = " + TRIM(STRING(piId)), NO-LOCK) NO-ERROR.
      IF FindFailed() THEN
        UNDO, THROW NEW Progress.Lang.AppError("Falha ao verificar vinculos", 0).
      IF lRelated THEN DO:
        RUN Fail("EMPRESA_IN_USE", "Empresa possui vinculos em " + cTable + ".", 409).
        RETURN FALSE.
      END.
      FINALLY:
        IF VALID-HANDLE(hDependent) THEN DELETE OBJECT hDependent NO-ERROR.
      END FINALLY.
    END.
  END.
  RETURN TRUE.
END FUNCTION.

poResponse = NEW JsonObject().
DO ON ERROR UNDO, THROW:
  IF NOT VALID-HANDLE(phData) OR NOT VALID-OBJECT(poRequest) THEN DO:
    RUN Fail("EMPRESA_CONFIGURATION", "API de empresas indisponivel.", 500). RETURN.
  END.
  cNames = poRequest:GetNames().
  DO iName = 1 TO EXTENT(cNames):
    IF LOOKUP(cNames[iName], "operation,id,empresa_id,nome,cod_emp_ems2,cod_emp_ems5") = 0 THEN DO:
      RUN Fail("EMPRESA_FIELD_INVALID", "Campo nao permitido na API de empresas.", 422). RETURN.
    END.
  END.
  IF NOT poRequest:Has("operation") THEN DO:
    RUN Fail("EMPRESA_OPERATION_INVALID", "Informe a operacao de empresas.", 422). RETURN.
  END.
  IF poRequest:GetType("operation") <> JsonDataType:STRING THEN DO:
    RUN Fail("EMPRESA_OPERATION_INVALID", "Operacao de empresas invalida.", 422). RETURN.
  END.
  cOperation = poRequest:GetCharacter("operation").
  IF LOOKUP(cOperation, "read,get,create,update,delete") = 0 THEN DO:
    RUN Fail("EMPRESA_OPERATION_INVALID", "Operacao de empresas invalida.", 422). RETURN.
  END.

  IF cOperation = "read" THEN DO:
    jaData = NEW JsonArray().
    CREATE QUERY hQuery.
    hQuery:SET-BUFFERS(phData).
    hQuery:QUERY-PREPARE("FOR EACH " + phData:NAME + " NO-LOCK BY " + phData:NAME + ".empresa_id").
    hQuery:QUERY-OPEN().
    hQuery:GET-FIRST().
    DO WHILE NOT hQuery:QUERY-OFF-END:
      jaData:Add(RecordJson()).
      hQuery:GET-NEXT().
    END.
    poResponse:Add("data", jaData). RETURN.
  END.

  IF cOperation = "create" AND (poRequest:Has("id") OR poRequest:Has("empresa_id")) THEN DO:
    RUN Fail("EMPRESA_ID_IMMUTABLE", "O ID da empresa e gerado pelo servidor.", 422). RETURN.
  END.
  IF cOperation <> "create" THEN DO:
    IF poRequest:Has("id") THEN iId = ReadInteger("id", TRUE).
    ELSE iId = ReadInteger("empresa_id", TRUE).
    IF poResponse:Has("error") THEN RETURN.
    IF poRequest:Has("id") AND poRequest:Has("empresa_id") THEN DO:
      iOtherId = ReadInteger("empresa_id", TRUE).
      IF poResponse:Has("error") THEN RETURN.
      IF iId <> iOtherId THEN DO:
        RUN Fail("EMPRESA_ID_IMMUTABLE", "O ID da empresa nao pode ser alterado.", 422). RETURN.
      END.
    END.
  END.
  IF cOperation = "get" THEN DO:
    lFound = phData:FIND-FIRST("WHERE " + phData:NAME + ".empresa_id = " + TRIM(STRING(iId)), NO-LOCK) NO-ERROR.
    IF NOT lFound THEN DO:
      RUN Fail("EMPRESA_NOT_FOUND", "Empresa nao encontrada.", 404). RETURN.
    END.
    poResponse:Add("data", RecordJson()). RETURN.
  END.

  IF cOperation = "create" OR cOperation = "update" THEN DO:
    cNome = "".
    IF poRequest:Has("nome") AND NOT poRequest:IsNull("nome") THEN DO:
      IF poRequest:GetType("nome") <> JsonDataType:STRING THEN DO:
        RUN Fail("EMPRESA_VALIDATION", "Nome deve ser texto.", 422). RETURN.
      END.
      cNome = poRequest:GetCharacter("nome").
    END.
    IF LENGTH(cNome) > 50 THEN DO:
      RUN Fail("EMPRESA_VALIDATION", "Nome deve ter ate 50 caracteres.", 422). RETURN.
    END.
    iEms2 = ReadInteger("cod_emp_ems2", FALSE).
    IF poResponse:Has("error") THEN RETURN.
    iEms5 = ReadInteger("cod_emp_ems5", FALSE).
    IF poResponse:Has("error") THEN RETURN.
  END.

  DO TRANSACTION ON ERROR UNDO, THROW:
    joBefore = NEW JsonObject().
    IF cOperation = "create" THEN DO:
      lFound = phData:FIND-LAST("", EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
      IF phData:LOCKED THEN DO:
        RUN Fail("EMPRESA_BUSY", "Outra inclusao esta em andamento. Tente novamente.", 409). RETURN.
      END.
      IF FindFailed() THEN
        UNDO, THROW NEW Progress.Lang.AppError("Falha ao gerar ID", 0).
      iNextId = 1.
      IF lFound THEN DO:
        IF phData:BUFFER-FIELD("empresa_id"):BUFFER-VALUE >= 2147483647 THEN DO:
          RUN Fail("EMPRESA_ID_LIMIT", "Limite de IDs de empresas atingido.", 409). RETURN.
        END.
        iNextId = phData:BUFFER-FIELD("empresa_id"):BUFFER-VALUE + 1.
      END.
      phData:BUFFER-CREATE().
      phData:BUFFER-FIELD("empresa_id"):BUFFER-VALUE = iNextId.
      iId = iNextId.
    END.
    ELSE DO:
      lFound = phData:FIND-FIRST("WHERE " + phData:NAME + ".empresa_id = " + TRIM(STRING(iId)), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
      IF phData:LOCKED THEN DO:
        RUN Fail("EMPRESA_BUSY", "Empresa em uso. Tente novamente.", 409). RETURN.
      END.
      IF NOT lFound THEN DO:
        RUN Fail("EMPRESA_NOT_FOUND", "Empresa nao encontrada.", 404). RETURN.
      END.
      /* O anterior vem do registro sob o bloqueio da propria escrita. */
      DELETE OBJECT joBefore.
      joBefore = RecordJson().
    END.
    IF cOperation = "delete" THEN DO:
      IF NOT CanDeleteEmpresa(iId) THEN RETURN.
      IF NOT phData:BUFFER-DELETE() THEN
        UNDO, THROW NEW Progress.Lang.AppError("Exclusao recusada", 0).
    END.
    ELSE DO:
      IF cOperation = "create" OR poRequest:Has("nome") THEN phData:BUFFER-FIELD("nome"):BUFFER-VALUE = cNome.
      IF cOperation = "create" OR poRequest:Has("cod_emp_ems2") THEN phData:BUFFER-FIELD("cod_emp_ems2"):BUFFER-VALUE = iEms2.
      IF cOperation = "create" OR poRequest:Has("cod_emp_ems5") THEN phData:BUFFER-FIELD("cod_emp_ems5"):BUFFER-VALUE = iEms5.
      IF NOT phData:BUFFER-VALIDATE() THEN
        UNDO, THROW NEW Progress.Lang.AppError("Gravacao recusada", 0).
      joResult = RecordJson().
    END.
  END.
  /* Objetos JSON sao NO-UNDO: publicar apenas apos a transacao terminar. */
  IF cOperation = "delete" THEN poResponse:Add("success", TRUE).
  ELSE poResponse:Add("data", joResult).
  joAudit = NEW JsonObject().
  joAudit:Add("version", 1).
  joAudit:Add("source", "progress-transaction").
  joAudit:Add("resource", "empresas").
  joAudit:Add("operation", cOperation).
  joAudit:Add("recordId", iId).
  joAudit:Add("before", joBefore).
  IF cOperation = "delete" THEN joAudit:Add("after", NEW JsonObject()).
  ELSE joAudit:Add("after", CAST(joResult:Clone(), JsonObject)).
  poResponse:Add("audit", joAudit).
  CATCH e AS Progress.Lang.Error:
    LOG-MANAGER:WRITE-MESSAGE("EmpresasCrudService: " + e:GetMessage(1), "EMPRESAS") NO-ERROR.
    RUN Fail("EMPRESA_PERSISTENCE_REJECTED", "Operacao de empresa recusada pelo banco. Nenhuma alteracao confirmada.", 409).
  END CATCH.
  FINALLY:
    IF VALID-HANDLE(hQuery) THEN DO:
      hQuery:QUERY-CLOSE() NO-ERROR.
      DELETE OBJECT hQuery NO-ERROR.
    END.
    IF VALID-HANDLE(phData) THEN phData:BUFFER-RELEASE() NO-ERROR.
  END FINALLY.
END.

PROCEDURE Fail:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  DEFINE VARIABLE joError AS JsonObject NO-UNDO.
  poResponse = NEW JsonObject().
  poResponse:Add("success", FALSE).
  joError = NEW JsonObject().
  joError:Add("code", pcCode).
  joError:Add("message", pcMessage).
  joError:Add("status", piStatus).
  poResponse:Add("error", joError).
END PROCEDURE.

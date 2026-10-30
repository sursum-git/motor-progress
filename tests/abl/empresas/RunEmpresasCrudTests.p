BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttEmpresas
  FIELD empresa_id AS INTEGER
  FIELD nome AS CHARACTER
  FIELD cod_emp_ems2 AS INTEGER
  FIELD cod_emp_ems5 AS INTEGER
  INDEX ind_empresa IS PRIMARY UNIQUE empresa_id.
/* Restricao de armazenamento apenas da fixture para provocar falha depois
   do inicio da escrita; nao altera schema ou dados de banco. */
DEFINE TEMP-TABLE ttRejected
  FIELD empresa_id AS INTEGER
  FIELD nome AS CHARACTER
  FIELD cod_emp_ems2 AS INTEGER
  FIELD cod_emp_ems5 AS INTEGER
  INDEX ind_empresa IS PRIMARY UNIQUE empresa_id
  INDEX unique_ems2 IS UNIQUE cod_emp_ems2.
DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE joBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE joAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE cAuditNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.

FUNCTION IsEmptyJsonObject RETURNS LOGICAL (poObject AS JsonObject):
  DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.
  /* A formatacao de GetJsonText no 12.2 pode incluir espacos e quebras.
     Remover somente whitespace JSON; qualquer propriedade continua invalida. */
  cJson = STRING(poObject:GetJsonText()).
  cJson = REPLACE(REPLACE(REPLACE(REPLACE(cJson, " ", ""), CHR(9), ""), CHR(10), ""), CHR(13), "").
  RETURN cJson = CHR(123) + CHR(125).
END FUNCTION.

OUTPUT TO "empresas-tests.log".
DO ON ERROR UNDO, THROW:
  IF SEARCH("EmpresasCrudService.p") = ? THEN
    UNDO, THROW NEW Progress.Lang.AppError("Servico ainda nao implementado", 0).

  RUN NewRequest("read").
  RUN EmpresasCrud.p (INPUT joRequest, OUTPUT joResponse).
  RUN AssertError("EMPRESA_AUTH_REQUIRED").
  joRequest:Add("_integrationToken", "invalido").
  RUN EmpresasCrud.p (INPUT joRequest, OUTPUT joResponse).
  RUN AssertError("EMPRESA_AUTH_REQUIRED").

  RUN NewRequest("create").
  joRequest:Add("nome", "Empresa São José").
  joRequest:Add("cod_emp_ems2", "").
  RUN ExecuteRequest.
  RUN AssertTrue(NOT joResponse:Has("error"), "create sucesso").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetInteger("empresa_id") = 1, "ID gerado").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetInteger("cod_emp_ems2") = 0, "vazio vira zero").
  RUN AssertAudit("create", 1).
  RUN AssertTrue(IsEmptyJsonObject(joBefore), "create anterior vazio JSON=" + STRING(joBefore:GetJsonText())).
  RUN AssertRow(joAfter, 1, "Empresa São José", 0, 0).

  RUN NewRequest("read"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonArray("data"):Length = 1, "lista completa").
  RUN AssertTrue(joResponse:GetJsonArray("data"):GetJsonObject(1):GetCharacter("nome") = "Empresa São José", "acentos preservados").
  RUN AssertTrue(NOT joResponse:Has("audit"), "read sem snapshot de escrita").

  RUN NewRequest("get"). joRequest:Add("id", 1). RUN ExecuteRequest.
  RUN AssertTrue(NOT joResponse:Has("audit"), "get sem snapshot de escrita").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetInteger("empresa_id") = 1, "get existente preservado").

  RUN NewRequest("get"). joRequest:Add("id", 99). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_NOT_FOUND").

  RUN NewRequest("update"). joRequest:Add("id", 1). joRequest:Add("nome", FILL("a", 51)). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_VALIDATION").
  FIND ttEmpresas WHERE ttEmpresas.empresa_id = 1 NO-LOCK.
  RUN AssertTrue(ttEmpresas.nome = "Empresa São José", "falha nao altera registro").
  RELEASE ttEmpresas.

  RUN NewRequest("update"). joRequest:Add("id", 1). joRequest:Add("empresa_id", 2). joRequest:Add("nome", "Nao gravar"). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_ID_IMMUTABLE").

  RUN NewRequest("update"). joRequest:Add("id", 1). joRequest:Add("cod_emp_ems2", 1.5). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_VALIDATION").

  RUN NewRequest("update"). joRequest:Add("id", 1). joRequest:Add("cod_emp_ems2", 2147483648). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_VALIDATION").

  RUN NewRequest("update"). joRequest:Add("id", 1). joRequest:Add("nome", FILL("ã", 50)). joRequest:Add("cod_emp_ems5", -10). RUN ExecuteRequest.
  RUN AssertTrue(NOT joResponse:Has("error"), "50 caracteres unicode aceitos").
  RUN AssertTrue(LENGTH(joResponse:GetJsonObject("data"):GetCharacter("nome")) = 50, "comprimento unicode").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetInteger("cod_emp_ems5") = -10, "inteiro negativo preservado").
  RUN AssertAudit("update", 1).
  RUN AssertRow(joBefore, 1, "Empresa São José", 0, 0).
  RUN AssertRow(joAfter, 1, FILL("ã", 50), 0, -10).

  RUN NewRequest("create"). joRequest:Add("empresa_id", 999). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_ID_IMMUTABLE").

  RUN NewRequest("create"). joRequest:Add("nome", "Segunda"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetInteger("empresa_id") = 2, "segundo ID unico").

  /* O anterior deve vir do buffer real, inclusive null, nunca do request. */
  FIND ttEmpresas WHERE ttEmpresas.empresa_id = 2 EXCLUSIVE-LOCK.
  ASSIGN ttEmpresas.nome = ? ttEmpresas.cod_emp_ems2 = ? ttEmpresas.cod_emp_ems5 = ?.
  VALIDATE ttEmpresas. RELEASE ttEmpresas.
  RUN NewRequest("update"). joRequest:Add("id", 2). joRequest:Add("nome", ""). joRequest:Add("cod_emp_ems2", 0). RUN ExecuteRequest.
  RUN AssertAudit("update", 2).
  RUN AssertTrue(joBefore:IsNull("nome") AND joBefore:IsNull("cod_emp_ems2") AND joBefore:IsNull("cod_emp_ems5"), "anterior preserva null do buffer").
  RUN AssertTrue(joAfter:GetCharacter("nome") = "" AND joAfter:GetInteger("cod_emp_ems2") = 0 AND joAfter:IsNull("cod_emp_ems5"), "posterior distingue vazio zero e null nao alterado").

  RUN NewRequest("update"). joRequest:Add("id", 2). joRequest:Add("before", NEW JsonObject()). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_FIELD_INVALID").

  RUN NewRequest("update"). joRequest:Add("id", 2). joRequest:Add("sql", "delete from empresas"). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_FIELD_INVALID").

  RUN NewRequest("delete"). joRequest:Add("id", 1). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"), "delete sucesso").
  RUN AssertAudit("delete", 1).
  RUN AssertRow(joBefore, 1, FILL("ã", 50), 0, -10).
  RUN AssertTrue(IsEmptyJsonObject(joAfter), "delete posterior vazio JSON=" + STRING(joAfter:GetJsonText())).
  RUN NewRequest("delete"). joRequest:Add("id", 1). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_NOT_FOUND").

  RUN NewRequest("execute"). RUN ExecuteRequest.
  RUN AssertError("EMPRESA_OPERATION_INVALID").

  CREATE ttRejected.
  ASSIGN ttRejected.empresa_id = 1 ttRejected.nome = "Original" ttRejected.cod_emp_ems2 = 10 ttRejected.cod_emp_ems5 = 5.
  VALIDATE ttRejected. RELEASE ttRejected.
  CREATE ttRejected.
  ASSIGN ttRejected.empresa_id = 2 ttRejected.nome = "Indice ocupado" ttRejected.cod_emp_ems2 = 20 ttRejected.cod_emp_ems5 = 7.
  VALIDATE ttRejected. RELEASE ttRejected.
  RUN NewRequest("update"). joRequest:Add("id", 1). joRequest:Add("nome", "Nao confirmar"). joRequest:Add("cod_emp_ems2", 20).
  RUN EmpresasCrudService.p (INPUT BUFFER ttRejected:HANDLE, INPUT joRequest, OUTPUT joResponse).
  RUN AssertError("EMPRESA_PERSISTENCE_REJECTED").
  FIND ttRejected WHERE ttRejected.empresa_id = 1 NO-LOCK.
  RUN AssertTrue(ttRejected.nome = "Original" AND ttRejected.cod_emp_ems2 = 10 AND ttRejected.cod_emp_ems5 = 5, "rollback restaura todos os campos apos falha de indice").
  RELEASE ttRejected.
  RUN NewRequest("create"). joRequest:Add("nome", "Nao incluir"). joRequest:Add("cod_emp_ems2", 20).
  RUN EmpresasCrudService.p (INPUT BUFFER ttRejected:HANDLE, INPUT joRequest, OUTPUT joResponse).
  RUN AssertError("EMPRESA_PERSISTENCE_REJECTED").
  RUN AssertTrue(NOT CAN-FIND(ttRejected WHERE ttRejected.empresa_id = 3), "rollback remove inclusao rejeitada").
  PUT UNFORMATTED "PASS: " iPassed " verificacoes CRUD em temp-table isolada" SKIP.
  CATCH e AS Progress.Lang.Error:
    PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
  END CATCH.
END.
OUTPUT CLOSE.
QUIT.

PROCEDURE NewRequest:
  DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
  joRequest = NEW JsonObject().
  joRequest:Add("operation", pcOperation).
END PROCEDURE.

PROCEDURE ExecuteRequest:
  RUN EmpresasCrudService.p (INPUT BUFFER ttEmpresas:HANDLE, INPUT joRequest, OUTPUT joResponse).
  IF joResponse:Has("error") THEN
    PUT UNFORMATTED "Resposta: " STRING(joResponse:GetJsonText()) SKIP.
END PROCEDURE.

PROCEDURE AssertTrue:
  DEFINE INPUT PARAMETER plCondition AS LOGICAL NO-UNDO.
  DEFINE INPUT PARAMETER pcDescription AS CHARACTER NO-UNDO.
  IF plCondition <> TRUE OR plCondition = ? THEN
    UNDO, THROW NEW Progress.Lang.AppError(pcDescription, 0).
  iPassed = iPassed + 1.
END PROCEDURE.

PROCEDURE AssertError:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  RUN AssertTrue(joResponse:Has("error"), "esperava erro " + pcCode).
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetCharacter("code") = pcCode, "codigo " + pcCode).
  RUN AssertTrue(NOT joResponse:Has("audit"), "erro nao confirma snapshot de escrita").
END PROCEDURE.

PROCEDURE AssertAudit:
  DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piId AS INTEGER NO-UNDO.
  RUN AssertTrue(joResponse:Has("audit"), pcOperation + " retorna snapshot transacional confirmado").
  joAudit = joResponse:GetJsonObject("audit").
  RUN AssertTrue(joAudit:GetInteger("version") = 1 AND joAudit:GetCharacter("source") = "progress-transaction", "versao e procedencia transacional").
  RUN AssertTrue(joAudit:GetCharacter("resource") = "empresas" AND joAudit:GetCharacter("operation") = pcOperation AND joAudit:GetInteger("recordId") = piId, "audit vinculado a recurso operacao e ID real").
  joBefore = joAudit:GetJsonObject("before").
  joAfter = joAudit:GetJsonObject("after").
END PROCEDURE.

PROCEDURE AssertRow:
  DEFINE INPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE INPUT PARAMETER piId AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pcNome AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piEms2 AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER piEms5 AS INTEGER NO-UNDO.
  cAuditNames = poRow:GetNames().
  RUN AssertTrue(EXTENT(cAuditNames) = 4, "snapshot conserva os quatro campos publicos").
  RUN AssertTrue(poRow:GetInteger("empresa_id") = piId AND poRow:GetCharacter("nome") = pcNome AND poRow:GetInteger("cod_emp_ems2") = piEms2 AND poRow:GetInteger("cod_emp_ems5") = piEms5, "snapshot reflete os valores reais do registro").
END PROCEDURE.

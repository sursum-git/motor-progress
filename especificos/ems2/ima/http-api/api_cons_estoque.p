/* API de consulta: JSON -> clienteSaldoPV -> JSON. Nao grava tabelas WP. */
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esbo/boSaldoPV.i}
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE sucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE mensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE itens AS JsonArray NO-UNDO.
DEFINE VARIABLE saldos AS JsonArray NO-UNDO.
DEFINE VARIABLE rowJSON AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 RUN esapi/estoque/EstoqueJsonParser.p(poRequest, OUTPUT TABLE ttFiltroSaldoPV, OUTPUT TABLE ttSelecaoSaldoPV).
 RUN esapi/estoque/EstoqueUsuarioEscopo.p(INPUT-OUTPUT TABLE ttFiltroSaldoPV).
 RUN esbo/clienteSaldoPV.p(INPUT TABLE ttFiltroSaldoPV, INPUT TABLE ttSelecaoSaldoPV,
  OUTPUT TABLE ttItensSaldoPV, OUTPUT TABLE ttSaldoPV, OUTPUT sucesso, OUTPUT mensagem).
 IF NOT sucesso THEN UNDO, THROW NEW AppError(mensagem,0).
 ASSIGN itens = NEW JsonArray() saldos = NEW JsonArray().
 FOR EACH ttItensSaldoPV BY ttItensSaldoPV.itCodigo:
  RUN serializeRow(INPUT BUFFER ttItensSaldoPV:HANDLE, OUTPUT rowJSON).
  itens:Add(rowJSON).
 END.
 FOR EACH ttSaldoPV BY ttSaldoPV.itCodigo BY ttSaldoPV.origem BY ttSaldoPV.codEstab
  BY ttSaldoPV.nrContainer BY ttSaldoPV.codRefer BY ttSaldoPV.linhaOrigem:
  RUN serializeRow(INPUT BUFFER ttSaldoPV:HANDLE, OUTPUT rowJSON).
  saldos:Add(rowJSON).
 END.
 poResponse = NEW JsonObject().
 poResponse:Add("success", TRUE).
 poResponse:Add("totalItens", itens:Length).
 poResponse:Add("totalSaldos", saldos:Length).
 poResponse:Add("itens", itens).
 poResponse:Add("saldos", saldos).
 CATCH erro AS Progress.Lang.Error:
  poResponse = NEW JsonObject().
  poResponse:Add("success", FALSE).
  poResponse:Add("error", erro:GetMessage(1)).
  poResponse:Add("totalItens", 0).
  poResponse:Add("totalSaldos", 0).
  poResponse:Add("itens", NEW JsonArray()).
  poResponse:Add("saldos", NEW JsonArray()).
 END CATCH.
END.
PROCEDURE serializeRow:
 DEFINE INPUT PARAMETER sourceBuffer AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER objectJSON AS JsonObject NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
 objectJSON = NEW JsonObject().
 DO k = 1 TO sourceBuffer:NUM-FIELDS:
  fieldHandle = sourceBuffer:BUFFER-FIELD(k).
  IF fieldHandle:BUFFER-VALUE = ? THEN objectJSON:AddNull(fieldHandle:NAME).
  ELSE CASE fieldHandle:DATA-TYPE:
   WHEN "CHARACTER" THEN objectJSON:Add(fieldHandle:NAME, STRING(fieldHandle:BUFFER-VALUE)).
   WHEN "INTEGER" THEN objectJSON:Add(fieldHandle:NAME, INTEGER(fieldHandle:BUFFER-VALUE)).
   WHEN "DECIMAL" THEN objectJSON:Add(fieldHandle:NAME, DECIMAL(fieldHandle:BUFFER-VALUE)).
   WHEN "LOGICAL" THEN objectJSON:Add(fieldHandle:NAME, LOGICAL(fieldHandle:BUFFER-VALUE)).
   OTHERWISE UNDO, THROW NEW AppError("Tipo de saida nao suportado",0).
  END CASE.
 END.
END PROCEDURE.

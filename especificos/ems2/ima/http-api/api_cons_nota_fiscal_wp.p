/* Mesmo contrato JsonObject da API de pedidos; login recebido e metadado. */
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esbo/boConsNotaFiscal.i}
{esapi/consulta-notas/ttFiltroDevolucoes.i}
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE login AS CHARACTER NO-UNDO.
DEFINE VARIABLE pagina AS CHARACTER NO-UNDO.
DEFINE VARIABLE filtro AS CHARACTER NO-UNDO.
DEFINE VARIABLE codWp AS CHARACTER NO-UNDO.
DEFINE VARIABLE total AS INTEGER NO-UNDO.
DEFINE VARIABLE inserted AS INTEGER NO-UNDO.
poResponse = NEW JsonObject().
DO ON ERROR UNDO, THROW:
 IF TRANSACTION THEN UNDO, THROW NEW AppError("API requer transacao raiz propria",0).
 /* Toda validacao de filtros/metadata antecede a consulta. */
 RUN esapi/consulta-notas/ConsultaNotasJsonParser.p(poRequest, OUTPUT TABLE ttFiltroDevolucoes,
  OUTPUT login, OUTPUT pagina, OUTPUT filtro).
 RUN esapi/consulta-notas/ConsultaNotasUsuarioEscopo.p(login, INPUT-OUTPUT TABLE ttFiltroDevolucoes).
 RUN esapi/consulta-notas/ConsultarNotasFiscais.p(INPUT TABLE ttFiltroDevolucoes, OUTPUT TABLE tt-NF).
 FOR EACH tt-NF: total = total + 1. END.
 RUN esapi/consulta-notas/ConsultaNotasWpWriter.p(INPUT TABLE tt-NF, login, pagina, filtro,
  OUTPUT codWp, OUTPUT inserted).
 poResponse:Add("success",TRUE).
 poResponse:Add("codWp",codWp).
 poResponse:Add("total",total).
 poResponse:Add("inserted",inserted).
 CATCH e AS Progress.Lang.Error:
  poResponse = NEW JsonObject().
  poResponse:Add("success",FALSE).
  poResponse:Add("error",e:GetMessage(1)).
 END CATCH.
END.


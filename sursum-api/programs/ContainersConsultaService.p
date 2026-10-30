/* Consulta somente leitura. O wrapper fornece tres buffers fixos; o JSON
   nunca escolhe tabelas, campos ou expressoes ABL. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSituacoes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmitente AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE iName AS INTEGER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iOtherId AS INTEGER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.

FUNCTION FindFailed RETURNS LOGICAL ():
  DEFINE VARIABLE iMessage AS INTEGER NO-UNDO.
  DO iMessage = 1 TO ERROR-STATUS:NUM-MESSAGES:
    /* FIND sem registro e resultado normal, nunca esconder outro erro. */
    IF ERROR-STATUS:GET-NUMBER(iMessage) <> 565 THEN RETURN TRUE.
  END.
  RETURN FALSE.
END FUNCTION.

FUNCTION ReadId RETURNS INTEGER (pcName AS CHARACTER):
  DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iChar AS INTEGER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  IF NOT poRequest:Has(pcName) OR poRequest:IsNull(pcName) THEN RETURN ?.
  CASE poRequest:GetType(pcName):
    WHEN JsonDataType:STRING THEN cText = poRequest:GetCharacter(pcName).
    WHEN JsonDataType:NUMBER THEN cText = poRequest:GetJsonText(pcName).
    OTHERWISE RETURN ?.
  END CASE.
  IF cText = "" OR LENGTH(cText) > 10 THEN RETURN ?.
  DO iChar = 1 TO LENGTH(cText):
    IF INDEX("0123456789", SUBSTRING(cText, iChar, 1)) = 0 THEN RETURN ?.
  END.
  /* Apenas digitos: conversao sem separadores e independente de cultura. */
  dValue = DECIMAL(cText).
  IF dValue < 1 OR dValue > 2147483647 THEN RETURN ?.
  RETURN INTEGER(dValue).
END FUNCTION.

FUNCTION SituacaoDescricao RETURNS CHARACTER (piId AS INTEGER):
  DEFINE VARIABLE cDescricao AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lAvailable AS LOGICAL NO-UNDO.
  IF piId = ? THEN RETURN "Não Informado".
  lAvailable = phSituacoes:FIND-FIRST("WHERE " + phSituacoes:NAME + ".situacao_container_id = " + TRIM(STRING(piId)), NO-LOCK) NO-ERROR.
  IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na consulta de situacoes.", 0).
  IF lAvailable THEN cDescricao = phSituacoes:BUFFER-FIELD("descricao"):BUFFER-VALUE.
  IF cDescricao = ? OR TRIM(cDescricao) = "" THEN RETURN "Não Informado".
  RETURN cDescricao.
END FUNCTION.

FUNCTION EmitenteNome RETURNS CHARACTER (piId AS INTEGER, pcFallback AS CHARACTER):
  DEFINE VARIABLE cAbrev AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cNome AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lAvailable AS LOGICAL NO-UNDO.
  IF piId = ? THEN RETURN pcFallback.
  lAvailable = phEmitente:FIND-FIRST("WHERE " + phEmitente:NAME + ".cod-emitente = " + TRIM(STRING(piId)), NO-LOCK) NO-ERROR.
  IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na consulta de emitentes.", 0).
  IF NOT lAvailable THEN RETURN pcFallback.
  ASSIGN cAbrev = phEmitente:BUFFER-FIELD("nome-abrev"):BUFFER-VALUE
         cNome = phEmitente:BUFFER-FIELD("nome-emit"):BUFFER-VALUE.
  IF cAbrev = ? OR cNome = ? THEN RETURN pcFallback.
  RETURN cAbrev + "-" + cNome.
END FUNCTION.

FUNCTION RecordJson RETURNS JsonObject ():
  DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
  DEFINE VARIABLE iField AS INTEGER NO-UNDO.
  DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cPublic AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hField AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dtValue AS DATE NO-UNDO.
  DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.
  joRow = NEW JsonObject().
  DO iField = 1 TO 20:
    cField = ENTRY(iField, "nr-container,cod-estabel,cod-emit-forn,nome-ab-forn,dt-recebimento,dt-prev-chegada,situacao,vl-dolar-compra,vl-dolar-venda,situacao_container_id,dt_prev_embarque,dt_real_embarque,num-pedido,dt-compra,exclusivo,ind_dt_embarque,ind_dt_prev_chegada,log_pagto_final,cod_agente_cargas,cod_armador").
    ASSIGN hField = phContainers:BUFFER-FIELD(cField)
           cPublic = IF cField = "nr-container" THEN "container_id" ELSE REPLACE(cField, "-", "_").
    IF hField:BUFFER-VALUE = ? THEN joRow:AddNull(cPublic).
    ELSE CASE hField:DATA-TYPE:
      WHEN "CHARACTER" THEN DO: cValue = hField:BUFFER-VALUE. joRow:Add(cPublic, cValue). END.
      WHEN "INTEGER" THEN DO: iValue = hField:BUFFER-VALUE. joRow:Add(cPublic, iValue). END.
      WHEN "DECIMAL" THEN DO: dValue = hField:BUFFER-VALUE. joRow:Add(cPublic, dValue). END.
      WHEN "DATE" THEN DO: dtValue = hField:BUFFER-VALUE. joRow:Add(cPublic, dtValue). END.
      WHEN "LOGICAL" THEN DO: lValue = hField:BUFFER-VALUE. joRow:Add(cPublic, lValue). END.
      OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo de campo inesperado.", 0).
    END CASE.
  END.
  joRow:Add("situacao_container_descricao", SituacaoDescricao(phContainers:BUFFER-FIELD("situacao_container_id"):BUFFER-VALUE)).
  joRow:Add("agente_cargas_nome", EmitenteNome(phContainers:BUFFER-FIELD("cod_agente_cargas"):BUFFER-VALUE, "Agente de Cargas Não Encontrado")).
  joRow:Add("armador_nome", EmitenteNome(phContainers:BUFFER-FIELD("cod_armador"):BUFFER-VALUE, "")).
  RETURN joRow.
END FUNCTION.

poResponse = NEW JsonObject().
DO ON ERROR UNDO, THROW:
  IF NOT VALID-HANDLE(phContainers) OR NOT VALID-HANDLE(phSituacoes) OR NOT VALID-HANDLE(phEmitente) OR NOT VALID-OBJECT(poRequest) THEN DO:
    RUN Fail("CONTAINER_CONFIGURATION", "Consulta de containers indisponivel.", 500). RETURN.
  END.
  IF NOT poRequest:Has("operation") THEN DO:
    RUN Fail("CONTAINER_OPERATION_INVALID", "Informe a operacao de consulta.", 422). RETURN.
  END.
  IF poRequest:GetType("operation") <> JsonDataType:STRING THEN DO:
    RUN Fail("CONTAINER_OPERATION_INVALID", "Operacao de consulta invalida.", 422). RETURN.
  END.
  cOperation = poRequest:GetCharacter("operation").
  IF cOperation <> "read" AND cOperation <> "get" THEN DO:
    RUN Fail("CONTAINER_OPERATION_INVALID", "A consulta aceita somente read e get.", 422). RETURN.
  END.
  cNames = poRequest:GetNames().
  DO iName = 1 TO EXTENT(cNames):
    IF LOOKUP(cNames[iName], "operation,id,container_id") = 0 THEN DO:
      RUN Fail("CONTAINER_VALIDATION", "Campo nao permitido na consulta.", 422). RETURN.
    END.
  END.
  IF cOperation = "get" THEN DO:
    iId = IF poRequest:Has("id") THEN ReadId("id") ELSE ReadId("container_id").
    IF iId = ? THEN DO:
      RUN Fail("CONTAINER_VALIDATION", "Informe um ID inteiro positivo valido.", 422). RETURN.
    END.
    IF poRequest:Has("id") AND poRequest:Has("container_id") THEN DO:
      iOtherId = ReadId("container_id").
      IF iOtherId = ? OR iOtherId <> iId THEN DO:
        RUN Fail("CONTAINER_VALIDATION", "Os IDs informados sao invalidos ou conflitantes.", 422). RETURN.
      END.
    END.
    lFound = phContainers:FIND-FIRST("WHERE " + phContainers:NAME + ".nr-container = " + TRIM(STRING(iId)), NO-LOCK) NO-ERROR.
    IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na consulta do container.", 0).
    IF NOT lFound THEN DO:
      RUN Fail("CONTAINER_NOT_FOUND", "Container nao encontrado.", 404). RETURN.
    END.
    poResponse:Add("success", TRUE).
    poResponse:Add("data", RecordJson()).
    RETURN.
  END.
  jaRows = NEW JsonArray().
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(phContainers).
  hQuery:QUERY-PREPARE("FOR EACH " + phContainers:NAME + " NO-LOCK BY " + phContainers:NAME + ".situacao BY " + phContainers:NAME + ".situacao_container_id BY " + phContainers:NAME + ".nr-container").
  hQuery:QUERY-OPEN().
  hQuery:GET-FIRST().
  DO WHILE NOT hQuery:QUERY-OFF-END:
    jaRows:Add(RecordJson()).
    hQuery:GET-NEXT().
  END.
  poResponse:Add("success", TRUE).
  poResponse:Add("data", jaRows).
  CATCH oError AS Progress.Lang.Error:
    RUN Fail("CONTAINER_INTERNAL", "Nao foi possivel consultar os containers.", 500).
  END CATCH.
  FINALLY:
    IF VALID-HANDLE(hQuery) THEN DO:
      hQuery:QUERY-CLOSE() NO-ERROR.
      DELETE OBJECT hQuery NO-ERROR.
    END.
  END FINALLY.
END.

PROCEDURE Fail:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  DEFINE VARIABLE joError AS JsonObject NO-UNDO.
  poResponse = NEW JsonObject().
  joError = NEW JsonObject().
  poResponse:Add("success", FALSE).
  joError:Add("code", pcCode).
  joError:Add("message", pcMessage).
  joError:Add("status", piStatus).
  poResponse:Add("error", joError).
END PROCEDURE.

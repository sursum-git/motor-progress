/* Private read-only collector for cost calculations. No public route/resource.
   It follows linked payment IDs, WITHOUT the payment grid's date/supplier/company/
   reversal filters. Ambiguous legacy FIRST-row selections are rejected explicitly. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPagtos AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTitAp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phValTitAp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER piContainer AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hLinks AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitles AS HANDLE NO-UNDO.
DEFINE VARIABLE cEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSpecies AS CHARACTER NO-UNDO.
DEFINE VARIABLE iTitle AS INTEGER NO-UNDO.
DEFINE VARIABLE nTitles AS INTEGER NO-UNDO.
DEFINE VARIABLE dReal AS DECIMAL NO-UNDO.
DEFINE VARIABLE dDolar AS DECIMAL NO-UNDO.
DEFINE VARIABLE dCurrent AS DECIMAL NO-UNDO.
DEFINE VARIABLE dForeign AS DECIMAL NO-UNDO.
DEFINE VARIABLE cFailure AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
DEFINE VARIABLE iStatus AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE joData AS JsonObject NO-UNDO.
DEFINE VARIABLE joPayments AS JsonObject NO-UNDO.
DEFINE VARIABLE jaPaymentRows AS JsonArray NO-UNDO.
DEFINE VARIABLE joPaymentRow AS JsonObject NO-UNDO.
DEFINE VARIABLE lCaptureRows AS LOGICAL NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
FUNCTION NumText RETURNS CHARACTER (piValue AS INTEGER):
  RETURN TRIM(STRING(piValue,"->>>>>>>>>9")).
END FUNCTION.
FUNCTION AblQuote RETURNS CHARACTER (pcValue AS CHARACTER):
  DEFINE VARIABLE c AS CHARACTER NO-UNDO.
  IF pcValue=? THEN RETURN "?".
  c=REPLACE(pcValue,CHR(126),CHR(126) + CHR(126)).
  c=REPLACE(c,CHR(34),CHR(126) + CHR(34)).
  c=REPLACE(c,CHR(10),CHR(126) + "n"). c=REPLACE(c,CHR(13),CHR(126) + "r").
  c=REPLACE(c,CHR(9),CHR(126) + "t").
  RETURN CHR(34) + c + CHR(34).
END FUNCTION.
FUNCTION InPolicy RETURNS LOGICAL (pcGroup AS CHARACTER,pcSpecies AS CHARACTER):
  DEFINE VARIABLE a AS JsonArray NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE c AS CHARACTER CASE-SENSITIVE NO-UNDO.
  a=poPolicy:GetJsonArray(pcGroup).
  DO k=1 TO a:Length: c=a:GetCharacter(k). IF c=pcSpecies THEN RETURN TRUE. END.
  RETURN FALSE.
END FUNCTION.
PROCEDURE CheckPolicy:
  DEFINE VARIABLE a AS JsonArray NO-UNDO.
  DEFINE VARIABLE cGroup AS CHARACTER NO-UNDO.
  DEFINE VARIABLE c AS CHARACTER NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE m AS INTEGER NO-UNDO.
  DEFINE VARIABLE p AS INTEGER NO-UNDO.
  DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
  IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Missing internal policy.",0).
  names=poPolicy:GetNames().
  IF EXTENT(names)<>(IF poPolicy:Has("capture_rows") THEN 3 ELSE 2) OR NOT poPolicy:Has("adiantamentos") OR NOT poPolicy:Has("titulos") THEN
    UNDO, THROW NEW Progress.Lang.AppError("Invalid internal policy.",0).
  IF poPolicy:Has("capture_rows") THEN DO:
    IF poPolicy:GetType("capture_rows")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid private capture flag.",0).
    lCaptureRows=poPolicy:GetLogical("capture_rows").
  END.
  DO k=1 TO 2:
    cGroup=ENTRY(k,"adiantamentos,titulos").
    IF poPolicy:GetType(cGroup)<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid species type.",0).
    a=poPolicy:GetJsonArray(cGroup).
    IF a:Length<1 OR a:Length>100 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid species count.",0).
    DO m=1 TO a:Length:
      IF a:GetType(m)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid species code type.",0).
      c=a:GetCharacter(m).
      IF LENGTH(c)<1 OR LENGTH(c)>3 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid species code length.",0).
      DO p=1 TO LENGTH(c):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(c,p,1))=0 THEN
          UNDO, THROW NEW Progress.Lang.AppError("Invalid species code.",0).
      END.
    END.
  END.
END PROCEDURE.
PROCEDURE OpenQuery:
  DEFINE INPUT PARAMETER phQuery AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER phBuffer AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER pcWhere AS CHARACTER NO-UNDO.
  phQuery:SET-BUFFERS(phBuffer).
  IF NOT phQuery:QUERY-PREPARE("FOR EACH " + phBuffer:NAME + " NO-LOCK WHERE " + pcWhere) THEN
    UNDO, THROW NEW Progress.Lang.AppError("Private total query failed.",0).
  phQuery:QUERY-OPEN(). phQuery:GET-FIRST().
END PROCEDURE.
PROCEDURE CurrencyValue:
  DEFINE INPUT PARAMETER pcPurpose AS CHARACTER NO-UNDO.
  DEFINE OUTPUT PARAMETER pdValue AS DECIMAL NO-UNDO.
  DEFINE VARIABLE h AS HANDLE NO-UNDO.
  DEFINE VARIABLE dOriginal AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dPaid AS DECIMAL NO-UNDO.
  DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
  pdValue=0.
  DO ON ERROR UNDO, THROW:
    CREATE QUERY h.
    RUN OpenQuery(h,phValTitAp,phValTitAp:NAME + ".num_id_tit_ap = " + NumText(iTitle)
      + " AND " + phValTitAp:NAME + ".cod_estab = " + AblQuote(cEstab)
      + " AND " + phValTitAp:NAME + ".cod_finalid_econ = " + AblQuote(pcPurpose)).
    DO WHILE NOT h:QUERY-OFF-END AND countRows<2:
      countRows=countRows + 1.
      ASSIGN dOriginal=phValTitAp:BUFFER-FIELD("val_origin_tit_ap"):BUFFER-VALUE
             dPaid=phValTitAp:BUFFER-FIELD("val_pagto_tit_ap"):BUFFER-VALUE.
      h:GET-NEXT().
    END.
    IF countRows>1 THEN DO:
      ASSIGN cFailure="CONTAINER_PAYMENT_AMBIGUOUS" cMessage="Mais de um valor por finalidade no titulo associado.".
      RETURN.
    END.
    IF countRows=1 THEN DO:
      IF InPolicy("adiantamentos",cSpecies) THEN pdValue=dOriginal.
      IF InPolicy("titulos",cSpecies) THEN pdValue=dPaid.
      IF pdValue=0 THEN DO: pdValue=dPaid. IF pdValue=0 THEN pdValue=dOriginal. END.
      IF pdValue=? THEN ASSIGN cFailure="CONTAINER_PAYMENT_VALUE_UNKNOWN" cMessage="Valor desconhecido em titulo associado ao container.".
    END.
    /* countRows=0 preserves the legacy numeric zero for an absent currency. */
    FINALLY:
      IF VALID-HANDLE(h) THEN DO: h:QUERY-CLOSE() NO-ERROR. DELETE OBJECT h NO-ERROR. END.
    END FINALLY.
  END.
END PROCEDURE.
poResponse=NEW JsonObject().
DO ON ERROR UNDO, THROW:
  IF piContainer=? OR piContainer<1 THEN DO:
    RUN Fail("CONTAINER_VALIDATION","Informe container_id inteiro positivo valido.",422). RETURN.
  END.
  IF NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phPagtos) OR NOT VALID-HANDLE(phTitAp) OR NOT VALID-HANDLE(phValTitAp) THEN
    UNDO, THROW NEW Progress.Lang.AppError("Missing fixed collector buffers.",0).
  lFound=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container = " + NumText(piContainer),NO-LOCK) NO-ERROR.
  DO j=1 TO ERROR-STATUS:NUM-MESSAGES:
    IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Parent lookup failed.",0).
  END.
  IF NOT lFound THEN DO: RUN Fail("CONTAINER_NOT_FOUND","Container nao encontrado.",404). RETURN. END.
  RUN CheckPolicy.
  IF lCaptureRows THEN jaPaymentRows=NEW JsonArray().
  CREATE QUERY hLinks. CREATE QUERY hTitles.
  RUN OpenQuery(hLinks,phPagtos,phPagtos:NAME + ".container_id = " + NumText(piContainer)).
  DO WHILE NOT hLinks:QUERY-OFF-END:
    iTitle=phPagtos:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
    IF iTitle=? OR iTitle<1 THEN DO:
      RUN Fail("CONTAINER_PAYMENT_NOT_FOUND","Vinculo de titulo invalido no container.",422). RETURN.
    END.
    nTitles=0.
    RUN OpenQuery(hTitles,phTitAp,phTitAp:NAME + ".num_id_tit_ap = " + NumText(iTitle)).
    DO WHILE NOT hTitles:QUERY-OFF-END AND nTitles<2:
      nTitles=nTitles + 1.
      ASSIGN cEstab=phTitAp:BUFFER-FIELD("cod_estab"):BUFFER-VALUE cSpecies=phTitAp:BUFFER-FIELD("cod_espec_docto"):BUFFER-VALUE.
      hTitles:GET-NEXT().
    END.
    hTitles:QUERY-CLOSE().
    IF nTitles=0 THEN DO: RUN Fail("CONTAINER_PAYMENT_NOT_FOUND","Titulo associado ao container nao encontrado.",422). RETURN. END.
    IF nTitles>1 THEN DO: RUN Fail("CONTAINER_PAYMENT_AMBIGUOUS","ID do titulo associado ocorre em mais de um estabelecimento.",422). RETURN. END.
    RUN CurrencyValue("corrente",OUTPUT dCurrent).
    IF cFailure<>"" THEN DO: RUN Fail(cFailure,cMessage,iStatus). RETURN. END.
    RUN CurrencyValue("dolar",OUTPUT dForeign).
    IF cFailure<>"" THEN DO: RUN Fail(cFailure,cMessage,iStatus). RETURN. END.
    ASSIGN dReal=dReal + dCurrent dDolar=dDolar + dForeign.
    IF lCaptureRows THEN DO:
      joPaymentRow=NEW JsonObject(). joPaymentRow:Add("num_id_tit_ap",iTitle).
      joPaymentRow:Add("vl_real",dCurrent). joPaymentRow:Add("vl_dolar",dForeign). jaPaymentRows:Add(joPaymentRow).
    END.
    hLinks:GET-NEXT().
  END.
  joData=NEW JsonObject(). joPayments=NEW JsonObject().
  joPayments:Add("real",dReal). joPayments:Add("dolar",dDolar).
  joData:Add("container_id",piContainer). joData:Add("payments",joPayments).
  joData:Add("confirmed",TRUE). joData:Add("source","linked-payment-totals").
  IF lCaptureRows THEN joData:Add("payment_rows",jaPaymentRows).
  poResponse:Add("success",TRUE). poResponse:Add("data",joData).
  CATCH e AS Progress.Lang.Error:
    RUN Fail("CONTAINER_CONFIGURATION","Nao foi possivel confirmar os pagamentos associados ao container.",500).
  END CATCH.
  FINALLY:
    IF VALID-HANDLE(hLinks) THEN DO: hLinks:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hLinks NO-ERROR. END.
    IF VALID-HANDLE(hTitles) THEN DO: hTitles:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hTitles NO-ERROR. END.
  END FINALLY.
END.
PROCEDURE Fail:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  DEFINE VARIABLE joError AS JsonObject NO-UNDO.
  IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
  poResponse=NEW JsonObject(). joError=NEW JsonObject(). poResponse:Add("success",FALSE).
  joError:Add("code",pcCode). joError:Add("message",pcMessage). joError:Add("status",piStatus). poResponse:Add("error",joError).
END PROCEDURE.

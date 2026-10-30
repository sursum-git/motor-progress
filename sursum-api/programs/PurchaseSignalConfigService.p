/* Fixed rule configuration. Persistence, concurrency and snapshots belong to the
   existing cadastro core; creating/removing executable rules is not a CRUD action. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phSignals AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE policyText AS LONGCHAR NO-UNDO.
DEFINE VARIABLE corePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE allowed AS CHARACTER NO-UNDO.
DEFINE VARIABLE rawId AS CHARACTER NO-UNDO.
DEFINE VARIABLE idValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
DEFINE VARIABLE daysValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE errorCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SIGNAL_CONFIG_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 ASSIGN errorCode=c statusCode=s.
 UNDO, THROW NEW Progress.Lang.AppError('Solicitacao recusada.',1).
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phSignals) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_CONFIGURATION',503).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(errorCode,422).
 op=poRequest:GetCharacter('operation').
 IF LOOKUP(op,'read,get,update')=0 THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_OPERATION',405).
 IF op='update' AND TRANSACTION THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_TRANSACTION',409).
 allowed='operation'.
 IF op='get' THEN allowed=allowed + ',id,sinaliz_imp_id'.
 IF op='update' THEN allowed=allowed + ',id,sinaliz_imp_id,original,nome,titulo,descricao,qt_dias_alerta'.
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  matched=FALSE.
  DO j=1 TO NUM-ENTRIES(allowed): IF COMPARE(names[n],'=',ENTRY(j,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_FIELD',422).
 END.
 IF op<>'read' THEN DO:
  IF NOT poRequest:Has('id') OR poRequest:IsNull('id') THEN RUN Fail(errorCode,422).
  IF poRequest:GetType('id')=JsonDataType:STRING THEN rawId=poRequest:GetCharacter('id').
  ELSE IF poRequest:GetType('id')=JsonDataType:NUMBER THEN rawId=poRequest:GetJsonText('id').
  ELSE RUN Fail(errorCode,422).
  IF rawId=? OR LENGTH(rawId)<1 OR LENGTH(rawId)>10 THEN RUN Fail(errorCode,422).
  DO n=1 TO LENGTH(rawId): IF INDEX('0123456789',SUBSTRING(rawId,n,1))=0 THEN RUN Fail(errorCode,422). END.
  idValue=DECIMAL(rawId).
  IF idValue<1 OR idValue>5 THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_RULE',422).
 END.
 /* Do not introduce unknown days, which would make the read evaluator fail closed.
    Historical nulls remain valid in original snapshots and unrelated fields. */
 IF op='update' AND poRequest:Has('qt_dias_alerta') THEN DO:
  IF poRequest:IsNull('qt_dias_alerta') THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_DAYS',422).
  IF poRequest:GetType('qt_dias_alerta')=JsonDataType:NUMBER THEN DO:
   daysValue=poRequest:GetDecimal('qt_dias_alerta').
   IF daysValue<0 OR daysValue>9999 THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_DAYS',422).
  END.
 END.
 DO n=1 TO 2:
  rawId=ENTRY(n,'nome,titulo').
  IF op='update' AND poRequest:Has(rawId) THEN DO:
   IF poRequest:IsNull(rawId) THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_REQUIRED',422).
   IF poRequest:GetType(rawId)=JsonDataType:STRING THEN
    IF poRequest:GetCharacter(rawId)='' THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_REQUIRED',422).
  END.
 END.
 FIX-CODEPAGE(policyText)='UTF-8'.
 policyText='~{"resource":"sinalizadores_importacao","primaryKey":"sinaliz_imp_id","fields":[~{"name":"nome","type":"character","maxLength":100~},~{"name":"titulo","type":"character","maxLength":300~},~{"name":"descricao","type":"character","maxLength":600~},~{"name":"qt_dias_alerta","type":"integer"~}]~}'.
 parser=NEW ObjectModelParser(). policy=CAST(parser:Parse(policyText),JsonObject).
 corePath=SEARCH('sursum-api/programs/CiwCadastroCoreService.r').
 IF corePath=? THEN RUN Fail('PURCHASE_SIGNAL_CONFIG_CONFIGURATION',503).
 RUN VALUE(corePath)(phSignals,?,?,?,policy,poRequest,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). err=NEW JsonObject().
  poResponse:Add('success',FALSE). err:Add('code',errorCode). err:Add('status',statusCode).
  err:Add('message','Configuracao de sinalizadores recusada ou indisponivel.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
  IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
 END FINALLY.
END.

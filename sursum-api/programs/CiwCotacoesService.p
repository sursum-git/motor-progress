/* Historico BC manual e importacao automatica: buffers e gerador de ID pertencem ao wrapper fechado. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIds AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE scan AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE id AS INTEGER NO-UNDO.
DEFINE VARIABLE priorId AS INTEGER NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE numberValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE found AS LOGICAL NO-UNDO.
DEFINE VARIABLE beforeRow AS JsonObject NO-UNDO.
DEFINE VARIABLE afterRow AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE chosenRow AS ROWID NO-UNDO.
DEFINE VARIABLE rootWasActive AS LOGICAL NO-UNDO.
DEFINE VARIABLE invalidatorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE isCreate AS LOGICAL NO-UNDO.
DEFINE VARIABLE isImport AS LOGICAL NO-UNDO.
FUNCTION Failed RETURNS LOGICAL ():
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DO k=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(k)<>565 THEN RETURN TRUE.
 END.
 RETURN FALSE.
END FUNCTION.
FUNCTION IntegerId RETURNS INTEGER (keyName AS CHARACTER):
 DEFINE VARIABLE v AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF NOT poRequest:Has(keyName) OR poRequest:IsNull(keyName) THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 IF poRequest:GetType(keyName)=JsonDataType:NUMBER THEN v=poRequest:GetJsonText(keyName).
 ELSE IF poRequest:GetType(keyName)=JsonDataType:STRING THEN v=poRequest:GetCharacter(keyName).
 ELSE RUN Fail('CIW_COTACAO_VALIDATION',422).
 IF LENGTH(v)<1 OR LENGTH(v)>10 THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 DO k=1 TO LENGTH(v): IF INDEX('0123456789',SUBSTRING(v,k,1))=0 THEN RUN Fail('CIW_COTACAO_VALIDATION',422). END.
 IF DECIMAL(v)<1 OR DECIMAL(v)>2147483647 THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 RETURN INTEGER(v).
END FUNCTION.
FUNCTION ParseDate RETURNS DATE (v AS CHARACTER):
 DEFINE VARIABLE d AS DATE NO-UNDO.
 IF LENGTH(v)<>10 OR SUBSTRING(v,5,1)<>'-' OR SUBSTRING(v,8,1)<>'-' THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 d=DATE(INTEGER(SUBSTRING(v,6,2)),INTEGER(SUBSTRING(v,9,2)),INTEGER(SUBSTRING(v,1,4))) NO-ERROR.
 IF ERROR-STATUS:ERROR OR d=? THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 IF ISO-DATE(d)<>v THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 RETURN d.
END FUNCTION.
FUNCTION ParseTime RETURNS DATETIME (v AS CHARACTER):
 DEFINE VARIABLE d AS DATE NO-UNDO.
 DEFINE VARIABLE h AS INTEGER NO-UNDO.
 DEFINE VARIABLE m AS INTEGER NO-UNDO.
 DEFINE VARIABLE s AS INTEGER NO-UNDO.
 DEFINE VARIABLE ms AS INTEGER NO-UNDO.
 DEFINE VARIABLE dt AS DATETIME NO-UNDO.
 DEFINE VARIABLE utcValue AS LOGICAL NO-UNDO.
 IF LENGTH(v)=24 AND SUBSTRING(v,24,1)='Z' THEN ASSIGN utcValue=TRUE v=SUBSTRING(v,1,23).
 IF LOOKUP(STRING(LENGTH(v)),'19,23')=0 OR SUBSTRING(v,11,1)<>'T' OR SUBSTRING(v,14,1)<>':' OR SUBSTRING(v,17,1)<>':' THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 d=ParseDate(SUBSTRING(v,1,10)).
 ASSIGN h=INTEGER(SUBSTRING(v,12,2)) m=INTEGER(SUBSTRING(v,15,2)) s=INTEGER(SUBSTRING(v,18,2)) NO-ERROR.
 IF ERROR-STATUS:ERROR OR h<0 OR h>23 OR m<0 OR m>59 OR s<0 OR s>59 THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 IF LENGTH(v)=23 THEN DO:
  IF SUBSTRING(v,20,1)<>'.' THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  ms=INTEGER(SUBSTRING(v,21,3)) NO-ERROR.
  IF ERROR-STATUS:ERROR OR ms<0 OR ms>999 THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 END.
 dt=DATETIME(d,h * 3600000 + m * 60000 + s * 1000 + ms).
 IF SUBSTRING(ISO-DATE(dt),1,LENGTH(v))<>v THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 /* SESSION:TIMEZONE=? usa o fuso do SO; nao significa deslocamento desconhecido. */
 IF utcValue THEN dt=ADD-INTERVAL(dt,IF SESSION:TIMEZONE=? THEN TIMEZONE(NOW) ELSE SESSION:TIMEZONE,'minutes').
 RETURN dt.
END FUNCTION.
FUNCTION Snapshot RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
 o=NEW JsonObject().
 DO k=1 TO 8:
  nameValue=ENTRY(k,'hist_cotacao_bc_id,data,serie,valor,dt_hr_busca,nome_serie,log_ok,log_manual'). f=b:BUFFER-FIELD(nameValue).
  IF f:BUFFER-VALUE=? THEN o:AddNull(nameValue).
  ELSE CASE f:DATA-TYPE:
   WHEN 'INTEGER' THEN o:Add(nameValue,INTEGER(f:BUFFER-VALUE)).
   WHEN 'DECIMAL' THEN o:Add(nameValue,DECIMAL(f:BUFFER-VALUE)).
   WHEN 'LOGICAL' THEN o:Add(nameValue,LOGICAL(f:BUFFER-VALUE)).
   WHEN 'DATE' THEN o:Add(nameValue,ISO-DATE(DATE(f:BUFFER-VALUE))).
   WHEN 'DATETIME' THEN o:Add(nameValue,ISO-DATE(DATETIME(f:BUFFER-VALUE))).
   WHEN 'CHARACTER' THEN o:Add(nameValue,STRING(f:BUFFER-VALUE)).
  END CASE.
 END.
 FIX-CODEPAGE(textValue)='UTF-8'. o:Write(textValue,FALSE).
 o:Add('row_stamp',CAPS(HEX-ENCODE(MESSAGE-DIGEST('SHA-256',textValue)))).
 RETURN o.
END FUNCTION.
PROCEDURE LocateUnique:
 DEFINE INPUT PARAMETER locking AS LOGICAL NO-UNDO.
 DEFINE VARIABLE countValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE whereClause AS CHARACTER NO-UNDO.
 whereClause='WHERE ' + scan:NAME + '.hist_cotacao_bc_id = ' + TRIM(STRING(id)).
 CREATE QUERY q. q:SET-BUFFERS(scan).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + scan:NAME + ' ' + whereClause + ' NO-LOCK') THEN RUN Fail('CIW_COTACAO_CONFIGURATION',503).
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  ASSIGN countValue=countValue + 1 chosenRow=scan:ROWID.
  IF countValue>1 THEN RUN Fail('CIW_COTACAO_AMBIGUOUS',409).
  q:GET-NEXT(NO-LOCK).
 END.
 DELETE OBJECT q. found=countValue=1.
 IF found THEN DO:
  found=b:FIND-BY-ROWID(chosenRow,IF locking THEN EXCLUSIVE-LOCK ELSE NO-LOCK,NO-WAIT) NO-ERROR.
  IF b:LOCKED THEN RUN Fail('CIW_COTACAO_BUSY',409).
  IF Failed() OR NOT found THEN RUN Fail('CIW_COTACAO_CHANGED',409).
 END.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 rootWasActive=TRANSACTION.
 IF NOT VALID-HANDLE(phData) OR NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phIds) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail('CIW_COTACAO_CONFIGURATION',503).
 CREATE BUFFER b FOR TABLE phData. CREATE BUFFER scan FOR TABLE phData.
 invalidatorPath=SEARCH('sursum-api/programs/ContainerCostInvalidation.r').
 IF invalidatorPath=? THEN invalidatorPath=SEARCH('ContainerCostInvalidation.r').
 IF invalidatorPath=? THEN invalidatorPath=SEARCH('ContainerCostInvalidation.p').
 IF invalidatorPath=? THEN RUN Fail('CIW_COTACAO_CONFIGURATION',503).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 op=poRequest:GetCharacter('operation').
 IF LOOKUP(op,'read,get,create,update,delete,import-bc')=0 THEN RUN Fail('CIW_COTACAO_OPERATION_INVALID',422).
 ASSIGN isImport=op='import-bc' isCreate=op='create' OR isImport.
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  IF (isImport AND LOOKUP(names[n],'operation,data,serie,valor,nome_serie')=0) OR (NOT isImport AND LOOKUP(names[n],'operation,id,hist_cotacao_bc_id,data,serie,valor,dt_hr_busca,row_stamp')=0) THEN RUN Fail('CIW_COTACAO_FIELD_INVALID',422).
  IF op='read' AND names[n]<>'operation' THEN RUN Fail('CIW_COTACAO_FIELD_INVALID',422).
  IF op='get' AND LOOKUP(names[n],'operation,id,hist_cotacao_bc_id')=0 THEN RUN Fail('CIW_COTACAO_FIELD_INVALID',422).
 END.
 IF op='read' THEN DO:
  CREATE QUERY q. q:SET-BUFFERS(b).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + b:NAME + ' NO-LOCK BY ' + b:NAME + '.hist_cotacao_bc_id') THEN RUN Fail('CIW_COTACAO_CONFIGURATION',503).
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK). rows=NEW JsonArray().
  DO WHILE NOT q:QUERY-OFF-END:
   id=INTEGER(b:BUFFER-FIELD('hist_cotacao_bc_id'):BUFFER-VALUE).
   IF id=? OR id<=0 OR id=priorId THEN RUN Fail('CIW_COTACAO_AMBIGUOUS',409).
   priorId=id. rows:Add(Snapshot()). q:GET-NEXT(NO-LOCK).
  END.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',rows). RETURN.
 END.
 IF NOT isCreate THEN DO:
  id=IntegerId('id').
  IF poRequest:Has('hist_cotacao_bc_id') THEN IF IntegerId('hist_cotacao_bc_id')<>id THEN RUN Fail('CIW_COTACAO_KEY_IMMUTABLE',422).
 END.
 ELSE IF poRequest:Has('id') OR poRequest:Has('hist_cotacao_bc_id') THEN RUN Fail('CIW_COTACAO_KEY_IMMUTABLE',422).
 IF op='get' THEN DO:
  RUN LocateUnique(FALSE). IF NOT found THEN RUN Fail('CIW_COTACAO_NOT_FOUND',404).
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',Snapshot()). RETURN.
 END.
 IF rootWasActive THEN RUN Fail('CIW_COTACAO_ROOT_TRANSACTION_REQUIRED',409).
 IF NOT isCreate THEN DO:
  IF NOT poRequest:Has('row_stamp') OR poRequest:GetType('row_stamp')<>JsonDataType:STRING THEN RUN Fail('CIW_COTACAO_ORIGINAL_REQUIRED',422).
  stamp=poRequest:GetCharacter('row_stamp').
  IF LENGTH(stamp)<>64 THEN RUN Fail('CIW_COTACAO_ORIGINAL_REQUIRED',422).
  DO n=1 TO 64: IF INDEX('0123456789ABCDEF',SUBSTRING(stamp,n,1))=0 THEN RUN Fail('CIW_COTACAO_ORIGINAL_REQUIRED',422). END.
 END.
 IF isCreate OR op='update' THEN DO:
  IF isCreate AND (NOT poRequest:Has('data') OR NOT poRequest:Has('serie') OR NOT poRequest:Has('valor')) THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  IF poRequest:Has('data') THEN DO:
   IF poRequest:GetType('data')<>JsonDataType:STRING THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
   IF ParseDate(poRequest:GetCharacter('data'))=? THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  END.
  IF poRequest:Has('dt_hr_busca') AND NOT poRequest:IsNull('dt_hr_busca') THEN DO:
   IF poRequest:GetType('dt_hr_busca')<>JsonDataType:STRING THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
   IF ParseTime(poRequest:GetCharacter('dt_hr_busca'))=? THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  END.
  IF poRequest:Has('serie') THEN DO:
   IF poRequest:GetType('serie')<>JsonDataType:NUMBER THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
   numberValue=poRequest:GetDecimal('serie').
   IF numberValue<1 OR numberValue>2147483647 OR TRUNCATE(numberValue,0)<>numberValue THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  END.
  IF poRequest:Has('valor') THEN DO:
   IF poRequest:GetType('valor')<>JsonDataType:NUMBER THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
   numberValue=poRequest:GetDecimal('valor').
   IF numberValue<>ROUND(numberValue,5) THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  END.
 END.
 IF isImport THEN DO:
  IF poRequest:GetInteger('serie')<>1 OR poRequest:GetDecimal('valor')<=0 OR ParseDate(poRequest:GetCharacter('data'))>TODAY THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  IF NOT poRequest:Has('nome_serie') OR poRequest:GetType('nome_serie')<>JsonDataType:STRING THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
  IF LENGTH(TRIM(poRequest:GetCharacter('nome_serie')))=0 OR LENGTH(poRequest:GetCharacter('nome_serie'))>200 THEN RUN Fail('CIW_COTACAO_VALIDATION',422).
 END.
 changes=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  IF isCreate THEN DO:
   RUN NextCotacaoId IN phIds(OUTPUT id).
   IF id=? OR id<=0 THEN RUN Fail('CIW_COTACAO_CONFIGURATION',503).
   RUN LocateUnique(TRUE). IF found THEN RUN Fail('CIW_COTACAO_DUPLICATE',409).
   IF NOT b:BUFFER-CREATE() THEN RUN Fail('CIW_COTACAO_PERSISTENCE_REJECTED',409).
   ASSIGN b:BUFFER-FIELD('hist_cotacao_bc_id'):BUFFER-VALUE=id
          b:BUFFER-FIELD('log_manual'):BUFFER-VALUE=NOT isImport b:BUFFER-FIELD('dt_hr_busca'):BUFFER-VALUE=NOW.
   IF isImport THEN ASSIGN b:BUFFER-FIELD('log_ok'):BUFFER-VALUE=TRUE b:BUFFER-FIELD('nome_serie'):BUFFER-VALUE=poRequest:GetCharacter('nome_serie').
   beforeRow=NEW JsonObject().
  END.
  ELSE DO:
   RUN LocateUnique(TRUE). IF NOT found THEN RUN Fail('CIW_COTACAO_NOT_FOUND',404).
   IF b:BUFFER-FIELD('log_manual'):BUFFER-VALUE<>TRUE OR b:BUFFER-FIELD('log_manual'):BUFFER-VALUE=? THEN RUN Fail('CIW_COTACAO_NOT_MANUAL',409).
   beforeRow=Snapshot(). IF beforeRow:GetCharacter('row_stamp')<>stamp THEN RUN Fail('CIW_COTACAO_CHANGED',409).
  END.
  IF op='delete' THEN DO:
   IF NOT b:BUFFER-DELETE() THEN RUN Fail('CIW_COTACAO_PERSISTENCE_REJECTED',409).
   afterRow=NEW JsonObject().
  END.
  ELSE DO:
   IF poRequest:Has('data') THEN b:BUFFER-FIELD('data'):BUFFER-VALUE=ParseDate(poRequest:GetCharacter('data')).
   IF poRequest:Has('serie') THEN b:BUFFER-FIELD('serie'):BUFFER-VALUE=poRequest:GetInteger('serie').
   IF poRequest:Has('valor') THEN b:BUFFER-FIELD('valor'):BUFFER-VALUE=poRequest:GetDecimal('valor').
   IF poRequest:Has('dt_hr_busca') THEN b:BUFFER-FIELD('dt_hr_busca'):BUFFER-VALUE=IF poRequest:IsNull('dt_hr_busca') THEN ? ELSE ParseTime(poRequest:GetCharacter('dt_hr_busca')).
   IF NOT b:BUFFER-VALIDATE() THEN RUN Fail('CIW_COTACAO_PERSISTENCE_REJECTED',409).
   IF INTEGER(b:BUFFER-FIELD('serie'):BUFFER-VALUE)=9999 THEN RUN VALUE(invalidatorPath)(INPUT phContainer,OUTPUT changes).
   afterRow=Snapshot().
  END.
 END.
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE).
 IF isImport THEN DO:
  audit=NEW JsonObject(). audit:Add('type','message'). audit:Add('message','Cotacao do Banco Central gravada no historico. Consulte o cadastro e os logs do registro.'). poResponse:Add('data',audit).
 END.
 ELSE IF op<>'delete' THEN poResponse:Add('data',afterRow).
 audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction').
 audit:Add('resource','hist_cotacoes_bc'). audit:Add('operation',op). audit:Add('recordId',id).
 audit:Add('before',beforeRow). audit:Add('after',afterRow). audit:Add('changes',changes). poResponse:Add('audit',audit).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('CIW_COTACAO_PERSISTENCE_REJECTED',409).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(b) THEN DO: b:BUFFER-RELEASE() NO-ERROR. DELETE OBJECT b NO-ERROR. END.
  IF VALID-HANDLE(scan) THEN DELETE OBJECT scan NO-ERROR.
 END FINALLY.
END.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code',code). err:Add('status',statusCode).
 err:Add('message','Cotacao invalida, automatica, alterada ou indisponivel. Recarregue o registro.').
 poResponse:Add('success',FALSE). poResponse:Add('error',err).
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN ErrorResponse(code,statusCode). UNDO,THROW NEW Progress.Lang.AppError(code,0).
END PROCEDURE.

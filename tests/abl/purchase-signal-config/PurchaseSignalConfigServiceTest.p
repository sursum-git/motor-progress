BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE signals FIELD sinaliz_imp_id AS INTEGER FIELD nome AS CHARACTER
 FIELD titulo AS CHARACTER FIELD descricao AS CHARACTER FIELD qt_dias_alerta AS INTEGER
 INDEX pk IS PRIMARY UNIQUE sinaliz_imp_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE original AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
DEFINE VARIABLE snapshotNames AS CHARACTER EXTENT NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
OUTPUT TO VALUE('signal-config-tests-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 DO k=1 TO 5:
  CREATE signals. ASSIGN signals.sinaliz_imp_id=k signals.nome='Rule' + STRING(k)
   signals.titulo='Title' signals.descricao='Historical' signals.qt_dias_alerta=7.
 END.
 RUN Request('read'). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonArray('data'):Length=5,'five records read').
 RUN Request('get'). req:Add('id',1). RUN Invoke. RUN Success.
 original=CAST(res:GetJsonObject('data'):Clone(),JsonObject). original:Remove('sinaliz_imp_id').
 RUN Request('update'). req:Add('id',1). req:Add('nome',''). req:Add('original',original). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_REQUIRED',422).
 RUN Request('update'). req:Add('id',1). req:AddNull('titulo'). req:Add('original',original). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_REQUIRED',422).
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',9). req:Add('original',original). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_TRANSACTION',409).
  UNDO, LEAVE.
 END.
 RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',-1). req:Add('original',original). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_DAYS',422).
 RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',10000). req:Add('original',original). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_DAYS',422).
 RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',12). req:Add('original',original). RUN Invoke. RUN Success.
 beforeValue=res:GetJsonObject('audit'):GetJsonObject('before'). afterValue=res:GetJsonObject('audit'):GetJsonObject('after').
 RUN Check(beforeValue:GetInteger('qt_dias_alerta')=7 AND afterValue:GetInteger('qt_dias_alerta')=12,'native before and after').
 snapshotNames=beforeValue:GetNames(). RUN Check(EXTENT(snapshotNames)=5,'five before fields audited').
 EXTENT(snapshotNames)=?. snapshotNames=afterValue:GetNames(). RUN Check(EXTENT(snapshotNames)=5,'five after fields audited').
 RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',13). req:Add('original',original). RUN Invoke. RUN Error('CIW_CADASTRO_CHANGED',409).
 RUN Check(CAN-FIND(FIRST signals WHERE signals.sinaliz_imp_id=1 AND signals.qt_dias_alerta=12),'stale unchanged').
 DO k=1 TO 3:
  RUN Request(ENTRY(k,'create,delete,batch')). req:Add('id',1). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_OPERATION',405).
 END.
 RUN Request('UPDATE'). req:Add('id',1). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_OPERATION',405).
 DO k=1 TO 3:
  RUN Request('get'). req:Add('id',ENTRY(k,'0,6,1e0')). RUN Invoke. RUN Error(IF k<3 THEN 'PURCHASE_SIGNAL_CONFIG_RULE' ELSE 'PURCHASE_SIGNAL_CONFIG_VALIDATION',422).
 END.
 RUN Request('get'). req:Add('id',1.5). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_VALIDATION',422).
 RUN Request('get'). req:Add('id',1). req:Add('sinaliz_imp_id',2). RUN Invoke. RUN Error('CIW_CADASTRO_ID_IMMUTABLE',422).
 RUN Request('read'). req:Add('TODAY','2026-10-28'). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_FIELD',422).
 RUN Request('read'). req:Add('sql','FOR EACH signals'). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_FIELD',422).
 RUN Request('read'). req:Add('ID',1). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_FIELD',422).
 RUN Request('get'). req:Add('id',1). RUN Invoke. RUN Success.
 original=CAST(res:GetJsonObject('data'):Clone(),JsonObject). original:Remove('sinaliz_imp_id').
 RUN Request('update'). req:Add('id',1). req:AddNull('qt_dias_alerta'). req:Add('original',original). RUN Invoke. RUN Error('PURCHASE_SIGNAL_CONFIG_DAYS',422).
 DO k=1 TO 3:
  fieldName=ENTRY(k,'nome,titulo,descricao').
  RUN Request('update'). req:Add('id',1). req:Add(fieldName,FILL('A',IF k=1 THEN 101 ELSE IF k=2 THEN 301 ELSE 601)). req:Add('original',original). RUN Invoke. RUN Error('CIW_CADASTRO_VALIDATION',422).
 END.
 RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',1.5). req:Add('original',original). RUN Invoke. RUN Error('CIW_CADASTRO_VALIDATION',422).
 /* Unedited historical null remains an exact concurrency image, never coerced. */
 FIND signals WHERE signals.sinaliz_imp_id=2. signals.descricao=?.
 RUN Request('get'). req:Add('id',2). RUN Invoke. RUN Success.
 original=CAST(res:GetJsonObject('data'):Clone(),JsonObject). original:Remove('sinaliz_imp_id').
 RUN Request('update'). req:Add('id',2). req:Add('titulo','Revised'). req:Add('original',original). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):IsNull('descricao') AND res:GetJsonObject('audit'):GetJsonObject('after'):IsNull('descricao'),'historical null preserved').
 DO k=1 TO 2:
  RUN Request('get'). req:Add('id',1). RUN Invoke. RUN Success.
  original=CAST(res:GetJsonObject('data'):Clone(),JsonObject). original:Remove('sinaliz_imp_id').
  RUN Request('update'). req:Add('id',1). req:Add('qt_dias_alerta',IF k=1 THEN 0 ELSE 9999). req:Add('original',original). RUN Invoke. RUN Success.
 END.
 RUN Check(NUM-DBS=0,'isolated fixture').
 PUT UNFORMATTED 'PASS signal-config checks=' checks ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE Request:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',op).
END PROCEDURE.
PROCEDURE Invoke:
 RUN sursum-api/programs/PurchaseSignalConfigService.p(INPUT BUFFER signals:HANDLE,INPUT req,OUTPUT res).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Success:
 RUN Check(res:GetLogical('success'),'success required').
END PROCEDURE.
PROCEDURE Error:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetCharacter('code')=c AND res:GetJsonObject('error'):GetInteger('status')=s,c).
END PROCEDURE.

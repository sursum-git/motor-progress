BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE formats FIELD formato_amostra_id AS INTEGER FIELD descricao AS CHARACTER FIELD log_inativo AS LOGICAL INITIAL TRUE INDEX pk IS UNIQUE PRIMARY formato_amostra_id.
DEFINE TEMP-TABLE items FIELD item_proc_compra_id AS INTEGER FIELD formato_amostra_id AS INTEGER.
DEFINE VARIABLE policy AS JsonObject NO-UNDO. DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO. DEFINE VARIABLE originalValue AS JsonObject NO-UNDO.
DEFINE VARIABLE dataValue AS JsonObject NO-UNDO. DEFINE VARIABLE changeValue AS JsonObject NO-UNDO. DEFINE VARIABLE changesValue AS JsonArray NO-UNDO.
DEFINE VARIABLE identityHandle AS HANDLE NO-UNDO. DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO. DEFINE VARIABLE priorRows AS INTEGER NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('formats-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 RUN sursum-api/programs/CiwCadastroDefinition.p('formatos_amostra',OUTPUT policy).
 RUN Check(policy:GetCharacter('primaryKey')='formato_amostra_id' AND policy:GetJsonArray('fields'):Length=2,'fixed three-field contract').
 RUN SampleFormatsTestIdentity.p PERSISTENT SET identityHandle.
 CREATE formats. ASSIGN formats.formato_amostra_id=13 formats.descricao='Historico' formats.log_inativo=FALSE.
 RUN Request('read'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=1,'existing records read unchanged').
 RUN Request('create'). req:Add('descricao','Amostra 01, pacote.'). RUN Invoke. RUN Success.
 rowValue=res:GetJsonObject('data'). idValue=rowValue:GetInteger('formato_amostra_id'). RUN Check(idValue=14,'fixed provider id').
 RUN Check(NOT rowValue:GetLogical('log_inativo'),'legacy create default active overrides physical inactive default').
 RUN Check(NOT res:GetJsonObject('audit'):GetJsonObject('before'):Has('formato_amostra_id'),'create has empty before').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('formato_amostra_id')=14,'full create after snapshot').
 RUN Request('get'). req:Add('id','14'). req:Add('formato_amostra_id','14'). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('data'):GetCharacter('descricao')='Amostra 01, pacote.','native matching alias get').
 RUN Request('get'). req:Add('id','14'). req:Add('formato_amostra_id','13'). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_ID_IMMUTABLE',422).
 RUN Request('create'). req:Add('formato_amostra_id',99). req:Add('descricao','Explicit identity'). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_ID_IMMUTABLE',422).
 RUN Request('read'). req:Add('formato_amostra_id',14). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_FIELD_INVALID',422).
 RUN Request('create'). req:Add('descricao',FILL('A',41)). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_VALIDATION',422).
 RUN Request('create'). req:Add('descricao','Ação'). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_VALIDATION',422).
 RUN Request('create'). req:Add('descricao','A' + CHR(9) + 'B'). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_VALIDATION',422).
 RUN Request('create'). req:Add('descricao',FILL('A',40)). req:Add('log_inativo',FALSE). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('data'):GetInteger('formato_amostra_id')=15,'invalid submissions do not consume identity').
 RUN Request('get'). req:Add('id',14). RUN Invoke. RUN Success.
 originalValue=CAST(res:GetJsonObject('data'):Clone(),JsonObject). originalValue:Remove('formato_amostra_id').
 RUN Request('update'). req:Add('id',14). req:Add('descricao','Amostra revisada'). req:Add('log_inativo',TRUE). req:Add('original',originalValue). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('descricao')='Amostra 01, pacote.' AND res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('descricao')='Amostra revisada','update before and after complete').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetLogical('log_inativo'),'inactive flag is boolean').
 RUN Request('update'). req:Add('id',14). req:Add('descricao','Stale'). req:Add('original',originalValue). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_CHANGED',409).
 FIND formats WHERE formats.formato_amostra_id=14. originalValue=NEW JsonObject(). originalValue:Add('descricao',formats.descricao). originalValue:Add('log_inativo',formats.log_inativo).
 CREATE items. ASSIGN items.item_proc_compra_id=77 items.formato_amostra_id=14.
 RUN Request('delete'). req:Add('id',14). req:Add('original',originalValue). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_DEPENDENCY',409).
 RUN Check(CAN-FIND(FIRST formats WHERE formats.formato_amostra_id=14),'referenced format retained').
 FOR EACH items: DELETE items. END.
 RUN Request('delete'). req:Add('id',14). req:Add('original',originalValue). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('formato_amostra_id')=14 AND NOT CAN-FIND(FIRST formats WHERE formats.formato_amostra_id=14),'delete preserves prior snapshot').
 RUN Request('create'). req:Add('descricao','Depois da exclusao'). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('data'):GetInteger('formato_amostra_id')=16,'deleted id not reused').
 RUN SetNext IN identityHandle(15). RUN Request('create'). req:Add('descricao','Collision'). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_ID_COLLISION',409).
 RUN Check(CAN-FIND(FIRST formats WHERE formats.formato_amostra_id=15 AND formats.descricao=FILL('A',40)),'collision does not overwrite existing').
 RUN SetNext IN identityHandle(30).
 /* Full-batch rollback after an earlier create; sequence values are consumed. */
 RUN Request('batch'). changesValue=NEW JsonArray(). changeValue=NEW JsonObject(). dataValue=NEW JsonObject(). dataValue:Add('descricao','Rollback row'). changeValue:Add('operation','create'). changeValue:Add('clientId','new'). changeValue:Add('data',dataValue). changesValue:Add(changeValue).
 changeValue=NEW JsonObject(). changeValue:Add('operation','delete'). changeValue:Add('clientId','missing'). changeValue:Add('id',999). dataValue=NEW JsonObject(). dataValue:Add('descricao','Missing'). dataValue:Add('log_inativo',FALSE). changeValue:Add('original',dataValue). changesValue:Add(changeValue). req:Add('changes',changesValue). RUN Invoke. RUN ErrorCode('CIW_CADASTRO_NOT_FOUND',404).
 RUN Check(NOT CAN-FIND(FIRST formats WHERE formats.formato_amostra_id=30),'earlier create rolled back').
 RUN Request('create'). req:Add('descricao','Apos rollback'). RUN Invoke. RUN Success. RUN Check(res:GetJsonObject('data'):GetInteger('formato_amostra_id')=31,'sequence not reset by rollback').
 RUN Request('create'). req:Add('descricao','No provider'). RUN NoIdentity. RUN ErrorCode('CIW_CADASTRO_CONFIGURATION',503).
 FIND formats WHERE formats.formato_amostra_id=13. formats.descricao='Histórico'.
 originalValue=NEW JsonObject(). originalValue:Add('descricao','Histórico'). originalValue:Add('log_inativo',FALSE).
 RUN Request('update'). req:Add('id',13). req:Add('log_inativo',TRUE). req:Add('original',originalValue). RUN Invoke. RUN Success.
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('descricao')='Histórico','historical snapshot not rejected by new-text whitelist').
 RUN Check(NUM-DBS=0 AND SESSION:NUMERIC-FORMAT=culture,'isolated and culture preserved').
 PUT UNFORMATTED 'PASS formats checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
 FINALLY: IF VALID-HANDLE(identityHandle) THEN DELETE PROCEDURE identityHandle. END FINALLY.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE Request:
 DEFINE INPUT PARAMETER operationValue AS CHARACTER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',operationValue).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Success: RUN Check(res:GetLogical('success'),IF res:Has('error') THEN res:GetJsonObject('error'):GetCharacter('code') ELSE 'success required'). END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetCharacter('code')=codeValue AND res:GetJsonObject('error'):GetInteger('status')=statusValue,codeValue).
END PROCEDURE.
PROCEDURE Invoke:
 res=?. IF SEARCH('sursum-api/programs/CiwCadastroCoreService.p')=? THEN UNDO, THROW NEW Progress.Lang.AppError('Core resource not implemented',1).
 RUN sursum-api/programs/CiwCadastroCoreService.p(INPUT BUFFER formats:HANDLE,INPUT BUFFER items:HANDLE,?,identityHandle,policy,req,OUTPUT res).
END PROCEDURE.
PROCEDURE NoIdentity:
 res=?. RUN sursum-api/programs/CiwCadastroCoreService.p(INPUT BUFFER formats:HANDLE,INPUT BUFFER items:HANDLE,?,?,policy,req,OUTPUT res).
END PROCEDURE.

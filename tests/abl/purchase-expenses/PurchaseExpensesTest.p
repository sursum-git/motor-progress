BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttExpenses FIELD despesa_proc_compra_id AS INTEGER FIELD proc_compra_id AS DECIMAL DECIMALS 2 FIELD despesa_id AS INTEGER FIELD vl_prev AS DECIMAL DECIMALS 2 FIELD calc_imp_proc_compra_id AS INTEGER INDEX pk IS PRIMARY UNIQUE despesa_proc_compra_id.
DEFINE TEMP-TABLE ttOrders FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD qt_container AS INTEGER FIELD cod_situacao AS INTEGER FIELD cod_proc_fornec AS CHARACTER FIELD qt_dias_translado AS INTEGER FIELD cotacao_prevista AS DECIMAL FIELD observacao AS CHARACTER FIELD dt_registro AS DATE FIELD fornecedor_id AS INTEGER FIELD dt_limite AS DATE FIELD log_facilid_contato_fornec AS LOGICAL FIELD log_considerar_previsao AS LOGICAL FIELD nr_container_original AS CHARACTER INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttDefs FIELD despesa_id AS INTEGER FIELD descricao AS CHARACTER FIELD log_imposto AS INTEGER INDEX pk IS PRIMARY UNIQUE despesa_id.
DEFINE TEMP-TABLE ttLinks FIELD empresa_despesa_id AS INTEGER FIELD empresa_id AS INTEGER FIELD despesa_id AS INTEGER FIELD log_ativo AS INTEGER FIELD vl_padrao AS DECIMAL DECIMALS 2 INDEX pk IS PRIMARY UNIQUE empresa_despesa_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE val AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO INITIAL 100.
DEFINE VARIABLE idValue AS INTEGER NO-UNDO. DEFINE VARIABLE oldStamp AS CHARACTER NO-UNDO. DEFINE VARIABLE newStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE actorValue AS CHARACTER NO-UNDO INITIAL 'teste'. DEFINE VARIABLE failAfter AS INTEGER NO-UNDO INITIAL -1.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO. DEFINE VARIABLE beforeSequence AS INTEGER NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('expenses-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed.
 RUN Request('create'). val=NEW JsonObject(). val:Add('despesa_id',7). val:Add('vl_prev',12.5). req:Add('values',val). RUN Invoke.
 RUN Check(VALID-OBJECT(res),'expense service not implemented').
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'expense create must commit').
 idValue=res:GetJsonObject('data'):GetInteger('despesa_proc_compra_id'). oldStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Check(idValue=101 AND res:GetJsonObject('data'):GetInteger('proc_compra_id')=10,'server sequence and integer owner despite physical decimal').
 RUN Check(res:GetJsonObject('data'):GetDecimal('vl_prev')=12.5 AND res:GetJsonObject('data'):GetCharacter('despesa_descricao')='Desp7','amount and shared description projection').
 RUN Check(res:GetJsonObject('audit'):GetJsonArray('before'):Length=0 AND res:GetJsonObject('audit'):GetJsonObject('after'):Has('calc_imp_proc_compra_id') AND res:GetJsonObject('audit'):GetJsonObject('actor'):GetCharacter('login')='teste','complete five-field create image and actor').
 RUN HiddenCalc.
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. newStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',newStamp). val=NEW JsonObject(). val:Add('vl_prev',25.75). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetDecimal('vl_prev')=25.75,'manual amount update').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('calc_imp_proc_compra_id')=99 AND res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('calc_imp_proc_compra_id')=99,'hidden calculation identity preserved and audited').
 newStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). val=NEW JsonObject(). val:Add('vl_prev',1). req:Add('values',val). RUN Invoke. RUN Status(409,'stale version rejected').
 RUN Request('get'). req:Add('id',idValue). req:Remove('proc_compra_id'). req:Add('proc_compra_id',11). RUN Invoke. RUN Status(404,'foreign MED process rejected').
 RUN Request('get'). req:Add('id',idValue). req:Remove('proc_compra_id'). req:Add('proc_compra_id',20). RUN Invoke. RUN Status(404,'non MED owner rejected').
 RUN Request('create'). req:Remove('proc_compra_id'). RUN Invoke. RUN Status(422,'missing process rejected').
 RUN Request('create'). req:Add('actor','forged'). RUN Invoke. RUN Status(422,'browser actor cannot override authenticated actor').
 RUN Request('create'). val=NEW JsonObject(). val:Add('despesa_id',7). val:Add('calc_imp_proc_compra_id',88). req:Add('values',val). RUN Invoke. RUN Status(422,'calculation field not writable').
 RUN Request('create'). val=NEW JsonObject(). val:Add('despesa_id',7). val:Add('vl_prev',0.001). req:Add('values',val). RUN Invoke. RUN Status(422,'physical scale checked before rounding').
 RUN Request('create'). val=NEW JsonObject(). val:Add('despesa_id',7). val:Add('vl_prev','1,25'). req:Add('values',val). RUN Invoke. RUN Status(422,'localized strings not accepted as JSON numbers').
 RUN Request('create'). val=NEW JsonObject(). val:Add('despesa_id',7.5). req:Add('values',val). RUN Invoke. RUN Status(422,'fractional identity rejected').
 RUN Request('create'). val=NEW JsonObject(). val:Add('despesa_id',999). req:Add('values',val). RUN Invoke. RUN Status(422,'missing expense definition rejected').
 RUN Request('generate'). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed') AND res:GetJsonObject('data'):GetCharacter('type')='message','explicit generation committed').
 RUN Check(res:GetJsonObject('audit'):GetJsonArray('changes'):Length=1 AND res:GetInteger('created')=1 AND res:GetInteger('skipped')=1,'generate only missing eligible expense').
 RUN Check(CAN-FIND(FIRST ttExpenses WHERE proc_compra_id=10 AND despesa_id=8) AND NOT CAN-FIND(FIRST ttExpenses WHERE proc_compra_id=10 AND LOOKUP(STRING(despesa_id),'9,10,11')>0),'inactive tax and foreign-company definitions excluded').
 FIND FIRST ttExpenses WHERE despesa_proc_compra_id=idValue NO-LOCK.
 RUN Check(ttExpenses.vl_prev=25.75 AND ttExpenses.calc_imp_proc_compra_id=99,'generation preserves manually changed value and calculation identity').
 beforeSequence=sequenceValue. RUN Request('generate'). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('created')=0 AND res:GetInteger('skipped')=2 AND res:GetJsonObject('audit'):GetJsonArray('changes'):Length=0 AND sequenceValue=beforeSequence,'second generation is idempotent and consumes no identity').
 RUN AddAmbiguity. RUN Request('generate'). RUN Invoke. RUN Status(409,'ambiguous active duplicate configuration rejected').
 RUN Check(sequenceValue=beforeSequence AND NOT CAN-FIND(FIRST ttExpenses WHERE proc_compra_id=10 AND despesa_id=12),'ambiguous plan has no partial rows or sequence calls').
 RUN RemoveAmbiguity. failAfter=1. RUN Request('generate'). RUN Invoke. RUN Status(503,'late sequence failure rolls entire generation back'). failAfter=-1.
 RUN Check(NOT CAN-FIND(FIRST ttExpenses WHERE proc_compra_id=10 AND LOOKUP(STRING(despesa_id),'12,13')>0),'all new rows rolled back on late failure').
 RUN Request('generate'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('created')=2,'valid generation after rollback leaves sequence gap').
 RUN Request('read'). req:Add('skip',0). req:Add('take',1). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=4 AND res:GetJsonArray('data'):Length=1,'shared reader pagination scoped to process').
 RUN Check(res:GetJsonArray('data'):GetJsonObject(1):Has('row_stamp') AND NOT res:GetJsonArray('data'):GetJsonObject(1):Has('record_key'),'DTO uses typed identity and hidden optimistic stamp').
 RUN Request('read'). val=NEW JsonObject(). val:Add('field','despesa_id'). val:Add('operator','eq'). val:Add('value',8). req:Add('filter',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'shared reader filter').
 RUN Request('options'). req:Add('lookup','despesa'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=7,'manual options match all expense definitions in regenerated form').
 RUN ForeignFraction.
 RUN Request('get'). req:Add('id',900). RUN Invoke. RUN Status(404,'fractional stored owner never truncated into selected process').
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. newStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('delete'). req:Add('id',idValue). req:Add('row_stamp',newStamp). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('calc_imp_proc_compra_id')=99 AND res:GetJsonObject('audit'):GetJsonArray('after'):Length=0,'delete has complete before and absent after').
 RUN Check(NOT CAN-FIND(FIRST ttExpenses WHERE despesa_proc_compra_id=idValue),'only selected row deleted').
 RUN Request('generate'). DO TRANSACTION: RUN Invoke. END. RUN Status(409,'external transaction rejected').
 actorValue=''. RUN Request('generate'). RUN Invoke. RUN Status(401,'authenticated actor required'). actorValue='teste'.
 PUT UNFORMATTED 'PASS expenses checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH err AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' err:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Status:
 DEFINE INPUT PARAMETER codeValue AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 RUN Check(NOT res:GetLogical('success') AND NOT res:GetLogical('committed') AND res:GetJsonObject('error'):GetInteger('status')=codeValue,msg).
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER opValue AS CHARACTER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',opValue). req:Add('proc_compra_id',10).
END PROCEDURE.
PROCEDURE Invoke:
 res=?. IF SEARCH('sursum-api/programs/PurchaseExpensesService.p')=? THEN RETURN.
 RUN VALUE('sursum-api/programs/PurchaseExpensesService.p')(INPUT BUFFER ttExpenses:HANDLE,INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttDefs:HANDLE,INPUT BUFFER ttLinks:HANDLE,THIS-PROCEDURE,actorValue,req,OUTPUT res) NO-ERROR.
END PROCEDURE.
PROCEDURE Seed:
 DO TRANSACTION:
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5. CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=1.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2 ttOrders.fornecedor_id=7 ttOrders.dt_registro=DATE(10,23,2026).
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=11 ttOrders.empresa_id=2 ttOrders.fornecedor_id=7.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=20 ttOrders.empresa_id=3 ttOrders.fornecedor_id=7.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=7 ttDefs.descricao='Desp7'. CREATE ttDefs. ASSIGN ttDefs.despesa_id=8 ttDefs.descricao='Desp8'.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=9 ttDefs.descricao='Inactive'. CREATE ttDefs. ASSIGN ttDefs.despesa_id=10 ttDefs.descricao='Tax' ttDefs.log_imposto=1.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=11 ttDefs.descricao='Foreign'. CREATE ttDefs. ASSIGN ttDefs.despesa_id=12 ttDefs.descricao='Later1'. CREATE ttDefs. ASSIGN ttDefs.despesa_id=13 ttDefs.descricao='Later2'.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=1 ttLinks.empresa_id=2 ttLinks.despesa_id=7 ttLinks.log_ativo=1 ttLinks.vl_padrao=9.99.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=2 ttLinks.empresa_id=2 ttLinks.despesa_id=8 ttLinks.log_ativo=1 ttLinks.vl_padrao=3.25.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=3 ttLinks.empresa_id=2 ttLinks.despesa_id=9 ttLinks.log_ativo=0 ttLinks.vl_padrao=4.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=4 ttLinks.empresa_id=2 ttLinks.despesa_id=10 ttLinks.log_ativo=1 ttLinks.vl_padrao=5.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=5 ttLinks.empresa_id=3 ttLinks.despesa_id=11 ttLinks.log_ativo=1 ttLinks.vl_padrao=6.
 END.
END PROCEDURE.
PROCEDURE HiddenCalc: DO TRANSACTION: FIND ttExpenses WHERE despesa_proc_compra_id=idValue. ttExpenses.calc_imp_proc_compra_id=99. END. END PROCEDURE.
PROCEDURE ForeignFraction: DO TRANSACTION: CREATE ttExpenses. ASSIGN ttExpenses.despesa_proc_compra_id=900 ttExpenses.proc_compra_id=10.5 ttExpenses.despesa_id=7. END. END PROCEDURE.
PROCEDURE AddAmbiguity:
 DO TRANSACTION:
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=6 ttLinks.empresa_id=2 ttLinks.despesa_id=7 ttLinks.log_ativo=1 ttLinks.vl_padrao=99.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=7 ttLinks.empresa_id=2 ttLinks.despesa_id=12 ttLinks.log_ativo=1 ttLinks.vl_padrao=7.25.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=8 ttLinks.empresa_id=2 ttLinks.despesa_id=13 ttLinks.log_ativo=1 ttLinks.vl_padrao=8.25.
 END.
END PROCEDURE.
PROCEDURE RemoveAmbiguity: DO TRANSACTION: FIND ttLinks WHERE empresa_despesa_id=6. DELETE ttLinks. END. END PROCEDURE.
PROCEDURE NextRawPurchaseExpenseId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 IF failAfter=0 THEN DO: valueId=0. RETURN. END.
 IF failAfter>0 THEN failAfter=failAfter - 1.
 sequenceValue=sequenceValue + 1. valueId=sequenceValue.
END PROCEDURE.

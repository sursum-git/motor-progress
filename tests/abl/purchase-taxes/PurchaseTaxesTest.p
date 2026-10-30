BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttOrders FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD qt_container AS INTEGER FIELD cod_situacao AS INTEGER FIELD cod_proc_fornec AS CHARACTER FIELD qt_dias_translado AS INTEGER FIELD cotacao_prevista AS DECIMAL FIELD observacao AS CHARACTER FIELD dt_registro AS DATE FIELD fornecedor_id AS INTEGER FIELD dt_limite AS DATE FIELD log_facilid_contato_fornec AS LOGICAL FIELD log_considerar_previsao AS LOGICAL FIELD nr_container_original AS CHARACTER INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttItems FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD qt_comprada AS DECIMAL DECIMALS 10 FIELD vl_base_tributacao AS DECIMAL DECIMALS 10 FIELD vl_negociado AS DECIMAL DECIMALS 10 INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttExpenses FIELD despesa_proc_compra_id AS INTEGER FIELD proc_compra_id AS DECIMAL DECIMALS 2 FIELD despesa_id AS INTEGER FIELD vl_prev AS DECIMAL DECIMALS 2 FIELD calc_imp_proc_compra_id AS INTEGER INDEX pk IS PRIMARY UNIQUE despesa_proc_compra_id.
DEFINE TEMP-TABLE ttDefs FIELD despesa_id AS INTEGER FIELD descricao AS CHARACTER FIELD log_imposto AS INTEGER FIELD log_calc_por_item AS INTEGER INDEX pk IS PRIMARY UNIQUE despesa_id.
DEFINE TEMP-TABLE ttLinks FIELD empresa_despesa_id AS INTEGER FIELD empresa_id AS INTEGER FIELD despesa_id AS INTEGER FIELD percentual AS DECIMAL DECIMALS 4 FIELD log_ativo AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_despesa_id.
DEFINE TEMP-TABLE ttBases FIELD empresa_id AS INTEGER FIELD imposto_id AS INTEGER FIELD despesa_id AS INTEGER INDEX tax empresa_id imposto_id despesa_id.
DEFINE TEMP-TABLE ttCalcs FIELD calc_imp_proc_compra_id AS INTEGER FIELD dt_hr_calculo AS DATETIME FIELD usuario_id AS CHARACTER INDEX pk IS PRIMARY UNIQUE calc_imp_proc_compra_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE changesValue AS JsonArray NO-UNDO. DEFINE VARIABLE effectValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE calcSequence AS INTEGER NO-UNDO INITIAL 100. DEFINE VARIABLE expenseSequence AS INTEGER NO-UNDO INITIAL 200.
DEFINE VARIABLE beforeCalc AS INTEGER NO-UNDO. DEFINE VARIABLE beforeExpense AS INTEGER NO-UNDO. DEFINE VARIABLE failAfter AS INTEGER NO-UNDO INITIAL -1.
DEFINE VARIABLE actorValue AS CHARACTER NO-UNDO INITIAL 'real'. DEFINE VARIABLE culture AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE newCalc AS INTEGER NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('taxes-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed.
 RUN Request. RUN Invoke. RUN Check(VALID-OBJECT(res),'purchase tax service not implemented').
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'fiscal command commits').
 newCalc=res:GetInteger('calculationId'). RUN Check(newCalc=101 AND res:GetInteger('created')=2 AND res:GetInteger('updated')=1,'one header, two missing taxes, one update').
 RUN ValueCheck(2,11). RUN ValueCheck(3,6.16). RUN ValueCheck(4,2.2).
 RUN Check(CAN-FIND(FIRST ttCalcs WHERE ttCalcs.calc_imp_proc_compra_id=newCalc AND ttCalcs.usuario_id='real'),'trusted actor on physical calculation').
 changesValue=res:GetJsonObject('audit'):GetJsonArray('changes').
 RUN Check(changesValue:Length=4 AND res:GetJsonObject('audit'):GetCharacter('operation')='calculate_taxes','root and every physical effect auditable').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('actor'):GetCharacter('login')='real','actor not inferred from owner or browser').
 effectValue=changesValue:GetJsonObject(1). RUN Check(effectValue:GetCharacter('resource')='calcs-imp-proc-compra' AND effectValue:GetJsonObject('after'):GetCharacter('usuario_id')='real','calculation create image').
 DO k=2 TO changesValue:Length:
  effectValue=changesValue:GetJsonObject(k). RUN Check(effectValue:GetJsonObject('after'):GetInteger('calc_imp_proc_compra_id')=newCalc,'expense effect belongs to new calculation').
 END.
 RUN Request. RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('created')=0 AND res:GetInteger('updated')=3 AND res:GetInteger('calculationId')=102,'explicit repeat updates without duplicates').
 RUN Check(CAN-FIND(FIRST ttExpenses WHERE ttExpenses.despesa_proc_compra_id=1 AND ttExpenses.vl_prev=10),'manual base preserved').
 RUN SetCase('round'). RUN Request. RUN Invoke. RUN Check(res:GetLogical('success'),'fractional product base supported'). RUN ValueCheck(2,11.01). RUN ValueCheck(3,6.17).
 RUN Seed. RUN SetCase('cycle'). RUN InvalidPlan('cycle').
 RUN Seed. RUN SetCase('duplicate-link'). RUN InvalidPlan('ambiguous percentage').
 RUN Seed. RUN SetCase('duplicate-base'). RUN InvalidPlan('duplicate fiscal component').
 RUN Seed. RUN SetCase('duplicate-target'). RUN InvalidPlan('ambiguous tax target').
 RUN Seed. RUN SetCase('missing-percent'). RUN InvalidPlan('missing percentage').
 RUN Seed. RUN SetCase('unknown-definition'). RUN InvalidPlan('unknown fiscal component').
 RUN Seed. RUN SetCase('other-company'). RUN Request. RUN Invoke. RUN Status(404,'nonMED parent refused').
 RUN Seed. RUN Request. req:Add('usuario','fake'). RUN Invoke. RUN Status(422,'browser actor forbidden').
 RUN Request. req:Remove('proc_compra_id'). req:Add('proc_compra_id',10.5). RUN Invoke. RUN Status(422,'fractional owner refused').
 RUN Request. req:Remove('proc_compra_id'). RUN Invoke. RUN Status(422,'mandatory context').
 RUN Request. req:Set('operation','generate'). RUN Invoke. RUN Status(405,'fixed fiscal operation only').
 actorValue=''. RUN Request. RUN Invoke. RUN Status(401,'trusted actor mandatory'). actorValue='real'.
 RUN Request. DO TRANSACTION: RUN Invoke. END. RUN Status(409,'independent root transaction required').
 RUN Seed. failAfter=expenseSequence + 2. RUN Request. RUN Invoke. RUN Status(503,'injected second insert sequence failure'). failAfter=-1.
 RUN Check(NOT CAN-FIND(FIRST ttCalcs),'header rolled back'). RUN Check(NOT CAN-FIND(FIRST ttExpenses WHERE ttExpenses.despesa_proc_compra_id>200),'first tax insert rolled back'). RUN ValueCheck(2,99).
 RUN Seed. RUN SetCase('zero-percent'). RUN Request. RUN Invoke. RUN Check(res:GetLogical('success'),'zero percentage valid'). RUN ValueCheck(2,0).
 RUN Seed. RUN SetCase('no-roots'). RUN Request. RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('created')=0 AND res:GetInteger('updated')=0,'empty root plan allowed and audited header').
 PUT UNFORMATTED 'PASS taxes checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
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
PROCEDURE ValueCheck:
 DEFINE INPUT PARAMETER did AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER expected AS DECIMAL NO-UNDO.
 FIND FIRST ttExpenses WHERE ttExpenses.proc_compra_id=10 AND ttExpenses.despesa_id=did NO-LOCK NO-ERROR.
 RUN Check(AVAILABLE ttExpenses AND ttExpenses.vl_prev=expected,'wrong tax amount for expense ' + STRING(did)).
END PROCEDURE.
PROCEDURE InvalidPlan:
 DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 ASSIGN beforeCalc=calcSequence beforeExpense=expenseSequence. RUN Request. RUN Invoke.
 RUN Check(NOT res:GetLogical('success') AND NOT res:GetLogical('committed') AND LOOKUP(STRING(res:GetJsonObject('error'):GetInteger('status')),'409,422')>0,msg).
 RUN Check(calcSequence=beforeCalc AND expenseSequence=beforeExpense AND NOT CAN-FIND(FIRST ttCalcs),'invalid plan consumes no identity'). RUN ValueCheck(2,99).
END PROCEDURE.
PROCEDURE Request: req=NEW JsonObject(). req:Add('operation','calculate_taxes'). req:Add('proc_compra_id',10). END PROCEDURE.
PROCEDURE Invoke:
 res=?. IF SEARCH('sursum-api/programs/PurchaseTaxesService.p')=? THEN RETURN.
 RUN VALUE('sursum-api/programs/PurchaseTaxesService.p')(INPUT BUFFER ttExpenses:HANDLE,INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttDefs:HANDLE,INPUT BUFFER ttLinks:HANDLE,INPUT BUFFER ttBases:HANDLE,INPUT BUFFER ttCalcs:HANDLE,THIS-PROCEDURE,actorValue,req,OUTPUT res).
END PROCEDURE.
PROCEDURE NextRawPurchaseTaxCalcId:
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Root transaction required',1).
 calcSequence=calcSequence + 1. idValue=calcSequence.
END PROCEDURE.
PROCEDURE NextRawPurchaseExpenseId:
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Root transaction required',1).
 expenseSequence=expenseSequence + 1. IF expenseSequence=failAfter THEN UNDO, THROW NEW Progress.Lang.AppError('Forced expense failure',1). idValue=expenseSequence.
END PROCEDURE.
PROCEDURE Seed:
 DO TRANSACTION:
  EMPTY TEMP-TABLE ttOrders. EMPTY TEMP-TABLE ttCompanies. EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttExpenses. EMPTY TEMP-TABLE ttDefs. EMPTY TEMP-TABLE ttLinks. EMPTY TEMP-TABLE ttBases. EMPTY TEMP-TABLE ttCalcs.
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5. CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=1.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2 ttOrders.cotacao_prevista=99 ttOrders.qt_container=9 ttOrders.dt_registro=TODAY ttOrders.fornecedor_id=7.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=1 ttItems.proc_compra_id=10 ttItems.qt_comprada=2 ttItems.vl_base_tributacao=50 ttItems.vl_negociado=999.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=2 ttItems.proc_compra_id=10 ttItems.qt_comprada=? ttItems.vl_base_tributacao=50.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=3 ttItems.proc_compra_id=20 ttItems.qt_comprada=999 ttItems.vl_base_tributacao=999.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=1 ttDefs.descricao='manual' ttDefs.log_imposto=0.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=2 ttDefs.log_imposto=1 ttDefs.log_calc_por_item=0.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=3 ttDefs.log_imposto=1 ttDefs.log_calc_por_item=0.
  CREATE ttDefs. ASSIGN ttDefs.despesa_id=4 ttDefs.log_imposto=1 ttDefs.log_calc_por_item=1.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=1 ttLinks.empresa_id=2 ttLinks.despesa_id=2 ttLinks.percentual=10 ttLinks.log_ativo=0.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=2 ttLinks.empresa_id=2 ttLinks.despesa_id=3 ttLinks.percentual=5 ttLinks.log_ativo=1.
  CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=3 ttLinks.empresa_id=2 ttLinks.despesa_id=4 ttLinks.percentual=2 ttLinks.log_ativo=1.
  CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=2 ttBases.despesa_id=1.
  CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=3 ttBases.despesa_id=1.
  CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=3 ttBases.despesa_id=2.
  CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=3 ttBases.despesa_id=4.
  CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=4 ttBases.despesa_id=1.
  CREATE ttBases. ASSIGN ttBases.empresa_id=3 ttBases.imposto_id=2 ttBases.despesa_id=2.
  CREATE ttExpenses. ASSIGN ttExpenses.despesa_proc_compra_id=1 ttExpenses.proc_compra_id=10 ttExpenses.despesa_id=1 ttExpenses.vl_prev=10 ttExpenses.calc_imp_proc_compra_id=0.
  CREATE ttExpenses. ASSIGN ttExpenses.despesa_proc_compra_id=2 ttExpenses.proc_compra_id=10 ttExpenses.despesa_id=2 ttExpenses.vl_prev=99 ttExpenses.calc_imp_proc_compra_id=99.
  CREATE ttExpenses. ASSIGN ttExpenses.despesa_proc_compra_id=3 ttExpenses.proc_compra_id=10.5 ttExpenses.despesa_id=1 ttExpenses.vl_prev=999.
 END.
END PROCEDURE.
PROCEDURE SetCase:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 DO TRANSACTION:
  CASE c:
   WHEN 'round' THEN DO: FIND ttItems WHERE item_proc_compra_id=1. ttItems.vl_base_tributacao=50.061725. END.
   WHEN 'cycle' THEN DO: CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=2 ttBases.despesa_id=3. END.
   WHEN 'duplicate-base' THEN DO: CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=2 ttBases.despesa_id=1. END.
   WHEN 'duplicate-link' THEN DO: CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=4 ttLinks.empresa_id=2 ttLinks.despesa_id=2 ttLinks.percentual=90. END.
   WHEN 'duplicate-target' THEN DO: CREATE ttExpenses. ASSIGN ttExpenses.despesa_proc_compra_id=4 ttExpenses.proc_compra_id=10 ttExpenses.despesa_id=2 ttExpenses.vl_prev=99. END.
   WHEN 'missing-percent' THEN DO: FIND ttLinks WHERE empresa_despesa_id=1. ttLinks.percentual=?. END.
   WHEN 'unknown-definition' THEN DO: CREATE ttBases. ASSIGN ttBases.empresa_id=2 ttBases.imposto_id=2 ttBases.despesa_id=999. END.
   WHEN 'other-company' THEN DO: FIND ttOrders WHERE ttOrders.proc_compra_id=10. ttOrders.empresa_id=3. END.
   WHEN 'zero-percent' THEN DO: FIND ttLinks WHERE empresa_despesa_id=1. ttLinks.percentual=0. END.
   WHEN 'no-roots' THEN DO: FOR EACH ttDefs WHERE log_imposto=1: ttDefs.log_calc_por_item=1. END. END.
  END CASE.
 END.
END PROCEDURE.

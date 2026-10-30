/* Fixed read-only sources; formulas are delegated to IolGerencialCalculator. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poScope AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pdReference AS DATE NO-UNDO.
DEFINE INPUT PARAMETER phSources AS HANDLE EXTENT 20 NO-UNDO.
DEFINE OUTPUT PARAMETER poSnapshot AS JsonObject NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE qOther AS HANDLE NO-UNDO.
DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPeriod AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSellerCodes AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCalendar AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
DEFINE VARIABLE iRep AS INTEGER NO-UNDO.
DEFINE VARIABLE iTotalDays AS INTEGER NO-UNDO.
DEFINE VARIABLE iElapsed AS INTEGER NO-UNDO.
DEFINE VARIABLE iPending AS INTEGER NO-UNDO.
DEFINE VARIABLE iOpen AS INTEGER NO-UNDO.
DEFINE VARIABLE dtStart AS DATE NO-UNDO.
DEFINE VARIABLE dtEnd AS DATE NO-UNDO.
DEFINE VARIABLE dtDay AS DATE NO-UNDO.
DEFINE VARIABLE dSales AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dReturns AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dTarget AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dFortnight AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dStoreTarget AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dStoreSales AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dAmount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDiscount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dPercent AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE oPart AS JsonObject NO-UNDO.
DEFINE VARIABLE aSellers AS JsonArray NO-UNDO.
DEFINE TEMP-TABLE ttIolSeller NO-UNDO
 FIELD repId AS INTEGER FIELD repName AS CHARACTER FIELD target AS DECIMAL DECIMALS 10
 INDEX ix IS UNIQUE repId.
DEFINE TEMP-TABLE ttIolSale NO-UNDO
 FIELD repName AS CHARACTER FIELD saleAmount AS DECIMAL DECIMALS 10 FIELD saleDiscount AS DECIMAL DECIMALS 10
 FIELD returnAmount AS DECIMAL DECIMALS 10 FIELD returnDiscount AS DECIMAL DECIMALS 10
 INDEX ix IS UNIQUE repName.
{IolReadBuffers.i}
FUNCTION ScopeCondition RETURNS CHARACTER (n AS INTEGER,c AS CHARACTER,lName AS LOGICAL):
 IF poScope:GetLogical("general") THEN RETURN "TRUE".
 IF lName THEN RETURN "LOOKUP(" + FieldName(n,c) + "," + QUOTER(poScope:GetCharacter("names")) + ") > 0".
 RETURN "LOOKUP(STRING(" + FieldName(n,c) + ")," + QUOTER(poScope:GetCharacter("representatives")) + ") > 0".
END FUNCTION.
FUNCTION DateExpression RETURNS CHARACTER (dt AS DATE):
 RETURN "DATE(" + STRING(MONTH(dt)) + "," + STRING(DAY(dt)) + "," + STRING(YEAR(dt)) + ")".
END FUNCTION.
FUNCTION PeriodCondition RETURNS CHARACTER (n AS INTEGER,monthField AS CHARACTER,yearField AS CHARACTER):
 RETURN FieldName(n,monthField) + " = " + STRING(MONTH(pdReference)) + " AND " + FieldName(n,yearField) + " = " + STRING(YEAR(pdReference)).
END FUNCTION.
FUNCTION SellerCondition RETURNS CHARACTER (n AS INTEGER,c AS CHARACTER):
 RETURN "LOOKUP(STRING(" + FieldName(n,c) + ")," + QUOTER(cSellerCodes) + ") > 0".
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF pdReference=? THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 dtStart=DATE(MONTH(pdReference),1,YEAR(pdReference)).
 dtEnd=ADD-INTERVAL(dtStart,1,"months") - 1.
 cWhere=PeriodCondition(6,"mes","ano") + " AND " + ScopeCondition(6,"cod_rep",FALSE) + " AND LOOKUP(" + FieldName(6,"cod_estabel") + ", '5,505') > 0".
 q=OpenRows(6,cWhere).
 DO WHILE NOT q:QUERY-OFF-END:
  IF FindRow(7,FieldName(7,"transacao_id") + " = " + STRING(NumValue(6,"transacao_id")) + " AND " + FieldName(7,"ind_sit_transacao") + " = 1") THEN
   ASSIGN dSales=dSales + NumValue(6,"vl_faturamento") dReturns=dReturns + NumValue(6,"vl_devolucoes").
  q:GET-NEXT().
 END.
 RUN CloseRows(q).
 IF poScope:GetInteger("role")=2 OR NOT poScope:GetLogical("general") THEN DO:
  IF poScope:Has("_aggregate_program") THEN DO:
   RUN ReadMetaTotal("vl_meta",TRUE,OUTPUT dTarget).
   RUN ReadMetaTotal("vl_meta_quinz",TRUE,OUTPUT dFortnight).
  END.
  ELSE DO:
   q=OpenRows(8,PeriodCondition(8,"mes","ano") + " AND " + ScopeCondition(8,"cod_repres",FALSE)).
   DO WHILE NOT q:QUERY-OFF-END:
    ASSIGN dTarget=dTarget + NumValue(8,"vl_meta") dFortnight=dFortnight + NumValue(8,"vl_meta_quinz").
    q:GET-NEXT().
   END.
   RUN CloseRows(q).
  END.
 END.
 ELSE DO:
  IF FindRow(10,PeriodCondition(10,"mes","ano")) THEN dTarget=NumValue(10,"meta").
  RUN ReadMetaTotal("vl_meta_quinz",FALSE,OUTPUT dFortnight).
 END.
 IF poScope:GetInteger("role")<>2 AND poScope:GetInteger("hierarchy_type")=3 THEN DO:
  dTarget=0. dFortnight=0.
  IF FindRow(9,PeriodCondition(9,"mes","ano") + " AND " + FieldName(9,"cod_rep_ger") + " = " + STRING(poScope:GetInteger("representative"))) THEN dTarget=NumValue(9,"meta").
 END.
 IF FindRow(9,PeriodCondition(9,"mes","ano") + " AND " + FieldName(9,"cod_rep_ger") + " = 11130") THEN dStoreTarget=NumValue(9,"meta").
 cCalendar=poScope:GetCharacter("calendar_code").
 IF cCalendar=? OR cCalendar="" THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_CALENDAR_INVALID",1).
 q=OpenRows(18,FieldName(18,"cod_calend") + " = " + QUOTER(cCalendar) + " AND " + FieldName(18,"dat_calend") + " >= " + DateExpression(dtStart) + " AND " + FieldName(18,"dat_calend") + " <= " + DateExpression(dtEnd) + " AND " + FieldName(18,"log_dia_util") + " = TRUE").
 DO WHILE NOT q:QUERY-OFF-END:
  dtDay=FieldHandle(18,"dat_calend"):BUFFER-VALUE.
  IF WEEKDAY(dtDay)>1 AND WEEKDAY(dtDay)<7 THEN DO:
   iTotalDays=iTotalDays + 1.
   IF dtDay<=pdReference THEN iElapsed=iElapsed + 1.
  END.
  q:GET-NEXT().
 END.
 RUN CloseRows(q).
 cWhere=FieldName(11,"ind_sit_ped_web") + " = 8".
 IF NOT poScope:GetLogical("general") THEN cWhere=cWhere + " AND LOOKUP(" + FieldName(11,"login") + "," + QUOTER(poScope:GetCharacter("names")) + ") > 0".
 IF poScope:Has("_aggregate_program") THEN DO:
  RUN VALUE(poScope:GetCharacter("_aggregate_program"))("pending",poScope,pdReference,TRUE,OUTPUT dAmount).
  iPending=INTEGER(dAmount).
 END.
 ELSE DO:
  q=OpenRows(11,cWhere).
  DO WHILE NOT q:QUERY-OFF-END: iPending=iPending + 1. q:GET-NEXT(). END.
  RUN CloseRows(q).
 END.
 cQuery="FOR EACH " + phSources[12]:NAME + " NO-LOCK WHERE " + FieldName(12,"cod-sit-ped") + " <> 3 AND " + FieldName(12,"cod-sit-ped") + " <> 6 AND ((" + FieldName(12,"completo") + " = TRUE AND " + FieldName(12,"tp-pedido") + " = 'PE') OR " + FieldName(12,"tp-pedido") + " = 'PI') AND " + ScopeCondition(12,"no-ab-reppri",TRUE)
  + ", EACH " + phSources[13]:NAME + " NO-LOCK WHERE " + FieldName(13,"nr-pedido") + " = " + FieldName(12,"nr-pedido") + " AND " + FieldName(13,"nome-ab-rep") + " = " + FieldName(12,"no-ab-reppri") + " AND " + FieldName(13,"nome-ab-rep") + " <> 'fulano'".
 q=OpenJoin("12,13",cQuery).
 DO WHILE NOT q:QUERY-OFF-END: iOpen=iOpen + 1. q:GET-NEXT(). END.
 RUN CloseRows(q).
 /* getVendedores: active users in group2, resolved through CAD repres. */
 q=OpenRows(2,FieldName(2,"cod_grupo") + " = 2").
 DO WHILE NOT q:QUERY-OFF-END:
  cName=TextValue(2,"login_usuario").
  IF FindRow(1,FieldName(1,"Login") + " = " + QUOTER(cName) + " AND " + FieldName(1,"ativo") + " = TRUE") AND FindRow(3,FieldName(3,"nome-abrev") + " = " + QUOTER(cName)) THEN DO:
   iRep=NumValue(3,"cod-rep").
   IF iRep>0 AND NOT CAN-FIND(FIRST ttIolSeller WHERE ttIolSeller.repId=iRep) THEN DO:
    CREATE ttIolSeller. ASSIGN ttIolSeller.repId=iRep ttIolSeller.repName=cName.
    cSellerCodes=cSellerCodes + (IF cSellerCodes="" THEN "" ELSE ",") + STRING(iRep).
   END.
  END.
  q:GET-NEXT().
 END.
 RUN CloseRows(q).
 FOR EACH ttIolSeller:
  q=OpenRows(8,PeriodCondition(8,"mes","ano") + " AND " + FieldName(8,"cod_repres") + " = " + STRING(ttIolSeller.repId)).
  DO WHILE NOT q:QUERY-OFF-END: ttIolSeller.target=NumValue(8,"vl_meta"). q:GET-NEXT(). END.
  RUN CloseRows(q).
 END.
 IF cSellerCodes<>"" THEN DO:
  cQuery="FOR EACH " + phSources[14]:NAME + " NO-LOCK WHERE " + FieldName(14,"dt-emis-nota") + " >= " + DateExpression(dtStart) + " AND " + FieldName(14,"dt-emis-nota") + " <= " + DateExpression(dtEnd) + " AND " + FieldName(14,"dt-cancela") + " = ? AND " + FieldName(14,"cod-emitente") + " <> 1 AND LOOKUP(" + FieldName(14,"cod-estabel") + ",'5,505') > 0 AND " + SellerCondition(14,"cod-rep")
   + ", EACH " + phSources[15]:NAME + " NO-LOCK WHERE " + FieldName(15,"nat-operacao") + " = " + FieldName(14,"nat-operacao") + " AND " + FieldName(15,"tp-rec-desp") + " = 1 AND " + FieldName(15,"tipo-compra") + " <> 3"
   + ", EACH " + phSources[12]:NAME + " NO-LOCK WHERE " + FieldName(12,"nr-pedido") + " = INTEGER(" + FieldName(14,"nr-pedcli") + ")"
   + ", EACH " + phSources[13]:NAME + " NO-LOCK WHERE " + FieldName(13,"nr-pedido") + " = " + FieldName(12,"nr-pedido") + " AND " + FieldName(13,"nome-ab-rep") + " <> 'fulano'".
  q=OpenJoin("14,15,12,13",cQuery).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN ReadAmount(FALSE).
   q:GET-NEXT().
  END.
  RUN CloseRows(q).
  cQuery="FOR EACH " + phSources[16]:NAME + " NO-LOCK WHERE " + FieldName(16,"dt-devol") + " >= " + DateExpression(dtStart) + " AND " + FieldName(16,"dt-devol") + " <= " + DateExpression(dtEnd)
   + ", EACH " + phSources[15]:NAME + " NO-LOCK WHERE " + FieldName(15,"nat-operacao") + " = " + FieldName(16,"nat-operacao") + " AND " + FieldName(15,"tp-rec-desp") + " = 1 AND " + FieldName(15,"tipo-compra") + " = 3"
   + ", EACH " + phSources[17]:NAME + " NO-LOCK WHERE " + FieldName(17,"serie-docto") + " = " + FieldName(16,"serie-docto") + " AND " + FieldName(17,"nro-docto") + " = " + FieldName(16,"nro-docto") + " AND " + FieldName(17,"cod-emitente") + " = " + FieldName(16,"cod-emitente") + " AND " + FieldName(17,"nat-operacao") + " = " + FieldName(16,"nat-operacao") + " AND " + FieldName(17,"cod-emitente") + " <> 1"
   + ", EACH " + phSources[14]:NAME + " NO-LOCK WHERE " + FieldName(14,"cod-estabel") + " = " + FieldName(16,"cod-estabel") + " AND " + FieldName(14,"nr-nota-fis") + " = " + FieldName(16,"nr-nota-fis") + " AND " + FieldName(14,"serie") + " = " + FieldName(16,"serie") + " AND SUBSTRING(" + FieldName(14,"cod-estabel") + ",1,1) = '5' AND " + SellerCondition(14,"cod-rep")
   + ", EACH " + phSources[12]:NAME + " NO-LOCK WHERE " + FieldName(12,"nr-pedido") + " = INTEGER(" + FieldName(14,"nr-pedcli") + ")"
   + ", EACH " + phSources[13]:NAME + " NO-LOCK WHERE " + FieldName(13,"nr-pedido") + " = " + FieldName(12,"nr-pedido").
  q=OpenJoin("16,15,17,14,12,13",cQuery).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN ReadAmount(TRUE).
   q:GET-NEXT().
  END.
  RUN CloseRows(q).
 END.
 FOR EACH ttIolSale: dStoreSales=dStoreSales + ttIolSale.saleAmount + ttIolSale.saleDiscount. END.
 aSellers=NEW JsonArray().
 FOR EACH ttIolSeller:
  /* A seller may see the aggregate store indicator, but not other sellers' individual results. */
  IF poScope:GetInteger("role")=2 AND ttIolSeller.repId<>poScope:GetInteger("representative") THEN NEXT.
  oPart=NEW JsonObject().
  oPart:Add("id",ttIolSeller.repId). oPart:Add("name",ttIolSeller.repName). oPart:Add("target",ttIolSeller.target).
  FIND FIRST ttIolSale WHERE ttIolSale.repName=ttIolSeller.repName NO-ERROR.
  oPart:Add("sales",IF AVAILABLE ttIolSale THEN MAXIMUM(0,ttIolSale.saleAmount) ELSE 0).
  oPart:Add("sales_discount",IF AVAILABLE ttIolSale THEN MAXIMUM(0,ttIolSale.saleDiscount) ELSE 0).
  oPart:Add("returns",IF AVAILABLE ttIolSale THEN ttIolSale.returnAmount ELSE 0).
  oPart:Add("returns_discount",IF AVAILABLE ttIolSale THEN ROUND(ttIolSale.returnDiscount,2) ELSE 0).
  aSellers:Add(oPart).
 END.
 poSnapshot=NEW JsonObject().
 poSnapshot:Add("reference_date",STRING(YEAR(pdReference),"9999") + "-" + STRING(MONTH(pdReference),"99") + "-" + STRING(DAY(pdReference),"99")).
 oPart=NEW JsonObject(). oPart:Add("sales",dSales). oPart:Add("returns",dReturns). oPart:Add("target",dTarget). oPart:Add("target_fortnight",dFortnight). poSnapshot:Add("monthly",oPart).
 oPart=NEW JsonObject(). oPart:Add("manager_target",dStoreTarget). oPart:Add("adjusted_sales",dStoreSales). poSnapshot:Add("store",oPart).
 oPart=NEW JsonObject(). oPart:Add("total",iTotalDays). oPart:Add("elapsed",iElapsed). poSnapshot:Add("calendar",oPart).
 oPart=NEW JsonObject(). oPart:Add("pending",iPending). oPart:Add("open",iOpen). poSnapshot:Add("orders",oPart).
 poSnapshot:Add("sellers",aSellers).
 FINALLY: RUN ReleaseQueries. END FINALLY.
END.

PROCEDURE ReadMetaTotal:
 DEFINE INPUT PARAMETER pcField AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER plScoped AS LOGICAL NO-UNDO.
 DEFINE OUTPUT PARAMETER pdTotal AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE hRows AS HANDLE NO-UNDO.
 DEFINE VARIABLE cCondition AS CHARACTER NO-UNDO.
 IF poScope:Has("_aggregate_program") THEN DO:
  RUN VALUE(poScope:GetCharacter("_aggregate_program"))(pcField,poScope,pdReference,plScoped,OUTPUT pdTotal).
  RETURN.
 END.
 cCondition=PeriodCondition(8,"mes","ano").
 IF plScoped THEN cCondition=cCondition + " AND " + ScopeCondition(8,"cod_repres",FALSE).
 hRows=OpenRows(8,cCondition).
 DO WHILE NOT hRows:QUERY-OFF-END:
  pdTotal=pdTotal + NumValue(8,pcField). hRows:GET-NEXT().
 END.
 RUN CloseRows(hRows).
END PROCEDURE.

PROCEDURE ReadAmount:
 DEFINE INPUT PARAMETER isReturn AS LOGICAL NO-UNDO.
 cName=TextValue(13,"nome-ab-rep").
 FIND FIRST ttIolSale WHERE ttIolSale.repName=cName NO-ERROR.
 IF NOT AVAILABLE ttIolSale THEN DO: CREATE ttIolSale. ttIolSale.repName=cName. END.
 dAmount=IF isReturn THEN NumValue(16,"vl-devol") ELSE NumValue(14,"vl-tot-nota").
 dPercent=NumValue(12,"val-pct-desconto-total").
 IF dPercent=100 THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DISCOUNT_INVALID",1).
 /* Gross-up is part of the shared collection contract, used identically for sales/returns. */
 dDiscount=dAmount * ((100 / (1 - dPercent / 100) - 100) / 100).
 IF isReturn THEN ASSIGN ttIolSale.returnAmount=ttIolSale.returnAmount + dAmount ttIolSale.returnDiscount=ttIolSale.returnDiscount + dDiscount.
 ELSE ASSIGN ttIolSale.saleAmount=ttIolSale.saleAmount + dAmount ttIolSale.saleDiscount=ttIolSale.saleDiscount + dDiscount.
END PROCEDURE.

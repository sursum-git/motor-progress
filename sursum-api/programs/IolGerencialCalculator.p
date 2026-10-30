/* Pure calculator. No DB, HTTP, session, sequence or business writes. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poSnapshot AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResult AS JsonObject NO-UNDO.
DEFINE VARIABLE oMonthly AS JsonObject NO-UNDO.
DEFINE VARIABLE oStore AS JsonObject NO-UNDO.
DEFINE VARIABLE oCalendar AS JsonObject NO-UNDO.
DEFINE VARIABLE oOrders AS JsonObject NO-UNDO.
DEFINE VARIABLE oSeller AS JsonObject NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE aSummary AS JsonArray NO-UNDO.
DEFINE VARIABLE aSellers AS JsonArray NO-UNDO.
DEFINE VARIABLE aOutput AS JsonArray NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE dNet AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dTarget AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dStoreTarget AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDays AS DECIMAL NO-UNDO.
DEFINE VARIABLE dElapsed AS DECIMAL NO-UNDO.
DEFINE VARIABLE dPercent AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE cReference AS CHARACTER NO-UNDO.
DEFINE TEMP-TABLE ttSeller NO-UNDO
 FIELD sellerId AS INTEGER
 FIELD sellerName AS CHARACTER
 FIELD sellerPercent AS DECIMAL DECIMALS 10
 INDEX idxId IS UNIQUE sellerId
 INDEX idxPercent sellerPercent DESCENDING sellerId.

FUNCTION NumberValue RETURNS DECIMAL (o AS JsonObject, c AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 IF NOT o:Has(c) THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 IF o:GetType(c)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 d=o:GetDecimal(c).
 IF d=? THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 RETURN d.
END FUNCTION.
FUNCTION CountValue RETURNS INTEGER (o AS JsonObject, c AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 d=NumberValue(o,c).
 IF d<0 OR d>2147483647 OR d<>TRUNCATE(d,0) THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 RETURN INTEGER(d).
END FUNCTION.

oMonthly=poSnapshot:GetJsonObject("monthly").
oStore=poSnapshot:GetJsonObject("store").
oCalendar=poSnapshot:GetJsonObject("calendar").
oOrders=poSnapshot:GetJsonObject("orders").
cReference=poSnapshot:GetCharacter("reference_date").
IF cReference=? OR LENGTH(cReference)<>10 THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
dDays=NumberValue(oCalendar,"total").
dElapsed=NumberValue(oCalendar,"elapsed").
IF dDays<=0 OR dDays<>TRUNCATE(dDays,0) OR dElapsed<0 OR dElapsed>dDays OR dElapsed<>TRUNCATE(dElapsed,0) THEN
 UNDO, THROW NEW Progress.Lang.AppError("IOL_CALENDAR_INVALID",1).
dNet=ABSOLUTE(NumberValue(oMonthly,"sales")) - ABSOLUTE(NumberValue(oMonthly,"returns")).
dTarget=NumberValue(oMonthly,"target").
dStoreTarget=NumberValue(oStore,"manager_target") / 2.
dPercent=0.
IF dTarget<>0 AND dNet<>0 THEN dPercent=ROUND(dNet / dTarget * 100,2).
oRow=NEW JsonObject().
oRow:Add("id",1).
oRow:Add("competencia",SUBSTRING(cReference,1,7)).
oRow:Add("data_referencia",cReference).
oRow:Add("meta_mensal",dTarget).
oRow:Add("meta_quinzenal",NumberValue(oMonthly,"target_fortnight")).
oRow:Add("faturamento_liquido",dNet).
oRow:Add("percentual_meta",dPercent).
dPercent=0.
IF dStoreTarget<>0 THEN dPercent=ROUND(NumberValue(oStore,"adjusted_sales") / dStoreTarget * 100,0).
oRow:Add("percentual_loja_vendido",dPercent).
dPercent=0.
IF dStoreTarget<>0 THEN dPercent=ROUND(dElapsed / dDays * 100,0).
oRow:Add("percentual_loja_ideal",dPercent).
oRow:Add("dias_uteis_mes",INTEGER(dDays)).
oRow:Add("dias_uteis_passados",INTEGER(dElapsed)).
oRow:Add("dias_uteis_restantes",INTEGER(dDays - dElapsed)).
oRow:Add("pedidos_avaliacao",CountValue(oOrders,"pending")).
oRow:Add("pedidos_abertos",CountValue(oOrders,"open")).
aSummary=NEW JsonArray().
aSummary:Add(oRow).
aSellers=poSnapshot:GetJsonArray("sellers").
DO i=1 TO aSellers:Length:
 oSeller=aSellers:GetJsonObject(i).
 CREATE ttSeller.
 ttSeller.sellerId=CountValue(oSeller,"id").
 IF ttSeller.sellerId=0 THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 ttSeller.sellerName=oSeller:GetCharacter("name").
 IF ttSeller.sellerName=? THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
 dTarget=NumberValue(oSeller,"target").
 dNet=NumberValue(oSeller,"sales") + NumberValue(oSeller,"sales_discount") - NumberValue(oSeller,"returns") - NumberValue(oSeller,"returns_discount").
 ttSeller.sellerPercent=0.
 IF dTarget>0 AND dNet<>0 THEN ttSeller.sellerPercent=ROUND(dNet / dTarget * 100,0).
END.
aOutput=NEW JsonArray().
FOR EACH ttSeller BY ttSeller.sellerPercent DESCENDING BY ttSeller.sellerId:
 oRow=NEW JsonObject().
 oRow:Add("representante_id",ttSeller.sellerId).
 oRow:Add("nome_abreviado",ttSeller.sellerName).
 oRow:Add("percentual_vendido",ttSeller.sellerPercent).
 aOutput:Add(oRow).
END.
poResult=NEW JsonObject().
poResult:Add("resumo",aSummary).
poResult:Add("vendedores",aOutput).

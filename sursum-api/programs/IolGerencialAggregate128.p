/* Compile with OE12.8 only. Static single-table aggregates; no joins or business writes.
   Not deployed as executable on OE12.2. Unknown sums must fail like NumValue(). */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poScope AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pdReference AS DATE NO-UNDO.
DEFINE INPUT PARAMETER plScoped AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pdValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE BUFFER bIolAggregateMeta FOR espec.metas_repres.
DEFINE BUFFER bIolAggregateOrder FOR espec.peds_web.
DEFINE VARIABLE iMonth AS INTEGER NO-UNDO.
DEFINE VARIABLE iYear AS INTEGER NO-UNDO.
DEFINE VARIABLE cRepresentatives AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER NO-UNDO.
DEFINE VARIABLE lGeneral AS LOGICAL NO-UNDO.
DEFINE VARIABLE dUnknown AS DECIMAL NO-UNDO.
IF pdReference=? THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
IF LOOKUP("AGGREGATE",CAPS(REPLACE(DBRESTRICTIONS("espec")," ","")))>0 OR DBRESTRICTIONS("espec")=? THEN
 UNDO, THROW NEW Progress.Lang.AppError("IOL_ENGINE_UNAVAILABLE",1).
ASSIGN iMonth=MONTH(pdReference) iYear=YEAR(pdReference)
 cRepresentatives=poScope:GetCharacter("representatives")
 cNames=poScope:GetCharacter("names") lGeneral=poScope:GetLogical("general").
CASE pcOperation:
 WHEN "vl_meta" THEN DO:
  AGGREGATE dUnknown = COUNT(bIolAggregateMeta.cod_repres) FOR bIolAggregateMeta
   WHERE bIolAggregateMeta.mes=iMonth AND bIolAggregateMeta.ano=iYear
   AND (NOT plScoped OR lGeneral OR LOOKUP(STRING(bIolAggregateMeta.cod_repres),cRepresentatives)>0)
   AND bIolAggregateMeta.vl_meta=?.
  IF dUnknown>0 THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
  AGGREGATE pdValue = TOTAL(bIolAggregateMeta.vl_meta) FOR bIolAggregateMeta
   WHERE bIolAggregateMeta.mes=iMonth AND bIolAggregateMeta.ano=iYear
   AND (NOT plScoped OR lGeneral OR LOOKUP(STRING(bIolAggregateMeta.cod_repres),cRepresentatives)>0).
 END.
 WHEN "vl_meta_quinz" THEN DO:
  AGGREGATE dUnknown = COUNT(bIolAggregateMeta.cod_repres) FOR bIolAggregateMeta
   WHERE bIolAggregateMeta.mes=iMonth AND bIolAggregateMeta.ano=iYear
   AND (NOT plScoped OR lGeneral OR LOOKUP(STRING(bIolAggregateMeta.cod_repres),cRepresentatives)>0)
   AND bIolAggregateMeta.vl_meta_quinz=?.
  IF dUnknown>0 THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
  AGGREGATE pdValue = TOTAL(bIolAggregateMeta.vl_meta_quinz) FOR bIolAggregateMeta
   WHERE bIolAggregateMeta.mes=iMonth AND bIolAggregateMeta.ano=iYear
   AND (NOT plScoped OR lGeneral OR LOOKUP(STRING(bIolAggregateMeta.cod_repres),cRepresentatives)>0).
 END.
 WHEN "pending" THEN DO:
  AGGREGATE pdValue = COUNT(bIolAggregateOrder.login) FOR bIolAggregateOrder
   WHERE bIolAggregateOrder.ind_sit_ped_web=8
   AND (lGeneral OR LOOKUP(bIolAggregateOrder.login,cNames)>0).
 END.
 OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("IOL_ENGINE_INVALID",1).
END CASE.
IF pdValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_DATA_INVALID",1).
/* Normalize the empty-set zero, including releases which represent it as -0. */
IF pdValue=0 THEN pdValue=0.

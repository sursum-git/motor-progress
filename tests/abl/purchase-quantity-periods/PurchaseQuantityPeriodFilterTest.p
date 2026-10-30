BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError('Filter assertion ' + STRING(checks + 1),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE CallFilter:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expected AS LOGICAL NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 RUN VALUE(pathValue)(requestValue,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical('success')=expected).
 IF NOT expected THEN RUN Check(resultValue:GetJsonObject('error'):GetInteger('status')=422).
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER. SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO VALUE('quantity-period-filter-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO,THROW NEW Progress.Lang.AppError('No DB allowed',1).
 pathValue=SEARCH('sursum-api/programs/PurchaseQuantityPeriodFilter.r').
 IF pathValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('RED missing period filter',1).
 parser=NEW ObjectModelParser().
 RUN CallFilter('~{"operation":"read","take":20,"skip":200~}',TRUE).
 RUN Check(NOT resultValue:GetJsonObject('request'):Has('filter')).
 RUN CallFilter('~{"operation":"read","filter":~{"logic":"and","filters":[~{"field":"dt_prev_chegada","operator":"gte","value":"2026-11-01"~},~{"field":"dt_prev_chegada","operator":"lte","value":"2026-11-30"~},~{"field":"codigo_erp","operator":"eq","value":"A"~}]~}~}',TRUE).
 RUN Check(resultValue:GetJsonObject('periods'):GetJsonObject('dt_prev_chegada'):GetCharacter('start')='2026-11-01').
 RUN Check(resultValue:GetJsonObject('request'):GetJsonObject('filter'):GetCharacter('field')='codigo_erp').
 RUN CallFilter('~{"operation":"read","filter":~{"field":"dt_registro","operator":"eq","value":"2026-10-01"~}~}',TRUE).
 RUN Check(resultValue:GetJsonObject('periods'):GetJsonObject('dt_registro'):GetCharacter('end')='2026-10-01').
 RUN Check(NOT resultValue:GetJsonObject('request'):Has('filter')).
 RUN CallFilter('~{"operation":"read","filter":~{"logic":"or","filters":[~{"field":"dt_registro","operator":"eq","value":"2026-10-01"~},~{"field":"codigo_erp","operator":"eq","value":"A"~}]~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"field":"dt_registro","operator":"gte","value":"2026-10-01"~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"field":"dt_registro","operator":"eq","value":"2026-02-29"~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"field":"dt_registro","operator":"contains","value":"2026-10-01"~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"logic":"and","filters":[~{"field":"dt_registro","operator":"gte","value":"2026-10-10"~},~{"field":"dt_registro","operator":"lte","value":"2026-10-01"~}]~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"logic":"and","filters":[~{"field":"dt_registro","operator":"eq","value":"2026-10-01"~},~{"field":"dt_registro","operator":"eq","value":"2026-10-02"~}]~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"field":"DT_REGISTRO","operator":"eq","value":"2026-10-02"~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"field":"dt_registro","operator":"EQ","value":"2026-10-02"~}~}',FALSE).
 RUN CallFilter('~{"operation":"read","filter":~{"logic":"AND","filters":[~{"field":"dt_registro","operator":"eq","value":"2026-10-02"~}]~}~}',FALSE).
 RUN Check(NUM-DBS=0 AND SESSION:NUMERIC-FORMAT=culture).
 PUT UNFORMATTED 'PASS period filter checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END. OUTPUT CLOSE. QUIT.

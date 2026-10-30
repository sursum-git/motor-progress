BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE periods AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError('Period assertion failed at ' + STRING(checks + 1),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE MakeNull:
 DEFINE INPUT PARAMETER fieldName AS CHARACTER NO-UNDO.
 IF rowValue:Has(fieldName) THEN rowValue:Remove(fieldName).
 rowValue:AddNull(fieldName).
END PROCEDURE.
PROCEDURE Evaluate:
 DEFINE INPUT PARAMETER expected AS LOGICAL NO-UNDO.
 RUN VALUE(pathValue)(rowValue,periods,60,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical('admitted')=expected).
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER.
SESSION:NUMERIC-FORMAT=culture. OUTPUT TO VALUE('quantity-period-rules-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO,THROW NEW Progress.Lang.AppError('No DB allowed',1).
 pathValue=SEARCH('sursum-api/programs/PurchaseQuantityPeriodRules.r').
 IF pathValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('RED missing period rules',1).
 parser=NEW ObjectModelParser().
 rowValue=CAST(parser:Parse('~{"dt_registro":"2026-10-01","dt_recebimento":null,"dt_prev_chegada":null,"dt_termino_producao":"2026-10-15","dt_prev_termino_producao":null,"dt_maxima_producao":"2026-10-20"~}'),JsonObject).
 periods=NEW JsonObject(). RUN Evaluate(TRUE).
 RUN Check(resultValue:GetCharacter('dt_prev_chegada')='2026-11-19').
 periods=CAST(parser:Parse('~{"dt_prev_chegada":~{"start":"2026-11-01","end":"2026-11-30"~}~}'),JsonObject).
 /* Authorised legacy asymmetry: arrival14Dec still passes November. */
 RUN Evaluate(TRUE).
 rowValue:Set('dt_termino_producao','2026-12-01'). RUN Evaluate(FALSE).
 rowValue:Set('dt_prev_termino_producao','2026-10-15'). RUN Evaluate(TRUE).
 RUN MakeNull('dt_termino_producao'). RUN Evaluate(TRUE).
 RUN MakeNull('dt_prev_termino_producao'). RUN Evaluate(FALSE).
 rowValue:Set('dt_prev_chegada','2026-11-01'). RUN Evaluate(TRUE).
 RUN Check(resultValue:GetCharacter('dt_prev_chegada')='2026-11-01').
 rowValue:Set('dt_prev_chegada','2026-11-30'). RUN Evaluate(TRUE).
 rowValue:Set('dt_prev_chegada','2026-12-01'). RUN Evaluate(FALSE).
 periods=CAST(parser:Parse('~{"dt_recebimento":~{"start":"2026-10-10","end":"2026-10-20"~}~}'),JsonObject).
 rowValue:Set('dt_termino_producao','2026-10-15'). RUN Evaluate(FALSE).
 rowValue:Set('dt_recebimento','2026-10-10'). RUN Evaluate(TRUE).
 rowValue:Set('dt_recebimento','2026-10-20'). RUN Evaluate(TRUE).
 rowValue:Set('dt_recebimento','2026-10-21'). RUN Evaluate(FALSE).
 periods=CAST(parser:Parse('~{"dt_registro":~{"start":"2026-10-01","end":"2026-10-01"~}~}'),JsonObject). RUN Evaluate(TRUE).
 rowValue:Set('dt_registro','2026-10-02'). RUN Evaluate(FALSE).
 RUN MakeNull('dt_registro'). RUN Evaluate(FALSE).
 periods=NEW JsonObject(). RUN MakeNull('dt_maxima_producao'). RUN MakeNull('dt_prev_chegada'). RUN Evaluate(TRUE).
 RUN Check(resultValue:IsNull('dt_prev_chegada')).
 RUN Check(NUM-DBS=0 AND SESSION:NUMERIC-FORMAT=culture).
 PUT UNFORMATTED 'PASS period rules checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END. OUTPUT CLOSE. QUIT.

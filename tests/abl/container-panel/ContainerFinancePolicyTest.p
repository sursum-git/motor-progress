BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttParam NO-UNDO FIELD cod-param AS CHARACTER FIELD val-param AS CHARACTER INDEX pk IS PRIMARY UNIQUE cod-param.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesList AS JsonArray NO-UNDO.
DEFINE VARIABLE invalids AS CHARACTER EXTENT 4 NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA ttParam
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerFinancePolicy.i}
OUTPUT TO VALUE("container-finance-policy-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 policy=ContainerFinancePolicy().
 RUN Check(policy:GetJsonArray("adiantamentos"):GetCharacter(1)="AF","AF default").
 RUN Check(policy:GetJsonArray("titulos"):GetCharacter(1)="DI","DI default").
 CREATE ttParam. ASSIGN ttParam.cod-param="especs_adiant_importacao" ttParam.val-param="'AF', 'AP'".
 policy=ContainerFinancePolicy().
 RUN Check(policy:GetJsonArray("adiantamentos"):Length=2,"list parsed").
 RUN Check(policy:GetJsonArray("adiantamentos"):GetCharacter(2)="AP","SQL quoted token as data").
 ttParam.val-param="AT".
 policy=ContainerFinancePolicy().
 RUN Check(policy:GetJsonArray("adiantamentos"):GetCharacter(1)="AT","no session cache").
 ttParam.val-param="".
 policy=ContainerFinancePolicy().
 RUN Check(policy:GetJsonArray("adiantamentos"):GetCharacter(1)="AF","empty fallback").
 ASSIGN invalids[1]="AF,,AP" invalids[2]="'AF');DELETE" invalids[3]="AF OR 1" invalids[4]="abcdefghijklmnop".
 DO n=1 TO 4:
  rejected=FALSE.
  DO ON ERROR UNDO, THROW:
   valuesList=ContainerSpecies(invalids[n],"'AF'").
   CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH.
  END.
  RUN Check(rejected,"invalid tokens rejected").
 END.
 PUT UNFORMATTED "PASS: " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
 CATCH err AS Progress.Lang.Error: PUT UNFORMATTED "FAIL: " err:GetMessage(1) SKIP. UNDO, THROW err. END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER plValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF plValue<>TRUE OR plValue=? THEN UNDO, THROW NEW Progress.Lang.AppError(messageText,0).
 checks = checks + 1.
END PROCEDURE.

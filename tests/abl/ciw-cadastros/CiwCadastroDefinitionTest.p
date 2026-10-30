BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE resourceList AS CHARACTER NO-UNDO INITIAL "coloracoes,situacoes_container,tipos_versao_custo,motivos_desconto,formatos_amostra".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
OUTPUT TO VALUE("ciw-cadastro-definition-" + SESSION:CPINTERNAL + ".log").
DO ON ERROR UNDO, THROW:
 DO n = 1 TO NUM-ENTRIES(resourceList):
  RUN CiwCadastroDefinition.p(INPUT ENTRY(n,resourceList),OUTPUT policy).
  IF NOT VALID-OBJECT(policy) OR policy:GetCharacter("resource")<>ENTRY(n,resourceList) THEN UNDO,THROW NEW Progress.Lang.AppError("Definicao incorreta",0).
  checks = checks + 1.
  IF policy:GetJsonArray("fields"):Length<1 THEN UNDO,THROW NEW Progress.Lang.AppError("Campos ausentes",0).
  checks = checks + 1.
  DELETE OBJECT policy.
 END.
 PUT UNFORMATTED "PASS " checks " checks " SESSION:CPINTERNAL SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
QUIT.

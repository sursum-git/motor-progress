/* Smoke de buffers DB: SOMENTE LEITURA. Requer espec conectado pelo runner.
   Nao autentica HTTP nem publica. Nao imprime registros ou configuracoes. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE h AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL "despesas,empresas_despesa,empresas,relacs_desp_calculada,despesas_impostos,despesas_proc_compra,despesas_container,item_container_custo_despesas".
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE r AS CHARACTER NO-UNDO.
DEFINE VARIABLE o AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE passed AS INTEGER NO-UNDO.
OUTPUT TO "despesas-db-read-tests.log".
PUT UNFORMATTED "OpenEdge " PROVERSION " FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco espec nao conectado",0).
 DO i = 1 TO 8:
  CREATE BUFFER h[i] FOR TABLE ("espec." + ENTRY(i,tables)) BUFFER-NAME ("bDespDbTest" + TRIM(STRING(i))).
 END.
 DO k = 1 TO 6:
  ASSIGN r = IF k = 2 THEN "empresas_despesa" ELSE "despesas"
   o = ENTRY(k,"read,read,opcoes_despesas,opcoes_impostos,opcoes_empresas,opcoes_custo").
  req = NEW JsonObject(). req:Add("resource",r). req:Add("operation",o).
  RUN DespesasCrudService.p (INPUT h[1], INPUT h[2], INPUT h[3], INPUT h[4], INPUT h[5], INPUT h[6], INPUT h[7], INPUT h[8], INPUT req, OUTPUT res).
  IF NOT res:GetLogical("success") THEN DO:
   PUT UNFORMATTED "FAIL: " r "." o " " res:GetJsonObject("error"):GetCharacter("code") SKIP.
   UNDO, THROW NEW Progress.Lang.AppError("Consulta DB recusada",0).
  END.
  IF res:GetType("data") <> JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Contrato de lista invalido",0).
  passed = passed + 1.
  PUT UNFORMATTED "OK: " r "." o " rows=" res:GetJsonArray("data"):Length SKIP.
  DELETE OBJECT req. DELETE OBJECT res.
 END.
 PUT UNFORMATTED "PASS: " passed " consultas DB somente leitura" SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
 END CATCH.
 FINALLY:
  DO i = 1 TO 8: IF VALID-HANDLE(h[i]) THEN DELETE OBJECT h[i] NO-ERROR. END.
  IF VALID-OBJECT(req) THEN DELETE OBJECT req.
  IF VALID-OBJECT(res) THEN DELETE OBJECT res.
 END FINALLY.
END.
OUTPUT CLOSE.
QUIT.

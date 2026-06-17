DEFINE VARIABLE h         AS HANDLE      NO-UNDO.
DEFINE VARIABLE cLinha  AS CHARACTER   NO-UNDO FORMAT 'x(200)'.
DEFINE VARIABLE cTb01  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTb02  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cArq    AS CHARACTER   NO-UNDO.
{esbo/boMetadados.i}    
ASSIGN cArq = 'c:\temp\relacoes_tabelas_der_03.csv'.
RUN esbo/boMetadados.p PERSIST SET h.
RUN getChaveEstrangCsv IN h(INPUT cArq).
RUN extrairTbsTTRelacs IN h.
RUN getTTtbsRelacs IN h(OUTPUT TABLE ttTbsRelac).
RUN setTabelasDireto IN h(INPUT TABLE ttTbsRelac).
RUN getDadosTbsDireto IN h .
RUN gerarDDlSqlite IN h('c:\temp\datasul.sql', NO).

IF VALID-HANDLE(h) THEN
   DELETE PROCEDURE h.

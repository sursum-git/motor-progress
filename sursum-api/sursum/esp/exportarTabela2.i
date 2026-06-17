//para utilizar dentro de procedures. n∆o pode ter a definiá∆o de temp-table que a exportarTabela.i tem
DEFINE VARIABLE cCampos{1} AS CHARACTER   NO-UNDO.

OUTPUT TO value('c:\temp\{4}') {6}.

RUN getCpsTT(TEMP-TABLE {1}:HANDLE,'{5}', OUTPUT cCampos{1}).
PUT UNFORM cCampos{1} SKIP.
FOR EACH {1} {2} NO-LOCK:
    EXPORT DELIMITER '{5}' {1} {3}.
END.

OUTPUT CLOSE.


/*

parametros:
1- nome da tabela ou tabela temporaria
2- condiá∆o com o where
3- campos except(se n∆o quiser colocar aspas)
4- nome do arquivo
5-delimitador
6-convert 
*/

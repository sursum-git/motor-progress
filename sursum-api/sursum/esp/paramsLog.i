/*************************************************************************************
Programa:{esp/paramsLog.i}
Objetivo: Consulta de parametros de Log's
Autor: Tadeu Silva Parreiras
Data: 05/2024
***************************************************************************************/

FUNCTION getLogPrograma RETURNS LOGICAL(cPrograma AS CHAR):

   DEFINE VARIABLE hBoConsParam AS HANDLE      NO-UNDO.
   DEFINE VARIABLE cValor       AS CHARACTER   NO-UNDO.

   RUN esbo/boConsParam.p PERSIST SET hBoConsParam.

   RUN setCodParam IN hBoConsParam('gerar_log_' + cPrograma).
   RUN getVlParam2 IN hBoConsParam('0',OUTPUT cValor).
   
   IF VALID-HANDLE(hBoConsParam) THEN
      DELETE PROCEDURE hBoConsParam.

   RETURN cvalor = '1'.



   

END FUNCTION.



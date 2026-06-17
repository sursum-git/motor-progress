DEFINE INPUT  PARAMETER  clsErros   AS Progress.Lang.SysError   NO-UNDO.
DEFINE OUTPUT PARAMETER nomeArquivo AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iQT AS INTEGER     NO-UNDO.

{utp/ut-glob.i}
ASSIGN nomeArquivo = c-seg-usuario + '_log_error_' + PROGRAM-NAME(2)                   
                    + STRING(TIME) + ".txt".

OUTPUT TO VALUE('p:\erros\' + nomeArquivo).

  REPEAT iQt = 1 TO clsErros:NumMessages :
    PUT UNFORMAT  clsErros:GetMessage(iQt) SKIP.  
  END.
  
OUTPUT CLOSE.
                    





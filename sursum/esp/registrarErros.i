{esp/usuario_corrente.i}

DEFINE VARIABLE cNomeArquivo AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iQT          AS INTEGER     NO-UNDO.
DEFINE VARIABLE cprogs       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iMsg        AS INTEGER     NO-UNDO.


/* IF ERROR-STATUS:ERROR THEN  DO:                                                            */
/*    ASSIGN cNomeArquivo = c-seg-usuario + '_log_error_status_' +  STRING(TIME) + ".txt".    */
/*    OUTPUT TO VALUE('P:\erros\' + cNomeArquivo).                                            */
/*    DO iMsg = 1 TO ERROR-STATUS:NUM-MESSAGES:                                               */
/*      PUT UNFORMAT  ERROR-STATUS:GET-NUMBER(iMsg) "-"  ERROR-STATUS:GET-MESSAGE(iMsg) SKIP. */
/*    END.                                                                                    */
/*    OUTPUT CLOSE.                                                                           */
/*                                                                                            */
/* END.                                                                                       */



CATCH clsErros AS Progress.Lang.SysError:
    RUN getNomesProgsCor(OUTPUT cProgs).
    ASSIGN cNomeArquivo = c-seg-usuario + '_log_error_sysError_' +  STRING(TIME) + ".txt".
    OUTPUT TO VALUE('P:\erros\' + cNomeArquivo).
      PUT UNFORM cProgs SKIP.
      REPEAT iQt = 1 TO clsErros:NumMessages :
        PUT UNFORMAT  clsErros:GetMessage(iQt) "->" clsErros:callStack SKIP.  
      END.      
    OUTPUT CLOSE.
    MESSAGE 'Ops...' SKIP
            'Ocorreu um erro. Favor informar ao TI ao Arquivo abaixo:'  SKIP
            cNomeArquivo
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        
 
        
END CATCH. 

CATCH clsErros2 AS Progress.Lang.AppError:
    RUN getNomesProgsCor(OUTPUT cProgs).
    ASSIGN cNomeArquivo = c-seg-usuario + '_log_error_AppError_' +  STRING(TIME) + ".txt".
    OUTPUT TO VALUE('P:\erros\' + cNomeArquivo).
      PUT UNFORM cProgs SKIP.
      REPEAT iQt = 1 TO clsErros2:NumMessages :
        PUT UNFORMAT  clsErros2:GetMessage(iQt) "->" clsErros2:callStack SKIP.  
      END.      
    OUTPUT CLOSE.
    MESSAGE 'Ops...' SKIP
            'Ocorreu um erro. Favor informar ao TI ao Arquivo abaixo:'  SKIP
            cNomeArquivo
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        
 
        
END CATCH. 

                    
                    



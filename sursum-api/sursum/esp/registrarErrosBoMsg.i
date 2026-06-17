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
    REPEAT iQt = 1 TO clsErros:NumMessages :
       RUN setMsg IN hBoMsg(999, clsErros:GetMessage(iQt) 
        + "->" + clsErros:callStack ,'erro').  
    END.      
    RUN setTransacaoLogCalculo IN hBoMsg(idTrans).
    RUN gravarLogCalculo       IN hBoMsg(idCalculo).                        
    RUN finalizarTransacao     IN hBoTrans(2).
    
 
        
END CATCH. 

CATCH clsErros2 AS Progress.Lang.AppError:
    
      REPEAT iQt = 1 TO clsErros2:NumMessages :
           RUN setMsg IN hBoMsg(999, clsErros:GetMessage(iQt) 
        + "->" + clsErros:callStack ,'erro').   
      END.      
      RUN setTransacaoLogCalculo IN hBoMsg(idTrans).
      RUN gravarLogCalculo       IN hBoMsg(idCalculo).                        
      RUN finalizarTransacao     IN hBoTrans(2).
        
 
        
END CATCH. 

                    
                    



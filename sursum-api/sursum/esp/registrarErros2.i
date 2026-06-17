{esp/usuario_corrente.i}




IF ERROR-STATUS:ERROR THEN  DO:
   ASSIGN cNomeArquivo2 = c-seg-usuario + '_log_error_status_' +  STRING(TIME) + ".txt".
   RUN getNomesProgsCor(OUTPUT cProgs2).
   OUTPUT TO VALUE('P:\erros\' + cNomeArquivo2).
   
   DO iMsg = 1 TO ERROR-STATUS:NUM-MESSAGES:
     PUT UNFORMAT  ERROR-STATUS:GET-NUMBER(iMsg) "-"  ERROR-STATUS:GET-MESSAGE(iMsg) SKIP.
   END.
   OUTPUT CLOSE.
END.





                    
                    



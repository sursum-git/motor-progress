DEFINE VARIABLE cErro AS CHARACTER   NO-UNDO.     
CATCH sistError AS Progress.Lang.SysError:    

     ASSIGN cErro = sistError:getMessage(1).
     MESSAGE cErro
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
END CATCH.

CATCH appError AS Progress.Lang.AppError:    
    
    ASSIGN cErro = appError:getMessage(1).
    MESSAGE cErro
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
END CATCH.

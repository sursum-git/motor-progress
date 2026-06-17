 DEFINE VARIABLE cErro AS CHARACTER   NO-UNDO.
CATCH sistError AS Progress.Lang.SysError:    

     IF NOT VALID-OBJECT(jsonOutput) THEN DO:
        jsonOutput = NEW jsonobject(). 
     END.
     ASSIGN cErro = sistError:getMessage(1).
     jsonOutput:ADD('Erro',cErro).
END CATCH.


CATCH appError AS Progress.Lang.AppError:    
    IF NOT VALID-OBJECT(jsonOutput) THEN DO:
        jsonOutput = NEW jsonobject(). 
     END.
     ASSIGN cErro = appError:getMessage(1).
     jsonOutput:ADD('Erro',cErro).   
END CATCH.

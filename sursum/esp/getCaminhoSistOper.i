FUNCTION getCaminhoSistOper RETURNS CHAR(caminho AS CHAR):

    IF OPSYS <> 'UNIX' THEN
    DO:
        RETURN REPLACE(caminho,"/","\").        
    END.
    ELSE DO:
        RETURN REPLACE(caminho,"\","/").        
    END.



END FUNCTION.

 
/*------------------------------------------------------------------------
   File        : LerArquivoChaveValor
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Mon Apr 21 10:53:44 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Arquivo.ILerArquivoChaveValor.
USING Arquivo.EDelimitador FROM PROPATH.
USING Comum.UtilTexto FROM PROPATH.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Arquivo.LerArquivoConfig IMPLEMENTS ILerArquivoChaveValor: 
    
    {comum/ttConfig.i} 
    DEFINE TEMP-TABLE ttConfigAux LIKE ttConfig.

    DEFINE PUBLIC PROPERTY arquivo AS Arquivo.IArquivo NO-UNDO 
        GET.
        SET. 

    DEFINE PUBLIC PROPERTY separador AS CHARACTER NO-UNDO 
        GET.
        SET. 

    DEFINE PUBLIC PROPERTY identificadorSessao AS CHARACTER NO-UNDO 
        GET.
        SET.   
           
    METHOD PUBLIC VOID ler(  ):
        DEFINE VARIABLE cLinha         AS CHARACTER NO-UNDO.
        DEFINE VARIABLE sessaoCorrente AS CHARACTER NO-UNDO.
        
        THIS-OBJECT:identificadorSessao = UtilTexto:atribuirSeVazio(identificadorSessao, '[').
          
        INPUT from value(arquivo:nomeArquivo).
        REPEAT:
            IF substr(cLinha,1,1) = substr(THIS-OBJECT:identificadorSessao,1,1) THEN 
            DO:
                ASSIGN 
                    sessaoCorrente = cLinha
                    sessaoCorrente = REPLACE(sessaoCorrente,substr(THIS-OBJECT:identificadorSessao,1,1),"")
                    sessaoCorrente = REPLACE(sessaoCorrente,substr(THIS-OBJECT:identificadorSessao,2,1),"")
                    .
            END.
            
            CREATE ttConfig.
            IMPORT UNFORMATTED cLinha.            
            IF NUM-ENTRIES(cLinha,separador) = 2 THEN
                ASSIGN ttConfig.chave  = ENTRY(1,cLinha,separador)
                    ttConfig.valor  = ENTRY(2,cLinha,separador) 
                    ttConfig.sessao = sessaoCorrente 
                    .           
        END.
        
        
        INPUT close.
        
        RETURN.

    END METHOD.
    
    METHOD PUBLIC CHARACTER getVlSessaoChave ( pSessao AS CHARACTER, pChave AS CHARACTER ):
            
        DEFINE VARIABLE cRetorno AS CHARACTER NO-UNDO.
          
        FIND LAST ttConfig 
            WHERE ttConfig.sessao = pSessao
            AND   ttConfig.chave  = pChave  NO-ERROR.
        IF AVAILABLE ttConfig THEN
            ASSIGN cRetorno = ttConfig.valor.
             
             
        
    END METHOD. 
    
    
    METHOD PUBLIC VOID  getTtSessaoChave ( pSessao AS CHARACTER ,OUTPUT table ttConfigAux ):
            
        DEFINE VARIABLE cRetorno AS CHARACTER NO-UNDO.
        EMPTY TEMP-TABLE ttConfigAux.          
        FOR EACH ttConfig 
            WHERE ttConfig.sessao = pSessao .            
            CREATE ttConfigAux.
            BUFFER-COPY ttConfig TO ttConfigAux.            
                    
        END.
             
             
        
    END METHOD.    

    {comum/retTT.i ttConfig}    

END CLASS.
 
 /*------------------------------------------------------------------------
    File        : GerarAcompanhamento
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : tadeu.parreiras
    Created     : Wed May 28 20:10:42 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Comum.GerarAcompanhamento FROM PROPATH.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Comum.GerarAcompanhamento: 
    
    
   

    DEFINE PUBLIC STATIC PROPERTY hAcomp AS HANDLE NO-UNDO 
    GET.
    SET. 

    
    METHOD PUBLIC STATIC VOID inicializar( pTitulo AS CHAR ):
        
        RUN utp/ut-acomp.p PERSIST SET hAcomp .
        RUN pi-inicializar IN GerarAcompanhamento:hAcomp(pTitulo).
        RETURN.

    END METHOD.   
    
    
    METHOD PUBLIC STATIC VOID acompanhar( pTexto AS CHAR ):
        
        RUN utp/ut-acomp.p PERSIST SET hAcomp.
        RUN pi-acompanhar IN GerarAcompanhamento:hAcomp(pTexto).
        RETURN.

    END METHOD.  
    
    
     METHOD PUBLIC STATIC VOID finalizar():
        
        RUN utp/ut-acomp.p PERSIST SET hAcomp.
        RUN pi-finalizar IN GerarAcompanhamento:hAcomp.
        RETURN.

    END METHOD.    
    
    
    

END CLASS.
 
/*------------------------------------------------------------------------
   File        : RegistrarErro
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : tadeu.parreiras
   Created     : Wed May 28 18:33:39 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Comum.RegistrarErro: 
    
    
    {comum/RegistrarErro.i static}    

    METHOD PUBLIC STATIC VOID incluirErro( pCoderro AS INTEGER,pDescErro AS CHARACTER ):
        
        CREATE ttErros.
        ASSIGN 
            ttErros.coderro  = pCodErro
            ttErros.descErro = pDescErro
            ttErros.dthr     = NOW.
        
        RETURN.

    END METHOD.

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC STATIC VOID limparErros(  ):
        EMPTY TEMP-TABLE ttErros.
        RETURN.

    END METHOD.    

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC STATIC VOID getTTErros( OUTPUT table ttErros  ):
        
        RETURN.

    END METHOD.  
    
    
    METHOD PUBLIC STATIC CHARACTER getTextoErro( ):
        DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
        FOR EACH ttErros:
            cErro = Comum.UtilTexto:incrValor(cErro, STRING(tterros.codErro) + '-' + tterros.descErro, 
                "|", FALSE).
            
        END.
        RETURN cErro.

    END METHOD.    
    
    

END CLASS.
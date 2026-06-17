 
/*------------------------------------------------------------------------
   File        : UtilTexto
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Tue Apr 15 20:48:38 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Comum.UtilTexto: 
    
    
    

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC STATIC LONGCHAR incrValor( INPUT texto AS LONGCHAR, INPUT termo AS CHARACTER,INPUT separador AS CHARACTER, INPUT logConsideraTermoBanco AS LOGICAL):
        
        IF texto <> '' THEN
            ASSIGN texto = texto + separador + termo.
        ELSE 
        DO:
            IF NOT logConsideraTermoBanco AND termo = '' THEN RETURN texto.
                            
            ASSIGN  
                texto = texto + separador + termo.
        END.
            
        
        RETURN texto.

    END METHOD.
    
    METHOD PUBLIC STATIC VOID convLongChar2Arq(pLc AS LONGCHAR, pArquivo AS CHARACTER ):
        
        COPY-LOB plc TO FILE pArquivo.
        
        
    END METHOD.
    
    METHOD PUBLIC STATIC VOID convArq2LongChar(pArquivo AS CHARACTER,pLc AS LONGCHAR ):
        
        COPY-LOB FILE pArquivo TO plc .
        
        
    END METHOD.
    
    METHOD PUBLIC STATIC CHARACTER atribuirSeVazio(texto AS CHARACTER, valor AS CHARACTER ):
        
        IF texto = '' THEN
            ASSIGN texto = valor.    
               
        RETURN texto.     
        
            
        
    END METHOD.
    
        

END CLASS.
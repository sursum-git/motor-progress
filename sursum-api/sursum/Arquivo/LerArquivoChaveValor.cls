 
/*------------------------------------------------------------------------
   File        : LerArquivoChaveValor
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Mon Apr 21 10:53:44 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.ILerArquivoChaveValor.
USING Arquivo.EDelimitador FROM PROPATH.

routine-level on error undo, throw.

class Arquivo.LerArquivoChaveValor implements ILerArquivoChaveValor: 
    
    {comum/ttChaveValor.i} 

    define public property arquivo as Arquivo.IArquivo no-undo 
        get.
        set. 

    define public property separador as char no-undo 
        get.
        set. 

    method public void ler(  ):
        DEFINE VARIABLE cLinha AS CHARACTER NO-UNDO.
        DEFINE VARIABLE sessao AS CHARACTER NO-UNDO.
        input from value(arquivo:nomeArquivo).
        repeat:
            
            create ttChaveValor.
            import unform cLinha.
            if num-entries(cLinha,separador) = 2 then
                assign ttChaveValor.chave = entry(1,cLinha,separador)
                       ttChaveValor.valor = entry(2,cLinha,separador) 
                  .                    
            
        end.
        
        
        input close.
        
        return.

    end method.

    {comum/retTT.i ttChaveValor}    

end class.

/*------------------------------------------------------------------------
    File        : ILerArquivoChaveValor
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Mon Apr 21 10:48:05 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.ILerArquivo.

interface Arquivo.ILerArquivoChaveValor inherits ILerArquivo:  
    
   //{comum/ttChaveValor.i} 
    
    define public property separador as character no-undo 
        get.
        set.   

   
        
    //{comum/IretTT.i ttChaveValor}    
        
  
end interface.
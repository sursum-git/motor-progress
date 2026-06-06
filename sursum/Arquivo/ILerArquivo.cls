
/*------------------------------------------------------------------------
    File        : LerArquivo
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 14:14:26 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.IArquivo.

interface Arquivo.ILerArquivo : 
         
    
   
    define public property arquivo as Arquivo.IArquivo no-undo 
    get.
    set. 

    method public void ler(  ).

    
    
      
    
    

end interface.
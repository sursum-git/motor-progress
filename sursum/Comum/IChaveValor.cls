
/*------------------------------------------------------------------------
    File        : IChaveValor
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 10:21:40 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

interface Comum.IChaveValor:  
    
    define public property ordem as int no-undo 
    get.
    set. 

    define public property valor as character no-undo 
    get.
    set. 

    define public property chave as character no-undo 
    get.
    set. 
  
end interface.
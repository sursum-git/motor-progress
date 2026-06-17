 
 /*------------------------------------------------------------------------
    File        : NivelLog
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : administrator
    Created     : Mon Apr 14 10:56:00 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

routine-level on error undo, throw.

class Log.NivelLog:
   
    
    

    define public property nome             as character no-undo 
    get.
    set. 

    define public property posicaoInicial   as int no-undo 
    get.
    set. 

    define public property posicaoFinal     as int no-undo 
    get.
    set. 

    define public property mascara          as character no-undo 
    get.
    set.     
    
    

end class.
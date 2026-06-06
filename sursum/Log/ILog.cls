
/*------------------------------------------------------------------------
    File        : ILog
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : administrator
    Created     : Thu Apr 10 14:51:28 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Log.ETipoLog from propath.
using Log.EMidiaLog from propath.

interface Log.ILog:    
    
    {Log/ILog.i} 
    
    //quando não é gravacao instantanea, será necessario chamar o metodo de gravacao
    define public property gravacaoInstantanea as logical no-undo 
    get.
    set. 

    define public property idLog as int64 no-undo 
    get.
    set.  
  
    define public property descricao as character no-undo 
    get.
    set.     

    define public property numTipoLog as Log.ETipoLog no-undo 
    get.
    set. 

    define public property dtHr as datetime no-undo 
    get.
    set.   
    
    
    //retorna a data e a hora que gravou o log
    method public datetime gravarLog(  ).    

    /*------------------------------------------------------------------------------
     Purpose: Adiciona na temp-table a relação entre o tipo do log e a midia de 
     log que deve ser utilizada
     Notes:
    ------------------------------------------------------------------------------*/

   
    
        
    
end interface.
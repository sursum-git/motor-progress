
/*------------------------------------------------------------------------
    File        : IColecaoLog
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : administrator
    Created     : Thu Apr 10 15:01:32 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using log.*.

interface Log.IColecaoLog inherits ILog,IColecao:  
    
    {Log/IColecaoLog.i}
   

    method public int incluirLog(input tipo as int, input descricao as char, dtHr as datetime  ).
    
    method public integer incluirLog(input aLog as Log.ILog  ).

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public void _criarLogTT(). 
       
    method public void retTTLog(output table ttLog).
    

end interface.
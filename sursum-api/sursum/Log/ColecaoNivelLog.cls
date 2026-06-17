 
 /*------------------------------------------------------------------------
    File        : ColecaoNivelLog
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : administrator
    Created     : Mon Apr 14 13:26:25 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using log.*.

routine-level on error undo, throw.

class Log.ColecaoNivelLog implements IColecao: 
    
   {log/ColecaoNivelLog.i}
   
   
    define variable oNivelLog as NivelLog.
    define public property obj as Object no-undo 
    get.
    set. 

    method public void _criarLogTT( ):
        
        oNivelLog = cast(obj,NivelLog).
        
        create ttNivelLog.     
        assign ttNivelLog.nome              = oNivelLog:nome
               ttNivelLog.posicaoInicial    = oNivelLog:posicaoInicial
               ttNivelLog.posicaoFinal      = oNivelLog:posicaoFinal
               ttNivelLog.mascara           = oNivelLog:mascara                
               .
          
        return.

    end method.

    {retTT.i ttNivelLog}

end class.
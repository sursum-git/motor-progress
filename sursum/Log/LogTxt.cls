 
 /*------------------------------------------------------------------------
    File        : LogTxt
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : administrator
    Created     : Thu Apr 10 18:03:28 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using log.*.
/*using Log.ETipoLog from propath.
using Log.EMidiaLog from propath.
using Log.EFormaRegistroLog from propath.*/

routine-level on error undo, throw.

class Log.LogTxt implements ILog: 
    
    
    

    define public property descricao as character no-undo 
    get.
    set. 

    define public property dtHr as datetime no-undo 
    get.
    set. 

     

    define public property gravacaoInstantanea as logical no-undo 
    get.
    set. 

    define public property idLog as int64 no-undo 
    get.
    set.
    

    define public property numTipoLog as Log.ETipoLog no-undo 
    get.
    set. 

    define public property prefixoArquivo as character no-undo 
    get.
    set. 
    
    define public property extensaoArquivoLog as character no-undo 
    get.
    set.
    
    define public property diretorioArquivoLog as character no-undo 
    get.
    set.
    
    define public property numCicloArquivoLog as int64 no-undo 
    get.
    set.
    
    define public property numMedidaTempoCicloArquivoLog as EMedidaTempo no-undo 
    get.
    set. 

    define public property numFormaRegistroLog as EFormaRegistroLog no-undo 
    get.
    set. 
    
    method public datetime gravarLog(  ):
        
        //todo
        

    end method.    

   
     

end class.
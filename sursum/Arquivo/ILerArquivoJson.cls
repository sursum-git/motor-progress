
/*------------------------------------------------------------------------
    File        : LerArquivoJson
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 14:31:18 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

interface Arquivo.ILerArquivoJson inherits Arquivo.LerArquivo:  
    
    /*------------------------------------------------------------------------------
     Purpose: no caso de arquivos do tipo Json, converte para json
     Notes:
    ------------------------------------------------------------------------------*/

    method public void converterParaObjetoJson(  ).  

    

    //todo -  Implementar a api analisarObjetoJson neste metodo 
    method public void interpretarJsonParaTT(  ).    
    
  
end interface.
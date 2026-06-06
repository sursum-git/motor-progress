
/*------------------------------------------------------------------------
    File        : EscreverArquivoChaveValor
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 14:55:59 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.IEscreverArquivo from propath.

interface Arquivo.IEscreverArquivoChaveValor inherits IEscreverArquivo:
    
    
      
  
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    
    method public void adicionarChaveValor(chave as char, valor as char  ).
    
    method public void criarArquivo(logNoConvert as logical ).
    
    
    

end interface.
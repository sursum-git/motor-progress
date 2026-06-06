
/*------------------------------------------------------------------------
    File        : EscreverArquivo
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 14:39:18 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.IArquivo.
using Progress.Json.ObjectModel.JsonObject from propath.

interface Arquivo.IEscreverArquivo :  
    
    
   
    define public property arquivo as IArquivo no-undo 
    get.
    set. 

    method public void adicionarConteudoArquivo( conteudo as char,separador as char ).
    
    method public void criarArquivo(conteudo as char).
    
    method public void criarArquivo(conteudo as longchar).
    
    method public void criarArquivo(conteudo as JsonObject).
    
    method public void criarArquivo(conteudo as memptr).
    
    
    
    

end interface.
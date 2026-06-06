
/*------------------------------------------------------------------------
    File        : Arquivo
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 14:04:33 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Comum.ESistemaOperacional from propath.
using Arquivo.ETipoArquivo from propath.

interface Arquivo.IArquivo: 
        
  
   
    

    define public property sistemaOperacional as ESistemaOperacional no-undo 
    get.
    set. 

    define public property nomeArquivo     as character no-undo 
    get. 
    
    method public void setNomeArquivo(pArquivo as char, pUtilizaSearch as logical  ).  

    define public property tamanhoArquivo     as int64 no-undo 
    get.
    //set.     

    define public property permissoes         as character no-undo 
    get.
    //set.     

    define public property extensao           as character no-undo 
    get.
    //set.     

    define public property tipoArquivo        as ETipoArquivo no-undo 
    get.
    set.     

    define public property dataUltimaAlteracao as date no-undo 
    get.
    //set. 
    
    define public property horaUltimaAlteracao as int no-undo 
    get.

    define public property nomePuro as character no-undo 
    get.

    define public property logNovoArquivo as logical no-undo 
    get.
    set.     

    //set.

end interface.
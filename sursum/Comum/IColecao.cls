
/*------------------------------------------------------------------------
    File        : IColecao
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : user
    Created     : Tue Apr 15 09:11:18 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

interface Comum.IColecao:  
    
    define public property obj as Object no-undo 
    get.
    //set. 
    
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public void adicionarObj(objeto as Object  ).

    method public void _criarTT( ).   
  
end interface.
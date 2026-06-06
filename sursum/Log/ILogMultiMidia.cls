
/*------------------------------------------------------------------------
    File        : ILogMultiMidia
    Purpose     : Adiciona o metodo de relação entre tipo de log e 
    e midia para classes que desejem gerar log em mais de uma midia
    conforme o tipo do log.
    Syntax      : 
    Description : 
    Author(s)   : administrator
    Created     : Mon Apr 14 11:09:14 BRT 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Log.ILog.
using Log.ETipoLog from propath.
using Log.EMidiaLog from propath.

interface Log.ILogMultiMidia inherits ILog:  
    
     method public void adicionarRelacaoTipoMidia( tipo as ETipoLog, midia as EMidiaLog ).
  
end interface.
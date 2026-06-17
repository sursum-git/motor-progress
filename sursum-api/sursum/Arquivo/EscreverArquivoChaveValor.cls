 
/*------------------------------------------------------------------------
   File        : EscreverArquivoChaveValor
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Tue Apr 15 15:05:31 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.IEscreverArquivoChaveValor.
using Comum.ESistemaOperacional             from propath.
using Arquivo.ETipoArquivo                  from propath.
using Progress.Json.ObjectModel.JsonObject  from propath.
using Comum.UtilTexto                       from propath.
using Arquivo.Arquivo from propath.
using Arquivo.IArquivo from propath.

routine-level on error undo, throw.

class Arquivo.EscreverArquivoChaveValor implements IEscreverArquivoChaveValor: 
    
    
    define variable LcConteudo as longchar no-undo. 
    define public property arquivo as IArquivo  no-undo 
        get.
        set. 

    method public void adicionarChaveValor( input chave as character, input valor as character ):
        
        this-object:adicionarConteudoArquivo(chave + "=" + valor,chr(13)).
        
        return.

    end method.
    
    method public void adicionarConteudoArquivo( conteudo as char,separador as char ):
        
        assign 
            lcConteudo = UtilTexto:incrValor(input lcConteudo, conteudo, separador, yes).
         
        
         
        return.
     
    end method.   

    method public void criarArquivo(logNoConvert as logical ):       
        
        if logNoConvert then
           copy-lob lcConteudo to file arquivo:nomeArquivo no-convert.                      
        else
           copy-lob lcConteudo to file arquivo:nomeArquivo . 
        
        return.

    end method.

    method public void criarArquivo( input conteudo as longchar ):
        
        return.

    end method.

    method public void criarArquivo( input conteudo as character ):
        
        return.

    end method.
    
    method public void criarArquivo(conteudo as JsonObject).
    
        return.
    end method.
    
    method public void criarArquivo(conteudo as memptr).
        return.
    
    end method.

end class.
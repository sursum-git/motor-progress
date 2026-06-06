 
/*------------------------------------------------------------------------
   File        : Arquivo
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Tue Apr 15 16:24:09 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.IArquivo.
using Comum.ESistemaOperacional from propath.
using Arquivo.ETipoArquivo from propath.

routine-level on error undo, throw.

class Arquivo.Arquivo implements IArquivo : 
    
    define variable separadorDiretorio as character initial "\".
    define public property sistemaOperacional as ESistemaOperacional no-undo 
        get.
        set. 

    
    define public property nomeArquivo        as character no-undo 
        get.        
        private set(arg as character).
             
            this-object:nomeArquivo = arg. 
            file-info:file-name     = arg.  
            if this-object:logNovoArquivo then
                return.             
            
            case substr(file-info:file-type,1,1):                
                when ? then 
                    do:                                                               
                        undo, throw new Progress.Lang.AppError('Arquivo:' + arg + ' não encontrado', 1).
                    end.                    
                when 'd' then
                    undo, throw new Progress.Lang.AppError('Arquivo:' + arg + ' é um diretório', 2).
                when 'L' then
                    undo, throw new Progress.Lang.AppError('Arquivo:' + arg + ' é um link', 3).
                when 'F' //arquivo 
                then 
                    do:                                                         
                        assign 
                            this-object:tamanhoArquivo      = file-info:file-size 
                            this-object:dataUltimaAlteracao = file-info:file-mod-date
                            this-object:horaUltimaAlteracao = file-info:file-mod-time
                            this-object:nomePuro            = entry(num-entries(this-object:nomeArquivo,separadorDiretorio),this-object:nomeArquivo, separadorDiretorio)
                            this-object:extensao            = entry(num-entries(this-object:nomePuro,'.'),this-object:nomePuro,".")                                               
                            .                        
                    end.   
            end.   
            catch erroApp as Progress.Lang.AppError :
                
                undo, throw erroApp.
                    
            end catch.         
                
        end set. 
        
            /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    method public void setNomeArquivo(pArquivo as char,pUtilizaSearch as logical  ):
        
        define variable cArquivo as character no-undo.
        
        if pUtilizaSearch then
           assign cArquivo = search(pArquivo).
        else
          assign cArquivo = pArquivo.
          
        if cArquivo = ? then
           assign cArquivo = pArquivo.  
           
           
        this-object:nomeArquivo = cArquivo.      
                    
        return.

    end method.
           

    define public property tamanhoArquivo     as int64 no-undo 
        get.
        private set.     

   //todo - implementar uma forma de recuperar as permissoes que por enquanto não são essenciais.
    define public property permissoes         as character no-undo 
        get.         

    define public property extensao           as character no-undo 
        get.         
        private set.
    define public property tipoArquivo        as ETipoArquivo no-undo 
        get.
        set.     
        
    define public property dataUltimaAlteracao as date no-undo 
        get.
        private set. 
    
    define public property horaUltimaAlteracao as int no-undo 
        get.
        private set.    
    
    define public property nomePuro as character no-undo 
        get.
        private set.
        
    define public property logNovoArquivo as logical no-undo 
        get.
        set.
end class.
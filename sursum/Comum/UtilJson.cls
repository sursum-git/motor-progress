 
/*------------------------------------------------------------------------
   File        : UtilJson
   Purpose     : Ser uma classe proxy para facilitar a conversão de Json
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Thu Apr 17 09:36:37 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Json.ObjectModel.ObjectModelParser from propath.
using Progress.Json.ObjectModel.JsonArray from propath.

routine-level on error undo, throw.

class Comum.UtilJson:    

  
    method public static JsonObject convArqJson2ObjJson(pArquivo as character  ):
        
        define variable oParser as ObjectModelParser no-undo.
        define variable obj     as JsonObject        no-undo.
        oParser = new ObjectModelParser().
        obj     = cast(oParser:ParseFile(pArquivo), JsonObject).
         
        return obj.

    end method.

    

    method public static longchar convJson2LongChar(pJson  as jsonObject  ):
        
        define variable lc as longchar no-undo.
        assign 
            lc = pJson:GetJsonText(). 
        return lc.        
        
        
    end method.    
    
    method public static void salvarJson2Arq(pJson as jsonObject, pArquivo as character):
    

        pJson:writeFile(pArquivo).


    end method.
    
    method public static jsonObject convLongChar2ObjJson(pLc as longchar):
        
        define variable oParser as ObjectModelParser no-undo.
        oParser = new ObjectModelParser().
        assign 
            pLc = codepage-convert(pLc, "UTF-8":U).
        
        return cast(oParser:Parse(pLc), JsonObject).
        
    end method.
    
    method public static JsonObject criarJsonAux( chave as character, valor as character, tipo as character ):
        
        define variable oJsonAux as JsonObject no-undo.
        oJsonAux    = new JsonObject().      
        case tipo:
            when 'int' then
                oJsonAux:add(chave,int(valor)).
            when 'int64' then
                oJsonAux:add(chave,int64(valor)).     
            when 'decimal' then
                oJsonAux:add(chave,decimal(valor)).
            when 'logico' then
                oJsonAux:add(chave,logical(valor)).     
            when 'data' then
                oJsonAux:add(chave,iso-date(date(valor))).
            otherwise 
            do:
                
                oJsonAux:add(chave,valor).
            end.      
            
        end case.
        
        return oJsonAux .

    end method.
    
    
    method public static JsonArray criarJsonArrayAux( obj as JsonArray, chave as character, valor as character, tipo as character ):
        
        define variable oJsonAux as JsonObject no-undo.
        oJsonAux    = new JsonObject().      
        case tipo:
            when 'int' then
                oJsonAux:add(chave,int(valor)).
            when 'int64' then
                oJsonAux:add(chave,int64(valor)).     
            when 'decimal' then
                oJsonAux:add(chave,decimal(valor)).
            when 'logico' then
                oJsonAux:add(chave,logical(valor)).     
            when 'data' then
                oJsonAux:add(chave,iso-date(date(valor))).
            otherwise 
            do:
                oJsonAux:add(chave,valor).
            end.                     
            
        end case.
        //oJsonAux:writeFile('c:\temp\itemPedvenda' + string(time) + string(random(1,99999)) + '.json').
        obj:add(oJsonAux).
        delete object oJsonAux no-error.                
        return obj.

    end method.
    


end class.
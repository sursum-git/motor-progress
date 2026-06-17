 
/*------------------------------------------------------------------------
   File        : importarArquivo
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : user
   Created     : Mon Apr 21 12:02:49 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Arquivo.ILerArquivo.
using Arquivo.EConvCodPag from propath.
using Arquivo.EDelimitador from propath.
using System.Diagnostics.DelimitedListTraceListener from assembly.


routine-level on error undo, throw.

class Arquivo.importarArquivo implements ILerArquivo: 

    define public property arquivo as Arquivo.IArquivo no-undo 
        get.
        set.
    
    define public property conversao as EConvCodPag no-undo 
        get.
        set. 
    
    define public property delimitador as EDelimitador no-undo 
        get.
        set. 
        
   {comum/ttExtent.i}

    method public void ler(  ):
        
                
        case conversao:            
            when EConvCodPag:ibm850_iso-8859-1 then
                input from(arquivo:nomeArquivo) convert source 'ibm850' target 'iso-8859-1' .
            when EConvCodPag:iso-8859-1_ibm850 then
                input from(arquivo:nomeArquivo) convert source 'iso-8859-1' target 'ibm850' .
            when EConvCodPag:iso-8859-1_utf-8 then
                input from(arquivo:nomeArquivo) convert source 'iso-8859-1' target 'utf-8' .
            when EConvCodPag:utf-8_iso-8859-1 then
                input from(arquivo:nomeArquivo) convert source 'utf-8' target 'iso-8859-1'.
            when EConvCodPag:NAO-CONVERTER then 
                input from(arquivo:nomeArquivo) NO-CONVERT.     
            otherwise         
            input from(arquivo:nomeArquivo).            
        end case.    
        
        create ttExtent.
        case delimitador:
            
            when EDelimitador:BARRA-PARA-DIREITA then
                import delimiter "/" ttExtent.
            when EDelimitador:BARRA-PARA-ESQUERDA then
                import delimiter "\" ttExtent.
            when EDelimitador:DOIS-PONTOS then
                import delimiter ":" ttExtent.
            when EDelimitador:HIFEN then
                import delimiter "-" ttExtent.
            when EDelimitador:PIPE then
                import delimiter "|" ttExtent.
            when EDelimitador:PONTO-VIRGULA then
                import delimiter ";" ttExtent.
            when EDelimitador:SINAL-DE-IGUAL then
                import delimiter "=" ttExtent.
            when EDelimitador:VIRGULA then
                import delimiter "," ttExtent.
            
        end case. 
        
        input close. 
        
        return.

    end method.
    
    
    {comum/retTT.i ttExtent}

end class.
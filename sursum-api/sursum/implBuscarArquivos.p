DEFINE VARIABLE cmd AS CHARACTER   NO-UNDO.
DEFINE VARIABLE hBo AS HANDLE   NO-UNDO.
{buscarArquivos.i}
{esbo/bomsg.i}
RUN buscarArquivos.p PERSIST SET hBo.


RUN iniciar                       IN hBo.
RUN limparTTs                     IN hBo.
RUN setDesconsiderarCaseSensitive IN hBo(YES).
RUN setDiretorios                 IN hBo('\\192.168.0.137\erp\especificos').
RUN setTermos                     IN hbo('peds_web').
RUN setExtensoes                  IN hBo('*.p,*.w').
RUN setArquivoResultado           IN hBo(SESSION:TEMP-DIRECTORY + 'result_peds_web.txt').
RUN executar                      IN hBo.
RUN getTtEstatistica              IN hBo(OUTPUT TABLE ttEstatistica).

IF RETURN-VALUE = 'nok' THEN DO:
   RUN getTTMsg IN hBo(OUTPUT TABLE ttMsg).
   FOR EACH ttMsg:
       MESSAGE ttMsg.cod SKIP
               ttMsg.descricao
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
       
   END.
    
END.
ELSE DO:
    RUN getTTArquivos IN hBo(OUTPUT TABLE ttArquivos).
    /*FOR EACH ttArquivos:
         DISP ttArquivos.nomeArquivo WITH WIDTH 550.
    END.*/
END.

RUN finalizar IN hBo.

FOR EACH ttEstatistica:
    DISP ttEstatistica.
END.

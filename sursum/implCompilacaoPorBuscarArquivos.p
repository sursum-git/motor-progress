/****************************************************************************************
Programa:implCompilacaoPorBuscarArquivos
Objetivo:Programa que implementa a compila‡Æo de arquivos por busca dentro do fonte.
Autor: Sursum Corda Solu‡äes
Data: 05/2025
*****************************************************************************************/
DEFINE VARIABLE logDesconsiderarCaseSensitive AS LOGICAL     NO-UNDO INIT YES.
DEFINE VARIABLE cListaDiretorios              AS CHARACTER   NO-UNDO FORMAT 'x(100)'.
DEFINE VARIABLE cTextos                       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cExtensoes                    AS CHARACTER   NO-UNDO.
DEFINE BUTTON btnOK LABEL "Compilar".
DEFINE BUTTON btnCancelar LABEL "Cancelar".
{buscarArquivos.i}
{esbo/bomsg.i}
{esp/util.i}

UPDATE 
//logDesconsiderarCaseSensitive 
cListaDiretorios              
cTextos                       
cExtensoes 
btnOK
btnCancelar
WITH FRAME fr  
    .                   

DEFINE FRAME fr
    'Diretorios separados por virgula' VIEW-AS TEXT AT ROW 1 COL 5
    cListaDiretorios AT ROW 2 COL 5   NO-LABEL
   'Textos a serem buscados separados por virgula' VIEW-AS TEXT AT ROW 3 COL 5
    cTextos          AT ROW 4 COL 5   NO-LABEL
    'Exten‡äes de arquivos a serem buscados' VIEW-AS TEXT AT ROW 5 COL 5
    cExtensoes       AT ROW 6 COL 5  NO-LABEL
    btnOK AT ROW 8 COL 5
    btnCancelar AT ROW 8 COL 15.5 
    WITH     
    SIDE-LABELS 
    THREE-D 
    VIEW-AS DIALOG-BOX 
    TITLE "Compilar arquivos"
    WIDTH 160 .        



ENABLE ALL WITH FRAME fr.
WAIT-FOR CLOSE OF FRAME fr.

ON CHOOSE OF btnOK DO:
   DEFINE VARIABLE hBo               AS HANDLE  NO-UNDO.
   RUN buscarArquivos.p              PERSISTENT SET hBo.
   RUN iniciar                       IN hBo.
   RUN limparTTs                     IN hBo.
   RUN setDesconsiderarCaseSensitive IN hBo(logDesconsiderarCaseSensitive).
   RUN setDiretorios                 IN hBo(cListaDiretorios).
   RUN setTermos                     IN hbo(cTextos).
   RUN setExtensoes                  IN hBo(cExtensoes).
   RUN setArquivoResultado           IN hBo(SESSION:TEMP-DIRECTORY + 'result_compilacao-' + STRING(TIME) + '.csv').
   RUN executar                      IN hBo.
   RUN getTtEstatistica              IN hBo(OUTPUT TABLE ttEstatistica).
END.

ON CHOOSE OF btnCancelar DO:
    APPLY "CLOSE" TO FRAME fr.
END.


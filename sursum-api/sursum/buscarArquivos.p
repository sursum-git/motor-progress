

DEFINE VARIABLE lgDesconsiderarCaseSensitive AS LOGICAL     NO-UNDO.
DEFINE VARIABLE qtNivelBusca                 AS INTEGER     NO-UNDO.
DEFINE VARIABLE lgBuscarEmArquivosOcultos    AS LOGICAL     NO-UNDO.
DEFINE VARIABLE limitadorListas              AS CHAR        NO-UNDO.
DEFINE VARIABLE arqResultado                 AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cmd                          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE hBoMsg                       AS HANDLE      NO-UNDO.
DEFINE VARIABLE cDiretorio                   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTermo                       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cExtensao                    AS CHARACTER   NO-UNDO.
{esp/util.i}
{esbo/boMsg.i}

 DEFINE TEMP-TABLE ttTermos NO-UNDO
       FIELD termo AS CHAR.                                            

DEFINE TEMP-TABLE ttDiretorios NO-UNDO
       FIELD diretorio AS CHAR.
       
/*DEFINE TEMP-TABLE ttDirExcluir NO-UNDO
       FIELD diretorio AS CHAR.*/
       
       
DEFINE TEMP-TABLE ttExtensoes NO-UNDO
       FIELD extensao  AS CHAR.

 {buscarArquivos.i}

 
PROCEDURE iniciar:

    RUN esbo/boMsg.p PERSIST SET hBoMsg.

END PROCEDURE.


PROCEDURE finalizar:

    IF VALID-HANDLE(hBoMsg) THEN DO:
       DELETE OBJECT hBoMsg.        
    END.
    DELETE OBJECT THIS-PROCEDURE.

END PROCEDURE.
    
PROCEDURE limparTTs:

    EMPTY TEMP-TABLE ttDiretorios.
    //EMPTY TEMP-TABLE ttDirExcluir.
    EMPTY TEMP-TABLE ttExtensoes.
    EMPTY TEMP-TABLE ttArquivos.


END PROCEDURE.

PROCEDURE setDesconsiderarCaseSensitive:

    DEFINE INPUT  PARAMETER pl AS LOGICAL     NO-UNDO.
    ASSIGN  lgDesconsiderarCaseSensitive = pl .

END PROCEDURE.

PROCEDURE setNivelBusca:

    DEFINE INPUT  PARAMETER pNivel AS INTEGER     NO-UNDO.
    ASSIGN qtNivelBusca = pNivel.

END PROCEDURE.

PROCEDURE setLimitadorLista:

    DEFINE INPUT  PARAMETER pLim AS CHARACTER   NO-UNDO.
    ASSIGN limitadorListas = pLim.


END PROCEDURE.

PROCEDURE setbuscarArquivosOcultos:

   DEFINE INPUT  PARAMETER pl AS LOGICAL     NO-UNDO.
    ASSIGN  lgBuscarEmArquivosOcultos  = pl . 


END PROCEDURE.


PROCEDURE setDiretorios:

    DEFINE INPUT  PARAMETER pDirs AS CHARACTER   NO-UNDO.
    
    ASSIGN cDiretorio = pDirs.
    
    
END PROCEDURE.


PROCEDURE _criarTtDiretorios:

    DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.
    REPEAT iCont = 1 TO NUM-ENTRIES(cDiretorio,limitadorListas):
         CREATE ttDiretorios. 
         ASSIGN ttDiretorios.diretorio = ENTRY(iCont,cDiretorio,limitadorListas).    
    END.


END PROCEDURE.

/*PROCEDURE setDiretoriosAExcluir:

    DEFINE INPUT  PARAMETER pDirs AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.

    REPEAT iCont = 1 TO NUM-ENTRIES(limitadorListas,pDirs):
         CREATE ttDirExcluir. 
         ASSIGN ttDirExcluir.diretorio = ENTRY(iCont,pDirs,limitadorListas).    
    END.

END PROCEDURE.   */


PROCEDURE setExtensoes:


    DEFINE INPUT  PARAMETER pExts AS CHARACTER   NO-UNDO.
    ASSIGN cExtensao = pExts.


END PROCEDURE.

PROCEDURE _criarTtExtensoes:

    DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.    
    REPEAT iCont = 1 TO NUM-ENTRIES(cExtensao,limitadorListas):
         CREATE ttExtensoes. 
         ASSIGN ttExtensoes.extensao = ENTRY(iCont,cExtensao,limitadorListas).    
    END.

END PROCEDURE.

PROCEDURE setTermos:

    DEFINE INPUT  PARAMETER pTermo AS CHARACTER   NO-UNDO.
    ASSIGN cTermo = pTermo.


END PROCEDURE.

PROCEDURE _criarTtTermos:   
   
    DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.   
    REPEAT iCont = 1 TO NUM-ENTRIES(cTermo,limitadorListas):
         CREATE ttTermos. 
         ASSIGN ttTermos.termo = ENTRY(iCont,cTermo,limitadorListas).    
    END. 


END PROCEDURE.


PROCEDURE setArquivoResultado:

    DEFINE INPUT  PARAMETER pc AS CHARACTER   NO-UNDO.
    ASSIGN arqResultado = pc.

END PROCEDURE.

PROCEDURE getCmd:

    DEFINE OUTPUT PARAMETER Pcmd AS CHARACTER   NO-UNDO.
    ASSIGN  pCmd = cmd.

END PROCEDURE.


PROCEDURE executar:

     
     DEFINE VARIABLE cTermos     AS CHARACTER   NO-UNDO.
     DEFINE VARIABLE cExtensoes  AS CHARACTER   NO-UNDO.
     DEFINE VARIABLE cDirs       AS CHARACTER   NO-UNDO. 
     DEFINE VARIABLE cArqExec    AS CHARACTER   NO-UNDO.
     DEFINE VARIABLE iQtArq      AS INTEGER     NO-UNDO.
     
     CREATE ttEstatistica.
    
     ASSIGN ttEstatistica.dtHrIni = NOW.
     
     IF limitadorListas = '' THEN
     DO:
        ASSIGN limitadorListas = ','.         
     END.
     
     RUN _criarTtDiretorios.
     RUN _criarTtExtensoes.
     RUN  _criarTtTermos.
     
     ASSIGN cArqExec = SEARCH('rg.exe').
     IF  cArqExec= ? THEN DO:
        RUN setMsg IN hBoMsg(999,'o Arquivo rg.exe n∆o foi encontrado.Baixe o arquivo em https://github.com/BurntSushi/ripgrep/releases e coloque em algum diretorio que conste no propath','erro').
         RETURN 'nok'.
     END.
     
     
     ASSIGN cmd = cArqExec + " -l ".
     
     IF lgDesconsiderarCaseSensitive THEN DO:
        
        ASSIGN cmd = cmd + " -i ".
         
     END.
     
     FOR EACH ttTermos:
         RUN incrValor(INPUT-OUTPUT cTermos, ' -e "'  + ttTermos.termo + '"',' ')  .
     END.
     
     FOR EACH ttExtensoes:     
         RUN incrValor(INPUT-OUTPUT cExtensoes,  ' -g "' + ttExtensoes.extensao + '"',' ' ).        
     END.
     
     FOR EACH ttDiretorios:
         RUN incrValor(INPUT-OUTPUT cDirs, '"' + ttDiretorios.diretorio + '"' , ' ').
     END.             
     
     //VALIDACOES
      IF limitadorListas = '|' THEN  DO:
        RUN setMsg IN hBoMsg(1,"O Limitador n∆o pode ser o caracter |(pipe) devido ao mesmo poder ser utilizado em uma express∆o REGEX para representar OR",'erro').         
        RETURN 'nok'.
     END.
     IF arqResultado = '' THEN  DO:
        RUN setMsg IN hBoMsg(2,"O Arquivo resultado deve ser informado ",'erro').         
        RETURN 'nok'.         
     END.
     
     IF cTermos = '' THEN  DO:
        RUN setMsg IN hBoMsg(5,"Informe um ou mais termos a serem pesquisados ",'erro').         
        RETURN 'nok'.         
     END.
     
     IF cDirs = '' THEN  DO:
        RUN setMsg IN hBoMsg(6,"Informe um ou mais diretorios separados pelo limitador informado ou virgula(no caso de n∆o ter informado nenhum limitador especifico no procedimento setLimitadorLista)",'erro').         
        RETURN 'nok'.         
     END.
     //FINAL VALIDACOES
     
     
     ASSIGN cmd = cmd + ' ' +  cTermos + ' ' + cDirs .
     
     IF cExtensoes <> '' THEN
     DO:
        ASSIGN cmd = cmd + ' ' + cExtensoes.
         
     END.
     
     IF qtNivelBusca > 0 THEN   DO:
        ASSIGN cmd = cmd + ' --max-depth ' + STRING(qtNivelBusca) .                       
        
     END.
     IF lgBuscarEmArquivosOcultos THEN     DO:
        ASSIGN cmd = cmd + " --hidden" .
         
     END.
     
     ASSIGN cmd = cmd + " > " + arqResultado. 
     
     //UPDATE cmd FORMAT "X(300)" WITH WIDTH 550.
     
     OS-COMMAND SILENT VALUE(cmd) NO-ERROR NO-WAIT.
     IF SEARCH(arqResultado) = ?  THEN     DO:
        RUN setMsg IN hBoMsg(4,"Arquivo resultado n∆o gerado ",'erro').                        
        RETURN 'nok'.
     END.
     ELSE DO:
        INPUT FROM VALUE(arqResultado).
        
        REPEAT:                
            CREATE ttArquivos.
            IMPORT  ttArquivos.                
        END.               
        INPUT CLOSE.
     END.      
     
     ASSIGN iQtArq = 0.
     FOR EACH ttArquivos 
        WHERE ttArquivos.nomeArquivo <> '':
         ASSIGN iQtArq = iQtArq + 1.
     END.
     
     
     ASSIGN ttEstatistica.dtHrFim   = NOW
            ttEstatistica.qtArquivo = iQtArq
            ttEstatistica.segundos  = INTERVAL(ttEstatistica.dtHrFim,ttEstatistica.dtHrIni,'seconds')
            .
           


END PROCEDURE.

PROCEDURE getTTArquivos:

    DEFINE OUTPUT PARAMETER TABLE FOR ttArquivos .


END PROCEDURE.

PROCEDURE getTtMsg:

    DEFINE OUTPUT PARAMETER TABLE FOR ttMsg.
    
    RUN getTtMsg IN hBoMsg('',OUTPUT TABLE ttMsg).


END PROCEDURE.

PROCEDURE getTTEstatistica:

    DEFINE OUTPUT PARAMETER TABLE FOR ttEstatistica.    
    

END PROCEDURE.
    

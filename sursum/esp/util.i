/*
  programa: esp/util.p
  Objetivo: Include com v†rios procedimentos genericos para otimizar
  blocos de programaá∆o repetitivos
  autor:Tadeu Silva
  data:09/2020
  25/10/23 - acrescimo de funá∆o de convers∆o de string no formato AAAMMDD
  para data progress.
*/



FUNCTION  convDt4A2M2D RETURNS DATE(data AS CHAR):
    DEFINE VARIABLE iData AS INTEGER     NO-UNDO.
    
    IF data <> '' THEN DO:
        ASSIGN data = REPLACE(data,"\","")
               data = REPLACE(data,"/","").
        ASSIGN iData = INT(data) NO-ERROR.
       IF NOT ERROR-STATUS:ERROR THEN DO:
          RETURN DATE(int(substr(data,5,2)), //mes
                      int(SUBSTR(data,7,2)), //dia
                     int(SUBSTR(data,1,4))
                     ).
       END.           
    END.              
    RETURN ? .


END FUNCTION.







PROCEDURE convListaCombo:
  DEFINE INPUT-OUTPUT  PARAMETER pLista     AS CHARACTER   NO-UNDO.
  DEFINE INPUT  PARAMETER pSeparador        AS CHARACTER   NO-UNDO.
  DEFINE INPUT  PARAMETER pPosicaoInicial   AS INTEGER     NO-UNDO.
  DEFINE INPUT  PARAMETER pExibeNumero      AS LOGICAL     NO-UNDO.
  DEFINE VARIABLE iCont                     AS INTEGER     NO-UNDO.
  DEFINE VARIABLE cIncr                     AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cListaCB                  AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE qtEntradas                AS INTEGER     NO-UNDO.
  DEFINE VARIABLE difPosIni                 AS INTEGER     NO-UNDO.
  ASSIGN qtEntradas = NUM-ENTRIES(pLista,pSeparador).

  IF pPosicaoInicial > 1 THEN DO:
     ASSIGN difPosIni  =  1 - pposicaoInicial 
            qtEntradas = qtEntradas - difPosIni.

  END.
  ELSE DO:
      ASSIGN difPosIni  = 1 - pPosicaoInicial .
      IF pPosicaoInicial < 1 THEN
         ASSIGN QtEntradas = qtEntradas - difPosIni.
  END.
  
  

  REPEAT iCont = pPosicaoInicial TO qtEntradas :
     /* MESSAGE 'posicao:' iCont SKIP
              'qt.entradas' qtEntradas SKIP
              'entrada:' Icont + difPosIni 
          VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
      ASSIGN cIncr = IF pExibeNumero THEN STRING(iCont) + '-' + ENTRY(Icont + difPosIni ,PLista,pSeparador) + ',' + STRING(iCont)
                     ELSE  ENTRY(Icont + difPosIni ,PLista,pSeparador) + ',' + STRING(iCont) . 
      RUN incrValor(input-output cListaCB, INPUT cIncr,',').
  END.
  ASSIGN pLista = cListaCB.
END PROCEDURE.


PROCEDURE incrValor:
    DEFINE INPUT-OUTPUT PARAMETER pValor      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER       pIncr       AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER       pSeparador  AS CHARACTER   NO-UNDO.
    IF pValor = '' THEN
       ASSIGN pValor = pIncr.
    ELSE 
      ASSIGN pValor = pValor + pSeparador + pIncr.

END PROCEDURE.


PROCEDURE getVlParametro:
    DEFINE INPUT  PARAMETER pParametro AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cRetorno AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE tipo AS INT   NO-UNDO.
    DEFINE VARIABLE hBo AS HANDLE      NO-UNDO.
    
    RUN esbo/boConsParam.p PERSISTENT SET hBo.
    RUN setCodParam IN hBo(pParametro).
    RUN getVlParam  IN hBo(OUTPUT cRetorno).  

    IF VALID-HANDLE(hBo) THEN 
       DELETE PROCEDURE hBo.
END PROCEDURE.

PROCEDURE getVlParametro2:
    DEFINE INPUT  PARAMETER pParametro AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pVlPadrao  AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cRetorno AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE tipo AS INT   NO-UNDO.
    DEFINE VARIABLE hBo AS HANDLE      NO-UNDO.
    
    RUN esbo/boConsParam.p PERSISTENT SET hBo.
    RUN setCodParam IN hBo(pParametro).
    RUN getVlParam  IN hBo(OUTPUT cRetorno).  
    IF cRetorno = '' THEN
       ASSIGN cRetorno  = pVlPadrao.
    IF VALID-HANDLE(hBo) THEN 
       DELETE PROCEDURE hBo.
END PROCEDURE.



PROCEDURE convDtApi:
    DEFINE INPUT  PARAMETER pData AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER data  AS DATE        NO-UNDO.
    DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.
    DEFINE VARIABLE listaSep AS CHARACTER   NO-UNDO INIT "-,/,.".
    DEFINE VARIABLE separador AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iDia AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iMes AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iano AS INTEGER     NO-UNDO.
    DEFINE VARIABLE lErro AS LOGICAL    NO-UNDO.

    REPEAT iCont = 1 TO NUM-ENTRIES(listaSep,","):
       ASSIGN separador = ENTRY(iCont,listaSep,",").
       IF INDEX(pData,separador ) > 0 THEN DO:

           CASE separador:
               WHEN  '-' THEN DO:
                  ASSIGN iAno   =  int(ENTRY(1,pData,separador))
                         iMes   =  int(ENTRY(2,pData,separador))
                         iDia   =  int(ENTRY(3,pData,separador)).
               END.
               WHEN '/' OR WHEN '.' THEN DO:
                   ASSIGN iAno  =  int(ENTRY(3,pData,separador))
                          iMes  =  int(ENTRY(2,pData,separador))
                          iDia  =  int(ENTRY(1,pData,separador)).
               END.
               /*WHEN '.' THEN DO:
                   ASSIGN iAno  =  int(ENTRY(3,pData,separador))
                          iMes  =  int(ENTRY(2,pData,separador))
                          iDia  =  int(ENTRY(1,pData,separador)).
               END.*/
               OTHERWISE
                  ASSIGN lErro = TRUE.

           END CASE.
       END.         
    END.
   IF NOT lErro THEN
      ASSIGN data = DATE(iMes,iDia,iAno).
   ELSE 
     ASSIGN data = ?.

    


END PROCEDURE.



PROCEDURE convertUnixTimestamp:
  DEFINE INPUT PARAMETER pdTimestamp AS DECIMAL NO-UNDO.
  DEFINE OUTPUT PARAMETER dtTime AS DATETIME    NO-UNDO.
  DEFINE VARIABLE pdtDate AS DATE        NO-UNDO.
  DEFINE VARIABLE pITime  AS INTEGER     NO-UNDO.
  DEFINE VARIABLE cPiTime AS CHARACTER   NO-UNDO.
  /* Seconds per day */
  DEFINE VARIABLE iSPD AS INTEGER NO-UNDO.
  /* Seconds per year */
  DEFINE VARIABLE iSPY AS INTEGER NO-UNDO.
  /* Variables to hold our calculation so far */
  DEFINE VARIABLE iYear AS INTEGER NO-UNDO.
  DEFINE VARIABLE iDay AS INTEGER NO-UNDO.
  DEFINE VARIABLE iSecsLeft AS INTEGER NO-UNDO.
  
  ASSIGN
    iSPD = 60 * 60 * 24
    iSPY = iSPD * 365
    /* Since it is impossible to have 365 or more leap years since
    ** 1970 this following calculation will always work and always
    ** come up with a correct year.
    */
    iYear = INTEGER(TRUNCATE (pdTimestamp / iSPY, 0))
    /* Calculate the number of seconds that have elapsed in the
    ** current year so far.
    */
    iSecsLeft = INTEGER(pdTimeStamp - (iYear * iSPY))
    .
/* Now we have to adjust the seconds left in the current year for the number of~
Feb 29th days that have elapsed since 1970, excluding the one in the current y~
ear, which will be handled further below.
*/
  /* How many leapyears since 1970? 1972 is the first one. */
  IF iYear > 2 THEN DO:
    DEFINE VARIABLE iLeapDays AS INTEGER NO-UNDO.
    ASSIGN /* subtract 3 from year to get relative to 1973 */
    /* 1973 = 1, 1977 = 2, etc. */
    /* We don't include the current year in this */
    iLeapDays = INTEGER(TRUNCATE((iYear - 3) / 4, 0)) + 1
    iSecsLeft = iSecsLeft - (iLeapDays * iSPD).
  END.

  /* Now the year and seconds since the beginning of the year are accurate
  */
  ASSIGN iDay = INTEGER(TRUNCATE(iSecsLeft / iSPD, 0))
  /* Now the year and day are in julian format (almost). */
  /* Julian would have year 2000 as "00", but we have "30". */
  /* If the current year is a leap year this is handled here. */
  /* DATE math allows us to add days to a date - add to Jan 1. */
  pdtDate = DATE('01/01/':U + STRING(iYear + 1970)) + iDay
  /* The number os seconds since midnight of the date above */
  piTime = iSecsLeft - (iDay * iSPD)
  .
  ASSIGN cPiTime = STRING(piTime,"hh:mm:ss").
     
  /*MESSAGE pDtDATE
      VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
  ASSIGN dtTime = DATETIME(MONTH(pDtDate),
                           DAY(pDtDate),
                           YEAR(pDtDate),
                           int(SUBSTR(cPiTime,1,2)),
                           int(SUBSTR(cPiTime,4,2)),
                           int(SUBSTR(cPiTime,7,2))).
END PROCEDURE. /* convertUnixTimestamp */


PROCEDURE getDadosBrowse:
    DEFINE INPUT  PARAMETER phbrowse          AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER pListaCampos      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pSeparadorRetorno AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cDados            AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cListaSel                 AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE qtLinhas                  AS INTEGER     NO-UNDO.
    DEFINE VARIABLE hQuery                    AS HANDLE      NO-UNDO.
    DEFINE VARIABLE hbFQuery                  AS HANDLE      NO-UNDO.
    DEFINE VARIABLE iCont                     AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont2                    AS INTEGER     NO-UNDO.


    ASSIGN qtLinhas = phbrowse:NUM-SELECTED-ROWS.
    REPEAT iCont = 1 TO qtLinhas.
        //phbrowse:FETCH-SELECTED-ROW(qtLinhas  - iCont + 1).
        phbrowse:FETCH-SELECTED-ROW(iCont).
        hQuery = phbrowse:QUERY.
        hQuery:GET-CURRENT().
        hBfQuery = hQuery:GET-BUFFER-HANDLE().
        IF hBfQuery:AVAILABLE THEN DO:
            REPEAT iCont2 = 1 TO NUM-ENTRIES(pListaCampos).
                RUN incrValor(INPUT-OUTPUT cListaSel, 
                              hBfQuery:BUFFER-FIELD(ENTRY(iCont2,pListaCampos)):BUFFER-VALUE(),
                              pSeparadorRetorno ).
            END.
        END.
        IF NUM-ENTRIES(pListaCampos) > 1  THEN
           RUN incrValor(cListaSel,chr(10),'').
   END.
   ASSIGN cDados = cListaSel .



END PROCEDURE.


PROCEDURE getUltDiaMesAno:

    DEFINE INPUT  PARAMETER pAno AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pMes AS INTEGER     NO-UNDO.
    DEFINE OUTPUT PARAMETER data AS DATE        NO-UNDO.
    DEFINE VARIABLE iAnoNovo     AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iMesNovo     AS INTEGER     NO-UNDO.
    
    IF pMes = 12 THEN
      ASSIGN iMesNovo = 1
             iAnoNovo = pAno + 1.
   ELSE
       ASSIGN imesNovo = pmes + 1
               ianoNovo = pAno.
   ASSIGN data = DATE(iMesNovo,1,iAnoNovo) - 1 .

END PROCEDURE.




PROCEDURE verificarNomeProgsCorrente:
    DEFINE INPUT  PARAMETER pProg   AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cProgsEncontrados AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont           AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cPrograma       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cProgs          AS CHARACTER   NO-UNDO.
    RUN getNomesProgsCor(OUTPUT cProgs).
    REPEAT iCont = 1 TO NUM-ENTRIES(pProg,","):
        ASSIGN cPrograma = entry(iCont,pProg,",").
        IF INDEX(cProgs,cPrograma) > 0 THEN
           RUN incrValor(INPUT-OUTPUT cProgsEncontrados,cPrograma,",").
    END.                                                               

END PROCEDURE.

PROCEDURE getNomesProgsCor:
    
    DEFINE OUTPUT PARAMETER cProgs  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont           AS INTEGER     NO-UNDO INIT 1.

    REPEAT WHILE PROGRAM-NAME(iCont) <> ?:
        RUN incrValor(INPUT-OUTPUT cProgs,PROGRAM-NAME(iCont),",").
        /*MESSAGE cProgs SKIP
                 iCont
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
        iCont = iCont + 1.

    END.

END PROCEDURE.


PROCEDURE limparTxtJson:
 //conforme https://community.progress.com/s/article/JSON-parser-returning-error-16068
 DEFINE INPUT-OUTPUT  PARAMETER txt AS LONGCHAR   NO-UNDO.

txt = REPLACE(txt, "\n", "").
txt = REPLACE(txt, "~r", "").
txt = REPLACE(txt, "~n", "").
txt = REPLACE(txt, " ", "").






END PROCEDURE.

PROCEDURE decodeFile2File:

    DEFINE INPUT  PARAMETER pArquivo    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCodPage    AS CHARACTER   NO-UNDO.
    DEFINE INPUT PARAMETER  pNovoArq    AS CHARACTER   NO-UNDO.

    IF pCodPage = '' THEN
       ASSIGN pcodPage = SESSION:CPINTERNAL .
    

    DEFINE VARIABLE decdmptr            AS MEMPTR NO-UNDO.
    DEFINE VARIABLE decdlngc            AS LONGCHAR NO-UNDO.

    COPY-LOB FROM FILE pArquivo TO decdlngc.
    decdmptr = BASE64-DECODE(decdlngc).
    COPY-LOB FROM decdmptr TO FILE pNovoArq CONVERT SOURCE CODEPAGE pCodPage.

END PROCEDURE.

PROCEDURE decodeFile2LongChar:

    DEFINE INPUT  PARAMETER pArquivo    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCodPage    AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER lchar       AS LONGCHAR    NO-UNDO.

    DEFINE VARIABLE decdmptr            AS MEMPTR       NO-UNDO.
    DEFINE VARIABLE decdlngc            AS LONGCHAR     NO-UNDO.
    DEFINE VARIABLE iTamanho            AS INT64        NO-UNDO.


    COPY-LOB FROM FILE pArquivo TO decdlngc.
    decdmptr = BASE64-DECODE(decdlngc).
    ASSIGN iTamanho = get-size(decdmptr).
    COPY-LOB FROM decdmptr STARTING  AT 1 FOR iTamanho  TO lchar CONVERT SOURCE CODEPAGE pCodPage.


END PROCEDURE.


PROCEDURE encodeFile2LongChar:

    DEFINE INPUT  PARAMETER pArquivo    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCodPage    AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER lchar       AS LONGCHAR    NO-UNDO.

    DEFINE VARIABLE encodeMptr            AS MEMPTR       NO-UNDO.
    DEFINE VARIABLE encodelngc            AS LONGCHAR     NO-UNDO.
    DEFINE VARIABLE iTamanho              AS INT64        NO-UNDO.

    IF pCodPage <> '' THEN
       COPY-LOB FROM FILE pArquivo TO encodeMptr convert target CODEPAGE pCodPage.
    ELSE 
       COPY-LOB FROM FILE pArquivo TO encodeMptr.

    encodelngc = BASE64-ENCODE(encodeMptr).


END PROCEDURE.






/*PROCEDURE sleep EXTERNAL "KERNEL32": 
    DEFINE INPUT PARAMETER iMilliseconds AS LONG NO-UNDO. 
END PROCEDURE.*/

FUNCTION sleep RETURNS INTEGER (msecs AS INTEGER):
  DEFINE VARIABLE cFunction AS CHARACTER NO-UNDO INITIAL "sleep".
  DEFINE VARIABLE cLibrary  AS CHARACTER NO-UNDO INITIAL "libc.so.1".
  DEFINE VARIABLE hCall     AS HANDLE    NO-UNDO.
  
  CREATE CALL hCall.
  ASSIGN
    cLibrary             = "kernel32.dll" WHEN OPSYS = "WIN32"
    cFunction            = "Sleep" WHEN OPSYS = "WIN32"
    hCall:CALL-NAME      = cFunction
    hCall:LIBRARY        = cLibrary
    hCall:CALL-TYPE      = DLL-CALL-TYPE
    hCall:NUM-PARAMETERS = 1.
  
  hCall:SET-PARAMETER(1, "LONG", "INPUT", msecs).
  hCall:INVOKE( ).
  
  DELETE OBJECT hCall.
  RETURN msecs.
END FUNCTION.

FUNCTION tratarNum RETURNS char (cRet AS char):
  IF cRet = '' THEN
     RETURN '0' .
  ELSE
     RETURN cRet.
END FUNCTION.


FUNCTION getTextoAGora RETURNS CHAR():

   DEFINE VARIABLE cAgora AS CHARACTER   NO-UNDO.
   ASSIGN cAgora = STRING(TODAY,'99/99/9999')
          cAgora = cAgora + "_" +  STRING(TIME,"hh:mm:ss")
          cAgora = REPLACE('/','_',cAgora)
          cAgora = REPLACE(':','_',cAgora).
   RETURN cAgora.


END FUNCTION.

FUNCTION  getPrimeiroDiaMes RETURNS DATE(iAno AS INT, iMes AS INT):

  RETURN DATE(imes,1,iAno).

END FUNCTION.


FUNCTION  getUltimoDiaMes RETURNS DATE(iAno AS INT, iMes AS INT):
  DEFINE VARIABLE dtUltDia AS DATE        NO-UNDO.

  ASSIGN dtUltDia = DATE(iMes,1,iAno )  
         dtUltDia = ADD-INTERVAL(dtUltDia,1,'months')
         dtUltDia = dtUltDia - 1 .


  RETURN dtUltDia .            

END FUNCTION.


FUNCTION getPropData RETURN CHAR(dt AS DATE, prop AS CHAR):

   CASE prop :
       WHEN 'dia' THEN
           RETURN string(DAY(dt)).
       WHEN 'mes' THEN
           RETURN STRING(MONTH(dt)).
       WHEN 'ano' THEN
           RETURN STRING(YEAR(dt)).
       WHEN 'dia_semana' THEN
           RETURN STRING(WEEKDAY(dt)).

   END CASE.

END FUNCTION.

FUNCTION getSeparadorDir RETURN char(arq AS CHAR):
    DEFINE VARIABLE cSeparador AS CHARACTER   NO-UNDO.
    IF NUM-ENTRIES(Arq,"/") > 1 THEN DO:
       ASSIGN cSeparador = "/". 
    END.
    ELSE DO:
       IF NUM-ENTRIES(Arq,"\") > 1 THEN DO:
          ASSIGN cSeparador = "\". 
       END.
    END.
    RETURN cSeparador.

END FUNCTION.

FUNCTION getNomeArqPuro RETURN char(arq AS CHAR):

    DEFINE VARIABLE cSep AS CHARACTER   NO-UNDO.
    ASSIGN cSep = getSeparadorDir(arq) .
    RETURN ENTRY(NUM-ENTRIES(arq,cSep),arq,cSep).

END FUNCTION.

PROCEDURE getRegiao:
    DEFINE INPUT  PARAMETER pUf     AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER regiao  AS CHARACTER   NO-UNDO.
    CASE pUf:
        WHEN 'GO' OR
        WHEN 'MT' OR
        WHEN 'MS' OR
        WHEN 'DF' THEN DO:
            ASSIGN regiao = 'centro-oeste'.
        END.
        WHEN 'AL' OR
        WHEN 'BA' OR
        WHEN 'CE' OR 
        WHEN 'MA' OR
        WHEN 'PB' OR
        WHEN 'PE' OR
        WHEN 'PI' OR
        WHEN 'RN' OR
        WHEN 'SE' THEN DO:
            ASSIGN regiao = 'nordeste'.
        END.   


        WHEN 'AC' OR
        WHEN 'AP' OR
        WHEN 'AM' OR
        WHEN 'PA' OR
        WHEN 'RO' OR
        WHEN 'RR' OR
        WHEN 'TO' THEN DO:
            ASSIGN regiao = 'norte'.
        END.

        WHEN 'ES' OR
        WHEN 'MG' OR
        WHEN 'RJ' OR
        WHEN 'SP' THEN DO:
            ASSIGN regiao = 'sudeste'.
        END.

        WHEN 'PR' OR
        WHEN 'RS' OR
        WHEN 'SC' THEN DO:
            ASSIGN regiao = 'sul'.
        END.

    END CASE.

END.

PROCEDURE getCpsTT:

    DEFINE INPUT  PARAMETER phTT        AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER pDelimitador  AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cListaCps   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hBTT                AS HANDLE      NO-UNDO.
    DEFINE VARIABLE hQ                  AS HANDLE      NO-UNDO.
    DEFINE VARIABLE cmdQ                AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCampo              AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iContExtent         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont               AS INTEGER     NO-UNDO.
    ASSIGN                               
    hBTT = phTT:DEFAULT-BUFFER-HANDLE
    cmdQ = 'for each ' + phTT:NAME .
    CREATE QUERY hQ.
    hQ:ADD-BUFFER(hBTT).
    hQ:QUERY-PREPARE(cmdQ).
    hQ:QUERY-OPEN.
    hQ:GET-NEXT().
    /*MESSAGE 'numero de campos:' hbTT:NUM-FIELDS
      VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    REPEAT iCont = 1 TO hbTT:NUM-FIELDS.
      IF hbTT:BUFFER-FIELD(iCont):EXTENT  > 0 THEN DO:
         REPEAT iContExtent = 1 TO hbTT:BUFFER-FIELD(iCont):EXTENT:
            //ASSIGN cValor[iContExtent] =  hBTT:BUFFER-FIELD(iCont):STRING-VALUE(iContExtent) .
            IF hbTT:BUFFER-FIELD(iCont):COLUMN-LABEL = '' THEN
               ASSIGN cCampo = hbTT:BUFFER-FIELD(iCont):NAME + "_" + STRING(iContExtent).
            ELSE
               ASSIGN cCampo = hbTT:BUFFER-FIELD(iCont):COLUMN-LABEL + "_" + STRING(iContExtent).
            RUN incrValor(INPUT-OUTPUT cListaCps, cCampo , pDelimitador).
         END.                                                                              
      END.
      ELSE DO:
          IF hbTT:BUFFER-FIELD(iCont):COLUMN-LABEL = '' THEN
             ASSIGN cCampo = hbTT:BUFFER-FIELD(iCont):NAME .
          ELSE
             ASSIGN cCampo = hbTT:BUFFER-FIELD(iCont):COLUMN-LABEL .

          RUN incrValor(INPUT-OUTPUT cListaCps, cCampo,pDelimitador).  
      END.
      /*MESSAGE cCampo    SKIP
              cListaCps SKIP
          VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    END.  
    hQ:QUERY-CLOSE().
     IF VALID-OBJECT(hQ) THEN
        DELETE OBJECT hQ.  

    hbTT:BUFFER-RELEASE().
    DELETE OBJECT hbtt.


END PROCEDURE.

PROCEDURE getVlCpTT:
    //para tabelas temporarias de BO. Desta forma trabalha-se com apenas um registro na tabela temporaria
    DEFINE INPUT  PARAMETER phTT        AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER pCampo      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pExtent     AS INTEGER     NO-UNDO.
    DEFINE OUTPUT PARAMETER valorCp     AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hBTT                AS HANDLE      NO-UNDO.
    DEFINE VARIABLE hQ                  AS HANDLE      NO-UNDO.
    DEFINE VARIABLE cmdQ                AS CHARACTER   NO-UNDO.
    ASSIGN hBTT = phTT:DEFAULT-BUFFER-HANDLE
    cmdQ = 'for each ' + phTT:NAME .
    CREATE QUERY hQ.
    hQ:ADD-BUFFER(hBTT).
    hQ:QUERY-PREPARE(cmdQ).
    hQ:QUERY-OPEN.
    hQ:GET-NEXT().
    IF pExtent > 0 THEN DO:
       ASSIGN valorCp = hbtt:BUFFER-FIELD(pCampo):string-VALUE(pExtent).
    END.
    ELSE DO:
      ASSIGN valorCp = hbtt:BUFFER-FIELD(pCampo):string-VALUE().
    END.
    hQ:QUERY-CLOSE().
    IF VALID-OBJECT(hQ) THEN
       DELETE OBJECT hQ.   

    hbTT:BUFFER-RELEASE().
    DELETE OBJECT hbtt.

END PROCEDURE.

PROCEDURE setCpTT:

    DEFINE INPUT  PARAMETER phTT        AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER PCampo      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pPosicao     AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pValor      AS CHARACTER   NO-UNDO.

    
    DEFINE VARIABLE hBTT                AS HANDLE      NO-UNDO.
    DEFINE VARIABLE hQ                  AS HANDLE      NO-UNDO.
    DEFINE VARIABLE cmdQ                AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iContExtent         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont               AS INTEGER     NO-UNDO.
    ASSIGN                               
    hBTT = phTT:DEFAULT-BUFFER-HANDLE
    cmdQ = 'for each ' + phTT:NAME .
    CREATE QUERY hQ.
    hQ:ADD-BUFFER(hBTT).
    hQ:QUERY-PREPARE(cmdQ).
    hQ:QUERY-OPEN.
    hQ:GET-NEXT().
    /*MESSAGE 'numero de campos:' hbTT:NUM-FIELDS
      VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    CASE hbtt:BUFFER-FIELD(pCampo):DATA-TYPE:
        WHEN 'integer' THEN DO:
            IF pPosicao = 0  THEN
                hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = int(pValor) .
            ELSE
              hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = int(pValor) .
        END.
            
        WHEN 'int64' THEN DO:
            IF pPosicao = 0 THEN
                hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = int64(pValor) .
            ELSE
                hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = int64(pValor) .
        END.
            
        WHEN 'logical' THEN DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = LOGICAL(pValor) .
            ELSE
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = LOGICAL(pValor). . 

        END.
            
        WHEN 'decimal' THEN DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = DECIMAL(pValor) .
            ELSE 
              hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = DECIMAL(pValor) .

        END.
            
        WHEN 'date' THEN DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = DATE(pValor) .
            ELSE
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = DATE(pValor) .
        END.
            
        WHEN 'datetime' THEN DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = DATETIME(pValor) .
            ELSE 
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = DATETIME(pValor) .
        END.

            
        WHEN 'datetime-tz' THEN DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = DATETIME-TZ(pValor) .
            ELSE
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = DATETIME-TZ(pValor) .
        END.
            
        WHEN 'rowid' THEN DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = TO-ROWID(pValor) .
            ELSE
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = TO-ROWID(pValor) .
        END.
            
        OTHERWISE  DO:
            IF pPosicao = 0 THEN
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE() = pValor . 
            ELSE
               hbtt:BUFFER-FIELD(pCampo):BUFFER-VALUE(pPosicao) = pValor . 
        END.                                                               
    END CASE.                                                              

END PROCEDURE.

PROCEDURE selDir:

    DEFINE INPUT  PARAMETER pDirIni AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTitulo AS CHARACTER   NO-UNDO.
    
    DEFINE OUTPUT PARAMETER cDir    AS CHARACTER   NO-UNDO.

    SYSTEM-DIALOG GET-DIR cDir
    INITIAL-DIR pDirIni
    RETURN-TO-START-DIR 
    TITLE pTitulo
        .


END PROCEDURE.


FUNCTION  getExtensaoArq RETURNS CHAR (arquivo AS CHAR):

    IF arquivo <> ''  THEN
       RETURN ENTRY(NUM-ENTRIES(arquivo,"."),arquivo,".") .
END FUNCTION.

PROCEDURE verifDirs:

    DEFINE INPUT  PARAMETER pCaminho   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pSeparador AS CHARACTER   NO-UNDO.

    DEFINE VARIABLE iCont           AS INTEGER     NO-UNDO.
    DEFINE VARIABLE caminhoAtu      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cSeparador      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE caminhoFinal    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cComando       AS CHARACTER   NO-UNDO.
    OUTPUT TO VALUE(SESSION:TEMP-DIRECTORY + 'log_criacao_pastas_' + STRING(TIME) + string(RANDOM(1,99999)) + '.txt').
    ASSIGN cSeparador = getSeparadorDir(pCaminho).
    PUT UNFORM "Separador:" cSeparador SKIP. 
    PUT UNFORM "Caminho:" pCaminho SKIP.
    PUT UNFORM "Qt.pastas:" NUM-ENTRIES(pCaminho,pSeparador) SKIP.
    REPEAT iCont = 1 TO NUM-ENTRIES(pCaminho,pSeparador):
        PUT UNFORM "numero:" iCont " -  termo a ser acrescentado:"  ENTRY(iCont,pCaminho,pSeparador) SKIP.        
        RUN incrValor(INPUT-OUTPUT caminhoAtu,
                      ENTRY(iCont,pCaminho,pSeparador),
                      pSeparador
                      ).
        PUT UNFORM "caminho atual:"  caminhoAtu SKIP.            
        ASSIGN caminhoFinal = cSeparador + caminhoAtu.
        PUT UNFORM "caminho final:"  caminhoFinal SKIP. 
        
        PUT UNFORM "achou?"  SEARCH(caminhoFinal) SKIP. 
        
        IF SEARCH(caminhoFinal) = ? AND caminhoAtu <> '' THEN DO:
           PUT UNFORM "caminho que ser† criado:"  caminhoFinal SKIP.
           ASSIGN cComando = "mkdir -p " + caminhoFinal.
           PUT UNFORM "comando:"  cComando SKIP.
           IF OPSYS = 'unix' THEN DO:
              OS-COMMAND SILENT VALUE("mkdir -p " + caminhoFinal).               
           END.
           ELSE DO:
              OS-COMMAND SILENT VALUE("mkdir " + caminhoFinal).          
           END.
           
        END.
    END.    
    OUTPUT close.
    

END PROCEDURE.

FUNCTION getNowToNameFile RETURNS CHAR():

    DEFINE VARIABLE hoje     AS DATETIME    NO-UNDO.
    DEFINE VARIABLE cRetorno AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iTime    AS INT         NO-UNDO.
    DEFINE VARIABLE cTempo   AS CHARACTER   NO-UNDO.
    ASSIGN  hoje = TODAY
           iTime = TIME.

    RUN incrValor(INPUT-OUTPUT cRetorno,YEAR(hoje),"-").
    RUN incrValor(INPUT-OUTPUT cRetorno,MONTH(hoje),"-").
    RUN incrValor(INPUT-OUTPUT cRetorno,DAY(hoje),"-").
    ASSIGN cTempo = STRING(iTime,'hh:mm:ss')
           cTempo = REPLACE(cTempo,':','-').
    RUN incrValor(INPUT-OUTPUT cRetorno,cTempo,"-").

    RETURN cRetorno.

    


END FUNCTION.

PROCEDURE gravarTextoEmArquivo:
    DEFINE INPUT  PARAMETER pNomeArquivo AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTexto       AS CHARACTER   NO-UNDO.

    OUTPUT TO VALUE(pNomeArquivo).
        PUT UNFORM pTexto SKIP.   
    OUTPUT CLOSE.

END PROCEDURE.

PROCEDURE extrairListaCpsTb:

    DEFINE INPUT  PARAMETER pHTb          AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER pListaCps     AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pSeparador    AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cLista        AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cTermo AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hQuery AS HANDLE      NO-UNDO.
    DEFINE VARIABLE iCont  AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cSep   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hCampo AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bh     AS HANDLE      NO-UNDO.
    
    ASSIGN bh = pHtb .
    CREATE QUERY hQuery.
    hQuery:SET-BUFFERS(bh).
    hQuery:QUERY-PREPARE(" FOR EACH "  + pHTb:NAME ).
    hQuery:QUERY-OPEN().
    REPEAT:
      hQuery:GET-NEXT().
      IF hQuery:QUERY-OFF-END THEN LEAVE.
      ASSIGN cTermo = ''.
      REPEAT iCont = 1 TO NUM-ENTRIES(pListaCps):
          ASSIGN cTermo = cTermo +  bh:BUFFER-FIELD(ENTRY(iCont,pListaCps)):BUFFER-VALUE() .
          IF iCont <> NUM-ENTRIES(pListaCps) AND pSeparador <> '' THEN
              ASSIGN cTermo = cTermo + pSeparador .
      END.
      RUN incrValor(INPUT-OUTPUT cLista,cTermo,",").
    END.                                            
    hQuery:QUERY-CLOSE().
    DELETE OBJECT hQuery.

END PROCEDURE.


PROCEDURE extrairListaCpsTbPorOrdem:

    DEFINE INPUT  PARAMETER pHTb          AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER pListaCps     AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pSeparador    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pOrdem        AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cLista        AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cTermo AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hQuery AS HANDLE      NO-UNDO.
    DEFINE VARIABLE iCont  AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cSep   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hCampo AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bh     AS HANDLE      NO-UNDO.
    
    ASSIGN bh = pHtb .
    CREATE QUERY hQuery.
    hQuery:SET-BUFFERS(bh).
    hQuery:QUERY-PREPARE(" FOR EACH "  + pHTb:NAME  + " " + pOrdem).
    hQuery:QUERY-OPEN().
    REPEAT:
      hQuery:GET-NEXT().
      IF hQuery:QUERY-OFF-END THEN LEAVE.
      ASSIGN cTermo = ''.
      REPEAT iCont = 1 TO NUM-ENTRIES(pListaCps):
          ASSIGN cTermo = cTermo +  bh:BUFFER-FIELD(ENTRY(iCont,pListaCps)):BUFFER-VALUE() .
          IF iCont <> NUM-ENTRIES(pListaCps) AND pSeparador <> '' THEN
              ASSIGN cTermo = cTermo + pSeparador .
      END.
      RUN incrValor(INPUT-OUTPUT cLista,cTermo,",").
    END.                                            
    hQuery:QUERY-CLOSE().
    DELETE OBJECT hQuery.

END PROCEDURE.

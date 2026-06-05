/*
  programa: esp/util.p
  Objetivo: Include com v rios procedimentos genericos para otimizar
  blocos de programa‡Æo repetitivos
  autor:Tadeu Silva
  data:09/2020
*/


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

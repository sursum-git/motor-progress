/***************************************************************************
programa: boConsDin
objetivo: converter os dados recebidos, executar a query dinamica conforme os
parametros e retornar os dados em uma tabela dinamica.
data: 10/2021
****************************************************************************/
USING Progress.Json.ObjectModel.JsonObject .
DEFINE VARIABLE  cTabelas       AS CHARACTER   NO-UNDO FORMAT 'x(200)'.
DEFINE VARIABLE  cCampos        AS CHARACTER   NO-UNDO FORMAT 'x(2000)'.
DEFINE VARIABLE  cCamposTransf  LIKE cCampos   NO-UNDO.
DEFINE VARIABLE  cCamposApelido LIKE cCampos   NO-UNDO.
DEFINE VARIABLE  cCondicao      AS CHARACTER   NO-UNDO FORMAT 'x(16000)'.
DEFINE VARIABLE  cInner         AS CHARACTER   NO-UNDO FORMAT 'x(8000)'.
DEFINE VARIABLE  logUnicaTb     AS LOGICAL     NO-UNDO.
DEFINE VARIABLE  lErro          AS LOGICAL     NO-UNDO INIT NO.
DEFINE VARIABLE  hTTResult      AS HANDLE      NO-UNDO.
DEFINE VARIABLE  hBTtResult     AS HANDLE      NO-UNDO.
DEFINE VARIABLE  hBoMsgConsDin  AS HANDLE      NO-UNDO.
DEFINE VARIABLE cArqCsv         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE hQuery          AS HANDLE      NO-UNDO.
DEFINE VARIABLE cmdSql          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iCont2          AS INTEGER     NO-UNDO.
DEFINE VARIABLE cCampo          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cOperador       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCabCsv         AS CHARACTER   NO-UNDO FORMAT 'x(2000)'.
DEFINE VARIABLE cmdSqlite       AS CHARACTER   NO-UNDO FORMAT 'x(2000)'.
DEFINE VARIABLE cmdPostGreSQL   AS CHARACTER   NO-UNDO FORMAT 'x(4000)'.
DEFINE VARIABLE cVlCampo        AS CHARACTER   NO-UNDO .
DEFINE VARIABLE joResult        AS jsonObject  NO-UNDO.
DEFINE VARIABLE breakBy         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lDistinct       AS LOGICAL     NO-UNDO.
DEFINE VARIABLE qtCampos        AS INTEGER     NO-UNDO.
DEFINE VARIABLE lApelido        AS LOGICAL     NO-UNDO.
DEFINE VARIABLE cArqInsertSql   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTipoRetorno    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE caracterOri     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE caracterSub     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lSubstCaracter  AS LOGICAL     NO-UNDO.

DEFINE VARIABLE lResultJson     AS LOGICAL     NO-UNDO.
{esp/util.i}
{esbo/boMsg.i}
{esbo/ttCampos.i}
DEFINE TEMP-TABLE ttCamposAux LIKE ttCampos.

DEFINE TEMP-TABLE ttTabelas NO-UNDO
    FIELD banco    AS CHAR FORMAT 'x(20)'
    FIELD tabela   AS CHAR FORMAT 'x(50)'
    FIELD campos   AS CHAR FORMAT 'x(2000)'
    FIELD condicao AS CHAR FORMAT 'x(8000)' 
    FIELD hbf      AS HANDLE
    FIELD relacao  AS CHAR
    INDEX primario AS PRIMARY UNIQUE tabela banco .

DEFINE TEMP-TABLE ttBancoTabela  NO-UNDO
    FIELD banco AS CHAR  FORMAT "x(20)"
    FIELD tabela AS CHAR FORMAT "x(20)" 
    INDEX ind AS PRIMARY tabela.



DEFINE TEMP-TABLE ttApelidosCp NO-UNDO
    FIELD campo         AS CHAR
    FIELD apelido       AS CHAR.

DEFINE TEMP-TABLE ttApelidosTb NO-UNDO
    FIELD tabela    AS CHAR
    FIELD apelido   AS CHAR.

FUNCTION _substCaracter RETURNS CHAR (texto AS CHAR):


    IF NOT lSubstCaracter THEN RETURN texto.
    ELSE DO:
        RETURN REPLACE(texto,caracterOri,caracterSub).
    END.



END FUNCTION.

PROCEDURE setCaracterSubst:

    DEFINE INPUT  PARAMETER pCaracterOri AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCaracterSub AS CHARACTER   NO-UNDO.

    ASSIGN caracterOri   = pCaracterOri
           caracterSub   = pCaracterSub
           lSubstCaracter = YES.

END PROCEDURE.

PROCEDURE incluirCpsTabela:

    DEFINE INPUT PARAMETER TABLE FOR ttCamposAux.

    FIND FIRST ttCampos
        WHERE ttCampos.tabela = ttCamposAux.tabela
        NO-ERROR.
    IF AVAIL ttCampos THEN DO:
       FOR EACH ttCampos
           WHERE ttCampos.tabela = ttCamposAux.tabela.
           DELETE ttCampos.
       END.
    END.

    FOR EACH ttCamposAux:
        CREATE ttCampos.
        BUFFER-COPY ttCamposAux TO ttCampos.
    END.                                    

END PROCEDURE.


PROCEDURE getTipoCpTabela:

    DEFINE INPUT  PARAMETER pTabela AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCampo  AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER tipoCp  AS CHARACTER   NO-UNDO.

    FIND LAST ttCampos
        WHERE ttCampos.tabela = pTabela
        AND   entry(1,ttCampos.nome,"[") = pCampo
        NO-ERROR.
    IF AVAIL ttcampos THEN
       ASSIGN tipoCp = ttCampos.tipo  .



END PROCEDURE.

PROCEDURE limparTTs:

    EMPTY TEMP-TABLE ttTabelas.
    EMPTY TEMP-TABLE ttMsg.
    EMPTY TEMP-TABLE ttApelidosCp .
    EMPTY TEMP-TABLE ttApelidosTb .
    EMPTY TEMP-TABLE ttBancoTabela.
    EMPTY TEMP-TABLE ttCampos.
    
    IF valid-handle(hTTResult) THEN DO:
       httResult:EMPTY-TEMP-TABLE().
       ASSIGN httResult = ?.
    END.
    ASSIGN cCamposTransf    = ''
           cCamposApelido   = ''
           qtCampos         = 0
           lDistinct        = NO
           breakBy          = ''
           joResult         = ?
           lApelido         = NO .

END PROCEDURE.
PROCEDURE iniciarBos:                              
    RUN esbo/boMsg.i PERSISTENT SET hBoMsgConsDin .
END PROCEDURE.


PROCEDURE finalizarBos:                            
    IF VALID-HANDLE(hBoMsgConsDin) THEN DO:
       DELETE PROCEDURE hBoMsgConsDin.
    END.                                           
END PROCEDURE.

PROCEDURE getTTMsg:
    DEFINE INPUT  PARAMETER pTipo AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER TABLE FOR ttMsg.

    RUN getTTMsg IN hBoMsgConsDin(pTipo, OUTPUT TABLE ttMsg).

END PROCEDURE.

PROCEDURE limparTTMsg:
    RUN limparTTmsg IN hBoMsgConsDin.
END PROCEDURE.

PROCEDURE setDadosConsulta:

    DEFINE INPUT  PARAMETER pTabelas  LIKE cTabelas    NO-UNDO.
    DEFINE INPUT  PARAMETER pCampos   LIKE cCampos     NO-UNDO.
    DEFINE INPUT  PARAMETER pCondicao LIKE cCondicao   NO-UNDO.
    DEFINE INPUT  PARAMETER pInner    LIKE cInner      NO-UNDO.

    
    ASSIGN cTabelas     = pTabelas
           cCampos      = pCampos
           cCondicao    = pCondicao
           cInner       = pInner .

    IF pTabelas = '' THEN DO:
        RUN setMsg IN hBoMsgConsDin(1,'Tabela nÆo informada','erro').
        ASSIGN lErro = YES.
    END.


    IF pCampos = '' THEN DO:
        RUN setMsg IN hBoMsgConsDin(2,'Nenhum Campo Informado','erro').
        ASSIGN lErro = YES.
    END.

    IF pCondicao = '' THEN DO:
        RUN setMsg IN hBoMsgConsDin(3,'Nenhuma condi‡Æo informada','erro').
        ASSIGN lErro = YES.
    END.

END PROCEDURE.


PROCEDURE criarTTResult:

DEFINE VARIABLE iCont  AS INTEGER     NO-UNDO.
DEFINE VARIABLE cCampo AS CHARACTER   NO-UNDO.
DEFINE VARIABLE hBf    AS HANDLE      NO-UNDO.

IF logUnicaTb AND lApelido = NO THEN DO:
   CREATE TEMP-TABLE hTTResult.
     /*MESSAGE cTabelas
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
   CREATE BUFFER hBf FOR TABLE ctabelas .           
   httResult:CREATE-LIKE(hBf). 
END.
ELSE DO:
    CREATE TEMP-TABLE hTTResult.
    /*MESSAGE 'campos apelido:' cCamposApelido SKIP
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    REPEAT iCont = 1 TO num-entries(cCamposApelido,",").
       ASSIGN cCampo =ENTRY(iCont,cCamposApelido,",").
       hTTResult:ADD-NEW-FIELD(cCampo,'char').
    END.
END.
httResult:TEMP-TABLE-PREPARE('ttResult').
hBTTResult = hTtResult:default-buffer-handle.

END PROCEDURE.





PROCEDURE execConsulta:

    /*
       op‡äes de retorno:
       objectjson, 
       csv,
       handle buffer,
       json
    */

    DEFINE INPUT  PARAMETER pTipoRetorno AS CHARACTER   NO-UNDO. 
    ASSIGN cTipoRetorno = pTipoRetorno.
    DEFINE VARIABLE condicaoFinal AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont         AS INTEGER     NO-UNDO.


    ASSIGN  cmdSql     = ''
            iCont2     = 0 
            cCampo      =''.
    

    IF lErro = NO THEN DO:
       RUN extrairTabelas.                                                                                                                                   
       RUN atribuirCampos.                                                                                                                                   
       RUN atribuirCondicao.                                                                                                                                 
       RUN criarTTResult.                                                                                                                                    
       CREATE QUERY hQuery.
       FOR EACH ttTabelas:                                                                                                                                   
           ASSIGN iCont = iCont + 1.                                                                                                                         
           hQuery:ADD-BUFFER(ttTabelas.hBf).                    
           IF iCont = 1 THEN
              ASSIGN cOperador = " WHERE ".
           ELSE
              ASSIGN cOperador = " AND ".
           RUN incrValor(INPUT-OUTPUT condicaoFinal, cOperador +  ttTabelas.condicao, "" ).                                                                               
           IF iCont = 1 THEN DO:                                    
               /*MESSAGE ttTabelas.banco
                   VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
               ASSIGN cmdSql = "for each " + ttTabelas.banco + "." + ttTabelas.tabela + " no-lock " .                                                                                
           END.                                                                                                                                              
           //pensar logica para duas tabelas considerando a modifica‡Æo do each, first e last e a forma de join que pode ser por "of" ou por campos.         
           ELSE DO:                                                                                                                                          
              IF ttTabelas.relacao = '' THEN                                                                                                                 
                 ASSIGN ttTabelas.relacao = ' each '.                                                                                                        
              RUN incrValor(INPUT-OUTPUT cmdSql,ttTabelas.relacao + ttTabelas.tabela + " no-lock " ).                                                        
           END.                                                                                                                                              
       END.                                                                                                                                                  
       RUN incrValor(INPUT-OUTPUT cmdSql,condicaoFinal," " ). 
       hQuery:QUERY-PREPARE(cmdSql).                                                                                                                     
       hQuery:QUERY-OPEN.  
       
       CASE pTipoRetorno:
           WHEN 'csv' THEN
              RUN _getDadosCsv.
           WHEN 'buffer' THEN
              RUN _getDadosBufferHandle.
           WHEN 'sqlite' THEN
              RUN _gerarInsertSqlite.
           WHEN 'postgresql' THEN
              RUN _gerarInsertPostgresql.


       END CASE.

       hQuery:QUERY-CLOSE().
       RUN limparObjTT.
       IF VALID-OBJECT(hQuery) THEN
          DELETE OBJECT hQuery.                                                                                                                                 
    END.
END PROCEDURE.

PROCEDURE getComando.

    DEFINE OUTPUT PARAMETER pComando AS CHARACTER   NO-UNDO.
    ASSIGN pComando = cmdSql.

END PROCEDURE.

PROCEDURE limparObjTT:
   //limpar buffers e objetos                                                                                                                            
   FOR EACH ttTabelas:                                                                                                                                   
       ttTabelas.hBf:BUFFER-RELEASE().
       IF VALID-OBJECT(ttTabelas.hBf) THEN
          DELETE OBJECT ttTabelas.hBf.                                                                                                                      
   END.                                                                                                                                                  

END PROCEDURE.



PROCEDURE _getDadosBufferHandle:
    DEFINE VARIABLE lSegue AS LOGICAL     NO-UNDO.
    REPEAT:                                                                                                                                               
      hQuery:GET-NEXT().                                                                                                                                  
      IF hQuery:QUERY-OFF-END THEN LEAVE. 
      RUN verificarCondBreak(hQuery, OUTPUT lSegue).
      IF lSegue = NO THEN NEXT.
      hbttResult:BUFFER-CREATE. 
      FOR EACH ttTabelas:
          REPEAT iCont2 = 1 TO num-entries(ttTabelas.campos,","):                                                                                                      
           ASSIGN cCampo = ENTRY(iCont2,ttTabelas.campos,",").
            hbttResult:BUFFER-FIELD(cCampo):BUFFER-VALUE = ttTabelas.hbf:BUFFER-FIELD(cCampo):BUFFER-VALUE.                                                          
          END.                                                                                                                                                
      END.
    END.
    
END PROCEDURE.

PROCEDURE getJsonObject:
    DEFINE OUTPUT PARAMETER  pjOResult AS jsonObject  NO-UNDO.
    IF lResultJson = FALSE THEN DO:
       ASSIGN jOResult = NEW jsonObject() .
       hbttResult:WRITE-JSON("jsonObject", jOResult).
       ASSIGN lResultJson = TRUE.

    END.
    ASSIGN pjOResult = jOresult.

END PROCEDURE.



PROCEDURE setNomeArqCsv:     
    DEFINE INPUT  PARAMETER pArqCsv AS CHARACTER   NO-UNDO.
    ASSIGN cArqCsv = pArqCsv.
END PROCEDURE.



PROCEDURE _gerarCabCsv:

    ASSIGN cCabCSV = ''.
    FIND FIRST ttTabelas NO-ERROR.
    IF AVAIL ttTabelas THEN
       ASSIGN cCabCsv = REPLACE(ttTabelas.campos,',',';').

        
        // RUN incrValor(INPUT-OUTPUT cCabCsv, ttTabelas.campos,";").
                                                           
    

END PROCEDURE.

PROCEDURE _gerarCpsInsertSqlite:
    DEFINE VARIABLE iCont   AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cCampos AS CHARACTER   NO-UNDO.
    ASSIGN cmdSqlite = ''.
    FIND FIRST  ttTabelas NO-LOCK NO-ERROR.
    IF AVAIL ttTabelas THEN DO:
       REPEAT iCont = 1 TO NUM-ENTRIES(ttTabelas.campos,","):
             RUN incrValor(INPUT-OUTPUT cCampos,"[" + ENTRY(iCont,ttTabelas.campos,",") + "]",",").
       END.
       ASSIGN cmdSqlite = "INSERT INTO [" + ttTabelas.tabela   + "] ( " + cCampos +   " )".
    END.
    

END PROCEDURE.

PROCEDURE _gerarCpsInsertPostGreSQL:
    DEFINE VARIABLE iCont   AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cCampos AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCampo  AS CHARACTER   NO-UNDO.
    ASSIGN cmdPostGreSQl = ''.
    FIND FIRST  ttTabelas NO-LOCK NO-ERROR.
    IF AVAIL ttTabelas THEN DO:
       REPEAT iCont = 1 TO NUM-ENTRIES(ttTabelas.campos,","):
             ASSIGN cCampo = _substCaracter(ENTRY(iCont,ttTabelas.campos,",")).
             RUN _tratarCampoExtentPostGres(INPUT-OUTPUT cCampo).
             //RUN incrValor(INPUT-OUTPUT cCampos,'"' + cCampo + '"',",").
             RUN incrValor(INPUT-OUTPUT cCampos, cCampo ,",").
       END.


       ASSIGN cmdPostGreSQL = 'INSERT INTO "' + _substCaracter(ttTabelas.tabela)   + '" ( ' + _substCaracter(cCampos) +   ' )'.
    END.
    

END PROCEDURE.


PROCEDURE getVlCp:
    DEFINE VARIABLE indice AS INTEGER     NO-UNDO.
    DEFINE VARIABLE limite AS INTEGER     NO-UNDO.
    ASSIGN limite = INDEX(cCampo,'[').
    IF INDEX(cCampo,'[') > 0 THEN DO:
       ASSIGN indice = INT( SUBSTR(cCampo, limite + 1,1))
              cCampo = SUBSTR(cCampo,1,limite - 1).
       ASSIGN cVlCampo = ttTabelas.hbf:BUFFER-FIELD(cCampo):BUFFER-VALUE(indice) .
        
    END.
    ELSE DO:
        ASSIGN cVlCampo = ttTabelas.hbf:BUFFER-FIELD(cCampo):BUFFER-VALUE() .
        /*MESSAGE cVlCampo
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    END.

    IF cTipoRetorno = 'csv' THEN DO:
       IF INDEX(STRING(cVlCampo),CHR(13)) > 0   THEN
         ASSIGN cVlCampo = REPLACE(cVlCampo,CHR(13), '++') .

        IF INDEX(STRING(cVlCampo),CHR(10)) > 0   THEN
            ASSIGN cVlCampo = REPLACE(cVlCampo,CHR(10), '--') .
    END.
    IF cTipoRetorno = 'sqlite' THEN DO:
       IF INDEX(STRING(cVlCampo),"'") > 0   THEN
          ASSIGN cVlCampo = REPLACE(cVlCampo,"'", '') .
       
    END.

    IF cTipoRetorno = 'postgresql' THEN DO:
       IF INDEX(STRING(cVlCampo),"'") > 0   THEN
          ASSIGN cVlCampo = REPLACE(cVlCampo,"'", '') .
       
    END.

    


END PROCEDURE.

PROCEDURE _getDadosCsv:
    DEFINE VARIABLE lSegue AS LOGICAL     NO-UNDO.
    OUTPUT TO VALUE(cArqCsv).
    RUN _gerarCabCsv.
    PUT UNFORMAT cCabCSV SKIP.
    REPEAT:                                                                                                                                               
      hQuery:GET-NEXT().                                                                                                                                  
      IF hQuery:QUERY-OFF-END THEN LEAVE.                                                                                                                 
      RUN verificarCondBreak(hQuery, OUTPUT lSegue).
      IF lSegue = NO THEN NEXT.
      FOR EACH ttTabelas:
          /*MESSAGE ttTabelas.campos
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
          REPEAT iCont2 = 1 TO num-entries(ttTabelas.campos,","):                                                                                                      
            ASSIGN cCampo = ENTRY(iCont2,ttTabelas.campos,",").
            RUN getVlCp.
            PUT UNFORMAT cVlCampo ";".
          END.                                                                                                                                                
      END.
      PUT SKIP.
    END. 
    OUTPUT CLOSE.
END PROCEDURE.


PROCEDURE setArqInsertSqlite:
    DEFINE INPUT  PARAMETER pArq AS CHARACTER   NO-UNDO.
    ASSIGN cArqInsertSql = pArq.

END PROCEDURE.

PROCEDURE _gerarInsertSqlite:
    DEFINE VARIABLE lSegue       AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE cmdValues    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cmdFinal     AS CHARACTER   NO-UNDO.
    OUTPUT TO VALUE(cArqInsertSql) CONVERT TARGET "UTF-8".
    PUT 'PRAGMA synchronous = OFF;' SKIP
        'PRAGMA journal_mode = MEMORY;' SKIP
        'BEGIN TRANSACTION;' SKIP .



    RUN _gerarCpsInsertSqlite.
    REPEAT:                                                                                                                                               
      hQuery:GET-NEXT().                                                                                                                                  
      IF hQuery:QUERY-OFF-END THEN LEAVE.                                                                                                                 
      RUN verificarCondBreak(hQuery, OUTPUT lSegue).
      IF lSegue = NO THEN NEXT.
      ASSIGN cmdValues = ''.
      FOR EACH ttTabelas:
          /*MESSAGE ttTabelas.campos
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
          REPEAT iCont2 = 1 TO num-entries(ttTabelas.campos,","):                                                                                                      
            ASSIGN cCampo = ENTRY(iCont2,ttTabelas.campos,",").
            RUN getVlCp.
            IF cVlCampo = ? THEN
               ASSIGN cVlCampo =  "NULL" .
                      
            RUN incrValor(INPUT-OUTPUT cmdValues, "'" + cvlCampo  + "'" , "," ).
          END.          

          ASSIGN cmdFinal = cmdSqlite + " values(" + cmdvalues + ");" .
          /*MESSAGE 'tb-cps:' cmdSqlite SKIP
                  'values:' cmdValues SKIP
                  'cmdfinal:' cmdFinal           
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
          PUT UNFORM cmdFinal SKIP.
      END.                                                             
      PUT SKIP.
    END. 
    PUT 'END TRANSACTION;' SKIP.
    OUTPUT CLOSE.
END PROCEDURE.


PROCEDURE _gerarInsertPostgreSQL:
    DEFINE VARIABLE lSegue       AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE cmdValues    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cmdFinal     AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cTipo        AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCampoTipo   AS CHARACTER   NO-UNDO.

    
    
    OUTPUT TO VALUE(cArqInsertSql)  CONVERT SOURCE "ISO8859-1" TARGET "UTF-8".
   


    RUN _gerarCpsInsertPostgreSQL.
    REPEAT:                                                                                                                                               
      hQuery:GET-NEXT().                                                                                                                                  
      IF hQuery:QUERY-OFF-END THEN LEAVE.                                                                                                                 
      RUN verificarCondBreak(hQuery, OUTPUT lSegue).
      IF lSegue = NO THEN NEXT.
      ASSIGN cmdValues = ''.
      FOR EACH ttTabelas:
          /*MESSAGE ttTabelas.campos
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
          REPEAT iCont2 = 1 TO num-entries(ttTabelas.campos,","):                                                                                                      
            ASSIGN cCampo = ENTRY(iCont2,ttTabelas.campos,",").
            RUN getVlCp.
            IF cVlCampo = ? THEN
               ASSIGN cVlCampo =  "NULL" .

            /*IF index(cCampo,"[") > 0 THEN
               ASSIGN cCampoTipo = ENTRY(1,cCampo,"[").
            ELSE
               ASSIGN cCampoTipo = cCampo. */


            RUN getTipoCpTabela(ttTabelas.tabela,cCampo,OUTPUT cTipo).
            IF cTipo = 'decimal' THEN DO:
               ASSIGN cVlCampo = REPLACE(cVlCampo,",",".").
            END.
                      
            IF cVlCampo <> 'NULL' THEN
               RUN incrValor(INPUT-OUTPUT cmdValues, "'" + cvlCampo  + "'" , "," ).
            ELSE
               RUN incrValor(INPUT-OUTPUT cmdValues, cvlCampo   , "," ).

            

          END.          

          ASSIGN cmdFinal = cmdPostgreSQL + " values(" + cmdvalues + ");" .
          /*MESSAGE 'tb-cps:' cmdSqlite SKIP
                  'values:' cmdValues SKIP
                  'cmdfinal:' cmdFinal           
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
          PUT UNFORM cmdFinal SKIP.
      END.                                                             
      PUT SKIP.
    END. 
    //PUT 'END TRANSACTION;' SKIP.
    OUTPUT CLOSE.
END PROCEDURE.






PROCEDURE getHandleResult:
    DEFINE OUTPUT PARAMETER h AS HANDLE      NO-UNDO.
    ASSIGN h = hbTtResult.
END PROCEDURE.

PROCEDURE atribuirCampos:
     DEFINE VARIABLE iCont            AS INTEGER     NO-UNDO.
     //DEFINE VARIABLE cps              AS CHARACTER   NO-UNDO.
     DEFINE VARIABLE campoCorrente    AS CHARACTER   NO-UNDO.
     DEFINE VARIABLE campoCorrApelido AS CHARACTER   NO-UNDO.
     DEFINE VARIABLE campoCorrCp      AS CHARACTER   NO-UNDO.
     /*MESSAGE 'campos:' cCampos
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
     /*verifica se existe a clausula distinct*/
     ASSIGN lDistinct = index(cCampos,'distinct') > 0 .
     IF lDistinct THEN
        ASSIGN breakBy = " BREAK ".           
     ASSIGN qtCampos = NUM-ENTRIES(cCampos,",").
     REPEAT iCont = 1 TO qtCampos:
         ASSIGN campoCorrente = ENTRY(iCont,cCampos,",")
                campoCorrente = REPLACE(campoCorrente,' ','').
         IF iCont = 1 THEN DO:
            //retira o distinct
            IF INDEX(campoCorrente,'distinct') > 0 THEN
               ASSIGN campoCorrente = REPLACE(campoCorrente,'distinct','').
         END.                                                              
         /*verifica se existe apelido para o campo*/                                 
         IF INDEX(campoCorrente, ' as ') > 0 THEN DO:                                  
            ASSIGN campoCorrApelido = ENTRY(2,campoCorrente,"as")              
                   campoCorrCp      = ENTRY(1,campoCorrente,"as") .            
            RUN inserirApelidoCp(campoCorrCp, campoCorrApelido).                     
            ASSIGN lApelido = YES.
         END.                                                                        
         ELSE DO:                                                                    
            ASSIGN campoCorrApelido  = ''                                            
                   campoCorrCp       = campoCorrente.                                
         END.      
         /*MESSAGE 'campo final:'campoCorrCp
             VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
         IF lDistinct THEN
            RUN incrValor(INPUT-OUTPUT breakBy,campoCorrCp, " BY " ).

         RUN tratarApelidoTb(INPUT-OUTPUT cCamposTransf).

         RUN incrValor(INPUT-OUTPUT cCamposTransf,campoCorrCp,',' ). 
         RUN incrValor(INPUT-OUTPUT cCamposApelido,
                       IF campoCorrApelido <> '' THEN campoCorrApelido ELSE campoCorrCp,
                       ',' ). 
     END.
     IF logUnicaTb THEN DO:
        FIND FIRST ttTabelas NO-ERROR.
        IF AVAIL ttTabelas THEN
           ASSIGN ttTabelas.campos = cCamposTransf.

        /*MESSAGE 'campos:' cCamposTransf
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
     END.
     //ASSIGN cCamposTransf = cps.

END PROCEDURE.


PROCEDURE atribuirCondicao:

      IF logUnicaTb THEN DO:
       FIND FIRST ttTabelas NO-ERROR.
       IF AVAIL ttTabelas THEN
          ASSIGN ttTabelas.condicao = cCondicao.
    END.

END PROCEDURE.


PROCEDURE extrairTabelas:
    DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.
    DEFINE VARIABLE tb    AS CHARACTER FORMAT 'x(50)'  NO-UNDO.
    ASSIGN logUnicaTb = NUM-ENTRIES(cTabelas,",")  <= 1 .  // quando  for passado apenas uma tabela.



    /*MESSAGE 'tabela unica?' SKIP
     logUnicaTb  SKIP
     'entries:' NUM-ENTRIES(cTabelas,",") SKIP

    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/

    REPEAT iCont = 1 TO NUM-ENTRIES(cTabelas,","):
        ASSIGN tb = ENTRY(iCont,cTabelas,",").
        IF INDEX(tb, ' ') > 0  THEN DO:
           RUN inserirApelidoTb(ENTRY(1,tb,' '), //nome da tabela
                            ENTRY(2,tb,' ') // apelido
                            ).
        END.
        RUN inserirTabela(tb).
    END.                      
END PROCEDURE.

PROCEDURE inserirTabela:
    DEFINE INPUT  PARAMETER pTabela AS CHARACTER FORMAT 'x(50)'  NO-UNDO.
    /*MESSAGE 'tabela:' pTabela
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/

    CREATE ttTabelas.
    ASSIGN ttTabelas.tabela = pTabela.
    FIND ttBancoTabela
        WHERE ttBancoTabela.tabela = ttTabelas.tabela
        NO-ERROR.
    IF NOT AVAIL ttBancoTabela THEN DO:
       CREATE BUFFER ttTabelas.hBf FOR TABLE ttTabelas.tabela .
       IF VALID-HANDLE(ttTabelas.hBf) THEN
          ASSIGN ttTabelas.Banco = ttTabelas.hBf:DBNAME.
    END.
    ELSE DO:
        CREATE BUFFER ttTabelas.hBf FOR TABLE ttBancoTabela.banco + "." + ttTabelas.tabela .
        ASSIGN ttTabelas.banco = ttBancoTabela.banco.
    END.

    

    /*FOR EACH ttTabelas.
        MESSAGE 'tabela:' ttTabelas.tabela SKIP 
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        
    END.*/

END PROCEDURE.

PROCEDURE setBancoTabela:
    DEFINE INPUT  PARAMETER pTabela AS CHARACTER FORMAT 'x(50)'  NO-UNDO.
    DEFINE INPUT  PARAMETER pBanco  AS CHARACTER   NO-UNDO.
    CREATE ttBancoTabela.
    ASSIGN ttBancoTabela.banco   = pBanco
           ttBancoTabela.tabela  = pTabela.
END PROCEDURE.

PROCEDURE setListaCamposTabela:
    DEFINE INPUT  PARAMETER pTabela         AS CHARACTER FORMAT 'x(50)'  NO-UNDO.
    DEFINE INPUT  PARAMETER pListaCampos    AS CHARACTER FORMAT 'x(50)'   NO-UNDO.
    FIND FIRST ttTabelas
        WHERE ttTabelas.tabela = pTabela
        NO-ERROR.
    IF AVAIL ttTabelas THEN
       ASSIGN ttTabelas.campos = pListaCampos .
END PROCEDURE.


PROCEDURE setCondicaoTabela:
    DEFINE INPUT  PARAMETER pTabela     AS CHARACTER FORMAT 'x(50)'     NO-UNDO.
    DEFINE INPUT  PARAMETER pCondicao   LIKE ttTabelas.condicao   NO-UNDO.
    FIND FIRST ttTabelas
        WHERE ttTabelas.tabela = pTabela
        NO-ERROR.
    IF AVAIL ttTabelas THEN
       ASSIGN ttTabelas.condicao = pCondicao .
END PROCEDURE.



PROCEDURE incrCampoTabela:

    DEFINE INPUT  PARAMETER pTabela         AS CHARACTER FORMAT 'x(50)'  NO-UNDO.
    DEFINE INPUT  PARAMETER pCampo          AS CHARACTER FORMAT 'x(50)'   NO-UNDO.
    FIND FIRST ttTabelas
        WHERE ttTabelas.tabela = pTabela
        NO-ERROR.
    IF AVAIL ttTabelas THEN DO:
        RUN incrValor(INPUT-OUTPUT ttTabelas.campo,pCampo,",").
    END.
END PROCEDURE.

PROCEDURE getListaCamposTabela:

    DEFINE INPUT   PARAMETER pTabela         AS CHARACTER FORMAT 'x(50)'  NO-UNDO.
    DEFINE OUTPUT  PARAMETER pListaCampos    AS CHAR FORMAT 'x(300)'      NO-UNDO.
    FIND FIRST ttTabelas
        WHERE ttTabelas.tabela = pTabela
        NO-ERROR.
    IF AVAIL ttTabelas THEN
       ASSIGN pListaCampos = ttTabelas.campos .

END PROCEDURE.

PROCEDURE inserirApelidoCp:
    DEFINE INPUT  PARAMETER pCampo AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pApelido AS CHARACTER   NO-UNDO.

    FIND FIRST ttApelidosCp
        WHERE  ttApelidosCp.campo =  pCampo NO-ERROR.
    IF NOT AVAIL ttApelidosCp THEN DO:
       CREATE ttApelidosCp.
       ASSIGN ttApelidosCp.campo = pCampo .
    END.                                   
    ASSIGN ttApelidosCp.apelido = pApelido.

END PROCEDURE.


PROCEDURE inserirApelidoTb:
    DEFINE INPUT  PARAMETER pTabela  AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pApelido AS CHARACTER   NO-UNDO.

    FIND FIRST ttApelidosTb
        WHERE  ttApelidosTb.tabela =  pTabela NO-ERROR.
    IF NOT AVAIL ttApelidosTb THEN DO:
       CREATE ttApelidosTb .
       ASSIGN ttApelidosTb.tabela = pTabela .
    END.                                   
    ASSIGN ttApelidosTb.apelido = pApelido.

END PROCEDURE.


PROCEDURE tratarApelidoTb:

    DEFINE INPUT-OUTPUT PARAMETER cCampo  LIKE cCampos NO-UNDO.
    DEFINE VARIABLE cApelidoTb    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCampoPuro    AS CHARACTER   NO-UNDO.
    IF INDEX(cCampo,".") > 0 THEN DO:
       ASSIGN cApelidoTb = ENTRY(1,cCampo,'.')
              cCampoPuro = ENTRY(2,cCampo,'.').
       FIND FIRST ttApelidosTb
           WHERE ttApelidosTb.apelido = cApelidoTb NO-ERROR.
       IF AVAIL ttApelidosTb THEN
          ASSIGN cCampo = ttApelidosTb.tabela + "." + cCampoPuro.
    END.
END PROCEDURE.

PROCEDURE verificarCondBreak:
    DEFINE INPUT  PARAMETER hQuery AS HANDLE      NO-UNDO.
    DEFINE OUTPUT PARAMETER pSegue AS LOGICAL     NO-UNDO.
    /*DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.
    IF lDistinct THEN DO:
        REPEAT iCont = 1 TO qtCampos:
            IF  NOT hQuery:FIRST-OF(iCont) THEN DO:
                ASSIGN pSegue = NO.
                LEAVE.
            END.      
        END.          
    END.
    ELSE DO:
        ASSIGN pSegue = YES.
    END. */

    ASSIGN pSegue = hQuery:FIRST-OF(qtCampos).

END PROCEDURE.

PROCEDURE verifExist:

DEFINE OUTPUT  PARAMETER lExist AS LOGICAL     NO-UNDO.

ASSIGN lExist = hbTTREsult:FIND-FIRST("", NO-LOCK) NO-ERROR.



END PROCEDURE.



PROCEDURE _tratarCampoExtentPostGres:


    DEFINE INPUT-OUTPUT  PARAMETER pListaCps  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cNovaLista  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCampo      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cNovoCampo  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont       AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont2      AS INTEGER     NO-UNDO.
    DEFINE VARIABLE qtExtent    AS INTEGER     NO-UNDO.
    REPEAT iCont = 1 TO NUM-ENTRIES(pListaCps):
        ASSIGN cCampo = ENTRY(iCont,pListaCps).
        IF INDEX( cCampo,"[") > 0 THEN DO:
           //extrair a quantidade de extends
           ASSIGN qtExtent = INT(replace(ENTRY(2,cCampo,"["),"]","")).
           REPEAT iCont2 = 1 TO qtExtent:
               RUN incrValor(INPUT-OUTPUT cNovoCampo,ENTRY(1,cCampo,"[") + "_" + STRING(iCont2),",") .
           END.
        END.
        ELSE DO:
           ASSIGN cNovoCampo = cCampo.
        END.
        RUN incrValor(INPUT-OUTPUT cNovaLista,cNovoCampo,",").
    END.
    ASSIGN pListaCps = cNovaLista.




END PROCEDURE.

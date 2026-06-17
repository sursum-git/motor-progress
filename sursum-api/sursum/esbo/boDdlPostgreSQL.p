/***********************************************************************
programa: esbo/boDllpostgresql.p
objetivo: Gerar comandos de criaá∆o de tabelas no Postgresql
a partir de metadados do banco progress.
                                                                         
************************************************************************/

{esbo/boMetaDados.i}
{util.i}
DEFINE VARIABLE logIncrementar AS LOGICAL     NO-UNDO.
DEFINE VARIABLE cArquivo       AS CHARACTER   NO-UNDO.

DEFINE VARIABLE caracterOri     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE caracterSub     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lSubstCaracter  AS LOGICAL     NO-UNDO.
DEFINE VARIABLE iLimiteCpChar   AS INTEGER     NO-UNDO INIT 50.
DEFINE VARIABLE fatorMultiChar  AS DECIMAL     NO-UNDO INIT 3.

DEFINE BUFFER bfTtCampos FOR ttCampos.

FUNCTION _substCaracter RETURNS CHAR (texto AS CHAR):


    IF NOT lSubstCaracter THEN RETURN texto.
    ELSE DO:
        RETURN REPLACE(texto,caracterOri,caracterSub).
    END.



END FUNCTION.


PROCEDURE iniciar:

    ASSIGN iLimiteCpchar    = 50
           fatorMultiChar   = 3
           .
    
     
END PROCEDURE.


PROCEDURE finalizar:

    DELETE PROCEDURE THIS-PROCEDURE.

END PROCEDURE.



PROCEDURE setTtTabela:

DEFINE  INPUT PARAMETER TABLE FOR ttTabelas.

END PROCEDURE.

PROCEDURE setTtCampos:

DEFINE  INPUT PARAMETER TABLE FOR ttCampos.

END PROCEDURE.


PROCEDURE setTTIndices:

DEFINE  INPUT PARAMETER TABLE FOR ttIndices.

END PROCEDURE.

PROCEDURE setTTCpsIndice:

DEFINE  INPUT PARAMETER TABLE FOR ttCpsInd.

END PROCEDURE.

PROCEDURE setlogIncrementar:

DEFINE INPUT  PARAMETER pLog     AS LOGICAL     NO-UNDO.
ASSIGN  logIncrementar = pLog.                          

END PROCEDURE.


PROCEDURE setArquivo:

DEFINE INPUT  PARAMETER pArquivo AS CHARACTER   NO-UNDO.
ASSIGN  cArquivo       = pArquivo .

END PROCEDURE.


PROCEDURE setCaracterSubst:

    /******************************************************************************************************************
    caracter a ser substituido para nome de tabelas, campos, indices etc.
    normalmente substitui-se o "-"(hifen) pelo "_"(underline)
    *****************************************************************************************************************/

    DEFINE INPUT  PARAMETER pCaracterOri AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCaracterSub AS CHARACTER   NO-UNDO.

    ASSIGN caracterOri   = pCaracterOri
           caracterSub   = pCaracterSub
           lSubstCaracter = YES.

END PROCEDURE.


PROCEDURE setLimiteCampoChar:
    /******************************************************************************************************************
    acima deste tamanho o tipo do campo Ç convertido para TEXT
    *****************************************************************************************************************/

    DEFINE INPUT  PARAMETER pTamanho AS INTEGER     NO-UNDO.
    ASSIGN iLimiteCpChar = pTamanho.


END PROCEDURE.

PROCEDURE setFatorMultiChar:
   /******************************************************************************************************************
    muitas vezes Ç preciso aumentar o tamanho do campo devido a problemas com exceso de caracteres no progress
    esse fator multiplica o tamanho do campo do progress para que n∆o ocorra problema ao fazer a migraá∆o dos dados
    *****************************************************************************************************************/
    DEFINE INPUT  PARAMETER pTamanho AS decimal     NO-UNDO.
    ASSIGN fatorMultiChar = pTamanho.


END PROCEDURE.


PROCEDURE exec:

//variaveis chave estrangeira
DEFINE VARIABLE cTbPai      AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTbFilho    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cpPai       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cpFilho     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cListaPai   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cListaFilho AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cConstraint AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iQtRegs     AS INTEGER     NO-UNDO.
DEFINE VARIABLE iCont       AS INTEGER     NO-UNDO.
DEFINE VARIABLE cCamposInd  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE nomeCampo   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTipo       AS CHARACTER   NO-UNDO.

DEFINE VARIABLE campo   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cExtent AS CHARACTER   NO-UNDO.



IF logIncrementar THEN
   OUTPUT TO VALUE(cArquivo) APPEND.
ELSE
   OUTPUT TO VALUE(cArquivo).

FIND FIRST ttTabelas  NO-ERROR.
ASSIGN iCont = 0.
IF AVAIL ttTabelas THEN DO:
   PUT UNFORM "create table  IF NOT EXISTS " +  _substCaracter(ttTabelas.nome) + " ( " SKIP.
   FOR EACH ttCampos
       WHERE ttCampos.tabela = ttTabelas.nome
            AND   ttCampos.nome <> ''
            BY ttCampos.ordem BY ttCampos.nome .
       ASSIGN cCamposInd = ''.
       
       RUN getQtRegsTtCampos(OUTPUT iQtRegs).
       ASSIGN iCont = iCont + 1.
       RUN converterTipo(INPUT ttCampos.tipo,
                        INPUT ttCampos.formato,
                        INPUT ttCampos.qtDecimais,
                        OUTPUT cTipo).

       RUN extrairExtentCp(INPUT ttCampos.nome, OUTPUT campo, OUTPUT cExtent).
       PUT UNFORM '"' + trim(_substCaracter(campo)) + '" ' + cTipo + cExtent.
       IF iCont <> iQtRegs THEN DO:
         PUT  "," SKIP .
       END.
   END.
   FIND ttIndices
       WHERE recidIndex = ttTabelas.recidIndPri
       NO-ERROR.
   IF AVAIL ttIndices THEN DO:
      FOR EACH ttCpsInd
          WHERE ttCpsInd.indexRecid = ttIndices.recidIndex.
          
          RUN getNomeCampo(ttCpsInd.fieldRecid, OUTPUT nomeCampo).
          /*MESSAGE ttCpsInd.fieldRecid SKIP
              nomeCampo
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
          RUN incrValor(INPUT-OUTPUT cCamposInd," " + _substCaracter(nomeCampo) + " ",",") .
      END.
   IF cCamposInd <> '' THEN
         PUT UNFORMAT "," SKIP 'PRIMARY KEY(' +  cCamposInd  + ')'  SKIP.
   END.
    
   PUT ");" SKIP. 
  
   RUN exportarIndices.
END.
OUTPUT CLOSE.
END PROCEDURE.

PROCEDURE getQtRegsTTCpsInd:
    DEFINE OUTPUT PARAMETER iQt AS INTEGER     NO-UNDO.
    FOR EACH ttCpsInd FIELDS(nome).
        ASSIGN iQt =iQT + 1.
    END.

END PROCEDURE.



PROCEDURE getQtRegsTTCampos:
    DEFINE OUTPUT PARAMETER iQt AS INTEGER     NO-UNDO.
    
    FOR EACH bfTtCampos FIELDS(nome).
        ASSIGN iQt =iQT + 1.

    END.

END PROCEDURE.

 
PROCEDURE converterTipo:
    DEFINE INPUT  PARAMETER pTipo       AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pFormato    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pQtDecimais AS INTEGER     NO-UNDO.
    DEFINE OUTPUT PARAMETER cTipo       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cFormConv AS CHARACTER   NO-UNDO.
    RUN converterFormato(INPUT pTipo,
                         INPUT pFormato, 
                         INPUT pQtDecimais,
                         OUTPUT cFormConv).
    
    
    
    CASE pTipo:
      WHEN 'decimal' THEN DO:
          ASSIGN cTipo = 'numeric'
                 cTipo = cTipo + "(" + cFormCOnv + ")".
      END.
          
      WHEN 'character' THEN DO:
          IF cFormConv = '' THEN
             ASSIGN cFormConv = '30'.
          ELSE
             ASSIGN cFormConv = string(INT(cFormConv) * fatorMultiChar).
          IF INT(cFormConv) > iLimiteCpChar THEN
              ASSIGN cTipo = 'TEXT'.
          ELSE
              ASSIGN cTipo = 'character'
                     cTipo = cTipo +  "(" + cFormCOnv + ")".

      END.
          
      WHEN 'logical' THEN
          ASSIGN cTipo  = 'BOOLEAN'.

        WHEN 'datetime' THEN
          ASSIGN cTipo = 'timestamp without time zone'.
      OTHERWISE DO:
         ASSIGN cTipo = pTipo .
      END.
    END CASE.     
   

END PROCEDURE.

PROCEDURE converterFormato:
    DEFINE INPUT  PARAMETER pTipo       AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pformato    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pQtDecimais AS INTEGER     NO-UNDO.
    DEFINE OUTPUT PARAMETER cFormato    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE icont AS INTEGER     NO-UNDO.

    CASE pTipo:
        WHEN 'integer' THEN DO:
            ASSIGN pFormato = REPLACE(pFormato,",","")
                   iCont    = LENGTH(pFormato)
                   cFormato = STRING(iCont).

        END.
        WHEN 'character' THEN DO:
           IF SUBSTR(pFormato,1,1) = 'x' THEN DO:
              ASSIGN  cFormato = substr(pFormato,3,LENGTH(pFormato))
                      cFormato = REPLACE(cFormato,")",""). 
           END.
           ELSE
             ASSIGN cFormato = STRING(LENGTH(pFormato)).

        END.
        WHEN 'decimal' THEN DO:
            ASSIGN pFormato = ENTRY(1,pFormato,'.')
                   pFormato = REPLACE(pFormato,",","")
                   iCont    = LENGTH(pFormato) + pqtDecimais
                   cFormato = STRING(iCont) + "," + STRING(pQtDecimais).
        END.
        

    END CASE.


END PROCEDURE.


PROCEDURE getNomeCampo:
    DEFINE INPUT  PARAMETER  pRecid AS RECID NO-UNDO.
    DEFINE OUTPUT PARAMETER cDescr AS CHARACTER   NO-UNDO.

    FIND ttCampos
        WHERE ttCampos.numRecid = pRecid
        NO-ERROR.
    IF AVAIL ttCampos THEN
       ASSIGN cDescr = ttCampos.nome.



END PROCEDURE.


PROCEDURE extrairExtentCp:

    DEFINE INPUT  PARAMETER pCampo  AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cCampo  AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cExtent AS CHARACTER   NO-UNDO.
    
    DEFINE VARIABLE iLimite AS INTEGER     NO-UNDO.

    ASSIGN iLimite = INDEX(pCampo,"[").
    IF iLimite > 0 THEN  DO:
       ASSIGN cExtent = SUBSTR(pCampo,iLimite,LENGTH(pCampo))
              cCampo  = SUBSTR(pCampo,1,iLimite - 1) 
              .
    END.
    ELSE DO:
       ASSIGN cCampo   = pCampo
              cExtent  = '' .
    END.
      

END PROCEDURE.

PROCEDURE exportarIndices:

    DEFINE VARIABLE cListaCampos AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE campo        AS CHARACTER   NO-UNDO.

    /*{esp/exportarTabelacsv3.i ttIndices " " " " "  "ttIndices01" }
    {esp/exportarTabelacsv3.i ttCpsInd  " " " " "  "ttCpsInd01" }*/

    FOR EACH ttIndices:

       PUT UNFORM " CREATE INDEX   IF NOT EXISTS  " + "index_" + _substCaracter(ttTabelas.nome) + "_" +   _substCaracter(ttIndices.nome) + " ON " +  _substCaracter(ttTabelas.nome) + "(" .
       
       ASSIGN cListaCampos = ''.
       FOR EACH ttCpsInd 
           WHERE ttCpsInd.idIndice  = ttIndices.id .
           ASSIGN campo = _substCaracter(ttCpsInd.nome).
           RUN incrvalor(INPUT-OUTPUT cListaCampos,campo,",").        
       END.
       PUT UNFORM  cListaCampos + ");" SKIP.


   END.




END PROCEDURE.

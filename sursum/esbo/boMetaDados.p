/*
programa:esbo/boMetaDados.p
objetivo: Extrair as informaá‰es de metadados das tabelas como por exemplo: campos, tipos, listas de opá‰es etc, possibilitando
a construá∆o dinamica de extraá∆o de dados para exibiá∆o em diversas plataformas(api, 4gl etc) e para comparaá∆o de valores anteriores a atuais
*/
DEFINE VARIABLE cTabela AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cBanco  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCampos AS CHARACTER   NO-UNDO.

DEFINE VARIABLE iMetaTbRelacCorr AS INTEGER  NO-UNDO.

DEFINE NEW SHARED VARIABLE  drec_db AS Recid NO-UNDO.
DEFINE VARIABLE lAtualizaMeta AS LOGICAL     NO-UNDO.

DEFINE VARIABLE cBancoFiltro    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTabelaFiltro   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCampoFiltro    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDumpNameFiltro AS CHARACTER   NO-UNDO.
DEFINE VARIABLE retCpExtent     AS CHARACTER   NO-UNDO INIT "unico".
DEFINE VARIABLE lTbSys          AS LOGICAL     NO-UNDO.
DEFINE VARIABLE dtHrAlteracao   AS DATETIME    NO-UNDO.
DEFINE VARIABLE operadorDtHr    AS CHARACTER   NO-UNDO.
//DEFINE VARIABLE cOrdemCps       AS CHARACTER   NO-UNDO.

DEFINE VARIABLE logRetCp        AS LOGICAL     NO-UNDO.
DEFINE VARIABLE logRetInd       AS LOGICAL     NO-UNDO.
DEFINE VARIABLE logRetCpInd     AS LOGICAL     NO-UNDO.
DEFINE VARIABLE logTbDireto     AS LOGICAL     NO-UNDO.


DEFINE VARIABLE caracterOri         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE caracterSub         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lSubstCaracter      AS LOGICAL     NO-UNDO.

DEFINE VARIABLE fatorTamanhoTexto   AS DECIMAL     NO-UNDO.

DEFINE VARIABLE lMensagem AS LOGICAL     NO-UNDO.
DEFINE STREAM s0.

{esbo/boMetaDados.i}

DEFINE TEMP-TABLE ttTabelasAux NO-UNDO LIKE ttTabelas.



{util.i}

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

PROCEDURE setFatorMultiplFormatoTexto:

    DEFINE INPUT  PARAMETER pFator AS DECIMAL     NO-UNDO.

   ASSIGN fatorTamanhoTexto = pFator.



END PROCEDURE.

PROCEDURE setTabelasDireto:
    DEFINE INPUT PARAMETER TABLE FOR ttTbsDireto.
    ASSIGN logTbDireto = YES.

END PROCEDURE.
PROCEDURE setTabela:
    DEFINE INPUT  PARAMETER pTabela AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hTabela AS HANDLE      NO-UNDO.
    ASSIGN cTabela = pTabela.
    CREATE BUFFER hTabela FOR TABLE cTabela NO-ERROR.
    IF VALID-HANDLE(hTabela) THEN
       ASSIGN cBanco = hTabela:DBNAME.

END PROCEDURE.

PROCEDURE setBanco:
    DEFINE INPUT  PARAMETER pBanco AS CHARACTER   NO-UNDO.
    ASSIGN cBanco = pBanco.

END PROCEDURE.

PROCEDURE setCampos:

 DEFINE INPUT  PARAMETER pCampos AS CHARACTER   NO-UNDO.
 ASSIGN cCampos = pCampos.                              

END PROCEDURE.

PROCEDURE setTipoRetCpExtent:

    // opá∆o unico - deve ser utilizado quando for um retorno da estrutura da tabela
    // opá∆o extent - deve ser utilizado quando for um retorno em conjunto com os dados
    // opá∆o separado - deve ser utilizado quando for um retorno em conjunto com os dados e quiser colocar os  dados em campos separados que n∆o s∆o extent 

    DEFINE INPUT  PARAMETER pRet AS CHARACTER   NO-UNDO.

    ASSIGN retCpExtent = pRet .



END PROCEDURE.

PROCEDURE limparTTCampos:
    EMPTY TEMP-TABLE ttCampos.
    ASSIGN cCampos = ''.

END PROCEDURE.

PROCEDURE limparTTCpsInd:
    EMPTY TEMP-TABLE ttCPsInd.
END PROCEDURE.

PROCEDURE limparTTsIndices:
    EMPTY TEMP-TABLE ttIndices.  
    EMPTY TEMP-TABLE ttCpsInd.  
END PROCEDURE.

PROCEDURE getBancoTb:
    DEFINE OUTPUT  PARAMETER pBanco AS CHARACTER   NO-UNDO.
    ASSIGN pBanco = cBanco.

END PROCEDURE.

/*PROCEDURE setTipoRetCps:
    DEFINE INPUT  PARAMETER pTipo AS CHARACTER   NO-UNDO.
    CASE pTipo:
        WHEN 'ordem' THEN
            ASSIGN cOrdemCps = " BY _ORDER ".
        OTHERWISE
            ASSIGN cOrdemCps = "".
    END CASE.

END PROCEDURE.*/

PROCEDURE getCpsTb:
    //DEFINE VARIABLE cBanco      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hQueryMD    AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhFile      AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhField     AS HANDLE      NO-UNDO.
    
    DEFINE VARIABLE bh AS WIDGET-HANDLE   NO-UNDO EXTENT 2.
    DEFINE VARIABLE i AS INTEGER     NO-UNDO.
    
    
    DEFINE VARIABLE iDb         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont       AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iExtensoes  AS INTEGER     NO-UNDO.
    DEFINE VARIABLE hTabela     AS HANDLE      NO-UNDO.
    DEFINE VARIABLE condCp      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cmd         AS CHARACTER   NO-UNDO.
    
    

    IF cBanco = '' THEN DO:
       CREATE BUFFER hTabela FOR TABLE cTabela NO-ERROR.
       IF VALID-HANDLE(hTabela) THEN
          ASSIGN cBanco = hTabela:DBNAME.
       
    END.

    IF cBanco = '' THEN LEAVE.
    CREATE QUERY hQueryMD.
    CREATE BUFFER bhFile  FOR TABLE cBanco + '._file'.
    CREATE BUFFER bhField FOR TABLE cBanco + '._field'.
    IF cCampos <> '' THEN DO:
       ASSIGN condCp = ' where lookup(_field._field-name,cCampos) > 0' .
    END.
    ELSE 
      ASSIGN condCp = ''.
    /*hQueryMD:SET-BUFFERS(bhFile:HANDLE).*/
    hQueryMD:ADD-BUFFER(bhFile).
    hQueryMD:ADD-BUFFER(bhField).
    /*MESSAGE 'banco:' cBanco
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    ASSIGN cmd = 'for each ' + cBanco + '._file no-lock where _file-name ="' + cTabela + '" , each _field of _file no-lock ' + condCp  .
    /*MESSAGE cmd
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    
    hQueryMD:QUERY-PREPARE(cmd) NO-ERROR.
    
    REPEAT i = 1 TO hQuerymd:NUM-BUFFERS:
      bh[i] = hQuerymd:GET-BUFFER-HANDLE(i).
      /*MESSAGE bh`i`:NAME
          VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.      */
    END.

    
    /*hQueryMD:QUERY-PREPARE('for each _file no-lock  , each _field of _file no-lock ').*/
    hQueryMD:QUERY-OPEN.
    REPEAT:
      hQueryMD:GET-NEXT().
      IF hQueryMD:QUERY-OFF-END THEN LEAVE.

      /*IF  bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() = 'cd-origem' THEN
          ASSIGN  lMensagem = YES.
      ELSE
          ASSIGN lMensagem = NO.*/

      /*IF bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() = 'qt-faturada' THEN
         ASSIGN  lMensagem = YES.
      ELSE
         ASSIGN lMensagem = NO.
       */

      IF lMensagem THEN
          MESSAGE "CD-ORIGEM -> view-as" bhField:BUFFER-FIELD('_view-as'):BUFFER-VALUE()
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

       IF lMensagem THEN
          MESSAGE "CD-ORIGEM -> extent:" bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE() SKIP
                  bhField:BUFFER-FIELD('_field-name'):EXTENT
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
      

  
      IF(bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE() > 0) THEN DO:
        CASE retCpExtent:
            WHEN 'extent' THEN DO:

                DO iExtensoes = 1 TO bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE() :

                   ASSIGN iCont = iCont + 1.
                   RUN inserirTtCampos(INPUT iCont,
                                       INPUT bhField:BUFFER-FIELD('_label'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() + "[" + string(iExtensoes) + "]" ,
                                       INPUT bhField:BUFFER-FIELD('_data-type'):BUFFER-VALUE() ,
                                       INPUT bhField:BUFFER-FIELD('_format'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_Extent'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_view-as'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_order'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_mandatory'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_decimals'):BUFFER-VALUE() ,
                                       INPUT bhField:RECID).
                   //ASSIGN iExtensoes = iExtensoes + 1.
        
                   
                END.
            END.
            WHEN 'unico' THEN DO:
                 RUN inserirTtCampos(INPUT iCont,
                                     INPUT bhField:BUFFER-FIELD('_label'):BUFFER-VALUE(),
                                     INPUT bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() + "[" + bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE() + "]" ,
                                     INPUT bhField:BUFFER-FIELD('_data-type'):BUFFER-VALUE() ,
                                     INPUT bhField:BUFFER-FIELD('_format'):BUFFER-VALUE(),
                                     INPUT bhField:BUFFER-FIELD('_Extent'):BUFFER-VALUE(),
                                     INPUT bhField:BUFFER-FIELD('_view-as'):BUFFER-VALUE(),
                                     INPUT bhField:BUFFER-FIELD('_order'):BUFFER-VALUE(),
                                     INPUT bhField:BUFFER-FIELD('_mandatory'):BUFFER-VALUE(),
                                     INPUT bhField:BUFFER-FIELD('_decimals'):BUFFER-VALUE() ,
                                     INPUT bhField:RECID).

            END.
            WHEN 'separado' THEN DO:

                DO iExtensoes = 1 TO bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE() :

                   ASSIGN iCont = iCont + 1.
                   RUN inserirTtCampos(INPUT iCont,
                                       INPUT bhField:BUFFER-FIELD('_label'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() + "_" + string(iExtensoes),
                                       INPUT bhField:BUFFER-FIELD('_data-type'):BUFFER-VALUE() ,
                                       INPUT bhField:BUFFER-FIELD('_format'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_Extent'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_view-as'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_order'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_mandatory'):BUFFER-VALUE(),
                                       INPUT bhField:BUFFER-FIELD('_decimals'):BUFFER-VALUE() ,
                                       INPUT bhField:RECID).
                   //ASSIGN iExtensoes = iExtensoes + 1.
        
                   
                END.
            END.


        END CASE.   
      END.
      ELSE DO :
         ASSIGN iCont = iCont + 1.
         IF lMensagem THEN
            MESSAGE 'vou criar o campo'
                VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
         RUN inserirTtCampos(INPUT iCont,
                             INPUT bhField:BUFFER-FIELD('_label'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() ,
                             INPUT bhField:BUFFER-FIELD('_data-type'):BUFFER-VALUE() ,
                             INPUT bhField:BUFFER-FIELD('_format'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_Extent'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_View-as'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_order'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_mandatory'):BUFFER-VALUE(), 
                             INPUT bhField:BUFFER-FIELD('_decimals'):BUFFER-VALUE(),
                             INPUT bhField:RECID).    
         
      END.      
    END.
    hQueryMD:QUERY-CLOSE().
    bhFile:BUFFER-RELEASE().
    bhField:BUFFER-RELEASE().
    DELETE OBJECT hQueryMD.
    DELETE OBJECT bhFile.
    DELETE OBJECT bhField.

END PROCEDURE.



PROCEDURE getTTCps:
    /*FOR EACH ttCampos:
        DISP ttCampos.nome.
    END.*/

    DEFINE OUTPUT PARAMETER TABLE FOR ttCampos.


END PROCEDURE.
PROCEDURE getTTsIndices:
    DEFINE OUTPUT PARAMETER TABLE FOR ttIndices.
    DEFINE OUTPUT PARAMETER TABLE FOR ttCpsInd.
END PROCEDURE.


PROCEDURE inserirTTCampos:
    DEFINE INPUT  PARAMETER pId             AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pLabel          AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pNome           AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTipo           AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pFormato        AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pExtensao       AS INT         NO-UNDO.
    DEFINE INPUT  PARAMETER cLista          LIKE ttCampos.lista  NO-UNDO.
    DEFINE INPUT  PARAMETER pOrdem          AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pObrigatorio    AS LOGICAL     NO-UNDO.
    DEFINE INPUT  PARAMETER pQtDecimais     AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pRecid          AS RECID       NO-UNDO.

    IF lMensagem THEN
       MESSAGE "Lista Dentro do inserirTTcampos " cLista SKIP
             'banco:' cBanco
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

    /*MESSAGE STRING(pRecid)
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    
    CREATE ttCampos.
    ASSIGN 
    ttCampos.id                 = pID
    ttCampos.labelCampo         = pLabel
    ttCampos.nome               = pNome
    ttCampos.tipo               = pTipo
    ttCampos.formato            = pFormato
    ttCampos.extensao           = pExtensao
    ttCampos.lista              = cLista 
    ttCampos.ordem              = pOrdem
    ttCampos.obrigatorio        = pObrigatorio
    ttCampos.qtDecimais         = pQtDecimais 
    ttCampos.tabela             = cTabela
    ttCampos.banco              = cBanco
    ttCampos.numRecid           = pRecid .
     
    IF index(cBanco,'ems5') = 0 THEN DO:
       IF lMensagem THEN
          MESSAGE 'vou extrair a lista'
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
       RUN extrairLista(INPUT cLista, OUTPUT ttCampos.lista).
    END.                               
    ELSE DO:
       IF lMensagem THEN
          MESSAGE 'vou extrair a lista ems5'
              VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
       RUN extrairListaEms5(INPUT cLista, OUTPUT ttCampos.lista ).
    END.
       

END PROCEDURE.


PROCEDURE inserirTtIndices:

     
     DEFINE INPUT-OUTPUT    PARAMETER pCont              AS INT NO-UNDO.
     DEFINE INPUT           PARAMETER pRecidFile         AS RECID NO-UNDO.
     DEFINE INPUT           PARAMETER pNome              AS CHARACTER   NO-UNDO.
     DEFINE INPUT           PARAMETER pUnique            AS LOGICAL     NO-UNDO.
     DEFINE INPUT           PARAMETER pActive            AS LOGICAL     NO-UNDO.
     DEFINE INPUT           PARAMETER pWordIdx           AS INTEGER     NO-UNDO.
     DEFINE INPUT           PARAMETER pidxCRC            AS INTEGER     NO-UNDO.
     DEFINE INPUT           PARAMETER pdtHrUltAlteracao  AS DATETIME    NO-UNDO.
     DEFINE INPUT           PARAMETER pWordRules         AS CHARACTER   NO-UNDO.
     DEFINE INPUT           PARAMETER pRecidIndex        AS RECID       NO-UNDO.
     DEFINE INPUT           PARAMETER precidPriIndex     AS RECID       NO-UNDO.
     ASSIGN pCont = pCont + 1.
     FIND  ttIndices
     WHERE ttIndices.nome = pNome      NO-ERROR.
     IF NOT AVAIL ttIndices THEN DO:
        CREATE ttIndices.
        ASSIGN ttIndices.id              = pCont
               ttIndices.recidFile       = pRecidFile
               ttIndices.nome            = pNome
               ttIndices.logUnico        = pUnique
               ttIndices.logAtivo        = pActive
               ttIndices.wordIdx         = pWordIdx
               ttIndices.idxCRC          = pIdxCRC
               ttIndices.dtHrUltAlteracao = pdtHrUltAlteracao
               ttIndices.wordRules       = pWordRules
               ttIndices.recidIndex      = pRecidIndex 
               ttIndices.logPrimario     = pRecidPriIndex = pRecidIndex  .
        
         
     END. 
     


END PROCEDURE.

PROCEDURE inserirTtCpsIndice:
    DEFINE INPUT  PARAMETER pCont2              AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pCont               AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pIndexRecid         AS RECID       NO-UNDO.
    DEFINE INPUT  PARAMETER pIndexSeq           AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pFieldRecid         AS RECID       NO-UNDO.
    DEFINE INPUT  PARAMETER pUnsorted           AS LOGICAL     NO-UNDO.
    DEFINE INPUT  PARAMETER pAscending          AS LOGICAL     NO-UNDO.
    DEFINE INPUT  PARAMETER pAbbreviate         AS LOGICAL     NO-UNDO.
    DEFINE INPUT  PARAMETER pdtHrUltAlteracao   AS DATETIME    NO-UNDO.

    FIND FIRST ttCampos
        WHERE ttCampos.numRecid = pFieldRecid
        NO-ERROR.
    CREATE ttCpsInd.
    ASSIGN ttCpsInd.id               = pCont2
           ttCpsInd.idIndice         = pCont
           ttCpsInd.indexSeq         = pIndexSeq
           ttCpsInd.fieldRecid       = pFieldrecid
           ttCpsInd.logUnsorted      = pUnsorted
           ttCpsInd.logAscending     = pAscending
           ttCpsInd.logAbbreviate    = pAbbreviate
           ttCpsInd.dtHrUtlAlteracao = pDtHrUltAlteracao
           ttCpsInd.indexRecid       = pIndexRecid 
           ttCpsInd.nome             = IF AVAIL ttCampos THEN ttCampos.nome ELSE '' 
           ttCpsInd.tipo             = IF AVAIL ttCampos THEN ttCampos.tipo ELSE ''    
           .  
   /*MESSAGE  pIndexRecid SKIP
            ttCpsInd.nome
   VIEW-AS ALERT-BOX INFORMATION BUTT*/
                  
    
    

END PROCEDURE.


PROCEDURE extrairLista:
    DEFINE INPUT  PARAMETER cLista      AS CHARACTER   NO-UNDO FORMAT 'x(200)'.
    DEFINE OUTPUT PARAMETER cRetorno    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cInclude            AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont               AS INTEGER     NO-UNDO.
    DEFINE VARIABLE lTemInclude         AS LOGICAL     NO-UNDO.
    
    
    ASSIGN lTemInclude = index(cLista,'.i') > 0 AND (INDEX(cLista,'02') > 0 OR INDEX(cLista,'2')> 0 ).              
    IF lMensagem THEN
       MESSAGE "tem include:"  lTemInclude
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
    IF cLista <> '' AND cLista <> ? AND lTemInclude THEN DO:   
       ASSIGN cInclude = ENTRY(2,cLista,"~{")
            cInclude = ENTRY(1,cInclude,".i")
            cInclude = cInclude + ".i 3" .  
       
       RUN esp/include_dinamica.i cInclude . 
       ASSIGN cRetorno = RETURN-VALUE.
    END.
    ELSE DO:
       ASSIGN cRetorno = IF cLista = ? OR cLista = '?' THEN  '' ELSE cLista.
    END.

    IF INDEX(cRetorno,'toggle-box') > 0  THEN
       ASSIGN cRetorno = ''.
    IF INDEX(cRetorno,'editor')  > 0 THEN
       ASSIGN cRetorno = '' .
   IF lMensagem THEN
   MESSAGE 'lista:' cLista SKIP
            'retorno:' cRetorno 
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.


END PROCEDURE.

PROCEDURE extrairListaEms5:
    DEFINE INPUT  PARAMETER cLista      AS CHARACTER   NO-UNDO FORMAT 'x(200)'.
    DEFINE OUTPUT PARAMETER cRetorno    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cInclude            AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont               AS INTEGER     NO-UNDO.
    DEFINE VARIABLE lTemLista           AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE cListaFinal         AS CHARACTER   NO-UNDO.
    
   
    ASSIGN lTemLista  = index(cLista,'list-item') > 0 .
    IF cLista <> '' AND cLista <> ? AND lTemLista THEN DO:       
       ASSIGN cRetorno = ENTRY(1,cLista,"/")
              cRetorno = REPLACE(cRetorno,ENTRY(1,cRetorno,'"'),"")
              cRetorno = REPLACE(cRetorno,'"','').

       REPEAT iCont = 1 TO NUM-ENTRIES(cRetorno):

           /*ASSIGN iCont = IF iCont > 1 THEN iCont  - 1 ELSE iCont
                  iCont = iCont * 2.*/
           /*IF iCont <= NUM-ENTRIES(cRetorno,'"') THEN*/
           RUN incrValor(INPUT-OUTPUT cListaFinal,ENTRY(iCont,cRetorno),",").
       END.
       ASSIGN cRetorno = cListaFinal.
    END.
    ELSE DO:
       ASSIGN cRetorno = cLista.
    END.
    IF INDEX(cRetorno,'toggle-box') > 0  THEN
       ASSIGN cRetorno = ''.
    IF INDEX(cRetorno,'editor')  > 0 THEN
       ASSIGN cRetorno = '' .

    IF cRetorno = ? OR cRetorno = '?' THEN
       ASSIGN cRetorno = ''.
END PROCEDURE.



PROCEDURE getBanco:
    DEFINE OUTPUT PARAMETER pBanco AS CHARACTER   NO-UNDO.
    ASSIGN pBanco = cBanco.

END PROCEDURE.
/*    
PROCEDURE inserirMetaTbRelac:

    DEFINE INPUT  PARAMETER pTb01   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTb02   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCampos AS CHARACTER   NO-UNDO.
    /*MESSAGE pTb01 SKIP
            pTb02 SKIP
            pCampos SKIP
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    FIND meta_tb_relacs
        WHERE meta_tb_relacs.cod_tb_01 = pTb01
        AND   meta_tb_relacs.cod_tb_02 = pTb02
        NO-LOCK NO-ERROR.
    IF AVAIL meta_tb_relacs AND lAtualizaMeta = YES THEN DO:
       FIND CURRENT meta_tb_relacs EXCLUSIVE-LOCK NO-ERROR.
       DELETE meta_tb_relacs.                    
    END.
    IF NOT AVAIL meta_tb_relacs THEN DO:
        /*MESSAGE 'meta tb relacs' SKIP
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/


       CREATE meta_tb_relacs.
       ASSIGN meta_tb_relacs.cod_tb_01         = pTb01 
              meta_tb_relacs.cod_tb_02         = pTb02
              meta_tb_relacs.cps_of            = pCampos
              meta_tb_relacs.dt_hr_registro    = NOW
              meta_tb_relacs.meta_tb_relac_id  = NEXT-VALUE(seq_meta_tb_relac)
              iMetaTbRelacCorr                 = meta_tb_relacs.meta_tb_relac_id .
    END.     

END PROCEDURE.

PROCEDURE inserirMetaTbRelacOF:

    DEFINE INPUT  PARAMETER pTb01   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTb02   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCampos AS CHARACTER   NO-UNDO.

    RUN inserirMetaTbRelac(INPUT pTb01, 
                           INPUT pTb02,
                           INPUT pCampos).




END PROCEDURE.
*/
PROCEDURE limparTtCpsMeta:

    EMPTY TEMP-TABLE ttCpsMeta .

END PROCEDURE.

PROCEDURE inserirTtCpMeta:

    DEFINE INPUT  PARAMETER pCp01 AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCp02 AS CHARACTER   NO-UNDO.

    CREATE ttCpsMeta.
    ASSIGN ttCpsMeta.cp1 = pCp01 
           ttCpsMeta.cp2 = pCp02 .



END PROCEDURE.
/*
PROCEDURE inserirMetaCpRelac:

    DEFINE INPUT  PARAMETER pCp01 AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCp02 AS CHARACTER   NO-UNDO.

    CREATE meta_cp_relacs.
    ASSIGN meta_cp_relacs.meta_tb_relac_id = iMetaTbRelacCorr 
           meta_cp_relacs.cod_cp_01        = pCp01
           meta_cp_relacs.cod_cp_02        = pCp02 
           meta_cp_relacs.dt_hr_registro   = NOW.


END PROCEDURE.
*/


PROCEDURE inserirMetaTbRelacInf:

    DEFINE INPUT  PARAMETER pTb01   AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTb02   AS CHARACTER   NO-UNDO.

    RUN inserirMetaTbRelac(INPUT pTb01, 
                           INPUT pTb02,
                           INPUT '').
    RUN associarTtCpMeta.
    RUN limparTtCpsMeta.

END PROCEDURE.

PROCEDURE associarTtCpMeta:

    FOR EACH ttCpsMeta:

        RUN inserirMetaCprelac(ttCpsMeta.cp1 , 
                               ttCpsMeta.cp2 ).
    END.

END PROCEDURE.


PROCEDURE criarRelacsOf:

    DEFINE INPUT  PARAMETER pAtualiza AS LOGICAL     NO-UNDO.
    ASSIGN lAtualizaMeta = pAtualiza.

    DELETE ALIAS dictdb.
    CREATE ALIAS dictdb FOR DATABASE VALUE(cBanco).
    FIND FIRST DICTDB._Db NO-LOCK.
    ASSIGN drec_db = RECID(DICTDB._Db).
    EMPTY TEMP-TABLE ttRelacs.
    RUN esp/getRelacs.p(drec_db,cTabela,OUTPUT TABLE ttRelacs).
    FOR EACH ttRelacs:
        //RUN inserirMetaTbRelacOF(ttRelacs.tb01,ttRelacs.tb02,ttRelacs.campos ).
    END.
    
END PROCEDURE.

PROCEDURE getBancoRelac:

    DEFINE INPUT  PARAMETER pBanco AS CHARACTER     NO-UNDO.
    DEFINE OUTPUT PARAMETER bdsRelac AS CHARACTER   NO-UNDO.

    DEFINE VARIABLE hBoArqIni      AS HANDLE        NO-UNDO.
    DEFINE VARIABLE cArqIni        AS CHARACTER     NO-UNDO.
    RUN esbo/boArqIni.p PERSISTENT SET hBoArqIni.
    ASSIGN cArqIni =  SEARCH('bd.ini').
    IF cArqIni <> ? THEN DO:
       RUN setArquivoIni IN hBoArqIni(cArqIni).                                    
       RUN getDados IN hBoArqIni.                                                        
       RUN getVlChave IN hBoArqIni(trim(pBanco), OUTPUT bdsRelac).

    END.


END PROCEDURE.


PROCEDURE setFiltrosTb:
    DEFINE INPUT  PARAMETER pChave AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pValor AS CHARACTER   NO-UNDO.

    CASE pChave:
        WHEN 'banco' THEN DO:
           ASSIGN cBancoFiltro = pValor.
        END.
        WHEN 'tabela' THEN DO:
           ASSIGN cTabelaFiltro = pValor.
        END.
        WHEN 'campo' THEN DO:
           ASSIGN cCampoFiltro = pValor.
        END.
        WHEN 'dump_name' THEN DO:
           ASSIGN cDumpNameFiltro = pValor.
        END.
        WHEN 'dt_hr_alteracao' THEN DO:
           ASSIGN dtHrAlteracao = datetime(pValor).
        END.
        WHEN 'mostrar_tbs_sys' THEN DO:
           ASSIGN lTbSys = LOGICAL(pValor).

        END.
        WHEN 'operador_dt_hr' THEN DO:
           ASSIGN operadorDtHr = pValor.
        END.
        


    END CASE.


END PROCEDURE.

PROCEDURE limparFiltros:

ASSIGN cBancoFiltro     = ''
       cTabelaFiltro    = ''
       cCampoFiltro     = ''
       cDumpNameFiltro  = ''
       dtHrAlteracao    = ?
       lTbSys           = NO
       operadorDtHr     = ''.

END PROCEDURE.


PROCEDURE getDadosTbsDireto:
    /*
    para utilizar este metodo È preciso antes chamar os metodo
    setbanco e setTbsDireto
    */
    /*DEFINE INPUT  PARAMETER pBanco  AS CHARACTER   NO-UNDO.*/
    DEFINE VARIABLE iDb             AS INTEGER     NO-UNDO.
    DEFINE VARIABLE bhFile          AS HANDLE      NO-UNDO.
    DEFINE VARIABLE hQueryMD        AS HANDLE      NO-UNDO.
    DEFINE VARIABLE cmd             AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE lastChange      AS INTEGER     NO-UNDO.
    DEFINE VARIABLE dtHrLastChange  AS DATETIME    NO-UNDO.
    DEFINE VARIABLE condTbs         AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cBancoCor       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cTermo AS CHARACTER   NO-UNDO.

    EMPTY TEMP-TABLE ttTabelas.

    FOR EACH TTTbsDireto:
        ASSIGN cTermo = " _file-name ='" + trim(ttTbsDireto.tabela) + "'".
        RUN incrvalor(INPUT-OUTPUT condTbs,
                      INPUT cTermo,
                      INPUT " or ").
       /* MESSAGE condTbs
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    END.
    IF condTbs <> '' THEN
       ASSIGN condTbs = "(" + condTbs + ")".
    ELSE 
      ASSIGN condTbs = " 1 = 0 ".

    REPEAT iDB = 1 TO NUM-DBS:
        ASSIGN cBancoCor = LDBNAME(iDB).
        IF cBancoFiltro <> '' THEN
           IF cBancoCor <> cBancoFiltro THEN NEXT.
        CREATE QUERY hQueryMD.
        CREATE BUFFER bhFile  FOR TABLE cBancoCor + '._file'.
        ASSIGN cmd = 'for each ' + cBancoCor + '._file where ' + condTbs. 
        hQueryMD:ADD-BUFFER(bhFile). 
        hQueryMD:QUERY-PREPARE( cmd ) .
        hQueryMD:QUERY-OPEN. 
        REPEAT:
            hQueryMD:GET-NEXT().
            IF hQueryMD:QUERY-OFF-END THEN LEAVE.
            ASSIGN lastChange = bhFile:BUFFER-FIELD('_Last-change'):BUFFER-VALUE().
            RUN convertUnixTimeStamp(lastChange,OUTPUT dtHrLastChange).
    
            RUN _inserirTTTabelas(
            INPUT cBancoCor,
            INPUT bhFile:BUFFER-FIELD('_file-name'):BUFFER-VALUE(),
            INPUT bhfile:BUFFER-FIELD('_DESC'):BUFFER-VALUE(),
            INPUT bhFile:BUFFER-FIELD('_Dump-name'):BUFFER-VALUE(),
            INPUT bhFile:recid,
            INPUT dtHrLastChange,
            INPUT lastChange,
            INPUT bhFile:BUFFER-FIELD('_prime-index'):BUFFER-VALUE()
            ).    
        END.
    END.
    /*MESSAGE cmd
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    
    hQueryMD:QUERY-CLOSE().
    bhFile:BUFFER-RELEASE().
    DELETE OBJECT hQueryMD.
    DELETE OBJECT bhFile.

END PROCEDURE.

PROCEDURE getTbs:
    DEFINE OUTPUT PARAMETER TABLE FOR ttTabelas.
    DEFINE VARIABLE iDb             AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cBancoCor       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE bhFile          AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhField         AS HANDLE      NO-UNDO.
    DEFINE VARIABLE hQueryMD        AS HANDLE      NO-UNDO.
    DEFINE VARIABLE cmd             AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cmdField        AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE operadorTb      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE operadorCp      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cRetorno        AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE operadorPrinc   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE lastChange      AS INTEGER     NO-UNDO.
    DEFINE VARIABLE tempoLastChange AS INTEGER     NO-UNDO.
    //DEFINE VARIABLE dtLastChange    AS DATE        NO-UNDO.
    DEFINE VARIABLE dtHrLastChange  AS DATETIME    NO-UNDO.

    EMPTY TEMP-TABLE ttTabelas.

    REPEAT iDB = 1 TO NUM-DBS:
        ASSIGN cBancoCor = LDBNAME(iDB).
        IF cBancoFiltro <> '' THEN
           IF cBancoCor <> cBancoFiltro THEN NEXT.

        CREATE QUERY hQueryMD.
        CREATE BUFFER bhFile  FOR TABLE cBancoCor + '._file'.
        CREATE BUFFER bhField FOR TABLE cBancoCor + '._field'.

        hQueryMD:ADD-BUFFER(bhFile). 
        

        ASSIGN cmd = 'for each ' + cBancoCor 
                               + '._file no-lock '.
        ASSIGN operadorPrinc = " WHERE ".

        // esconde as tabelas de sistema conforme filtros
        IF NOT lTbSys  THEN DO:
           RUN incrValor(INPUT-OUTPUT cmd, ' (_Tbl-type<> "V" and _Tbl-type <> "S")',operadorPrinc).
           ASSIGN operadorPrinc = " AND " .
        END.
            



        RUN _tratarFiltroChar(cTabelaFiltro, OUTPUT cRetorno).
        IF cRetorno <> '' THEN DO:
           RUN incrValor(INPUT-OUTPUT cmd,"_file-name " + cRetorno, operadorPrinc).
           ASSIGN operadorPrinc = " AND ".
        END.
           

        
        RUN _tratarFiltroChar(cDumpNameFiltro, OUTPUT cRetorno).
        IF cRetorno <> '' THEN DO:
           RUN incrValor(INPUT-OUTPUT cmd,"_dump-name " + cRetorno, operadorPrinc).
           ASSIGN operadorPrinc = " AND ".
        END.
           

        IF cCampoFiltro <> '' THEN DO:
           ASSIGN cmdField = " , each _field of _file no-lock "
                  operadorPrinc = " WHERE " .
           hQueryMD:ADD-BUFFER(bhField).
           
           RUN _tratarFiltroChar(cCampoFiltro, OUTPUT cRetorno).
           IF cRetorno <> '' THEN DO:
              RUN incrValor(INPUT-OUTPUT cmdField,"_field-name " + cRetorno, operadorPrinc).
              ASSIGN operadorPrinc = " AND " .
           END.
              

           IF cmdField <> '' THEN
              RUN incrValor(INPUT-OUTPUT cmd,cmdField, " ").


        END.

        /*MESSAGE cmd
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
        hQueryMD:QUERY-PREPARE( cmd ) NO-ERROR.
        hQueryMD:QUERY-OPEN. 
        REPEAT:
            hQueryMD:GET-NEXT().
            IF hQueryMD:QUERY-OFF-END THEN LEAVE.
            ASSIGN lastChange = bhFile:BUFFER-FIELD('_Last-change'):BUFFER-VALUE().
            RUN convertUnixTimeStamp(lastChange,OUTPUT dtHrLastChange).

            IF dtHrAlteracao <> ? THEN DO:
               CASE operadorDtHr:
                   WHEN '1' THEN //maior que
                       IF dtHrAlteracao >= dtHrLastChange THEN NEXT.
                   WHEN '2' THEN  //menor que
                       IF dtHrAlteracao <= dtHrLastChange THEN NEXT.
               END CASE.
            END.
            RUN _inserirTTTabelas(
            INPUT cBancoCor,
            INPUT bhFile:BUFFER-FIELD('_file-name'):BUFFER-VALUE(),
            INPUT bhfile:BUFFER-FIELD('_DESC'):BUFFER-VALUE(),
            INPUT bhFile:BUFFER-FIELD('_Dump-name'):BUFFER-VALUE(),
            INPUT bhFile:recid,
            INPUT dtHrLastChange,
            INPUT lastChange,
            INPUT bhFile:BUFFER-FIELD('_prime-index'):BUFFER-VALUE()
            ).    
        END.
    END.
    hQueryMD:QUERY-CLOSE().
    bhFile:BUFFER-RELEASE().
    bhField:BUFFER-RELEASE().
    DELETE OBJECT hQueryMD.
    DELETE OBJECT bhFile.
    DELETE OBJECT bhField.

END PROCEDURE.

PROCEDURE _inserirttTabelas:
    DEFINE INPUT  PARAMETER pBanco          AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pNome           AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pDescricao      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pNomeDump       AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pRecid          AS RECID       NO-UNDO.
    DEFINE INPUT  PARAMETER pDtHrAlt        AS DATETIME    NO-UNDO.
    DEFINE INPUT  PARAMETER plastChange     AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pRecidIndPri    AS RECID       NO-UNDO.

   CREATE ttTabelas.                                                                      
   ASSIGN ttTabelas.banco          = pBanco            
          ttTabelas.nome           = pNome
          ttTabelas.descricao      = pDescricao        
          ttTabelas.nomeDump       = pNomeDump         
          ttTabelas.numRecid       = pRecid            
          ttTabelas.dtHrAlteracao  = pDtHrAlt          
          ttTabelas.lastChange     = plastChange       
          ttTabelas.recidIndPri    = pRecidIndPri   .  



END PROCEDURE.

PROCEDURE filtrarDtHrAlteracao:



END PROCEDURE.

PROCEDURE getBancos:

    DEFINE OUTPUT PARAMETER cListaBancos AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cBancoCor    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE idb          AS INTEGER     NO-UNDO.
    REPEAT iDB = 1 TO NUM-DBS:
        ASSIGN cBancoCor = LDBNAME(iDb) .
        RUN incrValor(INPUT-OUTPUT cListaBancos,cBancoCor,",").
    END.
    
END PROCEDURE.

PROCEDURE _tratarFiltroChar:

    DEFINE INPUT  PARAMETER cFiltro AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER cFiltroNovo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE operador  AS CHARACTER   NO-UNDO.



    IF cFiltro <> '' THEN DO:
       IF INDEX(cFiltro,"*") > 0 THEN DO:
          ASSIGN operador = " matches ".
       END.
       ELSE DO: 
         ASSIGN operador = " = ".
       END.         
       ASSIGN cFiltroNovo = operador + " '" + cFiltro  + "'".
    END.
    ELSE DO:
        ASSIGN cFiltroNovo = ''.
    END.


END PROCEDURE.

PROCEDURE getIndicesCpsTb:
//DEFINE VARIABLE cBanco      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hQueryMD    AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhFile      AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhInd       AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhIndField  AS HANDLE      NO-UNDO.   
    DEFINE VARIABLE cmd         AS CHARACTER   NO-UNDO.
    
    
    DEFINE VARIABLE iDb         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont       AS INTEGER     NO-UNDO INIT 0.
    DEFINE VARIABLE iCont2      AS INTEGER     NO-UNDO INIT 1.
    DEFINE VARIABLE iExtensoes  AS INTEGER     NO-UNDO.
    DEFINE VARIABLE hTabela     AS HANDLE      NO-UNDO.
    DEFINE VARIABLE condCp      AS CHARACTER   NO-UNDO.
    
    IF cBanco = '' THEN DO:
       CREATE BUFFER hTabela FOR TABLE cTabela NO-ERROR.
       IF VALID-HANDLE(hTabela) THEN
          ASSIGN cBanco = hTabela:DBNAME.
       
    END.

    IF cBanco = '' THEN LEAVE.
    CREATE QUERY hQueryMD.
    CREATE BUFFER bhFile     FOR TABLE cBanco + '._file'.
    CREATE BUFFER bhInd      FOR TABLE cBanco + '._index'.
    CREATE BUFFER bhIndField FOR TABLE cBanco + '._index-field'.
    
    
    hQueryMD:SET-BUFFERS(bhFile).
    hQueryMD:ADD-BUFFER(bhInd).
    hQueryMD:ADD-BUFFER(bhIndField).
    ASSIGN cmd = 'for each ' + cBanco + '._file no-lock where _file-name ="' + cTabela + '" , each _index of _file no-lock, each _index-field of _index '.
    /*MESSAGE 'cps ind:' cmd
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    hQueryMD:QUERY-PREPARE(cmd) NO-ERROR.
    /*hQueryMD:QUERY-PREPARE('for each _file no-lock  , each _field of _file no-lock ').*/
    hQueryMD:QUERY-OPEN.
    REPEAT:
      hQueryMD:GET-NEXT().
      IF hQueryMD:QUERY-OFF-END THEN LEAVE.
     /* IF bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() = 'ind_orig_tit_acr' THEN
      MESSAGE     'view-as:' bhField:BUFFER-FIELD('_View-as'):BUFFER-VALUE() SKIP
             VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/                             
      
      /*MESSAGE 'indice:' bhInd:BUFFER-FIELD('_index-name'):BUFFER-VALUE()  SKIP
          'contador:' iCont SKIP
          'contador2:' iCont2 SKIP*/

          //VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
      //contador campos indice
      
      

     RUN inserirTtIndices(INPUT-OUTPUT iCont,
                          INPUT bhInd:BUFFER-FIELD('_file-recid'):BUFFER-VALUE(),
                          INPUT bhInd:BUFFER-FIELD('_index-name'):BUFFER-VALUE() ,
                          INPUT bhInd:BUFFER-FIELD('_unique'):BUFFER-VALUE() ,
                          INPUT bhInd:BUFFER-FIELD('_active'):BUFFER-VALUE(),
                          INPUT bhInd:BUFFER-FIELD('_wordIdx'):BUFFER-VALUE(),                          
                          INPUT bhInd:BUFFER-FIELD('_idx-CRC'):BUFFER-VALUE(),                          
                          INPUT bhInd:BUFFER-FIELD('_last-modified'):BUFFER-VALUE(),                          
                          INPUT bhInd:BUFFER-FIELD('_word-rules'):BUFFER-VALUE(),                          
                          INPUT bhInd:RECID,
                          INPUT bhfile:BUFFER-FIELD('_prime-index'):BUFFER-VALUE
                          ).
       RUN inserirTtCpsIndice(INPUT iCont2,
                              INPUT iCont,
                              INPUT bhIndField:BUFFER-FIELD('_index-recid'):BUFFER-VALUE,
                              INPUT bhIndField:BUFFER-FIELD('_index-seq'):BUFFER-VALUE,
                              INPUT bhIndField:BUFFER-FIELD('_field-recid'):BUFFER-VALUE,
                              INPUT bhIndField:BUFFER-FIELD('_unsorted'):BUFFER-VALUE,
                              INPUT bhIndField:BUFFER-FIELD('_ascending'):BUFFER-VALUE,
                              INPUT bhIndField:BUFFER-FIELD('_abbreviate'):BUFFER-VALUE,
                              INPUT DATETIME(bhIndField:BUFFER-FIELD('_last-modified'):BUFFER-VALUE)
                              ).                            
      ASSIGN iCont2 = iCont2 + 1.                    
         
        
    END.
    hQueryMD:QUERY-CLOSE().
    bhFile:BUFFER-RELEASE().
    bhInd:BUFFER-RELEASE().
    bhIndField:BUFFER-RELEASE().
    DELETE OBJECT hQueryMD.
    DELETE OBJECT bhFile.
    DELETE OBJECT bhInd.
    DELETE OBJECT bhIndField.




END PROCEDURE.


PROCEDURE setRetCampos:
    DEFINE INPUT  PARAMETER pLog AS LOGICAL     NO-UNDO.
    ASSIGN logRetCp = pLog.
END PROCEDURE.

PROCEDURE setRetIndices:
    DEFINE INPUT  PARAMETER pLog AS LOGICAL     NO-UNDO.
    ASSIGN logRetInd = pLog.
END PROCEDURE.

PROCEDURE setRetCpsIndice:
    DEFINE INPUT  PARAMETER pLog AS LOGICAL     NO-UNDO.
    ASSIGN logRetCpInd = pLog.
END PROCEDURE.


PROCEDURE preencherDescrCpsIndice:
    DEFINE INPUT  PARAMETER  pRecid AS RECID NO-UNDO.
    DEFINE OUTPUT PARAMETER cDescr AS CHARACTER   NO-UNDO.

    DEFINE VARIABLE cTermo AS CHARACTER   NO-UNDO.

    FOR EACH ttCpsInd
        WHERE ttCpsInd.indexRecid = pRecid :
        ASSIGN  cTermo = ttCpsInd.nome + "-" +
                         ttCpsInd.tipo + "-" +
                         IF ttCpsInd.logAscending THEN "ASC" ELSE "DESC" .

        RUN incrValor(INPUT-OUTPUT cDescr, cTermo,"," ).
    END.
     /*MESSAGE cDescr
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    



END PROCEDURE.



PROCEDURE getQtRegsTTCampos:
    DEFINE OUTPUT PARAMETER iQt AS INTEGER     NO-UNDO.
    FOR EACH ttCampos FIELDS(nome)
            WHERE ttCampos.tabela = ttTabelas.nome .
        ASSIGN iQt =iQT + 1.

    END.

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



PROCEDURE gerarDDlSqlite:

    DEFINE INPUT  PARAMETER cArquivo AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER logIncrementar AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE cTipo   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iQtRegs AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont   AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cCamposInd AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE nomeCampo  AS CHARACTER   NO-UNDO.

    //variaveis chave estrangeira
    DEFINE VARIABLE cTbPai      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cTbFilho    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cpPai       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cpFilho     AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cListaPai   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cListaFilho AS CHARACTER   NO-UNDO.

    IF logIncrementar THEN
       OUTPUT TO VALUE(cArquivo) APPEND.
    ELSE
       OUTPUT TO VALUE(cArquivo).

    FOR EACH ttTabelas
        WHERE ttTabelas.nome <> '':
        RUN setBanco(ttTabelas.banco).
        RUN setTabela(ttTabelas.nome) .
        RUN limparTTCampos.
        RUN limparTTsIndices.
        RUN getCpsTb.
        RUN getIndicesCpsTb.
        PUT UNFORM "create table  IF NOT EXISTS [" +  ttTabelas.nome + "] ( " SKIP.
        RUN getQtRegsTtCampos(OUTPUT iQtRegs).
        FOR EACH ttCampos
            WHERE ttCampos.tabela = ttTabelas.nome
            AND   ttCampos.nome <> ''
            BY ttCampos.ordem  BY ttCampos.nome .
            ASSIGN cCamposInd = ''.

            ASSIGN iCont = iCont + 1.
            RUN converterTipo(INPUT 'sqlite',
                              INPUT ttCampos.tipo,
                              INPUT ttCampos.formato,
                              INPUT ttCampos.qtDecimais,
                              OUTPUT cTipo).
            PUT UNFORM "[" + trim(ttCampos.nome) + "] " + cTipo.
            IF iCont <> iQtRegs THEN DO:
               PUT  "," SKIP .
            END.
               
            //PUT SKIP  . 
        END. 
        /*MESSAGE ttTabelas.recidIndPri
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
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
               RUN incrValor(INPUT-OUTPUT cCamposInd,"[" + nomeCampo + "]",",") .
           END.

           IF cCamposInd <> '' THEN
              PUT UNFORMAT  SKIP 'PRIMARY KEY(' +  cCamposInd  + ')'  SKIP.
        END.
        /* comentado pois as chaves estrangeiras teriam de ser feitas em ordem de precedencia, o que Ç envi†vel.
        FOR EACH ttRelacEstr 
            WHERE (ttRelacEstr.tb02 = tttabelas.nome AND ttRelacEstr.tipoRelac = 'pai-filho') OR
                  (ttRelacEstr.tb01 = tttabelas.nome AND ttRelacEstr.tipoRelac = 'filho-pai') 
            BREAK BY ttRelacEstr.chave :

            IF ttRelacEstr.tipoRelac = 'pai-filho' THEN DO:
               ASSIGN cTbPai    = ttRelacEstr.tb01
                      cTbFilho  = ttRelacEstr.tb02
                      cpPai     = ttRelacEstr.cp01
                      cpFilho   = ttRelacEstr.cp02 .
            END.
            ELSE DO:
                ASSIGN cTbPai    = ttRelacEstr.tb02
                       cTbFilho  = ttRelacEstr.tb01
                       cpPai     = ttRelacEstr.cp02
                       cpFilho   = ttRelacEstr.cp01.
            END.
    
    
            RUN incrValor(INPUT-OUTPUT cListaPai, 
                             INPUT "[" + cpPai + "]" , 
                             INPUT ",").
            RUN incrValor(INPUT-OUTPUT cListaFilho, 
                             INPUT "[" + cpFilho + "]", 
                             INPUT ",").
            IF LAST-OF(ttrelacEstr.chave) THEN DO:
               PUT "," SKIP.
               PUT UNFORM " FOREIGN KEY ("  + cListaFilho +  ")REFERENCES [" + cTbPai + "] (" + cListaPai + ")" SKIP.
               ASSIGN cListaPai   = ''
               cListaFilho = '' .
            END.
            
        END.*/
        
        PUT ");" SKIP.  
    END.

    OUTPUT CLOSE.       

END PROCEDURE.





PROCEDURE gerarDDlMySQL:

    DEFINE INPUT  PARAMETER cArquivo AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER logIncrementar AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE cTipo   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iQtRegs AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont   AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cCamposInd AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE nomeCampo  AS CHARACTER   NO-UNDO.

    //variaveis chave estrangeira
    DEFINE VARIABLE cTbPai      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cTbFilho    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cpPai       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cpFilho     AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cListaPai   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cListaFilho AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cConstraint AS CHARACTER   NO-UNDO.


    IF logIncrementar THEN
       OUTPUT TO VALUE(cArquivo) APPEND.
    ELSE
       OUTPUT TO VALUE(cArquivo).

    FOR EACH ttTabelas
        WHERE ttTabelas.nome <> '':
        RUN setBanco(ttTabelas.banco).
        RUN setTabela(ttTabelas.nome) .
        RUN limparTTCampos.
        RUN limparTTsIndices.
        RUN getCpsTb.
        RUN getIndicesCpsTb.
        PUT UNFORM "create table  IF NOT EXISTS `" +  ttTabelas.nome + "` ( " SKIP.
        RUN getQtRegsTtCampos(OUTPUT iQtRegs).
        ASSIGN iCont = 0.
        FOR EACH ttCampos
            WHERE ttCampos.tabela = ttTabelas.nome
            AND   ttCampos.nome <> ''
            BY ttCampos.ordem BY ttCampos.nome .
            ASSIGN cCamposInd = ''.

            ASSIGN iCont = iCont + 1.
            RUN converterTipo(INPUT 'mysql',
                              INPUT ttCampos.tipo,
                              INPUT ttCampos.formato,
                              INPUT ttCampos.qtDecimais,
                              OUTPUT cTipo).
            PUT UNFORM "`" + trim(ttCampos.nome) + "` " + cTipo.
            IF iCont <> iQtRegs THEN DO:
               PUT  "," SKIP .
            END.
               
            //PUT SKIP  . 
        END. 
        /*MESSAGE ttTabelas.recidIndPri
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
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
               RUN incrValor(INPUT-OUTPUT cCamposInd,"`" + nomeCampo + "`",",") .
           END.

           IF cCamposInd <> '' THEN
              PUT UNFORMAT "," SKIP 'PRIMARY KEY(' +  cCamposInd  + ')'  SKIP.
        END.
        
        PUT ");" SKIP.  
        
    END.
    PUT " -- CHAVES ESTRANGEIRAS" SKIP(2).
    FOR EACH ttRelacEstr 
        WHERE ttRelacEstr.tb01 <> ''
        BREAK BY ttRelacEstr.chave :

        IF ttRelacEstr.tipoRelac = 'pai-filho' THEN DO:
           ASSIGN cTbPai    = ttRelacEstr.tb01
                  cTbFilho  = ttRelacEstr.tb02
                  cpPai     = ttRelacEstr.cp01
                  cpFilho   = ttRelacEstr.cp02 .
        END.
        ELSE DO:
            ASSIGN cTbPai    = ttRelacEstr.tb02
                   cTbFilho  = ttRelacEstr.tb01
                   cpPai     = ttRelacEstr.cp02
                   cpFilho   = ttRelacEstr.cp01.
        END.
    
    
        RUN incrValor(INPUT-OUTPUT cListaPai, 
                         INPUT "`" + cpPai + "`" , 
                         INPUT ",").
        RUN incrValor(INPUT-OUTPUT cListaFilho, 
                         INPUT "`" + cpFilho + "`", 
                         INPUT ",").
        IF LAST-OF(ttrelacEstr.chave) THEN DO:
            ASSIGN cConstraint = cTbPai + "_" + cTbFilho 
                   cConstraint = REPLACE(cConstraint,"-","_").

           PUT UNFORM "ALTER table `"  +  cTbFilho  + "`"  skip  " ADD CONSTRAINT FK_" +  cConstraint  +   " FOREIGN KEY ("  + cListaFilho +  ")REFERENCES `" + cTbPai + "` (" + cListaPai + ");" SKIP.
           ASSIGN cListaPai   = ''
                  cListaFilho = '' .
        END.
        
    END.

    OUTPUT CLOSE.       

END PROCEDURE.

PROCEDURE gerarDDlPorBancoDados:

    DEFINE INPUT  PARAMETER pBanco         AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pArquivo       AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER logIncrementar AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE hBoDdl AS HANDLE      NO-UNDO.

    FOR EACH ttTabelas
        WHERE ttTabelas.nome <> '':

        EMPTY TEMP-TABLE ttTabelasAux.
        CREATE ttTabelasAux.
        BUFFER-COPY ttTabelas TO ttTabelasAux.
        RUN setBanco(ttTabelas.banco).
        RUN setTabela(ttTabelas.nome) .
        RUN limparTTCampos.
        RUN limparTTsIndices.
        RUN getCpsTb.
        RUN getIndicesCpsTb.
        /*{esp/exportarTabelacsv3.i ttIndices " " " " "  "ttIndices00" }
        {esp/exportarTabelacsv3.i ttCpsInd  " " " " "  "ttCpsInd00" }*/

        CASE pBanco:

            WHEN 'postgresql' THEN DO:

                RUN esbo/boDDlpostgresql.p PERSISTENT SET hBoDdl.
                RUN iniciar             IN hBoDdl.
                RUN setArquivo          IN hBoDdl(pArquivo + "_" + string(TIME) + STRING(RANDOM(1,9999999)) + "_" + ttTabelas.nome  ).
                RUN setLogIncrementar   IN hBoDdl(logIncrementar).
                RUN setTTTabela         IN hBoDdl(INPUT TABLE ttTabelasAux).
                RUN setTTCampos         IN hBoDdl(INPUT TABLE ttCampos).
                RUN setTTIndices        IN hBoDdl(INPUT TABLE ttIndices).
                RUN setTTCpsIndice      IN hBoDdl(INPUT TABLE ttCpsInd).
                IF caracterOri <> '' THEN
                   RUN setCaracterSubst    IN hBoDdl(caracterOri,caracterSub).    
                RUN exec                IN hBoDdl.
                RUN finalizar IN hBoDdl.

            END.

        END CASE.
    END.         

END PROCEDURE.




PROCEDURE getChaveEstrangCsv:

    DEFINE INPUT  PARAMETER cArquivo AS CHARACTER   NO-UNDO.
    EMPTY TEMP-TABLE ttRelacEstr.
    INPUT FROM VALUE(cArquivo).
    REPEAT:
        CREATE ttRelacEstr.
        IMPORT DELIMITER ";" ttRelacEstr.
    END.
    INPUT CLOSE.
END PROCEDURE.

PROCEDURE extrairTbsTtRelacs:
    FOR EACH ttRelacEstr
        WHERE ttRelacEstr.tb01 <> '' AND ttRelacEstr.tb02 <> '':
        FIND FIRST ttTbsRelac
            WHERE ttTbsRelac.tabela = ttRelacEstr.tb01
            NO-ERROR.
        IF  NOT AVAIL ttTbsRelac THEN DO:
            CREATE ttTbsRelac.
            ASSIGN ttTbsRelac.tabela = ttRelacEstr.tb01.
        END.             
        FIND FIRST ttTbsRelac
            WHERE ttTbsRelac.tabela = ttRelacEstr.tb02
            NO-ERROR.
        IF  NOT AVAIL ttTbsRelac THEN DO:
            CREATE ttTbsRelac.
            ASSIGN ttTbsRelac.tabela = ttRelacEstr.tb02.
        END.                                           
    END.                 
END PROCEDURE.

PROCEDURE getTTTbsRelacs:

    DEFINE OUTPUT PARAMETER  TABLE FOR ttTbsRelac.

END PROCEDURE.



PROCEDURE converterTipo:
    DEFINE INPUT  PARAMETER pBanco      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTipo       AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pFormato    AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pQtDecimais AS INTEGER     NO-UNDO.
    DEFINE OUTPUT PARAMETER cTipo    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cFormConv AS CHARACTER   NO-UNDO.
    RUN converterFormato(INPUT pTipo,
                         INPUT pFormato, 
                         INPUT pQtDecimais,
                         OUTPUT cFormConv).
    
    CASE pBanco:
        WHEN 'mysql' THEN DO:
              CASE pTipo:
                  WHEN 'decimal' THEN DO:
                      ASSIGN cTipo = 'numeric'
                             cTipo = cTipo + "(" + cFormCOnv + ")".
                  END.
                      
                  WHEN 'character' THEN DO:
                      IF cFormConv = '' THEN
                         ASSIGN cFormConv = '5'.
                      IF INT(cFormConv) > 500 THEN
                          ASSIGN cTipo = 'TEXT'.
                      ELSE
                          ASSIGN cTipo = 'VARCHAR'
                                 cTipo = cTipo +  "(" + cFormCOnv + ")".

                  END.
                      
                  WHEN 'logical' THEN
                      ASSIGN cTipo  = 'BIT'.

                  OTHERWISE DO:
                     ASSIGN cTipo = pTipo .
                  END.
              END CASE.     
        END.
        WHEN 'sqlite' THEN DO:
              CASE pTipo:
                  WHEN 'decimal' THEN DO:
                      ASSIGN cTipo = 'numeric'
                             cTipo = cTipo + "(" + cFormCOnv + ")".
                  END.
                      
                  WHEN 'character' THEN DO:
                      IF cFormConv = '' THEN
                         ASSIGN cFormConv = '5'.
                      ASSIGN cTipo = 'VARCHAR'
                             cTipo = cTipo +  "(" + cFormCOnv + ")".

                  END.
                      
                  WHEN 'logical' THEN
                      ASSIGN cTipo  = 'BOOLEAN'.

                  OTHERWISE DO:
                     ASSIGN cTipo = pTipo .
                  END.
              END CASE.     
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

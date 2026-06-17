/*
programa:esbo/boMetaDados.p
objetivo: Extrair as informa‡äes de metadados das tabelas como por exemplo: campos, tipos, listas de op‡äes etc, possibilitando
a constru‡Æo dinamica de extra‡Æo de dados para exibi‡Æo em diversas plataformas(api, 4gl etc) e para compara‡Æo de valores anteriores a atuais
*/
DEFINE VARIABLE cTabela AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cBanco  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCampos AS CHARACTER   NO-UNDO.

DEFINE VARIABLE iMetaTbRelacCorr AS INTEGER     NO-UNDO.
DEFINE NEW SHARED VARIABLE  drec_db AS Recid       NO-UNDO.
DEFINE VARIABLE lAtualizaMeta AS LOGICAL     NO-UNDO.

DEFINE VARIABLE cBancoFiltro    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTabelaFiltro   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCampoFiltro    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDumpNameFiltro AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lTbSys          AS LOGICAL     NO-UNDO.
DEFINE VARIABLE dtHrAlteracao   AS DATETIME    NO-UNDO.
DEFINE VARIABLE operadorDtHr    AS CHARACTER   NO-UNDO.
{esbo/boMetaDados.i}



{util.i}


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

PROCEDURE limparTTCampos:
    EMPTY TEMP-TABLE ttCampos.
    ASSIGN cCampos = ''.

END PROCEDURE.

PROCEDURE getBancoTb:
    DEFINE OUTPUT  PARAMETER pBanco AS CHARACTER   NO-UNDO.
    ASSIGN pBanco = cBanco.

END PROCEDURE.

PROCEDURE getCpsTb:
    //DEFINE VARIABLE cBanco      AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE hQueryMD    AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhFile      AS HANDLE      NO-UNDO.
    DEFINE VARIABLE bhField     AS HANDLE      NO-UNDO.
    DEFINE VARIABLE iDb         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iCont       AS INTEGER     NO-UNDO.
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
    hQueryMD:QUERY-PREPARE('for each ' + cBanco + '._file no-lock where _file-name ="' + cTabela + '" , each _field of _file no-lock ' + condCp) NO-ERROR.
    /*hQueryMD:QUERY-PREPARE('for each _file no-lock  , each _field of _file no-lock ').*/
    hQueryMD:QUERY-OPEN.
    REPEAT:
      hQueryMD:GET-NEXT().
      IF hQueryMD:QUERY-OFF-END THEN LEAVE.
     /* IF bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() = 'ind_orig_tit_acr' THEN
      MESSAGE     'view-as:' bhField:BUFFER-FIELD('_View-as'):BUFFER-VALUE() SKIP
             VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/                             
      IF(bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE() > 0) THEN DO:
        DO iExtensoes = 1 TO bhField:BUFFER-FIELD('_field-name'):EXTENT:
           ASSIGN iExtensoes = iExtensoes + 1
                  iCont = iCont + 1.
           RUN inserirTtCampos(INPUT iCont,
                               INPUT bhField:BUFFER-FIELD('_label'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() + "-" + bhField:BUFFER-FIELD('_extent'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_data-type'):BUFFER-VALUE() ,
                               INPUT bhField:BUFFER-FIELD('_format'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_Extent'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_view-as'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_order'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_mandatory'):BUFFER-VALUE(),
                               INPUT bhField:BUFFER-FIELD('_decimals'):BUFFER-VALUE() ).
           
        END.
      END.
      ELSE DO :
         ASSIGN iCont = iCont + 1.
         RUN inserirTtCampos(INPUT iCont,
                             INPUT bhField:BUFFER-FIELD('_label'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_field-name'):BUFFER-VALUE() ,
                             INPUT bhField:BUFFER-FIELD('_data-type'):BUFFER-VALUE() ,
                             INPUT bhField:BUFFER-FIELD('_format'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_Extent'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_View-as'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_order'):BUFFER-VALUE(),
                             INPUT bhField:BUFFER-FIELD('_mandatory'):BUFFER-VALUE(), 
                             INPUT bhField:BUFFER-FIELD('_decimals'):BUFFER-VALUE()).    
         
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

    DEFINE OUTPUT PARAMETER TABLE FOR ttCampos.


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
    ttCampos.banco              = cBanco.
    IF cBanco <> 'ems5' THEN
       RUN extrairLista(INPUT cLista, OUTPUT ttCampos.lista).
    ELSE
       RUN extrairListaEms5(INPUT cLista, OUTPUT ttCampos.lista ).

END PROCEDURE.


PROCEDURE extrairLista:
    DEFINE INPUT  PARAMETER cLista      AS CHARACTER   NO-UNDO FORMAT 'x(200)'.
    DEFINE OUTPUT PARAMETER cRetorno    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cInclude            AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iCont               AS INTEGER     NO-UNDO.
    DEFINE VARIABLE lTemInclude         AS LOGICAL     NO-UNDO.
    ASSIGN lTemInclude = index(cLista,'.i') > 0 .              
    IF cLista <> '' AND cLista <> ? AND lTemInclude THEN DO:   
       ASSIGN cInclude = ENTRY(2,cLista,"~{")
            cInclude = ENTRY(1,cInclude,".i")
            cInclude = cInclude + ".i 3" .  
       RUN esp/include_dinamica.i cInclude. 
       ASSIGN cRetorno = RETURN-VALUE.
    END.
    ELSE DO:
       ASSIGN cRetorno = IF cLista = ? OR cLista = '?' THEN  '' ELSE cLista.
    END.
    IF INDEX(cRetorno,'toggle-box') > 0  THEN
       ASSIGN cRetorno = ''.
    IF INDEX(cRetorno,'editor')  > 0 THEN
       ASSIGN cRetorno = '' .
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

PROCEDURE inserirMetaCpRelac:

    DEFINE INPUT  PARAMETER pCp01 AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCp02 AS CHARACTER   NO-UNDO.

    CREATE meta_cp_relacs.
    ASSIGN meta_cp_relacs.meta_tb_relac_id = iMetaTbRelacCorr 
           meta_cp_relacs.cod_cp_01        = pCp01
           meta_cp_relacs.cod_cp_02        = pCp02 
           meta_cp_relacs.dt_hr_registro   = NOW.


END PROCEDURE.



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
        RUN inserirMetaTbRelacOF(ttRelacs.tb01,ttRelacs.tb02,ttRelacs.campos ).
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
    DEFINE VARIABLE dtLastChange    AS DATE        NO-UNDO.
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
            /*MESSAGE lastChange SKIP
                bhFile:BUFFER-FIELD('_Last-change'):BUFFER-VALUE()
                VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
            RUN convertUnixTimeStamp(lastChange,OUTPUT dtHrLastChange).

            IF dtHrAlteracao <> ? THEN DO:
               CASE operadorDtHr:
                   WHEN '1' THEN //maior que
                       IF dtHrAlteracao >= dtHrLastChange THEN NEXT.
                   WHEN '2' THEN  //menor que
                       IF dtHrAlteracao <= dtHrLastChange THEN NEXT.
               END CASE.
            END.

            CREATE ttTabelas.
            ASSIGN ttTabelas.banco          = cBancoCor
                   ttTabelas.nome           = bhFile:BUFFER-FIELD('_file-name'):BUFFER-VALUE()
                   ttTabelas.descricao      = bhfile:BUFFER-FIELD('_DESC'):BUFFER-VALUE()
                   ttTabelas.nomeDump       = bhFile:BUFFER-FIELD('_Dump-name'):BUFFER-VALUE()
                   ttTabelas.dtHrAlteracao  = dtHrLastChange 
                   ttTabelas.lastChange     = lastChange .
        END.
     END.

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

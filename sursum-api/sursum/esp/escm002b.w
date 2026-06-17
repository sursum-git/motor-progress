&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS D-Dialog 
/*:T*******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i SCCM001A 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
DEF BUFFER empresa FOR mgadm.empresa.

/* Parameters Definitions ---                                           */
DEFINE TEMP-TABLE tt-descontos 
       FIELD cod-estabel   LIKE nota-fiscal.cod-estabel
       FIELD estab-ori     LIKE nota-fiscal.cod-estabel
       FIELD cod-rep       LIKE nota-fiscal.cod-rep
       FIELD num-desconto  LIKE cm-desc-repres.num-desconto
       FIELD desc-desconto LIKE cm-desc-repres.desc-desconto
       FIELD vlr-original  AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD vlr-desconto  AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD mes           LIKE cm-desc-repres.mes
       FIELD ano           LIKE cm-desc-repres.ano
       FIELD base          AS INT.

DEFINE TEMP-TABLE tt-work
       FIELD cod-rep    LIKE cm-desc-repres.cod-rep
       FIELD nome-abrev LIKE repres.nome-abrev
       FIELD base       AS INTEGER      
       FIELD cod-estab  LIKE cm-desc-repres.cod-estab
       FIELD mes-base   AS CHAR FORMAT "x(20)"
       FIELD ano        LIKE cm-desc-repres.ano
       FIELD codigo     AS INTEGER
       FIELD descricao  AS CHAR FORMAT "x(30)"
       FIELD qtd-parcela    LIKE cm-emprestimo.qtd-parcela
       FIELD vlr-emprestimo LIKE cm-emprestimo.vlr-emprestimo
       FIELD valor          LIKE cm-desc-repres.vlr-desconto
       FIELD vlr-original   LIKE cm-desc-repres.vlr-desconto.

DEFINE INPUT PARAMETER TABLE FOR tt-descontos.
DEFINE INPUT PARAMETER p-cod-rep AS INT.
DEFINE INPUT PARAMETER p-cod-estab AS CHAR.
DEFINE INPUT PARAMETER p-base AS INT.
DEFINE INPUT PARAMETER p-tipo AS CHAR.

DEF BUFFER b-tt-work FOR tt-work.

DEF VAR c-meses   AS CHAR INIT "Janeiro,Fevereiro,Maráo,Abril,Maio,Junho,Julho,Agosto,Setembro,Outubro,Novembro,Dezembro".
DEF VAR da-data-base  AS DATE.

DEF VAR h-acomp   AS HANDLE NO-UNDO.
DEF VAR c-empresa AS CHAR.
DEF VAR de-mts    AS DEC.

 /* Variaveis da Rotina de Impress∆o */
DEFINE VAR l-ok         AS LOG.
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-ct         AS INT.
DEFINE VAR i-lin        AS INT.
DEFINE VAR i-pag        AS INT.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME D-Dialog
&Scoped-define BROWSE-NAME br-work

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-work

/* Definitions for BROWSE br-work                                       */
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.nome-abrev tt-work.cod-estab tt-work.base tt-work.mes-base tt-work.ano tt-work.codigo tt-work.descricao tt-work.vlr-emprestimo tt-work.qtd-parcela tt-work.vlr-original tt-work.valor   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom br-work bt-imprime bt-ok ~
bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-total 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "&Ajuda" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-cancela AUTO-END-KEY 
     LABEL "&Cancelar" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/img-pri.bmp":U
     LABEL "Impress∆o" 
     SIZE 13 BY 1.25 TOOLTIP "Imprime o Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-total AS DECIMAL FORMAT "Z,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14.43 BY .88 NO-UNDO.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 103.43 BY 1.42
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-work FOR 
      tt-work SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-work D-Dialog _FREEFORM
  QUERY br-work NO-LOCK DISPLAY
      tt-work.nome-abrev     COLUMN-LABEL "Repres"  
      tt-work.cod-estab      COLUMN-LABEL "Est"          
      tt-work.base           COLUMN-LABEL "Base"
      tt-work.mes-base       COLUMN-LABEL "Mes" 
      tt-work.ano            COLUMN-LABEL "Ano" 
      tt-work.codigo         COLUMN-LABEL "Descto"  
      tt-work.descricao      COLUMN-LABEL "Descriá∆o"
      tt-work.vlr-emprestimo COLUMN-LABEL "Qt Parc" 
      tt-work.qtd-parcela    COLUMN-LABEL "Qt Parc" 
      tt-work.vlr-original   COLUMN-LABEL "Vlr Original"
      tt-work.valor          COLUMN-LABEL "Vlr Descontado"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 103 BY 12.17
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1.25 COL 2
     bt-imprime AT ROW 13.75 COL 2
     fi-total AT ROW 13.88 COL 86.14 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     bt-ok AT ROW 15.46 COL 3.29
     bt-cancela AT ROW 15.46 COL 14.29
     bt-ajuda AT ROW 15.46 COL 94.72
     "TOTAL SELEC.:" VIEW-AS TEXT
          SIZE 14 BY .88 AT ROW 13.92 COL 74.14
          FGCOLOR 1 FONT 6
     rt-buttom AT ROW 15.25 COL 2
     SPACE(0.42) SKIP(0.20)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Detalha Descontos Por Representante - ESCM002B"
         DEFAULT-BUTTON bt-ok.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartDialog
   Allow: Basic,Browse,DB-Fields,Query,Smart
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB D-Dialog 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/d-dialog.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR DIALOG-BOX D-Dialog
   NOT-VISIBLE FRAME-NAME L-To-R                                        */
/* BROWSE-TAB br-work rt-buttom D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN fi-total IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-work */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK DIALOG-BOX D-Dialog
/* Query rebuild information for DIALOG-BOX D-Dialog
     _Options          = "SHARE-LOCK"
     _Query            is NOT OPENED
*/  /* DIALOG-BOX D-Dialog */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL D-Dialog D-Dialog
ON WINDOW-CLOSE OF FRAME D-Dialog /* Detalha Descontos Por Representante - ESCM002B */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda D-Dialog
ON CHOOSE OF bt-ajuda IN FRAME D-Dialog /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO: /* Call Help Function (or a simple message). */
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime D-Dialog
ON CHOOSE OF bt-imprime IN FRAME D-Dialog /* Impress∆o */
DO:
  RUN pi-imprime.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

{src/adm/template/dialogmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects D-Dialog  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available D-Dialog  _ADM-ROW-AVAILABLE
PROCEDURE adm-row-available :
/*------------------------------------------------------------------------------
  Purpose:     Dispatched to this procedure when the Record-
               Source has a new row available.  This procedure
               tries to get the new row (or foriegn keys) from
               the Record-Source and process it.
  Parameters:  <none>
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.             */
  {src/adm/template/row-head.i}

  /* Process the newly available records (i.e. display fields,
     open queries, and/or pass records on to any RECORD-TARGETS).    */
  {src/adm/template/row-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI D-Dialog  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Hide all frames. */
  HIDE FRAME D-Dialog.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI D-Dialog  _DEFAULT-ENABLE
PROCEDURE enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  DISPLAY fi-total 
      WITH FRAME D-Dialog.
  ENABLE rt-buttom br-work bt-imprime bt-ok bt-cancela bt-ajuda 
      WITH FRAME D-Dialog.
  {&OPEN-BROWSERS-IN-QUERY-D-Dialog}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy D-Dialog 
PROCEDURE local-destroy :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'destroy':U ) .
  {include/i-logfin.i}

  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize D-Dialog 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* {utp/ut9000.i "ESSP0174A" "2.04.00.000"} */ 

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  /* Busca Nome da Empresa */
  FIND FIRST param-global NO-LOCK NO-ERROR.
  FIND FIRST empresa
       WHERE empresa.ep-codigo = param-global.empresa-prin NO-LOCK NO-ERROR. 
  ASSIGN c-empresa = (IF AVAIL empresa THEN empresa.razao-social ELSE "").

  RUN pi-processa.

  {&OPEN-QUERY-br-work}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-cabec D-Dialog 
PROCEDURE pi-imp-cabec :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 PUT c-empresa FORMAT "X(40)"                  AT   1
     "DATA: "                                  AT  58
     STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  64
     "HORA: "                                  AT  85
     STRING(TIME,"hh:mm:ss")                   AT  91
     "PAG:"                                    AT 125
     i-pag FORMAT ">>"                         AT 130
     SKIP(1).

 IF p-tipo = "D" THEN 
    PUT "DESCONTOS REPRESENTANTE: " + repres.nome  FORMAT "x(60)" AT 35 SKIP(1).
 ELSE
    PUT "EMPRESTIMOS REPRESENTANTE: " + repres.nome  FORMAT "x(60)" AT 35 SKIP(1).

 PUT "Est   Representante                                     Valor " AT 1.
 PUT "----- ---------------------------------------- -------------- " AT 1.
 
 ASSIGN i-pag = i-pag + 1.
                                                                           
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imprime D-Dialog 
PROCEDURE pi-imprime :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF VAR h-prog AS HANDLE NO-UNDO.
 DEF VAR i-ct   AS INT.

 RUN utp/ut-utils.p PERSISTENT SET h-prog.

 RUN esapi/saida-imp.p (OUTPUT i-saida,
                        OUTPUT c-saida,
                        OUTPUT i-num-copias,
                        OUTPUT l-ok).

 CASE i-saida:
     WHEN 1 THEN DO.
         OUTPUT TO PRINTER CONVERT TARGET "ibm850" PAGED PAGE-SIZE 62.
         PUT CONTROL "~033E~033(s18H".    
     END.
     WHEN 2 THEN
         OUTPUT TO VALUE(c-saida).
     WHEN 3 THEN DO.
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "escm002.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.

 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-pag =  1
           i-lin = 99.
    FOR EACH b-tt-work WHERE NO-LOCK.
        
        IF i-lin > 62 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
        PUT b-tt-work.cod-estab     AT  01  
            b-tt-work.nome-abrev      AT  07  
            b-tt-work.valor         AT  52
            SKIP.

        ACCUMULATE b-tt-work.valor (TOTAL).

        ASSIGN i-lin = i-lin + 1.
    END.
    /*             
    IF (ACCUM TOTAL b-tt-work.valor <> 0) THEN DO:
       IF i-lin > 59 THEN DO:
          RUN pi-imp-cabec.
          ASSIGN i-lin = 7.
       END.
       PUT "" AT 1.
       PUT " -------------- --------------" AT 102 SKIP.
       PUT "Total Geral.........:" AT 53.
       PUT ACCUM TOTAL b-tt-work.vl-tot-nota FORMAT ">>>,>>>,>>9.99" AT 102.
    END.
    */ 
    IF i-saida = 1 THEN DO:
       PAGE.
       PUT "" AT 1.
    END.
 END.

 IF i-saida = 3 THEN DO.
   RUN EXECUTE IN h-prog(INPUT "notepad.exe",
                         INPUT c-saida).
   DELETE PROCEDURE h-prog.
 END.
 OUTPUT CLOSE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-processa D-Dialog 
PROCEDURE pi-processa :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Selecionando_Notas_Fiscais *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 FIND repres WHERE
      repres.cod-rep = p-cod-rep NO-LOCK NO-ERROR.

 EMPTY TEMP-TABLE tt-work.

 ASSIGN tt-work.vlr-emprestimo:VISIBLE IN BROWSE br-work = NO.
 ASSIGN tt-work.qtd-parcela:VISIBLE IN BROWSE br-work = NO.  

 IF p-tipo = "D" THEN DO.
    ASSIGN br-work:TITLE IN FRAME {&FRAME-NAME} = "DESCONTOS DO REPRESENTANTE: " + repres.nome.

    ASSIGN tt-work.ano:VISIBLE IN BROWSE br-work = YES.

    FOR EACH tt-descontos WHERE
             tt-descontos.cod-estab = p-cod-estab AND
             tt-descontos.cod-rep = p-cod-rep AND
             tt-descontos.base = p-base NO-LOCK.

        CREATE tt-work.
        ASSIGN tt-work.cod-rep = tt-descontos.cod-rep
               tt-work.cod-estab = tt-descontos.estab-ori
               tt-work.base = tt-descontos.base
               tt-work.vlr-original = tt-descontos.vlr-original
               tt-work.valor = tt-descontos.vlr-desconto.

        ASSIGN tt-work.codigo = tt-descontos.num-desconto
               tt-work.descricao = tt-descontos.desc-desconto
               tt-work.mes-base = ENTRY(tt-descontos.mes,c-meses)
               tt-work.ano = tt-descontos.ano.

        FIND repres WHERE
             repres.cod-rep = tt-descontos.cod-rep NO-LOCK NO-ERROR.
        ASSIGN tt-work.nome-abrev = repres.nome-abrev.
    END.
 END.
 ELSE DO.
    ASSIGN br-work:TITLE IN FRAME {&FRAME-NAME} = "EMPRESTIMOS DO REPRESENTANTE: " + repres.nome.
    ASSIGN tt-work.vlr-emprestimo:VISIBLE IN BROWSE br-work = YES.
    ASSIGN tt-work.qtd-parcela:VISIBLE IN BROWSE br-work = YES.  

    FOR EACH cm-emprestimo WHERE
             cm-emprestimo.cod-estab = p-cod-estab AND
             cm-emprestimo.cod-rep = p-cod-rep 
             NO-LOCK.

        /*
        ASSIGN da-data-base = DATE(LOOKUP(cm-emprestimo.mes-base,c-meses),1,cm-emprestimo.ano-base).
        IF p-dt-periodo-ini > da-data-base + (cm-emprestimo.qtd-parcelas * 30) THEN NEXT.

        CREATE tt-work.
        ASSIGN tt-work.cod-rep = cm-emprestimo.cod-rep
               tt-work.cod-estab = cm-emprestimo.cod-estab
               tt-work.valor = cm-emprestimo.vlr-parcela.

        ASSIGN tt-work.codigo = cm-emprestimo.num-emprestimo
               tt-work.descricao = 'Emprestimo'
               tt-work.mes-base = cm-emprestimo.mes-base
               tt-work.ano = cm-emprestimo.ano-base
               tt-work.qtd-parcela = cm-emprestimo.qtd-parcela   
               tt-work.vlr-emprestimo = cm-emprestimo.vlr-emprestimo.

        FIND repres WHERE
             repres.cod-rep = cm-emprestimo.cod-rep NO-LOCK NO-ERROR.
        ASSIGN tt-work.nome-abrev = repres.nome-abrev.
        */
    END.
 END.

 RUN pi-finalizar in h-acomp.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-total D-Dialog 
PROCEDURE pi-total :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 
 ASSIGN fi-total = 0.
        
 FOR EACH tt-work NO-LOCK.
     ASSIGN fi-total = fi-total + tt-work.valor.
 END.
 
 DISP fi-total 
      WITH FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records D-Dialog  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-work"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed D-Dialog 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
  
  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


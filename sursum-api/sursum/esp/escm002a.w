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

DEFINE TEMP-TABLE tt-nfs   LIKE nota-fiscal
       FIELD qt-faturada   AS   DECIMAL
       FIELD comissao      AS   DECIMAL
       FIELD base          AS   INT
       INDEX indice1 IS PRIMARY cod-rep cod-estabel serie nr-nota-fis.

DEFINE TEMP-TABLE tt-work NO-UNDO 
       FIELD nr-nota-fis  LIKE nota-fiscal.nr-nota-fis
       FIELD cod-estabel  LIKE nota-fiscal.cod-estabel
       FIELD serie        LIKE nota-fiscal.serie
       FIELD dt-emis-nota LIKE nota-fiscal.dt-emis-nota
       FIELD dt-saida     LIKE nota-fiscal.dt-saida
       FIELD dt-embarque  LIKE nota-fiscal.dt-embarque
       FIELD nr-pedcli    LIKE ped-venda.nr-pedcli
       FIELD nome-abrev   LIKE ped-venda.nome-abrev
       FIELD cod-rep      LIKE nota-fiscal.cod-rep
       FIELD no-ab-reppri LIKE ped-venda.no-ab-reppri
       FIELD dt-implant   LIKE ped-venda.dt-implant
       FIELD dt-entrega   LIKE ped-venda.dt-entrega
       FIELD vl-tot-nota  LIKE nota-fiscal.vl-tot-nota
       FIELD perc-comis   AS   DEC FORMAT ">>9.9999" 
       FIELD comissao     LIKE nota-fiscal.vl-tot-nota
       FIELD base         AS   INT
       FIELD visualiza    AS   LOG.

DEFINE BUFFER b-tt-work FOR tt-work.

DEFINE INPUT PARAMETER TABLE FOR tt-nfs.  
DEFINE INPUT PARAMETER p-cod-rep AS INT.
DEFINE INPUT PARAMETER p-cod-estab AS CHAR.
DEFINE INPUT PARAMETER p-base AS INT.
DEFINE INPUT PARAMETER p-esp-docto AS INT.

/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-ped-venda   AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR gr-nota-fiscal AS ROWID NO-UNDO.

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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.cod-estab tt-work.base tt-work.nr-nota-fis tt-work.nr-pedcli tt-work.nome-abrev tt-work.no-ab-reppri tt-work.dt-emis-nota tt-work.dt-saida tt-work.vl-tot-nota tt-work.perc-comis tt-work.comissao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY {&SELF-NAME} FOR EACH tt-work WHERE                                  tt-work.visualiza = YES NO-LOCK.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom RECT-61 rs-tipo br-work ~
bt-detalhe-ped bt-detalhe-nf bt-imprime bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS rs-tipo fi-mts fi-comis 

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

DEFINE BUTTON bt-detalhe-nf 
     IMAGE-UP FILE "image/img-detnf.bmp":U
     LABEL "Detalhe" 
     SIZE 18 BY 1.25 TOOLTIP "Detalhe da Nota Fiscal".

DEFINE BUTTON bt-detalhe-ped 
     IMAGE-UP FILE "image/img-detped.bmp":U
     LABEL "Detalhe" 
     SIZE 15 BY 1.25 TOOLTIP "Detalhe do Pedido".

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/img-pri.bmp":U
     LABEL "Impress∆o" 
     SIZE 13 BY 1.25 TOOLTIP "Imprime o Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-comis AS DECIMAL FORMAT "Z,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13.72 BY .88 NO-UNDO.

DEFINE VARIABLE fi-mts AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13.14 BY .88 NO-UNDO.

DEFINE VARIABLE rs-tipo AS INTEGER INITIAL 1 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Notas na Base Selecionada", 1,
"Notas do Representante", 2,
"TODAS as Notas", 3
     SIZE 101 BY 1.25
     FONT 6 NO-UNDO.

DEFINE RECTANGLE RECT-61
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 103 BY 1.75
     BGCOLOR 7 .

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
      tt-work.cod-estab    COLUMN-LABEL "Est"           WIDTH 4
      tt-work.base         COLUMN-LABEL "P"             WIDTH 3
      tt-work.nr-nota-fis  COLUMN-LABEL "N.Fiscal"      WIDTH 7
      tt-work.nr-pedcli    COLUMN-LABEL "Ped Cli"       WIDTH 8
      tt-work.nome-abrev   COLUMN-LABEL "Cliente"       WIDTH 12
      tt-work.no-ab-reppri COLUMN-LABEL "Representante" WIDTH 12
      tt-work.dt-emis-nota COLUMN-LABEL "Dt.Emiss∆o"    WIDTH 8.5
      tt-work.dt-saida     COLUMN-LABEL "Data Saida"    WIDTH 8.5
      tt-work.vl-tot-nota  COLUMN-LABEL "Vl.Total"
      tt-work.perc-comis   COLUMN-LABEL "%Comis" 
      tt-work.comissao     COLUMN-LABEL "Comissao"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 103 BY 12.17
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     rs-tipo AT ROW 1.5 COL 3 NO-LABEL WIDGET-ID 8
     br-work AT ROW 3.25 COL 2
     bt-detalhe-ped AT ROW 15.58 COL 2.86
     bt-detalhe-nf AT ROW 15.58 COL 18.29
     bt-imprime AT ROW 15.58 COL 36.72
     fi-mts AT ROW 15.75 COL 67.86 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     fi-comis AT ROW 15.75 COL 81.29 COLON-ALIGNED NO-LABEL WIDGET-ID 14
     bt-ok AT ROW 17.29 COL 2.86
     bt-cancela AT ROW 17.29 COL 13.86
     bt-ajuda AT ROW 17.29 COL 94.29
     rt-buttom AT ROW 17.08 COL 1.57
     RECT-61 AT ROW 1.25 COL 2 WIDGET-ID 12
     SPACE(0.85) SKIP(15.57)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Detalha Nota Fiscal Por Representante - ESCM002A"
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
/* BROWSE-TAB br-work rs-tipo D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN fi-comis IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-mts IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY {&SELF-NAME} FOR EACH tt-work WHERE
                                 tt-work.visualiza = YES NO-LOCK.
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Detalha Nota Fiscal Por Representante - ESCM002A */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON VALUE-CHANGED OF br-work IN FRAME D-Dialog
DO:
  ASSIGN bt-detalhe-ped:SENSITIVE IN FRAME {&FRAME-NAME} = YES
         bt-detalhe-nf:SENSITIVE IN FRAME {&FRAME-NAME}  = YES.

  IF tt-work.nr-pedcli = "" THEN
     ASSIGN bt-detalhe-ped:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
  IF tt-work.nr-nota-fis = "" THEN
     ASSIGN bt-detalhe-nf:SENSITIVE IN FRAME {&FRAME-NAME} = NO.


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


&Scoped-define SELF-NAME bt-detalhe-nf
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-detalhe-nf D-Dialog
ON CHOOSE OF bt-detalhe-nf IN FRAME D-Dialog /* Detalhe */
DO:
  IF AVAIL tt-work THEN DO:
      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-work.cod-estabel AND
           nota-fiscal.serie       = tt-work.serie       AND
           nota-fiscal.nr-nota-fis = tt-work.nr-nota-fis NO-LOCK NO-ERROR.
     IF AVAIL nota-fiscal THEN DO:
        ASSIGN gr-nota-fiscal = ROWID(nota-fiscal).
        ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
        RUN ftp/ft0904.
        ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
     END.  
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-detalhe-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-detalhe-ped D-Dialog
ON CHOOSE OF bt-detalhe-ped IN FRAME D-Dialog /* Detalhe */
DO:
  IF AVAIL tt-work THEN DO:
     FIND ped-venda WHERE
          ped-venda.nr-pedcli  = tt-work.nr-pedcli AND
          ped-venda.nome-abrev = tt-work.nome-abrev NO-LOCK NO-ERROR.
     ASSIGN gr-ped-venda = ROWID(ped-venda).
     ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
     RUN esp\espd4000.w (INPUT "Consultar").
     ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
  END.
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


&Scoped-define SELF-NAME rs-tipo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-tipo D-Dialog
ON VALUE-CHANGED OF rs-tipo IN FRAME D-Dialog
DO:
  ASSIGN INPUT FRAME {&FRAME-NAME} rs-tipo.

  FOR EACH tt-work.
      ASSIGN tt-work.visualiza = YES.

      IF rs-tipo = 1 THEN DO.
         IF tt-work.cod-estab <> p-cod-estab OR
            tt-work.cod-rep <> p-cod-rep OR
            tt-work.base <> p-base THEN
            ASSIGN tt-work.visualiza = NO.
      END.
      IF rs-tipo = 2 THEN DO.
         IF tt-work.cod-rep <> p-cod-rep THEN
            ASSIGN tt-work.visualiza = NO.
      END.
  END.

  {&OPEN-QUERY-br-work}
  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


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
  DISPLAY rs-tipo fi-mts fi-comis 
      WITH FRAME D-Dialog.
  ENABLE rt-buttom RECT-61 rs-tipo br-work bt-detalhe-ped bt-detalhe-nf 
         bt-imprime bt-ok bt-cancela bt-ajuda 
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

  APPLY 'VALUE-CHANGED' TO rs-tipo IN FRAME {&FRAME-NAME}.

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

     

     PUT "NOTAS FISCAIS DO REPRESENTANTE: " + repres.nome  FORMAT "x(60)" AT 35 SKIP(1).
     PUT "N.Fiscal Ped Cli Cliente      Representante  Dt.Emiss∆o Dt.Embarque Dt.Saida   Dt.Implant Dt.Entrega     Qtde (MTS)     Peso (KGS)" AT 1.
     PUT "-------- ------- ------------ -------------- ---------- ----------- ---------- ---------- ---------- -------------- --------------" AT 1.
 
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
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0197b.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.

 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-pag      =  1
           i-lin      = 99.
    FOR EACH b-tt-work WHERE NO-LOCK.
        
        IF i-lin > 62 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
        PUT b-tt-work.nr-nota-fis  FORMAT "x(7)"       AT  01
            b-tt-work.nr-pedcli    FORMAT "x(6)"       AT  10   
            b-tt-work.nome-abrev                       AT  18   
            b-tt-work.no-ab-reppri                     AT  31   
            b-tt-work.dt-emis-nota                     AT  46   
            b-tt-work.dt-embarque                      AT  57   
            b-tt-work.dt-saida                         AT  69
            b-tt-work.dt-implant                       AT  80
            b-tt-work.dt-entrega                       AT  91
            b-tt-work.vl-tot-nota                      AT  102.

        ACCUMULATE b-tt-work.vl-tot-nota (TOTAL).

        ASSIGN i-lin    = i-lin + 1.
    END.
                 /*
    IF (ACCUM TOTAL b-tt-work.vl-tot-nota <> 0) THEN DO:
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

 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Selecionando_Notas_Fiscais *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 FIND repres WHERE
      repres.cod-rep = p-cod-rep NO-LOCK NO-ERROR.

 IF p-esp-docto = 22 THEN
    ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "NOTAS FISCAIS DO REPRESENTANTE: " + repres.nome.
 ELSE
    ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "DEVOLUÄÂES DO REPRESENTANTE: " + repres.nome.

 EMPTY TEMP-TABLE tt-work.

 FOR EACH tt-nfs.
     RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(tt-nfs.dt-emis-nota) +
                                         " Nota Fiscal: " + tt-nfs.nr-nota-fis).

     IF tt-nfs.esp-docto <> p-esp-docto THEN NEXT.

     FIND repres WHERE
          repres.cod-rep = tt-nfs.cod-rep NO-LOCK NO-ERROR.

     FIND cm-ext-repres OF repres NO-LOCK NO-ERROR.

     FIND tt-work WHERE
          tt-work.cod-estab = tt-nfs.cod-estabel AND
          tt-work.base = tt-nfs.base AND
          tt-work.nr-nota-fis = tt-nfs.nr-nota-fis NO-LOCK NO-ERROR.
     IF NOT AVAIL tt-work THEN DO:
        CREATE tt-work.
        ASSIGN tt-work.nr-nota-fis  = tt-nfs.nr-nota-fis
               tt-work.cod-estabel  = tt-nfs.cod-estabel
               tt-work.serie        = tt-nfs.serie
               tt-work.nr-pedcli    = tt-nfs.nr-pedcli
               tt-work.nome-abrev   = tt-nfs.nome-ab-cli
               tt-work.cod-rep      = tt-nfs.cod-rep
               tt-work.no-ab-reppri = tt-nfs.no-ab-reppri
               tt-work.dt-embarque  = tt-nfs.dt-embarque
               tt-work.dt-emis-nota = tt-nfs.dt-emis-nota
               tt-work.dt-saida     = tt-nfs.dt-saida
               tt-work.vl-tot-nota  = tt-nfs.vl-tot-nota
               tt-work.comissao     = tt-nfs.comissao
               tt-work.perc-comis   = tt-nfs.comissao / tt-nfs.vl-tot-nota * 100
               tt-work.base         = tt-nfs.base
               tt-work.visualiza    = YES.
     END.
 END.

 RUN pi-finalizar in h-acomp.
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.

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
 
 ASSIGN fi-mts = 0
        fi-comis = 0.
        
 FOR EACH tt-work where
          tt-work.visualiza NO-LOCK.
     ASSIGN fi-mts = fi-mts + tt-work.vl-tot-nota
            fi-comis = fi-comis + tt-work.comis.
 END.
 
 DISP fi-mts 
      fi-comis
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


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
{include/i-prgvrs.i ESSP0190C 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */
DEF BUFFER empresa FOR mgadm.empresa.

DEFINE TEMP-TABLE tt-pedidos NO-UNDO
       FIELD nr-pedcli   LIKE ped-venda.nr-pedcli
       FIELD nr-nota-fis LIKE nota-fiscal.nr-nota-fis
       FIELD cod-estabel LIKE nota-fiscal.cod-estabel
       FIELD serie       LIKE nota-fiscal.serie
       FIELD exportacao  AS LOG
       FIELD qt-faturada LIKE it-nota-fisc.qt-faturada
       FIELD vl-tot-item LIKE it-nota-fisc.vl-tot-item
       FIELD desc-pratic AS DEC.

DEFINE TEMP-TABLE tt-work NO-UNDO 
       FIELD nr-nota-fis  LIKE nota-fiscal.nr-nota-fis
       FIELD cod-estabel  LIKE nota-fiscal.cod-estabel
       FIELD serie        LIKE nota-fiscal.serie
       FIELD dt-emis-nota LIKE nota-fiscal.dt-emis-nota
       FIELD dt-saida     LIKE nota-fiscal.dt-saida
       FIELD nr-pedcli    LIKE ped-venda.nr-pedcli
       FIELD nr-pedrep    LIKE ped-venda.nr-pedrep
       FIELD nome-abrev   LIKE ped-venda.nome-abrev
       FIELD no-ab-reppri LIKE ped-venda.no-ab-reppri
       FIELD dt-implant   LIKE ped-venda.dt-implant
       FIELD dt-entrega   LIKE ped-venda.dt-entrega
       FIELD Sit          AS CHAR
       FIELD qtde         AS DEC
       FIELD desc-pratic  AS DEC
       FIELD valor        AS DEC
       FIELD prazo-medio  LIKE nota-fiscal.nr-praz-med.

DEFINE BUFFER b-tt-work FOR tt-work.

&GLOBAL-DEFINE SORTBY-PHRASE BY IF opt-sort = 1 ~
                                THEN STRING(tt-work.dt-entrega) + tt-work.nr-pedcli ~
                                ELSE IF opt-sort = 2 ~
                                     THEN tt-work.nr-nota-fis ~
                                     ELSE STRING(tt-work.dt-entrega) + tt-work.nr-pedcli 

&GLOBAL-DEFINE SORTBY-PRINT BY IF opt-sort = 1 ~
                               THEN STRING(b-tt-work.dt-entrega) + b-tt-work.nr-pedcli ~
                               ELSE IF opt-sort = 2 ~
                                    THEN b-tt-work.nr-nota-fis ~
                                    ELSE STRING(b-tt-work.dt-entrega) + b-tt-work.nr-pedcli 

DEFINE INPUT PARAMETER TABLE FOR tt-pedidos.  
DEFINE INPUT PARAMETER p-dt-faturar       AS CHAR.
DEFINE INPUT PARAMETER p-dt-faturadas-ini AS DATE.
DEFINE INPUT PARAMETER p-dt-faturadas-fin AS DATE.
DEFINE INPUT PARAMETER p-dt-vendido-ini   AS CHAR.
DEFINE INPUT PARAMETER p-dt-vendido-fin   AS CHAR.
DEFINE INPUT PARAMETER p-tipo-selecao     AS INT.

/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-ped-venda   AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR gr-nota-fiscal AS ROWID NO-UNDO.

DEF VAR h-acomp      AS HANDLE NO-UNDO.
DEF VAR h-query      AS HANDLE.
DEF VAR opt-sort     AS INT.
DEF VAR de-tot-qtd   AS DEC.
DEF VAR de-tot-vlr   AS DEC.
DEF VAR c-sit-ped    AS CHAR.
DEF VAR c-selecao    AS CHAR.
DEF VAR c-nr-pedcli  AS CHAR.
DEF VAR c-empresa    AS CHAR.
DEF VAR de-prazo     AS DEC.
DEF VAR i-qtd-nf     AS INT.

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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.nr-nota-fis tt-work.nr-pedcli tt-work.nr-pedrep tt-work.nome-abrev tt-work.no-ab-reppri tt-work.dt-emis-nota tt-work.dt-saida tt-work.dt-implant tt-work.dt-entrega tt-work.sit tt-work.qtde tt-work.valor tt-work.desc-pratic ((tt-work.valor + tt-work.desc-pratic) / tt-work.qtde) tt-work.prazo-medio   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK                                  ~{&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom br-work bt-detalhe-ped ~
bt-detalhe-nf bt-imprime bt-vapara bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-qtd fi-tot-vlr fi-tot-desc ~
fi-pco-medio fi-prazo-medio 

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
     SIZE 15 BY 1.25 TOOLTIP "Imprime Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-vapara 
     IMAGE-UP FILE "image/img-vapra.bmp":U
     LABEL "Impress∆o" 
     SIZE 13 BY 1.25 TOOLTIP "Va Para a Nota Fiscal".

DEFINE VARIABLE fi-pco-medio AS DECIMAL FORMAT " ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-prazo-medio AS DECIMAL FORMAT " ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-desc AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 10.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd AS DECIMAL FORMAT "    ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 122.43 BY 1.42
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
      tt-work.nr-nota-fis  COLUMN-LABEL "N.Fiscal"      WIDTH  6
      tt-work.nr-pedcli    COLUMN-LABEL "Ped Cli"       WIDTH  8
      tt-work.nr-pedrep    COLUMN-LABEL "Ped Rep"       WIDTH  9
      tt-work.nome-abrev   COLUMN-LABEL "Cliente"       WIDTH 12
      tt-work.no-ab-reppri COLUMN-LABEL "Representante" WIDTH 12
      tt-work.dt-emis-nota COLUMN-LABEL "Dt.Emiss∆o"    WIDTH 8.5
      tt-work.dt-saida     COLUMN-LABEL "Data Saida"    WIDTH 8.5
      tt-work.dt-implant   COLUMN-LABEL "Dt.Implant"    WIDTH 10
      tt-work.dt-entrega   COLUMN-LABEL "Dt.Entrega"    WIDTH 10
      tt-work.sit          COLUMN-LABEL "Sit"           WIDTH  3
      tt-work.qtde         COLUMN-LABEL "Quantidade"    WIDTH 10
      tt-work.valor        COLUMN-LABEL "Valor"         WIDTH 10
      tt-work.desc-pratic  COLUMN-LABEL "Desc. Pratic"  WIDTH 10
      ((tt-work.valor + tt-work.desc-pratic) /
       tt-work.qtde)       COLUMN-LABEL "Preáo MÇdio"
      tt-work.prazo-medio  COLUMN-LABEL "Prazo MÇdio"   WIDTH 9
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 123.29 BY 11.92
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1.72
     bt-detalhe-ped AT ROW 13.08 COL 2.57
     bt-detalhe-nf AT ROW 13.08 COL 18
     bt-imprime AT ROW 13.08 COL 36.57
     bt-vapara AT ROW 13.08 COL 52.29
     fi-tot-qtd AT ROW 13.08 COL 66 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr AT ROW 13.13 COL 78.43 COLON-ALIGNED NO-LABEL
     fi-tot-desc AT ROW 13.13 COL 90.86 COLON-ALIGNED NO-LABEL WIDGET-ID 2
     fi-pco-medio AT ROW 13.13 COL 102.14 COLON-ALIGNED NO-LABEL
     fi-prazo-medio AT ROW 13.13 COL 111.72 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     bt-ok AT ROW 14.79 COL 2.57
     bt-cancela AT ROW 14.79 COL 13.57
     bt-ajuda AT ROW 14.79 COL 112.72
     rt-buttom AT ROW 14.54 COL 1.57
     SPACE(1.56) SKIP(0.49)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Detalha Pedidos - ESSP0190C"
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

/* SETTINGS FOR FILL-IN fi-pco-medio IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-prazo-medio IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-desc IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK
                                 ~{&SORTBY-PHRASE}.
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Detalha Pedidos - ESSP0190C */
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


&Scoped-define SELF-NAME bt-vapara
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vapara D-Dialog
ON CHOOSE OF bt-vapara IN FRAME D-Dialog /* Impress∆o */
DO:
  IF p-tipo-selecao <> 2 THEN DO:
     RUN esdlg/d03essp0174.w (OUTPUT c-nr-pedcli).

     IF c-nr-pedcli <> ? THEN DO:
        FIND tt-work WHERE
             tt-work.nr-pedcli = c-nr-pedcli NO-LOCK NO-ERROR. 

        IF NOT AVAIL tt-work THEN DO.
           MESSAGE "Pedido n∆o est† contido na seleá∆o!"
               VIEW-AS ALERT-BOX INFO BUTTONS OK.
           RETURN NO-APPLY.
        END.
     END.
  END.
  ELSE DO:
      RUN esdlg/d01essp0164.w (OUTPUT c-nr-pedcli, INPUT NO).
      IF c-nr-pedcli <> "" THEN DO:
         FIND tt-work WHERE
              tt-work.nr-nota-fis = c-nr-pedcli NO-LOCK NO-ERROR.
         IF NOT AVAIL tt-work THEN DO:
            MESSAGE "Pedido n∆o est† contido na seleá∆o!"
                VIEW-AS ALERT-BOX INFO BUTTONS OK.
            RETURN NO-APPLY.
         END.
      END.
  END.
  h-query:REPOSITION-TO-ROWID(ROWID(tt-work)) NO-ERROR.
  APPLY 'value-changed' TO br-work IN FRAME {&FRAME-NAME}.
  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.


END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

ASSIGN h-query = br-work:QUERY.

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
  DISPLAY fi-tot-qtd fi-tot-vlr fi-tot-desc fi-pco-medio fi-prazo-medio 
      WITH FRAME D-Dialog.
  ENABLE rt-buttom br-work bt-detalhe-ped bt-detalhe-nf bt-imprime bt-vapara 
         bt-ok bt-cancela bt-ajuda 
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

  /* {utp/ut9000.i "ESSP0190C" "2.04.00.000"} */ 

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
  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cor D-Dialog 
PROCEDURE pi-cor :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF INPUT PARAMETER p-cor AS INT.

 tt-work.nr-pedcli:FGCOLOR IN BROWSE    {&browse-name} = p-cor.
 tt-work.nr-pedrep:FGCOLOR IN BROWSE    {&browse-name} = p-cor.
 tt-work.nome-abrev:FGCOLOR IN BROWSE   {&browse-name} = p-cor.
 tt-work.no-ab-reppri:FGCOLOR IN BROWSE {&browse-name} = p-cor.
 tt-work.dt-implant:FGCOLOR IN BROWSE   {&browse-name} = p-cor.
 tt-work.dt-entrega:FGCOLOR IN BROWSE   {&browse-name} = p-cor.
 tt-work.sit:FGCOLOR IN BROWSE          {&browse-name} = p-cor.
 tt-work.qtd:FGCOLOR IN BROWSE          {&browse-name} = p-cor.
 tt-work.valor:FGCOLOR IN BROWSE        {&browse-name} = p-cor. 

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
 PUT c-empresa FORMAT "x(40)"                  AT   1
     "DATA: "                                  AT  58
     STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  64
     "HORA: "                                  AT  85
     STRING(TIME,"hh:mm:ss")                   AT  91
     "PAG:"                                    AT 125
     i-pag FORMAT ">>"                         AT 130
     SKIP(1).

 CASE p-tipo-selecao:
     WHEN 1 THEN DO:
         PUT "ANALISE DA CARTEIRA A FATURAR NO PERIODO: " +  SUBSTR(p-dt-faturar,1,2) + "/"+ SUBSTR(p-dt-faturar,3,4) + 
             c-selecao FORMAT "x(100)" AT 25 SKIP(1).
         PUT "Ped Cli  Ped. Repres. Cliente      Representante Sit Dt.Implant Dt.Entrega   Qtde Vendida  Valor Vendido" AT 10.
         PUT " ------- ------------ ------------ ------------- --- ---------- ---------- -------------- --------------" AT 10.
     END.
     WHEN 2 THEN DO:
         PUT "ANALISE DO FATURAMENTO DE: " + STRING(p-dt-faturadas-ini, "99/99/9999") + " A " +  STRING(p-dt-faturadas-fin, "99/99/9999") +
             c-selecao FORMAT "x(100)" AT 25 SKIP(1).
         PUT "N.Fiscal Ped Cli Ped. Repres. Cliente      Representante  Dt.Implant Dt.Entrega   Qtde Vendida  Valor Vendido   Desc. Pratic P.Medio" AT 1.
         PUT "-------- ------- ------------ ------------ -------------- ---------- ---------- -------------- -------------- -------------- -------" AT 1.
     END.
     WHEN 3 THEN DO:
         PUT "ANALISE DAS VENDAS DE: " + SUBSTR(p-dt-vendido-ini,1,2) + "/"+ SUBSTR(p-dt-vendido-ini,3,4) + " A " +
                                         SUBSTR(p-dt-vendido-fin,1,2) + "/"+ SUBSTR(p-dt-vendido-fin,3,4) +
                                         c-selecao FORMAT "x(100)" AT 25 SKIP(1).
         PUT "Ped Cli  Ped. Repres. Cliente      Representante Sit Dt.Implant Dt.Entrega   Qtde Vendida  Valor Vendido" AT 10.
         PUT " ------- ------------ ------------ ------------- --- ---------- ---------- -------------- --------------" AT 10.
     END.
 END CASE.
 
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

 DEF VAR i-col AS INT INITIAL 0.

 IF p-tipo-selecao = 2 THEN
    ASSIGN i-col = 4.

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
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0190c.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.

 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-pag      =  1
           i-lin      = 99.
    FOR EACH b-tt-work NO-LOCK
            {&SORTBY-PRINT}.

        IF i-lin > 62 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
        IF p-tipo-selecao = 2 THEN
           PUT b-tt-work.nr-nota-fis  FORMAT "x(7)"    AT 01
               b-tt-work.nr-pedcli    FORMAT "x(6)"    AT 10   
               b-tt-work.nr-pedrep                     AT 19   
               b-tt-work.nome-abrev                    AT 32   
               b-tt-work.no-ab-reppri                  AT 45   
               b-tt-work.dt-emis-nota                  AT 59   
               b-tt-work.dt-saida                      AT 70   
               b-tt-work.qtde  FORMAT ">>>,>>>,>>9.99" AT 81   
               b-tt-work.valor FORMAT ">>>,>>>,>>9.99" AT 96
               b-tt-work.desc-pratic FORMAT ">>>,>>>,>>9.99" AT 111
               (b-tt-work.valor + b-tt-work.desc-pratic) /
                b-tt-work.qtde       FORMAT ">>>9.99"        AT 126.
        ELSE
           PUT b-tt-work.nr-pedcli  FORMAT "x(6)"      AT 10
               b-tt-work.nr-pedrep                     AT 19
               b-tt-work.nome-abrev                    AT 32
               b-tt-work.no-ab-reppri                  AT 45
               b-tt-work.sit  FORMAT "x(3)"            AT 59
               b-tt-work.dt-implant                    AT 63
               b-tt-work.dt-entrega                    AT 74
               b-tt-work.qtde  FORMAT ">>>,>>>,>>9.99" AT 85
               b-tt-work.valor FORMAT ">>>,>>>,>>9.99" AT 100.

        ASSIGN i-lin = i-lin + 1.
        ACCUMULATE b-tt-work.qtde (TOTAL).
        ACCUMULATE b-tt-work.valor (TOTAL).
        ACCUMULATE b-tt-work.desc-pratic (TOTAL).
    END.
    IF (ACCUM TOTAL b-tt-work.qtde)  <> 0 OR
       (ACCUM TOTAL b-tt-work.valor) <> 0 THEN DO:
       IF i-lin > 59 THEN DO:
          RUN pi-imp-cabec.
          ASSIGN i-lin = 7.
       END.
       PUT "-------------- -------------- --------------" AT (85 - i-col) SKIP.
       PUT "Total Geral.........:"              AT (63 - i-col).
       PUT ACCUM TOTAL b-tt-work.qtde  FORMAT ">>>,>>>,>>9.99" AT (85 - i-col).
       PUT ACCUM TOTAL b-tt-work.valor FORMAT ">>>,>>>,>>9.99" AT (100 - i-col).
       PUT ACCUM TOTAL b-tt-work.desc-pratic FORMAT ">>>,>>>,>>9.99" AT (115 - i-col).
    END.
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-nota-fiscal D-Dialog 
PROCEDURE pi-nota-fiscal :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  FOR EACH tt-pedidos.

      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
           nota-fiscal.serie       = tt-pedidos.serie       AND
           nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.
      IF NOT AVAIL nota-fiscal THEN NEXT.

      RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(nota-fiscal.dt-emis-nota) +
                                          " Nota Fiscal: " + nota-fiscal.nr-nota-fis).
      
      FIND ped-venda WHERE
           ped-venda.nome-abrev = nota-fiscal.nome-ab-cli AND
           ped-venda.nr-pedcli  = nota-fiscal.nr-pedcli NO-LOCK NO-ERROR.

      FIND tt-work WHERE
           tt-work.cod-estabel = nota-fiscal.cod-estabel AND
           tt-work.serie       = nota-fiscal.serie       AND
           tt-work.nr-nota-fis = nota-fiscal.nr-nota-fis NO-LOCK NO-ERROR.
      IF NOT AVAIL tt-work THEN DO:
         CREATE tt-work.
         ASSIGN tt-work.nr-nota-fis  = nota-fiscal.nr-nota-fis
                tt-work.cod-estabel  = tt-pedidos.cod-estabel
                tt-work.serie        = tt-pedidos.serie
                tt-work.nr-pedcli    = nota-fiscal.nr-pedcli
                tt-work.nr-pedrep    = IF AVAIL ped-venda THEN ped-venda.nr-pedrep
                                                          ELSE ""
                tt-work.nome-abrev   = nota-fiscal.nome-ab-cli
                tt-work.no-ab-reppri = nota-fiscal.no-ab-reppri
                tt-work.dt-emis-nota = nota-fiscal.dt-emis-nota
                tt-work.dt-saida     = nota-fiscal.dt-saida
                tt-work.prazo-medio  = nota-fiscal.nr-praz-med
                tt-work.qtde         = tt-pedidos.qt-faturada[1] 
                tt-work.desc-pratic  = tt-pedidos.desc-pratic
                tt-work.valor        = tt-pedidos.vl-tot-item. 
      END.
  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-pedidos D-Dialog 
PROCEDURE pi-pedidos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 FOR EACH tt-pedidos NO-LOCK.
     FIND ped-venda WHERE 
          ped-venda.nr-pedcli = tt-pedidos.nr-pedcli NO-LOCK NO-ERROR.
     IF NOT AVAIL ped-venda THEN NEXT.

     RUN pi-acompanhar IN h-acomp (INPUT "   Data: " + STRING(ped-venda.dt-implant) +
                                         " Pedido: " + ped-venda.nr-pedcli).

     FIND emitente WHERE
          emitente.nome-abrev = ped-venda.nome-abrev NO-LOCK NO-ERROR.
     IF NOT AVAIL emitente THEN NEXT.

     FIND natur-oper WHERE
          natur-oper.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
     IF NOT AVAIL natur-oper THEN NEXT.

     ASSIGN de-tot-qtd = 0
            de-tot-vlr = 0.
     FOR EACH ped-item OF ped-venda WHERE
              LOOKUP(STRING(ped-item.cod-sit-item),c-sit-ped) > 0 NO-LOCK.
         ASSIGN de-tot-qtd = de-tot-qtd + ped-item.qt-pedida
                de-tot-vlr = de-tot-vlr + (ped-item.qt-pedida * ped-item.vl-preuni).
     END.
     IF de-tot-qtd + de-tot-vlr = 0 THEN NEXT.

     FIND tt-work WHERE
          tt-work.nr-pedcli = ped-venda.nr-pedcli NO-LOCK NO-ERROR.
     IF NOT AVAIL tt-work THEN DO:
        CREATE tt-work.
        ASSIGN tt-work.nr-pedcli    = ped-venda.nr-pedcli
               tt-work.nr-pedrep    = ped-venda.nr-pedrep
               tt-work.nome-abrev   = ped-venda.nome-abrev
               tt-work.no-ab-reppri = ped-venda.no-ab-reppri
               tt-work.dt-implant   = ped-venda.dt-implant
               tt-work.dt-entrega   = ped-venda.dt-entrega
               tt-work.qtde         = de-tot-qtd
               tt-work.valor        = de-tot-vlr.
        CASE ped-venda.cod-sit-ped.
             WHEN 1 THEN ASSIGN tt-work.sit = 'ABE'.
             WHEN 2 THEN ASSIGN tt-work.sit = 'ATP'.
             WHEN 3 THEN ASSIGN tt-work.sit = 'ATT'.
             WHEN 4 THEN ASSIGN tt-work.sit = 'PEN'.
             WHEN 5 THEN ASSIGN tt-work.sit = 'SUS'.
             WHEN 6 THEN ASSIGN tt-work.sit = 'CAN'.
        END CASE.
     END.
 END.

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

 ASSIGN opt-sort = p-tipo-selecao.

 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Calculando_Valores *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 tt-work.nr-nota-fis:VISIBLE IN BROWSE br-work  = NO.  
 tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = NO.    
 tt-work.nr-pedrep:VISIBLE IN BROWSE br-work    = NO.
 tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = NO.   
 tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = NO. 
 tt-work.dt-emis-nota:VISIBLE IN BROWSE br-work = NO. 
 tt-work.dt-saida:VISIBLE IN BROWSE br-work     = NO.     
 tt-work.dt-implant:VISIBLE IN BROWSE br-work   = NO.   
 tt-work.dt-entrega:VISIBLE IN BROWSE br-work   = NO.   
 tt-work.sit:VISIBLE IN BROWSE br-work          = NO.          
 tt-work.qtde:VISIBLE IN BROWSE br-work         = NO.         
 tt-work.valor:VISIBLE IN BROWSE br-work        = NO.        

 CASE p-tipo-selecao:
     WHEN 1 THEN DO:
         ASSIGN c-sit-ped = "1,2,4,5". /* Aberto, Atendido Parcial,Pendente,Suspendo */
         tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = YES.    
         tt-work.nr-pedrep:VISIBLE IN BROWSE br-work    = YES.
         tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-implant:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.dt-entrega:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.sit:VISIBLE IN BROWSE br-work          = YES.          
         tt-work.qtde:VISIBLE IN BROWSE br-work         = YES.         
         tt-work.valor:VISIBLE IN BROWSE br-work        = YES.        
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DA CARTEIRA A FATURAR NO PERIODO: " + 
                                                        SUBSTR(p-dt-faturar,1,2) + "/"+ SUBSTR(p-dt-faturar,3,4).
         RUN pi-pedidos.
     END.
     WHEN 2 THEN DO:
         tt-work.nr-nota-fis:VISIBLE IN BROWSE br-work  = YES.  
         tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = YES.    
         tt-work.nr-pedrep:VISIBLE IN BROWSE br-work    = YES.
         tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-emis-nota:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-saida:VISIBLE IN BROWSE br-work     = YES.     
         tt-work.qtde:VISIBLE IN BROWSE br-work         = YES.         
         tt-work.valor:VISIBLE IN BROWSE br-work        = YES.        
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DO FATURAMENTO DE: " +
                                                        STRING(p-dt-faturadas-ini, "99/99/9999") + " A " + 
                                                        STRING(p-dt-faturadas-fin, "99/99/9999").
         RUN pi-nota-fiscal.
         APPLY 'VALUE-CHANGED' to br-work.
     END.
     WHEN 3 THEN DO:
         ASSIGN c-sit-ped = "1,2,3,4,5". /* Aberto, Atendido Parcial,Atendito Total, Pendente,Suspendo */
         tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = YES.    
         tt-work.nr-pedrep:VISIBLE IN BROWSE br-work    = YES.
         tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-implant:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.dt-entrega:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.sit:VISIBLE IN BROWSE br-work          = YES.          
         tt-work.qtde:VISIBLE IN BROWSE br-work         = YES.         
         tt-work.valor:VISIBLE IN BROWSE br-work        = YES.        
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DAS VENDAS DE: " +
                                                        SUBSTR(p-dt-vendido-ini,1,2) + "/"+ SUBSTR(p-dt-vendido-ini,3,4) + " A " +
                                                        SUBSTR(p-dt-vendido-fin,1,2) + "/"+ SUBSTR(p-dt-vendido-fin,3,4).
         RUN pi-pedidos.
     END.
 END CASE.
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
 ASSIGN fi-tot-qtd  = 0
        fi-tot-desc = 0
        de-prazo    = 0
        i-qtd-nf    = 0
        fi-tot-vlr  = 0.
 FOR EACH tt-work NO-LOCK.
     ASSIGN fi-tot-qtd  = fi-tot-qtd  + tt-work.qtde  
            fi-tot-desc = fi-tot-desc + tt-work.desc-pratic
            fi-tot-vlr  = fi-tot-vlr  + tt-work.valor
            de-prazo    = de-prazo    + tt-work.prazo-medio
            i-qtd-nf    = i-qtd-nf    + 1.
 END.
 ASSIGN fi-pco-medio = (fi-tot-vlr + fi-tot-desc) / fi-tot-qtd
        fi-prazo-medio = de-prazo / i-qtd-nf.
 DISP fi-tot-qtd 
      fi-tot-vlr
      fi-tot-desc
      fi-pco-medio
      fi-prazo-medio
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


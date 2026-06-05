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
{utp/utapi011.i} /* Geraá∆o de Graficos */

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
       FIELD it-codigo    LIKE item.it-codigo
       FIELD desc-item    LIKE item.desc-item
       FIELD classif      LIKE fam-comerc.descricao
       INDEX indice1 it-codigo.

DEFINE TEMP-TABLE tt-semanas NO-UNDO 
       FIELD semana        AS INTEGER
       FIELD dt-ini-semana AS DATE
       FIELD dt-fin-semana AS DATE.

DEFINE TEMP-TABLE tt-semanal NO-UNDO 
       FIELD semana        AS INTEGER
       FIELD it-codigo     LIKE item.it-codigo
       FIELD qtde          AS DECIMAL
       FIELD valor         AS DECIMAL.

DEFINE BUFFER b-tt-work FOR tt-work.

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

DEF VAR c-titulo     AS CHAR.
DEF VAR c-sub-tit    AS CHAR.
DEF VAR c-regiao     AS CHAR.
DEF VAR c-lote-refer AS CHAR.

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
DEF VAR i-qt-sem     AS INT.

DEF VAR wh-semanas AS WIDGET-HANDLE EXTENT 260.


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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.it-codigo tt-work.desc-item tt-work.classif   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-work rt-buttom bt-grafico-qtd ~
bt-grafico-vlr bt-imprime bt-excel bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-qtd fi-tot-vlr fi-tot-desc ~
fi-pco-medio fi-prazo-medio 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-6 bt-excel 

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

DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/excel.bmp":U
     LABEL "Button 2" 
     SIZE 5 BY 1.21 TOOLTIP "Gerar Planilha".

DEFINE BUTTON bt-grafico-qtd 
     IMAGE-UP FILE "image/img-graf.bmp":U
     LABEL "Impress∆o do Grafico de Quantidades" 
     SIZE 15 BY 1.25 TOOLTIP "Visualizaá∆o/Impress∆o do Grafico QUANTIDADES".

DEFINE BUTTON bt-grafico-vlr 
     IMAGE-UP FILE "image/img-graf1.bmp":U
     LABEL "Impress∆o do Gr†fico de Valores" 
     SIZE 15 BY 1.25 TOOLTIP "Visualizaá∆o/Impress∆o do Grafico VALORES".

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/im-pri.bmp":U
     LABEL "Impress∆o" 
     SIZE 4 BY 1.25 TOOLTIP "Imprime Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

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
     SIZE 123.43 BY 1.42
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
      tt-work.it-codigo    COLUMN-LABEL "Item"           WIDTH  6
      tt-work.desc-item    COLUMN-LABEL "Descriá∆o"      WIDTH 30
      tt-work.classif      COLUMN-LABEL "Classificaá∆o"  WIDTH 17
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 124 BY 11.75
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1
     bt-grafico-qtd AT ROW 13 COL 2 WIDGET-ID 18
     bt-grafico-vlr AT ROW 13 COL 17.86 WIDGET-ID 20
     bt-imprime AT ROW 13 COL 33.43
     bt-excel AT ROW 13 COL 38 WIDGET-ID 22
     fi-tot-qtd AT ROW 13.5 COL 49 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr AT ROW 13.5 COL 64 COLON-ALIGNED NO-LABEL
     fi-tot-desc AT ROW 13.5 COL 79 COLON-ALIGNED NO-LABEL WIDGET-ID 2
     fi-pco-medio AT ROW 13.5 COL 92 COLON-ALIGNED NO-LABEL
     fi-prazo-medio AT ROW 13.5 COL 103 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     bt-ok AT ROW 14.79 COL 2.57
     bt-cancela AT ROW 14.79 COL 13.57
     bt-ajuda AT ROW 14.79 COL 112.72
     "Prz Medio" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 12.88 COL 105.14 WIDGET-ID 16
     "Qtde Total" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 12.88 COL 55.57 WIDGET-ID 8
     "Valor Total" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 12.88 COL 70.43 WIDGET-ID 10
     "Desconto" VIEW-AS TEXT
          SIZE 7 BY .54 AT ROW 12.88 COL 84.57 WIDGET-ID 12
     "Preáo Medio" VIEW-AS TEXT
          SIZE 9 BY .54 AT ROW 12.88 COL 94 WIDGET-ID 14
     rt-buttom AT ROW 14.54 COL 1.57
     SPACE(0.56) SKIP(0.11)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Faturamento Semanal - ESSP0190g"
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
/* BROWSE-TAB br-work 1 D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR BUTTON bt-excel IN FRAME D-Dialog
   6                                                                    */
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Faturamento Semanal - ESSP0190g */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON ROW-DISPLAY OF br-work IN FRAME D-Dialog
DO:

  FOR EACH tt-semanas NO-LOCK.
      FIND tt-semanal WHERE
           tt-semanal.semana = tt-semanas.semana AND
           tt-semanal.it-codigo = tt-work.it-codigo NO-LOCK NO-ERROR.

      IF AVAIL tt-semanal AND
         VALID-HANDLE(wh-semanas[tt-semanal.semana]) THEN
         wh-semanas[tt-semanal.semana]:SCREEN-VALUE = STRING(tt-semanal.valor).
  END.
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


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel D-Dialog
ON CHOOSE OF bt-excel IN FRAME D-Dialog /* Button 2 */
DO:
   OUTPUT TO VALUE(SESSION:TEMP-DIRECTORY + "essp0190.csv").

   PUT "ITEM;DESCRIÄ«O;CLASSIF;".
   ASSIGN i-qt-sem = 0.
   FOR EACH tt-semanas.
       ASSIGN i-qt-sem = i-qt-sem + 1.

       PUT UNFORMATTED 
           STRING(DAY(tt-semanas.dt-ini-semana),"99") + "/" + 
           STRING(MONTH(tt-semanas.dt-ini-semana),"99") +  
           " a " +  
           STRING(DAY(tt-semanas.dt-fin-semana),"99") + "/" + 
           STRING(MONTH(tt-semanas.dt-fin-semana),"99") 
           ";".
   END.
   PUT "" SKIP.

   FOR EACH b-tt-work NO-LOCK.
       PUT b-tt-work.it-codigo ";" 
           b-tt-work.desc-item ";"
           b-tt-work.classif ";".

       DO i-ct = 1 TO i-qt-sem.
          FIND tt-semanal WHERE
               tt-semanal.semana = i-ct AND 
               tt-semanal.it-codigo = b-tt-work.it-codigo NO-LOCK NO-ERROR.

          IF AVAIL tt-semanal THEN
             PUT tt-semanal.valor ";".
           ELSE
             PUT "0,00" ";".
       END.
       PUT "" SKIP.
   END.

   OUTPUT CLOSE.


   MESSAGE 'Gerado Arquivo c:\temp\essp0190.csv' 
       VIEW-AS ALERT-BOX INFO BUTTONS OK.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-grafico-qtd
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-grafico-qtd D-Dialog
ON CHOOSE OF bt-grafico-qtd IN FRAME D-Dialog /* Impress∆o do Grafico de Quantidades */
DO:
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
  RUN pi-grafico (INPUT 1).
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-grafico-vlr
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-grafico-vlr D-Dialog
ON CHOOSE OF bt-grafico-vlr IN FRAME D-Dialog /* Impress∆o do Gr†fico de Valores */
DO:
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
  RUN pi-grafico (INPUT 2).
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
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


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

ASSIGN h-query = br-work:QUERY.

br-work:NUM-LOCKED-COLUMNS = 2.

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
  ENABLE br-work rt-buttom bt-grafico-qtd bt-grafico-vlr bt-imprime bt-excel 
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

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-gera-excel D-Dialog 
PROCEDURE pi-gera-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  /*
  RUN pi-excel-cabec (INPUT 1,
                      INPUT "Item").
  ASSIGN i-Lin    = 4.
  
  FOR EACH b-tt-work NO-LOCK.
      
      ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.it-codigo
             chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.desc-item.

      /*
      ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.lote
             chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.und
             chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.qtd
             chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.vlr
             chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.
      IF i-tp-selecao = 2 THEN
         ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.qtd-devol
                chworksheet:range("I" + STRING(i-lin)):VALUE = b-tt-work.vlr-devol
                chworksheet:range("J" + STRING(i-lin)):VALUE = b-tt-work.rentabilidade
                chworksheet:range("K" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.
      ELSE
          ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.


      /*  Configura Tamanho da Fonte */
      ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
             chworksheet:Rows(c-lin):FONT:SIZE = 9.

      IF b-tt-work.uf <> "ZZ" THEN DO:
         ACCUMULATE b-tt-work.qtd (TOTAL).
         ACCUMULATE b-tt-work.vlr (TOTAL).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL).
         ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.it-codigo).
         ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.it-codigo).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL BY b-tt-work.it-codigo).
      END.
      ASSIGN i-Lin = i-Lin + 1.
      IF LAST-OF(b-tt-work.it-codigo) THEN DO:
         ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo  b-tt-work.qtd)
                chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo b-tt-work.vlr)
                chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo b-tt-work.vlr-devol).
         /* Colorir a Linha / Negrito */
         chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
         chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:Bold           = TRUE.
         ASSIGN i-lin = i-lin + 1.
      END.
      */
  END.
  */
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grafico D-Dialog 
PROCEDURE pi-grafico :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT PARAMETER p-tipo-grafico AS INT.

 DEF VAR i-point   AS INT INITIAL 1.
 DEF VAR i-numsets AS INT.
 DEF VAR de-work   AS DEC.
 DEF VAR c-desc    AS CHAR.
 DEF VAR h-utapi011 AS HANDLE NO-UNDO.


 EMPTY TEMP-TABLE tt-atributos.
 EMPTY TEMP-TABLE tt-sets.
 EMPTY TEMP-TABLE tt-points-2.
 EMPTY TEMP-TABLE tt-dados.
 EMPTY TEMP-TABLE tt-erros.

 IF p-tipo-grafico = 1 THEN
    ASSIGN c-desc = "Quantidade em METROS.".
 ELSE
    ASSIGN c-desc = "Valores em Real (R$).".


 /* Configuraá∆o Geral do Grafico */
 CREATE tt-atributos.
 ASSIGN tt-atributos.cod-versao-integracao = 3
        tt-atributos.graphtype             = 3
        tt-atributos.graphtitle            = c-titulo
        tt-atributos.lefttitle             = c-desc
        tt-atributos.lefttitlestyle        = 1
        tt-atributos.bottomtitle           = "Data INI Semana"
        tt-atributos.numgraph              = 1.
                                             
 /* Configuraá∆o das Variantes do Grafico */
 ASSIGN i-numsets = 1.
 CREATE tt-sets.
 ASSIGN tt-sets.NumSet     = i-numsets 
        tt-sets.NumGraph   = 1
        tt-sets.ColorSet   = 1
        tt-sets.legendText = "Data INI Semana".

 /*
 ASSIGN de-work = 0.
 FOR EACH b-tt-semanal NO-LOCK.

     IF p-tipo-grafico = 1 THEN
        ASSIGN de-work = de-work + b-tt-semanal.qtd.
     ELSE
        ASSIGN de-work = de-work + b-tt-semanal.valor.

     /* Valores do EIXO X (SEMANA) */
     CREATE tt-points-2.
     ASSIGN tt-points-2.NumPoint  = i-point
            tt-points-2.NumGraph  = 1
            tt-points-2.labeltext = STRING(b-tt-semanal.dt-ini-semana).

     /* Valores do EIXO Y (QUANTIDADE / VALORES) */
     ASSIGN i-numsets = 1.
     CREATE tt-dados.
     ASSIGN tt-dados.NumPoint   = i-point
            tt-dados.NumSet     = i-numsets
            tt-dados.NumGraph   = 1
            tt-dados.graphdata  = de-work.

     ASSIGN i-numsets = i-numsets + 1 
            i-point   = i-point   + 1
            de-work   = 0.
 END.
 */
 RUN utp/utapi011.p PERSISTENT SET h-utapi011.

 RUN pi-execute IN h-utapi011 (INPUT  TABLE tt-atributos,
                               INPUT  TABLE tt-points-2,
                               INPUT  TABLE tt-sets,
                               INPUT  TABLE tt-dados,
                               INPUT  TABLE tt-ylabels,
                               OUTPUT TABLE tt-erros).

 IF RETURN-VALUE = "NOK" THEN DO: 
    FOR EACH tt-erros: 
        DISP cod-erro desc-erro FORMAT "x(100)" WITH 1 COL WIDTH 500. 
    END.
 END.                  

 DELETE PROCEDURE h-utapi011.
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

 /*
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
 */
 
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
   DEF VAR d-data AS DATE.
   DEF VAR d2 AS DATE.
   DEF VAR i-semana AS INTEGER.

   ASSIGN i-semana = 0.
   DO d-data = p-dt-faturadas-ini TO p-dt-faturadas-fin.
      ASSIGN d2 = 7 - WEEKDAY(d-data) + d-data.
      IF d2 > p-dt-faturadas-fin THEN
         ASSIGN d2 = p-dt-faturadas-fin.

      ASSIGN i-semana = i-semana + 1.
      CREATE tt-semanas.
      ASSIGN tt-semanas.semana = i-semana
             tt-semanas.dt-ini-semana = d-data
             tt-semanas.dt-fin-semana = d2.
      ASSIGN d-data = d2.
  END.

  DO i-ct = 1 TO EXTENT(wh-semanas).
     IF VALID-HANDLE(wh-semanas[i-ct]) THEN
        DELETE WIDGET wh-semanas[i-ct].
  END.

  FOR EACH tt-semanas.
      IF NOT VALID-HANDLE(wh-semanas[tt-semanas.semana]) THEN
         wh-semanas[tt-semanas.semana] = br-work:ADD-CALC-COLUMN("dec",
                                                                 ">>>,>>>,>>9.99",
                                                                 "",
                                                                 STRING(DAY(tt-semanas.dt-ini-semana),"99") + "/" + 
                                                                 STRING(MONTH(tt-semanas.dt-ini-semana),"99") +  
                                                                 " a " +  
                                                                 STRING(DAY(tt-semanas.dt-fin-semana),"99") + "/" + 
                                                                 STRING(MONTH(tt-semanas.dt-fin-semana),"99") ) IN FRAME {&FRAME-NAME}.
  END.

  FOR EACH tt-pedidos.

      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
           nota-fiscal.serie       = tt-pedidos.serie       AND
           nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.
      IF NOT AVAIL nota-fiscal THEN NEXT.


      RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(nota-fiscal.dt-emis-nota) +
                                          " Nota Fiscal: " + nota-fiscal.nr-nota-fis).

      FIND tt-semanas WHERE
           tt-semanas.dt-ini-semana <= nota-fiscal.dt-emis-nota AND
           tt-semanas.dt-fin-semana >= nota-fiscal.dt-emis-nota NO-ERROR.

      FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
          FIND item WHERE
               item.it-codigo = it-nota-fisc.it-codigo NO-LOCK NO-ERROR.

          FIND fam-comerc WHERE
               fam-comerc.fm-cod-com = ITEM.fm-cod-com NO-LOCK NO-ERROR.

          FIND tt-work WHERE
               tt-work.it-codigo = it-nota-fisc.it-codigo  NO-LOCK NO-ERROR.
          IF NOT AVAIL tt-work THEN DO:
             CREATE tt-work.
             ASSIGN tt-work.it-codigo = it-nota-fisc.it-codigo
                    tt-work.desc-item = item.desc-item
                    tt-work.classif   = fam-comerc.descricao.
          END.

          FIND tt-semanal WHERE
               tt-semanal.it-codigo = it-nota-fisc.it-codigo AND
               tt-semanal.semana = tt-semanas.semana NO-ERROR.
          IF NOT AVAIL tt-semanal THEN DO.
             CREATE tt-semanal.
             ASSIGN tt-semanal.it-codigo = it-nota-fisc.it-codigo 
                    tt-semanal.semana = tt-semanas.semana.
          END.
          ASSIGN tt-semanal.qtde = tt-semanal.qtde + it-nota-fisc.qt-faturada[1]
                 tt-semanal.valor = tt-semanal.valor + it-nota-fisc.vl-tot-item +
                                    IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                                    THEN it-nota-fisc.val-desconto-total 
                                    ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)).
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

 ASSIGN br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE SEMANAL DO FATURAMENTO DE: " +
                                               STRING(p-dt-faturadas-ini, "99/99/9999") + " A " + 
                                               STRING(p-dt-faturadas-fin, "99/99/9999").
 RUN pi-nota-fiscal.

 RUN pi-finalizar in h-acomp.
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.

 {&OPEN-QUERY-br-work}
 APPLY 'VALUE-CHANGED' to br-work.

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

 FOR EACH tt-semanal NO-LOCK.
     ASSIGN fi-tot-qtd  = fi-tot-qtd  + tt-semanal.qtde  
            /*fi-tot-desc = fi-tot-desc + tt-work.desc-pratic*/
            fi-tot-vlr  = fi-tot-vlr  + tt-semanal.valor
            /*de-prazo    = de-prazo    + tt-work.prazo-medio*/
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


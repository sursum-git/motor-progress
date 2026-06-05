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
{include/i-prgvrs.i ESSP0190E1 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
DEF BUFFER empresa FOR mgcad.empresa.

/* Parameters Definitions ---                                           */
DEF TEMP-TABLE tt-trab      NO-UNDO
    FIELD no-ab-reppri      LIKE repres.nome
    FIELD cod-rep           LIKE repres.cod-rep
    FIELD Und               AS CHAR
    FIELD qtd               AS DEC
    FIELD vlr               AS DEC
    FIELD desc-pratic       AS DEC
    FIELD preco-medio       AS DEC
    FIELD qtd-devol         AS DEC
    FIELD vlr-devol         AS DEC.


DEF TEMP-TABLE tt-work      NO-UNDO
    FIELD no-ab-reppri      LIKE repres.nome
    FIELD cod-rep           LIKE repres.cod-rep
    FIELD vlr               AS DEC
    FIELD vlr-devol         AS DEC.

DEF BUFFER b-tt-work FOR tt-work.                                                         

/* PARAMETROS RECEBIDOS */
DEFINE INPUT PARAMETER TABLE FOR tt-trab. 
DEFINE INPUT PARAMETER p-titulo AS CHAR.

/* Local Variable Definitions ---                                       */
DEF VAR h-acomp   AS HANDLE NO-UNDO.
DEF VAR c-codigo  AS CHAR.
DEF VAR c-titulo  AS CHAR.
DEF VAR h-query   AS HANDLE. 
DEF VAR c-empresa AS CHAR.
DEF VAR de-valor  AS DEC.
DEF VAR de-devol  AS DEC.

/* Variaveis para o Excel */
DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF VAR chworksheet AS COM-HANDLE NO-UNDO.
DEF VAR c-lin       AS CHAR FORMAT "x(500)".
DEF VAR arq-saida   AS CHAR FORMAT "x(65)".

/* Variaveis da Rotina de Impress∆o */
DEFINE VAR l-ok         AS LOG.
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-ct         AS INT.
DEFINE VAR i-lin        AS INT.
DEFINE VAR i-pag        AS INT.

/* Variaveis da Rotina de CLASSIFICAÄ«O POR COLUNAS DO BROWSE */
DEFINE VAR  h-col      AS HANDLE.
DEFINE VAR  i-col      AS INT.
DEFINE VAR sort-col    AS INT INIT 1.
DEFINE VAR order-col   AS INT INIT 1.
DEFINE VAR c-label     AS CHAR.
DEFINE VAR c-label-ori AS CHAR.

/* Preprocessor usado na Classificaá∆o do Browse */
&GLOBAL-DEFINE SORTBY-PHRASE BY IF sort-col = 1 ~
                                 THEN STRING(tt-work.cod-rep, ">>>>>9") ~
                                ELSE IF sort-col = 2 ~
                                     THEN tt-work.no-ab-reppri ~
                                    ELSE IF sort-col = 3 ~
                                         THEN STRING(tt-work.vlr, "999,999,999.99") ~
                                         ELSE STRING(tt-work.vlr-devol, "999,999,999.99") ~

/* Preprocessor usado na Classificaá∆o do Relatorio Impress∆o / Gerar EXCEL */
&GLOBAL-DEFINE SORTBY-IMP-EXCEL BY IF sort-col = 1 ~
                                 THEN STRING(b-tt-work.cod-rep, ">>>>>9") ~
                                ELSE IF sort-col = 2 ~
                                     THEN b-tt-work.no-ab-reppri ~
                                    ELSE IF sort-col = 3 ~
                                         THEN STRING(b-tt-work.vlr, "999,999,999.99") ~
                                         ELSE STRING(b-tt-work.vlr-devol, "999,999,999.99") ~

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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.cod-rep tt-work.no-ab-reppri tt-work.vlr tt-work.vlr-devol   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work tt-work.cod-rep   tt-work.no-ab-reppri   tt-work.vlr   tt-work.vlr-devol   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-work tt-work
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY br-work FOR EACH tt-work NO-LOCK {&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-work RECT-1 rt-buttom bt-vapara bt-excel ~
bt-imprime bt-exit bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-geral fi-tot-devol 

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
     SIZE 5.86 BY 1.5 TOOLTIP "Gerar Planilha".

DEFINE BUTTON bt-exit AUTO-END-KEY 
     IMAGE-UP FILE "image/im-exi.bmp":U
     LABEL "" 
     SIZE 5.86 BY 1.5 TOOLTIP "Fechar Programa"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/im-pri.bmp":U
     LABEL "" 
     SIZE 5.86 BY 1.5 TOOLTIP "Imprimir Informaá‰es do Browse.".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-vapara AUTO-GO 
     IMAGE-UP FILE "image/im-vapra.bmp":U
     LABEL "" 
     SIZE 5.86 BY 1.5 TOOLTIP "Posicionar no Item"
     BGCOLOR 8 FONT 10.

DEFINE VARIABLE fi-tot-devol AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 4  NO-UNDO.

DEFINE VARIABLE fi-tot-geral AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 4  NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 6.86 BY 17.54.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 71.43 BY 1.42
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
      tt-work.cod-rep         COLUMN-LABEL "Cod.Rep"              FORMAT ">>>>9"              WIDTH 07.5
      tt-work.no-ab-reppri    COLUMN-LABEL "Representante"        FORMAT "x(35)"              WIDTH 35.2 
      tt-work.vlr             COLUMN-LABEL "Valor"                FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 11.5
      tt-work.vlr-devol       COLUMN-LABEL "Valor Devoluá∆o"      FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 12.2
ENABLE
    tt-work.cod-rep
    tt-work.no-ab-reppri
    tt-work.vlr
    tt-work.vlr-devol
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 71.43 BY 15.25
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1.57
     bt-vapara AT ROW 1.38 COL 74.14
     bt-excel AT ROW 2.92 COL 74.14
     bt-imprime AT ROW 4.5 COL 74.14
     fi-tot-geral AT ROW 16.38 COL 43.72 COLON-ALIGNED NO-LABEL
     fi-tot-devol AT ROW 16.38 COL 56.43 COLON-ALIGNED NO-LABEL
     bt-exit AT ROW 16.83 COL 74.14
     bt-ok AT ROW 17.58 COL 2.57
     bt-cancela AT ROW 17.58 COL 13.57
     bt-ajuda AT ROW 17.58 COL 61.72
     "TOTAIS:" VIEW-AS TEXT
          SIZE 5.86 BY .71 AT ROW 16.46 COL 39.14
          FGCOLOR 4 
     RECT-1 AT ROW 1.08 COL 73.57
     rt-buttom AT ROW 17.33 COL 1.57
     SPACE(8.13) SKIP(0.03)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "TOTALIZADOR - ESSP0190E"
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
/* BROWSE-TAB br-work TEXT-1 D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR BUTTON bt-excel IN FRAME D-Dialog
   6                                                                    */
/* SETTINGS FOR FILL-IN fi-tot-devol IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-geral IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY br-work FOR EACH tt-work NO-LOCK {&SORTBY-PHRASE}.
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* TOTALIZADOR - ESSP0190E */
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
  IF tt-work.vlr-devol = 0 THEN 
     tt-work.vlr-devol:FGCOLOR IN BROWSE br-work = 15.
  IF tt-work.vlr-devol <> 0 THEN
     tt-work.vlr-devol:FGCOLOR IN BROWSE br-work = 12.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON START-SEARCH OF br-work IN FRAME D-Dialog
DO:
   ASSIGN h-col = br-work:CURRENT-COLUMN.

   DO i-col = 1 TO br-work:NUM-COLUMNS.
      IF br-work:GET-BROWSE-COLUMN(i-col) <> h-col THEN DO.
         IF br-work:GET-BROWSE-COLUMN(i-col):LABEL-FGCOLOR = 3 THEN
            br-work:GET-BROWSE-COLUMN(i-col):LABEL = c-label-ori. 

         ASSIGN br-work:GET-BROWSE-COLUMN(i-col):LABEL-FGCOLOR = ?.
      END.
   END.

   DO i-col = 1 TO br-work:NUM-COLUMNS.
      IF br-work:GET-BROWSE-COLUMN(i-col) = h-col THEN DO.
         ASSIGN sort-col = i-col.

         IF h-col:LABEL-FGCOLOR = 3 THEN 
            ASSIGN order-col = IF order-col = 1 THEN 4 ELSE 1.
         ELSE
            ASSIGN h-col:LABEL-FGCOLOR = 3
                   order-col           = 1
                   c-label-ori         = h-col:LABEL.
      END.
   END.

   ASSIGN c-label = c-label-ori.
   IF order-col = 1 THEN
      OVERLAY(c-label,LENGTH(c-label) + 1,2) = " " + CHR(171). 
   ELSE
      OVERLAY(c-label,LENGTH(c-label) + 1,2) = " " + CHR(187). 

   h-col:LABEL = c-label. 

   {&OPEN-QUERY-br-work} 

   APPLY "leave" TO br-work.
   RETURN NO-APPLY.
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
  
   ASSIGN c-lin = "Faturamento Periodo " + SUBSTR(p-titulo, 27, 24).
   ASSIGN c-lin = REPLACE(c-lin, "/", "-").
   RUN esdlg/d03essp0190.w (OUTPUT arq-saida, 
                            INPUT c-lin).
   IF arq-saida <> "" THEN DO:
      RUN pi-gera-excel. 
      MESSAGE "O arquivo foi gerado em " TRIM(arq-saida) + "." SKIP 
              "Para acess†-lo,  abra-o atravÇs do Excel."
          VIEW-AS ALERT-BOX INFO BUTTONS OK. 
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-exit
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exit D-Dialog
ON CHOOSE OF bt-exit IN FRAME D-Dialog
DO:
   APPLY 'CLOSE':U TO THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime D-Dialog
ON CHOOSE OF bt-imprime IN FRAME D-Dialog
DO:
  RUN pi-imprime.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vapara
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vapara D-Dialog
ON CHOOSE OF bt-vapara IN FRAME D-Dialog
DO:
   RUN esdlg/d01essp0190.w (OUTPUT c-codigo).

   IF c-codigo <> "" THEN DO:
      FIND FIRST tt-work WHERE
                 tt-work.cod-rep = INT(c-codigo) NO-LOCK NO-ERROR.
      IF NOT AVAIL tt-work THEN DO.
         MESSAGE "C¢digo n∆o est† contido na seleá∆o!"
             VIEW-AS ALERT-BOX INFO BUTTONS OK.
         RETURN NO-APPLY.
      END.
      h-query:REPOSITION-TO-ROWID(ROWID(tt-work)) NO-ERROR. 
      APPLY 'VALUE-CHANGED' TO br-work. 
   END.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */
 ASSIGN FRAME d-dialog:TITLE = "Valores dos Representantes  -  ESSP0190E1a".

 tt-work.cod-rep:READ-ONLY IN BROWSE br-work      = YES.
 tt-work.no-ab-reppri:READ-ONLY IN BROWSE br-work = YES.
 tt-work.vlr:READ-ONLY IN BROWSE br-work          = YES.
 tt-work.vlr-devol:READ-ONLY IN BROWSE br-work    = YES.

 ASSIGN h-query  = br-work:QUERY.

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
  DISPLAY fi-tot-geral fi-tot-devol 
      WITH FRAME D-Dialog.
  ENABLE br-work RECT-1 rt-buttom bt-vapara bt-excel bt-imprime bt-exit bt-ok 
         bt-cancela bt-ajuda 
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

  /* Marcar a coluna de classificaá∆o */
  ASSIGN h-col   = br-work:GET-BROWSE-COLUMN(1) IN FRAME {&FRAME-NAME}
         c-label = h-col:LABEL
         c-label-ori = c-label.
  OVERLAY(c-label,LENGTH(c-label) + 1,2) = " " + CHR(171). 
  ASSIGN h-col:LABEL         = c-label 
         h-col:LABEL-FGCOLOR = 3.

  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-abre-excel D-Dialog 
PROCEDURE pi-abre-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 CREATE "Excel.Application" chExcelApp NO-ERROR.
 IF chExcelApp <> ? THEN /* Cria a Planilha */
    ASSIGN chExcelApp:VISIBLE     = TRUE  /* A Planilha Ficar† Visivel */
           chExcelApp:SheetsInNewWorkbook = 1 /* Nı PLANILHAS A SEREM CRIADAS */
           chWorkbook             = chExcelApp:Workbooks:ADD() /* Cria Planilha */
           chworksheet            = chExcelapp:sheets:ITEM(1).


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
  RUN pi-abre-excel.
  IF chExcelApp = ? THEN DO:
     MESSAGE "O Aplicativo EXCEL n∆o foi encontrado. N∆o Ç possivel a execuá∆o do programa."
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     ASSIGN arq-saida = "".
     RETURN.
  END.

  RUN pi-monta-planilha.

  /* Posiciona o Foco no Inicio da Planilha */
  chExcelApp:Range("A1"):SELECT.
  chExcelApp:Range("A:A"):EntireColumn:AutoFit.

  /* Posiciona na Planilha 1, Salva e Fecha */
  chWorkSheet = chExcelapp:Sheets:ITEM(1).
  chWorkbook:Worksheets(1):activate.

 /* ASSIGN arq-saida = "C:\TEMP\LIXO.XLS". */

  /* Salva e Fecha Planilha */
  OS-DELETE VALUE(arq-saida).

  /* chWorkBook:SaveAs(arq-saida,39,,,,,,,TRUE). /* Salva em formato mais Antigo EXCEL97 */ */
  chWorkBook:SaveAs(arq-saida,,,,,,,).  /* Salva na Vers∆o da planilha da ESTAÄ«O */
  chWorkBook:CLOSE().
  chExcelApp:QUIT().
  RELEASE OBJECT chExcelApp. 
  RELEASE OBJECT chworkBook.
  RELEASE OBJECT chworksheet.
    

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

    PUT c-empresa FORMAT "x(40)"                  AT  1
        "DATA: "                                  AT 46
        STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT 52
        "HORA: "                                  AT 68
        STRING(TIME,"hh:mm:ss")                   AT 74
        "PAG:"                                    AT 90
        i-pag FORMAT ">>>"                        AT 95
        SKIP(1).

    PUT p-titulo FORMAT "X(60)" AT 20 SKIP(1).


    PUT "CODIGO  NOME DO REPRESENTANTE                        FATURAMENTO   VLR DEVOLUÄ«O" AT 1.
    PUT "------  ---------------------------------------  ---------------   -------------" AT 1.
         
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
          OUTPUT TO VALUE(c-saida) CONVERT TARGET "ibm850" PAGED PAGE-SIZE 62.
          PUT CONTROL "~033E~033(s15H".  /* ORIENTAÄ«O RETRATO & COMPACTA */
      END.
      WHEN 2 THEN
          OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
      WHEN 3 THEN DO.
          ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0190e1a.tmp".
          OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
      END.
  END CASE.

  DO i-ct = 1 TO i-num-copias.
     ASSIGN i-pag      =  1
            i-lin      = 99.

     ASSIGN fi-tot-geral = 0 
            fi-tot-devol = 0.

     FOR EACH b-tt-work NO-LOCK {&SORTBY-IMP-EXCEL}.
         IF i-lin > 62 THEN DO:
            RUN pi-imp-cabec.
            ASSIGN i-lin = 7.
         END.
         PUT b-tt-work.cod-rep      FORMAT ">>>>>9"           AT  1
             b-tt-work.no-ab-reppri FORMAT "x(40)"            AT  9 
             b-tt-work.vlr          FORMAT ">>>>,>>>,>>9.99"  AT 50
             b-tt-work.vlr-devol    FORMAT ">>>>,>>>,>>9.99"  AT 66.
             
         ASSIGN i-lin = i-lin + 1.
         ASSIGN fi-tot-geral = fi-tot-geral + b-tt-work.vlr
                fi-tot-devol = fi-tot-devol + b-tt-work.vlr-devol.
     END.
     IF i-lin > 62 THEN DO:
        RUN pi-imp-cabec.
        ASSIGN i-lin = 7.
     END.
     PUT "---------------  ---------------" AT 50.
     PUT "TOTAL GERAL:"  AT 36.
     PUT fi-tot-geral FORMAT ">>>>,>>>,>>9.99"  AT  50
         fi-tot-devol FORMAT ">>>>,>>>,>>9.99"  AT  66.

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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-monta-planilha D-Dialog 
PROCEDURE pi-monta-planilha :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 ASSIGN fi-tot-geral = 0
        fi-tot-devol = 0.

 /* Nomear Aba da Planilha */
 chWorkSheet = chExcelapp:Sheets:ITEM(1).
 chWorkSheet:NAME = "Faturamento Por Representante".
 chWorkSheet:TAB:ColorIndex = 19.

 /* Ativar a Planilha */
 chWorkSheet = chExcelapp:Sheets:ITEM(1).
 chWorkbook:Worksheets(1):activate.
 chExcelApp:ActiveWindow:Zoom = 100.

 ASSIGN chworksheet:range("A1"):VALUE = p-titulo.

 /* Configura Alinhamento Horizontal do Titulo da Planilha */
 ChWorkSheet:range("A1:D1"):SELECT().
 ChWorksheet:range("A1:D1"):Merge.
 Chworksheet:Range("A1:D1"):HorizontalAlignment =  3.
 /* Colorir Titulo da Planilha */
 chWorkSheet:Range("A1:D1"):FONT:ColorIndex     = 18. /* Avermelhado */
 chWorkSheet:Range("A1:D1"):Interior:ColorIndex = 2. /* Branco */

 /* Configura a Linha do Titulo da Planilha */
 ASSIGN chWorkSheet:Rows("1:1"):RowHeight = 25
        chWorkSheet:Rows("2:2"):RowHeight =  4
        chWorkSheet:Rows("1:1"):FONT:SIZE = 12
        chWorkSheet:Rows("1:1"):FONT:bold = TRUE.

 /* Titulo das Colunas */
 ASSIGN chworksheet:range("A3"):VALUE = "CODIGO"
        chworksheet:range("B3"):VALUE = "NOME DO REPRESENTANTE"    
        chworksheet:range("C3"):VALUE = "FATURAMENTO"  
        chworksheet:range("D3"):VALUE = "VALOR DEVOLUÄ«O".

 /* Tamanho das Colunas */
 ASSIGN chWorkSheet:Columns("A"):ColumnWidth =  6
        chWorkSheet:Columns("B"):ColumnWidth = 40
        chWorkSheet:Columns("C"):ColumnWidth = 15
        chWorkSheet:Columns("D"):ColumnWidth = 15.

 /* Configura as Colunas da Planilha */
 ASSIGN chworksheet:range("A:A"):NumberFormat        = "###.###.##0"
        chworksheet:range("B:B"):NumberFormat        = "@".
 ASSIGN chworksheet:range("C:D"):NumberFormat        = "###.###.##0,00"
        Chworksheet:range("C:D"):HorizontalAlignment = 4. /* Alinhamento a Direita */

 /* Configura Cabeáalho das Colunas */
 chWorkSheet:Range("A3:D3"):SELECT().
 ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
        chExcelApp:SELECTION:FONT:SIZE               = 09
        chExcelApp:SELECTION:FONT:Bold               = TRUE 
        chExcelApp:SELECTION:Interior:ColorIndex     = 19
        chExcelApp:SELECTION:FONT:ColorIndex         = 11.

 ASSIGN i-Lin    = 4.

 ASSIGN fi-tot-geral = 0
        fi-tot-devol = 0.

FOR EACH b-tt-work NO-LOCK {&SORTBY-IMP-EXCEL}.
    ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.cod-rep
           chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.no-ab-reppri
           chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.vlr
           chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.vlr-devol.

    /*  Configura Tamanho da Fonte */
    ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
           chworksheet:Rows(c-lin):FONT:SIZE = 9.

    ASSIGN i-lin = i-lin + 1.

    ASSIGN fi-tot-geral = fi-tot-geral + b-tt-work.vlr
           fi-tot-devol = fi-tot-devol + b-tt-work.vlr-devol.

END.
IF i-lin <> 4 THEN DO:
   ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = "TOTAL GERAL".
   ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = fi-tot-geral     
          chworksheet:range("D" + STRING(i-lin)):VALUE = fi-tot-devol.     
    /* Colorir a Linha / Negrito */
   ASSIGN chWorkSheet:Range("A" + STRING(i-lin) + ":D" + STRING(i-lin)):Interior:ColorIndex = 14
          chWorkSheet:Range("A" + STRING(i-lin) + ":D" + STRING(i-lin)):FONT:ColorIndex     =  2
          chWorkSheet:Range("A" + STRING(i-lin) + ":D" + STRING(i-lin)):FONT:Bold           = TRUE.
   ASSIGN i-lin = i-lin + 1.
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
ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Selecionando_Totais *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 FOR EACH tt-trab NO-LOCK
     BREAK BY tt-trab.cod-rep.
     ASSIGN de-valor = de-valor + tt-trab.vlr
            de-devol = de-devol + tt-trab.vlr-devol.
     IF LAST-OF(tt-trab.cod-rep) THEN DO:
        CREATE tt-work.
        ASSIGN tt-work.cod-rep      = tt-trab.cod-rep
               tt-work.no-ab-reppri = tt-trab.no-ab-reppri
               tt-work.vlr          = de-valor
               tt-work.vlr-devol    = de-devol.
        ASSIGN de-valor = 0
               de-devol = 0.
     END.
 END.     

 ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = p-titulo. 
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

 ASSIGN fi-tot-geral = 0
        fi-tot-devol = 0.
 FOR EACH tt-work NO-LOCK.
     ASSIGN fi-tot-geral = fi-tot-geral + tt-work.vlr  
            fi-tot-devol = fi-tot-devol + tt-work.vlr-devol.
 END.
 DISP fi-tot-geral 
      fi-tot-devol 
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


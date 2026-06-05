&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-window 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i XX9999 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.
DEFINE VARIABLE ChaveFinal          AS CHARACTER   NO-UNDO FORMAT 'x(50)'.
DEFINE VARIABLE i                   AS INTEGER     NO-UNDO.
DEFINE VARIABLE uf                  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE ano                 AS CHARACTER   NO-UNDO.
DEFINE VARIABLE Mes                 AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCnpj               AS CHARACTER   NO-UNDO FORMAT 'x(20)'.
DEFINE VARIABLE serie               AS CHARACTER   NO-UNDO FORMAT '999'.
DEFINE VARIABLE nrNota              AS CHARACTER   NO-UNDO FORMAT '999999999'.
DEFINE VARIABLE iResultado          AS INTEGER     NO-UNDO INIT 0.
DEFINE VARIABLE novoChar2           AS CHARACTER   NO-UNDO.
/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE JanelaDetalhe
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 btBuscar fiCodEstabel fiserie ~
finrNotaFisc fiChar2 fiChave btAtualizar bt-ok bt-cancelar bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fiCodEstabel fiserie finrNotaFisc fiChar2 ~
fiChave 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-window AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "OK" 
     SIZE 10 BY 1.

DEFINE BUTTON btAtualizar 
     LABEL "Atualizar" 
     SIZE 8 BY 1.25.

DEFINE BUTTON btBuscar 
     LABEL "Buscar" 
     SIZE 8 BY 1.25.

DEFINE VARIABLE fiChar2 AS CHARACTER FORMAT "x(2000)" 
     LABEL "Char-2" 
     VIEW-AS FILL-IN 
     SIZE 70 BY 2.25 NO-UNDO.

DEFINE VARIABLE fiChave AS CHARACTER FORMAT "X(256)":U 
     LABEL "Chave" 
     VIEW-AS FILL-IN 
     SIZE 70 BY 1 NO-UNDO.

DEFINE VARIABLE fiCodEstabel AS CHARACTER FORMAT "X(3)":U 
     LABEL "Estab" 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE VARIABLE finrNotaFisc AS CHARACTER FORMAT "X(20)":U 
     LABEL "Nota Fiscal" 
     VIEW-AS FILL-IN 
     SIZE 18.29 BY .88 NO-UNDO.

DEFINE VARIABLE fiserie AS CHARACTER FORMAT "X(3)":U 
     LABEL "Serie" 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 77.86 BY 1.38
     BGCOLOR 7 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     btBuscar AT ROW 2 COL 55 WIDGET-ID 10
     fiCodEstabel AT ROW 2.25 COL 6.72 COLON-ALIGNED WIDGET-ID 4
     fiserie AT ROW 2.25 COL 18 COLON-ALIGNED WIDGET-ID 6
     finrNotaFisc AT ROW 2.25 COL 32.72 COLON-ALIGNED WIDGET-ID 8
     fiChar2 AT ROW 3.5 COL 7 COLON-ALIGNED WIDGET-ID 2
     fiChave AT ROW 6 COL 7 COLON-ALIGNED WIDGET-ID 14
     btAtualizar AT ROW 7.5 COL 9 WIDGET-ID 12
     bt-ok AT ROW 12.21 COL 3
     bt-cancelar AT ROW 12.21 COL 14
     bt-ajuda AT ROW 12.21 COL 69
     RECT-1 AT ROW 12 COL 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 80 BY 12.58
         FONT 1 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: JanelaDetalhe
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-window ASSIGN
         HIDDEN             = YES
         TITLE              = "<insert Custom SmartWindow title>"
         HEIGHT             = 12.67
         WIDTH              = 80
         MAX-HEIGHT         = 21.13
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 21.13
         VIRTUAL-WIDTH      = 114.29
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-window 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-window.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-window
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
THEN w-window:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON END-ERROR OF w-window /* <insert Custom SmartWindow title> */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON WINDOW-CLOSE OF w-window /* <insert Custom SmartWindow title> */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-window
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-window
ON CHOOSE OF bt-cancelar IN FRAME F-Main /* Cancelar */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-window
ON CHOOSE OF bt-ok IN FRAME F-Main /* OK */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btAtualizar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btAtualizar w-window
ON CHOOSE OF btAtualizar IN FRAME F-Main /* Atualizar */
DO:
  FIND FIRST nota-fiscal
      WHERE nota-fiscal.cod-estabel = INPUT FRAME {&FRAME-NAME} fiCodEstabel
      AND   nota-fiscal.serie       = INPUT FRAME {&FRAME-NAME} fiSerie
      AND   nota-fiscal.nr-nota-fis = INPUT FRAME {&FRAME-NAME} fiNrNotaFisc EXCLUSIVE-LOCK NO-ERROR.
  IF AVAIL nota-fiscal THEN DO:
     ASSIGN nota-fiscal.char-2 = fiChar2:SCREEN-VALUE .
     MESSAGE   "campo atualizado"
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     RELEASE nota-fiscal.
  END.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btBuscar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btBuscar w-window
ON CHOOSE OF btBuscar IN FRAME F-Main /* Buscar */
DO:
  OUTPUT TO c:\temp\novachave.txt.
  FIND FIRST nota-fiscal
      WHERE nota-fiscal.cod-estabel = INPUT FRAME {&FRAME-NAME} fiCodEstabel
      AND   nota-fiscal.serie       = INPUT FRAME {&FRAME-NAME} fiSerie
      AND   nota-fiscal.nr-nota-fis = INPUT FRAME {&FRAME-NAME} fiNrNotaFisc NO-LOCK NO-ERROR.
  IF AVAIL nota-fiscal THEN DO:
     /*ASSIGN fiChar2:SCREEN-VALUE = nota-fiscal.char-2.*/
     
     /*calculo da chave*/
     IF nota-fiscal.cod-estabel = '1' THEN
        ASSIGN uf = '31'.
     ELSE
        ASSIGN uf = '32'.
     FIND FIRST estabelec 
        WHERE estabelec.cod-estabel = nota-fiscal.cod-estabel
        NO-LOCK NO-ERROR.
     ASSIGN cCNPJ = IF AVAIL estabelec THEN estabelec.cgc ELSE ''.

     /*ASSIGN  anoMes = STRING(YEAR(nota-fiscal.dt-emis-nota),'99')  
                   + STRING(MONTH(nota-fiscal.dt-emis-nota),'99').*/
    RUN preencherZeros(SUBSTR(string(YEAR(nota-fiscal.dt-emis-nota)),3,2),2, OUTPUT ano).
    RUN preencherZeros(MONTH(nota-fiscal.dt-emis-nota),2, OUTPUT mes).
    RUN preencherZeros(nota-fiscal.nr-nota-fis,9, OUTPUT nrNota).
    RUN preencherZeros(nota-fiscal.serie,3, OUTPUT serie).
    ASSIGN  chaveFinal = uf + Ano + Mes + cCNPJ + '55' + serie + nrNota + '100000000'.
    RUN calcChave(chaveFinal, OUTPUT iResultado).
   /* MESSAGE chaveFinal SKIP iResultado
        VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
    ASSIGN chaveFinal  = chaveFinal + STRING(iResultado).
    /*MESSAGE chavefinal
        VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
    DISP nota-fiscal.nr-nota-fis nota-fiscal.serie chavefinal WITH WIDTH 550.
    /*MESSAGE Chavefinal
         VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
     ASSIGN fichave:SCREEN-VALUE = chavefinal
            novoChar2 = nota-fiscal.char-2
            substr(novoChar2,3,44) = chavefinal
            fiChar2:SCREEN-VALUE = novoChar2.
  END.
  ELSE
      MESSAGE "Nota n∆o encontrada"
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
     
  OUTPUT CLOSE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-window 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-window  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-window  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE calcChave w-window 
PROCEDURE calcChave :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER chave AS CHARACTER   NO-UNDO FORMAT 'x(50)'.
    DEFINE OUTPUT PARAMETER iResultado AS DECIMAL     NO-UNDO.
    DEFINE VARIABLE deTotal             AS DECIMAL     NO-UNDO.
    DEFINE VARIABLE Multiplicadores     AS CHARACTER   NO-UNDO INIT '2,3,4,5,6,7,8,9'.
    DEFINE VARIABLE iMod                AS INTEGER     NO-UNDO.
    DEFINE VARIABLE deResto             AS DECIMAL     NO-UNDO.
    REPEAT i = 1 TO LENGTH(chave):
        ASSIGN iMod =  i MOD 8.
        IF iMod = 0 THEN
           ASSIGN iMod = 8.
        ASSIGN deTotal = deTotal + int(SUBSTR(chave,LENGTH(chave) + 1 - i,1))* int(ENTRY(iMod ,multiplicadores)) .
       /* DISP detotal. */
    END.
    ASSIGN deResto = deTotal  MOD 11.
    IF(deResto = 0 OR deResto = 1) THEN
      ASSIGN iResultado = 0.
    ELSE
      ASSIGN iResultado = 11 - deResto.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-window  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
  THEN DELETE WIDGET w-window.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-window  _DEFAULT-ENABLE
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
  DISPLAY fiCodEstabel fiserie finrNotaFisc fiChar2 fiChave 
      WITH FRAME F-Main IN WINDOW w-window.
  ENABLE RECT-1 btBuscar fiCodEstabel fiserie finrNotaFisc fiChar2 fiChave 
         btAtualizar bt-ok bt-cancelar bt-ajuda 
      WITH FRAME F-Main IN WINDOW w-window.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW w-window.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE LimpaChave w-window 
PROCEDURE LimpaChave :
DEFINE INPUT  PARAMETER cChave AS CHARACTER   NO-UNDO.
DEFINE VARIABLE novoCampo AS CHARACTER   NO-UNDO.
DEFINE VARIABLE i AS INTEGER     NO-UNDO.
ASSIGN novoCampo = cChave
       SUBSTR(novoCampo,3,44) = ''
       SUBSTR(novoCampo,65,20)= SUBSTR(cChave,65,20) .
     
/*
REPEAT i = 1 TO LENGTH(cChave):
    IF i >= 3 AND i <= 47 THEN 
       ASSIGN novoCampo = novoCampo + ' '.
    ELSE                       
       ASSIGN novoCampo = novocampo + substr(cChave,i,1).

       
END.

MESSAGE   '    antigo:' cChave 
          'novo campo:' novoCampo 
          VIEW-AS ALERT-BOX INFO BUTTONS OK.*/

ASSIGN fichar2:SCREEN-VALUE IN FRAME {&FRAME-NAME} = novoCampo .




END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-window 
PROCEDURE local-exit :
/* -----------------------------------------------------------
  Purpose:  Starts an "exit" by APPLYing CLOSE event, which starts "destroy".
  Parameters:  <none>
  Notes:    If activated, should APPLY CLOSE, *not* dispatch adm-exit.   
-------------------------------------------------------------*/
   APPLY "CLOSE":U TO THIS-PROCEDURE.
   
   RETURN.
       
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-window 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  {include/win-size.i}
  
  {utp/ut9000.i "XX9999" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE preencherZeros w-window 
PROCEDURE preencherZeros :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER texto    AS CHARACTER   NO-UNDO FORMAT 'x(50)'.
DEFINE INPUT  PARAMETER tamanho  AS INTEGER     NO-UNDO.
DEFINE OUTPUT PARAMETER novoText AS CHARACTER   NO-UNDO FORMAT 'x(50)'.
DEFINE VARIABLE zeros AS CHARACTER   NO-UNDO.
DEFINE VARIABLE i AS INTEGER     NO-UNDO.

REPEAT i = 1 TO tamanho - LENGTH(texto):

    ASSIGN zeros = zeros + '0'.
END.

ASSIGN novoText = zeros + texto.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-window  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this JanelaDetalhe, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-window 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


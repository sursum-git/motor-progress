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
{include/i-prgvrs.i ESSP0190F 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
DEF BUFFER empresa FOR mgadm.empresa.

/* Parameters Definitions ---                                           */

DEF TEMP-TABLE tt-devolucao NO-UNDO
    FIELD serie-docto  LIKE docum-est.serie-docto
    FIELD nro-docto    LIKE docum-est.nro-docto
    FIELD cod-emitente LIKE docum-est.cod-emitente
    FIELD nat-operacao LIKE docum-est.nat-operacao
    FIELD qtd-devol    AS DEC 
    FIELD vlr-devol    AS DEC.

DEFINE TEMP-TABLE tt-work  NO-UNDO 
       FIELD nr-nota-fis   LIKE nota-fiscal.nr-nota-fis
       FIELD cod-estabel   LIKE nota-fiscal.cod-estabel
       FIELD serie         LIKE nota-fiscal.serie
       FIELD dt-entrega    LIKE ped-venda.dt-entrega
       FIELD dt-emis-nota  LIKE nota-fiscal.dt-emis-nota
       FIELD nome-ab-cli   LIKE nota-fiscal.nome-ab-cli
       FIELD nr-pedcli     LIKE nota-fiscal.nr-pedcli
       FIELD no-ab-reppri  LIKE nota-fiscal.no-ab-reppri
       FIELD qtd-nota      AS DEC FORMAT ">>>,>>9.99" 
       FIELD vl-tot-nota   LIKE nota-fiscal.vl-tot-nota FORMAT "->>>,>>9.99"
       FIELD dt-devol      LIKE devol-cli.dt-devol
       FIELD nro-docto     LIKE devol-cli.nro-docto
       FIELD qtd-devol     AS DEC
       FIELD vlr-devol     AS DEC
       FIELD motivo        AS CHAR FORMAT "x(100)".

DEFINE BUFFER b-tt-work FOR tt-work.

DEFINE INPUT PARAMETER TABLE FOR tt-devolucao.  
DEFINE INPUT PARAMETER p-dt-faturadas-ini AS CHAR.
DEFINE INPUT PARAMETER p-dt-faturadas-fin AS CHAR.

/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-ped-venda   AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR gr-nota-fiscal AS ROWID NO-UNDO.

DEF VAR h-acomp         AS HANDLE NO-UNDO.
DEF VAR de-tot-qtd      AS DEC.
DEF VAR de-tot-vlr      AS DEC.
DEF VAR c-empresa       AS CHAR.

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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.nr-nota-fis tt-work.dt-emis-nota tt-work.nome-ab-cli tt-work.nr-pedcli tt-work.no-ab-reppri tt-work.qtd-nota tt-work.vl-tot-nota tt-work.nro-docto tt-work.qtd-devol tt-work.vlr-devol tt-work.dt-devol tt-work.motivo   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define QUERY-STRING-br-work FOR EACH tt-work NO-LOCK                               BY tt-work.nr-nota-fis
&Scoped-define OPEN-QUERY-br-work OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK                               BY tt-work.nr-nota-fis.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-work rt-buttom bt-detalhe-ped ~
bt-detalhe-nf bt-imprime bt-observ bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-qtd fi-tot-vlr 

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
     SIZE 14 BY 1.25 TOOLTIP "Detalhe do Pedido".

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/img-pri.bmp":U
     LABEL "Impress∆o" 
     SIZE 12 BY 1.25 TOOLTIP "Imprime o Relat¢rio".

DEFINE BUTTON bt-observ 
     LABEL "Observaá∆o Completa" 
     SIZE 17 BY 1.25 TOOLTIP "Imprime o Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-tot-qtd AS DECIMAL FORMAT "    ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     LABEL "Qtd Devolvida" 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     LABEL "Vlr Devolvido" 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 93 BY 1.42
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
      tt-work.nr-nota-fis   COLUMN-LABEL "N.Fiscal"  WIDTH 6.4
      tt-work.dt-emis-nota  COLUMN-LABEL "Dt.Emiss∆o" 
      tt-work.nome-ab-cli   COLUMN-LABEL "Cliente"     
      tt-work.nr-pedcli     COLUMN-LABEL "Pedido" WIDTH 6
      tt-work.no-ab-reppri  COLUMN-LABEL "Representante"
      tt-work.qtd-nota      COLUMN-LABEL "Quantidade"   
      tt-work.vl-tot-nota   COLUMN-LABEL "Valor NF"    
      tt-work.nro-docto     COLUMN-LABEL "NF Dev." WIDTH 6
      tt-work.qtd-devol     COLUMN-LABEL "Qtd Devol"
      tt-work.vlr-devol     COLUMN-LABEL "Valor Dev"
      tt-work.dt-devol      COLUMN-LABEL "Dt.Devol."  
      tt-work.motivo        COLUMN-LABEL "Motivo"  WIDTH 100
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 93.29 BY 11.92
         FONT 1
         TITLE "DEVOLUÄÂES" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1.72
     fi-tot-qtd AT ROW 13 COL 78 COLON-ALIGNED NO-TAB-STOP 
     bt-detalhe-ped AT ROW 13.38 COL 2.57
     bt-detalhe-nf AT ROW 13.38 COL 16.72
     bt-imprime AT ROW 13.38 COL 34.86
     bt-observ AT ROW 13.38 COL 47 WIDGET-ID 2
     fi-tot-vlr AT ROW 14 COL 78 COLON-ALIGNED
     bt-ok AT ROW 15.17 COL 2.57
     bt-cancela AT ROW 15.17 COL 13.57
     bt-ajuda AT ROW 15.17 COL 83.57
     rt-buttom AT ROW 14.92 COL 1.57
     SPACE(0.71) SKIP(0.23)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Devoluá∆o de Mercadorias - ESSP0190F"
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
OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK
                              BY tt-work.nr-nota-fis.
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Devoluá∆o de Mercadorias - ESSP0190F */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON VALUE-CHANGED OF br-work IN FRAME D-Dialog /* DEVOLUÄÂES */
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
          ped-venda.nome-abrev = tt-work.nome-ab-cli NO-LOCK NO-ERROR.
     ASSIGN gr-ped-venda = ROWID(ped-venda).
     ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
     RUN pdp\pd1001.w.
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


&Scoped-define SELF-NAME bt-observ
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-observ D-Dialog
ON CHOOSE OF bt-observ IN FRAME D-Dialog /* Observaá∆o Completa */
DO:
  MESSAGE tt-work.motivo
      VIEW-AS ALERT-BOX INFO BUTTONS OK.
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
  DISPLAY fi-tot-qtd fi-tot-vlr 
      WITH FRAME D-Dialog.
  ENABLE br-work rt-buttom bt-detalhe-ped bt-detalhe-nf bt-imprime bt-observ 
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

  /* {utp/ut9000.i "ESSP0174A" "2.04.00.000"} */ 

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  FIND FIRST param-global NO-LOCK NO-ERROR.
  FIND FIRST empresa
       WHERE empresa.ep-codigo = param-global.empresa-prin NO-LOCK NO-ERROR. 
  ASSIGN c-empresa = (IF AVAIL empresa THEN empresa.razao-social ELSE "").

  RUN pi-processa.

  {&OPEN-QUERY-br-work}
  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.
  APPLY 'VALUE-CHANGED' to br-work IN FRAME {&FRAME-NAME}.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cabec-item D-Dialog 
PROCEDURE pi-cabec-item :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 PUT "Seq  Item    Referencia  Lote  Corte       Quantidade  Reservado" AT 19.
 PUT "---  ------  ----------  ----  ----------  ----------  ---------" AT 19.
 ASSIGN i-lin = i-lin + 2.
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
     "DATA: "                                  AT  66
     STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  72
     "HORA: "                                  AT  88
     STRING(TIME,"hh:mm:ss")                   AT  94
     "PAGINA:"                                 AT 122
     i-pag FORMAT "999"                        AT 130
     SKIP(1).
        
 PUT "DEVOLUÄ«O DE MERCADORIAS NO PERIODO DE: " + 
      p-dt-faturadas-ini + " A " + p-dt-faturadas-fin FORMAT "x(100)" AT 39 SKIP(1).                          

 PUT "N.Fiscal Dt.Emissao Cliente      Pedido Representante Quantidade Valor NF    Dt. Devol. NF Dev. Quantidade  Valor Dev. Motivo Devoluá∆o" AT 1.  
 PUT "-------- ---------- ------------ ------ ------------- ---------- ----------- ---------- ------- ----------- ---------- ----------------" AT 1.
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
         OUTPUT TO VALUE(c-saida) CONVERT TARGET "ibm850" PAGED PAGE-SIZE 64.
         PUT CONTROL "~033E~033(s18H".    
     END.
     WHEN 2 THEN
         OUTPUT TO VALUE(c-saida).
     WHEN 3 THEN DO.
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0183.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.
 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-lin = 99
           i-pag = 1.
    FOR EACH b-tt-work NO-LOCK 
        BREAK BY b-tt-work.dt-devol.
        IF i-lin > 64 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
        PUT b-tt-work.nr-nota-fis  FORMAT "x(7)"        AT   1
            b-tt-work.dt-emis-nota                      AT  10
            b-tt-work.nome-ab-cli                       AT  21
            b-tt-work.nr-pedcli    FORMAT "x(6)"        AT  34
            b-tt-work.no-ab-reppri                      AT  41
            b-tt-work.qtd-nota                          AT  55
            b-tt-work.vl-tot-nota  FORMAT "->>>,>>9.99" AT  66
            b-tt-work.dt-devol                          AT  78
            b-tt-work.nro-docto    FORMAT "x(7)"        AT  89
            b-tt-work.qtd-dev                           AT  98
            b-tt-work.vlr-dev                           AT 109.

        PUT SUBSTR(b-tt-work.motivo,4,16) FORMAT "x(16)" AT 120. 

        ACCUMULATE b-tt-work.qtd-nota    (TOTAL).
        ACCUMULATE b-tt-work.vl-tot-nota (TOTAL).
        ACCUMULATE b-tt-work.qtd-dev     (TOTAL).
        ACCUMULATE b-tt-work.vlr-dev     (TOTAL).

        ASSIGN i-lin = i-lin + 1.

    END.
    IF (ACCUM TOTAL b-tt-work.qtd-nota) > 0 THEN DO:
       IF i-lin > 63 THEN DO:
          PAGE.
          RUN pi-cab-devol.
          ASSIGN i-lin = 7.
       END.
       
       PUT "----------------------                    ----------------------" AT  55 SKIP.
       PUT ACCUM TOTAL b-tt-work.qtd-nota                          AT  55.
       PUT ACCUM TOTAL b-tt-work.vl-tot-nota FORMAT ">>>>,>>9.99"  AT  66.
       PUT ACCUM TOTAL b-tt-work.qtd-dev                           AT  98. 
       PUT ACCUM TOTAL b-tt-work.vlr-dev FORMAT ">>>>,>>9.99"      AT 109 SKIP.
       
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-lixo D-Dialog 
PROCEDURE pi-lixo :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/*
    FOR EACH item-doc-est OF docum-est NO-LOCK.

       RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(docum-est.dt-trans) +
                                            " Nota Fiscal: " + item-doc-est.nro-docto).
       FIND nota-fiscal WHERE
            nota-fiscal.cod-estabel  = docum-est.cod-estabel   AND
            nota-fiscal.serie        = item-doc-est.serie-comp AND
            nota-fiscal.nr-nota-fis  = item-doc-est.nro-comp   NO-LOCK NO-ERROR.
       IF AVAIL nota-fiscal THEN DO:
           FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
               ACCUMULATE it-nota-fisc.qt-faturada[1] (TOTAL).
           END.
       END.

       IF de-qtd-amostra = 0 THEN DO: /* Descarta Amostra */ 
          FIND tt-itens WHERE
               tt-itens.it-codigo = item-doc-est.it-codigo NO-ERROR.
          IF NOT AVAIL tt-itens THEN DO:
             CREATE tt-itens.
             ASSIGN tt-itens.it-codigo = item-doc-est.it-codigo.
          END.
          ASSIGN tt-itens.qtd   = tt-itens.qtd   + item-doc-est.quantidade
                 tt-itens.valor = tt-itens.valor + item-doc-est.preco-total[1].
          IF i-tp-devol = 1 THEN DO: /* Devoluá∆o MENSAL */
              FIND tt-work WHERE
                   tt-work.nr-nota-fis = item-doc-est.nro-comp AND
                   tt-work.nro-docto   = item-doc-est.nro-docto NO-LOCK NO-ERROR.
              IF NOT AVAIL tt-work THEN DO: 
                 CREATE tt-work.
                 ASSIGN  tt-work.dt-emis-nota = ?.
                 IF AVAIL nota-fiscal THEN  DO:
                    ASSIGN tt-work.nr-nota-fis  = nota-fiscal.nr-nota-fis   
                           tt-work.dt-emis-nota = nota-fiscal.dt-emis-nota  
                           tt-work.nome-ab-cli  = nota-fiscal.nome-ab-cli   
                           tt-work.nr-pedcli    = nota-fiscal.nr-pedcli     
                           tt-work.no-ab-reppri = nota-fiscal.no-ab-reppri  
                           tt-work.qtd-nota     = ACCUM TOTAL it-nota-fisc.qt-faturada[1] 
                           tt-work.vl-tot-nota  = nota-fiscal.vl-tot-nota.
                    ASSIGN fi-total-1 = fi-total-1 + ACCUM TOTAL it-nota-fisc.qt-faturada[1] 
                           fi-total-2 = fi-total-2 + nota-fiscal.vl-tot-nota.
                 END.
                 ASSIGN tt-work.dt-devol     = docum-est.dt-trans
                        tt-work.nro-docto    = item-doc-est.nro-docto
                        tt-work.motivo       = SUBSTR(docum-est.observacao,1,70).
    
                 IF docum-est.despesa-nota <> 0 THEN  /* Frete */
                   ASSIGN tt-work.vlr-devol = docum-est.despesa-nota
                          fi-total-4 = fi-total-4 + docum-est.despesa-nota.
              END.
              ASSIGN tt-work.qtd-devol = tt-work.qtd-devol + item-doc-est.quantidade
                     tt-work.vlr-devol = tt-work.vlr-devol + item-doc-est.preco-total[1]
                     fi-total-3        = fi-total-3        + item-doc-est.quantidade
                     fi-total-4        = fi-total-4        + item-doc-est.preco-total[1].
          END.
          ELSE DO: /* Devoluá∆o ANUAL */
              ASSIGN i-mes = MONTH(docum-est.dt-trans).
              FIND tt-work WHERE
                   tt-work.mes  = i-mes NO-ERROR.
              IF NOT AVAIL tt-work THEN DO:
                 CREATE tt-work.
                 ASSIGN tt-work.mes       = i-mes
                        tt-work.nome-mes  = SUBSTR(c-meses, i-mes * 9 - 8,9).
              END.
              ASSIGN tt-work.qtd-devol = tt-work.qtd-devol + item-doc-est.quantidade
                     tt-work.vlr-devol = tt-work.vlr-devol + item-doc-est.preco-total[1]
                     fi-total-1        = fi-total-1        + item-doc-est.quantidade
                     fi-total-2        = fi-total-2        + item-doc-est.preco-total[1].
          END.
       END. 
    END.
*/
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
 {utp/ut-liter.i Calculando_Valores *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "DEVOLUÄ«O DE MERCADORIAS NO PERIODO DE: " +
                                                p-dt-faturadas-ini + " A " + 
                                                p-dt-faturadas-fin.
 ASSIGN fi-tot-qtd = 0
        fi-tot-vlr = 0.

 FOR EACH tt-devolucao NO-LOCK.
     FIND docum-est WHERE
          docum-est.serie-docto  = tt-devolucao.serie-docto  AND
          docum-est.nro-docto    = tt-devolucao.nro-docto    AND
          docum-est.cod-emitente = tt-devolucao.cod-emitente AND
          docum-est.nat-operacao = tt-devolucao.nat-operacao NO-LOCK NO-ERROR.

     IF NOT AVAIL docum-est THEN NEXT.

     FIND FIRST devol-cli OF docum-est NO-LOCK NO-ERROR.

     FOR EACH item-doc-est OF docum-est NO-LOCK.

         RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(docum-est.dt-trans) +
                                            " Nota Fiscal: " + item-doc-est.nro-docto).

         FIND nota-fiscal WHERE
              nota-fiscal.cod-estabel  = docum-est.cod-estabel   AND
              nota-fiscal.serie        = item-doc-est.serie-comp AND
              nota-fiscal.nr-nota-fis  = item-doc-est.nro-comp   NO-LOCK NO-ERROR.

         IF AVAIL nota-fiscal THEN DO:
            FIND ped-venda WHERE
                 ped-venda.nr-pedcli = nota-fiscal.nr-pedcli NO-LOCK NO-ERROR.

            FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
                ACCUMULATE it-nota-fisc.qt-faturada[1] (TOTAL).
            END.
         END.

         FIND it-nota-fisc OF nota-fiscal WHERE
              it-nota-fisc.nr-seq-fat = item-doc-est.seq-comp
              NO-LOCK NO-ERROR.   

         FIND tt-work WHERE
              tt-work.nr-nota-fis = item-doc-est.nro-comp AND
              tt-work.nro-docto   = item-doc-est.nro-docto NO-LOCK NO-ERROR.

         IF NOT AVAIL tt-work THEN DO: 
            CREATE tt-work.
            ASSIGN tt-work.dt-emis-nota = ?.
            IF AVAIL nota-fiscal THEN  DO:
               ASSIGN tt-work.nr-nota-fis  = nota-fiscal.nr-nota-fis 
                      tt-work.cod-estabel  = nota-fiscal.cod-estabel
                      tt-work.serie        = nota-fiscal.serie
                      tt-work.dt-emis-nota = nota-fiscal.dt-emis-nota  
                      tt-work.nome-ab-cli  = nota-fiscal.nome-ab-cli   
                      tt-work.nr-pedcli    = nota-fiscal.nr-pedcli     
                      tt-work.no-ab-reppri = nota-fiscal.no-ab-reppri  
                      tt-work.qtd-nota     = ACCUM TOTAL it-nota-fisc.qt-faturada[1] 
                      tt-work.vl-tot-nota  = nota-fiscal.vl-tot-nota.
            END.
            /*
            IF docum-est.despesa-nota <> 0 THEN  /* Frete */
               ASSIGN tt-work.vlr-devol = docum-est.despesa-nota
                      fi-tot-vlr        = fi-tot-vlr + docum-est.despesa-nota.
            */          
         END.
         
         ASSIGN tt-work.dt-devol  = docum-est.dt-trans
                tt-work.nro-docto = item-doc-est.nro-docto.
     END.
     ASSIGN tt-work.qtd-devol = tt-work.qtd-devol + tt-devolucao.qtd-devol
            tt-work.vlr-devol = tt-work.vlr-devol + tt-devolucao.vlr-devol
            fi-tot-qtd        = fi-tot-qtd        + tt-devolucao.qtd-devol
            fi-tot-vlr        = fi-tot-vlr        + tt-devolucao.vlr-devol.

     IF AVAIL devol-cli THEN DO.
        FIND cod-rejeicao WHERE
             cod-rejeicao.codigo-rejei = devol-cli.codigo-rejei NO-LOCK NO-ERROR.
        IF AVAIL cod-rejeicao THEN
           ASSIGN tt-work.motivo = STRING(cod-rejeicao.codigo-rejei) + " - " +
                                   cod-rejeicao.descricao.
     END.
     IF tt-work.motivo = '' THEN
        ASSIGN tt-work.motivo = "MOTIVO N«O INFORMADO".

     IF docum-est.observacao <> '' THEN
        ASSIGN tt-work.motivo = tt-work.motivo + " // " +
                                SUBSTR(docum-est.observacao,1,100).
 END. 

 RUN pi-finalizar in h-acomp.
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.

 DISP fi-tot-qtd 
     fi-tot-vlr 
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


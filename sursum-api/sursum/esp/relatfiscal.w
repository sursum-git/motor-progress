&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-livre 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
/*{include/i-prgvrs.i XX9999 9.99.99.999}*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

DEFINE VARIABLE deCredPresumido AS DECIMAL     NO-UNDO.
DEFINE VARIABLE fatorDevolucao AS INT          NO-UNDO.
DEFINE VARIABLE cNatureza AS CHARACTER   NO-UNDO FORMAT 'x(500)'.

DEFINE VARIABLE LOG_dados AS LOGICAL     NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS fi_cod_estabel_ini fi_cod_estabel_fim ~
fi_grupo_ini fi_grupo_fim fi_codigo_orig_ini fi_codigo_orig_fim ~
fi_it_codigo_ini fi_it_codigo_fim fi_dt_docto_ini fi_dt_docto_fim ~
tg_devolucao fi_perc_presumido bt_gerar_excel rt-button RECT-3 RECT-2 
&Scoped-Define DISPLAYED-OBJECTS fi_cod_estabel_ini fi_cod_estabel_fim ~
fi_grupo_ini fi_grupo_fim fi_codigo_orig_ini fi_codigo_orig_fim ~
fi_it_codigo_ini fi_it_codigo_fim fi_dt_docto_ini fi_dt_docto_fim ~
tg_devolucao fi_perc_presumido 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-livre AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU mi-programa 
       MENU-ITEM mi-consultas   LABEL "Co&nsultas"     ACCELERATOR "CTRL-L"
       MENU-ITEM mi-imprimir    LABEL "&Relat¢rios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU m_Ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-livre MENUBAR
       SUB-MENU  mi-programa    LABEL "&Nome-do-Programa"
       SUB-MENU  m_Ajuda        LABEL "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt_gerar_excel 
     LABEL "Gerar Excel" 
     SIZE 15 BY 1.25.

DEFINE VARIABLE fi_codigo_orig_fim AS INTEGER FORMAT ">9" INITIAL 9 
     LABEL "AtÇ":R8 
     VIEW-AS FILL-IN 
     SIZE 3.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi_codigo_orig_ini AS INTEGER FORMAT ">9" INITIAL 0 
     LABEL "Origem":R8 
     VIEW-AS FILL-IN 
     SIZE 3.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi_cod_estabel_fim AS CHARACTER FORMAT "X(3)" INITIAL "999" 
     LABEL "AtÇ":R18 
     VIEW-AS FILL-IN 
     SIZE 3.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi_cod_estabel_ini AS CHARACTER FORMAT "X(3)" 
     LABEL "Estabelecimento":R18 
     VIEW-AS FILL-IN 
     SIZE 3.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi_dt_docto_fim AS DATE FORMAT "99/99/9999" INITIAL 12/31/9999 
     LABEL "AtÇ":R15 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88 NO-UNDO.

DEFINE VARIABLE fi_dt_docto_ini AS DATE FORMAT "99/99/9999" INITIAL 01/01/01 
     LABEL "Dt Documento":R15 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88 NO-UNDO.

DEFINE VARIABLE fi_grupo_fim AS INTEGER FORMAT "99" INITIAL 99 
     LABEL "AtÇ":R16 
     VIEW-AS FILL-IN 
     SIZE 3.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi_grupo_ini AS INTEGER FORMAT "99" INITIAL 0 
     LABEL "Grupo Estoque":R16 
     VIEW-AS FILL-IN 
     SIZE 3.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi_it_codigo_fim AS CHARACTER FORMAT "X(256)" INITIAL "zzzzzzzzzzzzzzzzzzzzzzzz" 
     LABEL "AtÇ":R5 
     VIEW-AS FILL-IN 
     SIZE 29.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi_it_codigo_ini AS CHARACTER FORMAT "X(256)" 
     LABEL "Item":R5 
     VIEW-AS FILL-IN 
     SIZE 29.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi_perc_presumido AS DECIMAL FORMAT ">9.99" INITIAL 41.66 
     LABEL "% Presumido":R15 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 89 BY 7.75.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 89 BY 2.58.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 91 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tg_devolucao AS LOGICAL INITIAL no 
     LABEL "Apenas Devoluá∆o?" 
     VIEW-AS TOGGLE-BOX
     SIZE 23 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fi_cod_estabel_ini AT ROW 3.38 COL 19.14 COLON-ALIGNED WIDGET-ID 52
     fi_cod_estabel_fim AT ROW 3.38 COL 58 COLON-ALIGNED WIDGET-ID 54
     fi_grupo_ini AT ROW 4.42 COL 19.14 COLON-ALIGNED HELP
          "Grupo de estoque" WIDGET-ID 2
     fi_grupo_fim AT ROW 4.42 COL 58 COLON-ALIGNED HELP
          "Grupo de estoque" WIDGET-ID 26
     fi_codigo_orig_ini AT ROW 5.46 COL 19.14 COLON-ALIGNED WIDGET-ID 32
     fi_codigo_orig_fim AT ROW 5.46 COL 58 COLON-ALIGNED WIDGET-ID 34
     fi_it_codigo_ini AT ROW 6.5 COL 19.14 COLON-ALIGNED HELP
          "C¢digo do Item" WIDGET-ID 28
     fi_it_codigo_fim AT ROW 6.5 COL 58 COLON-ALIGNED HELP
          "C¢digo do Item" WIDGET-ID 30
     fi_dt_docto_ini AT ROW 7.58 COL 19 COLON-ALIGNED HELP
          "Data de emiss∆o/entrada do documento" WIDGET-ID 36
     fi_dt_docto_fim AT ROW 7.5 COL 58 COLON-ALIGNED HELP
          "Data de emiss∆o/entrada do documento" WIDGET-ID 38
     tg_devolucao AT ROW 8.92 COL 21 WIDGET-ID 18
     fi_perc_presumido AT ROW 11.71 COL 19.14 COLON-ALIGNED WIDGET-ID 42
     bt_gerar_excel AT ROW 13.5 COL 2 WIDGET-ID 50
     "Geral" VIEW-AS TEXT
          SIZE 6.43 BY 1 AT ROW 2.88 COL 2.57 WIDGET-ID 48
          FONT 0
     "Fiscal" VIEW-AS TEXT
          SIZE 8.14 BY 1 AT ROW 10.75 COL 2.86 WIDGET-ID 46
          FONT 0
     rt-button AT ROW 1 COL 1
     RECT-3 AT ROW 10.67 COL 2 WIDGET-ID 44
     RECT-2 AT ROW 2.75 COL 2 WIDGET-ID 40
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 91.72 BY 14.04
         FONT 1 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-livre
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-livre ASSIGN
         HIDDEN             = YES
         TITLE              = "Relat¢rio de Vendas e Devoluá‰es Com CrÇdito Presumido - relatfiscal.w"
         HEIGHT             = 14.13
         WIDTH              = 90.86
         MAX-HEIGHT         = 27.54
         MAX-WIDTH          = 194.86
         VIRTUAL-HEIGHT     = 27.54
         VIRTUAL-WIDTH      = 194.86
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU m-livre:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-livre 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-livre.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-livre
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-cad
   FRAME-NAME Custom                                                    */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Relat¢rio de Vendas e Devoluá‰es Com CrÇdito Presumido - relatfiscal.w */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Relat¢rio de Vendas e Devoluá‰es Com CrÇdito Presumido - relatfiscal.w */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt_gerar_excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt_gerar_excel w-livre
ON CHOOSE OF bt_gerar_excel IN FRAME f-cad /* Gerar Excel */
DO: 

  ASSIGN bt_gerar_excel:LABEL IN FRAME {&FRAME-NAME} = 'Gerando...'
         bt_gerar_excel:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

  

  RUN retornaNaturezas( OUTPUT cNatureza).
  OUTPUT TO value(SESSION:TEMP-DIRECTORY  + 'relatfiscal.txt').
  ASSIGN LOG_dados = NO.
  FOR EACH doc-fiscal NO-LOCK
      WHERE doc-fiscal.ind-sit-doc = 1 /*normal*/
      AND   doc-fiscal.ind-ori-doc < 3 /*n∆o pega digitaá‰es manuais no OF*/
      AND   doc-fiscal.dt-docto >= INPUT FRAME {&frame-name} fi_dt_docto_ini
      AND   doc-fiscal.dt-docto <= INPUT FRAME {&frame-name} fi_dt_docto_fim
      AND   doc-fiscal.tipo-nat < 3 /*apenas entrada e saida*/
      AND   LOOKUP(doc-fiscal.nat-operacao,cNatureza) > 0
      USE-INDEX ch-apuracao,
      EACH it-doc-fisc OF doc-fiscal NO-LOCK,
      EACH ITEM NO-LOCK
        WHERE ITEM.it-codigo = it-doc-fisc.it-codigo
        AND   ITEM.ge-codigo >= INPUT FRAME {&frame-name}   fi_grupo_ini 
        AND   item.ge-codigo  <= INPUT FRAME {&frame-name}  fi_grupo_fim
        AND   ITEM.codigo-orig >= INPUT FRAME {&frame-name} fi_codigo_orig_ini
        AND   ITEM.codigo-orig <= INPUT FRAME {&FRAME-NAME} fi_codigo_orig_fim 
        AND   ITEM.it-codigo  >= INPUT FRAME {&frame-name} fi_it_codigo_ini
        AND   ITEM.it-codigo  <= INPUT FRAME {&frame-name} fi_it_codigo_fim:
        ASSIGN LOG_dados = YES.
        IF doc-fiscal.cod-observa = 3 THEN
           ASSIGN fatorDevolucao = -1.
        ELSE
           ASSIGN fatorDevolucao = 1.
        ASSIGN deCredPresumido = it-doc-fisc.vl-icms-it * fi_perc_presumido / 100.
        FIND FIRST emitente
            WHERE emitente.cod-emitente = doc-fiscal.cod-emitente
            NO-LOCK NO-ERROR.
        FIND FIRST natur-oper
            WHERE natur-oper.nat-operacao = doc-fiscal.nat-operacao
            NO-LOCK NO-ERROR.
        FIND FIRST grup-estoque
            WHERE grup-estoque.ge-codigo = ITEM.ge-codigo NO-LOCK NO-ERROR.
        EXPORT DELIMITER "|"
            doc-fiscal.cod-estabel
            doc-fiscal.dt-docto
            doc-fiscal.dt-emis-doc
            doc-fiscal.nr-doc-fis
            doc-fiscal.serie
            doc-fiscal.cod-emitente
            IF AVAIL emitente THEN emitente.nome-emit ELSE ''
            {diinc/i07di037.i 4 doc-fiscal.ind-ori-doc} 
            doc-fiscal.cod-cfop
            doc-fiscal.nat-operacao
            IF AVAIL natur-oper THEN natur-oper.denominacao ELSE ''
            {diinc/i06di037.i 4 doc-fiscal.cod-observa}
            doc-fiscal.esp-docto
            {diinc/i01di025.i 4 doc-fiscal.tipo-nat}
            it-doc-fisc.aliquota-icm 
            {ininc/i07in122.i 4 it-doc-fisc.cd-trib-icm} 
            it-doc-fisc.class-fiscal
            it-doc-fisc.it-codigo
            ITEM.desc-item
            it-doc-fisc.quantidade * fatorDevolucao
            it-doc-fisc.vl-bicms-it * fatorDevolucao
            it-doc-fisc.vl-icms-it  * fatorDevolucao
            deCredPresumido * fatorDevolucao
            (it-doc-fisc.vl-icms-it - deCredPresumido) * fatorDevolucao
            ITEM.codigo-orig
            ITEM.ge-codigo
            IF AVAIL grup-estoque THEN grup-estoque.descricao ELSE ''
            IF AVAIL emitente THEN emitente.cidade ELSE '' .

  END.
  IF LOG_dados = NO THEN
      PUT "NAO FORAM ENCONTRADOS DADOS" SKIP.
  OUTPUT CLOSE.
   ASSIGN bt_gerar_excel:LABEL IN FRAME {&FRAME-NAME} = 'Gerar Excel'
          bt_gerar_excel:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
   OS-COMMAND SILENT "start excel /n M:\EMS206\esp\excel\relatfiscal.xls". 

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-livre
ON CHOOSE OF MENU-ITEM mi-consultas /* Consultas */
DO:
  RUN pi-consulta IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-livre
ON CHOOSE OF MENU-ITEM mi-conteudo /* Conteudo */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  RUN pi-ajuda IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-livre
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relat¢rios */
DO:
  RUN pi-imprimir IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-programa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-programa w-livre
ON MENU-DROP OF MENU mi-programa /* Nome-do-Programa */
DO:
  run pi-disable-menu.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-livre
ON CHOOSE OF MENU-ITEM mi-sair /* Sair */
DO:
  RUN pi-sair IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-livre
ON CHOOSE OF MENU-ITEM mi-sobre /* Sobre... */
DO:
  {include/sobre.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-livre 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-livre  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE adm-current-page  AS INTEGER NO-UNDO.

  RUN get-attribute IN THIS-PROCEDURE ('Current-Page':U).
  ASSIGN adm-current-page = INTEGER(RETURN-VALUE).

  CASE adm-current-page: 

    WHEN 0 THEN DO:
       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-exihel.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 2,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-exihel ).
       RUN set-position IN h_p-exihel ( 1.13 , 75.72 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fi_cod_estabel_ini:HANDLE IN FRAME f-cad , 'BEFORE':U ).
    END. /* Page 0 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-livre  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-livre  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
  THEN DELETE WIDGET w-livre.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-livre  _DEFAULT-ENABLE
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
  DISPLAY fi_cod_estabel_ini fi_cod_estabel_fim fi_grupo_ini fi_grupo_fim 
          fi_codigo_orig_ini fi_codigo_orig_fim fi_it_codigo_ini 
          fi_it_codigo_fim fi_dt_docto_ini fi_dt_docto_fim tg_devolucao 
          fi_perc_presumido 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE fi_cod_estabel_ini fi_cod_estabel_fim fi_grupo_ini fi_grupo_fim 
         fi_codigo_orig_ini fi_codigo_orig_fim fi_it_codigo_ini 
         fi_it_codigo_fim fi_dt_docto_ini fi_dt_docto_fim tg_devolucao 
         fi_perc_presumido bt_gerar_excel rt-button RECT-3 RECT-2 
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-livre 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-livre 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-livre 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  run pi-before-initialize.

  {include/win-size.i}

  /*{utp/ut9000.i "XX9999" "9.99.99.999"}*/

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE retornaNaturezas w-livre 
PROCEDURE retornaNaturezas :
DEFINE OUTPUT PARAMETER cNatOper AS CHAR FORMAT 'x(400)'.
/*naturezas de venda*/
IF INPUT FRAME {&frame-name} tg_devolucao = NO THEN /*caso queira apenas devoluá∆o n∆o ser∆o selecionadas as naturezas de venda*/
FOR EACH natur-oper  NO-LOCK
    WHERE natur-oper.tp-rec-desp = 1 /*apenas venda de mercadorias*/  :
    IF cNatOPer = '' THEN
       ASSIGN cNatOPer = natur-oper.nat-operacao.
    ELSE
       ASSIGN cNatOper = cNatOper + ',' + natur-oper.nat-operacao.
END.

/*naturezas de devoluá∆o de vendas*/
FOR EACH natur-oper NO-LOCK
    WHERE especie-doc  = 'NFD' /*nota fiscal de devoluá∆o*/
    AND   natur-oper.tipo = 1 /*entrada*/ :
    IF cNatOPer = '' THEN
       ASSIGN cNatOPer = natur-oper.nat-operacao.
    ELSE
       ASSIGN cNatOper = cNatOper + ',' + natur-oper.nat-operacao.
END.




END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-livre  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this w-livre, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-livre 
PROCEDURE state-changed :
/*:T -----------------------------------------------------------
  Purpose:     Manuseia trocas de estado dos SmartObjects
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.

  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


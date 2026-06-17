&Scoped-define WINDOW-NAME C-Win

/*------------------------------------------------------------------------
File.............: imft01.w
Description......: Tela que apresenta os relat¢rios do Procedimento
Author...........: DATASUL S.A.
Created..........: 03/10/02 - 19:08 - super
OBS..............: Este fonte foi gerado pelo Data Viewer
------------------------------------------------------------------------*/

define variable c-prog-gerado as character no-undo initial "IMFT01".

def new shared var c-nom-prog-upc-mg97  as char format "x(50)" no-undo.
def new shared var c-nom-prog-appc-mg97 as char format "x(50)" no-undo.
def new shared var c-nom-prog-dpc-mg97  as char format "x(50)" no-undo.
def new shared var c-programa-mg97      as char format "x(08)" no-undo.
def new shared var c-versao-mg97        as char format "x(08)" no-undo.



def new global shared var c-arquivo-log    as char  format "x(60)"no-undo.
def new global shared var c-prg-vrs as char no-undo.
def new global shared var c-prg-obj as char no-undo.

run grapi/gr2002.p (input c-prog-gerado, input "2.00.00.000").

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

def var c-impressora-old     as char    no-undo. 
def var c-programa         as char                          no-undo.              
def var c-arquivo          as char                          no-undo.              
def var c-arq-old          as char                          no-undo.              
def var c-lista            as char init "" no-undo.              
def var c-cod-proced       as char                          no-undo.              
def var c-prog             as char init "" no-undo.              
def var c-titulo           as char init "Instru‡Æo para Separa‡Æo e Faturamento" no-undo.        
def var v-cod-prog-gerado  as char init "imft01" no-undo.           
DEF BUFFER empresa FOR mgadm.empresa.
/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define FRAME-NAME DEFAULT-FRAME                                   

/* ***********************  Control Definitions  ********************** */

DEFINE VAR C-Win AS WIDGET-HANDLE NO-UNDO.                                

DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda"
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar"
     SIZE 10 BY 1.

DEFINE BUTTON bt-ok 
     LABEL "Executar"
     SIZE 10 BY 1.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  
     SIZE 49.72 BY 1.38
     BGCOLOR 7 .

DEFINE VARIABLE SELECT-1 AS CHARACTER 
     VIEW-AS SELECTION-LIST                               SINGLE                               SCROLLBAR-VERTICAL                               SCROLLBAR-HORIZONTAL 
     SIZE 49 BY 5.46 NO-UNDO.

/* ************************  Frame Definitions  *********************** */

DEFINE FRAME DEFAULT-FRAME
     SELECT-1 AT ROW 1.08 COL 2 NO-LABEL
     bt-ok AT ROW 7.17 COL 2.57
     bt-cancelar AT ROW 7.17 COL 13.57
     bt-ajuda AT ROW 7.17 COL 40.43
     RECT-1 AT ROW 6.96 COL 1.57
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 51 BY 7.54.

/* *************************  Create Window  ************************** */

IF SESSION:DISPLAY-TYPE = "GUI" THEN
  CREATE WINDOW C-Win ASSIGN
         HIDDEN             = YES
         HEIGHT             = 7.54
         WIDTH              = 51.14
         MAX-HEIGHT         = 16
         MAX-WIDTH          = 80
         VIRTUAL-HEIGHT     = 16
         VIRTUAL-WIDTH      = 80
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = no
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

/* ***************  Runtime Attributes and UIB Settings  ************** */

IF SESSION:DISPLAY-TYPE = "GUI" AND VALID-HANDLE(C-Win)
THEN C-Win:HIDDEN = no.

/* ************************* Included-Libraries *********************** */


def new global shared var i-ep-codigo-usuario  like empresa.ep-codigo no-undo.
def new Global shared var l-implanta           as logical    init no.
def new Global shared var c-seg-usuario        as char format "x(12)" no-undo.
def new global shared var i-num-ped-exec-rpw  as integer no-undo.   
def new global shared var i-pais-impto-usuario as integer format ">>9" no-undo.
def new global shared var l-rpc as logical no-undo.
def new global shared var r-registro-atual as rowid no-undo.
def new global shared var c-arquivo-log    as char  format "x(60)"no-undo.
def new global shared var i-num-ped as integer no-undo.         
def new global shared var v_cdn_empres_usuar   like empresa.ep-codigo        no-undo.
def new global shared var v_cod_usuar_corren   like usuar_mestre.cod_usuario no-undo.
def new global shared var h_prog_segur_estab     as handle                   no-undo.
def new global shared var v_cod_grp_usuar_lst    as char                     no-undo.
def new global shared var v_num_tip_aces_usuar   as int                      no-undo.
def new global shared var rw-log-exec            as rowid                    no-undo.



/* ************************  Control Triggers  ************************ */

ON END-ERROR OF C-Win 
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

ON WINDOW-CLOSE OF C-Win
DO:
  APPLY "CLOSE" TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

ON CHOOSE OF bt-ajuda IN FRAME DEFAULT-FRAME
OR HELP OF FRAME {&FRAME-NAME}
DO:

RUN men/men900za.p (INPUT ?, INPUT THIS-PROCEDURE:HANDLE).

END.

ON CHOOSE OF bt-cancelar IN FRAME DEFAULT-FRAME
DO:
  apply "close" to this-procedure.
END.

ON CHOOSE OF bt-ok IN FRAME DEFAULT-FRAME
DO:
  if select-1:screen-value in frame {&frame-name} <> ? then do:
    if select-1:num-items in frame {&frame-name} <> 0 then
      run pi-selecao.
    RUN enable_UI.
  end.
END.

ON MOUSE-SELECT-DBLCLICK OF SELECT-1 IN FRAME DEFAULT-FRAME
DO:
    apply "choose" to bt-ok in frame {&frame-name}.
END.

/* ***************************  Main Block  *************************** */

ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME}
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.

ON CLOSE OF THIS-PROCEDURE 
   RUN disable_UI.

PAUSE 0 BEFORE-HIDE.

assign v-cod-prog-gerado = "imft01".

def var c-tit as char no-undo.

run grapi/gr2011.p (input v-cod-prog-gerado,
                    input "2.00.00.000",
                    input  v-cod-prog-gerado,
                    output c-tit,
                    output c-arquivo).

if return-value = "adm-error" then do:
   APPLY "CLOSE" TO THIS-PROCEDURE.
   return no-apply.
end.

assign {&WINDOW-NAME}:title = c-tit
       c-arq-old        = c-arquivo
       c-impressora-old = c-arquivo.


MAIN-BLOCK:
DO ON ERROR   UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK 
   ON END-KEY UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK:

        assign c-lista = "" + "," + 
                         "" + "," + 
                         "".

        assign c-prog = "imft01a.w" + "," + 
                        "imft01b.w" + "," + 
                        "imft01c.w".


run grapi/gr2012.p (input {&window-name}:handle,
                    input v-cod-prog-gerado,
                    input-output c-lista,
                    input-output c-prog).

  assign select-1:list-items in frame {&frame-name} = c-lista.

  if c-lista <> "" then
    assign select-1:screen-value in frame {&frame-name} = entry(1, select-1:list-items in frame {&frame-name}).

  RUN enable_UI.
  IF NOT THIS-PROCEDURE:PERSISTENT THEN
    WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.

/* **********************  Internal Procedures  *********************** */

PROCEDURE disable_UI :
  IF SESSION:DISPLAY-TYPE = "GUI" AND VALID-HANDLE(C-Win)
  THEN DELETE WIDGET C-Win.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

PROCEDURE enable_UI :
  DISPLAY SELECT-1 
      WITH FRAME DEFAULT-FRAME IN WINDOW C-Win.
  ENABLE SELECT-1 /* bt-gerador */ RECT-1 bt-ok bt-cancelar bt-ajuda
      WITH FRAME DEFAULT-FRAME IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-DEFAULT-FRAME}
  VIEW C-Win.
END PROCEDURE.

PROCEDURE local-destroy :
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'destroy':U ) .
END PROCEDURE.

PROCEDURE pi-selecao :
selecao:
do on error undo selecao, retry selecao:

  if select-1:num-items in frame {&frame-name}<> 0 then do:
    assign c-programa = entry(select-1:lookup(select-1:screen-value in frame {&FRAME-NAME}) in frame {&FRAME-NAME}, c-prog)
           c-programa = "imp" + "/" + c-programa.


    assign c-programa = entry(select-1:lookup(select-1:screen-value in frame {&FRAME-NAME}) in frame {&FRAME-NAME}, c-prog).

    def var h-prog as handle no-undo.

    run value(c-programa) persistent set h-prog.
    if valid-handle(h-prog) then
      run dispatch in h-prog ("Initialize":U) no-error.

  end.
end.

hide frame {&FRAME-NAME}.

END PROCEDURE.

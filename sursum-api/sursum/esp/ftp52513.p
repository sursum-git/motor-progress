/*****************************************************************************
**
**       Programa: ftp52513.p
**
**       Data....: 21/05/03
**
**       Autor...: DATASUL S.A.
**
**       Objetivo: Fechamento de Caixa
**
**       VersÆo..: 1.00.000 - CDIAS
**
**       OBS.....: Este fonte foi gerado pelo Data Viewer
**
*******************************************************************************/

define variable c-prog-gerado as character no-undo initial "FTP52513".

def new global shared var c-arquivo-log    as char  format "x(60)"no-undo.
def new global shared var c-prg-vrs as char no-undo.
def new global shared var c-prg-obj as char no-undo.

run grapi/gr2002.p (input c-prog-gerado, input "2.00.00.000").

/****************** Defini‡Æo de Tabelas Tempor rias do Relat¢rio **********************/

def temp-table tt-raw-digita
    field raw-digita as raw.

define temp-table tt-param
    field destino              as integer
    field arquivo              as char
    field usuario              as char
    field data-exec            as date
    field hora-exec            as integer
    field parametro            as logical
    field formato              as integer
    field v_num_tip_aces_usuar as integer
    field ep-codigo            as integer
    field da-dt-emis-nota-ini like nota-fiscal.dt-emis-nota
    field da-dt-emis-nota-fim like nota-fiscal.dt-emis-nota
.

/****************** INCLUDE COM VARIµVEIS GLOBAIS *********************/

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


/****************** FIM INCLUDE COM VARIµVEIS GLOBAIS *********************/
/****************** Defini‡ao de Parƒmetros do Relat¢rio *********************/ 

/****************** Defini‡ao de Vari veis de Sele‡Æo do Relat¢rio *********************/ 

def new shared var da-dt-emis-nota-ini like nota-fiscal.dt-emis-nota format "99/99/9999" initial "01/01/1800" no-undo.
def new shared var da-dt-emis-nota-fim like nota-fiscal.dt-emis-nota format "99/99/9999" initial "12/31/9999" no-undo.

/****************** Defini‡ao de Vari veis p/ Campos Virtuais do Relat¢rio *******************/ 

/****************** Defini‡ao de Vari veis Campo do Layout do Relat¢rio **********************/ 

def var branco as character.
def var dt-at as date.

/****************** Defini‡ao de Vari veis do Relat¢rio NÆo Pedidas em Tela ******************/ 

/****************** Defini‡ao de Vari veis de Total do Relat¢rio *****************************/ 

def var de-vl-tot-nota-tt-001 like nota-fiscal.vl-tot-nota no-undo.

/****************** Defini‡ao de Vari veis dos Calculos do Relat¢rio *************************/ 

def input param raw-param as raw no-undo.
def input param table for tt-raw-digita.

/***************** Defini‡ao de Vari veis de Processamento do Relat¢rio *********************/

def var h-acomp              as handle no-undo.
def var v-cod-destino-impres as char   no-undo.
def var v-num-reg-lidos      as int    no-undo.
def var v-num-point          as int    no-undo.
def var v-num-set            as int    no-undo.
def var v-num-linha          as int    no-undo.

/****************** Defini‡ao de Forms do Relat¢rio 132 Colunas ***************************************/ 

form nota-fiscal.cod-estabel label "Empresa" format "X(3)" at 001
     estabelec.nome no-label  format "X(40)" at 014
     dt-at label "Data" format "99/99/9999" at 059 skip
     branco no-label  format "xxx" at 001
     with down width 132 side-labels no-box stream-io frame f-relat-01-132.

form nota-fiscal.nr-nota-fis column-label "Nota Fiscal" format "x(7)" at 001
     nota-fiscal.nr-pedcli column-label "Pedido" format "x(6)" at 014
     nota-fiscal.cod-emitente column-label "Cliente" format ">>>>9" at 021
     emitente.nome-emit column-label "Nome" format "X(40)" at 029
     cond-pagto.descricao column-label "Cond. Pagamento" format "x(20)" at 070
     nota-fiscal.vl-tot-nota column-label "Total da Nota" format ">>>,>>>,>>9.99" at 091
     with down width 132 no-box stream-io frame f-relat-09-132.

create tt-param.
raw-transfer raw-param to tt-param.

def temp-table tt-editor no-undo
    field linha      as integer
    field conteudo   as character format "x(80)"
    index editor-id is primary unique linha.


def var rw-log-exec                            as rowid no-undo.
def var c-erro-rpc as character format "x(60)" initial " " no-undo.
def var c-erro-aux as character format "x(60)" initial " " no-undo.
def var c-ret-temp as char no-undo.
def var h-servid-rpc as handle no-undo.     
define var c-empresa       as character format "x(40)"      no-undo.
define var c-titulo-relat  as character format "x(50)"      no-undo.
define var i-numper-x      as integer   format "ZZ"         no-undo.
define var da-iniper-x     as date      format "99/99/9999" no-undo.
define var da-fimper-x     as date      format "99/99/9999" no-undo.
define var i-page-size-rel as integer                       no-undo.
define var c-programa      as character format "x(08)"      no-undo.
define var c-versao        as character format "x(04)"      no-undo.
define var c-revisao       as character format "999"        no-undo.

define new shared var c-impressora   as character                      no-undo.
define new shared var c-layout       as character                      no-undo.
define new shared var v_num_count     as integer                       no-undo.
define new shared var c-arq-control   as character                     no-undo.
define new shared var c-sistema       as character format "x(25)"      no-undo.
define new shared var c-rodape        as character                     no-undo.

define new shared buffer b_ped_exec_style for ped_exec.
define new shared buffer b_servid_exec_style for servid_exec.

define new shared stream str-rp.

assign c-programa     = "ftp52513"
       c-versao       = "2.00"
       c-revisao      = ".00.000"
       c-titulo-relat = "Fechamento de Caixa"
       c-sistema      = "ftp".

if  tt-param.formato = 2 then do:


form header
    fill("-", 132) format "x(132)" skip
    c-empresa c-titulo-relat at 50
    "Folha:" at 122 page-number(str-rp) at 128 format ">>>>9" skip
    fill("-", 112) format "x(110)" today format "99/99/9999"
    "-" string(time, "HH:MM:SS") skip(1)
    with stream-io width 132 no-labels no-box page-top frame f-cabec.

form header
    fill("-", 132) format "x(132)" skip
    c-empresa c-titulo-relat at 50
    "Folha:" at 122 page-number(str-rp) at 128 format ">>>>9" skip
    "Periodo:" i-numper-x at 08 "-"
    da-iniper-x at 14 "to" da-fimper-x
    fill("-", 74) format "x(72)" today format "99/99/9999"
    "-" string(time, "HH:MM:SS") skip(1)
    with stream-io width 132 no-labels no-box page-top frame f-cabper.

run grapi/gr2004.p.

form header
    c-rodape format "x(132)"
    with stream-io width 132 no-labels no-box page-bottom frame f-rodape.


end. /* tt-param.formato = 2 */


run grapi/gr2009.p (input tt-param.destino,
                    input tt-param.arquivo,
                    input tt-param.usuario,
                    input no).

    assign i-ep-codigo-usuario = tt-param.ep-codigo
           v_cdn_empres_usuar  = i-ep-codigo-usuario.

    assign da-dt-emis-nota-ini = tt-param.da-dt-emis-nota-ini
           da-dt-emis-nota-fim = tt-param.da-dt-emis-nota-fim
           da-dt-emis-nota-fim = tt-param.da-dt-emis-nota-fim
.


find first empresa no-lock
    where empresa.ep-codigo = i-ep-codigo-usuario no-error.
if  avail empresa
then
    assign c-empresa = empresa.razao-social.
else
    assign c-empresa = "".

/* for each e disp */

def var l-imprime as logical no-undo.


        assign de-vl-tot-nota-tt-001 = 0.
assign l-imprime = no.
if  tt-param.destino = 1 then
    assign v-cod-destino-impres = "Impressora".
else
    if  tt-param.destino = 2 then
        assign v-cod-destino-impres = "Arquivo".
    else
        assign v-cod-destino-impres = "Terminal".


run utp/ut-acomp.p persistent set h-acomp.

run pi-inicializar in h-acomp(input "Acompanhamento Relat¢rio").

assign v-num-reg-lidos = 0.

for each nota-fiscal no-lock
         where nota-fiscal.dt-emis-nota >= da-dt-emis-nota-ini and 
               nota-fiscal.dt-emis-nota <= da-dt-emis-nota-fim,
    each emitente no-lock
         where emitente.cod-emitente = nota-fiscal.cod-emitente,
    each estabelec no-lock
         where estabelec.cod-estabel = nota-fiscal.cod-estabel,
    each cond-pagto no-lock
         where cond-pagto.cod-cond-pag = nota-fiscal.cod-cond-pag and
               (emitente.identific  <> 2) and
               (nota-fiscal.nat-operacao  = "51201" or
               nota-fiscal.nat-operacao  = "51202" or
               nota-fiscal.nat-operacao  = "51203" or
               nota-fiscal.nat-operacao  = "61201" or
               nota-fiscal.nat-operacao  = "61202" or
               nota-fiscal.nat-operacao  = "61203")
    break by nota-fiscal.cod-estabel
          by nota-fiscal.nr-nota-fis:

    assign v-num-reg-lidos = v-num-reg-lidos + 1.
    run pi-acompanhar in h-acomp(input string(v-num-reg-lidos)).

    assign dt-at = nota-fiscal.dt-emis-nota .
    /***  CàDIGO PARA SAÖDA EM 132 COLUNAS ***/

    if  tt-param.formato = 2 then do:

        view stream str-rp frame f-cabec.
        view stream str-rp frame f-rodape.
        assign l-imprime = yes.
        if  first-of(nota-fiscal.cod-estabel) then do:
            display stream str-rp " " with stream-io no-box frame f-branco.
            display stream str-rp nota-fiscal.cod-estabel
                estabelec.nome
                dt-at
                branco
                    with stream-io frame f-relat-01-132.
            display stream str-rp " " with stream-io no-box frame f-branco.
        end.

        display stream str-rp nota-fiscal.nr-nota-fis
            nota-fiscal.nr-pedcli
            nota-fiscal.cod-emitente
            emitente.nome-emit
            cond-pagto.descricao
            nota-fiscal.vl-tot-nota
                with stream-io frame f-relat-09-132.
            down stream str-rp with frame f-relat-09-132.
    end.
    assign de-vl-tot-nota-tt-001 = de-vl-tot-nota-tt-001 + 
                                           nota-fiscal.vl-tot-nota.

    
end.


if  l-imprime = no then do:
    if  tt-param.formato = 2 then do:
        view stream str-rp frame f-cabec.
        view stream str-rp frame f-rodape.
    end.
    disp stream str-rp " " with stream-io frame f-nulo.
end.
    display stream str-rp "--------------" @ 
            nota-fiscal.vl-tot-nota
            with stream-io frame f-relat-09-132.
    down stream str-rp with frame f-relat-09-132.
put stream str-rp "Total Faturado:" at 075 de-vl-tot-nota-tt-001 format ">>>,>>>,>>9.99" to 104.

run pi-finalizar in h-acomp.

if  tt-param.destino <> 1 then

    page stream str-rp.

else do:

    if   tt-param.parametro = yes then

         page stream str-rp.

end.

if  tt-param.parametro then do:


   disp stream str-rp "SELE€ÇO" skip(01) with stream-io frame f-imp-sel.
   disp stream str-rp 
      da-dt-emis-nota-ini colon 14 "|< >|"   at 38 da-dt-emis-nota-fim no-label
        with stream-io side-labels overlay row 038 frame f-imp-sel.

   put stream str-rp unformatted skip(1) "IMPRESSÇO" skip(1).

   put stream str-rp unformatted skip "    " "Destino : " v-cod-destino-impres " - " tt-param.arquivo format "x(40)".
   put stream str-rp unformatted skip "    " "Execu‡Æo: " if i-num-ped-exec-rpw = 0 then "On-Line" else "Batch".
   put stream str-rp unformatted skip "    " "Formato : " if tt-param.formato = 1 then "80 colunas" else "132 colunas".
   put stream str-rp unformatted skip "    " "Usu rio : " tt-param.usuario.

end.

else
    output stream str-rp close.

procedure pi-print-editor:

    def input param c-editor    as char    no-undo.
    def input param i-len       as integer no-undo.

    def var i-linha  as integer no-undo.
    def var i-aux    as integer no-undo.
    def var c-aux    as char    no-undo.
    def var c-ret    as char    no-undo.

    for each tt-editor:
        delete tt-editor.
    end.

    assign c-ret = chr(255) + chr(255).

    do  while c-editor <> "":
        if  c-editor <> "" then do:
            assign i-aux = index(c-editor, chr(10)).
            if  i-aux > i-len or (i-aux = 0 and length(c-editor) > i-len) then
                assign i-aux = r-index(c-editor, " ", i-len + 1).
            if  i-aux = 0 then
                assign c-aux = substr(c-editor, 1, i-len)
                       c-editor = substr(c-editor, i-len + 1).
            else
                assign c-aux = substr(c-editor, 1, i-aux - 1)
                       c-editor = substr(c-editor, i-aux + 1).
            if  i-len = 0 then
                assign entry(1, c-ret, chr(255)) = c-aux.
            else do:
                assign i-linha = i-linha + 1.
                create tt-editor.
                assign tt-editor.linha    = i-linha
                       tt-editor.conteudo = c-aux.
            end.
        end.
        if  i-len = 0 then
            return c-ret.
    end.
    return c-ret.
end procedure.

return 'OK'.

/* fim do programa */

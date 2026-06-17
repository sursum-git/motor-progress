/*****************************************************************************
**
**  MESSAGE.P - Interface de Mensagens do Magnus 97
**
**  1.00.000 - 12/1997 - Marcio Chaves 
**
*****************************************************************************/

def input param p_msg_val as character no-undo.
def input param p_msg_hlp as character no-undo.

def var v_msg_val        as character no-undo
                            view-as editor size-char 61 by 1.
 
def var v_msg_hlp        as character no-undo
                            view-as editor size-char 50 by 3
                            scrollbar-vertical font 2.
                            
def var l-question       as logical   no-undo.
def var l_status         as logical   no-undo.
 
def rectangle rt_help    size-char 52 by 4 edge-pixels 2 bgcolor 8.
def image im_msg_ico     file "image/im-mqerr".
def rectangle rt_button  size-char 61 by 1.42 edge-pixels 1 bgcolor 7.
def button bt_ok         label "OK" size-char 10 by 1 auto-go.
def button bt_no         label "NÆo" size-char 10 by 1 auto-go.
def var c-tipo  as char no-undo.
 
def frame f_msg_help
    v_msg_val    at row 1.5 col 2
    im_msg_ico   at row 3.5 col  4
    v_msg_hlp    at row 3.5 col 12
    rt_help      at row 3.0 col 11
    " Ajuda "    at row 2.5 col 14
    rt_button    at row 7.5 col 2 space(1)
    bt_ok        at row 7.71 col 3
    bt_no        at row 7.71 col 14
    skip(0.5)
    with Title "Mensagem de Erro" three-d no-label view-as dialog-box.
 
on  cursor-right of
 bt_ok, bt_no    apply "TAB" to self.
on  cursor-left of
 bt_ok, bt_no    apply "SHIFT-TAB" to self.
 
on  choose of bt_ok
    return "yes".
on  choose of bt_no
    return "no".

assign l-question = no.

assign v_msg_val = p_msg_val  
       v_msg_hlp = p_msg_hlp.

   assign v_msg_val:read-only in frame f_msg_help = yes
          v_msg_hlp:read-only in frame f_msg_help = yes.
 
if  l-question then
    assign bt_no:hidden in frame f_msg_help = no
           bt_no:sensitive in frame f_msg_help = yes
           bt_ok:label in frame f_msg_help = "Sim".
else
    assign bt_no:hidden in frame f_msg_help = yes
           bt_no:sensitive in frame f_msg_help = no
           bt_ok:label in frame f_msg_help = "OK".
 

if  session:batch-mode = no then do:
   do  on endkey undo, retry with frame f_msg_help:
       display v_msg_val v_msg_hlp.
       enable  v_msg_val v_msg_hlp.
       update bt_ok bt_no when l-question with keep-tab-order.
   end.
end.
else do:
   message v_msg_val v_msg_hlp.
end.   
   
hide frame f_msg_help.

RETURN 'Ok'.

/* UT-MSGS2.P */

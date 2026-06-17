/*Programa para simula‡Æo de nota fiscal … vista
Permite o faturista ver o valor TOTAL da nota quando 
o pedido possui desconto informado.Programa feito por 
Tadeu Silva devido mudan‡a dos parametros dos CFOP's 
para calculo sobre valor liquido da nota.
Data: 24/01/2007*/
/*MESSAGE 'Esse programa foi descontinuado.' skip
        'Para verifica‡Æo do valor deve ser utilizado o programa essp0155' SKIP
    VIEW-AS ALERT-BOX INFO BUTTONS OK.
RUN esp/essp0155.p.
RETURN.*/
DEF VAR c-pedido   AS CHAR       VIEW-AS FILL-IN LABEL "N§ Pedido" FORMAT "x(11)".
DEF VAR c-embarque AS CHAR       VIEW-AS COMBO-BOX INNER-LINES 3 LIST-ITEMS " " DROP-DOWN  SIZE 15.5 BY 1 LABEL "Embarque" .
DEF VAR c-lista    AS CHAR.
DEF VAR vr-nf      AS DEC INIT 0 VIEW-AS FILL-IN. 
DEF VAR vr-res     AS DEC INIT 0 VIEW-AS FILL-IN.
DEF VAR tt-nf      AS DEC INIT 0 VIEW-AS TEXT LABEL "VR Nota" .
DEF VAR tt-res     AS DEC INIT 0 VIEW-AS TEXT LABEL "Outros".
DEF VAR tt-geral   AS DEC INIT 0 VIEW-AS TEXT LABEL "Total".
DEF VAR i-cont     AS INT.
DEF BUTTON b-atu   LABEL "Consultar" SIZE 10 BY 1.
DEF BUTTON bt-sair LABEL "Sair" SIZE 10 BY 1.
DEF TEMP-TABLE teste 
         FIELD pedido   AS CHAR
         FIELD ITEM     AS CHAR
         FIELD codigo   AS CHAR
         FIELD seq      AS INT
         FIELD quant    AS DEC
         FIELD vr-nf    AS DEC
         FIELD vr-res   AS DEC.


DEF FRAME f-cons 
    c-pedido        AT ROW 2   COL 2        
    b-atu           AT ROW 2   COL-OF c-pedido + 26   
    bt-sair         AT ROW 3   COL-OF c-pedido + 26
    c-embarque      AT ROW 3   COL 1.6
    tt-nf           AT ROW 4.5 COL 3.7
    tt-res          AT ROW 5.5 COL 5 
    tt-geral        AT ROW 6.5 COL 6.5 WITH SIDE-LABELS  VIEW-AS DIALOG-BOX 
       THREE-D SIZE 40 BY 8 TITLE "Simula‡Æo … vista" OVERLAY .


ON 'leave':U OF  c-pedido DO:
  IF c-pedido:SCREEN-VALUE <> '' THEN DO:
    ASSIGN I-CONT = 0.
    FOR EACH bc-etiqueta WHERE bc-etiqueta.nr-pedcli = c-pedido:SCREEN-VALUE BREAK  BY bc-etiqueta.nr-embarque :
       IF LAST-OF(bc-etiqueta.nr-embarque) THEN DO:
           ASSIGN i-cont = i-cont + 1.
           ASSIGN c-lista = IF c-lista = ' ' THEN STRING(bc-etiqueta.nr-embarque)
                        ELSE c-lista + ',' + STRING (bc-etiqueta.nr-embarque).
       END.
    END.
    ASSIGN c-embarque:LIST-ITEMS  = c-lista.
  FIND pre-fatur WHERE  pre-fatur.nr-pedcli = c-pedido:SCREEN-VALUE NO-LOCK NO-ERROR.
    ASSIGN c-embarque:SCREEN-VALUE = STRING (pre-fatur.nr-embarque).
  IF i-cont > 1  THEN
      MESSAGE 'Esse pedido possui etiquetas romaneadas em mais de um embarque.'
              'No campo embarque aparecer  a op‡Æo dos embarques romaneados, tendo '
              'como inicio o embarque no qual est  o pedido. INFORME O ROMANEIO!!!' 
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
  END.

    
RETURN.
END.

ON 'leave':U OF c-embarque DO:
   IF c-embarque:SCREEN-VALUE <> " " THEN DO:
      FIND  pre-fatur WHERE pre-fatur.nr-embarque = INT (c-embarque:SCREEN-VALUE) NO-LOCK NO-ERROR.
            ASSIGN c-pedido:SCREEN-VALUE = pre-fatur.nr-pedcli.
   END.

RETURN.
END.

ON 'choose':U OF b-atu DO:
  
  IF c-pedido:SCREEN-VALUE <> " " THEN DO:
     FOR EACH bc-etiqueta WHERE bc-etiqueta.nr-pedcli   = c-pedido:SCREEN-VALUE AND 
                                bc-etiqueta.nr-embarque = INT (c-embarque:SCREEN-VALUE)  BY bc-etiqueta.nr-seq-fat.
       CREATE TESTE.
       ASSIGN teste.ITEM     = BC-ETIQUETA.IT-CODIGO
             teste.CODIGO    = BC-ETIQUETA.REFERENCIA
             teste.QUANT     = BC-ETIQUETA.QT-ITEM
             teste.VR-NF     = 0
             teste.VR-RES    = 0
             i-cont          = i-cont + 1
             teste.pedido    = bc-etiqueta.nr-pedcli
             teste.seq       = bc-etiqueta.nr-seq-fat.
    END.
    /*FOR EACH teste.
    DISP teste WITH WIDTH 550.
    END.*/
    
    IF i-cont = 0 THEN
      MESSAGE "NÆo h  etiquetas romaneadas para esse pedido "
              VIEW-AS ALERT-BOX INFO BUTTONS OK.
    FOR EACH ped-venda WHERE ped-venda.nr-pedido = INT(c-pedido:SCREEN-VALUE),
      EACH ped-item OF ped-venda WHERE cod-sit-item <> 5 AND cod-sit-item <> 6 NO-LOCK.
       FOR EACH teste WHERE teste.ITEM = ped-item.it-codigo AND 
                teste.codigo           = ped-item.cod-refer .
           ASSIGN teste.VR-NF  = TESTE.QUANT * PED-ITEM.VL-PREUNI
                  teste.VR-RES = IF PED-ITEM.VL-PREORI <> PED-ITEM.VL-PREUNI THEN 
                                    TESTE.QUANT * (PED-ITEM.VL-PREORI - PED-ITEM.VL-PREUNI)
                                 ELSE 0 . 
        
                               
       END.

   END.
   OUTPUT TO c:\temp\teste.txt.

   FOR EACH teste.
   DISP teste WITH WIDTH 550.
   END. 
   OUTPUT CLOSE.
   FIND ped-venda WHERE ped-venda.nr-pedcli = c-pedido:SCREEN-VALUE NO-LOCK NO-ERROR.
        IF NOT AVAIL ped-venda THEN
           MESSAGE "Pedido NÆo Existe"
               VIEW-AS ALERT-BOX INFO BUTTONS OK.
    FOR EACH teste.
    ASSIGN tt-res = tt-res + teste.vr-res
           tt-nf  = tt-nf  + teste.vr-nf.
    END.           
                
    ASSIGN tt-geral = tt-res + tt-nf .
    DISP tt-res tt-nf tt-geral WITH FRAME f-cons.
    /*DISP i-cont.   */
    ASSIGN tt-geral       = 0.
    ASSIGN tt-res         = 0.
    ASSIGN tt-nf          = 0.    
    ASSIGN i-cont         = 0.
    FOR EACH teste.
     DELETE teste.
    END.
  END.                                                                                                                 
RETURN 'ok'.

END.


ENABLE c-pedido c-embarque b-atu bt-sair WITH FRAME f-cons .
WAIT-FOR WINDOW-CLOSE OF CURRENT-WINDOW OR CHOOSE OF bt-sair .



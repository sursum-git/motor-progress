disable triggers for load of ems2cad.emitente.
disable triggers for load of ems5.clien_financ.

DEF BUFFER b-repres FOR repres.


define variable c-saida         as character                  no-undo.
define variable l-rep-ima          as logical initial false      no-undo.

//define variable d-ultdata-ima   as date initial 01.01.1000    no-undo.
//define variable c-ultpedcli-ima as character initial ""       no-undo.

define variable da-ultped   as date initial 01.01.1000    no-undo.
define variable c-ultped as character initial ""       no-undo.

//define variable i-qtddias-ima   as integer initial 0          no-undo.
define variable i-qtd-dias-ultped   as integer initial 0          no-undo.
define variable i-qtddias-cli   as integer initial 0          no-undo.

DEF VAR c-rep-ultped LIKE ped-venda.no-ab-reppri.


ASSIGN c-saida = IF OPSYS = "WIN32" THEN "c:\temp\" ELSE "/log/repres/".
ASSIGN c-saida = c-saida + "prgvalida_repres_" + string(today,"99-99-99") + "_" + replace(string(time,"hh:mm"),":","h") + ".csv".

os-delete value(c-saida).
//output to value(c-saida).

FIND espec.im-param where
     espec.im-param.cod-param = "valida_repres"
     no-lock no-error.

IF not avail espec.im-param then do:
   put unformat "parametro nao encontrado na tabela espec.im-param".
   leave.
END.

/*
put unformat "relatorio diario valida cliente do representante mais de " + espec.im-param.val-param + " dias" skip.
put unformat "ems2cad.repres;;;ems2cad.emitente;;;;;imatextil;;;;medtextil" skip.
put unformat "cod-rep;nome-abrev;;cod-emitente;nome-abrev;dt-implant;i-qtddias-cli;;d-ultdata-ima;c-ultpedcli-ima;i-qtddias-ima;;da-ultped;c-ultped;i-qtd-dias-ultped" skip.
*/
FOR EACH emitente WHERE 
         emitente.identific <> 2 SHARE-LOCK.
         
    DISP emitente.cod-emit.
    PAUSE 0.

    ASSIGN da-ultped    = ?
           c-ultped     = ""
           c-rep-ultped = ""
           i-qtd-dias-ultped = 0.

    FOR LAST ped-venda WHERE
             ped-venda.nome-abrev = emitente.nome-abrev AND 
             ped-venda.cod-sit-ped <> 6 NO-LOCK.
        ASSIGN da-ultped = ped-venda.dt-emissao
               c-ultped = ped-venda.nr-pedcli
               c-rep-ultped = ped-venda.no-ab-reppri.
    END.

    ASSIGN l-rep-ima = NO.

    IF da-ultped <> ? THEN DO.
       IF da-ultped <> ? THEN
          ASSIGN i-qtd-dias-ultped = TODAY - da-ultped.

       IF i-qtd-dias-ultped > INT(im-param.val-param) AND 
          emitente.data-implant < TODAY - INT(im-param.val-param) THEN 
          ASSIGN l-rep-ima = YES.
    END.
    ELSE DO.   // NÆo tem Pedido, e ‚ Antigo, vira IMA
       IF emitente.data-implant < TODAY - INT(im-param.val-param) THEN
          ASSIGN l-rep-ima = YES.
    END.

    IF l-rep-ima THEN DO:
       ASSIGN emitente.cod-rep = 1.
       FOR EACH ems5.clien_financ WHERE
                ems5.clien_financ.cdn_cliente = ems2cad.emitente.cod-emitente
                SHARE-LOCK.
            ASSIGN ems5.clien_financ.cdn_repres = 1.
       END.
    END.
    ELSE DO.
       IF c-rep-ultped <> '' THEN DO.
          FIND b-repres WHERE
               b-repres.nome-abrev = c-rep-ultped NO-LOCK NO-ERROR.

          ASSIGN emitente.cod-rep = b-repres.cod-rep.
          FOR EACH clien_financ WHERE
                   clien_financ.cdn_cliente = ems2cad.emitente.cod-emitente 
                   SHARE-LOCK.
              ASSIGN clien_financ.cdn_repres = b-repres.cod-rep.
          END.
       END.
    END.
END.

//output close.

disable triggers for load of ems2cad.emitente.
disable triggers for load of ems2cad.emitente.
disable triggers for load of ems5.clien_financ.

define variable c-saida      as character no-undo.
DEFINE VARIABLE d-dt-implant AS DATE INITIAL TODAY NO-UNDO.
/*DEFINE VARIABLE d-dt-implant AS DATE INITIAL 03.12.2015 NO-UNDO. */

DEFINE VARIABLE i-cod-rep-ima    AS INT  INITIAL 0 NO-UNDO.
DEFINE VARIABLE i-cod-rep-med    AS INT  INITIAL 0 NO-UNDO.
DEFINE VARIABLE i-cdn_repres-100 AS INT  INITIAL 0 NO-UNDO.
DEFINE VARIABLE i-cdn_repres-500 AS INT  INITIAL 0 NO-UNDO.

DEF TEMP-TABLE tt-ped-venda
    FIELD cod-estabel  LIKE ems2ima.ped-venda.cod-estabel
    FIELD cod-emitente LIKE ems2ima.ped-venda.cod-emitente
    FIELD no-ab-reppri LIKE ems2ima.ped-venda.no-ab-reppri
    FIELD nr-pedcli    LIKE ems2ima.ped-venda.nr-pedcli
    FIELD dt-implant   LIKE ems2ima.ped-venda.dt-implant.

assign c-saida = if opsys = "win32" then "c:\temp\" else "/log/ped-venda/".
assign c-saida = c-saida + "prgvalida_ped-venda_" + string(today,"99-99-99") + "_" + replace(string(time,"hh:mm"),":","h") + ".csv".

os-delete value(c-saida).
//output to value(c-saida).

//put UNFORMAT "ped-venda.cod-estabel;ped-venda.cod-emitente;ped-venda.no-ab-reppri;ped-venda.nr-pedcli;ped-venda.dt-implant;emitente.cod-emitente;emitente.nome-abrev;emitente.cod-rep;i-cod-rep-ima;i-cod-rep-med;repres.cod-rep;repres.nome-abrev;clien_financ.cod_empresa;clien_financ.cdn_cliente;clien_financ.cdn_repres;i-cdn_repres-100;i-cdn_repres-500" SKIP.

FOR EACH ems2med.ped-venda WHERE 
         ems2med.ped-venda.no-ab-reppri <> "ima" AND 
         ems2med.ped-venda.cod-emitente <> 1 AND 
         ems2med.ped-venda.dt-implant   >= TODAY - 200 NO-LOCK.

    FIND tt-ped-venda WHERE
         tt-ped-venda.cod-emitente = ems2med.ped-venda.cod-emitente
         NO-LOCK NO-ERROR.

    IF NOT AVAIL tt-ped-venda THEN DO.
       CREATE tt-ped-venda.
       ASSIGN tt-ped-venda.cod-estabel  = ems2med.ped-venda.cod-estabel 
              tt-ped-venda.cod-emitente = ems2med.ped-venda.cod-emitente
              tt-ped-venda.no-ab-reppri = ems2med.ped-venda.no-ab-reppri.
    END.
    ASSIGN tt-ped-venda.no-ab-reppri = ems2med.ped-venda.no-ab-reppri
           tt-ped-venda.nr-pedcli    = ems2med.ped-venda.nr-pedcli   
           tt-ped-venda.dt-implant   = ems2med.ped-venda.dt-implant.
END.

FOR EACH tt-ped-venda NO-LOCK BY tt-ped-venda.cod-emit.
    DISP tt-ped-venda.cod-emit.
    PAUSE 0.

    FIND ems2cad.emitente WHERE 
         ems2cad.emitente.cod-emitente = tt-ped-venda.cod-emitente
         SHARE-LOCK NO-ERROR.

    FIND ems2cad.repres WHERE
         ems2cad.repres.nome-abrev = tt-ped-venda.no-ab-reppri
         NO-LOCK NO-ERROR.

    ASSIGN ems2cad.emitente.cod-rep = ems2cad.repres.cod-rep.


    FOR EACH ems5.clien_financ WHERE
             ems5.clien_financ.cdn_cliente = tt-ped-venda.cod-emitente
             SHARE-LOCK.

        ASSIGN ems5.clien_financ.cdn_repres = ems2cad.repres.cod-rep.

        /*
        put UNFORMAT
              tt-ped-venda.cod-estabel
           ";"tt-ped-venda.cod-emitente
           ";"tt-ped-venda.no-ab-reppri
           ";"tt-ped-venda.nr-pedcli
           ";"tt-ped-venda.dt-implant
           ";"ems2cad.emitente.cod-emitente
           ";"ems2cad.emitente.nome-abrev
           ";"ems2cad.emitente.cod-rep
           ";"i-cod-rep-ima
           ";"i-cod-rep-med
           ";"ems2cad.repres.cod-rep
           ";"ems2cad.repres.nome-abrev
           ";"ems5.clien_financ.cod_empresa
           ";"ems5.clien_financ.cdn_cliente
           ";"ems5.clien_financ.cdn_repres
           ";"i-cdn_repres-100
           ";"i-cdn_repres-500
           skip.
        */    
    END.
END.

//output close.

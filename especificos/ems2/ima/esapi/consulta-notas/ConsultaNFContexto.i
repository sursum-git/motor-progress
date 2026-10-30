/* Mesmos buffers logicos nas duas coletas. Sem cache entre notas/requisicoes. */
DEFINE BUFFER bExt FOR espec.ped-venda-ext.
DEFINE BUFFER bPrincipal FOR {&ERP}.ped-repre.

PROCEDURE PreencherContextoNota:
    ASSIGN tt-NF.cod-emitente = bNota.cod-emitente
           tt-NF.cod-rep = bNota.cod-rep
           tt-NF.nr-pedcli = bNota.nr-pedcli
           tt-NF.preposto = ""
           tt-NF.perc-comis = ?.
    IF CAN-FIND(FIRST bExt WHERE bExt.cod-estabel = bNota.cod-estabel
                             AND bExt.nr-pedido = bPedido.nr-pedido NO-LOCK) THEN DO:
        FIND FIRST bExt NO-LOCK WHERE bExt.cod-estabel = bNota.cod-estabel
                                 AND bExt.nr-pedido = bPedido.nr-pedido.
        tt-NF.preposto = bExt.preposto.
    END.
    IF CAN-FIND(FIRST bPrincipal WHERE bPrincipal.nr-pedido = bPedido.nr-pedido
                                   AND bPrincipal.nome-ab-rep = bNota.no-ab-reppri NO-LOCK) THEN DO:
        FIND FIRST bPrincipal NO-LOCK WHERE bPrincipal.nr-pedido = bPedido.nr-pedido
                                       AND bPrincipal.nome-ab-rep = bNota.no-ab-reppri.
        tt-NF.perc-comis = bPrincipal.perc-comis.
    END.
END PROCEDURE.

BLOCK-LEVEL ON ERROR UNDO, THROW.
{esapi/consulta-notas/BuscarNotasFiscaisParametros.i}
DEFINE BUFFER bNota FOR {&ERP}.nota-fiscal.
DEFINE BUFFER bNatureza FOR {&ERP}.natur-oper.
DEFINE BUFFER bPedido FOR {&ERP}.ped-venda.
DEFINE BUFFER bPedRep FOR {&ERP}.ped-repre.
DEFINE BUFFER bItem FOR {&ERP}.it-nota-fisc.
DEFINE VARIABLE dDesconto AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dItem AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE cTexto AS CHARACTER NO-UNDO.

FUNCTION DecimalLegado RETURNS DECIMAL (INPUT pcTexto AS CHARACTER):
    DEFINE VARIABLE c AS CHARACTER NO-UNDO.
    DEFINE VARIABLE k AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
    DEFINE VARIABLE fator AS DECIMAL DECIMALS 10 NO-UNDO INITIAL 1.
    DEFINE VARIABLE fracao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE negativo AS LOGICAL NO-UNDO.
    IF pcTexto=? THEN RETURN ?.
    c=TRIM(REPLACE(pcTexto,".","")).
    IF c="" THEN RETURN ?.
    IF SUBSTRING(c,1,1)="-" THEN DO: negativo=TRUE. c=SUBSTRING(c,2). END.
    IF SUBSTRING(c,1,1)="+" THEN c=SUBSTRING(c,2).
    IF c="" THEN RETURN ?.
    DO k=1 TO LENGTH(c):
        IF SUBSTRING(c,k,1)="," THEN DO:
            IF fracao THEN RETURN ?.
            fracao=TRUE. NEXT.
        END.
        n=INDEX("0123456789",SUBSTRING(c,k,1)) - 1.
        IF n<0 THEN RETURN ?.
        IF fracao THEN DO: fator=fator / 10. d=d + n * fator. END.
        ELSE d=d * 10 + n.
    END.
    RETURN IF negativo THEN d * -1 ELSE d.
END FUNCTION.

EMPTY TEMP-TABLE tt-NF.
IF pcEmpresa=? OR pcEmpresa<>"{&EMPRESA}" THEN
    UNDO,THROW NEW Progress.Lang.AppError("Empresa incompativel com o programa",1).
{esapi/consulta-notas/ConsultaNFFiltrosValidar.i}
IF (pcNomeRepDe<>"" AND pcNomeRepAte<>"" AND pcNomeRepDe>pcNomeRepAte)
OR (piNumeroPedidoDe<>? AND piNumeroPedidoAte<>? AND piNumeroPedidoDe>piNumeroPedidoAte) THEN
    UNDO,THROW NEW Progress.Lang.AppError("Faixa invalida",1).

DO ON ERROR UNDO,THROW:
    FOR EACH bNota NO-LOCK
        WHERE bNota.dt-cancela=? AND bNota.idi-sit-nf-eletro<>4
          AND (pcEstabelDe="" OR bNota.cod-estabel>=pcEstabelDe)
          AND (pcEstabelAte="" OR bNota.cod-estabel<=pcEstabelAte)
          AND (piClienteDe=? OR bNota.cod-emitente>=piClienteDe)
          AND (piClienteAte=? OR bNota.cod-emitente<=piClienteAte)
          AND (pcNotaDe="" OR bNota.nr-nota-fis>=pcNotaDe)
          AND (pcNotaAte="" OR bNota.nr-nota-fis<=pcNotaAte)
          AND (pcPedidoDe="" OR bNota.nr-pedcli>=pcPedidoDe)
          AND (pcPedidoAte="" OR bNota.nr-pedcli<=pcPedidoAte)
          AND (piRepresentanteDe=? OR bNota.cod-rep>=piRepresentanteDe)
          AND (piRepresentanteAte=? OR bNota.cod-rep<=piRepresentanteAte)
          AND (pdEmissaoDe=? OR bNota.dt-emis-nota>=pdEmissaoDe)
          AND (pdEmissaoAte=? OR bNota.dt-emis-nota<=pdEmissaoAte)
          AND (pcNomeRepDe="" OR bNota.no-ab-reppri>=pcNomeRepDe)
          AND (pcNomeRepAte="" OR bNota.no-ab-reppri<=pcNomeRepAte)
          AND (piTipoNota=? OR bNota.esp-docto=piTipoNota)
          &IF "{&EMPRESA}"="IMA" &THEN
          AND bNota.cod-estabel="1" AND bNota.cod-emitente<>10535
          &ELSE
          AND (bNota.cod-estabel="5" OR bNota.cod-estabel="505") AND bNota.cod-emitente<>1
          &ENDIF
          , FIRST bNatureza NO-LOCK
        WHERE bNatureza.nat-operacao=bNota.nat-operacao
          AND bNatureza.tp-rec-desp=1 AND bNatureza.tipo-compra<>3:
        pedidos:
        FOR EACH bPedido NO-LOCK WHERE bPedido.nr-pedcli=bNota.nr-pedcli
          AND bPedido.nome-abrev=bNota.nome-ab-cli
          AND (piNumeroPedidoDe=? OR bPedido.nr-pedido>=piNumeroPedidoDe)
          AND (piNumeroPedidoAte=? OR bPedido.nr-pedido<=piNumeroPedidoAte):
        IF NOT CAN-FIND(FIRST bPedRep WHERE bPedRep.nr-pedido=bPedido.nr-pedido NO-LOCK) THEN NEXT.
        IF bNota.vl-tot-nota=? THEN UNDO,THROW NEW Progress.Lang.AppError("Valor desconhecido na nota",1).
        dDesconto=0.
        FOR EACH bItem NO-LOCK WHERE bItem.cod-estabel=bNota.cod-estabel
            AND bItem.serie=bNota.serie AND bItem.nr-nota-fis=bNota.nr-nota-fis:
            cTexto=SUBSTRING(bItem.char-2,1500,10).
            dItem=DecimalLegado(cTexto).
            IF dItem<>? THEN dDesconto=dDesconto + dItem.
        END.
        CREATE tt-NF.
        ASSIGN tt-NF.cod-estabel=bNota.cod-estabel tt-NF.serie=bNota.serie tt-NF.nf=bNota.nr-nota-fis
               tt-NF.data=bNota.dt-emis-nota tt-NF.dt-emis-nota=bNota.dt-emis-nota
               tt-NF.nr-Pedido=bPedido.nr-pedido tt-NF.nome-abrev=bNota.nome-ab-cli
               tt-NF.nome-ab-reppri=bNota.no-ab-reppri tt-NF.cidade=bNota.cidade tt-NF.estado=bNota.estado
               tt-NF.vl-nota=bNota.vl-tot-nota tt-NF.vl-desconto=dDesconto
               tt-NF.vl-bruto=bNota.vl-tot-nota + dDesconto tt-NF.tipo-nota=bNota.esp-docto
               tt-NF.nf-original="" tt-NF.descr-mot-dev="".
        RUN PreencherContextoNota.
        /* Uma nota por documento, usando o primeiro pedido elegivel. */
        LEAVE pedidos.
        END.
    END.
    CATCH e AS Progress.Lang.Error:
        EMPTY TEMP-TABLE tt-NF. UNDO,THROW e.
    END CATCH.
END.
{esapi/consulta-notas/ConsultaNFContexto.i}

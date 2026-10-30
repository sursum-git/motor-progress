/**************************************************************************
Programa: esbo/boConsPedVenda2.p
Autor: Tadeu Silva 
Objetivo: Bo de consulta ampla de pedidos e tabelas relacionadas a ser 
utilizada em APIs 
Data: 06/2026
Modificacoes:
*****************************************************************************/
{esp/util.i}


DEFINE VARIABLE hAcomp AS HANDLE      NO-UNDO.

DEFINE VARIABLE codEstabIni     AS CHARACTER   NO-UNDO INIT ''.
DEFINE VARIABLE codEstabFim     AS CHARACTER   NO-UNDO INIT '999'.

DEFINE VARIABLE dtImplantIni    AS DATE        NO-UNDO INIT 01.01.0001.
DEFINE VARIABLE dtImplantFim    AS DATE        NO-UNDO INIT 01.01.2999.

DEFINE VARIABLE iClienteIni     AS INTEGER     NO-UNDO INIT 0.
DEFINE VARIABLE iClienteFim     AS INTEGER     NO-UNDO INIT 9999999.

DEFINE VARIABLE cRepresIni      AS CHARACTER   NO-UNDO INIT ''.
DEFINE VARIABLE cRepresFIm      AS CHARACTER   NO-UNDO INIT 'zzzzzzzzzzzzz' .

DEFINE VARIABLE nrPedidoIni     AS INTEGER     NO-UNDO INIT 0.
DEFINE VARIABLE nrPedidoFIm     AS INTEGER     NO-UNDO INIT 999999.

DEFINE VARIABLE cClubeIMA             AS CHARACTER   NO-UNDO INIT 'YES,NO'.
DEFINE VARIABLE cBloqueioAprov        AS CHAR        NO-UNDO INIT 'YES,NO'.
DEFINE VARIABLE cSitPed               AS CHAR        NO-UNDO INIT '1,2,3,4,5,6'.
DEFINE VARIABLE cSitAval              AS CHAR        NO-UNDO INIT '1,2,3,4,5,6'.
DEFINE VARIABLE cSitPreco             AS CHAR        NO-UNDO INIT '1,2,3,4,5,6'.

DEFINE VARIABLE vlBruto               AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlDesconto            AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlLiquido             AS DECIMAL     NO-UNDO.


DEFINE TEMP-TABLE tt-containers NO-UNDO
        FIELD nr-container AS INT
        INDEX primario IS PRIMARY nr-container.
        
DEFINE TEMP-TABLE tt-matriz-busca NO-UNDO
    FIELD estab         AS LOGICAL
    FIELD dtImplant     AS LOGICAL
    FIELD cliente       AS LOGICAL
    FIELD repres        AS LOGICAL
    FIELD containers    AS LOGICAL
    FIELD clubeIma      AS LOGICAL
    //FIELD bloqueioAprov AS LOGICAL
    FIELD sitPed        AS LOGICAL
    FIELD sitAVal       AS LOGICAL
    FIELD sitPreco      AS LOGICAL
    .
    
{esbo/boConsPedVenda2.i}
FUNCTION getComisRepres RETURNS DECIMAL(nrPedido AS INT):

      //TODO

END FUNCTION.

FUNCTION getDtEmisNota RETURNS DATE(rowidPedido AS ROWID):
    
   DEFINE VARIABLE rowidNF AS ROWID       NO-UNDO.
   DEFINE VARIABLE cErros  AS CHARACTER   NO-UNDO.

    
   RUN esapi/getNFVendaPedido.p(rowidPedido,OUTPUT rowidNF, OUTPUT cErros).
   FOR FIRST nota-fiscal FIELDS(dt-emis-nota)
    WHERE ROWID(nota-fiscal) = rowidNF NO-LOCK:
    RETURN nota-fiscal.dt-emis-nota.
   END.
   RETURN ? .
   

END FUNCTION.


FUNCTION getPreChegContainer RETURNS CHAR(nrContainer AS INT):

    DEFINE VARIABLE dt AS DATE        NO-UNDO.
   
   FOR FIRST pp-container FIELDS( nr-container dt-prev-chegada ) NO-LOCK
       WHERE pp-container.nr-container = nrContainer :  
       ASSIGN dt = pp-container.dt-prev-cheg .
       
   END.
   IF dt = ? THEN
     RETURN "".

   RETURN
       (IF DAY(dt) <= 15 THEN "1ï¿½ quinzena" ELSE "2ï¿½ quinzena")
        + "/"
        + STRING(YEAR(dt)).

END FUNCTION.
PROCEDURE iniciarBo:
    RUN esbo/boAcomp.p PERSIST SET hAcomp.
END PROCEDURE.

PROCEDURE finalizarBo:
IF VALID-HANDLE(hAcomp) THEN
   RUN finalizar IN hAcomp.
DELETE PROCEDURE THIS-PROCEDURE.    
END PROCEDURE.  


PROCEDURE setTTContainer:

    DEFINE INPUT PARAMETER TABLE FOR tt-containers.

END PROCEDURE.

PROCEDURE setIntervalNrPedido:

    DEFINE INPUT  PARAMETER pNrPedidoIni AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pNrPedidoFim AS INTEGER     NO-UNDO.
    
    ASSIGN nrPedidoIni  = pNrPedidoIni
           nrPedidoFim  = pNrPedidoFim
           .
    


END PROCEDURE.

PROCEDURE setIntervalEstab:

   DEFINE INPUT  PARAMETER pEstabIni AS CHARACTER   NO-UNDO.
   DEFINE INPUT  PARAMETER pEstabFim AS CHARACTER   NO-UNDO.
   RUN _sincrMatriz.
   ASSIGN codEstabIni = pEstabIni
          codEstabFim = pEstabFim
          tt-matriz-busca.estab = YES          
          .
   
   
END.

PROCEDURE setIntervalDtImplant:

    DEFINE INPUT  PARAMETER dtIni   AS DATE        NO-UNDO.
    DEFINE INPUT  PARAMETER dtFim   AS DATE        NO-UNDO.
    RUN _sincrMatriz.
    ASSIGN dtImplantIni = dtIni
           dtImplantFim = dtFim
           tt-matriz-busca.dtImplant = YES.
           .
END.

PROCEDURE setIntervalCliente:

    DEFINE INPUT  PARAMETER pClienteIni AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pClienteFim AS INTEGER     NO-UNDO.
    RUN _sincrMatriz.
    ASSIGN iClienteIni                    =   pClienteIni
           iClienteFim                    =   pClienteFim
           tt-matriz-busca.cliente        =   YES 
           .

END PROCEDURE.

PROCEDURE setIntervalRepres:
    RUN _sincrMatriz.
    DEFINE INPUT  PARAMETER pRepresIni AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pRepresFim AS CHARACTER   NO-UNDO.
    
    ASSIGN cRepresIni           = pRepresIni
           cRepresFim           = pRepresFim
           tt-matriz-busca.repres = YES
           .    

END PROCEDURE.

PROCEDURE setSomenteClubeIma:

    DEFINE INPUT  PARAMETER pl AS LOGICAL     NO-UNDO.
        
    IF pl  THEN DO:
       ASSIGN cClubeIma = 'YES' .       
    END.
    ELSE DO:
       ASSIGN cClubeIma = 'YES,NO'. 
    END.
    RUN _sincrMatriz.
    ASSIGN tt-matriz-busca.clubeIma = pl.


END PROCEDURE.

PROCEDURE setSitPed:

    DEFINE INPUT  PARAMETER pc AS CHARACTER   NO-UNDO.
    
    RUN _sincrMatriz.
    ASSIGN  cSitPed                   = pC
            tt-matriz-busca.sitPed    = pC <> ''
            .

END PROCEDURE.

PROCEDURE setSitAval:
    
    DEFINE INPUT  PARAMETER pc AS CHARACTER   NO-UNDO.
    
    RUN _sincrMatriz.
    ASSIGN  cSitAval                  = pC
            tt-matriz-busca.sitAval   = pC <> ''
            .

END PROCEDURE.


PROCEDURE setSitPreco:
    
    DEFINE INPUT  PARAMETER pc AS CHARACTER   NO-UNDO.
    
    RUN _sincrMatriz.
    ASSIGN  cSitPreco                 = pC
            tt-matriz-busca.sitPreco  = pC <> ''
            .

END PROCEDURE.



PROCEDURE setBloqueioAprov:

    DEFINE INPUT  PARAMETER pc AS CHARACTER   NO-UNDO.
    
    //RUN _sincrMatriz.
    ASSIGN  cBloqueioAprov                  = pC
            //tt-matriz-busca.bloqueioAprov     = pC <> ''
            .  

END PROCEDURE.





PROCEDURE exec: 

    RUN _sincrMatriz.
    IF can-find( FIRST tt-Containers) THEN DO:
       RUN _fonteContainer. 
    
    END.
    ELSE DO:
        IF  tt-matriz-busca.clubeIma      = YES THEN DO:
            RUN _fonteExt.        
        END.
        ELSE DO:
            RUN _fonteVenda.
        END.
    END.       
   

END PROCEDURE.


PROCEDURE _fonteExt:

    FOR EACH ped-venda-ext NO-LOCK
        WHERE lookup(string(ped-venda-ext.log_clube_ima),cClubeIma)  > 0,
        EACH ped-venda NO-LOCK
        WHERE ped-venda.nr-pedido       = ped-venda-ext.nr-pedido
        AND   ped-venda.cod-estabel     = ped-venda-ext.cod-estabel 
        AND   ped-venda.cod-estabel     >= codEstabIni
        AND   ped-venda.cod-estabel     <= codEstabFim
        AND   ped-venda.cod-emitente    >= iClienteIni
        AND   ped-venda.cod-emitente    <= iClienteFim
        AND   ped-venda.dt-implant      >= dtImplantIni
        AND   ped-venda.dt-implant      <= dtImplantFim
        AND   ped-venda.no-ab-reppri    >= cRepresIni
        AND   ped-venda.no-ab-reppri    <= cRepresFim
        AND   ped-venda.nr-pedido       >= nrPedidoIni
        AND   ped-venda.nr-pedido       <= nrPedidoFim
        :
        IF LOOKUP(string(ped-venda-ext.l-nao-aprovar)   ,cBloqueioAprov)   = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-ped)         ,cSitPed)          = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-aval)        ,cSitAval)         = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-preco)       ,cSitPreco)        = 0 THEN NEXT.
        RUN _comum.
        
    END.


END PROCEDURE.



PROCEDURE _fonteVenda:
    
     MESSAGE    
           'estab.:'codEstabIni '-'  codEstabFim            SKIP
           'cliente:' iClienteIni '-' iClienteFim           SKIP
           'dt.implant:' dtImplantIni '-' dtImplantFim      SKIP
           'repres:' cRepresIni '-' cRepresFim              SKIP
           'pedido:' nrPedidoIni '-' nrPedidoFim            SKIP
           'bloqueio:' cBloqueioAprov                       SKIP
           'sitped:' cSitPed                                SKIP
           'sitaval:' cSitAval                              SKIP
           'sitpreco:' cSitPreco                            SKIP
           'clube ima:' cClubeIMA
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
     FOR EACH ped-venda NO-LOCK        
        WHERE ped-venda.cod-estabel     >= codEstabIni
        AND   ped-venda.cod-estabel     <= codEstabFim
        AND   ped-venda.cod-emitente    >= iClienteIni
        AND   ped-venda.cod-emitente    <= iClienteFim
        AND   ped-venda.dt-implant      >= dtImplantIni
        AND   ped-venda.dt-implant      <= dtImplantFim
        AND   ped-venda.no-ab-reppri    >= cRepresIni
        AND   ped-venda.no-ab-reppri    <= cRepresFim
        AND   ped-venda.nr-pedido       >= nrPedidoIni
        AND   ped-venda.nr-pedido       <= nrPedidoFim,
        EACH  ped-venda-ext NO-LOCK
        WHERE ped-venda.nr-pedido       = ped-venda-ext.nr-pedido
        AND   ped-venda.cod-estabel     = ped-venda-ext.cod-estabel 
        AND   LOOKUP( STRING(ped-venda-ext.log_clube_ima),cCLubeIma)  > 0        
        :
        IF LOOKUP(string(ped-venda-ext.l-nao-aprovar)   ,cBloqueioAprov)   = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-ped)         ,cSitPed)          = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-aval)        ,cSitAval)         = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-preco)       ,cSitPreco)        = 0 THEN NEXT.
        RUN _comum.
         /*MESSAGE 'oi'
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    END.


END PROCEDURE.

PROCEDURE _fonteContainer:

    FOR EACH tt-containers,
        EACH ped-venda-ext NO-LOCK  
        WHERE ped-venda-ext.nr-container = tt-containers.nr-container
        AND   LOOKUP( STRING(ped-venda-ext.log_clube_ima),cCLubeIma)  > 0
        ,
        EACH ped-venda NO-LOCK
        WHERE ped-venda.nr-pedido        = ped-venda-ext.nr-pedido
        AND   ped-venda.cod-estabel      = ped-venda-ext.cod-estabel
        AND   ped-venda.cod-estabel     >= codEstabIni
        AND   ped-venda.cod-estabel     <= codEstabFim
        AND   ped-venda.cod-emitente    >= iClienteIni
        AND   ped-venda.cod-emitente    <= iClienteFim
        AND   ped-venda.dt-implant      >= dtImplantIni
        AND   ped-venda.dt-implant      <= dtImplantFim
        AND   ped-venda.no-ab-reppri    >= cRepresIni
        AND   ped-venda.no-ab-reppri    <= cRepresFim
        AND   ped-venda.nr-pedido       >= nrPedidoIni
        AND   ped-venda.nr-pedido       <= nrPedidoFim
        :
        IF LOOKUP(string(ped-venda-ext.l-nao-aprovar)   ,cBloqueioAprov)   = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-ped)         ,cSitPed)          = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-aval)        ,cSitAval)         = 0 THEN NEXT.
        IF LOOKUP(STRING(ped-venda.cod-sit-preco)       ,cSitPreco)        = 0 THEN NEXT.
       
        RUN _comum.
    
    END.

END PROCEDURE.



PROCEDURE _comum:
     RUN _calcValoresPedido.
     CREATE tt-dados.
     ASSIGN 
     tt-dados.cod-estabel          =  ped-venda.cod-estabel
     tt-dados.dt-implant           =  ped-venda.dt-implant
     tt-dados.nr-pedido            =  ped-venda.nr-pedido
     tt-dados.cod-emitente         =  ped-venda.cod-emitente
     tt-dados.nome-abrev           =  ped-venda.nome-abrev
     tt-dados.nome-repres          =  ped-venda.no-ab-reppri
     tt-dados.perc-comis           =  getComisRepres(ped-venda.nr-pedido)
     tt-dados.dt-emis-nota         =  getDtEmisNota(rowid(ped-venda))
     tt-dados.cod-sit-ped          =  ped-venda.cod-sit-ped
     tt-dados.desc-sit-ped         =  {diinc/i03di149.i 4 ped-venda.cod-sit-ped}
     tt-dados.cod-sit-aval         =  ped-venda.cod-sit-aval
     tt-dados.desc-sit-aval        =  {diinc/i03di159.i 4 ped-venda.cod-sit-aval}
     tt-dados.num-origem           =  ped-venda-ext.origem //1-Telefone 2- Fax 3-E-mail 4-Papel 5-Site
     tt-dados.nr-container         =  ped-venda-ext.nr-container
     tt-dados.nr-pedcli           =  ped-venda.nr-pedcli
     tt-dados.no-ab-reppri        =  ped-venda.no-ab-reppri
     tt-dados.cod-sit-preco       =  ped-venda.cod-sit-preco
     tt-dados.cod-priori          =  ped-venda.cod-priori
     tt-dados.mo-codigo           =  ped-venda.mo-codigo
     tt-dados.completo            =  ped-venda.completo
     tt-dados.preposto            =  ped-venda-ext.preposto
     tt-dados.l-nao-aprovar       =  ped-venda-ext.l-nao-aprovar
     tt-dados.origem              =  ped-venda-ext.origem
     tt-dados.vl-liq-ped          =  ped-venda.vl-liq-ped
     tt-dados.val-desconto-total  =  ped-venda.val-desconto-total
     tt-dados.vl-bruto            =  vlBruto
     tt-dados.vl-desconto         =  vlDesconto
     tt-dados.vl-liquido          =  vlLiquido
     tt-dados.tp-pedido           =  ped-venda.tp-pedido
     tt-dados.c-prev-container    =  getPreChegContainer(ped-venda-ext.nr-container)
     .

END PROCEDURE.

PROCEDURE _sincrMatriz:

    IF NOT CAN-FIND( FIRST tt-matriz-busca ) THEN     DO:
        CREATE tt-matriz-busca.    
    END.
    
    FOR FIRST tt-matriz-busca:
    END.

END PROCEDURE.

PROCEDURE _calcValoresPedido.

    DEFINE VARIABLE dFatorDesc AS DECIMAL NO-UNDO.

    ASSIGN vlBruto    = 0
           vlDesconto = 0
           vlLiquido  = 0
           dFatorDesc = ((20 - ped-venda.cod-priori) MODULO 10) / 10
           .

    IF ped-venda.cod-sit-ped = 1 AND ped-venda.completo THEN DO:
        ASSIGN vlLiquido  = ped-venda.vl-liq-abe
               vlDesconto = ped-venda.val-desconto-total
               vlBruto    = vlLiquido + vlDesconto
               .
        RETURN.
    END.

    IF ped-venda.cod-sit-ped = 6 THEN DO:
        ASSIGN vlLiquido  = ped-venda.vl-liq-ped
               vlDesconto = ped-venda.val-desconto-total
               vlBruto    = vlLiquido + vlDesconto
               .
        RETURN.
    END.

    IF ped-venda.cod-sit-ped = 3 THEN DO:
        FOR EACH ped-item FIELDS(vl-preori qt-pedida cod-sit-item) NO-LOCK
            WHERE ped-item.nr-pedcli     = ped-venda.nr-pedcli
            AND   ped-item.nome-abrev    = ped-venda.nome-abrev
            AND   ped-item.cod-sit-item <> 6:
            ASSIGN vlBruto    = vlBruto + (ped-item.vl-preori * ped-item.qt-pedida)
                   vlDesconto = vlDesconto + (ped-item.vl-preori * ped-item.qt-pedida * dFatorDesc)
                   .
        END.
    END.
    ELSE DO:
        FOR EACH ped-item FIELDS(vl-preuni qt-pedida cod-sit-item) NO-LOCK
            WHERE ped-item.nr-pedcli     = ped-venda.nr-pedcli
            AND   ped-item.nome-abrev    = ped-venda.nome-abrev
            AND   ped-item.cod-sit-item <> 6:
            ASSIGN vlBruto    = vlBruto + (ped-item.vl-preuni * ped-item.qt-pedida)
                   vlDesconto = vlDesconto + (ped-item.vl-preuni * ped-item.qt-pedida * dFatorDesc)
                   .
        END.
    END.

    vlLiquido = vlBruto - vlDesconto.

END PROCEDURE.

PROCEDURE limparContexto:

    EMPTY TEMP-TABLE tt-dados.
    EMPTY TEMP-TABLE tt-matriz-busca.
    EMPTY TEMP-TABLE tt-containers .

END PROCEDURE.

PROCEDURE getTTDados:

    DEFINE OUTPUT PARAMETER TABLE FOR tt-dados.

END PROCEDURE.

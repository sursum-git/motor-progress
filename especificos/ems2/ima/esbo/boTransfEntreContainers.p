/******************************************************************************************************************
Programa:boTransfEntreContainers.p
Objetivo:fazer os ajustes necessarios pra transferencias de saldos 
e de pedidos de venda entre containers independente
da origem(pedido de importaá∆o,container)
Data:07/2026
Autor:Tadeu silva

logica de validaá‰es antes de fazer qualquer coisa:
0- id da transferencia invalido para as opá‰es escolhidas ou inexistente
1- verificar se o item e a referencia substituida existem , sen∆o retorna erro.
2- verificar se existe regra fiscal no caso de troca de estabelecimento. se n∆o existir avisar
e verificar se ser† necessario apenas deixar esse pedido sem integrar e com o saldo no container
origem.
3- retornar erros que a alteraá∆o do pedido lanáar.(este caso n∆o tem jeito de ser antes)

******************************************************************************************************************/
DEFINE VARIABLE nrContainerOrig     AS INTEGER     NO-UNDO.
DEFINE VARIABLE nrContainerDest     AS INTEGER     NO-UNDO.
DEFINE VARIABLE hBoControlePreco    AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoMsg              AS HANDLE      NO-UNDO.
DEFINE VARIABLE iTransacaoLog       AS INTEGER     NO-UNDO.
DEFINE TEMP-TABLE transfPreco NO-UNDO  LIKE controle_preco.
DEFINE BUFFER bfTransf FOR transf_container.
DEFINE TEMP-TABLE ttItemTransfContainer NO-UNDO LIKE item_transf_container.
DEFINE TEMP-TABLE ttContainer           NO-UNDO LIKE pp-container.
DEFINE TEMP-TABLE ttPedNat              NO-UNDO
    FIELD codEstabel        AS CHAR
    FIELD nrPedido          AS INT
    FIELD nomeAbrev         AS CHAR
    FIELD idParamNat        AS INT
    FIELD natOperacao       AS CHAR
    FIELD logErroFinalid    AS LOGICAL
    FIELD logNatNaoEncontr  AS LOGICAL
    FIELD logMudouEstab     AS LOGICAL
    FIELD ultSeq            AS INT
    INDEX primario IS PRIMARY codEstabel nrPedido
    .
DEFINE TEMP-TABLE tt-ped-venda NO-UNDO LIKE ped-venda
    FIELD r-rowid AS ROWID.
    
DEFINE TEMP-TABLE tt-ped-item  NO-UNDO LIKE ped-item
    FIELD r-rowid AS ROWID .    
    
DEFINE TEMP-TABLE ttPedItem NO-UNDO LIKE ped-item
    FIELD logMudouProdRef   AS LOGICAL.    
                                                        
{method/dbotterr.i}    
/*DEFINE TEMP-TABLE RowErrors NO-UNDO
       FIELD ErrorSequence    AS INTEGER
       FIELD ErrorNumber      AS INTEGER
       FIELD ErrorDescription AS CHARACTER
       FIELD ErrorParameters  AS CHARACTER
       FIELD ErrorType        AS CHARACTER
       FIELD ErrorHelp        AS CHARACTER
       FIELD ErrorSubType     AS CHARACTER. */   
    
PROCEDURE iniciarBos:

    RUN esbo/boControlePreco.p PERSIST SET hBoControlePreco.
    RUN inicarBos IN hBoControlePreco.     
    RUN esbo/boMsg.p PERSIST SET hBoMsg.    

END PROCEDURE.


PROCEDURE finalizarBos:

    IF VALID-HANDLE(hBoControlePreco) THEN   DO:
       RUN finalizarBos IN hBoControlepreco. 
       DELETE OBJECT hBoControlePreco.        
    END.
    
    IF VALID-HANDLE(hBoMsg) THEN  DO:
       DELETE OBJECT hBoMsg.        
    END.

END PROCEDURE.

PROCEDURE setIdTransfContainer:
    DEFINE INPUT  PARAMETER pId AS INT64   NO-UNDO.    
    FOR FIRST bfTransf NO-LOCK
        WHERE bfTransf.id = pId:
        ASSIGN nrContainerOrig = bfTransf.nr_container_orig
               nrContainerDest = bfTransf.nr_container_dest
              .
    END.
    
    IF NOT AVAIL bfTransf THEN DO:
       RUN setMsg IN hBoMsg(1,'ID da transf. de container n∆o encontrado:' + STRING(pId),'erro'). 
       RETURN.
    END.
        
    EMPTY TEMP-TABLE ttItemTransfContainer.    
    FOR EACH item_transf_container NO-LOCK
        WHERE item_transf_container.transf_container_id = bfTransf.id:
        CREATE ttItemTransfContainer.
        BUFFER-COPY item_transf_container TO ttItemTransfContainer.
    END.
    RUN verifItemRefSubst.
    
END PROCEDURE.

PROCEDURE setTransacaoLog:
    DEFINE INPUT PARAMETER piTransacao AS INTEGER NO-UNDO.
    ASSIGN iTransacaoLog = piTransacao.
END PROCEDURE.


PROCEDURE setNrContainerOrigem:

DEFINE INPUT  PARAMETER pContainer AS INTEGER     NO-UNDO.
ASSIGN nrContainerOrig = pContainer.

END PROCEDURE.

PROCEDURE setNrContainerDestino:

DEFINE INPUT  PARAMETER pContainer AS INTEGER     NO-UNDO.
ASSIGN nrContainerDest = pContainer.

END PROCEDURE.




PROCEDURE vencerPrecosPorContainer:  
    DEFINE INPUT  PARAMETER pDtRefer AS DATE        NO-UNDO.
    DEFINE BUFFER bf FOR controle_preco.
    FOR EACH  bf
        WHERE bf.nr_container = nrContainerOrig        
        AND   bf.log_vencido  = NO
        AND   bf.dt_inicial  <= pDtRefer
        AND   bf.dt_final    >= pDtRefer  NO-LOCK .
        RUN setTbPreco              IN hBoControlePreco(bf.tb_preco_id).
        RUN setNrContainer          IN hBoControlePreco(bf.nr_container).
        RUN setNivel                IN hBoControlePreco(bf.num_nivel).
        RUN setTpPreco              IN hBoControlePreco(bf.tp_Preco).
        RUN setItem                 IN hBoControlePreco(bf.it_codigo).
        RUN setCodRefer             IN hBoControlePreco(bf.cod_refer).        
        RUN vencerPreco             IN hBoControlePreco(pDtRefer).
        
       
    END.
END PROCEDURE.

PROCEDURE transfPrecosEntreContainers:     
      DEFINE INPUT  PARAMETER pLogVencerAnteriores   AS LOGICAL     NO-UNDO.
      DEFINE INPUT  PARAMETER pDtRefer               AS DATE        NO-UNDO.
      DEFINE BUFFER bf FOR controle_preco.
      DEFINE VARIABLE vlReal     AS DECIMAL     NO-UNDO.
      DEFINE VARIABLE vlDolar    AS DECIMAL     NO-UNDO.
      DEFINE VARIABLE cErroPreco AS CHARACTER   NO-UNDO.
      IF pDtRefer = ? THEN DO:
          ASSIGN pDtRefer = TODAY.          
      END.
/*       MESSAGE 'origem:'  nrContainerOrig SKIP       */
/*               'destino:' nrContainerDest SKIP       */
/*           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK. */
          
      FOR EACH bf NO-LOCK
        WHERE bf.nr_container   = nrContainerOrig
        AND   bf.log_vencido    = NO
        AND   bf.dt_inicial     <= pDtRefer
        AND   bf.dt_final       >= pDtRefer
        AND   bf.vl_real        > 0
        AND   bf.vl_dolar       > 0
        :       
        CREATE transfPreco.
        BUFFER-COPY bf TO transfPreco. 
        ASSIGN transfPreco.nr_container = nrContainerDest.
        
              
        //substituir produtos, refs e preáos
        FOR FIRST ttItemTransfContainer
            WHERE ttItemTransfContainer.it_codigo_orig  = bf.it_codigo 
            AND   ttItemTransfContainer.cod_Refer_orig  = bf.cod_refer:            
            IF ttItemTransfContainer.it_codigo_dest <> '' THEN   DO:
               ASSIGN transfPreco.it_codigo = ttItemTransfContainer.it_codigo_dest.                
            END.            
            IF ttItemTransfContainer.cod_refer_dest <> '' THEN DO:
               ASSIGN transfPreco.cod_Refer = ttItemTransfContainer.cod_refer_dest.                
            END.
            IF ttItemTransfContainer.vl_novo_preco_90 > 0 THEN  DO:
               //transformar 90 dias em preáo base
               IF ttItemTransfContainer.num_moeda = 0 THEN DO:  //real
                  RUN esapi/getPrecoBasePreco90.p(transfPreco.vl_real, OUTPUT vlReal, OUTPUT cErroPreco).                       
                  ASSIGN transfPreco.vl_dolar = 0.
               END.
               ELSE DO:    //dolar
                 RUN esapi/getPrecoBasePreco90.p(transfPreco.vl_dolar, OUTPUT vlDolar, OUTPUT cErroPreco).        
                 ASSIGN transfPreco.vl_real = 0.
               END.                
            END.
        END.        
      END.      
      
      FOR EACH transfPreco:        
                
         RUN setTbPreco              IN hBoControlePreco(transfPreco.tb_preco_id).
         RUN setNrContainer          IN hBoControlePreco(transfPreco.nr_container).
         RUN setNivel                IN hBoControlePreco(transfPreco.num_nivel).
         RUN setTpPreco              IN hBoControlePreco(transfPreco.tp_Preco).
         RUN setItem                 IN hBoControlePreco(transfPreco.it_codigo).
         RUN setCodRefer             IN hBoControlePreco(transfPreco.cod_refer).               
         RUN setVencido              IN hBoControlePreco(NO).
         RUN setDtInicio             IN hBoControlePreco(pDtRefer).
         RUN setDtFinal              IN hBoControlePreco(12.31.2999).        
         RUN inserirPreco            IN hBoControlePreco(transfPreco.vl_real , transfPreco.vl_dolar ).         
      END.
      
      IF pLogVencerAnteriores THEN DO:
         RUN vencerPrecosPorContainer(pDtRefer).    
      END.
      
      
      

END PROCEDURE.

PROCEDURE exportarTransfPreco:

    DEFINE OUTPUT PARAMETER TABLE FOR transfPreco.



END PROCEDURE.


PROCEDURE verifItemRefSubst:

    DEFINE VARIABLE lErro AS LOGICAL     NO-UNDO.
    FOR EACH ttItemTransfContainer:
        ASSIGN lErro = NO.
        IF NOT CAN-FIND(ITEM  
                    WHERE ITEM.it-codigo = ttItemTransfContainer.it_codigo_dest) THEN  DO:
           RUN setMsg IN hBoMsg(2,'Item N∆o cadastrado no sistema:' + ttItemTransfContainer.it_codigo_dest,'erro').            
           ASSIGN lErro = YES.
        END.
        IF NOT CAN-FIND(referencia  
                    WHERE referencia.cod-refer = ttItemTransfContainer.cod_refer_dest) THEN  DO:
           RUN setMsg IN hBoMsg(3,'Referància N∆o cadastrado no sistema:' + ttItemTransfContainer.cod_refer_dest,'erro').            
           ASSIGN lErro = YES.
        END.
        IF lErro = NO THEN   DO:
           // cria a relaá∆o entre item x referencia
           FOR FIRST ref-item FIELDS(it-codigo cod-refer) NO-LOCK
               WHERE ref-item.it-codigo = ttItemTransfContainer.it_codigo_dest
               AND ref-item.cod-refer   = ttItemTransfContainer.cod_refer_dest :               
           END.
           IF NOT AVAIL ref-item THEN  DO:
              CREATE ref-item.
              ASSIGN ref-item.it-codigo = ttItemTransfContainer.it_codigo_dest
                     ref-item.cod-refer = ttItemTransfContainer.cod_refer_dest
                     .                
           END.
        END.
    END.

END PROCEDURE.

PROCEDURE verifRegraFiscal:

    DEFINE VARIABLE iFinNat         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cCNAE           AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cErroNat        AS CHARACTER   NO-UNDO. 
    DEFINE VARIABLE cNatOperacao    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iParamNat       AS INTEGER     NO-UNDO.
    DEFINE VARIABLE hBoNat001       AS HANDLE      NO-UNDO.
    
       FOR EACH ped-venda NO-LOCK,
           EACH ped-venda-ext NO-LOCK
           WHERE ped-venda-ext.cod-estabel  = ped-venda.cod-estabel
           AND   ped-venda-ext.nr-pedido    = ped-venda.nr-pedido  
           AND   ped-venda-ext.nr-container = nrContainerOrig
           :           
           CREATE ttPedNat.
           ASSIGN ttPedNat.codEstabel       = ped-venda.cod-estabel
                  ttPedNat.nrPedido         = ped-venda.nr-pedido
                  ttPedNat.nomeAbrev        = ped-venda.nome-abrev
                  ttPedNat.logmudouEStab    =  bfTransf.cod_estab_novo <> ''
                  .
           //grava a ultima sequencia       
           FOR LAST ped-item fields(nome-abrev nr-pedcli nr-sequencia)OF ped-venda NO-LOCK
            USE-INDEX ch-item-ped:
               ASSIGN ttPedNat.ultSeq = ped-item.nr-sequencia. 
           END.
           
           IF bfTransf.cod_estab_novo = '' THEN DO:
              //se n∆o teve troca de estab. n∆o precisa recalcular a natureza de operaá∆o
              NEXT. 
           END.
           RUN limparErros IN hBoNat001.
           RUN retornarfinalidadecliente IN hBoNat001 (INPUT ped-venda.cod-emitente,
                                                     OUTPUT iFinNat, 
                                                     OUTPUT cCnae).
           RUN retornarerros IN hBoNat001 (OUTPUT cErroNat).
           IF cErroNat <> '' THEN DO:
              RUN setMsg IN hBoMsg(4,'Erro ao Buscar Finalidade do Cliente:' + STRING(ped-venda.cod-emitente) + "-pedido:" + STRING(ped-venda.nr-pedido),'erro').               
              ASSIGN ttPedNat.logErroFinalid = YES.
              LEAVE.
           END.
           RUN limparErros IN hBoNat001.
           RUN limparErros IN hBonat001.
           RUN buscarnatoperacao IN hBoNat001 ( INPUT iFinNat, 
                                                INPUT bfTransf.cod_estab_novo,
                                                INPUT ped-venda.cod-emitente,
                                                INPUT ped-venda.nome-abrev-tri,  
                                                OUTPUT cNatOperacao,
                                                OUTPUT iParamNat).
            RUN retornarerros IN hBoNat001 (OUTPUT cErroNat).
            IF cErroNat <> '' THEN DO:
              RUN setMsg IN hBoMsg(5,'Erro ao Buscar Regra de natureza de Operaá∆o-pedido ' + STRING(ped-venda.nr-pedido) + ':' + cErroNat,'erro'). 
              ASSIGN ttPedNat.logNatNaoEncontr = YES.
           END.
           ELSE DO:
             ASSIGN ttPedNat.idParamNat     = iParamNat
                    ttPedNat.natOperacao    = cNatOperacao
                    .           
           END.
       END.        
    
END PROCEDURE.



PROCEDURE exec:
       
    DEFINE VARIABLE logErro AS LOGICAL     NO-UNDO.       
    RUN verifItemRefSubst.
    RUN verifRegraFiscal.
    RUN getErro IN hBoMsg(OUTPUT logErro).
    IF logErro THEN RETURN .
    //s¢ sincroniza(cria ou altera) o container se n∆o tiver erros anteriores
    RUN sincrContainer.     
    RUN transfPeds.
    RUN recalcSaldoContainer.
    RUN transfPrecosEntreContainers(bfTransf.log_vencer_preco_anteriores,TODAY).
    RUN sincrSubstProdRef .
    RUN alterarNatoperacao .
    RUN alterarItensPedidoERP.

END PROCEDURE.



PROCEDURE sincrContainer:

    DEFINE BUFFER bf FOR pp-container.
    FOR FIRST pp-container NO-LOCK
        WHERE pp-container.nr-container = nrContainerDest:
    END.
    IF NOT AVAIL pp-container THEN  DO:
       FOR FIRST bf NO-LOCK
           WHERE bf.nr-container = nrContainerOrig:
           EMPTY TEMP-TABLE ttContainer.
           CREATE ttContainer.
           BUFFER-COPY bf TO ttContainer.
           ASSIGN ttContainer.nr-container = nrContainerDest.
           IF bfTransf.cod_estab_novo <> '' THEN  DO:
              ASSIGN ttContainer.cod-estabel            = bfTransf.cod_estab_novo
                     ttContainer.num_origem             = 2 //pedido importaá∆o
                     ttContainer.log_rota_indefinida    = NO
                     . 
           END.
           CREATE pp-container.
           BUFFER-COPY ttContainer TO pp-container.
       END.
       
        
    END.

END PROCEDURE.

PROCEDURE transfPeds:

    FOR EACH ped-venda-ext EXCLUSIVE-LOCK
        WHERE ped-venda-ext.nr-container = nrContainerOrig :
        ASSIGN ped-venda-ext.nr-container = nrContainerDest.
        IF bfTransf.cod_estab_novo <> '' THEN   DO:
           ASSIGN ped-venda-ext.cod-estabel = cod_estab_novo.            
        END.
    END.   
    
    
END PROCEDURE.

PROCEDURE recalcSaldoContainer:

    RUN _recalcSaldoContainer(nrContainerOrig).
    RUN _recalcSaldoContainer(nrContainerDest).   


END PROCEDURE.

PROCEDURE _recalcSaldoContainer:

    DEFINE INPUT  PARAMETER pContainer AS INTEGER     NO-UNDO.
    DEF VAR de-qt-vend AS DEC.
    
    FOR EACH pp-container WHERE
         pp-container.nr-container = pContainer NO-LOCK.

        FOR EACH pp-it-container OF pp-container.
            ASSIGN de-qt-vend = 0.
            RUN _pi-ver-ped(INPUT pp-container.nr-container,
                            INPUT pp-it-container.it-codigo,
                            INPUT pp-it-container.cod-refer, 
                            OUTPUT de-qt-vend).
            IF de-qt-vend = pp-it-container.qt-vendida  THEN NEXT.
            FIND CURRENT pp-container EXCLUSIVE-LOCK.
            ASSIGN pp-it-container.qt-vendida = de-qt-vend.
            FIND CURRENT pp-container NO-LOCK.            
        END.
    END.

END PROCEDURE.


PROCEDURE _pi-ver-ped.
    DEFINE INPUT  PARAMETER pNrContainer AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pProd        AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pRef         AS CHARACTER   NO-UNDO.    
    DEFINE OUTPUT PARAMETER pQt AS DECIMAL     NO-UNDO.
    FOR EACH ped-item fields(it-codigo cod-refer cod-sit-item qt-pedida) NO-LOCK 
        WHERE ped-item.it-codigo = pProd
        AND   ped-item.cod-refer = pRef
        AND   ped-item.cod-sit-item <> 6 ,
        ped-venda FIELDS(cod-estabel nr-pedido cod-sit-ped) OF ped-item NO-LOCK
        WHERE ped-venda.cod-sit-ped <> 6,
        EACH ped-venda-ext FIELDS(cod-estabel nr-pedido nr-container) NO-LOCK 
            WHERE ped-venda-ext.cod-estabel     = ped-venda.cod-estabel 
            AND   ped-venda-ext.nr-pedido       = ped-venda.nr-pedido 
            AND   ped-venda-ext.nr-container    = pNrContainer.
        ASSIGN pQt = pQt + ped-item.qt-pedida.
    END.
END PROCEDURE.

PROCEDURE sincrSubstProdRef:
    //TODO   fazer as alteraá‰es de produto e referencia e se nao tiver criar a tabela ttPedItem com os valores originais
    //logMudouProdRef
    DEFINE BUFFER bfPedItem FOR ped-item.
    FOR EACH ttPedNat,
    EACH bfPedItem NO-LOCK
    WHERE bfPedItem.nome-abrev = ttPedNat.nomeAbrev 
    AND   bfPedItem.nr-pedcli  = STRING(ttPedNat.nrPedido)
    :
        IF  ttPednat.logMudouEstab THEN  DO:
            CREATE ttPedItem.
            BUFFER-COPY bfPedItem TO ttPedItem.    
        END.        
        
        FOR FIRST ttItemTransfContainer
            WHERE ttItemTransfContainer.it_codigo_orig = bfPedItem.it-codigo
            AND   ttItemTransfContainer.cod_refer_orig = bfPedITem.cod-refer
            :                    
        END.    
        IF AVAIL ttItemTransfContainer THEN  DO:           
            
           IF ttItemTransfContainer.it_codigo_dest <> '' THEN
           DO:  
                IF NOT AVAIL ttPedNat THEN DO:
                   CREATE ttPedItem.
                   BUFFER-COPY bfPedItem TO ttPedItem.    
                END.
                ASSIGN ttPedItem.it-codigo          = ttItemTransfContainer.it_codigo_dest
                       ttPedItem.logMudouProdRef    = YES
                       .               
           END.
           IF ttItemTransfContainer.cod_refer_dest <> '' THEN  DO:
                IF NOT AVAIL ttPedNat THEN DO:
                   CREATE ttPedItem.
                   BUFFER-COPY bfPedItem TO ttPedItem.    
                END.
                ASSIGN ttPedItem.cod-refer          = ttItemTransfContainer.cod_refer_dest
                       ttPedItem.logMudouProdRef    = YES
                       .               
           END.            
        END.        
    END.
    
    
    
END PROCEDURE.

PROCEDURE alterarNatoperacao:

   DEFINE BUFFER bfPv FOR ped-venda .
   DEFINE BUFFER bfExt FOR ped-venda-ext.
   DEFINE VARIABLE logErro AS LOGICAL     NO-UNDO.
   //premissa: s¢ roda se o estabelecimento estiver mudado
   IF bfTransf.cod_estab_novo <> ''  THEN  DO:
        FOR EACH ttPedNat
            WHERE ttPedNat.logErroFinalid    = NO
            AND   ttPedNat.logNatNaoEncontr  = NO             
            :
            FOR FIRST bfPv NO-LOCK
                WHERE bfPv.nr-pedido = ttPedNat.nrPedido:
                EMPTY TEMP-TABLE tt-ped-venda.
                CREATE tt-ped-venda.
                BUFFER-COPY bfPv TO tt-ped-venda.
                ASSIGN tt-ped-venda.nat-operacao = ttPedNat.natoperacao.
                RUN alterarPedidoERP.
                RUN getErro IN hBoMsg(OUTPUT logErro).
                IF logErro THEN NEXT.
                FOR FIRST bfExt EXCLUSIVE-LOCK
                    WHERE bfExt.cod-estabel  =   ped-venda.cod-estabel
                    AND   bfExt.nr-pedido    =   ped-venda.nr-pedido
                    :
                    ASSIGN bfExt.cod_param_nat_operacao = ttPedNat.idParamNat.
                END.
                FIND CURRENT bfExt NO-LOCK. 
                RELEASE bfExt NO-ERROR.                 
            END.       
            IF AVAIL bfPv THEN  DO:
               //se existir alteraá∆o de produto ou referencia j† deve estar alterado chamando a funcao alterarProdRef antes desta   
               FOR EACH ttPedItem OF bfPv:
                   ASSIGN ttPedItem.nat-operacao =  bfPv.nat-operacao.             
               END.
            END.       
        END.   
   END.
   
    
    /* DEFINE TEMP-TABLE ttPedNat              NO-UNDO
    FIELD codEstabel        AS CHAR
    FIELD nrPedido          AS INT
    FIELD idParamNat        AS INT
    FIELD natOperacao       AS CHAR
    FIELD logErroFinalid    AS LOGICAL
    FIELD logNatNaoEncontr  AS LOGICAL
    INDEX primario IS PRIMARY codEstabel nrPedido */


END PROCEDURE.

PROCEDURE alterarPedidoERP:

    DEF VAR h-bodi159       AS HANDLE.
    DEF VAR h-bodi159com    AS HANDLE.
    DEFINE VARIABLE cErros  AS CHARACTER   NO-UNDO.
    
    IF NOT VALID-HANDLE(h-bodi159) OR
       h-bodi159:TYPE      <> "PROCEDURE":U OR
       h-bodi159:FILE-NAME <> "dibo/bodi159.p":U THEN
       RUN dibo/bodi159.p PERSISTENT SET h-bodi159.

    IF NOT VALID-HANDLE(h-bodi159com) OR
       h-bodi159com:TYPE      <> "PROCEDURE":U OR
       h-bodi159com:FILE-NAME <> "dibo/bodi159com.p":U THEN
       RUN dibo/bodi159com.p PERSISTENT SET h-bodi159com.

    RUN setconstraintRowid IN h-bodi159 (INPUT ROWID(ped-venda)).
    RUN openQueryStatic    IN h-bodi159 (input "Rowid":U).      
    RUN emptyRowErrors     IN h-bodi159.
    RUN setRecord          IN h-bodi159(INPUT TABLE tt-ped-venda).
    RUN UpdateRecord       IN h-bodi159.
    RUN getRowErrors       IN h-bodi159(OUTPUT TABLE RowErrors).
    IF CAN-FIND(FIRST RowErrors 
               WHERE RowErrors.ErrorSubType = "ERROR":U  ) THEN DO:
        RUN esp/getMsgRowErrors.p(TABLE rowErrors, OUTPUT cErros).           
        RUN setMsg IN hBoMsg(99,cErros,'erro').
    END.
     
    IF VALID-HANDLE(h-bodi159) THEN
       DELETE OBJECT h-bodi159.

    IF VALID-HANDLE(h-bodi159com) THEN
       DELETE OBJECT h-bodi159com. 
       
END PROCEDURE.


PROCEDURE alterarItensPedidoERP:

    
    DEF VAR h-bodi154       AS HANDLE.
    DEF VAR h-bodi154sdf    AS HANDLE.
    DEFINE VARIABLE cErros  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE proxSeq AS INTEGER     NO-UNDO.
    IF NOT VALID-HANDLE(h-bodi154) 
       OR  h-bodi154:TYPE      <> "PROCEDURE":U 
       OR  h-bodi154:FILE-NAME <> "dibo/bodi154.p":U THEN
       RUN dibo/bodi154.p PERSISTENT SET h-bodi154.
       
    IF NOT VALID-HANDLE(h-bodi154sdf) 
       OR h-bodi154sdf:TYPE      <> "PROCEDURE":U 
       OR h-bodi154sdf:FILE-NAME <> "dibo/bodi154sdf.p":U THEN
       RUN dibo/bodi154sdf.p PERSISTENT SET h-bodi154sdf.        
    /*
    pela logica abaixo, quando tem uma alteraá∆o de produto ou referencia
    muda a situaá∆o do item, caso contr†rio vai ser uma alteraá∆o de natureza de operaá∆o
    por troca de estabelecimento e n∆o precisa cancelar.
    Chama a BO de item do pedido que vai cancelar ou atualizar a natureza do item do pedido.
    
    */   
    FOR EACH ttPedITem: 
        EMPTY TEMP-TABLE tt-ped-item.        
        CREATE tt-ped-item.
        BUFFER-COPY ttPedItem TO tt-ped-item.        
        IF ttPedItem.logMudouProdRef = NO THEN DO:            
           ASSIGN ttPedITem.cod-sit-item = 6 . //cancelado 
        END.
        RUN setConstraintKey IN h-bodi154 (INPUT tt-ped-item.nome-abrev,
                                   INPUT tt-ped-item.nr-pedcli,
                                   INPUT tt-ped-item.nr-sequencia,
                                   INPUT tt-ped-item.it-codigo,
                                   INPUT tt-ped-item.cod-refer).

        RUN openQueryStatic in h-bodi154 (input "Key":U).        
        RUN emptyRowErrors IN h-bodi154.
        RUN setRecord IN h-bodi154(INPUT TABLE tt-ped-item).
        RUN updateRecord IN h-bodi154.
        RUN getRowErrors IN h-bodi154(OUTPUT TABLE RowErrors).
            
        IF CAN-FIND(FIRST RowErrors 
                    WHERE RowErrors.ErrorSubType = "ERROR":U  ) THEN DO:
            RUN esp/getMsgRowErrors.p(TABLE rowErrors, OUTPUT cErros).           
            RUN setMsg IN hBoMsg(98,cErros,'erro').         
        END.
    END.
    /*
    recria apenas os itens do pedido com alteraá∆o no produto ou referencia    
    */
    FOR EACH ttPedITem
        WHERE ttPedItem.logMudouProdRef,
        EACH ttPedNat 
        WHERE ttPedNat.nrPedido = int(ttPedItem.nr-Pedcli):
        IF proxSeq <= ttPedNat.ultSeq THEN DO:
           ASSIGN proxSeq = ttPedNat.ultSeq.            
        END.
        ASSIGN proxSeq  = proxSeq + 10 .
        
        EMPTY TEMP-TABLE tt-ped-item. 
        CREATE tt-ped-item.
        BUFFER-COPY ttPedItem TO tt-ped-item.  
        ASSIGN tt-ped-item.nr-sequencia = proxSeq .
        
        RUN openQueryStatic in h-bodi154 (input "main":U).        
        RUN emptyRowErrors IN h-bodi154.
        RUN inputTable     IN h-bodi154sdf (INPUT TABLE tt-ped-item).
        RUN setDefaultItem IN h-bodi154sdf.
        RUN outputTable    IN h-bodi154sdf (OUTPUT TABLE tt-ped-item).         
        RUN setRecord      IN h-bodi154(INPUT TABLE tt-ped-item).
        RUN createRecord   IN h-bodi154.
        RUN getRowErrors   IN h-bodi154(OUTPUT TABLE RowErrors).
            
        IF CAN-FIND(FIRST RowErrors 
                    WHERE RowErrors.ErrorSubType = "ERROR":U  ) THEN DO:
            RUN esp/getMsgRowErrors.p(TABLE rowErrors, OUTPUT cErros).           
            RUN setMsg IN hBoMsg(97,cErros,'erro').         
        END.
    
    END.
    IF VALID-HANDLE(h-bodi154) THEN
       DELETE PROCEDURE h-bodi154.
    IF VALID-HANDLE(h-bodi154sdf) THEN
       DELETE PROCEDURE h-bodi154sdf.   
       
END PROCEDURE.


PROCEDURE getTTMsg:
    DEFINE INPUT  PARAMETER pTipo AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER TABLE FOR ttMsg.

    IF VALID-HANDLE(hBoMsg) THEN
        RUN getTTMsg IN hBoMsg(INPUT pTipo, OUTPUT TABLE ttMsg).
END PROCEDURE.

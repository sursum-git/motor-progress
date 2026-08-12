/***************************************************************************
PROGRAMA: api_transf_container_v2.p
OBJETIVO: API JsonObject para transferencia entre containers usando analiseJsonObject10.p.
DATA: 08/2026
****************************************************************************/
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT  PARAMETER poRequest  AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

DEFINE VARIABLE hBo AS HANDLE NO-UNDO.
DEFINE VARIABLE hBoTransacao AS HANDLE NO-UNDO.
DEFINE VARIABLE iTransacaoLog AS INTEGER NO-UNDO.
DEFINE VARIABLE lTransacaoFinalizada AS LOGICAL NO-UNDO.
DEFINE VARIABLE iLogOrigem AS INTEGER NO-UNDO.
DEFINE VARIABLE iLogContainerOrig AS INTEGER NO-UNDO.
DEFINE VARIABLE iLogContainerDest AS INTEGER NO-UNDO.
DEFINE VARIABLE iLogTransfContainer AS INT64 NO-UNDO.
DEFINE VARIABLE cLogOperation AS CHARACTER NO-UNDO INITIAL "".
DEFINE VARIABLE cLogScreen AS CHARACTER NO-UNDO INITIAL "".

DEFINE TEMP-TABLE ttTransfItem NO-UNDO
    FIELD sequenciaJson       AS INTEGER
    FIELD produtoOrigem       AS CHARACTER
    FIELD referenciaOrigem    AS CHARACTER
    FIELD produtoDestino      AS CHARACTER
    FIELD referenciaDestino   AS CHARACTER
    FIELD quantidadeOriginal  AS DECIMAL
    FIELD quantidadeInformada AS DECIMAL
    FIELD preco90Novo         AS DECIMAL
    FIELD moeda               AS INTEGER
    FIELD selecionadoProduto  AS LOGICAL
    FIELD selecionadoSaldo    AS LOGICAL
    FIELD selecionadoPreco    AS LOGICAL
    INDEX idxItem produtoOrigem referenciaOrigem.

DEFINE TEMP-TABLE ttJsonTag NO-UNDO
    FIELD id       AS INTEGER
    FIELD parentId AS INTEGER
    FIELD nivel    AS INTEGER
    FIELD nome     AS CHARACTER
    FIELD caminho  AS CHARACTER
    FIELD tipo     AS CHARACTER
    FIELD indice   AS INTEGER
    FIELD valor    AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE id
    INDEX idxCaminho caminho.

DEFINE TEMP-TABLE ttJsonDestino NO-UNDO
    FIELD destino     AS CHARACTER
    FIELD tableHandle AS HANDLE
    FIELD nivel       AS INTEGER
    FIELD caminhoBase AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE destino.

DEFINE TEMP-TABLE ttJsonDePara NO-UNDO
    FIELD destino      AS CHARACTER
    FIELD campoTabela  AS CHARACTER
    FIELD tagJson      AS CHARACTER
    FIELD obrigatorio  AS LOGICAL
    FIELD valorDefault AS CHARACTER
    INDEX idxDestino destino.

DEFINE TEMP-TABLE ttJsonErro NO-UNDO
    FIELD destino     AS CHARACTER
    FIELD campoTabela AS CHARACTER
    FIELD tagJson     AS CHARACTER
    FIELD caminho     AS CHARACTER
    FIELD mensagem    AS CHARACTER.

DEFINE TEMP-TABLE ttRequestHeader NO-UNDO
    FIELD origem                 AS CHARACTER
    FIELD piNumero               AS CHARACTER
    FIELD containerNumero        AS CHARACTER
    FIELD operationId            AS CHARACTER
    FIELD screenId               AS CHARACTER
    FIELD changeEstablishment    AS CHARACTER
    FIELD changeProducts         AS CHARACTER
    FIELD priceMode              AS CHARACTER
    FIELD expirePreviousPrices   AS CHARACTER
    FIELD salesBalanceMode       AS CHARACTER
    FIELD estabelecimentoDestino AS CHARACTER
    FIELD moeda                  AS CHARACTER.

DEFINE TEMP-TABLE ttJsonItemMap NO-UNDO
    FIELD sequenciaJson              AS CHARACTER
    FIELD produtoOrigem              AS CHARACTER
    FIELD referenciaOrigem           AS CHARACTER
    FIELD selecionadoProduto         AS CHARACTER
    FIELD selecionadoSaldo           AS CHARACTER
    FIELD selecionadoPreco           AS CHARACTER
    FIELD produtoDestino             AS CHARACTER
    FIELD referenciaDestino          AS CHARACTER
    FIELD trocaQuantidadeComprada    AS CHARACTER
    FIELD trocaQuantidadeTransferir  AS CHARACTER
    FIELD saldoQuantidadeSaldo       AS CHARACTER
    FIELD saldoQuantidadeTransferir  AS CHARACTER
    FIELD preco90Novo                AS CHARACTER.

{esapi/jsonValorConversoes10-fwd.i}
FUNCTION priceModeToType RETURNS INTEGER (INPUT pcMode AS CHARACTER) FORWARD.
FUNCTION salesModeToType RETURNS INTEGER (INPUT pcMode AS CHARACTER) FORWARD.
FUNCTION priceTablesFromTags RETURNS CHARACTER () FORWARD.
FUNCTION iSeqJsonTags RETURNS INTEGER () FORWARD.
FUNCTION nextTableId RETURNS INT64 (INPUT pcTable AS CHARACTER, INPUT pcField AS CHARACTER) FORWARD.
FUNCTION currentUser RETURNS CHARACTER () FORWARD.
FUNCTION logTypeToInt RETURNS INTEGER (INPUT pcTipo AS CHARACTER) FORWARD.

DEFINE TEMP-TABLE ttMsg NO-UNDO
    FIELD cod       AS INTEGER
    FIELD descricao AS CHARACTER
    FIELD tipo      AS CHARACTER.

ASSIGN poResponse = NEW JsonObject().

DO ON ERROR UNDO, LEAVE:
    DEFINE VARIABLE jaOutItems AS JsonArray NO-UNDO.
    DEFINE VARIABLE jaMessages AS JsonArray NO-UNDO.
    DEFINE VARIABLE iOrigem AS INTEGER NO-UNDO.
    DEFINE VARIABLE iContainerOrig AS INTEGER NO-UNDO.
    DEFINE VARIABLE iContainerDest AS INTEGER NO-UNDO.
    DEFINE VARIABLE iMoeda AS INTEGER NO-UNDO.
    DEFINE VARIABLE iTipoPreco AS INTEGER NO-UNDO.
    DEFINE VARIABLE iTipoSaldo AS INTEGER NO-UNDO.
    DEFINE VARIABLE iIdTransf AS INT64 NO-UNDO.
    DEFINE VARIABLE cOperation AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cScreen AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPriceTables AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEstabDestino AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lChangeEstab AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lChangeProducts AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lExpirePrices AS LOGICAL NO-UNDO.

    RUN startTransacao.
    RUN logTransacao(INPUT 0, INPUT "Inicio api_transf_container_v2.p", INPUT "log").

    IF NOT VALID-OBJECT(poRequest) THEN DO:
        RUN addMessage(INPUT 1, INPUT "Requisicao JSON nao informada", INPUT "erro").
        RUN buildMessagesJson(OUTPUT jaMessages).
        poResponse:Add("success", FALSE).
        poResponse:Add("program", "api_transf_container_v2.p").
        poResponse:Add("transacaoId", iTransacaoLog).
        poResponse:Add("messages", jaMessages).
        RUN finishTransacao(INPUT 2).
        RETURN.
    END.

    RUN analyzeRequest(INPUT poRequest).

    IF CAN-FIND(FIRST ttJsonErro) THEN
        RUN addMapperMessages.

    FIND FIRST ttRequestHeader NO-ERROR.

    IF AVAILABLE ttRequestHeader THEN DO:
        ASSIGN iOrigem         = intFromChar(ttRequestHeader.origem, 0)
               iContainerOrig  = intFromChar(ttRequestHeader.piNumero, 0)
               iContainerDest  = intFromChar(ttRequestHeader.containerNumero, 0)
               cOperation      = ttRequestHeader.operationId
               cScreen         = ttRequestHeader.screenId
               iMoeda          = intFromChar(ttRequestHeader.moeda, 0)
               iTipoPreco      = priceModeToType(ttRequestHeader.priceMode)
               iTipoSaldo      = salesModeToType(ttRequestHeader.salesBalanceMode)
               cPriceTables    = priceTablesFromTags()
               cEstabDestino   = ttRequestHeader.estabelecimentoDestino
               lChangeEstab    = logFromChar(ttRequestHeader.changeEstablishment, FALSE)
               lChangeProducts = logFromChar(ttRequestHeader.changeProducts, FALSE)
               lExpirePrices   = logFromChar(ttRequestHeader.expirePreviousPrices, FALSE).
        ASSIGN iLogOrigem = iOrigem
               iLogContainerOrig = iContainerOrig
               iLogContainerDest = iContainerDest
               cLogOperation = cOperation
               cLogScreen = cScreen.
    END.
    ELSE
        RUN addMessage(INPUT 4, INPUT "answers nao informado", INPUT "erro").

    IF iContainerOrig = 0 THEN
        RUN addMessage(INPUT 2, INPUT "piNumero/container origem invalido", INPUT "erro").
    IF iContainerDest = 0 THEN
        RUN addMessage(INPUT 3, INPUT "containerNumero deve ser informado", INPUT "erro").
    IF NOT CAN-FIND(FIRST ttJsonItemMap) THEN
        RUN addMessage(INPUT 5, INPUT "items nao informado", INPUT "erro").

    RUN buildTransfItemsFromMap(INPUT iMoeda).

    IF CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro") THEN DO:
        RUN buildItemsJson(OUTPUT jaOutItems).
        RUN buildMessagesJson(OUTPUT jaMessages).
        poResponse:Add("success", FALSE).
        poResponse:Add("program", "api_transf_container_v2.p").
        poResponse:Add("parser", "analiseJsonObject10Table.p").
        poResponse:Add("parserRecords", iSeqJsonTags()).
        poResponse:Add("transacaoId", iTransacaoLog).
        poResponse:Add("items", jaOutItems).
        poResponse:Add("messages", jaMessages).
        RUN finishTransacao(INPUT 2).
        RETURN.
    END.

    RUN createTransferRecords(
        INPUT iOrigem,
        INPUT iContainerOrig,
        INPUT iContainerDest,
        INPUT cOperation,
        INPUT cScreen,
        INPUT lChangeEstab,
        INPUT cEstabDestino,
        INPUT lChangeProducts,
        INPUT iTipoPreco,
        INPUT lExpirePrices,
        INPUT cPriceTables,
        INPUT iTipoSaldo,
        OUTPUT iIdTransf
    ).
    ASSIGN iLogTransfContainer = iIdTransf.

    IF NOT CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro") THEN
        RUN executeBo(INPUT iIdTransf).

    RUN buildItemsJson(OUTPUT jaOutItems).
    RUN buildMessagesJson(OUTPUT jaMessages).

    poResponse:Add("success", NOT CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro")).
    poResponse:Add("program", "api_transf_container_v2.p").
    poResponse:Add("parser", "analiseJsonObject10Table.p").
    poResponse:Add("parserRecords", iSeqJsonTags()).
    poResponse:Add("transacaoId", iTransacaoLog).
    poResponse:Add("origem", iOrigem).
    poResponse:Add("containerOrigem", iContainerOrig).
    poResponse:Add("containerDestino", iContainerDest).
    poResponse:Add("operationId", cOperation).
    poResponse:Add("screenId", cScreen).
    poResponse:Add("transfContainerId", iIdTransf).
    poResponse:Add("priceTables", cPriceTables).
    poResponse:Add("tipoCopiaPreco", iTipoPreco).
    poResponse:Add("tipoTransferenciaSaldo", iTipoSaldo).
    poResponse:Add("items", jaOutItems).
    poResponse:Add("messages", jaMessages).
    RUN finishTransacao(INPUT IF CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro") THEN 2 ELSE 1).
    RETURN.
END.

IF ERROR-STATUS:ERROR THEN DO:
    IF NOT VALID-OBJECT(poResponse) THEN
        ASSIGN poResponse = NEW JsonObject().
    RUN addMessage(INPUT 999, INPUT ERROR-STATUS:GET-MESSAGE(1), INPUT "erro") NO-ERROR.
    poResponse:Add("success", FALSE) NO-ERROR.
    poResponse:Add("error", ERROR-STATUS:GET-MESSAGE(1)) NO-ERROR.
    poResponse:Add("transacaoId", iTransacaoLog) NO-ERROR.
    RUN finishTransacao(INPUT 2) NO-ERROR.
END.

PROCEDURE analyzeRequest:
    DEFINE INPUT PARAMETER poJsonRequest AS JsonObject NO-UNDO.

    EMPTY TEMP-TABLE ttJsonTag.
    EMPTY TEMP-TABLE ttJsonDestino.
    EMPTY TEMP-TABLE ttJsonDePara.
    EMPTY TEMP-TABLE ttJsonErro.
    EMPTY TEMP-TABLE ttRequestHeader.
    EMPTY TEMP-TABLE ttJsonItemMap.

    RUN configureMappings.

    RUN esapi/analiseJsonObject10Table.p (
        INPUT poJsonRequest,
        INPUT "ISO8859-1",
        INPUT FALSE,
        INPUT TABLE ttJsonDestino,
        INPUT TABLE ttJsonDePara,
        OUTPUT TABLE ttJsonTag,
        OUTPUT TABLE ttJsonErro
    ) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        RUN addMessage(INPUT 7, INPUT "Erro ao executar analiseJsonObject10Table.p: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
        ERROR-STATUS:ERROR = FALSE.
        RETURN.
    END.
END PROCEDURE.

PROCEDURE configureMappings:
    RUN addDestino(INPUT "header", INPUT TEMP-TABLE ttRequestHeader:HANDLE, INPUT 1, INPUT "answers").
    RUN addDestino(INPUT "item", INPUT TEMP-TABLE ttJsonItemMap:HANDLE, INPUT 2, INPUT "items[]").

    RUN addDePara(INPUT "header", INPUT "origem", INPUT "/origem", INPUT FALSE, INPUT "0").
    RUN addDePara(INPUT "header", INPUT "piNumero", INPUT "/piNumero", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "header", INPUT "containerNumero", INPUT "/containerNumero", INPUT FALSE, INPUT "0").
    RUN addDePara(INPUT "header", INPUT "operationId", INPUT "/operationId", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "header", INPUT "screenId", INPUT "/screenId", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "header", INPUT "changeEstablishment", INPUT "changeEstablishment", INPUT FALSE, INPUT "false").
    RUN addDePara(INPUT "header", INPUT "changeProducts", INPUT "changeProducts", INPUT FALSE, INPUT "false").
    RUN addDePara(INPUT "header", INPUT "priceMode", INPUT "priceMode", INPUT FALSE, INPUT "copy").
    RUN addDePara(INPUT "header", INPUT "expirePreviousPrices", INPUT "expirePreviousPrices", INPUT FALSE, INPUT "false").
    RUN addDePara(INPUT "header", INPUT "salesBalanceMode", INPUT "salesBalanceMode", INPUT FALSE, INPUT "all").
    RUN addDePara(INPUT "header", INPUT "estabelecimentoDestino", INPUT "estabelecimentoDestino", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "header", INPUT "moeda", INPUT "moeda", INPUT FALSE, INPUT "0").

    RUN addDePara(INPUT "item", INPUT "sequenciaJson", INPUT "$indice", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "produtoOrigem", INPUT "produto", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "referenciaOrigem", INPUT "referencia", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "selecionadoProduto", INPUT "selecionadoTrocaProduto", INPUT FALSE, INPUT "false").
    RUN addDePara(INPUT "item", INPUT "selecionadoSaldo", INPUT "selecionadoSaldo", INPUT FALSE, INPUT "false").
    RUN addDePara(INPUT "item", INPUT "selecionadoPreco", INPUT "selecionadoPreco", INPUT FALSE, INPUT "false").
    RUN addDePara(INPUT "item", INPUT "produtoDestino", INPUT "trocaProduto.novoProduto", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "referenciaDestino", INPUT "trocaProduto.novaReferencia", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "trocaQuantidadeComprada", INPUT "trocaProduto.quantidadeComprada", INPUT FALSE, INPUT "0").
    RUN addDePara(INPUT "item", INPUT "trocaQuantidadeTransferir", INPUT "trocaProduto.quantidadeTransferir", INPUT FALSE, INPUT "0").
    RUN addDePara(INPUT "item", INPUT "saldoQuantidadeSaldo", INPUT "saldo.quantidadeSaldo", INPUT FALSE, INPUT "0").
    RUN addDePara(INPUT "item", INPUT "saldoQuantidadeTransferir", INPUT "saldo.quantidadeTransferir", INPUT FALSE, INPUT "0").
    RUN addDePara(INPUT "item", INPUT "preco90Novo", INPUT "preco.preco90Novo", INPUT FALSE, INPUT "0").
END PROCEDURE.

PROCEDURE addDestino:
    DEFINE INPUT PARAMETER pcDestino AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER phTable AS HANDLE NO-UNDO.
    DEFINE INPUT PARAMETER piNivel AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcCaminhoBase AS CHARACTER NO-UNDO.

    CREATE ttJsonDestino.
    ASSIGN ttJsonDestino.destino = pcDestino
           ttJsonDestino.tableHandle = phTable
           ttJsonDestino.nivel = piNivel
           ttJsonDestino.caminhoBase = pcCaminhoBase.
END PROCEDURE.

PROCEDURE addDePara:
    DEFINE INPUT PARAMETER pcDestino AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcCampoTabela AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcTagJson AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER plObrigatorio AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER pcValorDefault AS CHARACTER NO-UNDO.

    CREATE ttJsonDePara.
    ASSIGN ttJsonDePara.destino = pcDestino
           ttJsonDePara.campoTabela = pcCampoTabela
           ttJsonDePara.tagJson = pcTagJson
           ttJsonDePara.obrigatorio = plObrigatorio
           ttJsonDePara.valorDefault = pcValorDefault.
END PROCEDURE.

PROCEDURE addMapperMessages:
    DEFINE VARIABLE iMsg AS INTEGER NO-UNDO INITIAL 100.

    FOR EACH ttJsonErro:
        ASSIGN iMsg = iMsg + 1.
        RUN addMessage(
            INPUT iMsg,
            INPUT "Mapa JSON " + ttJsonErro.destino + "/" + ttJsonErro.campoTabela
                + " (" + ttJsonErro.caminho + "): " + ttJsonErro.mensagem,
            INPUT "erro"
        ).
    END.
END PROCEDURE.

PROCEDURE buildTransfItemsFromMap:
    DEFINE INPUT PARAMETER piMoeda AS INTEGER NO-UNDO.

    FOR EACH ttJsonItemMap BY ttJsonItemMap.sequenciaJson:
        CREATE ttTransfItem.
        ASSIGN ttTransfItem.sequenciaJson       = intFromChar(ttJsonItemMap.sequenciaJson, 0)
               ttTransfItem.produtoOrigem       = ttJsonItemMap.produtoOrigem
               ttTransfItem.referenciaOrigem    = ttJsonItemMap.referenciaOrigem
               ttTransfItem.selecionadoProduto  = logFromChar(ttJsonItemMap.selecionadoProduto, FALSE)
               ttTransfItem.selecionadoSaldo    = logFromChar(ttJsonItemMap.selecionadoSaldo, FALSE)
               ttTransfItem.selecionadoPreco    = logFromChar(ttJsonItemMap.selecionadoPreco, FALSE)
               ttTransfItem.produtoDestino      = IF ttTransfItem.selecionadoProduto THEN ttJsonItemMap.produtoDestino ELSE ""
               ttTransfItem.referenciaDestino   = IF ttTransfItem.selecionadoProduto THEN ttJsonItemMap.referenciaDestino ELSE ""
               ttTransfItem.quantidadeOriginal  = IF ttTransfItem.selecionadoSaldo
                                                   THEN decFromChar(ttJsonItemMap.saldoQuantidadeSaldo, 0)
                                                   ELSE decFromChar(ttJsonItemMap.trocaQuantidadeComprada, 0)
               ttTransfItem.quantidadeInformada = IF ttTransfItem.selecionadoSaldo
                                                   THEN decFromChar(ttJsonItemMap.saldoQuantidadeTransferir, 0)
                                                   ELSE decFromChar(ttJsonItemMap.trocaQuantidadeTransferir, 0)
               ttTransfItem.preco90Novo         = IF ttTransfItem.selecionadoPreco THEN decFromChar(ttJsonItemMap.preco90Novo, 0) ELSE 0
               ttTransfItem.moeda               = piMoeda.

        IF ttTransfItem.produtoOrigem = "" THEN
            RUN addMessage(INPUT 11, INPUT "Produto nao informado no item " + STRING(ttTransfItem.sequenciaJson), INPUT "erro").
    END.
END PROCEDURE.

{esapi/jsonValorConversoes10.i}

FUNCTION priceModeToType RETURNS INTEGER (INPUT pcMode AS CHARACTER):
    CASE LC(pcMode):
        WHEN "update" THEN RETURN 2.
        WHEN "none" THEN RETURN 3.
        WHEN "no-copy" THEN RETURN 3.
        OTHERWISE RETURN 1.
    END CASE.
END FUNCTION.

FUNCTION salesModeToType RETURNS INTEGER (INPUT pcMode AS CHARACTER):
    CASE LC(pcMode):
        WHEN "manual" THEN RETURN 3.
        WHEN "open" THEN RETURN 2.
        WHEN "open-orders" THEN RETURN 2.
        OTHERWISE RETURN 1.
    END CASE.
END FUNCTION.

FUNCTION priceTablesFromTags RETURNS CHARACTER ():
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.

    FOR EACH ttJsonTag
        WHERE ttJsonTag.tipo = "value"
          AND INDEX(ttJsonTag.caminho, "answers.priceTables[") = 1
        BY ttJsonTag.id:
        IF cRet <> "" THEN
            ASSIGN cRet = cRet + ",".
        ASSIGN cRet = cRet + ttJsonTag.valor.
    END.

    RETURN cRet.
END FUNCTION.

FUNCTION iSeqJsonTags RETURNS INTEGER ():
    DEFINE VARIABLE iRet AS INTEGER NO-UNDO.
    FOR EACH ttJsonTag:
        ASSIGN iRet = iRet + 1.
    END.
    RETURN iRet.
END FUNCTION.

FUNCTION nextTableId RETURNS INT64 (INPUT pcTable AS CHARACTER, INPUT pcField AS CHARACTER):
    DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
    DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
    DEFINE VARIABLE iNext AS INT64 NO-UNDO INITIAL 1.

    CREATE BUFFER hBuffer FOR TABLE pcTable NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hBuffer) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN iNext.
    END.

    CREATE QUERY hQuery.
    hQuery:ADD-BUFFER(hBuffer).
    hQuery:QUERY-PREPARE("FOR EACH " + pcTable + " NO-LOCK BY " + pcField + " DESCENDING") NO-ERROR.
    IF NOT ERROR-STATUS:ERROR THEN DO:
        hQuery:QUERY-OPEN() NO-ERROR.
        hQuery:GET-FIRST() NO-ERROR.
        IF hBuffer:AVAILABLE THEN
            ASSIGN iNext = INT64(hBuffer:BUFFER-FIELD(pcField):BUFFER-VALUE) + 1 NO-ERROR.
    END.
    ERROR-STATUS:ERROR = FALSE.
    IF VALID-HANDLE(hQuery) THEN DELETE OBJECT hQuery.
    IF VALID-HANDLE(hBuffer) THEN DELETE OBJECT hBuffer.
    RETURN iNext.
END FUNCTION.

FUNCTION currentUser RETURNS CHARACTER ():
    DEFINE VARIABLE cUser AS CHARACTER NO-UNDO.

    ASSIGN cUser = OS-GETENV("USERNAME") NO-ERROR.
    IF cUser = "" OR cUser = ? THEN
        ASSIGN cUser = OS-GETENV("USER") NO-ERROR.
    IF cUser = "" OR cUser = ? THEN
        ASSIGN cUser = "api".

    RETURN cUser.
END FUNCTION.

FUNCTION logTypeToInt RETURNS INTEGER (INPUT pcTipo AS CHARACTER):
    CASE LC(pcTipo):
        WHEN "aviso" THEN RETURN 1.
        WHEN "erro" THEN RETURN 2.
        OTHERWISE RETURN 3.
    END CASE.
END FUNCTION.

PROCEDURE startTransacao:
    IF VALID-HANDLE(hBoTransacao) OR iTransacaoLog > 0 THEN
        RETURN.

    RUN esbo/boTransacoes.p PERSISTENT SET hBoTransacao NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hBoTransacao) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN.
    END.

    RUN gerarTransacao IN hBoTransacao(
        INPUT "api_transf_container_v2.p",
        INPUT currentUser(),
        INPUT 500,
        INPUT iLogContainerOrig,
        OUTPUT iTransacaoLog
    ) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        ASSIGN iTransacaoLog = 0.
    END.
END PROCEDURE.

PROCEDURE finishTransacao:
    DEFINE INPUT PARAMETER piSituacao AS INTEGER NO-UNDO.

    IF lTransacaoFinalizada THEN
        RETURN.

    IF VALID-HANDLE(hBoTransacao) AND iTransacaoLog > 0 THEN DO:
        RUN finalizarTransacao IN hBoTransacao(INPUT piSituacao) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            ERROR-STATUS:ERROR = FALSE.
    END.

    ASSIGN lTransacaoFinalizada = TRUE.

    IF VALID-HANDLE(hBoTransacao) THEN DO:
        DELETE PROCEDURE hBoTransacao NO-ERROR.
        ASSIGN hBoTransacao = ?.
    END.
END PROCEDURE.

PROCEDURE logTransacao:
    DEFINE INPUT PARAMETER piCod AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcDescricao AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcTipo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescricao AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMsg AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cOper AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cScreen AS CHARACTER NO-UNDO.

    IF NOT VALID-HANDLE(hBoTransacao) OR iTransacaoLog <= 0 THEN
        RETURN.

    ASSIGN cMsg = IF pcDescricao = ? THEN "" ELSE pcDescricao
           cOper = IF cLogOperation = ? THEN "" ELSE cLogOperation
           cScreen = IF cLogScreen = ? THEN "" ELSE cLogScreen.

    ASSIGN cDescricao = STRING(piCod) + "-" + cMsg
        + " | origem=" + STRING(iLogOrigem)
        + " | containerOrigem=" + STRING(iLogContainerOrig)
        + " | containerDestino=" + STRING(iLogContainerDest)
        + " | transfContainerId=" + STRING(iLogTransfContainer)
        + " | operationId=" + cOper
        + " | screenId=" + cScreen.

    RUN setTransacao IN hBoTransacao(INPUT iTransacaoLog) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN ERROR-STATUS:ERROR = FALSE.

    RUN setTipo IN hBoTransacao(INPUT logTypeToInt(pcTipo)) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN ERROR-STATUS:ERROR = FALSE.

    RUN setDescricao IN hBoTransacao(INPUT cDescricao) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN ERROR-STATUS:ERROR = FALSE.

    RUN criarLog IN hBoTransacao NO-ERROR.
    IF ERROR-STATUS:ERROR THEN ERROR-STATUS:ERROR = FALSE.
END PROCEDURE.

PROCEDURE createTransferRecords:
    DEFINE INPUT PARAMETER piOrigem AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER piContainerOrig AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER piContainerDest AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcScreen AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER plMudarEstab AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER pcEstabNovo AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER plMudarProdutos AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER piTipoPreco AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER plVencerPrecos AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER pcTabelasPreco AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piTipoSaldo AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER piIdTransf AS INT64 NO-UNDO.

    DEFINE VARIABLE hTransf AS HANDLE NO-UNDO.
    DEFINE VARIABLE hItem AS HANDLE NO-UNDO.
    DEFINE VARIABLE iIdItem AS INT64 NO-UNDO.

    CREATE BUFFER hTransf FOR TABLE "transf_container" NO-ERROR.
    CREATE BUFFER hItem FOR TABLE "item_transf_container" NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hTransf) OR NOT VALID-HANDLE(hItem) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RUN addMessage(INPUT 20, INPUT "Nao foi possivel abrir buffers de transf_container/item_transf_container", INPUT "erro").
        RETURN.
    END.

    ASSIGN piIdTransf = nextTableId("transf_container", "id").
    hTransf:BUFFER-CREATE() NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        RUN addMessage(INPUT 21, INPUT "Erro ao criar transf_container: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
        ERROR-STATUS:ERROR = FALSE.
        RETURN.
    END.

    RUN setBufferField(INPUT hTransf, INPUT "id", INPUT STRING(piIdTransf)).
    RUN setBufferField(INPUT hTransf, INPUT "nr_container_orig", INPUT STRING(piContainerOrig)).
    RUN setBufferField(INPUT hTransf, INPUT "nr_container_dest", INPUT STRING(piContainerDest)).
    RUN setBufferField(INPUT hTransf, INPUT "dt_hr_ini", INPUT STRING(NOW)).
    RUN setBufferField(INPUT hTransf, INPUT "num_situacao", INPUT "0").
    RUN setBufferField(INPUT hTransf, INPUT "id_externo", INPUT pcOperation + ":" + pcScreen + ":" + STRING(piContainerOrig)).
    RUN setBufferField(INPUT hTransf, INPUT "log_conversao_ped_container", INPUT STRING(pcOperation = "pi_to_container" OR piOrigem = 1)).
    RUN setBufferField(INPUT hTransf, INPUT "log_mudar_estab", INPUT STRING(plMudarEstab)).
    RUN setBufferField(INPUT hTransf, INPUT "cod_estab_novo", INPUT pcEstabNovo).
    RUN setBufferField(INPUT hTransf, INPUT "log_mudar_produtos", INPUT STRING(plMudarProdutos)).
    RUN setBufferField(INPUT hTransf, INPUT "num_tipo_copia_preco", INPUT STRING(piTipoPreco)).
    RUN setBufferField(INPUT hTransf, INPUT "log_vencer_preco_anteriores", INPUT STRING(plVencerPrecos)).
    RUN setBufferField(INPUT hTransf, INPUT "lista_tbs_preco_a_copiar", INPUT pcTabelasPreco).
    RUN setBufferField(INPUT hTransf, INPUT "num_tipo_transf_saldo", INPUT STRING(piTipoSaldo)).

    FOR EACH ttTransfItem BY ttTransfItem.sequenciaJson:
        ASSIGN iIdItem = nextTableId("item_transf_container", "id").
        hItem:BUFFER-CREATE() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            RUN addMessage(INPUT 22, INPUT "Erro ao criar item_transf_container: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
            ERROR-STATUS:ERROR = FALSE.
            NEXT.
        END.
        RUN setBufferField(INPUT hItem, INPUT "id", INPUT STRING(iIdItem)).
        RUN setBufferField(INPUT hItem, INPUT "transf_container_id", INPUT STRING(piIdTransf)).
        RUN setBufferField(INPUT hItem, INPUT "it_codigo_orig", INPUT ttTransfItem.produtoOrigem).
        RUN setBufferField(INPUT hItem, INPUT "cod_refer_orig", INPUT ttTransfItem.referenciaOrigem).
        RUN setBufferField(INPUT hItem, INPUT "it_codigo_dest", INPUT ttTransfItem.produtoDestino).
        RUN setBufferField(INPUT hItem, INPUT "cod_refer_dest", INPUT ttTransfItem.referenciaDestino).
        RUN setBufferField(INPUT hItem, INPUT "vl_novo_preco_90", INPUT STRING(ttTransfItem.preco90Novo)).
        RUN setBufferField(INPUT hItem, INPUT "num_moeda", INPUT STRING(ttTransfItem.moeda)).
        RUN setBufferField(INPUT hItem, INPUT "qt_original", INPUT STRING(ttTransfItem.quantidadeOriginal)).
        RUN setBufferField(INPUT hItem, INPUT "qt_informada", INPUT STRING(ttTransfItem.quantidadeInformada)).
    END.

    IF VALID-HANDLE(hTransf) THEN DELETE OBJECT hTransf.
    IF VALID-HANDLE(hItem) THEN DELETE OBJECT hItem.
END PROCEDURE.

PROCEDURE setBufferField:
    DEFINE INPUT PARAMETER phBuffer AS HANDLE NO-UNDO.
    DEFINE INPUT PARAMETER pcField AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pxValue AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hField AS HANDLE NO-UNDO.
    DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.

    ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hField) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN.
    END.
    CASE hField:DATA-TYPE:
        WHEN "integer" THEN hField:BUFFER-VALUE = INTEGER(pxValue) NO-ERROR.
        WHEN "int64" THEN hField:BUFFER-VALUE = INT64(pxValue) NO-ERROR.
        WHEN "decimal" THEN DO:
            ASSIGN dValue = decimalJson(pxValue) NO-ERROR.
            IF NOT ERROR-STATUS:ERROR THEN
                hField:BUFFER-VALUE = dValue NO-ERROR.
        END.
        WHEN "logical" THEN hField:BUFFER-VALUE = LOGICAL(pxValue) NO-ERROR.
        WHEN "datetime" THEN hField:BUFFER-VALUE = DATETIME(pxValue) NO-ERROR.
        WHEN "datetime-tz" THEN hField:BUFFER-VALUE = DATETIME-TZ(pxValue) NO-ERROR.
        WHEN "date" THEN hField:BUFFER-VALUE = DATE(pxValue) NO-ERROR.
        OTHERWISE hField:BUFFER-VALUE = pxValue NO-ERROR.
    END CASE.
    IF ERROR-STATUS:ERROR THEN
        ERROR-STATUS:ERROR = FALSE.
END PROCEDURE.

PROCEDURE executeBo:
    DEFINE INPUT PARAMETER piIdTransf AS INT64 NO-UNDO.

    RUN esbo/boTransfEntreContainers.p PERSISTENT SET hBo NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hBo) THEN DO:
        RUN addMessage(INPUT 30, INPUT "Nao foi possivel iniciar boTransfEntreContainers.p: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
        ERROR-STATUS:ERROR = FALSE.
        RETURN.
    END.

    RUN iniciarBos IN hBo NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        RUN addMessage(INPUT 31, INPUT "Erro em iniciarBos: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
        ERROR-STATUS:ERROR = FALSE.
    END.

    IF NOT CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro") THEN DO:
        RUN setTransacaoLog IN hBo(INPUT iTransacaoLog) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            ERROR-STATUS:ERROR = FALSE.

        RUN setIdTransfContainer IN hBo(INPUT piIdTransf) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            RUN addMessage(INPUT 32, INPUT "Erro em setIdTransfContainer: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
            ERROR-STATUS:ERROR = FALSE.
        END.
        ELSE DO:
            RUN exec IN hBo NO-ERROR.
            IF ERROR-STATUS:ERROR THEN DO:
                RUN addMessage(INPUT 33, INPUT "Erro em exec: " + ERROR-STATUS:GET-MESSAGE(1), INPUT "erro").
                ERROR-STATUS:ERROR = FALSE.
            END.
        END.
    END.

    RUN getTTMsg IN hBo(INPUT "", OUTPUT TABLE ttMsg) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN
        ERROR-STATUS:ERROR = FALSE.
    ELSE DO:
        FOR EACH ttMsg:
            RUN logTransacao(INPUT ttMsg.cod, INPUT ttMsg.descricao, INPUT ttMsg.tipo).
        END.
    END.

    RUN finalizarBos IN hBo NO-ERROR.
    IF VALID-HANDLE(hBo) THEN
        DELETE PROCEDURE hBo.
END PROCEDURE.

PROCEDURE buildItemsJson:
    DEFINE OUTPUT PARAMETER poItems AS JsonArray NO-UNDO.
    DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
    ASSIGN poItems = NEW JsonArray().
    FOR EACH ttTransfItem BY ttTransfItem.sequenciaJson:
        ASSIGN joItem = NEW JsonObject().
        joItem:Add("sequenciaJson", ttTransfItem.sequenciaJson).
        joItem:Add("produtoOrigem", ttTransfItem.produtoOrigem).
        joItem:Add("referenciaOrigem", ttTransfItem.referenciaOrigem).
        joItem:Add("produtoDestino", ttTransfItem.produtoDestino).
        joItem:Add("referenciaDestino", ttTransfItem.referenciaDestino).
        joItem:Add("quantidadeOriginal", ttTransfItem.quantidadeOriginal).
        joItem:Add("quantidadeInformada", ttTransfItem.quantidadeInformada).
        joItem:Add("preco90Novo", ttTransfItem.preco90Novo).
        joItem:Add("moeda", ttTransfItem.moeda).
        joItem:Add("selecionadoProduto", ttTransfItem.selecionadoProduto).
        joItem:Add("selecionadoSaldo", ttTransfItem.selecionadoSaldo).
        joItem:Add("selecionadoPreco", ttTransfItem.selecionadoPreco).
        poItems:Add(joItem).
    END.
END PROCEDURE.

PROCEDURE buildMessagesJson:
    DEFINE OUTPUT PARAMETER poMessages AS JsonArray NO-UNDO.
    DEFINE VARIABLE joMsg AS JsonObject NO-UNDO.
    ASSIGN poMessages = NEW JsonArray().
    FOR EACH ttMsg:
        ASSIGN joMsg = NEW JsonObject().
        joMsg:Add("cod", ttMsg.cod).
        joMsg:Add("descricao", ttMsg.descricao).
        joMsg:Add("tipo", ttMsg.tipo).
        poMessages:Add(joMsg).
    END.
END PROCEDURE.

PROCEDURE addMessage:
    DEFINE INPUT PARAMETER piCod AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcDescricao AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcTipo AS CHARACTER NO-UNDO.

    CREATE ttMsg.
    ASSIGN ttMsg.cod = piCod
           ttMsg.descricao = pcDescricao
           ttMsg.tipo = pcTipo.
    RUN logTransacao(INPUT piCod, INPUT pcDescricao, INPUT pcTipo).
END PROCEDURE.

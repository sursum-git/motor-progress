/***************************************************************************
PROGRAMA: api_transf_container.p
OBJETIVO: API JsonObject para transferencia entre containers.
DATA: 08/2026
****************************************************************************/
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT  PARAMETER poRequest  AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

DEFINE VARIABLE hBo AS HANDLE NO-UNDO.

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

{esapi/jsonValorConversoes10-fwd.i}
{esapi/jsonObjectConversoes10-fwd.i}
FUNCTION priceModeToType RETURNS INTEGER (INPUT pcMode AS CHARACTER) FORWARD.
FUNCTION salesModeToType RETURNS INTEGER (INPUT pcMode AS CHARACTER) FORWARD.
FUNCTION nextTableId RETURNS INT64 (INPUT pcTable AS CHARACTER, INPUT pcField AS CHARACTER) FORWARD.

DEFINE TEMP-TABLE ttMsg NO-UNDO
    FIELD cod       AS INTEGER
    FIELD descricao AS CHARACTER
    FIELD tipo      AS CHARACTER.

ASSIGN poResponse = NEW JsonObject().

DO ON ERROR UNDO, LEAVE:
    DEFINE VARIABLE joAnswers AS JsonObject NO-UNDO.
    DEFINE VARIABLE jaItems AS JsonArray NO-UNDO.
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

    IF NOT VALID-OBJECT(poRequest) THEN DO:
        RUN addMessage(INPUT 1, INPUT "Requisicao JSON nao informada", INPUT "erro").
        RETURN.
    END.

    ASSIGN joAnswers      = getObject(poRequest, "answers")
           jaItems        = getArray(poRequest, "items")
           iOrigem        = getInt(poRequest, "origem", 0)
           iContainerOrig = getInt(poRequest, "piNumero", 0)
           iContainerDest = getInt(poRequest, "containerNumero", 0)
           cOperation     = getChar(poRequest, "operationId", "")
           cScreen        = getChar(poRequest, "screenId", "")
           iMoeda         = getInt(joAnswers, "moeda", 0)
           iTipoPreco     = priceModeToType(getChar(joAnswers, "priceMode", "copy"))
           iTipoSaldo     = salesModeToType(getChar(joAnswers, "salesBalanceMode", "all"))
           cPriceTables   = listFromArray(getArray(joAnswers, "priceTables"))
           cEstabDestino  = getChar(joAnswers, "estabelecimentoDestino", "").

    IF iContainerOrig = 0 THEN
        RUN addMessage(INPUT 2, INPUT "piNumero/container origem invalido", INPUT "erro").
    IF iContainerDest = 0 THEN
        RUN addMessage(INPUT 3, INPUT "containerNumero deve ser informado", INPUT "erro").
    IF NOT VALID-OBJECT(joAnswers) THEN
        RUN addMessage(INPUT 4, INPUT "answers nao informado", INPUT "erro").
    IF NOT VALID-OBJECT(jaItems) OR jaItems:Length = 0 THEN
        RUN addMessage(INPUT 5, INPUT "items nao informado", INPUT "erro").

    IF VALID-OBJECT(jaItems) THEN
        RUN parseItems(INPUT jaItems, INPUT iMoeda).

    IF CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro") THEN DO:
        RUN buildItemsJson(OUTPUT jaOutItems).
        RUN buildMessagesJson(OUTPUT jaMessages).
        poResponse:Add("success", FALSE).
        poResponse:Add("program", "api_transf_container.p").
        poResponse:Add("items", jaOutItems).
        poResponse:Add("messages", jaMessages).
        RETURN.
    END.

    RUN createTransferRecords(
        INPUT iOrigem,
        INPUT iContainerOrig,
        INPUT iContainerDest,
        INPUT cOperation,
        INPUT cScreen,
        INPUT getLog(joAnswers, "changeEstablishment", FALSE),
        INPUT cEstabDestino,
        INPUT getLog(joAnswers, "changeProducts", FALSE),
        INPUT iTipoPreco,
        INPUT getLog(joAnswers, "expirePreviousPrices", FALSE),
        INPUT cPriceTables,
        INPUT iTipoSaldo,
        OUTPUT iIdTransf
    ).

    IF NOT CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro") THEN
        RUN executeBo(INPUT iIdTransf).

    RUN buildItemsJson(OUTPUT jaOutItems).
    RUN buildMessagesJson(OUTPUT jaMessages).

    poResponse:Add("success", NOT CAN-FIND(FIRST ttMsg WHERE ttMsg.tipo = "erro")).
    poResponse:Add("program", "api_transf_container.p").
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
    RETURN.
END.

IF ERROR-STATUS:ERROR THEN DO:
    IF NOT VALID-OBJECT(poResponse) THEN
        ASSIGN poResponse = NEW JsonObject().
    poResponse:Add("success", FALSE) NO-ERROR.
    poResponse:Add("error", ERROR-STATUS:GET-MESSAGE(1)) NO-ERROR.
END.

{esapi/jsonValorConversoes10.i}
{esapi/jsonObjectConversoes10.i}

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

PROCEDURE parseItems:
    DEFINE INPUT PARAMETER poItems AS JsonArray NO-UNDO.
    DEFINE INPUT PARAMETER piMoeda AS INTEGER NO-UNDO.
    DEFINE VARIABLE iItem AS INTEGER NO-UNDO.
    DEFINE VARIABLE joItem AS JsonObject NO-UNDO.

    DO iItem = 1 TO poItems:Length:
        ASSIGN joItem = poItems:GetJsonObject(iItem) NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-OBJECT(joItem) THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            RUN addMessage(INPUT 10, INPUT "Item JSON invalido na posicao " + STRING(iItem), INPUT "erro").
            NEXT.
        END.
        RUN addItemFromJson(INPUT joItem, INPUT piMoeda, INPUT iItem).
    END.
END PROCEDURE.

PROCEDURE addItemFromJson:
    DEFINE INPUT PARAMETER poItem AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER piMoeda AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER piSeq AS INTEGER NO-UNDO.
    DEFINE VARIABLE joTroca AS JsonObject NO-UNDO.
    DEFINE VARIABLE joSaldo AS JsonObject NO-UNDO.
    DEFINE VARIABLE joPreco AS JsonObject NO-UNDO.

    ASSIGN joTroca = getObject(poItem, "trocaProduto")
           joSaldo = getObject(poItem, "saldo")
           joPreco = getObject(poItem, "preco").

    CREATE ttTransfItem.
    ASSIGN ttTransfItem.sequenciaJson       = piSeq
           ttTransfItem.produtoOrigem       = getChar(poItem, "produto", "")
           ttTransfItem.referenciaOrigem    = getChar(poItem, "referencia", "")
           ttTransfItem.selecionadoProduto  = getLog(poItem, "selecionadoTrocaProduto", FALSE)
           ttTransfItem.selecionadoSaldo    = getLog(poItem, "selecionadoSaldo", FALSE)
           ttTransfItem.selecionadoPreco    = getLog(poItem, "selecionadoPreco", FALSE)
           ttTransfItem.produtoDestino      = IF ttTransfItem.selecionadoProduto THEN getChar(joTroca, "novoProduto", "") ELSE ""
           ttTransfItem.referenciaDestino   = IF ttTransfItem.selecionadoProduto THEN getChar(joTroca, "novaReferencia", "") ELSE ""
           ttTransfItem.quantidadeOriginal  = IF ttTransfItem.selecionadoSaldo THEN getDec(joSaldo, "quantidadeSaldo", 0) ELSE getDec(joTroca, "quantidadeComprada", 0)
           ttTransfItem.quantidadeInformada = IF ttTransfItem.selecionadoSaldo THEN getDec(joSaldo, "quantidadeTransferir", 0) ELSE getDec(joTroca, "quantidadeTransferir", 0)
           ttTransfItem.preco90Novo         = IF ttTransfItem.selecionadoPreco THEN getDec(joPreco, "preco90Novo", 0) ELSE 0
           ttTransfItem.moeda               = piMoeda.

    IF ttTransfItem.produtoOrigem = "" THEN
        RUN addMessage(INPUT 11, INPUT "Produto nao informado no item " + STRING(piSeq), INPUT "erro").
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
END PROCEDURE.

USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT  PARAMETER poRequest  AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

DEFINE VARIABLE joAnaliseReq AS JsonObject NO-UNDO.
DEFINE VARIABLE joAnaliseRes AS JsonObject NO-UNDO.
DEFINE VARIABLE jaRecords AS JsonArray NO-UNDO.
DEFINE VARIABLE jaPedidos AS JsonArray NO-UNDO.
DEFINE VARIABLE jaItens AS JsonArray NO-UNDO.
DEFINE VARIABLE jaErros AS JsonArray NO-UNDO.

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

DEFINE TEMP-TABLE ttPedido NO-UNDO
    FIELD nrPedido   AS INTEGER
    FIELD codCliente AS CHARACTER
    FIELD nomeCliente AS CHARACTER
    FIELD observacao AS CHARACTER.

DEFINE TEMP-TABLE ttItem NO-UNDO
    FIELD nrPedido AS INTEGER
    FIELD sequencia AS INTEGER
    FIELD itCodigo AS CHARACTER
    FIELD quantidade AS DECIMAL
    FIELD valorUnit AS DECIMAL.

FUNCTION jsonChar RETURNS CHARACTER (INPUT poObject AS JsonObject, INPUT pcName AS CHARACTER) FORWARD.

ASSIGN poResponse = NEW JsonObject().

DO ON ERROR UNDO, LEAVE:
    ASSIGN joAnaliseReq = NEW JsonObject().
    joAnaliseReq:Add("jsonText", jsonChar(poRequest, "jsonText")).
    joAnaliseReq:Add("targetCodepage", "ISO8859-1").
    joAnaliseReq:Add("escapeUnicodeOutput", TRUE).

    RUN esapi/analiseJsonObject10.p (INPUT joAnaliseReq, OUTPUT joAnaliseRes).

    IF NOT VALID-OBJECT(joAnaliseRes) THEN DO:
        poResponse:Add("success", FALSE).
        poResponse:Add("error", "analiseJsonObject10.p nao retornou resposta").
        RETURN.
    END.

    IF joAnaliseRes:Has("success") AND NOT joAnaliseRes:GetLogical("success") THEN DO:
        poResponse:Add("success", FALSE).
        poResponse:Add("error", jsonChar(joAnaliseRes, "error")).
        RETURN.
    END.

    ASSIGN jaRecords = joAnaliseRes:GetJsonArray("records") NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-OBJECT(jaRecords) THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        poResponse:Add("success", FALSE).
        poResponse:Add("error", "Analise nao retornou records").
        RETURN.
    END.

    RUN carregarTagsDaAnalise(INPUT jaRecords).
    RUN montarMapeamento.

    RUN esapi/preencheTempTablesJson10.p (
        INPUT TABLE ttJsonTag,
        INPUT TABLE ttJsonDestino,
        INPUT TABLE ttJsonDePara,
        OUTPUT TABLE ttJsonErro
    ).

    RUN buildPedidosJson(OUTPUT jaPedidos).
    RUN buildItensJson(OUTPUT jaItens).
    RUN buildErrosJson(OUTPUT jaErros).

    poResponse:Add("success", TRUE).
    poResponse:Add("program", "exemplo-preenche-tt-json10").
    poResponse:Add("pedidos", jaPedidos).
    poResponse:Add("itens", jaItens).
    poResponse:Add("erros", jaErros).
    poResponse:Add("qtdPedidos", jaPedidos:Length).
    poResponse:Add("qtdItens", jaItens:Length).
    poResponse:Add("qtdErros", jaErros:Length).
    RETURN.
END.

IF ERROR-STATUS:ERROR THEN DO:
    IF NOT VALID-OBJECT(poResponse) THEN
        ASSIGN poResponse = NEW JsonObject().
    poResponse:Add("success", FALSE) NO-ERROR.
    poResponse:Add("error", ERROR-STATUS:GET-MESSAGE(1)) NO-ERROR.
END.

FUNCTION jsonChar RETURNS CHARACTER (INPUT poObject AS JsonObject, INPUT pcName AS CHARACTER):
    DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcValue AS LONGCHAR NO-UNDO.

    IF NOT VALID-OBJECT(poObject) OR NOT poObject:Has(pcName) OR poObject:IsNull(pcName) THEN
        RETURN "".

    ASSIGN cValue = poObject:GetCharacter(pcName) NO-ERROR.
    IF NOT ERROR-STATUS:ERROR AND cValue <> ? THEN
        RETURN cValue.

    ERROR-STATUS:ERROR = FALSE.
    ASSIGN lcValue = poObject:GetJsonText(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR OR lcValue = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN "".
    END.

    RETURN STRING(lcValue).
END FUNCTION.

PROCEDURE carregarTagsDaAnalise:
    DEFINE INPUT PARAMETER poRecords AS JsonArray NO-UNDO.
    DEFINE VARIABLE iItem AS INTEGER NO-UNDO.
    DEFINE VARIABLE joRow AS JsonObject NO-UNDO.

    DO iItem = 1 TO poRecords:Length:
        ASSIGN joRow = poRecords:GetJsonObject(iItem).
        CREATE ttJsonTag.
        ASSIGN ttJsonTag.id       = joRow:GetInteger("id")
               ttJsonTag.parentId = joRow:GetInteger("parentId")
               ttJsonTag.nivel    = joRow:GetInteger("nivel")
               ttJsonTag.nome     = jsonChar(joRow, "nome")
               ttJsonTag.caminho  = jsonChar(joRow, "caminho")
               ttJsonTag.tipo     = jsonChar(joRow, "tipo")
               ttJsonTag.indice   = joRow:GetInteger("indice")
               ttJsonTag.valor    = jsonChar(joRow, "valor").
    END.
END PROCEDURE.

PROCEDURE montarMapeamento:
    RUN addDestino(INPUT "pedido", INPUT TEMP-TABLE ttPedido:HANDLE, INPUT 2, INPUT "pedidos[]").
    RUN addDestino(INPUT "item", INPUT TEMP-TABLE ttItem:HANDLE, INPUT 4, INPUT "pedidos[].itens[]").

    RUN addDePara(INPUT "pedido", INPUT "nrPedido", INPUT "numero", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "pedido", INPUT "codCliente", INPUT "cliente.codigo", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "pedido", INPUT "nomeCliente", INPUT "cliente.nome", INPUT FALSE, INPUT "").
    RUN addDePara(INPUT "pedido", INPUT "observacao", INPUT "observacao", INPUT FALSE, INPUT "").

    RUN addDePara(INPUT "item", INPUT "nrPedido", INPUT "../numero", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "sequencia", INPUT "sequencia", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "itCodigo", INPUT "produto", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "quantidade", INPUT "quantidade", INPUT TRUE, INPUT "").
    RUN addDePara(INPUT "item", INPUT "valorUnit", INPUT "valorUnitario", INPUT TRUE, INPUT "").
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

PROCEDURE buildPedidosJson:
    DEFINE OUTPUT PARAMETER poRows AS JsonArray NO-UNDO.
    DEFINE VARIABLE joRow AS JsonObject NO-UNDO.

    ASSIGN poRows = NEW JsonArray().
    FOR EACH ttPedido:
        ASSIGN joRow = NEW JsonObject().
        joRow:Add("nrPedido", ttPedido.nrPedido).
        joRow:Add("codCliente", ttPedido.codCliente).
        joRow:Add("nomeCliente", ttPedido.nomeCliente).
        joRow:Add("observacao", ttPedido.observacao).
        poRows:Add(joRow).
    END.
END PROCEDURE.

PROCEDURE buildItensJson:
    DEFINE OUTPUT PARAMETER poRows AS JsonArray NO-UNDO.
    DEFINE VARIABLE joRow AS JsonObject NO-UNDO.

    ASSIGN poRows = NEW JsonArray().
    FOR EACH ttItem:
        ASSIGN joRow = NEW JsonObject().
        joRow:Add("nrPedido", ttItem.nrPedido).
        joRow:Add("sequencia", ttItem.sequencia).
        joRow:Add("itCodigo", ttItem.itCodigo).
        joRow:Add("quantidade", ttItem.quantidade).
        joRow:Add("valorUnit", ttItem.valorUnit).
        poRows:Add(joRow).
    END.
END PROCEDURE.

PROCEDURE buildErrosJson:
    DEFINE OUTPUT PARAMETER poRows AS JsonArray NO-UNDO.
    DEFINE VARIABLE joRow AS JsonObject NO-UNDO.

    ASSIGN poRows = NEW JsonArray().
    FOR EACH ttJsonErro:
        ASSIGN joRow = NEW JsonObject().
        joRow:Add("destino", ttJsonErro.destino).
        joRow:Add("campoTabela", ttJsonErro.campoTabela).
        joRow:Add("tagJson", ttJsonErro.tagJson).
        joRow:Add("caminho", ttJsonErro.caminho).
        joRow:Add("mensagem", ttJsonErro.mensagem).
        poRows:Add(joRow).
    END.
END PROCEDURE.

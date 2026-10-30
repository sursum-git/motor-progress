/* Consulta de pedidos via JsonObject. Datas de entrada: YYYY-MM-DD. */
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.

{esp/util.i}
{esbo/boConsPedVenda2.i}

/* Mesmo esquema da tabela recebida por setTTContainer na BO publicada. */
DEFINE TEMP-TABLE tt-containers NO-UNDO
    FIELD nr-container AS INTEGER
    INDEX primario IS PRIMARY nr-container.

DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hBo AS HANDLE NO-UNDO.
DEFINE VARIABLE joAnaliseReq AS JsonObject NO-UNDO.
DEFINE VARIABLE joAnaliseRes AS JsonObject NO-UNDO.
DEFINE VARIABLE jaTags AS JsonArray NO-UNDO.
DEFINE VARIABLE joTag AS JsonObject NO-UNDO.
DEFINE VARIABLE joDados AS JsonObject NO-UNDO.
DEFINE VARIABLE joTiming AS JsonObject NO-UNDO.
DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
DEFINE VARIABLE cNome AS CHARACTER NO-UNDO.
DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipo AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.
DEFINE VARIABLE dtIni AS DATE NO-UNDO.
DEFINE VARIABLE dtFim AS DATE NO-UNDO.
DEFINE VARIABLE nrIni AS INTEGER NO-UNDO.
DEFINE VARIABLE nrFim AS INTEGER NO-UNDO.
DEFINE VARIABLE lNrIni AS LOGICAL NO-UNDO.
DEFINE VARIABLE lNrFim AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOk AS LOGICAL NO-UNDO.
DEFINE VARIABLE cEstabIni AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabFim AS CHARACTER NO-UNDO.
DEFINE VARIABLE iClienteIni AS INTEGER NO-UNDO.
DEFINE VARIABLE iClienteFim AS INTEGER NO-UNDO.
DEFINE VARIABLE cRepresIni AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRepresFim AS CHARACTER NO-UNDO.
DEFINE VARIABLE lClube AS LOGICAL NO-UNDO.
DEFINE VARIABLE cSitPed AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSitAval AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSitPreco AS CHARACTER NO-UNDO.
DEFINE VARIABLE cBloqueio AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTextoValidado AS CHARACTER NO-UNDO.
DEFINE VARIABLE cListaContainers AS CHARACTER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE lDebugTiming AS LOGICAL NO-UNDO.
DEFINE VARIABLE iParseRequestMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iContainerMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iCreateBoMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iInitBoMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iSetterMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iExecMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iGetTTMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iFinalizeBoMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iCountMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iWriteJsonMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iResponseMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iPhase AS INTEGER NO-UNDO.
DEFINE VARIABLE cLogin AS CHARACTER NO-UNDO.
DEFINE VARIABLE lUsuarioRepresentante AS LOGICAL NO-UNDO.
DEFINE VARIABLE cRepresUsuario AS CHARACTER NO-UNDO.

FUNCTION lerDataIso RETURNS DATE (INPUT pcValor AS CHARACTER, INPUT pcCampo AS CHARACTER) FORWARD.
FUNCTION lerPedido RETURNS INTEGER (INPUT pcValor AS CHARACTER, INPUT pcCampo AS CHARACTER) FORWARD.
FUNCTION lerLista RETURNS CHARACTER (INPUT pcValor AS CHARACTER, INPUT pcCampo AS CHARACTER, INPUT plLogica AS LOGICAL) FORWARD.
FUNCTION normalizarIntervaloEstab RETURNS CHARACTER (INPUT pcValor AS CHARACTER, INPUT plInicio AS LOGICAL) FORWARD.
FUNCTION recuperarUsuario RETURNS CHARACTER (INPUT poReq AS JsonObject) FORWARD.

DO ON ERROR UNDO, THROW:
    ASSIGN poResponse = NEW JsonObject()
           dtIni = DATE(4, 1, 2026)
           dtFim = DATE(9, 24, 2026).
    IF NOT VALID-OBJECT(poRequest) THEN
        UNDO, THROW NEW AppError("Informe um JsonObject de entrada", 0).
    cLogin = recuperarUsuario(poRequest).
    IF poRequest:Has("debugTiming") THEN DO:
        lDebugTiming = poRequest:GetLogical("debugTiming") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            UNDO, THROW NEW AppError("debugTiming deve ser booleano true ou false", 0).
    END.
    iPhase = ETIME(TRUE).

    /* O analisador publicado recebe jsonText e devolve records com as tags. */
    joAnaliseReq = NEW JsonObject().
    poRequest:Write(lcJson).
    joAnaliseReq:Add("jsonText", lcJson).
    joAnaliseReq:Add("targetCodepage", SESSION:CPINTERNAL).
    RUN esapi/analiseJsonObject10.p (INPUT joAnaliseReq, OUTPUT joAnaliseRes).
    IF NOT VALID-OBJECT(joAnaliseRes) THEN
        UNDO, THROW NEW AppError("Analisador JSON nao retornou resposta", 0).
    IF NOT joAnaliseRes:Has("success") OR NOT joAnaliseRes:GetLogical("success") THEN
        UNDO, THROW NEW AppError("Falha no analisador JSON", 0).
    jaTags = joAnaliseRes:GetJsonArray("records").
    iParseRequestMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).

    DO i = 1 TO jaTags:Length:
        joTag = jaTags:GetJsonObject(i).
        /* Somente filtros na raiz: objetos internos nao sobrescrevem filtros. */
        IF joTag:GetInteger("parentId") <> 0 THEN NEXT.
        ASSIGN cNome = joTag:GetCharacter("nome")
               cValor = joTag:GetCharacter("valor")
               cTipo = joTag:GetCharacter("tipo").
        IF LOOKUP(cNome, "dtImplantIni,dtImplantFim,nrPedidoIni,nrPedidoFim,estabIni,estabFim,clienteIni,clienteFim,represIni,represFim,somenteClubeIma,sitPed,sitAval,sitPreco,bloqueioAprov,lista_containers") = 0 THEN NEXT.
        IF cTipo <> "value" THEN
            UNDO, THROW NEW AppError("Filtro invalido: " + cNome, 0).
        IF LOOKUP(cNome, "estabIni,estabFim,represIni,represFim,sitPed,sitAval,sitPreco,bloqueioAprov,lista_containers") > 0 THEN DO:
            /* Confere o tipo original, pois o analisador representa valores como texto. */
            cTextoValidado = poRequest:GetCharacter(cNome) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN
                UNDO, THROW NEW AppError(cNome + " deve ser texto", 0).
        END.
        CASE cNome:
            WHEN "dtImplantIni" THEN dtIni = lerDataIso(cValor, cNome).
            WHEN "dtImplantFim" THEN dtFim = lerDataIso(cValor, cNome).
            WHEN "nrPedidoIni" THEN ASSIGN nrIni = lerPedido(cValor, cNome) lNrIni = TRUE.
            WHEN "nrPedidoFim" THEN ASSIGN nrFim = lerPedido(cValor, cNome) lNrFim = TRUE.
            WHEN "estabIni" THEN cEstabIni = cValor.
            WHEN "estabFim" THEN cEstabFim = cValor.
            WHEN "clienteIni" THEN iClienteIni = lerPedido(cValor, cNome).
            WHEN "clienteFim" THEN iClienteFim = lerPedido(cValor, cNome).
            WHEN "represIni" THEN cRepresIni = cValor.
            WHEN "represFim" THEN cRepresFim = cValor.
            WHEN "somenteClubeIma" THEN DO:
                lClube = poRequest:GetLogical(cNome) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN
                    UNDO, THROW NEW AppError("somenteClubeIma deve ser booleano true ou false", 0).
            END.
            WHEN "sitPed" THEN cSitPed = lerLista(cValor, cNome, FALSE).
            WHEN "sitAval" THEN cSitAval = lerLista(cValor, cNome, FALSE).
            WHEN "sitPreco" THEN cSitPreco = lerLista(cValor, cNome, FALSE).
            WHEN "bloqueioAprov" THEN cBloqueio = lerLista(cValor, cNome, TRUE).
            WHEN "lista_containers" THEN cListaContainers = TRIM(cValor).
        END CASE.
    END.
    IF dtIni > dtFim THEN
        UNDO, THROW NEW AppError("dtImplantIni deve ser menor ou igual a dtImplantFim", 0).
    IF lNrIni <> lNrFim THEN
        UNDO, THROW NEW AppError("Informe nrPedidoIni e nrPedidoFim juntos", 0).
    IF lNrIni AND nrIni > nrFim THEN
        UNDO, THROW NEW AppError("nrPedidoIni deve ser menor ou igual a nrPedidoFim", 0).

    IF poRequest:Has("estabIni") <> poRequest:Has("estabFim") THEN
        UNDO, THROW NEW AppError("Informe estabIni e estabFim juntos", 0).
    IF poRequest:Has("clienteIni") <> poRequest:Has("clienteFim") THEN
        UNDO, THROW NEW AppError("Informe clienteIni e clienteFim juntos", 0).
    RUN aplicarRestricaoRepresentante(INPUT cLogin, OUTPUT lUsuarioRepresentante, OUTPUT cRepresUsuario).
    IF lUsuarioRepresentante THEN
        ASSIGN cRepresIni = cRepresUsuario
               cRepresFim = cRepresUsuario.
    ELSE IF poRequest:Has("represIni") <> poRequest:Has("represFim") THEN
        UNDO, THROW NEW AppError("Informe represIni e represFim juntos", 0).
    IF poRequest:Has("estabIni") THEN DO:
        cEstabFim = normalizarIntervaloEstab(cEstabIni, FALSE).
        cEstabIni = normalizarIntervaloEstab(cEstabIni, TRUE).
        IF cEstabIni > cEstabFim THEN
            UNDO, THROW NEW AppError("estabIni deve ser menor ou igual a estabFim", 0).
    END.
    IF poRequest:Has("clienteIni") AND iClienteIni > iClienteFim THEN
        UNDO, THROW NEW AppError("clienteIni deve ser menor ou igual a clienteFim", 0).
    IF NOT lUsuarioRepresentante AND poRequest:Has("represIni") AND cRepresIni > cRepresFim THEN
        UNDO, THROW NEW AppError("represIni deve ser menor ou igual a represFim", 0).

    iParseRequestMs = iParseRequestMs + ETIME(FALSE).
    iPhase = ETIME(TRUE).

    EMPTY TEMP-TABLE tt-containers.
    IF cListaContainers <> "" THEN DO:
        REPEAT i = 1 TO NUM-ENTRIES(cListaContainers, ","):
            iContainer = lerPedido(TRIM(ENTRY(i, cListaContainers, ",")), "lista_containers").
            /* A mesma selecao repetida nao deve duplicar os pedidos. */
            IF NOT CAN-FIND(FIRST tt-containers WHERE tt-containers.nr-container = iContainer) THEN DO:
                CREATE tt-containers.
                tt-containers.nr-container = iContainer.
            END.
        END.
    END.

    iContainerMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    RUN esbo/boConsPedVenda2.p PERSISTENT SET hBo.
    iCreateBoMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    RUN iniciarBo IN hBo.
    RUN limparContexto IN hBo.
    iInitBoMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    IF cListaContainers <> "" THEN
        RUN setTTContainer IN hBo (INPUT TABLE tt-containers).
    IF lNrIni THEN RUN setIntervalNrPedido IN hBo (nrIni, nrFim).
    RUN setIntervalDtImplant IN hBo (dtIni, dtFim).
    IF poRequest:Has("estabIni") THEN RUN setIntervalEstab IN hBo (cEstabIni, cEstabFim).
    IF poRequest:Has("clienteIni") AND (iClienteIni <> 0 OR iClienteFim <> 0) THEN RUN setIntervalCliente IN hBo (iClienteIni, iClienteFim).
    IF lUsuarioRepresentante OR poRequest:Has("represIni") THEN RUN setIntervalRepres IN hBo (cRepresIni, cRepresFim).
    IF poRequest:Has("somenteClubeIma") THEN RUN setSomenteClubeIma IN hBo (lClube).
    IF poRequest:Has("sitPed") THEN RUN setSitPed IN hBo (cSitPed).
    IF poRequest:Has("sitAval") THEN RUN setSitAval IN hBo (cSitAval).
    IF poRequest:Has("sitPreco") THEN RUN setSitPreco IN hBo (cSitPreco).
    IF poRequest:Has("bloqueioAprov") AND cBloqueio <> "" THEN RUN setBloqueioAprov IN hBo (cBloqueio).
    iSetterMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    RUN exec IN hBo.
    iExecMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    RUN getTTDados IN hBo (OUTPUT TABLE tt-dados).
    iGetTTMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    RUN finalizarBo IN hBo.
    iFinalizeBoMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).

    FOR EACH tt-dados:
        iTotal = iTotal + 1.
    END.
    iCountMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    TEMP-TABLE tt-dados:SERIALIZE-NAME = "tt-dados".
    joDados = NEW JsonObject().
    lOk = TEMP-TABLE tt-dados:WRITE-JSON("JsonObject", joDados, FALSE).
    IF NOT lOk THEN UNDO, THROW NEW AppError("Falha ao serializar tt-dados", 0).
    iWriteJsonMs = ETIME(FALSE).
    iPhase = ETIME(TRUE).
    poResponse:Add("success", TRUE).
    poResponse:Add("total", iTotal).
    poResponse:Add("tt-dados", joDados:GetJsonArray("tt-dados")).
    iResponseMs = ETIME(FALSE).
    IF lDebugTiming THEN DO:
        joTiming = NEW JsonObject().
        joTiming:Add("parseRequestMs", iParseRequestMs).
        joTiming:Add("containersMs", iContainerMs).
        joTiming:Add("createBoMs", iCreateBoMs).
        joTiming:Add("initBoMs", iInitBoMs).
        joTiming:Add("settersMs", iSetterMs).
        joTiming:Add("execMs", iExecMs).
        joTiming:Add("getTTDadosMs", iGetTTMs).
        joTiming:Add("finalizarBoMs", iFinalizeBoMs).
        joTiming:Add("countMs", iCountMs).
        joTiming:Add("writeJsonMs", iWriteJsonMs).
        joTiming:Add("responseBuildMs", iResponseMs).
        joTiming:Add("measuredInsideProgramMs", iParseRequestMs + iContainerMs + iCreateBoMs + iInitBoMs + iSetterMs + iExecMs + iGetTTMs + iFinalizeBoMs + iCountMs + iWriteJsonMs + iResponseMs).
        poResponse:Add("timing", joTiming).
    END.

    CATCH oErro AS Progress.Lang.Error:
        IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
        poResponse = NEW JsonObject().
        poResponse:Add("success", FALSE).
        poResponse:Add("error", oErro:GetMessage(1)).
        poResponse:Add("tt-dados", NEW JsonArray()).
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hBo) THEN DO:
            RUN finalizarBo IN hBo NO-ERROR.
            IF VALID-HANDLE(hBo) THEN DELETE PROCEDURE hBo NO-ERROR.
        END.
        IF VALID-OBJECT(joAnaliseReq) THEN DELETE OBJECT joAnaliseReq NO-ERROR.
        IF VALID-OBJECT(joAnaliseRes) THEN DELETE OBJECT joAnaliseRes NO-ERROR.
        IF VALID-OBJECT(joDados) THEN DELETE OBJECT joDados NO-ERROR.
    END FINALLY.
END.

PROCEDURE aplicarRestricaoRepresentante:
    DEFINE INPUT PARAMETER pcLogin AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plRepresentante AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER pcNomeAbrev AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hUser AS HANDLE NO-UNDO.
    DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
    DEFINE VARIABLE hLogin AS HANDLE NO-UNDO.
    DEFINE VARIABLE hTpUsuario AS HANDLE NO-UNDO.
    DEFINE VARIABLE hNomeAbrev AS HANDLE NO-UNDO.

    ASSIGN plRepresentante = FALSE
           pcNomeAbrev = "".
    IF pcLogin = ? OR TRIM(pcLogin) = "" THEN RETURN.

    DO ON ERROR UNDO, THROW:
        CREATE BUFFER hUser FOR TABLE "espec.user-web" NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hUser) THEN
            UNDO, THROW NEW AppError("Tabela espec.user-web indisponivel para validar permissoes", 0).

        ASSIGN hLogin = hUser:BUFFER-FIELD("Login")
               hTpUsuario = hUser:BUFFER-FIELD("tp-usuario")
               hNomeAbrev = hUser:BUFFER-FIELD("nome-ab-cli") NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hLogin) OR NOT VALID-HANDLE(hTpUsuario) OR NOT VALID-HANDLE(hNomeAbrev) THEN
            UNDO, THROW NEW AppError("Campos da user-web indisponiveis para validar permissoes", 0).

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hUser).
        hQuery:QUERY-PREPARE("FOR EACH espec.user-web NO-LOCK WHERE espec.user-web.Login = " + QUOTER(TRIM(pcLogin))).
        hQuery:QUERY-OPEN().
        hQuery:GET-FIRST().
        IF NOT hUser:AVAILABLE THEN RETURN.
        IF INTEGER(hTpUsuario:BUFFER-VALUE) <> 2 THEN RETURN.

        ASSIGN plRepresentante = TRUE
               pcNomeAbrev = TRIM(STRING(hNomeAbrev:BUFFER-VALUE)).
        IF pcNomeAbrev = "" THEN
            pcNomeAbrev = TRIM(STRING(hLogin:BUFFER-VALUE)).
        IF pcNomeAbrev = "" THEN
            UNDO, THROW NEW AppError("Usuario representante sem representante na user-web", 0).

        FINALLY:
            IF VALID-HANDLE(hQuery) THEN DO:
                hQuery:QUERY-CLOSE() NO-ERROR.
                DELETE OBJECT hQuery NO-ERROR.
            END.
            IF VALID-HANDLE(hUser) THEN DELETE OBJECT hUser NO-ERROR.
        END FINALLY.
    END.
END PROCEDURE.

FUNCTION lerDataIso RETURNS DATE (INPUT pcValor AS CHARACTER, INPUT pcCampo AS CHARACTER):
    DEFINE VARIABLE d AS DATE NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    IF LENGTH(pcValor) <> 10 OR SUBSTRING(pcValor,5,1) <> "-" OR SUBSTRING(pcValor,8,1) <> "-" THEN
        UNDO, THROW NEW AppError(pcCampo + " deve usar YYYY-MM-DD", 0).
    DO n = 1 TO 10:
        IF n = 5 OR n = 8 THEN NEXT.
        IF INDEX("0123456789", SUBSTRING(pcValor,n,1)) = 0 THEN
            UNDO, THROW NEW AppError(pcCampo + " deve usar YYYY-MM-DD", 0).
    END.
    d = DATE(INTEGER(SUBSTRING(pcValor,6,2)), INTEGER(SUBSTRING(pcValor,9,2)), INTEGER(SUBSTRING(pcValor,1,4))) NO-ERROR.
    IF ERROR-STATUS:ERROR OR d = ? THEN
        UNDO, THROW NEW AppError("Data invalida: " + pcCampo, 0).
    RETURN d.
END FUNCTION.

FUNCTION lerPedido RETURNS INTEGER (INPUT pcValor AS CHARACTER, INPUT pcCampo AS CHARACTER):
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE resultado AS INTEGER NO-UNDO.
    IF pcValor = "" THEN UNDO, THROW NEW AppError((IF pcCampo BEGINS "nrPedido" THEN "Pedido invalido: " ELSE "Inteiro invalido: ") + pcCampo, 0).
    DO n = 1 TO LENGTH(pcValor):
        IF INDEX("0123456789", SUBSTRING(pcValor,n,1)) = 0 THEN
            UNDO, THROW NEW AppError((IF pcCampo BEGINS "nrPedido" THEN "Pedido invalido: " ELSE "Inteiro invalido: ") + pcCampo, 0).
    END.
    resultado = INTEGER(pcValor) NO-ERROR.
    IF ERROR-STATUS:ERROR OR resultado = ? THEN
        UNDO, THROW NEW AppError((IF pcCampo BEGINS "nrPedido" THEN "Pedido invalido: " ELSE "Inteiro invalido: ") + pcCampo, 0).
    RETURN resultado.
END FUNCTION.

FUNCTION normalizarIntervaloEstab RETURNS CHARACTER (INPUT pcValor AS CHARACTER, INPUT plInicio AS LOGICAL):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    cValor = TRIM(IF pcValor = ? THEN "" ELSE pcValor).
    IF NUM-ENTRIES(cValor, ",") >= 2 THEN
        RETURN TRIM(ENTRY(IF plInicio THEN 1 ELSE 2, cValor, ",")).
    RETURN cValor.
END FUNCTION.

FUNCTION recuperarUsuario RETURNS CHARACTER (INPUT poReq AS JsonObject):
    DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
    IF NOT VALID-OBJECT(poReq) THEN RETURN "".
    IF poReq:Has("login") THEN DO:
        cUsuario = poReq:GetCharacter("login") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW AppError("login deve ser texto", 0).
        RETURN TRIM(cUsuario).
    END.
    IF poReq:Has("usuario") THEN DO:
        cUsuario = poReq:GetCharacter("usuario") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW AppError("usuario deve ser texto", 0).
        RETURN TRIM(cUsuario).
    END.
    IF poReq:Has("userName") THEN DO:
        cUsuario = poReq:GetCharacter("userName") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW AppError("userName deve ser texto", 0).
        RETURN TRIM(cUsuario).
    END.
    IF poReq:Has("requestUser") THEN DO:
        cUsuario = poReq:GetCharacter("requestUser") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW AppError("requestUser deve ser texto", 0).
        RETURN TRIM(cUsuario).
    END.
    RETURN "".
END FUNCTION.
/* Listas vazias sao repassadas como vazias, conforme o contrato dos setters.
   Omissao do campo preserva o padrao da BO; lista vazia nao significa omissao. */
FUNCTION lerLista RETURNS CHARACTER (INPUT pcValor AS CHARACTER, INPUT pcCampo AS CHARACTER, INPUT plLogica AS LOGICAL):
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE cItem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLista AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iCodigo AS INTEGER NO-UNDO.
    IF TRIM(pcValor) = "" THEN RETURN "".
    DO n = 1 TO NUM-ENTRIES(pcValor):
        cItem = TRIM(ENTRY(n, pcValor)).
        IF cItem = "" THEN
            UNDO, THROW NEW AppError("Lista invalida: " + pcCampo, 0).
        IF plLogica THEN DO:
            cItem = CAPS(cItem).
            IF LOOKUP(cItem, "YES,NO") = 0 THEN
                UNDO, THROW NEW AppError(pcCampo + " aceita YES, NO ou YES,NO", 0).
        END.
        ELSE DO:
            iCodigo = lerPedido(cItem, pcCampo).
            cItem = TRIM(STRING(iCodigo, ">>>>>>>>>>9")).
        END.
        IF LOOKUP(cItem, cLista) = 0 THEN
            cLista = cLista + (IF cLista = "" THEN "" ELSE ",") + cItem.
    END.
    RETURN cLista.
END FUNCTION.







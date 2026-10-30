/* Somente temp-tables: nunca publicar este programa. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttContainers NO-UNDO
  FIELD nr-container AS INTEGER
  FIELD cod-estabel AS CHARACTER
  FIELD cod-emit-forn AS INTEGER
  FIELD nome-ab-forn AS CHARACTER
  FIELD dt-recebimento AS DATE
  FIELD dt-prev-chegada AS DATE
  FIELD situacao AS INTEGER
  FIELD vl-dolar-compra AS DECIMAL DECIMALS 5
  FIELD vl-dolar-venda AS DECIMAL DECIMALS 5
  FIELD situacao_container_id AS INTEGER
  FIELD dt_prev_embarque AS DATE
  FIELD dt_real_embarque AS DATE
  FIELD num-pedido AS INTEGER
  FIELD dt-compra AS DATE
  FIELD exclusivo AS LOGICAL
  FIELD ind_dt_embarque AS INTEGER
  FIELD ind_dt_prev_chegada AS INTEGER
  FIELD log_pagto_final AS LOGICAL
  FIELD cod_agente_cargas AS INTEGER
  FIELD cod_armador AS INTEGER
  INDEX pk IS PRIMARY UNIQUE nr-container.
DEFINE TEMP-TABLE ttSituacoes NO-UNDO
  FIELD situacao_container_id AS INTEGER
  FIELD descricao AS CHARACTER
  FIELD log_gerar_saldo_a_pagar AS LOGICAL INITIAL TRUE
  FIELD log_gerar_distr_custo AS LOGICAL INITIAL TRUE
  FIELD num_ordem AS INTEGER
  INDEX pk IS PRIMARY UNIQUE situacao_container_id.
DEFINE TEMP-TABLE ttEmitente NO-UNDO
  FIELD cod-emitente AS INTEGER
  FIELD nome-abrev AS CHARACTER
  FIELD nome-emit AS CHARACTER
  INDEX pk IS PRIMARY UNIQUE cod-emitente.
DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cInvalid AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.
DEFINE VARIABLE cFailure AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

OUTPUT TO VALUE("containers-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
  RUN NewRequest("read"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"), "read vazio tem sucesso explicito").
  RUN AssertTrue(joResponse:GetJsonArray("data"):Length = 0, "read vazio devolve array").

  /* Ordem fisica propositalmente diferente de situacao/status/chave. */
  CREATE ttContainers. ASSIGN nr-container = 9 situacao = 2 ttContainers.situacao_container_id = 1.
  CREATE ttContainers. ASSIGN nr-container = 5 situacao = 1 ttContainers.situacao_container_id = 2.
  CREATE ttContainers.
  ASSIGN nr-container = 3 situacao = 1 ttContainers.situacao_container_id = 1
    cod-estabel = "001" nome-ab-forn = "São José" cod-emit-forn = 27
    dt-recebimento = DATE(10, 16, 2026) dt-prev-chegada = ?
    dt-compra = DATE(1, 2, 2026) dt_prev_embarque = DATE(2, 3, 2026)
    dt_real_embarque = DATE(3, 4, 2026)
    vl-dolar-compra = 5.12345 vl-dolar-venda = 6.54321
    exclusivo = TRUE log_pagto_final = FALSE cod_agente_cargas = 71 cod_armador = 72.
  CREATE ttContainers. ASSIGN nr-container = 2 situacao = 1 ttContainers.situacao_container_id = 1.
  CREATE ttSituacoes. ASSIGN ttSituacoes.situacao_container_id = 1 descricao = "Em trânsito".
  CREATE ttSituacoes. ASSIGN ttSituacoes.situacao_container_id = 2 descricao = "".
  CREATE ttEmitente. ASSIGN cod-emitente = 71 nome-abrev = "AÇÃO" nome-emit = "Agência São José".
  CREATE ttEmitente. ASSIGN cod-emitente = 72 nome-abrev = "MAR" nome-emit = "Navegação".

  RUN NewRequest("read"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"), "read tem sucesso explicito").
  jaRows = joResponse:GetJsonArray("data").
  RUN AssertTrue(jaRows:Length = 4, "read retorna conjunto completo").
  RUN AssertTrue(jaRows:GetJsonObject(1):GetInteger("container_id") = 2, "ordem desempata pela chave").
  RUN AssertTrue(jaRows:GetJsonObject(2):GetInteger("container_id") = 3, "ordem status e chave").
  RUN AssertTrue(jaRows:GetJsonObject(3):GetInteger("container_id") = 5, "ordem status antes chave").
  RUN AssertTrue(jaRows:GetJsonObject(4):GetInteger("container_id") = 9, "ordem situacao antes status").
  joRow = jaRows:GetJsonObject(2).
  cNames = joRow:GetNames().
  RUN AssertTrue(EXTENT(cNames) = 23, "20 campos de origem mais tres virtuais").
  RUN AssertTrue(NOT joRow:Has("nr_container"), "sem chave fisica redundante").
  RUN AssertTrue(joRow:GetType("cod_estabel") = JsonDataType:STRING AND joRow:GetCharacter("cod_estabel") = "001", "estabelecimento preserva zeros").
  RUN AssertTrue(joRow:GetCharacter("nome_ab_forn") = "São José", "acentos fornecedor").
  RUN AssertTrue(joRow:GetInteger("cod_emit_forn") = 27, "codigo fornecedor bruto").
  RUN AssertTrue(joRow:GetCharacter("dt_recebimento") = "2026-10-16", "data recebimento ISO").
  RUN AssertTrue(joRow:IsNull("dt_prev_chegada"), "data desconhecida null JSON").
  RUN AssertTrue(joRow:GetCharacter("dt_compra") = "2026-01-02", "data compra ISO").
  RUN AssertTrue(joRow:GetCharacter("dt_prev_embarque") = "2026-02-03", "data prevista ISO").
  RUN AssertTrue(joRow:GetCharacter("dt_real_embarque") = "2026-03-04", "data real ISO").
  RUN AssertTrue(joRow:GetType("vl_dolar_compra") = JsonDataType:NUMBER AND joRow:GetDecimal("vl_dolar_compra") = 5.12345, "dolar compra cinco casas numerico").
  RUN AssertTrue(joRow:GetType("vl_dolar_venda") = JsonDataType:NUMBER AND joRow:GetDecimal("vl_dolar_venda") = 6.54321, "dolar venda cinco casas numerico").
  RUN AssertTrue(joRow:GetType("exclusivo") = JsonDataType:BOOLEAN AND joRow:GetLogical("exclusivo"), "exclusivo booleano").
  RUN AssertTrue(joRow:GetType("log_pagto_final") = JsonDataType:BOOLEAN AND NOT joRow:GetLogical("log_pagto_final"), "pagamento false preservado").
  RUN AssertTrue(joRow:GetInteger("num_pedido") = 0 AND joRow:GetInteger("ind_dt_embarque") = 0 AND joRow:GetInteger("ind_dt_prev_chegada") = 0, "inteiros zero preservados").
  RUN AssertTrue(joRow:GetInteger("cod_agente_cargas") = 71 AND joRow:GetInteger("cod_armador") = 72, "IDs lookup preservados").
  RUN AssertTrue(joRow:GetCharacter("situacao_container_descricao") = "Em trânsito", "descricao status").
  RUN AssertTrue(joRow:GetCharacter("agente_cargas_nome") = "AÇÃO-Agência São José", "nome agente sem HTML").
  RUN AssertTrue(joRow:GetCharacter("armador_nome") = "MAR-Navegação", "nome armador sem HTML").
  joRow:Write(lcJson).
  RUN AssertTrue(INDEX(STRING(lcJson), "5.12345") > 0 AND INDEX(STRING(lcJson), "6.54321") > 0, "serializacao decimal independe cultura").
  joRow = jaRows:GetJsonObject(1).
  RUN AssertTrue(joRow:GetDecimal("vl_dolar_compra") = 0 AND NOT joRow:GetLogical("exclusivo"), "zero decimal e false preservados").
  RUN AssertTrue(joRow:GetCharacter("agente_cargas_nome") = "Agente de Cargas Não Encontrado", "fallback agente ausente").
  RUN AssertTrue(joRow:GetCharacter("armador_nome") = "", "fallback armador vazio sem HTML").
  RUN AssertTrue(jaRows:GetJsonObject(3):GetCharacter("situacao_container_descricao") = "Não Informado", "descricao vazia tem fallback").

  RUN NewRequest("get"). joRequest:Add("id", 3). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:GetJsonObject("data"):GetInteger("container_id") = 3, "get numerico").
  RUN NewRequest("get"). joRequest:Add("container_id", "0003"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:GetJsonObject("data"):GetInteger("container_id") = 3, "get string inteira").
  RUN NewRequest("get"). joRequest:Add("id", "3"). joRequest:Add("container_id", 3). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"), "aliases concordantes aceitos").
  RUN NewRequest("get"). joRequest:Add("id", 3). joRequest:Add("container_id", 5). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("get"). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  DO i = 1 TO NUM-ENTRIES("0,-1,2147483648,1.5,3 OR TRUE,3;DELETE,1e1,, 3 ,+3,?,null"):
    cInvalid = ENTRY(i, "0,-1,2147483648,1.5,3 OR TRUE,3;DELETE,1e1,, 3 ,+3,?,null").
    RUN NewRequest("get"). joRequest:Add("id", cInvalid). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  END.
  RUN NewRequest("get"). joRequest:Add("id", 0). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("get"). joRequest:Add("id", 1.5). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("get"). joRequest:Add("id", TRUE). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("get"). joRequest:AddNull("id"). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("get"). joRequest:Add("id", 2147483647). RUN ExecuteRequest. RUN AssertError("CONTAINER_NOT_FOUND", 404).
  RUN NewRequest("get"). joRequest:Add("id", 888). RUN ExecuteRequest. RUN AssertError("CONTAINER_NOT_FOUND", 404).
  DO i = 1 TO 6:
    cOperation = ENTRY(i, "create,update,delete,batch,READ,read OR TRUE").
    RUN NewRequest(cOperation). RUN ExecuteRequest. RUN AssertError("CONTAINER_OPERATION_INVALID", 422).
  END.
  RUN NewRequest("read"). joRequest:Add("table", "espec.pp-container"). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("read"). joRequest:Add("where", "TRUE"). RUN ExecuteRequest. RUN AssertError("CONTAINER_VALIDATION", 422).
  RUN NewRequest("read"). joRequest:Set("operation", 1). RUN ExecuteRequest. RUN AssertError("CONTAINER_OPERATION_INVALID", 422).
  joRequest = NEW JsonObject(). RUN ExecuteRequest. RUN AssertError("CONTAINER_OPERATION_INVALID", 422).

  FIND ttContainers WHERE nr-container = 9.
  ASSIGN ttContainers.situacao_container_id = 998 cod_agente_cargas = 999 cod_armador = 999.
  RUN NewRequest("get"). joRequest:Add("id", 9). RUN ExecuteRequest.
  joRow = joResponse:GetJsonObject("data").
  RUN AssertTrue(joRow:GetCharacter("situacao_container_descricao") = "Não Informado", "status inexistente fallback").
  RUN AssertTrue(joRow:GetCharacter("agente_cargas_nome") = "Agente de Cargas Não Encontrado" AND joRow:GetCharacter("armador_nome") = "", "emitente inexistente fallback").
  RUN NewRequest("read"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonArray("data"):Length = 4, "operacoes rejeitadas nao alteram registros").
  PUT UNFORMATTED "PASS " iPassed " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
  CATCH oError AS Progress.Lang.Error:
    cFailure = oError:GetMessage(1).
    PUT UNFORMATTED "FAIL " cFailure SKIP.
  END CATCH.
END.
OUTPUT CLOSE.
IF cFailure <> "" THEN RETURN ERROR cFailure.

PROCEDURE NewRequest:
  DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
  joRequest = NEW JsonObject(). joRequest:Add("operation", pcOperation).
END PROCEDURE.
PROCEDURE ExecuteRequest:
  RUN ContainersConsultaService.p (INPUT BUFFER ttContainers:HANDLE, INPUT BUFFER ttSituacoes:HANDLE, INPUT BUFFER ttEmitente:HANDLE, INPUT joRequest, OUTPUT joResponse).
END PROCEDURE.
PROCEDURE AssertTrue:
  DEFINE INPUT PARAMETER plCondition AS LOGICAL NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  IF plCondition <> TRUE OR plCondition = ? THEN UNDO, THROW NEW Progress.Lang.AppError(pcMessage, 0).
  iPassed = iPassed + 1.
END PROCEDURE.
PROCEDURE AssertError:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  DEFINE VARIABLE joError AS JsonObject NO-UNDO.
  RUN AssertTrue(NOT joResponse:GetLogical("success"), "erro sinaliza success false: " + STRING(joRequest:GetJsonText())).
  RUN AssertTrue(joResponse:Has("error") AND joResponse:GetType("error") = JsonDataType:OBJECT, "erro usa envelope sursum-programs").
  joError = joResponse:GetJsonObject("error").
  RUN AssertTrue(joError:GetCharacter("code") = pcCode, "codigo " + pcCode).
  RUN AssertTrue(joError:GetInteger("status") = piStatus, "status erro").
  RUN AssertTrue(joError:GetCharacter("message") <> "", "erro explica motivo").
  RUN AssertTrue(NOT joResponse:Has("data"), "erro nao entrega dados").
END PROCEDURE.

/* Read-only panel. All buffer handles originate in the fixed authenticated wrapper.
   No table, database, field or ABL expression may come from client JSON.
   Costs/summary/processes are intentionally outside this persisted-data service. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersoes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAnexos AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTiposAnexo AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDespesasContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresasDespesa AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDespesas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItensContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItensProcCompra AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phProcsCompra AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cKey AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iAlias AS INTEGER NO-UNDO.
DEFINE VARIABLE iCompany AS INTEGER NO-UNDO.
DEFINE VARIABLE iName AS INTEGER NO-UNDO.
DEFINE VARIABLE hRows AS HANDLE NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE lInclude AS LOGICAL NO-UNDO.

FUNCTION ReadId RETURNS INTEGER (pcName AS CHARACTER):
  DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  IF NOT poRequest:Has(pcName) OR poRequest:IsNull(pcName) THEN RETURN ?.
  CASE poRequest:GetType(pcName):
    WHEN JsonDataType:STRING THEN cText = poRequest:GetCharacter(pcName).
    WHEN JsonDataType:NUMBER THEN cText = poRequest:GetJsonText(pcName).
    OTHERWISE RETURN ?.
  END CASE.
  IF LENGTH(cText) = 0 OR LENGTH(cText) > 10 THEN RETURN ?.
  DO n = 1 TO LENGTH(cText):
    IF INDEX("0123456789",SUBSTRING(cText,n,1)) = 0 THEN RETURN ?.
  END.
  dValue = DECIMAL(cText).
  IF dValue < 1 OR dValue > 2147483647 THEN RETURN ?.
  RETURN INTEGER(dValue).
END FUNCTION.

FUNCTION AllowedName RETURNS LOGICAL (pcName AS CHARACTER):
  DEFINE VARIABLE cName AS CHARACTER CASE-SENSITIVE NO-UNDO.
  cName = pcName.
  RETURN cName = "operation" OR cName = "resource" OR cName = "container_id"
    OR cName = "id" OR (cOperation = "get" AND cName = cKey).
END FUNCTION.

FUNCTION FindFirst RETURNS LOGICAL (phBuffer AS HANDLE, pcCondition AS CHARACTER):
  DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  lFound = phBuffer:FIND-FIRST("WHERE " + pcCondition,NO-LOCK) NO-ERROR.
  DO n = 1 TO ERROR-STATUS:NUM-MESSAGES:
    IF ERROR-STATUS:GET-NUMBER(n) <> 565 THEN
      UNDO, THROW NEW Progress.Lang.AppError("Read buffer failed.",0).
  END.
  RETURN lFound.
END FUNCTION.

FUNCTION Matches RETURNS INTEGER (phBuffer AS HANDLE, pcCondition AS CHARACTER):
  DEFINE VARIABLE hCount AS HANDLE NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
    CREATE QUERY hCount.
    hCount:SET-BUFFERS(phBuffer).
    IF NOT hCount:QUERY-PREPARE("FOR EACH " + phBuffer:NAME + " NO-LOCK WHERE " + pcCondition) THEN
      UNDO, THROW NEW Progress.Lang.AppError("Count query preparation failed.",0).
    hCount:QUERY-OPEN(). hCount:GET-FIRST().
    DO WHILE NOT hCount:QUERY-OFF-END AND n < 2:
      n = n + 1. hCount:GET-NEXT().
    END.
    FINALLY:
      IF VALID-HANDLE(hCount) THEN DO:
        hCount:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hCount NO-ERROR.
      END.
    END FINALLY.
  END.
  RETURN n.
END FUNCTION.

PROCEDURE AddField:
  DEFINE INPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE INPUT PARAMETER phBuffer AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER pcField AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcPublic AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hField AS HANDLE NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dtValue AS DATE NO-UNDO.
  DEFINE VARIABLE dtmValue AS DATETIME NO-UNDO.
  DEFINE VARIABLE dtzValue AS DATETIME-TZ NO-UNDO.
  DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.
  IF NOT phBuffer:AVAILABLE THEN DO: poRow:AddNull(pcPublic). RETURN. END.
  hField = phBuffer:BUFFER-FIELD(pcField).
  IF hField:BUFFER-VALUE = ? THEN DO: poRow:AddNull(pcPublic). RETURN. END.
  CASE hField:DATA-TYPE:
    WHEN "CHARACTER" THEN DO: cValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,cValue). END.
    WHEN "INTEGER" THEN DO: iValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,iValue). END.
    WHEN "DECIMAL" THEN DO: dValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,dValue). END.
    WHEN "DATE" THEN DO: dtValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,dtValue). END.
    WHEN "DATETIME" THEN DO: dtmValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,dtmValue). END.
    WHEN "DATETIME-TZ" THEN DO: dtzValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,dtzValue). END.
    WHEN "LOGICAL" THEN DO: lValue = hField:BUFFER-VALUE. poRow:Add(pcPublic,lValue). END.
    OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Unexpected field type.",0).
  END CASE.
END PROCEDURE.

PROCEDURE BuildRow:
  DEFINE OUTPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cPublic AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iLookup AS INTEGER NO-UNDO.
  DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
  DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
  DEFINE VARIABLE dPrev AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dNegotiated AS DECIMAL NO-UNDO.
  DEFINE VARIABLE iCost AS INTEGER NO-UNDO.
  poRow = NEW JsonObject().
  DO n = 1 TO NUM-ENTRIES(cFields):
    cField = ENTRY(n,cFields).
    cPublic = IF cField = "nr-container" THEN "container_id" ELSE REPLACE(cField,"-","_").
    RUN AddField(poRow,hRows,cField,cPublic).
  END.
  CASE cResource:
    WHEN "versoes" THEN DO:
      iLookup = hRows:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE.
      IF iLookup = 1 THEN poRow:Add("situacao_descricao","Incompleto").
      ELSE IF iLookup = 2 THEN poRow:Add("situacao_descricao","Completo").
      ELSE poRow:AddNull("situacao_descricao").
    END.
    WHEN "anexos" THEN DO:
      cPath = hRows:BUFFER-FIELD("caminho_arquivo"):BUFFER-VALUE.
      poRow:Add("tem_arquivo",cPath <> ? AND LENGTH(TRIM(cPath)) > 0).
      iLookup = hRows:BUFFER-FIELD("tipos_anexo_id"):BUFFER-VALUE.
      phTiposAnexo:BUFFER-RELEASE().
      IF iLookup <> ? THEN lFound = FindFirst(phTiposAnexo,phTiposAnexo:NAME + ".tipo_anexo_id = " + TRIM(STRING(iLookup))).
      RUN AddField(poRow,phTiposAnexo,"descricao","tipo_anexo_descricao").
    END.
    WHEN "despesas" THEN DO:
      /* Eligibility performed before BuildRow; these are the matching join buffers. */
      RUN AddField(poRow,phDespesas,"descricao","descricao").
      RUN AddField(poRow,phDespesas,"ordem","ordem").
      poRow:Add("empresa_id",iCompany).
      RUN AddField(poRow,phEmpresasDespesa,"log_custo","log_custo").
      ASSIGN dPrev = hRows:BUFFER-FIELD("vl_prev"):BUFFER-VALUE
             dNegotiated = hRows:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE
             iCost = phEmpresasDespesa:BUFFER-FIELD("log_custo"):BUFFER-VALUE.
      IF dPrev = ? OR dNegotiated = ? THEN poRow:AddNull("vl_distr").
      ELSE poRow:Add("vl_distr",dPrev - dNegotiated).
      IF iCost = 1 AND dNegotiated <> 0 AND dNegotiated <> ? THEN DO:
        IF dPrev = ? THEN poRow:AddNull("vl_a_distr").
        ELSE poRow:Add("vl_a_distr",MAXIMUM(0,dNegotiated - dPrev)).
      END.
      ELSE poRow:Add("vl_a_distr",0).
    END.
    WHEN "itens" THEN DO:
      iLookup = hRows:BUFFER-FIELD("item_proc_compra_id"):BUFFER-VALUE.
      phItensProcCompra:BUFFER-RELEASE(). phProcsCompra:BUFFER-RELEASE().
      IF iLookup <> ? THEN lFound = FindFirst(phItensProcCompra,phItensProcCompra:NAME + ".item_proc_compra_id = " + TRIM(STRING(iLookup))).
      RUN AddField(poRow,phItensProcCompra,"descricao","descricao_item").
      RUN AddField(poRow,phItensProcCompra,"codigo_erp","codigo_erp").
      RUN AddField(poRow,phItensProcCompra,"unid_medida","unid_medida").
      RUN AddField(poRow,phItensProcCompra,"proc_compra_id","proc_compra_id").
      IF phItensProcCompra:AVAILABLE THEN DO:
        iLookup = phItensProcCompra:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE.
        IF iLookup <> ? THEN lFound = FindFirst(phProcsCompra,phProcsCompra:NAME + ".proc_compra_id = " + TRIM(STRING(iLookup))).
      END.
      RUN AddField(poRow,phProcsCompra,"cod_proc_fornec","cod_proc_fornec").
      RUN AddField(poRow,phProcsCompra,"fornecedor_id","fornecedor_id").
      RUN AddField(poRow,phProcsCompra,"empresa_id","empresa_pedido_id").
    END.
  END CASE.
END PROCEDURE.

poResponse = NEW JsonObject().
DO ON ERROR UNDO, THROW:
  IF NOT VALID-HANDLE(phContainer) OR NOT VALID-OBJECT(poRequest) THEN DO:
    RUN Fail("CONTAINER_CONFIGURATION","Painel indisponivel.",500). RETURN.
  END.
  IF NOT poRequest:Has("operation") THEN DO:
    RUN Fail("CONTAINER_OPERATION_INVALID","Informe read ou get.",422). RETURN.
  END.
  IF poRequest:GetType("operation") <> JsonDataType:STRING THEN DO:
    RUN Fail("CONTAINER_OPERATION_INVALID","Operacao invalida.",422). RETURN.
  END.
  cOperation = poRequest:GetCharacter("operation").
  IF cOperation <> "read" AND cOperation <> "get" THEN DO:
    RUN Fail("CONTAINER_OPERATION_INVALID","O painel aceita somente read e get.",422). RETURN.
  END.
  IF NOT poRequest:Has("resource") THEN DO:
    RUN Fail("CONTAINER_RESOURCE_INVALID","Informe o recurso.",422). RETURN.
  END.
  IF poRequest:GetType("resource") <> JsonDataType:STRING THEN DO:
    RUN Fail("CONTAINER_RESOURCE_INVALID","Recurso invalido.",422). RETURN.
  END.
  cResource = poRequest:GetCharacter("resource").
  CASE cResource:
    WHEN "painel" THEN ASSIGN hRows = phContainer cKey = "container_id"
      cFields = "cod-estabel,nr-container,num-pedido,nome-ab-forn,cod-emit-forn,comprador,narrativa,usuario,dt-compra,dt-prev-chegada,dt-recebimento,situacao,char-1,dec-1,int-1,log-1,data-1,vlr-frete,vlr-seguro,vlr-despesas,exclusivo,vl-dolar-venda,vl-dolar-compra,log_liberar_custo_realizado,medidas_container,dt_prev_embarque,dt_real_embarque,ind_dt_embarque,situacao_container_id,ind_dt_prev_chegada,log_pagto_final,cod_agente_cargas,cod_armador,cod_tipo_calculo,perc_custo,vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar,log_versao_custo_desatualizada,dt_hr_ult_alt_versao_custo,ptax,cod-depos,dt_prev_chegada_loja,estacao,num_origem,log_rota_indefinida".
    WHEN "versoes" THEN ASSIGN hRows = phVersoes cKey = "versao_id"
      cFields = "versao_id,dt_hr_versao,cod_usuario,descricao,ind_sit_versao,vl_dolar_compra,vl_desconto_utiliz_dolar,vl_desconto_utiliz_real,tipo_versao_id,container_id,vl_dolar_medio,vl_dolar_di,usuario_id,log_gerar_saldo_a_pagar,log_gerar_distr_custo,situacao_container_id,desc_sit_container,cod_tipo_cotacao,vl_cotacao,data_ref_cotacao,perc_fixo_container,hist_dolar".
    WHEN "anexos" THEN ASSIGN hRows = phAnexos cKey = "anexo_container_id"
      cFields = "anexo_container_id,container_id,item_container_id,descricao,tipos_anexo_id,dt_hr_arquivo".
    WHEN "despesas" THEN ASSIGN hRows = phDespesasContainer cKey = "despesa_container_id"
      cFields = "despesa_container_id,despesa_id,vl_prev,container_id,calc_imp_container_id,vl_base_imp,vl_negociado,vl_proforma,cta_corren_custo_distr_id,log_utilizado,log_manual,perc_calc,memoria_calculo,item_container_id".
    WHEN "itens" THEN ASSIGN hRows = phItensContainer cKey = "item_container_id"
      cFields = "item_container_id,container_id,item_proc_compra_id,qt_alocada,qt_confirm_emb,qt_recbto_fisico,log_rec_doc_prazo_emb,observacao,cod_tipo_calculo,perc_custo,log_calc_icms,log_calc_ipi,perc_icms,perc_ipi,preco_liquida_ima".
    OTHERWISE DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Recurso invalido.",422). RETURN. END.
  END CASE.
  cNames = poRequest:GetNames().
  DO iName = 1 TO EXTENT(cNames):
    IF NOT AllowedName(cNames[iName]) THEN DO:
      RUN Fail("CONTAINER_VALIDATION","Campo nao permitido na consulta.",422). RETURN.
    END.
  END.
  iContainer = ReadId("container_id").
  IF iContainer = ? THEN DO:
    RUN Fail("CONTAINER_VALIDATION","Informe container_id inteiro positivo valido.",422). RETURN.
  END.
  IF cOperation = "read" AND poRequest:Has("id") THEN DO:
    RUN Fail("CONTAINER_VALIDATION","id exige operacao get.",422). RETURN.
  END.
  IF cOperation = "get" THEN DO:
    iId = IF cResource = "painel" AND NOT poRequest:Has("id") THEN iContainer ELSE ReadId("id").
    IF iId = ? OR (cResource = "painel" AND iId <> iContainer) THEN DO:
      RUN Fail("CONTAINER_VALIDATION","Informe id valido e consistente com o contexto.",422). RETURN.
    END.
    IF cResource <> "painel" AND poRequest:Has(cKey) THEN DO:
      iAlias = ReadId(cKey).
      IF iAlias = ? OR iAlias <> iId THEN DO:
        RUN Fail("CONTAINER_VALIDATION","Alias da chave conflitante.",422). RETURN.
      END.
    END.
  END.
  /* Master is validated before any lookup/child query. */
  IF NOT FindFirst(phContainer,phContainer:NAME + ".nr-container = " + TRIM(STRING(iContainer))) THEN DO:
    RUN Fail("CONTAINER_NOT_FOUND","Container nao encontrado.",404). RETURN.
  END.
  IF NOT VALID-HANDLE(hRows) THEN UNDO, THROW NEW Progress.Lang.AppError("Missing resource buffer.",0).
  IF cResource = "anexos" AND NOT VALID-HANDLE(phTiposAnexo) THEN UNDO, THROW NEW Progress.Lang.AppError("Missing type buffer.",0).
  IF cResource = "itens" AND (NOT VALID-HANDLE(phItensProcCompra) OR NOT VALID-HANDLE(phProcsCompra)) THEN
    UNDO, THROW NEW Progress.Lang.AppError("Missing purchase buffers.",0).
  IF cResource = "despesas" THEN DO:
    IF NOT VALID-HANDLE(phEmpresas) OR NOT VALID-HANDLE(phEmpresasDespesa) OR NOT VALID-HANDLE(phDespesas) THEN
      UNDO, THROW NEW Progress.Lang.AppError("Missing company buffers.",0).
    cPrefix = phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
    IF cPrefix = ? OR LENGTH(cPrefix) = 0 THEN DO:
      RUN Fail("CONTAINER_COMPANY_CONTEXT","Estabelecimento sem empresa identificavel.",422). RETURN.
    END.
    cPrefix = SUBSTRING(cPrefix,1,1).
    IF INDEX("0123456789",cPrefix) = 0 THEN DO:
      RUN Fail("CONTAINER_COMPANY_CONTEXT","Estabelecimento sem empresa identificavel.",422). RETURN.
    END.
    cWhere = phEmpresas:NAME + ".cod_emp_ems2 = " + cPrefix.
    IF Matches(phEmpresas,cWhere) <> 1 THEN DO:
      RUN Fail("CONTAINER_COMPANY_CONTEXT","Empresa do estabelecimento ausente ou ambigua.",422). RETURN.
    END.
    lInclude = FindFirst(phEmpresas,cWhere).
    iCompany = phEmpresas:BUFFER-FIELD("empresa_id"):BUFFER-VALUE.
    IF iCompany = ? THEN DO:
      RUN Fail("CONTAINER_COMPANY_CONTEXT","Empresa do estabelecimento invalida.",422). RETURN.
    END.
  END.
  IF cResource = "painel" THEN DO:
    RUN BuildRow(OUTPUT joRow).
    IF cOperation = "get" THEN DO: poResponse:Add("success",TRUE). poResponse:Add("data",joRow). RETURN. END.
    jaRows = NEW JsonArray(). jaRows:Add(joRow).
  END.
  ELSE DO:
    CREATE QUERY hQuery.
    hQuery:SET-BUFFERS(hRows).
    cWhere = hRows:NAME + ".container_id = " + TRIM(STRING(iContainer)).
    IF cOperation = "get" THEN cWhere = cWhere + " AND " + hRows:NAME + "." + cKey + " = " + TRIM(STRING(iId)).
    IF NOT hQuery:QUERY-PREPARE("FOR EACH " + hRows:NAME + " NO-LOCK WHERE " + cWhere + " BY " + hRows:NAME + "." + cKey) THEN
      UNDO, THROW NEW Progress.Lang.AppError("Read query preparation failed.",0).
    hQuery:QUERY-OPEN(). hQuery:GET-FIRST().
    jaRows = NEW JsonArray().
    DO WHILE NOT hQuery:QUERY-OFF-END:
      lInclude = TRUE.
      IF cResource = "despesas" THEN DO:
        iAlias = hRows:BUFFER-FIELD("despesa_id"):BUFFER-VALUE.
        IF iAlias = ? THEN lInclude = FALSE.
        ELSE DO:
          cWhere = phEmpresasDespesa:NAME + ".empresa_id = " + TRIM(STRING(iCompany))
            + " AND " + phEmpresasDespesa:NAME + ".despesa_id = " + TRIM(STRING(iAlias)).
          iName = Matches(phEmpresasDespesa,cWhere).
          IF iName > 1 THEN DO:
            RUN Fail("CONTAINER_COMPANY_CONTEXT","Despesa com configuracao de empresa ambigua.",422). RETURN.
          END.
          lInclude = iName = 1.
          IF lInclude THEN lInclude = FindFirst(phEmpresasDespesa,cWhere).
          IF lInclude THEN lInclude = FindFirst(phDespesas,phDespesas:NAME + ".despesa_id = " + TRIM(STRING(iAlias))).
        END.
      END.
      IF lInclude THEN DO:
        RUN BuildRow(OUTPUT joRow).
        IF cOperation = "get" THEN DO:
          poResponse:Add("success",TRUE). poResponse:Add("data",joRow). RETURN.
        END.
        jaRows:Add(joRow).
      END.
      hQuery:GET-NEXT().
    END.
    IF cOperation = "get" THEN DO:
      RUN Fail("CONTAINER_CHILD_NOT_FOUND","Registro nao encontrado neste container.",404). RETURN.
    END.
  END.
  poResponse:Add("success",TRUE). poResponse:Add("data",jaRows).
  CATCH e AS Progress.Lang.Error:
    RUN Fail("CONTAINER_INTERNAL","Nao foi possivel consultar o painel.",500).
  END CATCH.
  FINALLY:
    IF VALID-HANDLE(hQuery) THEN DO:
      hQuery:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hQuery NO-ERROR.
    END.
  END FINALLY.
END.
PROCEDURE Fail:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  DEFINE VARIABLE joError AS JsonObject NO-UNDO.
  IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
  poResponse = NEW JsonObject(). joError = NEW JsonObject().
  poResponse:Add("success",FALSE).
  joError:Add("code",pcCode). joError:Add("message",pcMessage). joError:Add("status",piStatus).
  poResponse:Add("error",joError).
END PROCEDURE.

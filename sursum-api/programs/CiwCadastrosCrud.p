/* Entrada de recursos fechados CIW. Transporte autenticado pelo backend atual;
   integracao adicional das permissoes legadas ficou para o final por instrucao. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hData AS HANDLE NO-UNDO.
DEFINE VARIABLE hReference1 AS HANDLE NO-UNDO.
DEFINE VARIABLE hReference2 AS HANDLE NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDefinition AS CHARACTER NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER NO-UNDO.
DEFINE VARIABLE cActor AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSession AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE cleanRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE cMedCompany AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMedResolver AS CHARACTER NO-UNDO.
FUNCTION ValidHeader RETURNS LOGICAL (v AS CHARACTER):
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF v=? OR v="" OR LENGTH(v)>256 THEN RETURN FALSE.
 DO n = 1 TO LENGTH(v):
  IF ASC(SUBSTRING(v,n,1))<32 OR ASC(SUBSTRING(v,n,1))=127 THEN RETURN FALSE.
 END.
 RETURN TRUE.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 cToken=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_CIW_CADASTROS_TOKEN") NO-ERROR.
 IF cToken=? THEN cToken="".
 IF LENGTH(cToken)<32 OR LENGTH(cToken)>128 THEN DO: RUN ErrorResponse("CIW_CADASTRO_AUTH_REQUIRED",401). RETURN. END.
 cConfig=SEARCH("sursum-conf/ciw-cadastros-api.json").
 cService=SEARCH("sursum-api/programs/CiwCadastroCrudService.r").
 cDefinition=SEARCH("sursum-api/programs/CiwCadastroDefinition.r").
 IF cConfig=? OR cService=? OR cDefinition=? THEN UNDO,THROW NEW Progress.Lang.AppError("Configuracao ausente",0).
 FIX-CODEPAGE(lcConfig)="UTF-8". COPY-LOB FROM FILE cConfig TO lcConfig.
 parser=NEW ObjectModelParser(). cfg=CAST(parser:Parse(lcConfig),JsonObject).
 IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cToken)))<>CAPS(cfg:GetCharacter("tokenSha256")) THEN DO: RUN ErrorResponse("CIW_CADASTRO_AUTH_REQUIRED",401). RETURN. END.
 IF NOT VALID-OBJECT(poRequest) THEN DO: RUN ErrorResponse("CIW_CADASTRO_VALIDATION",422). RETURN. END.
 IF NOT poRequest:Has("resource") OR poRequest:GetType("resource")<>JsonDataType:STRING OR NOT poRequest:Has("operation") OR poRequest:GetType("operation")<>JsonDataType:STRING THEN DO: RUN ErrorResponse("CIW_CADASTRO_VALIDATION",422). RETURN. END.
 cResource=poRequest:GetCharacter("resource"). cOperation=poRequest:GetCharacter("operation").
 IF NOT CONNECTED("espec") THEN UNDO,THROW NEW Progress.Lang.AppError("Banco indisponivel",0).
 IF LOOKUP(cOperation,"read,get")=0 AND NOT (cResource="proc_compra_itens" AND cOperation="options") THEN DO:
  cActor=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_SURSUM_USER") NO-ERROR.
  cSession=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_SESSION_ID") NO-ERROR.
  IF NOT ValidHeader(cActor) OR NOT ValidHeader(cSession) THEN DO: RUN ErrorResponse("CIW_CADASTRO_IDENTITY_REQUIRED",401). RETURN. END.
 END.
 CASE cResource:
  WHEN "despesas_impostos_geral" THEN DO:
   IF cOperation<>"read" AND cOperation<>"get" THEN DO: RUN ErrorResponse("CIW_ERP_READ_ONLY",405). RETURN. END.
   cService=SEARCH("sursum-api/programs/CiwErpReadService.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Leitor de relacoes despesa/imposto indisponivel",1).
   CREATE BUFFER hData FOR TABLE "espec.despesas_impostos" BUFFER-NAME "bCiwExpenseTaxRelations".
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(hData,"despesas_impostos_geral","",cleanRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "container_custos_comparacao_real" OR WHEN "container_custos_comparacao_dolar" THEN DO:
   IF cOperation<>"read" AND cOperation<>"get" THEN DO: RUN ErrorResponse("CIW_ERP_READ_ONLY",405). RETURN. END.
   cService=SEARCH("sursum-api/programs/ContainersVersionComparisonApi.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Comparison API unavailable",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "item_custos_manual" THEN DO:
   IF cOperation<>"read" AND cOperation<>"get" THEN DO: RUN ErrorResponse("CIW_ERP_READ_ONLY",405). RETURN. END.
   cService=SEARCH("sursum-api/programs/CiwErpReadService.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Leitor de custos manuais indisponivel",1).
   CREATE BUFFER hData FOR TABLE "espec.item_custos" BUFFER-NAME "bCiwManualItemCosts".
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(hData,"item_custos_manual","",cleanRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "item_container_amostra" THEN DO:
   cService=SEARCH("sursum-api/programs/SampleContainerItemsReadApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de itens de amostra indisponivel.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "import_descontos_geral" OR WHEN "import_descontos_lancamentos" THEN DO:
   cService=SEARCH("sursum-api/programs/ImportDiscountsReadApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de descontos indisponivel.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "custo_distribuicao_itens_aptos" THEN DO:
   cService=SEARCH("sursum-api/programs/CostDistributionEligibleReadApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de itens aptos indisponivel.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "custo_distribuicao_lancamentos_item" THEN DO:
   cService=SEARCH("sursum-api/programs/CostDistributionLedgerReadApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de itens aptos indisponivel.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "container_versao_pagtos_historico_med" OR WHEN "container_versao_nfs_historico_med" OR WHEN "container_versao_descontos_historico_med" OR WHEN "container_versao_despesas_historico_med" THEN DO:
   cService=SEARCH("sursum-api/programs/ContainersVersionAuxHistoryApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Historical auxiliary API unavailable",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "container_calculos_impostos_med" OR WHEN "container_despesa_memoria_med" THEN DO:
   cService=SEARCH("sursum-api/programs/ContainerFiscalReadOnlyApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta fiscal readonly indisponivel.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "container_versoes_historico_med" THEN DO:
   cService=SEARCH("sursum-api/programs/ContainersVersionHistoryApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Historical version API unavailable",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_quantidades_periodo_med" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseQuantityPeriodsApi.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Consulta por periodo indisponivel",0).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_quantidades" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseImportQuantitiesApi.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Alertas indisponiveis",0).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_sinalizadores" OR WHEN "proc_compra_sinalizados" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseSignalsGlobalApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Signal global API unavailable",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_alertas" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseSignalsApi.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Alertas indisponiveis",0).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_alocacoes" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseItemAllocationsApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de alocacoes nao publicada.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_resumo" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseSummaryApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Resumo nao publicado.",1).
   RUN VALUE(cService)(poRequest,OUTPUT poResponse). RETURN.
  END.
   WHEN "proc_compra_documentos" THEN DO:
    cService=SEARCH("sursum-api/programs/PurchaseOrderAttachmentsApi.r").
    IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Anexos do processo nao publicados.",0).
    RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse). RETURN.
   END.
  WHEN "proc_compra_anexos" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseItemAttachmentsApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Anexos de itens nao publicados.",0).
   RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse). RETURN.
  END.
  WHEN "proc_compra_despesas" THEN DO:
   cService=SEARCH(IF cOperation="calculate_taxes" THEN "sursum-api/programs/PurchaseTaxesApi.r" ELSE "sursum-api/programs/PurchaseExpensesApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico de despesas nao publicado.",1).
   RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "proc_compra_amostras" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseSamplesApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Envios de amostras nao publicados.",0).
   RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse). RETURN.
  END.

  WHEN "proc_compra_itens" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseItemsApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Itens de processos nao publicados.",0).
   RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse). RETURN.
  END.
  WHEN "procs_compra_med" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseOrdersApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Cadastro de processos nao publicado.",0).
   RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse). RETURN.
  END.
  WHEN "procs_compra_financeiro_med" OR WHEN "proc_compra_pagamentos" OR WHEN "proc_compra_titulos_disponiveis" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchasePaymentsApi.r").
   IF cService=? THEN UNDO, THROW NEW Progress.Lang.AppError("Seletor de pagamentos nao publicado.",0).
   RUN VALUE(cService)(poRequest,cActor,OUTPUT poResponse). RETURN.
  END.
  WHEN "notas_fiscais_med" OR WHEN "titulos_pagar_med" THEN DO:
   cService=SEARCH("sursum-api/programs/CiwErpReadService.r"). cMedResolver=SEARCH("sursum-api/programs/CiwMedCompanyContext.r").
   IF cService=? OR cMedResolver=? THEN UNDO,THROW NEW Progress.Lang.AppError("Consulta MED indisponivel",0).
   CREATE BUFFER hReference1 FOR TABLE "espec.empresas" BUFFER-NAME "bCiwErpMedEmpresas".
   RUN VALUE(cMedResolver)(INPUT hReference1,OUTPUT cMedCompany).
   IF cResource="notas_fiscais_med" THEN DO:
    IF NOT CONNECTED("ems2med") THEN UNDO,THROW NEW Progress.Lang.AppError("Banco MED indisponivel",0).
    CREATE BUFFER hData FOR TABLE "ems2med.nota-fiscal" BUFFER-NAME "bCiwErpMedNf".
   END.
   ELSE DO:
    IF NOT CONNECTED("ems5") THEN UNDO,THROW NEW Progress.Lang.AppError("Banco financeiro indisponivel",0).
    CREATE BUFFER hData FOR TABLE "ems5.tit_ap" BUFFER-NAME "bCiwErpMedTitle".
   END.
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(INPUT hData,INPUT cResource,INPUT cMedCompany,INPUT cleanRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "itens" OR WHEN "representantes_ativos" THEN DO:
   cService=SEARCH("sursum-api/programs/CiwReferenciasService.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
   IF cResource="itens" THEN DO:
    IF NOT CONNECTED("ems2med") THEN UNDO,THROW NEW Progress.Lang.AppError("Banco indisponivel",0).
    CREATE BUFFER hData FOR TABLE "ems2med.item" BUFFER-NAME "bCiwItem".
   END.
   ELSE DO:
    IF NOT CONNECTED("ems5") THEN UNDO,THROW NEW Progress.Lang.AppError("Banco indisponivel",0).
    CREATE BUFFER hData FOR TABLE "ems5.representante" BUFFER-NAME "bCiwRepresentante".
   END.
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(INPUT hData,INPUT cResource,INPUT cleanRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "fornecedores" OR WHEN "fornecedores_estrangeiros" THEN DO:
   cService=SEARCH("sursum-api/programs/CiwFornecedoresService.r").
   IF cService=? OR NOT CONNECTED("ems2cad") THEN UNDO,THROW NEW Progress.Lang.AppError("Consulta indisponivel",0).
   CREATE BUFFER hData FOR TABLE "ems2cad.emitente" BUFFER-NAME "bCiwFornecedor".
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(INPUT hData,INPUT cResource,INPUT cleanRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "hist_cotacoes_bc" THEN DO:
   cService=SEARCH("sursum-api/programs/CiwCotacoesService.r").
   IF cService=? OR SEARCH("sursum-api/programs/ContainerCostInvalidation.r")=? THEN UNDO,THROW NEW Progress.Lang.AppError("Cotacoes indisponiveis",0).
   CREATE BUFFER hData FOR TABLE "espec.hist_cotacoes_bc" BUFFER-NAME "bCiwCotacao".
   CREATE BUFFER hReference1 FOR TABLE "espec.pp-container" BUFFER-NAME "bCiwCotacaoContainer".
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(INPUT hData,INPUT hReference1,INPUT THIS-PROCEDURE,INPUT cleanRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "estoque_termos" THEN DO:
   cService=SEARCH("sursum-api/programs/EstoqueTermosCrudService.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Cadastro de equivalencias indisponivel",0).
   CREATE BUFFER hData FOR TABLE "espec.estoque_termo_busca" BUFFER-NAME "bEstoqueTermo".
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(INPUT hData,INPUT cleanRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "im_param" THEN DO:
   cService=SEARCH("sursum-api/programs/CiwParametrosService.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Editor indisponivel",0).
   CREATE BUFFER hData FOR TABLE "espec.im-param" BUFFER-NAME "bCiwParametro".
   cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
   RUN VALUE(cService)(INPUT hData,INPUT cleanRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "sinalizadores_importacao" THEN DO:
   cService=SEARCH("sursum-api/programs/PurchaseSignalConfigApi.r").
   IF cService=? THEN UNDO,THROW NEW Progress.Lang.AppError("Sinalizadores indisponiveis",0).
   RUN VALUE(cService)(INPUT poRequest,OUTPUT poResponse).
   RETURN.
  END.
  WHEN "formatos_amostra" THEN DO:
   CREATE BUFFER hData FOR TABLE "espec.formatos_amostra" BUFFER-NAME "bCiwFormatoAmostra".
   CREATE BUFFER hReference1 FOR TABLE "espec.itens_proc_compra" BUFFER-NAME "bCiwFormatoItem".
  END.
  WHEN "coloracoes" THEN DO:
   CREATE BUFFER hData FOR TABLE "espec.coloracoes" BUFFER-NAME "bCiwColoracao".
   CREATE BUFFER hReference1 FOR TABLE "espec.itens_proc_compra" BUFFER-NAME "bCiwColoracaoItem".
  END.
  WHEN "situacoes_container" THEN DO:
   CREATE BUFFER hData FOR TABLE "espec.situacoes_container" BUFFER-NAME "bCiwSituacao".
   CREATE BUFFER hReference1 FOR TABLE "espec.pp-container" BUFFER-NAME "bCiwSituacaoContainer".
   CREATE BUFFER hReference2 FOR TABLE "espec.versoes_item_custo_container" BUFFER-NAME "bCiwSituacaoVersao".
  END.
  WHEN "tipos_versao_custo" THEN CREATE BUFFER hData FOR TABLE "espec.tipos_versao_custo" BUFFER-NAME "bCiwTipoVersao".
  WHEN "motivos_desconto" THEN DO:
   CREATE BUFFER hData FOR TABLE "espec.motivos_desconto" BUFFER-NAME "bCiwMotivo".
   CREATE BUFFER hReference1 FOR TABLE "espec.descontos_importacao" BUFFER-NAME "bCiwMotivoDesconto".
  END.
  OTHERWISE DO: RUN ErrorResponse("CIW_CADASTRO_RESOURCE_INVALID",422). RETURN. END.
 END CASE.
 RUN VALUE(cDefinition)(INPUT cResource,OUTPUT policy).
 cleanRequest=CAST(poRequest:Clone(),JsonObject). cleanRequest:Remove("resource").
 RUN VALUE(cService)(INPUT hData,INPUT hReference1,INPUT hReference2,INPUT policy,INPUT cleanRequest,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  RUN ErrorResponse("CIW_CADASTRO_CONFIGURATION",503).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hData) THEN DELETE OBJECT hData NO-ERROR.
  IF VALID-HANDLE(hReference1) THEN DELETE OBJECT hReference1 NO-ERROR.
  IF VALID-HANDLE(hReference2) THEN DELETE OBJECT hReference2 NO-ERROR.
  IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
  IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
  IF VALID-OBJECT(cleanRequest) THEN DELETE OBJECT cleanRequest.
 END FINALLY.
END.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add("code",c). err:Add("status",s).
 err:Add("message","Solicitacao recusada ou cadastro indisponivel."). poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.

PROCEDURE NextCotacaoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 valueId=DYNAMIC-NEXT-VALUE("seq_hist_cotacao_bc","espec").
END PROCEDURE.

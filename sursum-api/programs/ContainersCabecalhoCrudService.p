/* Header CRUD. Composite business rules are mandatory trusted callbacks inside
   this service's transaction. No default/no-op fiscal or delete implementation. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phFornecedor AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuleProvider AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cFailure AS CHARACTER NO-UNDO INITIAL "CONTAINER_VALIDATION".
DEFINE VARIABLE cWritable AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSnapshot AS CHARACTER NO-UNDO.
DEFINE VARIABLE cField AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cPhysical AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCallback AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCompany AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cInputNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE iAlias AS INTEGER NO-UNDO.
DEFINE VARIABLE iFornecedor AS INTEGER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE lStale AS LOGICAL NO-UNDO.
DEFINE VARIABLE dt AS DATE NO-UNDO.
DEFINE VARIABLE oValues AS JsonObject NO-UNDO.
DEFINE VARIABLE oBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE oAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE oActor AS JsonObject NO-UNDO.
DEFINE VARIABLE oCapabilities AS JsonObject NO-UNDO.
DEFINE VARIABLE oContext AS JsonObject NO-UNDO.
DEFINE VARIABLE oRules AS JsonObject NO-UNDO.
DEFINE VARIABLE oAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE aChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE aRuleWarnings AS JsonArray NO-UNDO.
DEFINE VARIABLE hField AS HANDLE NO-UNDO.

FUNCTION Physical RETURNS CHARACTER (pcPublic AS CHARACTER):
 IF pcPublic="container_id" THEN RETURN "nr-container".
 IF LOOKUP(pcPublic,"cod_estabel,num_pedido,nome_ab_forn,cod_emit_forn,dt_compra,dt_prev_chegada,dt_recebimento,char_1,dec_1,int_1,log_1,data_1,vlr_frete,vlr_seguro,vlr_despesas,vl_dolar_venda,vl_dolar_compra,cod_depos")>0 THEN RETURN REPLACE(pcPublic,"_","-").
 RETURN pcPublic.
END FUNCTION.
FUNCTION ExactList RETURNS LOGICAL (pcName AS CHARACTER,pcList AS CHARACTER):
 DEFINE VARIABLE name AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 name=pcName.
 DO k=1 TO NUM-ENTRIES(pcList): IF name=ENTRY(k,pcList) THEN RETURN TRUE. END.
 RETURN FALSE.
END FUNCTION.
FUNCTION Id RETURNS INTEGER (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 IF NOT o:Has(f) THEN RETURN ?.
 CASE o:GetType(f):
  WHEN JsonDataType:NUMBER THEN cText=o:GetJsonText(f).
  WHEN JsonDataType:STRING THEN cText=o:GetCharacter(f).
  OTHERWISE RETURN ?.
 END CASE.
 IF LENGTH(cText)<1 OR LENGTH(cText)>10 THEN RETURN ?.
 DO k=1 TO LENGTH(cText): IF INDEX("0123456789",SUBSTRING(cText,k,1))=0 THEN RETURN ?. END.
 d=DECIMAL(cText). IF d<1 OR d>2147483647 THEN RETURN ?. RETURN INTEGER(d).
END FUNCTION.
FUNCTION JsonRecord RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE p AS CHARACTER NO-UNDO.
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 DEFINE VARIABLE l AS LOGICAL NO-UNDO.
 DEFINE VARIABLE da AS DATE NO-UNDO.
 DEFINE VARIABLE dm AS DATETIME NO-UNDO.
 o=NEW JsonObject().
 DO k=1 TO NUM-ENTRIES(cSnapshot):
  p=ENTRY(k,cSnapshot). h=phContainer:BUFFER-FIELD(Physical(p)).
  IF h:BUFFER-VALUE=? THEN o:AddNull(p).
  ELSE CASE h:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: c=h:BUFFER-VALUE. o:Add(p,c). END.
   WHEN "INTEGER" THEN DO: i=h:BUFFER-VALUE. o:Add(p,i). END.
   WHEN "DECIMAL" THEN DO: d=h:BUFFER-VALUE. o:Add(p,d). END.
   WHEN "LOGICAL" THEN DO: l=h:BUFFER-VALUE. o:Add(p,l). END.
   WHEN "DATE" THEN DO: da=h:BUFFER-VALUE. o:Add(p,da). END.
   WHEN "DATETIME" THEN DO: dm=h:BUFFER-VALUE. o:Add(p,dm). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo de snapshot inesperado.",1).
  END CASE.
 END.
 RETURN o.
END FUNCTION.
FUNCTION FindUnique RETURNS LOGICAL (h AS HANDLE,cond AS CHARACTER):
 DEFINE VARIABLE qh AS HANDLE NO-UNDO.
 DEFINE VARIABLE r AS ROWID NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY qh. qh:SET-BUFFERS(h).
  IF NOT qh:QUERY-PREPARE("FOR EACH " + h:NAME + " NO-LOCK WHERE " + cond) THEN UNDO, THROW NEW Progress.Lang.AppError("Lookup invalido.",1).
  qh:QUERY-OPEN(). qh:GET-FIRST().
  IF qh:QUERY-OFF-END THEN RETURN FALSE.
  r=h:ROWID. qh:GET-NEXT().
  IF NOT qh:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Lookup de fornecedor/empresa ambiguo.",1).
  RETURN h:FIND-BY-ROWID(r,NO-LOCK).
  FINALLY:
   IF VALID-HANDLE(qh) THEN DO: qh:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qh NO-ERROR. END.
  END FINALLY.
 END.
END FUNCTION.

ASSIGN cWritable="cod_estabel,cod_emit_forn,narrativa,dt_recebimento,dt_prev_chegada,situacao,vl_dolar_venda,vl_dolar_compra,log_liberar_custo_realizado,medidas_container,dt_prev_embarque,dt_real_embarque,situacao_container_id,ind_dt_embarque,ind_dt_prev_chegada,ordem_busca_dolar_di,log_pagto_final,cod_agente_cargas,cod_armador,perc_custo,vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,ordem_busca_dolar_compra,cod_tipo_proj_dolar,vl_proj_dolar,ptax,cod_depos,dt_prev_chegada_loja"
       cSnapshot="cod_estabel,container_id,num_pedido,nome_ab_forn,cod_emit_forn,comprador,narrativa,usuario,dt_compra,dt_prev_chegada,dt_recebimento,situacao,char_1,dec_1,int_1,log_1,data_1,vlr_frete,vlr_seguro,vlr_despesas,exclusivo,vl_dolar_venda,vl_dolar_compra,log_liberar_custo_realizado,medidas_container,dt_prev_embarque,dt_real_embarque,ind_dt_embarque,situacao_container_id,ind_dt_prev_chegada,log_pagto_final,cod_agente_cargas,cod_armador,cod_tipo_calculo,perc_custo,vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar,log_versao_custo_desatualizada,dt_hr_ult_alt_versao_custo,ptax,cod_depos,dt_prev_chegada_loja,estacao,num_origem,log_rota_indefinida".
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError("Requisicao ausente.",1).
 cNames=poRequest:GetNames().
 DO n=1 TO EXTENT(cNames): IF NOT ExactList(cNames[n],"operation,container_id,id,values") THEN UNDO, THROW NEW Progress.Lang.AppError("Campo externo nao permitido.",1). END.
 IF NOT poRequest:Has("operation") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao necessaria.",1).
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao invalida.",1).
 cOperation=poRequest:GetCharacter("operation").
 IF NOT (cOperation="create" OR cOperation="update" OR cOperation="delete" OR cOperation="get") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao nao suportada.",1).
 iContainer=Id(poRequest,"container_id"). iAlias=Id(poRequest,"id").
 IF cOperation="create" THEN DO:
  IF iContainer=? OR poRequest:Has("id") THEN UNDO, THROW NEW Progress.Lang.AppError("Informe container_id manual para inclusao.",1).
 END.
 ELSE DO:
  IF poRequest:Has("container_id") AND iContainer=? THEN UNDO, THROW NEW Progress.Lang.AppError("container_id invalido.",1).
  IF poRequest:Has("id") AND iAlias=? THEN UNDO, THROW NEW Progress.Lang.AppError("id invalido.",1).
  IF iContainer=? THEN iContainer=iAlias.
  IF iContainer=? OR (iAlias<>? AND iAlias<>iContainer) THEN UNDO, THROW NEW Progress.Lang.AppError("Chave ausente ou conflitante.",1).
 END.
 IF cOperation="create" OR cOperation="update" THEN DO:
  IF NOT poRequest:Has("values") THEN UNDO, THROW NEW Progress.Lang.AppError("Valores necessarios.",1).
  IF poRequest:GetType("values")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto values necessario.",1).
  oValues=poRequest:GetJsonObject("values"). cInputNames=oValues:GetNames().
  IF EXTENT(cInputNames)=? OR EXTENT(cInputNames)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Nenhum campo informado.",1).
 END.
 ELSE IF poRequest:Has("values") THEN UNDO, THROW NEW Progress.Lang.AppError("Esta operacao nao recebe values.",1).
 cFailure="CONTAINER_CONFIGURATION".
 IF NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phFornecedor) OR NOT VALID-HANDLE(phEmpresas) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffers fixos indisponiveis.",1).
 DO n=1 TO NUM-ENTRIES(cSnapshot): hField=phContainer:BUFFER-FIELD(Physical(ENTRY(n,cSnapshot))). END.
 IF cOperation="get" THEN DO:
  lFound=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(iContainer),NO-LOCK) NO-ERROR.
  IF NOT lFound THEN DO: cFailure="CONTAINER_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1). END.
  poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",JsonRecord()). RETURN.
 END.
 cFailure="CONTAINER_TRANSACTION_CONTEXT".
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("CRUD requer transacao propria para confirmar snapshots apos commit.",1).
 cFailure="CONTAINER_IDENTITY_REQUIRED".
 IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Identidade autenticada obrigatoria.",1).
 IF NOT poPolicy:Has("actor") THEN UNDO, THROW NEW Progress.Lang.AppError("Ator autenticado ausente.",1).
 IF poPolicy:GetType("actor")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Ator invalido.",1).
 oActor=poPolicy:GetJsonObject("actor").
 IF NOT oActor:Has("login") THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado ausente.",1).
 IF oActor:GetType("login")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado invalido.",1).
 IF TRIM(oActor:GetCharacter("login"))="" OR LENGTH(oActor:GetCharacter("login"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado vazio/invalido.",1).
 oContext=NEW JsonObject(). oContext:Add("login",oActor:GetCharacter("login")).
 IF oActor:Has("id") THEN DO:
  IF oActor:GetType("id")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Identificador de ator deve ser opaco.",1).
  oContext:Add("id",oActor:GetCharacter("id")).
 END.
 oActor=oContext.
 cFailure="CONTAINER_VALIDATION".
 IF cOperation="create" OR cOperation="update" THEN DO:
  DO n=1 TO EXTENT(cInputNames):
   cField=cInputNames[n].
   IF NOT ExactList(cField,cWritable) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao editavel: " + cField,1).
   RUN ValidateValue(cField).
  END.
  IF cOperation="create" THEN DO:
   DO n=1 TO 5:
    cField=ENTRY(n,"cod_estabel,cod_emit_forn,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar").
    IF NOT oValues:Has(cField) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo de inclusao necessario: " + cField,1).
   END.
  END.
 END.
 IF cOperation="update" OR cOperation="delete" THEN RUN PreflightRules.
 aChanges=NEW JsonArray().
 aRuleWarnings=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  ASSIGN cFailure="CONTAINER_PERSISTENCE_REJECTED" oBefore=NEW JsonObject() oAfter=NEW JsonObject().
  IF cOperation="create" THEN DO:
   lFound=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(iContainer),NO-LOCK) NO-ERROR.
   IF lFound THEN DO: cFailure="CONTAINER_EXISTS". UNDO, THROW NEW Progress.Lang.AppError("Numero de container ja existe.",1). END.
   phContainer:BUFFER-CREATE(). phContainer:BUFFER-FIELD("nr-container"):BUFFER-VALUE=iContainer.
   phContainer:BUFFER-FIELD("situacao"):BUFFER-VALUE=1.
   phContainer:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE.
  END.
  ELSE DO:
   lFound=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(iContainer),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
   IF phContainer:LOCKED THEN DO: cFailure="CONTAINER_BUSY". UNDO, THROW NEW Progress.Lang.AppError("Container em uso.",1). END.
   IF NOT lFound THEN DO: cFailure="CONTAINER_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1). END.
   oBefore=JsonRecord().
  END.
  IF cOperation="create" OR cOperation="update" THEN DO:
   DO n=1 TO EXTENT(cInputNames): RUN AssignValue(cInputNames[n]). END.
   RUN SupplierName.
   IF cOperation="update" THEN DO:
    DO n=1 TO 6:
     cField=ENTRY(n,"vl_dolar_compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar").
     oAfter=JsonRecord().
     IF oBefore:GetJsonText(cField)<>oAfter:GetJsonText(cField) THEN lStale=TRUE.
    END.
    IF lStale THEN DO:
     phContainer:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE.
     phContainer:BUFFER-FIELD("dt_hr_ult_alt_versao_custo"):BUFFER-VALUE=DATETIME(TODAY, MTIME).
    END.
    RUN ExecuteRules.
   END.
   cFailure="CONTAINER_PERSISTENCE_REJECTED".
   IF NOT phContainer:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Cabecalho recusado pelo banco.",1).
   oAfter=JsonRecord().
  END.
  ELSE DO:
   RUN ExecuteRules.
   cFailure="CONTAINER_PERSISTENCE_REJECTED".
   IF NOT phContainer:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao recusada pelo banco.",1).
   oAfter=NEW JsonObject().
  END.
 END.
 /* JSON is NO-UNDO. Only a committed transaction is allowed to expose audit. */
 ASSIGN poResponse=NEW JsonObject() oAudit=NEW JsonObject().
 poResponse:Add("success",TRUE).
 IF cOperation<>"delete" THEN poResponse:Add("data",oAfter).
 oAudit:Add("version",1). oAudit:Add("source","progress-transaction"). oAudit:Add("resource","containers"). oAudit:Add("operation",cOperation). oAudit:Add("recordId",iContainer).
 oAudit:Add("before",oBefore). oAudit:Add("after",CAST(oAfter:Clone(),JsonObject)). oAudit:Add("changes",aChanges). oAudit:Add("actor",oActor).
 oAudit:Add("warnings",aRuleWarnings).
 poResponse:Add("audit",oAudit).
 CATCH e AS Progress.Lang.Error:
  RUN Fail(cFailure,e:GetMessage(1)).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(phContainer) THEN phContainer:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.

PROCEDURE ValidateValue:
 DEFINE INPUT PARAMETER f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE maxLen AS INTEGER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 h=phContainer:BUFFER-FIELD(Physical(f)).
 CASE h:DATA-TYPE:
  WHEN "CHARACTER" THEN DO:
   IF oValues:GetType(f)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Texto JSON necessario: " + f,1).
   cText=oValues:GetCharacter(f).
   maxLen=IF f="narrativa" THEN 100 ELSE IF f="cod_estabel" THEN 3 ELSE IF f="cod_depos" THEN 8 ELSE 20.
   IF LENGTH(cText)>maxLen THEN UNDO, THROW NEW Progress.Lang.AppError("Texto excede limite: " + f,1).
   IF f="cod_estabel" AND (cText="" OR (SUBSTRING(cText,1,1)<>"1" AND SUBSTRING(cText,1,1)<>"5")) THEN UNDO, THROW NEW Progress.Lang.AppError("Estabelecimento invalido.",1).
   IF f="ordem_busca_dolar_compra" OR f="ordem_busca_dolar_di" THEN DO:
    IF cText="" THEN UNDO, THROW NEW Progress.Lang.AppError("Ordem de cotacao obrigatoria.",1).
    DO k=1 TO NUM-ENTRIES(cText): IF LOOKUP(ENTRY(k,cText),"1,2,3,4")=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Prioridade de cotacao invalida.",1). END.
   END.
  END.
  WHEN "INTEGER" THEN DO:
   IF oValues:GetType(f)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro JSON necessario: " + f,1).
   amount=oValues:GetDecimal(f).
   IF amount<0 OR amount>2147483647 OR amount<>TRUNCATE(amount,0) THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro fora do limite: " + f,1).
   IF f="cod_emit_forn" AND amount=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Fornecedor obrigatorio.",1).
   IF f="cod_tipo_proj_dolar" AND LOOKUP(STRING(INTEGER(amount)),"1,2,3")=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de projecao invalido.",1).
  END.
  WHEN "DECIMAL" THEN DO:
   IF oValues:GetType(f)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Decimal JSON necessario: " + f,1).
   amount=oValues:GetDecimal(f). IF amount=? THEN UNDO, THROW NEW Progress.Lang.AppError("Decimal desconhecido.",1).
  END.
  WHEN "LOGICAL" THEN IF oValues:GetType(f)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario: " + f,1).
  WHEN "DATE" THEN DO:
   IF oValues:IsNull(f) THEN RETURN.
   IF oValues:GetType(f)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("DATE ISO necessario: " + f,1).
   RUN ParseDate(oValues:GetCharacter(f),OUTPUT dt).
  END.
  OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Campo nao editavel.",1).
 END CASE.
END PROCEDURE.
PROCEDURE ParseDate:
 DEFINE INPUT PARAMETER cText AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER valueDate AS DATE NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF LENGTH(cText)<>10 OR SUBSTRING(cText,5,1)<>"-" OR SUBSTRING(cText,8,1)<>"-" THEN UNDO, THROW NEW Progress.Lang.AppError("Data ISO invalida.",1).
 DO k=1 TO 10:
  IF k=5 OR k=8 THEN NEXT.
  IF INDEX("0123456789",SUBSTRING(cText,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Data ISO invalida.",1).
 END.
 valueDate=DATE(INTEGER(SUBSTRING(cText,6,2)),INTEGER(SUBSTRING(cText,9,2)),INTEGER(SUBSTRING(cText,1,4))) NO-ERROR.
 IF ERROR-STATUS:ERROR OR valueDate=? THEN UNDO, THROW NEW Progress.Lang.AppError("Data inexistente.",1).
END PROCEDURE.
PROCEDURE AssignValue:
 DEFINE INPUT PARAMETER f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 h=phContainer:BUFFER-FIELD(Physical(f)).
 CASE h:DATA-TYPE:
  WHEN "CHARACTER" THEN h:BUFFER-VALUE=oValues:GetCharacter(f).
  WHEN "INTEGER" THEN h:BUFFER-VALUE=oValues:GetInteger(f).
  WHEN "DECIMAL" THEN h:BUFFER-VALUE=oValues:GetDecimal(f).
  WHEN "LOGICAL" THEN h:BUFFER-VALUE=oValues:GetLogical(f).
  WHEN "DATE" THEN DO:
   IF oValues:IsNull(f) THEN h:BUFFER-VALUE=?.
   ELSE DO: RUN ParseDate(oValues:GetCharacter(f),OUTPUT dt). h:BUFFER-VALUE=dt. END.
  END.
 END CASE.
END PROCEDURE.
PROCEDURE SupplierName:
 DEFINE VARIABLE code AS INTEGER NO-UNDO.
 DEFINE VARIABLE name AS CHARACTER NO-UNDO.
 cFailure="CONTAINER_VALIDATION".
 ASSIGN cEstab=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE iFornecedor=phContainer:BUFFER-FIELD("cod-emit-forn"):BUFFER-VALUE.
 IF cEstab=? OR cEstab="" OR iFornecedor=? OR iFornecedor<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Estabelecimento e fornecedor obrigatorios.",1).
 IF NOT FindUnique(phEmpresas,phEmpresas:NAME + ".cod_emp_ems2=" + SUBSTRING(cEstab,1,1)) THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa nao encontrada.",1).
 code=phEmpresas:BUFFER-FIELD("cod_emp_ems5"):BUFFER-VALUE.
 IF code=? OR code<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa EMS5 nao configurada.",1).
 cCompany=STRING(code).
 IF NOT FindUnique(phFornecedor,phFornecedor:NAME + ".cdn_fornecedor=" + STRING(iFornecedor) + " AND " + phFornecedor:NAME + ".cod_empresa=" + CHR(34) + cCompany + CHR(34)) THEN UNDO, THROW NEW Progress.Lang.AppError("Fornecedor nao encontrado na empresa.",1).
 name=phFornecedor:BUFFER-FIELD("nom_abrev"):BUFFER-VALUE.
 IF name=? OR name="" OR LENGTH(name)>15 THEN UNDO, THROW NEW Progress.Lang.AppError("Nome abreviado fornecedor invalido para container.",1).
 phContainer:BUFFER-FIELD("nome-ab-forn"):BUFFER-VALUE=name.
END PROCEDURE.
PROCEDURE PreflightRules:
 cFailure="CONTAINER_RULE_UNAVAILABLE".
 IF NOT VALID-HANDLE(phRuleProvider) THEN UNDO, THROW NEW Progress.Lang.AppError("Regras compostas nao ligadas; gravacao bloqueada.",1).
 IF phRuleProvider:TYPE<>"PROCEDURE" OR NOT phRuleProvider:PERSISTENT THEN UNDO, THROW NEW Progress.Lang.AppError("Provider de regras invalido.",1).
 cCallback=IF cOperation="update" THEN "OnUpdate" ELSE "BeforeDelete".
 IF LOOKUP("GetCapabilities",phRuleProvider:INTERNAL-ENTRIES)=0 OR LOOKUP(cCallback,phRuleProvider:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Callback composto nao implementado.",1).
 RUN GetCapabilities IN phRuleProvider(OUTPUT oCapabilities).
 IF NOT VALID-OBJECT(oCapabilities) THEN UNDO, THROW NEW Progress.Lang.AppError("Capacidades ausentes.",1).
 IF oCapabilities:GetCharacter("contract")<>"container-rules-v1" THEN UNDO, THROW NEW Progress.Lang.AppError("Contrato do provider incompativel.",1).
 cName=IF cOperation="update" THEN "onUpdate" ELSE "beforeDelete".
 IF oCapabilities:GetType(cName)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Capacidade de regra invalida.",1).
 IF NOT oCapabilities:GetLogical(cName) THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao sem regra concreta; gravacao bloqueada.",1).
END PROCEDURE.
PROCEDURE ExecuteRules:
 DEFINE VARIABLE change AS JsonObject NO-UNDO.
 DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE resource AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE key AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cAuditKeys AS CHARACTER NO-UNDO.
 DEFINE VARIABLE count AS INTEGER NO-UNDO.
 cFailure="CONTAINER_RULE_FAILED".
 oContext=NEW JsonObject(). oContext:Add("operation",cOperation). oContext:Add("container_id",iContainer). oContext:Add("actor",oActor). oContext:Add("before",CAST(oBefore:Clone(),JsonObject)).
 IF cOperation="update" THEN RUN OnUpdate IN phRuleProvider(phContainer,oContext,OUTPUT oRules).
 ELSE RUN BeforeDelete IN phRuleProvider(phContainer,oContext,OUTPUT oRules).
 IF NOT VALID-OBJECT(oRules) OR NOT phContainer:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("Provider nao confirmou regra composta.",1).
 IF oRules:GetType("success")<>JsonDataType:BOOLEAN OR NOT oRules:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Regra composta recusada.",1).
 IF oRules:GetType("changes")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots de filhos ausentes/incompletos.",1).
 aChanges=oRules:GetJsonArray("changes").
 IF oRules:Has("warnings") THEN DO:
  IF oRules:GetType("warnings")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Avisos de regra invalidos.",1).
  IF oRules:GetJsonArray("warnings"):Length>100 THEN UNDO, THROW NEW Progress.Lang.AppError("Avisos de regra excedem limite.",1).
  DO count=1 TO oRules:GetJsonArray("warnings"):Length:
   IF oRules:GetJsonArray("warnings"):GetType(count)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Aviso de regra deve ser texto controlado.",1).
   IF LENGTH(oRules:GetJsonArray("warnings"):GetCharacter(count))>4000 THEN UNDO, THROW NEW Progress.Lang.AppError("Aviso de regra excede limite.",1).
   aRuleWarnings:Add(oRules:GetJsonArray("warnings"):GetCharacter(count)).
  END.
 END.
 DO count=1 TO aChanges:Length:
  IF aChanges:GetType(count)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Evento de filho invalido.",1).
  change=aChanges:GetJsonObject(count).
  ASSIGN resource=change:GetCharacter("resource") op=change:GetCharacter("operation").
  IF NOT ExactList(resource,"itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp,pagtos_container,nfs_container,cta_corren_desconto,anexos_container,versoes_item_custo_container,pp_container_permissao,pp_container_saldo_repres,pp_it_container,item_container_custos,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos") THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso de filho desconhecido.",1).
  IF NOT (op="create" OR op="update" OR op="delete") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao de filho invalida.",1).
  IF ExactList(resource,"nfs_container,pp_container_permissao,pp_container_saldo_repres,pp_it_container,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos") THEN DO:
   IF change:GetType("recordId")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Chave composta de filho invalida.",1).
   key=change:GetCharacter("recordId"). IF key="" OR LENGTH(key)>512 THEN UNDO, THROW NEW Progress.Lang.AppError("Chave de filho vazia/invalida.",1).
  END.
  ELSE DO:
   IF change:GetType("recordId")<>JsonDataType:NUMBER OR Id(change,"recordId")=? THEN UNDO, THROW NEW Progress.Lang.AppError("ID inteiro de filho invalido.",1).
   key=STRING(Id(change,"recordId")).
  END.
  IF change:GetType("before")<>JsonDataType:OBJECT OR change:GetType("after")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots de filho invalidos.",1).
  IF ExactList(resource,"item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos") THEN DO:
   IF cOperation<>"delete" OR op<>"delete" THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots auxiliares somente na exclusao do container.",1).
   IF change:GetJsonObject("before"):GetType("container_id")<>JsonDataType:NUMBER OR change:GetJsonObject("before"):GetInteger("container_id")<>iContainer OR Id(change:GetJsonObject("before"),"versao_id")=? THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot auxiliar sem contexto de versao/container.",1).
  END.
  key=resource + ":" + key.
  IF LOOKUP(key,cAuditKeys,CHR(1))>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Filho duplicado; coalescer snapshot antes/depois.",1).
  cAuditKeys=cAuditKeys + (IF cAuditKeys="" THEN "" ELSE CHR(1)) + key.
 END.
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). err=NEW JsonObject().
 err:Add("code",code). err:Add("message",msg). err:Add("status",IF code="CONTAINER_NOT_FOUND" THEN 404 ELSE IF code="CONTAINER_BUSY" OR code="CONTAINER_EXISTS" OR code="CONTAINER_PERSISTENCE_REJECTED" THEN 409 ELSE IF code="CONTAINER_RULE_UNAVAILABLE" OR code="CONTAINER_CONFIGURATION" THEN 503 ELSE 422).
 poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.


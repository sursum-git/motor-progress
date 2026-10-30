/* Pure distribution plan shared by simulation and transactional commands.
   Does not calculate general item costs, read databases or modify its inputs. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttItem NO-UNDO
 FIELD id AS INTEGER FIELD purchaseId AS INTEGER FIELD distributionFlag AS INTEGER
 FIELD allocated AS DECIMAL DECIMALS 10 FIELD shipped AS DECIMAL DECIMALS 10
 FIELD tributary AS DECIMAL DECIMALS 10 FIELD negotiated AS DECIMAL DECIMALS 10
 FIELD previous AS DECIMAL DECIMALS 10 FIELD weight AS DECIMAL DECIMALS 10
 FIELD exclusiveAmount AS DECIMAL DECIMALS 10 FIELD basis AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttExpense NO-UNDO FIELD id AS INTEGER INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttLink NO-UNDO FIELD expenseId AS INTEGER FIELD isCost AS INTEGER INDEX pk IS PRIMARY UNIQUE expenseId.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE selectedCompany AS INTEGER NO-UNDO.
DEFINE VARIABLE companyMode AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE enabled AS LOGICAL NO-UNDO.
DEFINE VARIABLE globalEnabled AS LOGICAL NO-UNDO.
DEFINE VARIABLE masterEnabled AS LOGICAL NO-UNDO.
DEFINE VARIABLE statusEnabled AS LOGICAL NO-UNDO.
DEFINE VARIABLE requiredVersion AS LOGICAL NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE items AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE o AS JsonObject NO-UNDO.
DEFINE VARIABLE resultRow AS JsonObject NO-UNDO.
DEFINE VARIABLE memory AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE warningRow AS JsonObject NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "DISTRIBUTION_INPUT_INVALID".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE id AS INTEGER NO-UNDO.
DEFINE VARIABLE expenseId AS INTEGER NO-UNDO.
DEFINE VARIABLE targetItem AS INTEGER NO-UNDO.
DEFINE VARIABLE costFlag AS INTEGER NO-UNDO.
DEFINE VARIABLE forecast AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE negotiated AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE pool AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE totalWeight AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE confirmedTributary AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE itemShare AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE delta AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE rounded AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE emitEntry AS LOGICAL NO-UNDO.
FUNCTION Num RETURNS DECIMAL (objectData AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 IF objectData:GetType(name)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Numero JSON confirmado necessario: " + name,1).
 d=objectData:GetDecimal(name). IF d=? THEN UNDO, THROW NEW Progress.Lang.AppError("Numero desconhecido: " + name,1). RETURN d.
END FUNCTION.
FUNCTION IntValue RETURNS INTEGER (objectData AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO. d=Num(objectData,name).
 IF d<>TRUNCATE(d,0) OR d< -2147483648 OR d>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro32 necessario: " + name,1). RETURN INTEGER(d).
END FUNCTION.
FUNCTION PositiveId RETURNS INTEGER (objectData AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE d AS INTEGER NO-UNDO. d=IntValue(objectData,name). IF d<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("ID positivo necessario: " + name,1). RETURN d.
END FUNCTION.
FUNCTION Flag RETURNS LOGICAL (objectData AS JsonObject,name AS CHARACTER):
 IF objectData:GetType(name)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario: " + name,1). RETURN objectData:GetLogical(name).
END FUNCTION.
PROCEDURE Keys:
 DEFINE INPUT PARAMETER objectData AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE found AS LOGICAL NO-UNDO.
 names=objectData:GetNames().
 DO k=1 TO EXTENT(names): c=names[k]. found=FALSE.
  DO j=1 TO NUM-ENTRIES(allowed): IF c=ENTRY(j,allowed) THEN found=TRUE. END.
  IF NOT found THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao previsto: " + c,1).
 END.
END PROCEDURE.
PROCEDURE Warning:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE w AS JsonObject NO-UNDO. w=NEW JsonObject(). w:Add("code",code). w:Add("message",messageText). w:Add("origin","distribution-source-v1"). warnings:Add(w).
END PROCEDURE.
poOutput=NEW JsonObject(). warnings=NEW JsonArray(). items=NEW JsonArray().
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poInput) THEN UNDO, THROW NEW Progress.Lang.AppError("Entrada confirmada obrigatoria.",1).
 RUN Keys(poInput,"confirmed,source,container_id,container_company_id,company_policy,global_enabled,container_enabled,status_enabled,items,expenses,company_links").
 IF NOT Flag(poInput,"confirmed") OR poInput:GetType("source")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Origem confirmada obrigatoria.",1).
 IF poInput:GetCharacter("source")<>"distribution-inputs-v1" THEN UNDO, THROW NEW Progress.Lang.AppError("Origem de distribuicao nao reconhecida.",1).
 containerId=PositiveId(poInput,"container_id"). companyId=PositiveId(poInput,"container_company_id").
 IF poInput:GetType("company_policy")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Politica privada de empresa obrigatoria.",1).
 companyMode=poInput:GetCharacter("company_policy").
 CASE companyMode: WHEN "legacy_company_2" THEN selectedCompany=2. WHEN "container_company" THEN selectedCompany=companyId.
  OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Politica privada de empresa nao reconhecida.",1). END CASE.
 globalEnabled=Flag(poInput,"global_enabled"). masterEnabled=Flag(poInput,"container_enabled"). statusEnabled=Flag(poInput,"status_enabled"). enabled=masterEnabled AND statusEnabled.
 RUN Warning("DISTRIBUTION_COMPANY_POLICY","Empresa selecionada por politica privada explicita: " + companyMode + "; getVlDespADistribuir original usa empresa2.").
 rows=poInput:GetJsonArray("items").
 DO n=1 TO rows:Length:
  o=rows:GetJsonObject(n). RUN Keys(o,"item_container_id,item_proc_compra_id,ind_distr_custo,qt_alocada,qt_confirm_emb,vl_base_tributacao,vl_negociado,previous_distribution").
  id=PositiveId(o,"item_container_id"). FIND ttItem WHERE ttItem.id=id NO-ERROR.
  IF AVAILABLE ttItem THEN DO: failureCode="DISTRIBUTION_ITEM_DUPLICATE". UNDO, THROW NEW Progress.Lang.AppError("Item repetido no conjunto confirmado.",1). END.
  CREATE ttItem. ASSIGN ttItem.id=id ttItem.purchaseId=PositiveId(o,"item_proc_compra_id") ttItem.distributionFlag=IntValue(o,"ind_distr_custo")
   ttItem.allocated=Num(o,"qt_alocada") ttItem.shipped=Num(o,"qt_confirm_emb") ttItem.tributary=Num(o,"vl_base_tributacao") ttItem.negotiated=Num(o,"vl_negociado") ttItem.previous=Num(o,"previous_distribution").
  ttItem.basis="disabled".
  IF enabled AND ttItem.distributionFlag<>0 THEN DO:
   confirmedTributary=ttItem.tributary * ttItem.shipped.
   IF confirmedTributary=0 THEN ASSIGN ttItem.weight=MAXIMUM((ttItem.negotiated - ttItem.tributary) * ttItem.allocated,0) ttItem.basis="allocated-tributary-product-zero".
   ELSE ASSIGN ttItem.weight=MAXIMUM((ttItem.negotiated - ttItem.tributary) * ttItem.shipped,0) ttItem.basis="confirmed".
  END.
  totalWeight=totalWeight + ttItem.weight.
 END.
 rows=poInput:GetJsonArray("company_links").
 DO n=1 TO rows:Length:
  o=rows:GetJsonObject(n). RUN Keys(o,"empresa_id,despesa_id,log_custo").
  id=PositiveId(o,"empresa_id"). expenseId=PositiveId(o,"despesa_id"). costFlag=IntValue(o,"log_custo").
  IF id<>selectedCompany THEN NEXT.
  FIND ttLink WHERE ttLink.expenseId=expenseId NO-ERROR.
  IF AVAILABLE ttLink THEN DO: failureCode="DISTRIBUTION_LINK_AMBIGUOUS". UNDO, THROW NEW Progress.Lang.AppError("Mais de um vinculo empresa/despesa para a mesma chave.",1). END.
  CREATE ttLink. ASSIGN ttLink.expenseId=expenseId ttLink.isCost=costFlag.
 END.
 rows=poInput:GetJsonArray("expenses").
 DO n=1 TO rows:Length:
  o=rows:GetJsonObject(n). RUN Keys(o,"despesa_container_id,despesa_id,item_container_id,vl_prev,vl_negociado").
  id=PositiveId(o,"despesa_container_id"). expenseId=PositiveId(o,"despesa_id"). targetItem=IntValue(o,"item_container_id"). forecast=Num(o,"vl_prev"). negotiated=Num(o,"vl_negociado").
  IF targetItem<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Item da despesa invalido.",1).
  FIND ttExpense WHERE ttExpense.id=id NO-ERROR.
  IF AVAILABLE ttExpense THEN DO: failureCode="DISTRIBUTION_EXPENSE_DUPLICATE". UNDO, THROW NEW Progress.Lang.AppError("Despesa fisica repetida no conjunto confirmado.",1). END.
  CREATE ttExpense. ttExpense.id=id.
  IF targetItem>0 THEN DO:
   FIND ttItem WHERE ttItem.id=targetItem NO-ERROR.
   IF NOT AVAILABLE ttItem THEN DO: failureCode="DISTRIBUTION_ITEM_UNKNOWN". UNDO, THROW NEW Progress.Lang.AppError("Despesa exclusiva aponta para item fora do container.",1). END.
  END.
  FIND ttLink WHERE ttLink.expenseId=expenseId NO-ERROR.
  IF NOT enabled OR NOT AVAILABLE ttLink THEN NEXT.
  IF ttLink.isCost<>1 OR negotiated=0 OR negotiated<=forecast THEN NEXT.
  IF targetItem=0 THEN pool=pool + negotiated - forecast.
  ELSE ttItem.exclusiveAmount=ttItem.exclusiveAmount + negotiated - forecast.
 END.
 IF enabled AND pool>0 AND totalWeight=0 THEN DO: failureCode="DISTRIBUTION_ZERO_WEIGHT". UNDO, THROW NEW Progress.Lang.AppError("Despesa geral positiva sem peso distribuivel; divisao por zero bloqueada.",1). END.
 IF enabled AND NOT globalEnabled THEN RUN Warning("DISTRIBUTION_GLOBAL_DISABLED","Parametro global gerar_distr_custo desliga valores de novos movimentos/despesas; snapshot preserva delta e movimento zero mantem origem legada.").
 FOR EACH ttItem BY ttItem.id:
  ASSIGN itemShare=0 delta=0 rounded=0 emitEntry=FALSE.
  IF enabled THEN DO:
   IF pool>0 THEN itemShare=pool * ttItem.weight / totalWeight.
   delta=itemShare + ttItem.exclusiveAmount - ttItem.previous.
   rounded=ROUND(delta,2). emitEntry=rounded<>0.
  END.
  requiredVersion=requiredVersion OR emitEntry.
  resultRow=NEW JsonObject(). resultRow:Add("item_container_id",ttItem.id). resultRow:Add("snapshot_distribution",delta).
  resultRow:Add("snapshot_persisted_distribution",rounded).
  resultRow:Add("ledger_amount",IF globalEnabled THEN rounded ELSE 0). resultRow:Add("emit_entry",emitEntry).
  IF delta<>rounded THEN DO:
   warningRow=NEW JsonObject(). warningRow:Add("code","DISTRIBUTION_STORAGE_ROUNDING"). warningRow:Add("origin","distribution-source-v1").
   warningRow:Add("message","Dicionario DECIMALS2 limita snapshot e movimento; plano preserva delta bruto.").
   warningRow:Add("item_container_id",ttItem.id). warningRow:Add("unrounded",delta). warningRow:Add("persisted",rounded). warnings:Add(warningRow).
  END.
  memory=NEW JsonObject(). memory:Add("weight",ttItem.weight). memory:Add("quantity_basis",ttItem.basis). memory:Add("general_share",itemShare).
  memory:Add("exclusive_expense",ttItem.exclusiveAmount). memory:Add("previous_distribution",ttItem.previous). memory:Add("rounded_delta",rounded).
  resultRow:Add("memory",memory). items:Add(resultRow).
 END.
 data=NEW JsonObject(). data:Add("container_id",containerId). data:Add("company_id",selectedCompany). data:Add("company_policy",companyMode).
 data:Add("enabled",enabled). data:Add("global_enabled",globalEnabled). data:Add("expense_pool",pool). data:Add("total_weight",totalWeight).
 data:Add("items",items). data:Add("requiredNewSnapshot",requiredVersion). data:Add("warnings",warnings). data:Add("source","distribution-source-v1").
 poOutput:Add("success",TRUE). poOutput:Add("data",data).
 CATCH e AS Progress.Lang.Error:
  err=NEW JsonObject(). err:Add("code",failureCode). err:Add("message",e:GetMessage(1)). err:Add("status",422). err:Add("origin","distribution-source-v1").
  poOutput=NEW JsonObject(). poOutput:Add("success",FALSE). poOutput:Add("error",err).
 END CATCH.
END.

/* Single pure final-unit calculation shared by simulation and closing.
   No SQL, database handles, HTTP, session state or persistent writes. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttSeen NO-UNDO FIELD id AS INTEGER INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttSeenCost NO-UNDO FIELD id AS INTEGER INDEX pk IS PRIMARY UNIQUE id.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE versionData AS JsonObject NO-UNDO.
DEFINE VARIABLE item AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DEFINE VARIABLE previous AS JsonObject NO-UNDO.
DEFINE VARIABLE stock AS JsonObject NO-UNDO.
DEFINE VARIABLE row AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE errorRow AS JsonObject NO-UNDO.
DEFINE VARIABLE resultRow AS JsonObject NO-UNDO.
DEFINE VARIABLE aResults AS JsonArray NO-UNDO.
DEFINE VARIABLE aWarnings AS JsonArray NO-UNDO.
DEFINE VARIABLE aGlobalErrors AS JsonArray NO-UNDO.
DEFINE VARIABLE aErrorItems AS JsonArray NO-UNDO.
DEFINE VARIABLE aItemErrors AS JsonArray NO-UNDO.
DEFINE VARIABLE aRows AS JsonArray NO-UNDO.
DEFINE VARIABLE aItems AS JsonArray NO-UNDO.
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
DEFINE VARIABLE versionType AS INTEGER NO-UNDO.
DEFINE VARIABLE currentId AS INTEGER NO-UNDO.
DEFINE VARIABLE itemIndex AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE motherCount AS INTEGER NO-UNDO.
DEFINE VARIABLE errorCount AS INTEGER NO-UNDO.
DEFINE VARIABLE motherDate AS DATE NO-UNDO.
DEFINE VARIABLE rowDate AS DATE NO-UNDO.
DEFINE VARIABLE hasMother AS LOGICAL NO-UNDO.
DEFINE VARIABLE requiresMother AS LOGICAL NO-UNDO.
DEFINE VARIABLE stale AS LOGICAL NO-UNDO.
DEFINE VARIABLE released AS LOGICAL NO-UNDO.
DEFINE VARIABLE prioritize AS LOGICAL NO-UNDO.
DEFINE VARIABLE motherTypes AS CHARACTER NO-UNDO.

FUNCTION Num RETURNS DECIMAL (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 IF o:GetType(f)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Numero JSON confirmado necessario: " + f,1).
 d=o:GetDecimal(f). IF d=? THEN UNDO, THROW NEW Progress.Lang.AppError("Numero desconhecido: " + f,1). RETURN d.
END FUNCTION.
FUNCTION IntValue RETURNS INTEGER (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO. d=Num(o,f).
 IF d<>TRUNCATE(d,0) OR d< -2147483648 OR d>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro32bits necessario: " + f,1). RETURN INTEGER(d).
END FUNCTION.
FUNCTION PositiveId RETURNS INTEGER (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE id AS INTEGER NO-UNDO. id=IntValue(o,f).
 IF id<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("ID positivo necessario: " + f,1). RETURN id.
END FUNCTION.
FUNCTION TextValue RETURNS CHARACTER (o AS JsonObject,f AS CHARACTER):
 IF o:GetType(f)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Texto JSON necessario: " + f,1). RETURN o:GetCharacter(f).
END FUNCTION.
FUNCTION Flag RETURNS LOGICAL (o AS JsonObject,f AS CHARACTER):
 IF o:GetType(f)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario: " + f,1). RETURN o:GetLogical(f).
END FUNCTION.
FUNCTION IsoDate RETURNS DATE (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DATE NO-UNDO.
 c=TextValue(o,f).
 IF LENGTH(c)<>10 OR SUBSTRING(c,5,1)<>"-" OR SUBSTRING(c,8,1)<>"-" THEN UNDO, THROW NEW Progress.Lang.AppError("DATE ISO necessario: " + f,1).
 DO k=1 TO 10: IF k=5 OR k=8 THEN NEXT. IF INDEX("0123456789",SUBSTRING(c,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError("DATE ISO invalido: " + f,1). END.
 d=DATE(INTEGER(SUBSTRING(c,6,2)),INTEGER(SUBSTRING(c,9,2)),INTEGER(SUBSTRING(c,1,4))) NO-ERROR.
 IF d=? OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("DATE inexistente: " + f,1).
 IF YEAR(d)<>INTEGER(SUBSTRING(c,1,4)) OR MONTH(d)<>INTEGER(SUBSTRING(c,6,2)) OR DAY(d)<>INTEGER(SUBSTRING(c,9,2)) THEN UNDO, THROW NEW Progress.Lang.AppError("DATE alterada pelo runtime; ano ISO nao pode ser expandido.",1). RETURN d.
END FUNCTION.
PROCEDURE Keys:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER namesAllowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE keyName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE m AS INTEGER NO-UNDO. DEFINE VARIABLE found AS LOGICAL NO-UNDO.
 names=o:GetNames().
 DO k=1 TO EXTENT(names):
  ASSIGN keyName=names[k] found=FALSE.
  DO m=1 TO NUM-ENTRIES(namesAllowed): IF keyName=ENTRY(m,namesAllowed) THEN found=TRUE. END.
  IF NOT found THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao previsto no contrato: " + keyName,1).
 END.
END PROCEDURE.
PROCEDURE AddGlobalError:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=NEW JsonObject(). o:Add("code",code). o:Add("message",messageText). o:Add("origin","container-item-cost-v1"). aGlobalErrors:Add(o). errorCount=errorCount + 1.
END PROCEDURE.
PROCEDURE AddItemError:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=NEW JsonObject(). o:Add("code",code). o:Add("message",messageText). o:Add("origin","container-item-cost-v1"). aItemErrors:Add(o). errorCount=errorCount + 1.
END PROCEDURE.
PROCEDURE Warn:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=NEW JsonObject(). o:Add("code",code). o:Add("message",messageText). o:Add("origin","container-item-cost-v1").
 IF currentId<>? AND currentId>0 THEN o:Add("item_container_id",currentId). aWarnings:Add(o).
END PROCEDURE.

ASSIGN aResults=NEW JsonArray() aWarnings=NEW JsonArray() aGlobalErrors=NEW JsonArray() aErrorItems=NEW JsonArray() currentId=?.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poInput) THEN UNDO, THROW NEW Progress.Lang.AppError("Entrada confirmada ausente.",1).
 RUN Keys(poInput,"confirmed,source,container_id,policy,version,nfs,items").
 IF NOT Flag(poInput,"confirmed") OR TextValue(poInput,"source")<>"item-cost-inputs-v1" THEN UNDO, THROW NEW Progress.Lang.AppError("Origem de dados nao confirmada.",1).
 containerId=PositiveId(poInput,"container_id"). policy=poInput:GetJsonObject("policy"). versionData=poInput:GetJsonObject("version").
 RUN Keys(policy,"log_liberar_custo_realizado,log_priorizar_custo_previsto,tipo_versao_valida_nf").
 ASSIGN released=Flag(policy,"log_liberar_custo_realizado") prioritize=Flag(policy,"log_priorizar_custo_previsto").
 aRows=policy:GetJsonArray("tipo_versao_valida_nf").
 DO n=1 TO aRows:Length:
  IF aRows:GetType(n)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de versao NF deve ser inteiro.",1).
  row=NEW JsonObject(). row:Add("id",aRows:GetDecimal(n)). j=PositiveId(row,"id").
  IF LOOKUP(STRING(j),motherTypes)>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de versao NF repetido.",1).
  motherTypes=motherTypes + (IF motherTypes="" THEN "" ELSE ",") + STRING(j).
 END.
 RUN Keys(versionData,"versao_id,tipo_versao_id,log_versao_custo_desatualizada").
 ASSIGN versionId=PositiveId(versionData,"versao_id") versionType=IntValue(versionData,"tipo_versao_id") stale=Flag(versionData,"log_versao_custo_desatualizada")
  requiresMother=LOOKUP(STRING(versionType),motherTypes)>0.
 aRows=poInput:GetJsonArray("nfs").
 DO n=1 TO aRows:Length:
  row=aRows:GetJsonObject(n). RUN Keys(row,"documento,serie,estab,nat_operacao,cod_emitente,dt_emis_nota").
  IF TextValue(row,"documento")="" OR TextValue(row,"estab")="" THEN UNDO, THROW NEW Progress.Lang.AppError("Referencia de NF incompleta.",1).
  IF TextValue(row,"serie")=? OR PositiveId(row,"cod_emitente")=? THEN UNDO, THROW NEW Progress.Lang.AppError("Referencia de NF invalida.",1).
  IF SUBSTRING(TextValue(row,"nat_operacao"),1,1)="3" THEN DO:
   rowDate=IsoDate(row,"dt_emis_nota"). motherCount=motherCount + 1.
   IF motherDate=? THEN motherDate=rowDate.
   ELSE IF rowDate<>motherDate THEN RUN AddGlobalError("MOTHER_DATE_AMBIGUOUS","Notas maes possuem datas diferentes; origem PHP nao define ordenacao.").
  END.
 END.
 hasMother=motherCount>0.
 IF NOT hasMother THEN DO:
  motherDate=DATE(1,1,2001). RUN Warn("MOTHER_DATE_LEGACY_DEFAULT","Sem nota mae confirmada: data de referencia2001-01-01 conforme default explicito do PHP.").
 END.
 ELSE IF motherCount>1 THEN RUN Warn("MULTIPLE_MOTHER_SAME_DATE","Multiplos vinculos de nota mae; datas iguais produzem o mesmo corte de movimentos.").
 aItems=poInput:GetJsonArray("items"). IF aItems:Length=0 THEN RUN AddGlobalError("NO_ITEMS","Conjunto completo de itens do container necessario.").
 DO itemIndex=1 TO aItems:Length:
  ASSIGN aItemErrors=NEW JsonArray() currentId=?.
  DO ON ERROR UNDO, THROW:
   item=aItems:GetJsonObject(itemIndex). RUN Keys(item,"item_container_id,item_proc_compra_id,it_codigo,previous_cost,version_cost,stock,movimentos_med,etiquetas").
   currentId=PositiveId(item,"item_container_id").
   IF CAN-FIND(ttSeen WHERE ttSeen.id=currentId) THEN RUN AddItemError("ITEM_ID_DUPLICATE","Item repetido no conjunto de calculo.").
   ELSE DO: CREATE ttSeen. ttSeen.id=currentId. END.
   RUN CalculateItem.
   CATCH itemError AS Progress.Lang.Error: RUN AddItemError("ITEM_DATA_INVALID",itemError:GetMessage(1)). END CATCH.
  END.
  IF aItemErrors:Length>0 THEN DO:
   errorRow=NEW JsonObject(). errorRow:Add("index",itemIndex). IF currentId<>? THEN errorRow:Add("item_container_id",currentId).
   errorRow:Add("errors",aItemErrors). aErrorItems:Add(errorRow).
  END.
 END.
 CATCH inputError AS Progress.Lang.Error: RUN AddGlobalError("INPUT_INVALID",inputError:GetMessage(1)). END CATCH.
END.
poOutput=NEW JsonObject().
IF errorCount>0 THEN DO:
 poOutput:Add("success",FALSE). errorRow=NEW JsonObject(). errorRow:Add("code","ITEM_COST_VALIDATION"). errorRow:Add("status",422).
 errorRow:Add("message","Calculo unitario bloqueado; corrija todos os erros do conjunto antes de gravar."). errorRow:Add("error_count",errorCount).
 errorRow:Add("global_errors",aGlobalErrors). errorRow:Add("items",aErrorItems). poOutput:Add("error",errorRow).
END.
ELSE DO:
 data=NEW JsonObject(). data:Add("source","container-item-cost-v1"). data:Add("container_id",containerId). data:Add("versao_id",versionId).
 data:Add("items",aResults). data:Add("warnings",aWarnings). poOutput:Add("success",TRUE). poOutput:Add("data",data).
END.

PROCEDURE CalculateItem:
 DEFINE VARIABLE erp AS CHARACTER NO-UNDO.
 DEFINE VARIABLE purchaseItemId AS INTEGER NO-UNDO.
 DEFINE VARIABLE priorCostId AS INTEGER NO-UNDO.
 DEFINE VARIABLE versionItemId AS INTEGER NO-UNDO.
 DEFINE VARIABLE historical AS LOGICAL NO-UNDO.
 DEFINE VARIABLE historicalBalance AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE priorUnit AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE previousMissing AS LOGICAL NO-UNDO.
 DEFINE VARIABLE versionMissing AS LOGICAL NO-UNDO.
 DEFINE VARIABLE grossStock AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE adjustedStock AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE stockIma AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE stockMed AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE labelsCurrent AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE labelsOther AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE labelDifference AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE allocated AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE shipped AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE received AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE containerQuantity AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE motherQuantity AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE forecastUnit AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE realizedUnit AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE containerUnit AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE containerValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE stockValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE totalValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE totalQuantity AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE newUnit AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE origin AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE code AS INTEGER NO-UNDO.
 DEFINE VARIABLE memory AS JsonObject NO-UNDO.
 purchaseItemId=PositiveId(item,"item_proc_compra_id"). erp=TextValue(item,"it_codigo").
 IF TRIM(erp)="" THEN RUN AddItemError("ERP_CODE_MISSING","Item do pedido sem codigo ERP; gere nova versao apos corrigir o cadastro.").
 IF stale THEN RUN AddItemError("STALE_VERSION","Versao de custo desatualizada; gere nova versao antes de calcular o custo unitario.").
 IF NOT hasMother AND requiresMother THEN RUN AddItemError("MOTHER_NF_REQUIRED","Tipo de versao exige nota mae confirmada.").
 stock=item:GetJsonObject("stock"). RUN Keys(stock,"ima,med").
 ASSIGN stockIma=Num(stock,"ima") stockMed=Num(stock,"med") grossStock=stockIma + stockMed adjustedStock=grossStock.
 previousMissing=item:IsNull("previous_cost").
 IF NOT previousMissing THEN DO:
  previous=item:GetJsonObject("previous_cost"). RUN Keys(previous,"item_custo_id,vl_unit_novo").
  ASSIGN priorCostId=PositiveId(previous,"item_custo_id") priorUnit=Num(previous,"vl_unit_novo").
 END.
 aRows=item:GetJsonArray("movimentos_med").
 DO k=1 TO aRows:Length:
  row=aRows:GetJsonObject(k). RUN Keys(row,"dt_trans,tipo_trans,quantidade").
  ASSIGN rowDate=IsoDate(row,"dt_trans") code=IntValue(row,"tipo_trans") amount=Num(row,"quantidade").
  IF rowDate<motherDate THEN DO: historical=TRUE. historicalBalance=historicalBalance + (IF code=1 THEN amount ELSE - amount). END.
 END.
 IF previousMissing AND historical AND historicalBalance>0 THEN RUN AddItemError("PREVIOUS_COST_REQUIRED","Ha movimento MED e saldo anterior positivo sem custo anterior confirmado.").
 ELSE IF previousMissing THEN RUN Warn("PREVIOUS_COST_ABSENCE_ALLOWED","Custo anterior ausente permitido pelo ramo legado: sem movimento MED anterior ou saldo anterior nao positivo; origemID0/unitario0 explicitos.").
 aRows=item:GetJsonArray("etiquetas").
 DO k=1 TO aRows:Length:
  row=aRows:GetJsonObject(k). RUN Keys(row,"nr_container,situacao,quantidade").
  code=IntValue(row,"nr_container"). j=IntValue(row,"situacao"). amount=Num(row,"quantidade").
  IF hasMother AND (j=3 OR j=4) AND amount<>0 THEN DO:
   IF code=containerId THEN labelsCurrent=labelsCurrent + amount. ELSE labelsOther=labelsOther + amount.
  END.
 END.
 IF hasMother THEN DO:
  labelDifference=grossStock - labelsCurrent - labelsOther. adjustedStock=MAXIMUM(grossStock - labelsCurrent,0).
  IF grossStock - labelsCurrent<0 THEN RUN Warn("MOTHER_STOCK_CLAMPED","Estoque menos etiquetas do container negativo; aplicado clamp0 comprovado na origem.").
 END.
 versionMissing=item:IsNull("version_cost").
 IF versionMissing THEN RUN AddItemError("VERSION_ITEM_MISSING","Snapshot do item ausente na ultima versao do container.").
 ELSE DO:
  snapshotData=item:GetJsonObject("version_cost"). RUN Keys(snapshotData,"item_container_custo_id,versao_id,item_container_id,vl_unit_prev,vl_unit_realiz,qt_alocada,qt_confirm_emb,qt_recebto_fisico").
  IF PositiveId(snapshotData,"versao_id")<>versionId OR PositiveId(snapshotData,"item_container_id")<>currentId THEN RUN AddItemError("VERSION_ITEM_MISMATCH","Snapshot pertence a outra versao/item.").
  ASSIGN versionItemId=PositiveId(snapshotData,"item_container_custo_id") shipped=Num(snapshotData,"qt_confirm_emb") forecastUnit=? realizedUnit=? allocated=? received=?.
  IF CAN-FIND(ttSeenCost WHERE ttSeenCost.id=versionItemId) THEN RUN AddItemError("VERSION_COST_ID_DUPLICATE","Mesmo snapshot fisico de custo foi atribuido a mais de um item.").
  ELSE DO: CREATE ttSeenCost. ttSeenCost.id=versionItemId. END.
  IF NOT snapshotData:IsNull("vl_unit_prev") THEN forecastUnit=Num(snapshotData,"vl_unit_prev").
  IF NOT snapshotData:IsNull("vl_unit_realiz") THEN realizedUnit=Num(snapshotData,"vl_unit_realiz").
  IF NOT snapshotData:IsNull("qt_alocada") THEN allocated=Num(snapshotData,"qt_alocada").
  IF NOT snapshotData:IsNull("qt_recebto_fisico") THEN received=Num(snapshotData,"qt_recebto_fisico").
  IF shipped=0 THEN allocated=Num(snapshotData,"qt_alocada").
  IF released AND NOT prioritize THEN DO:
   realizedUnit=Num(snapshotData,"vl_unit_realiz"). IF realizedUnit=0 THEN forecastUnit=Num(snapshotData,"vl_unit_prev").
  END.
  ELSE forecastUnit=Num(snapshotData,"vl_unit_prev").
 END.
 IF aItemErrors:Length>0 THEN RETURN.
 ASSIGN containerQuantity=IF shipped<>0 THEN shipped ELSE allocated motherQuantity=IF shipped<>0 THEN shipped ELSE 0.
 IF prioritize THEN ASSIGN containerUnit=forecastUnit origin="priorizar-previsto".
 ELSE IF NOT released THEN ASSIGN containerUnit=forecastUnit origin="realizado-nao-liberado".
 ELSE IF realizedUnit<>0 THEN ASSIGN containerUnit=realizedUnit origin="realizado-liberado".
 ELSE ASSIGN containerUnit=forecastUnit origin="realizado-zero-fallback-previsto".
 ASSIGN containerValue=containerQuantity * containerUnit stockValue=adjustedStock * priorUnit totalValue=containerValue + stockValue totalQuantity=containerQuantity + adjustedStock.
 IF totalValue>0 AND totalQuantity>0 THEN newUnit=ROUND(totalValue / totalQuantity,2).
 ELSE DO:
  newUnit=0. RUN Warn("LEGACY_NONPOSITIVE_RESULT","Valor total ou quantidade ponderada nao positivos; ramo matematico explicito resulta0 antes do override por ausencia de movimento.").
 END.
 IF NOT historical THEN newUnit=containerUnit.
 resultRow=NEW JsonObject().
 resultRow:Add("container_id",containerId). resultRow:Add("item_container_id",currentId). resultRow:Add("item_proc_compra_id",purchaseItemId). resultRow:Add("it_codigo",erp).
 resultRow:Add("qt_saldo_estoq",adjustedStock). resultRow:Add("qt_diferenca",labelDifference). resultRow:Add("qt_etiquetas_container",labelsCurrent). resultRow:Add("qt_restante",labelsOther).
 resultRow:Add("qt_container",containerQuantity). resultRow:Add("vl_unit_container",containerUnit). resultRow:Add("vl_tot_container",containerValue). resultRow:Add("vl_unit_atual",priorUnit).
 resultRow:Add("vl_total",totalValue). resultRow:Add("qt_total",totalQuantity). resultRow:Add("vl_unit_novo",newUnit). resultRow:Add("item_custo_id_orig",priorCostId).
 resultRow:Add("item_container_custo_id",versionItemId). resultRow:Add("qt_nota_mae",motherQuantity). resultRow:Add("qt_saldo_estoq_atu",grossStock).
 memory=NEW JsonObject(). memory:Add("source","calcularNovoCustoItem-v1"). memory:Add("reference_date",motherDate). memory:Add("has_mother_nf",hasMother).
 memory:Add("prior_movement_med",historical). memory:Add("prior_balance_med",historicalBalance). memory:Add("prior_cost_missing",previousMissing).
 memory:Add("stock_ima",stockIma). memory:Add("stock_med",stockMed). memory:Add("stock_value",stockValue). memory:Add("unit_container_origin",origin).
 memory:Add("quantity_origin",IF shipped<>0 THEN "qt_confirm_emb" ELSE "qt_alocada").
 IF received=? THEN memory:AddNull("qt_recebto_fisico_unused"). ELSE memory:Add("qt_recebto_fisico_unused",received).
 memory:Add("unit_result_origin",IF NOT historical THEN "no-prior-med-movement-unrounded-container-unit" ELSE IF totalValue>0 AND totalQuantity>0 THEN "weighted-average-round2" ELSE "legacy-nonpositive-zero").
 resultRow:Add("memory",memory). aResults:Add(resultRow).
END PROCEDURE.

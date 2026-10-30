/* Explicit fiscal process. Fixed buffers/provider/internal confirmed rates only.
   All persistent mutations occur in one transaction. Nested callers own commit
   and MUST undo their outer transaction if this service returns failure. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTaxBases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRelations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCalcs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdProvider AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poCalculationInputs AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttDef NO-UNDO
 FIELD id AS INTEGER FIELD ordinal AS INTEGER FIELD tax AS INTEGER FIELD calculated AS LOGICAL FIELD description AS CHARACTER
 FIELD productBase AS LOGICAL FIELD perItem AS LOGICAL FIELD taxType AS INTEGER FIELD percentage AS DECIMAL DECIMALS 10
 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttLink NO-UNDO FIELD id AS INTEGER FIELD percentage AS DECIMAL DECIMALS 10 FIELD active AS INTEGER FIELD defaultValue AS DECIMAL DECIMALS 10
 FIELD costId AS INTEGER FIELD costPercentage AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttBase NO-UNDO FIELD taxId AS INTEGER FIELD baseId AS INTEGER INDEX pk IS UNIQUE PRIMARY taxId baseId.
DEFINE TEMP-TABLE ttRel NO-UNDO FIELD id AS INTEGER FIELD baseId AS INTEGER INDEX pk IS UNIQUE PRIMARY id baseId.
DEFINE TEMP-TABLE ttItem NO-UNDO FIELD id AS INTEGER FIELD buyId AS INTEGER FIELD allocated AS DECIMAL DECIMALS 10
 FIELD shipped AS DECIMAL DECIMALS 10 FIELD ipi AS LOGICAL FIELD ipiPercentage AS DECIMAL DECIMALS 10
 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttBuy NO-UNDO FIELD id AS INTEGER FIELD purchaseId AS INTEGER
 FIELD price AS DECIMAL EXTENT 4 DECIMALS 10 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttPurchase NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttExpense NO-UNDO FIELD id AS INTEGER FIELD expenseId AS INTEGER FIELD itemId AS INTEGER
 FIELD amount AS DECIMAL EXTENT 3 DECIMALS 10 FIELD taxBase AS DECIMAL DECIMALS 10 FIELD manual AS LOGICAL
 FIELD calcId AS INTEGER FIELD percentage AS DECIMAL DECIMALS 10 FIELD memoryText AS CHARACTER
 FIELD ledgerId AS INTEGER FIELD managed AS LOGICAL
 FIELD used AS LOGICAL FIELD changed AS LOGICAL FIELD useNewCalc AS LOGICAL INDEX pk IS UNIQUE PRIMARY id
 INDEX tuple expenseId itemId.
DEFINE TEMP-TABLE ttWork NO-UNDO FIELD kind AS CHARACTER FIELD id AS INTEGER FIELD targetId AS INTEGER
 FIELD ordinal AS INTEGER FIELD done AS LOGICAL INDEX pk IS UNIQUE PRIMARY kind id.
DEFINE BUFFER bWork FOR ttWork.
DEFINE BUFFER bLink FOR ttLink.
DEFINE TEMP-TABLE ttSelected NO-UNDO FIELD id AS INTEGER FIELD ordinal AS INTEGER FIELD calculated AS LOGICAL INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttSelectionOrder NO-UNDO FIELD id AS INTEGER FIELD position AS INTEGER INDEX pk IS PRIMARY UNIQUE id.
DEFINE VARIABLE lSelectedCalculated AS LOGICAL NO-UNDO.
DEFINE BUFFER bExpense FOR ttExpense.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE iCompany AS INTEGER NO-UNDO.
DEFINE VARIABLE iCalcId AS INTEGER NO-UNDO.
DEFINE VARIABLE iNewId AS INTEGER NO-UNDO.
DEFINE VARIABLE iPlanId AS INTEGER NO-UNDO.
DEFINE VARIABLE iIpiId AS INTEGER NO-UNDO.
DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
DEFINE VARIABLE i As INTEGER NO-UNDO.
DEFINE VARIABLE k As INTEGER NO-UNDO.
DEFINE VARIABLE n As INTEGER NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cField AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.
DEFINE VARIABLE cActor AS CHARACTER NO-UNDO.
DEFINE VARIABLE iUser AS INTEGER NO-UNDO.
DEFINE VARIABLE iDistribution AS INTEGER NO-UNDO.
DEFINE VARIABLE dDi AS DECIMAL NO-UNDO.
DEFINE VARIABLE dBuy AS DECIMAL NO-UNDO.
DEFINE VARIABLE dAllocated AS DECIMAL EXTENT 4 NO-UNDO.
DEFINE VARIABLE dShipped AS DECIMAL EXTENT 4 NO-UNDO.
DEFINE VARIABLE dTotals AS DECIMAL EXTENT 4 NO-UNDO.
DEFINE VARIABLE dValues AS DECIMAL EXTENT 3 NO-UNDO.
DEFINE VARIABLE dBases AS DECIMAL EXTENT 3 NO-UNDO.
DEFINE VARIABLE dProducts AS DECIMAL EXTENT 3 NO-UNDO.
DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE dOriginal AS DECIMAL NO-UNDO.
DEFINE VARIABLE dFactor AS DECIMAL NO-UNDO.
DEFINE VARIABLE lNested AS LOGICAL NO-UNDO.
DEFINE VARIABLE lProgress AS LOGICAL NO-UNDO.
DEFINE VARIABLE lReady AS LOGICAL NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE hq AS HANDLE NO-UNDO.
DEFINE VARIABLE hqBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE lWriteQuery AS LOGICAL NO-UNDO.
DEFINE VARIABLE joBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE joMemory AS JsonObject NO-UNDO.
DEFINE VARIABLE jaSteps AS JsonArray NO-UNDO.
DEFINE VARIABLE jaEvents AS JsonArray NO-UNDO.
DEFINE VARIABLE jaWarnings AS JsonArray NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE joEvent AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.
DEFINE VARIABLE joData AS JsonObject NO-UNDO.
DEFINE VARIABLE joOld AS JsonObject NO-UNDO.
DEFINE VARIABLE cMemory AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcMemory AS LONGCHAR NO-UNDO.
DEFINE VARIABLE iTaxOnlyRows AS INTEGER NO-UNDO.
DEFINE VARIABLE iTaxOnlyStarted AS INTEGER NO-UNDO.
DEFINE VARIABLE lTaxOnlyCompleted AS LOGICAL NO-UNDO.

FUNCTION Num RETURNS CHARACTER (v AS INTEGER): RETURN TRIM(STRING(v,"->>>>>>>>>9")). END FUNCTION.
FUNCTION Id RETURNS INTEGER (o AS JsonObject,f AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT o:Has(f) OR o:IsNull(f) THEN RETURN ?.
 CASE o:GetType(f):
  WHEN JsonDataType:NUMBER THEN c=o:GetJsonText(f).
  WHEN JsonDataType:STRING THEN c=o:GetCharacter(f).
  OTHERWISE RETURN ?.
 END CASE.
 IF LENGTH(c)=0 OR LENGTH(c)>10 THEN RETURN ?.
 DO j=1 TO LENGTH(c): IF INDEX("0123456789",SUBSTRING(c,j,1))=0 THEN RETURN ?. END.
 d=DECIMAL(c). IF d<1 OR d>2147483647 THEN RETURN ?. RETURN INTEGER(d).
END FUNCTION.
FUNCTION Found RETURNS LOGICAL (h AS HANDLE,w AS CHARACTER,writeLock AS LOGICAL):
 DEFINE VARIABLE ok AS LOGICAL NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 ok=h:FIND-FIRST("WHERE " + w,IF writeLock THEN EXCLUSIVE-LOCK ELSE SHARE-LOCK,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail("CONTAINER_BUSY","Registro em uso. Tente novamente.",409).
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Read/lock failed.",0).
 END.
 RETURN ok.
END FUNCTION.
FUNCTION Amount RETURNS DECIMAL (h AS HANDLE,f AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL NO-UNDO. d=h:BUFFER-FIELD(f):BUFFER-VALUE.
 IF d=? THEN RUN Fail("CONTAINER_VALUE_UNKNOWN","Valor numerico desconhecido no calculo fiscal.",422).
 RETURN d.
END FUNCTION.
FUNCTION UniqueExpense RETURNS LOGICAL (expenseId AS INTEGER):
 DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
 FOR EACH bExpense WHERE bExpense.expenseId=expenseId: countRows=countRows + 1. END.
 IF countRows>1 THEN RUN Fail("CONTAINER_EXPENSE_AMBIGUOUS","Base de despesa com mais de uma linha; selecao legada ambigua.",422).
 FIND FIRST ttExpense WHERE ttExpense.expenseId=expenseId NO-ERROR.
 RETURN AVAILABLE ttExpense.
END FUNCTION.
PROCEDURE Open:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER w AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER ordering AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER writeLock AS LOGICAL NO-UNDO.
 IF VALID-HANDLE(hq) THEN DO: hq:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hq. END.
 CREATE QUERY hq. ASSIGN hqBuffer=h lWriteQuery=writeLock.
 hq:SET-BUFFERS(h).
 IF NOT hq:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + w + " " + ordering) THEN UNDO, THROW NEW Progress.Lang.AppError("Query preparation failed.",0).
 hq:QUERY-OPEN(). hq:GET-FIRST(IF writeLock THEN EXCLUSIVE-LOCK ELSE SHARE-LOCK,NO-WAIT) NO-ERROR.
 RUN CheckQuery.
END PROCEDURE.
PROCEDURE Next:
 hq:GET-NEXT(IF lWriteQuery THEN EXCLUSIVE-LOCK ELSE SHARE-LOCK,NO-WAIT) NO-ERROR. RUN CheckQuery.
END PROCEDURE.
PROCEDURE CheckQuery:
 IF (cOperation="calcular_impostos" OR cOperation="selecionar_despesas" OR cOperation="opcoes_despesas_selecao") AND NOT hq:QUERY-OFF-END THEN DO:
  iTaxOnlyRows=iTaxOnlyRows + 1.
  IF iTaxOnlyRows>50000 OR ETIME - iTaxOnlyStarted>10000 THEN RUN Fail("CONTAINER_TAX_LIMIT","Limite do comando fiscal excedido.",503).
 END.
 IF hqBuffer:LOCKED THEN RUN Fail("CONTAINER_BUSY","Registro em uso. Tente novamente.",409).
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("Query read failed.",0).
END PROCEDURE.
FUNCTION Snapshot RETURNS JsonObject (h AS HANDLE,fieldList AS CHARACTER):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO. DEFINE VARIABLE publicName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE hf AS HANDLE NO-UNDO. DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE iv AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 DEFINE VARIABLE dt AS DATETIME NO-UNDO. DEFINE VARIABLE l AS LOGICAL NO-UNDO.
 o=NEW JsonObject().
 DO j=1 TO NUM-ENTRIES(fieldList):
  f=ENTRY(j,fieldList). hf=h:BUFFER-FIELD(f). publicName=REPLACE(f,"-","_").
  IF hf:BUFFER-VALUE=? THEN o:AddNull(publicName).
  ELSE CASE hf:DATA-TYPE:
   WHEN "INTEGER" THEN DO: iv=hf:BUFFER-VALUE. o:Add(publicName,iv). END.
   WHEN "DECIMAL" THEN DO: d=hf:BUFFER-VALUE. o:Add(publicName,d). END.
   WHEN "LOGICAL" THEN DO: l=hf:BUFFER-VALUE. o:Add(publicName,l). END.
   WHEN "DATETIME" THEN DO: dt=hf:BUFFER-VALUE. o:Add(publicName,dt). END.
   WHEN "CHARACTER" THEN DO: c=hf:BUFFER-VALUE. o:Add(publicName,c). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Unexpected snapshot type.",0).
  END CASE.
 END.
 RETURN o.
END FUNCTION.
PROCEDURE CheckInputs:
 DEFINE VARIABLE snap AS JsonObject NO-UNDO. DEFINE VARIABLE hf AS HANDLE NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT VALID-OBJECT(poCalculationInputs) OR NOT VALID-OBJECT(poPolicy) THEN RUN Fail("CONTAINER_INPUT_INVALID","Componentes internos ausentes.",422).
 IF NOT poCalculationInputs:Has("confirmed") OR NOT poCalculationInputs:Has("source") OR NOT poCalculationInputs:Has("container_snapshot")
  OR NOT poCalculationInputs:Has("dolar_di") OR NOT poCalculationInputs:Has("dolar_compra") THEN RUN Fail("CONTAINER_INPUT_INVALID","Cotacoes internas incompletas.",422).
 IF poCalculationInputs:GetType("confirmed")<>JsonDataType:BOOLEAN OR Id(poCalculationInputs,"container_id")<>iContainer THEN RUN Fail("CONTAINER_INPUT_INVALID","Cotacoes fora do container.",422).
 IF NOT poCalculationInputs:GetLogical("confirmed") OR poCalculationInputs:GetType("source")<>JsonDataType:STRING THEN RUN Fail("CONTAINER_INPUT_INVALID","Cotacoes nao confirmadas.",422).
 IF poCalculationInputs:GetCharacter("source")<>"container-cost-collector" OR poCalculationInputs:GetType("container_snapshot")<>JsonDataType:OBJECT THEN RUN Fail("CONTAINER_INPUT_INVALID","Origem de cotacao invalida.",422).
 IF poCalculationInputs:GetType("dolar_di")<>JsonDataType:NUMBER OR poCalculationInputs:GetType("dolar_compra")<>JsonDataType:NUMBER THEN RUN Fail("CONTAINER_INPUT_INVALID","Cotacao deve ser numerica.",422).
 ASSIGN dDi=poCalculationInputs:GetDecimal("dolar_di") dBuy=poCalculationInputs:GetDecimal("dolar_compra").
 IF dDi<=0 OR dBuy<=0 OR dDi=? OR dBuy=? THEN RUN Fail("CONTAINER_INPUT_INVALID","Cotacao positiva obrigatoria.",422).
 snap=poCalculationInputs:GetJsonObject("container_snapshot").
 DO i=1 TO 6:
  c=ENTRY(i,"vl-dolar-compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar").
  IF NOT snap:Has(c) THEN RUN Fail("CONTAINER_INPUT_STALE","Snapshot da cotacao incompleto.",412).
  hf=phContainer:BUFFER-FIELD(c).
  IF hf:BUFFER-VALUE=? THEN RUN Fail("CONTAINER_INPUT_STALE","Parametro de cotacao desconhecido.",412).
  IF hf:DATA-TYPE="CHARACTER" THEN DO:
   IF snap:GetType(c)<>JsonDataType:STRING THEN RUN Fail("CONTAINER_INPUT_STALE","Tipo do snapshot divergente.",412).
   IF snap:GetCharacter(c)<>hf:BUFFER-VALUE THEN RUN Fail("CONTAINER_INPUT_STALE","Parametros de cotacao alterados. Releia o container.",412).
  END.
  ELSE DO:
   IF snap:GetType(c)<>JsonDataType:NUMBER THEN RUN Fail("CONTAINER_INPUT_STALE","Tipo do snapshot divergente.",412).
   d=hf:BUFFER-VALUE.
   IF snap:GetDecimal(c)<>d THEN RUN Fail("CONTAINER_INPUT_STALE","Parametros de cotacao alterados. Releia o container.",412).
  END.
 END.
 IF NOT poPolicy:Has("usuario_id") OR NOT poPolicy:Has("actor") THEN RUN Fail("CONTAINER_INPUT_INVALID","Autoria interna ausente.",422).
 IF poPolicy:GetType("usuario_id")<>JsonDataType:NUMBER OR poPolicy:GetType("actor")<>JsonDataType:STRING THEN RUN Fail("CONTAINER_INPUT_INVALID","Autoria interna invalida.",422).
 d=poPolicy:GetDecimal("usuario_id"). IF d<0 OR d>2147483647 OR TRUNCATE(d,0)<>d THEN RUN Fail("CONTAINER_INPUT_INVALID","Usuario interno invalido.",422).
 ASSIGN iUser=INTEGER(d) cActor=poPolicy:GetCharacter("actor").
 IF cActor="" OR LENGTH(cActor)>160 THEN RUN Fail("CONTAINER_INPUT_INVALID","Autoria interna invalida.",422).
 IF poPolicy:Has("despesa_distr_custo") THEN DO:
  IF poPolicy:GetType("despesa_distr_custo")<>JsonDataType:NUMBER THEN RUN Fail("CONTAINER_INPUT_INVALID","Parametro privado de distribuicao invalido.",422).
  d=poPolicy:GetDecimal("despesa_distr_custo").
  IF d=? OR d<0 OR d>2147483647 OR TRUNCATE(d,0)<>d THEN RUN Fail("CONTAINER_INPUT_INVALID","Parametro privado de distribuicao invalido.",422).
  iDistribution=INTEGER(d).
 END.
END PROCEDURE.
PROCEDURE LoadState:
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO. DEFINE VARIABLE companyCount AS INTEGER NO-UNDO.
 RUN LoadCompany.
 RUN Open(phItems,phItems:NAME + ".container_id = " + Num(iContainer),"BY " + phItems:NAME + ".item_container_id",FALSE).
 DO WHILE NOT hq:QUERY-OFF-END:
  CREATE ttItem.
  ASSIGN ttItem.id=phItems:BUFFER-FIELD("item_container_id"):BUFFER-VALUE ttItem.buyId=phItems:BUFFER-FIELD("item_proc_compra_id"):BUFFER-VALUE
   ttItem.allocated=Amount(phItems,"qt_alocada") ttItem.shipped=Amount(phItems,"qt_confirm_emb")
   ttItem.ipi=phItems:BUFFER-FIELD("log_calc_ipi"):BUFFER-VALUE ttItem.ipiPercentage=phItems:BUFFER-FIELD("perc_ipi"):BUFFER-VALUE.
  IF ttItem.id=? OR ttItem.buyId=? THEN RUN Fail("CONTAINER_ITEM_INVALID","Item com vinculo desconhecido.",422).
  IF NOT CAN-FIND(FIRST ttBuy WHERE ttBuy.id=ttItem.buyId) THEN DO: CREATE ttBuy. ttBuy.id=ttItem.buyId. END.
  RUN Next.
 END.
 FOR EACH ttBuy BY ttBuy.id:
  IF NOT Found(phPurchaseItems,phPurchaseItems:NAME + ".item_proc_compra_id = " + Num(ttBuy.id),FALSE) THEN RUN Fail("CONTAINER_ITEM_INVALID","Item do pedido nao encontrado.",422).
  ASSIGN ttBuy.purchaseId=phPurchaseItems:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE
   ttBuy.price[1]=Amount(phPurchaseItems,"vl_base_tributacao") ttBuy.price[2]=Amount(phPurchaseItems,"vl_custo_dolar")
   ttBuy.price[3]=Amount(phPurchaseItems,"vl_negociado") ttBuy.price[4]=MAXIMUM(ttBuy.price[1] - ttBuy.price[3],0).
  IF ttBuy.purchaseId=? THEN RUN Fail("CONTAINER_ITEM_INVALID","Processo do item desconhecido.",422).
  IF NOT CAN-FIND(FIRST ttPurchase WHERE ttPurchase.id=ttBuy.purchaseId) THEN DO: CREATE ttPurchase. ttPurchase.id=ttBuy.purchaseId. END.
 END.
 FOR EACH ttPurchase BY ttPurchase.id:
  IF NOT Found(phPurchases,phPurchases:NAME + ".proc_compra_id = " + Num(ttPurchase.id),FALSE) THEN RUN Fail("CONTAINER_ITEM_INVALID","Processo de compra nao encontrado.",422).
 END.
 FOR EACH ttItem:
  FIND ttBuy WHERE ttBuy.id=ttItem.buyId.
  DO k=1 TO 4: ASSIGN dAllocated[k]=dAllocated[k] + ttItem.allocated * ttBuy.price[k] dShipped[k]=dShipped[k] + ttItem.shipped * ttBuy.price[k]. END.
 END.
 DO k=1 TO 4: dTotals[k]=IF dShipped[k]=0 THEN dAllocated[k] ELSE dShipped[k]. END.
 RUN LoadCatalog.
 RUN Open(phExpenses,phExpenses:NAME + ".container_id = " + Num(iContainer),"BY " + phExpenses:NAME + ".despesa_container_id",TRUE).
 DO WHILE NOT hq:QUERY-OFF-END:
  idValue=phExpenses:BUFFER-FIELD("despesa_id"):BUFFER-VALUE. iNewId=phExpenses:BUFFER-FIELD("item_container_id"):BUFFER-VALUE.
  IF idValue=? OR iNewId=? THEN RUN Fail("CONTAINER_EXPENSE_AMBIGUOUS","Despesa/item desconhecido no container.",422).
  RUN CheckDistribution(idValue,iNewId).
  CREATE ttExpense.
  ASSIGN ttExpense.id=phExpenses:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE ttExpense.expenseId=idValue ttExpense.itemId=iNewId
   ttExpense.ledgerId=phExpenses:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE
   ttExpense.managed=idValue=iDistribution AND iDistribution>0 AND ttExpense.ledgerId<>? AND ttExpense.ledgerId>0
   ttExpense.amount[1]=Amount(phExpenses,"vl_prev") ttExpense.amount[2]=Amount(phExpenses,"vl_proforma") ttExpense.amount[3]=Amount(phExpenses,"vl_negociado")
   ttExpense.taxBase=Amount(phExpenses,"vl_base_imp") ttExpense.manual=phExpenses:BUFFER-FIELD("log_manual"):BUFFER-VALUE
   ttExpense.calcId=phExpenses:BUFFER-FIELD("calc_imp_container_id"):BUFFER-VALUE.
  IF cOperation="selecionar_despesas" THEN ASSIGN ttExpense.used=phExpenses:BUFFER-FIELD("log_utilizado"):BUFFER-VALUE ttExpense.percentage=phExpenses:BUFFER-FIELD("perc_calc"):BUFFER-VALUE ttExpense.memoryText=phExpenses:BUFFER-FIELD("memoria_calculo"):BUFFER-VALUE.
  joBefore:Add(Num(ttExpense.id),Snapshot(phExpenses,"despesa_container_id,despesa_id,container_id,item_container_id,vl_prev,vl_proforma,vl_negociado,vl_base_imp,calc_imp_container_id,cta_corren_custo_distr_id,log_manual,log_utilizado,perc_calc,memoria_calculo")).
  RUN Next.
 END.
END PROCEDURE.
PROCEDURE LoadCompany:
 DEFINE VARIABLE companyCount AS INTEGER NO-UNDO.
 cPrefix=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
 IF cPrefix=? OR LENGTH(cPrefix)=0 THEN RUN Fail("CONTAINER_COMPANY_CONTEXT","Estabelecimento invalido.",422).
 IF (cOperation="selecionar_despesas" OR cOperation="opcoes_despesas_selecao") AND NOT cPrefix BEGINS "5" THEN RUN Fail("CONTAINER_SELECTION_MED_REQUIRED","Selecao exige container MED sob lock.",422).
 cPrefix=SUBSTRING(cPrefix,1,1). IF INDEX("0123456789",cPrefix)=0 THEN RUN Fail("CONTAINER_COMPANY_CONTEXT","Estabelecimento invalido.",422).
 RUN Open(phEmpresas,phEmpresas:NAME + ".cod_emp_ems2 = " + cPrefix,"BY " + phEmpresas:NAME + ".empresa_id",FALSE).
 DO WHILE NOT hq:QUERY-OFF-END:
  companyCount=companyCount + 1. iCompany=phEmpresas:BUFFER-FIELD("empresa_id"):BUFFER-VALUE. RUN Next.
 END.
 IF companyCount<>1 OR iCompany=? THEN RUN Fail("CONTAINER_COMPANY_CONTEXT","Empresa ausente ou ambigua.",422).
END PROCEDURE.
PROCEDURE LoadCatalog:
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
 /* Catalog/configuration locks precede the persistent expense locks. */
 RUN Open(phDefs,"TRUE","BY " + phDefs:NAME + ".despesa_id",FALSE).
 DO WHILE NOT hq:QUERY-OFF-END:
  CREATE ttDef.
  ASSIGN ttDef.id=phDefs:BUFFER-FIELD("despesa_id"):BUFFER-VALUE ttDef.ordinal=phDefs:BUFFER-FIELD("ordem"):BUFFER-VALUE
   ttDef.tax=phDefs:BUFFER-FIELD("log_imposto"):BUFFER-VALUE ttDef.calculated=phDefs:BUFFER-FIELD("log_calculada"):BUFFER-VALUE
   ttDef.productBase=phDefs:BUFFER-FIELD("log_vl_prod_base_calculo"):BUFFER-VALUE ttDef.perItem=phDefs:BUFFER-FIELD("log_calc_por_item"):BUFFER-VALUE
   ttDef.taxType=phDefs:BUFFER-FIELD("ind_imposto"):BUFFER-VALUE ttDef.percentage=phDefs:BUFFER-FIELD("perc_calculo"):BUFFER-VALUE.
  IF ttDef.taxType=3 THEN DO: IF iIpiId<>0 THEN RUN Fail("CONTAINER_TAX_CONFIG","Mais de uma despesa IPI configurada.",422). iIpiId=ttDef.id. END.
  IF cOperation="selecionar_despesas" OR cOperation="opcoes_despesas_selecao" THEN ttDef.description=phDefs:BUFFER-FIELD("descricao"):BUFFER-VALUE.
  RUN Next.
 END.
 RUN Open(phLinks,phLinks:NAME + ".empresa_id = " + Num(iCompany),"BY " + phLinks:NAME + ".empresa_despesa_id",FALSE).
 DO WHILE NOT hq:QUERY-OFF-END:
  idValue=phLinks:BUFFER-FIELD("despesa_id"):BUFFER-VALUE.
  IF idValue=? OR CAN-FIND(FIRST ttLink WHERE ttLink.id=idValue) THEN RUN Fail("CONTAINER_TAX_CONFIG","Vinculo empresa/despesa duplicado ou invalido.",422).
  IF NOT CAN-FIND(FIRST ttDef WHERE ttDef.id=idValue) THEN RUN Fail("CONTAINER_TAX_CONFIG","Despesa do vinculo nao encontrada.",422).
  CREATE ttLink. ASSIGN ttLink.id=idValue ttLink.percentage=phLinks:BUFFER-FIELD("percentual"):BUFFER-VALUE
   ttLink.costId=phLinks:BUFFER-FIELD("despesa_custo_id"):BUFFER-VALUE ttLink.costPercentage=phLinks:BUFFER-FIELD("percentual_custo"):BUFFER-VALUE.
  IF cOperation="selecionar_despesas" OR cOperation="opcoes_despesas_selecao" THEN ASSIGN ttLink.active=phLinks:BUFFER-FIELD("log_ativo"):BUFFER-VALUE ttLink.defaultValue=phLinks:BUFFER-FIELD("vl_padrao"):BUFFER-VALUE.
  RUN Next.
 END.
 RUN Open(phTaxBases,phTaxBases:NAME + ".empresa_id = " + Num(iCompany),"BY " + phTaxBases:NAME + ".imposto_id BY " + phTaxBases:NAME + ".despesa_id",FALSE).
 DO WHILE NOT hq:QUERY-OFF-END:
  CREATE ttBase. ASSIGN ttBase.taxId=phTaxBases:BUFFER-FIELD("imposto_id"):BUFFER-VALUE ttBase.baseId=phTaxBases:BUFFER-FIELD("despesa_id"):BUFFER-VALUE. RUN Next.
 END.
 RUN Open(phRelations,"TRUE","BY " + phRelations:NAME + ".despesa_id BY " + phRelations:NAME + ".despesa_id_base",FALSE).
 DO WHILE NOT hq:QUERY-OFF-END:
  CREATE ttRel. ASSIGN ttRel.id=phRelations:BUFFER-FIELD("despesa_id"):BUFFER-VALUE ttRel.baseId=phRelations:BUFFER-FIELD("despesa_id_base"):BUFFER-VALUE. RUN Next.
 END.
END PROCEDURE.
{sursum-api/includes/ContainerExpenseDefaultsPlan.i}
PROCEDURE UpsertPlan:
 DEFINE INPUT PARAMETER expenseId AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER itemId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER useCalc AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER percentage AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER memoryText AS CHARACTER NO-UNDO.
 DO n=1 TO 3: IF dValues[n]=? THEN RUN Fail("CONTAINER_VALUE_UNKNOWN","Resultado fiscal desconhecido.",422). END.
 iCount=0.
 FOR EACH bExpense WHERE bExpense.expenseId=expenseId AND bExpense.itemId=itemId:
  iCount=iCount + 1.
  IF bExpense.managed THEN RUN Fail("CONTAINER_EXPENSE_AMBIGUOUS","Destino fiscal pertence a movimento de distribuicao.",422).
 END.
 IF iCount>1 THEN RUN Fail("CONTAINER_EXPENSE_AMBIGUOUS","Destino fiscal com multiplas despesas.",422).
 FIND FIRST ttExpense WHERE ttExpense.expenseId=expenseId AND ttExpense.itemId=itemId NO-ERROR.
 IF NOT AVAILABLE ttExpense THEN DO:
  iPlanId=iPlanId - 1. CREATE ttExpense. ASSIGN ttExpense.id=iPlanId ttExpense.expenseId=expenseId ttExpense.itemId=itemId ttExpense.manual=percentage=0.
 END.
 ASSIGN ttExpense.amount[1]=dValues[1] ttExpense.amount[2]=dValues[2] ttExpense.amount[3]=dValues[3]
  ttExpense.percentage=percentage ttExpense.calcId=0 ttExpense.useNewCalc=useCalc ttExpense.memoryText=memoryText ttExpense.changed=TRUE.
 IF cOperation="selecionar_despesas" THEN ttExpense.ledgerId=0.
END PROCEDURE.
PROCEDURE StepMemory:
 DEFINE INPUT PARAMETER kind AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER expenseId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER percentage AS DECIMAL NO-UNDO.
 joRow=NEW JsonObject(). joRow:Add("kind",kind). joRow:Add("despesa_id",expenseId). joRow:Add("percentual",percentage).
 joRow:Add("tributado",dValues[1]). joRow:Add("proforma",dValues[2]). joRow:Add("negociado",dValues[3]).
 jaSteps:Add(joRow). cMemory=STRING(joRow:GetJsonText()).
END PROCEDURE.
PROCEDURE TaxPlan:
 FOR EACH ttLink:
  FIND ttDef WHERE ttDef.id=ttLink.id.
  IF ttDef.tax=1 AND ttDef.perItem=FALSE THEN DO: CREATE ttWork. ASSIGN ttWork.kind="tax" ttWork.id=ttDef.id ttWork.ordinal=ttDef.ordinal. END.
 END.
 DO WHILE CAN-FIND(FIRST ttWork WHERE ttWork.kind="tax" AND NOT ttWork.done):
  lProgress=FALSE.
  FOR EACH ttWork WHERE ttWork.kind="tax" AND NOT ttWork.done BY ttWork.ordinal BY ttWork.id:
   lReady=TRUE.
   FOR EACH ttBase WHERE ttBase.taxId=ttWork.id:
    IF CAN-FIND(FIRST bWork WHERE bWork.kind="tax" AND bWork.id=ttBase.baseId AND NOT bWork.done) THEN lReady=FALSE.
   END.
   IF NOT lReady THEN NEXT.
   dValue=0.
   FOR EACH ttBase WHERE ttBase.taxId=ttWork.id:
    ASSIGN dOriginal=0 dFactor=0.
    FOR EACH ttExpense WHERE ttExpense.expenseId=ttBase.baseId:
     ASSIGN dOriginal=dOriginal + ttExpense.amount[1] dFactor=dFactor + ttExpense.taxBase.
    END.
    dValue=dValue + (IF dFactor<>0 THEN dFactor ELSE dOriginal).
   END.
   FIND ttLink WHERE ttLink.id=ttWork.id.
   IF ttLink.percentage=? THEN RUN Fail("CONTAINER_VALUE_UNKNOWN","Percentual fiscal desconhecido.",422).
   RUN SharedTaxAmount(dTotals[1] * dDi,dValue,ttLink.percentage,OUTPUT dValues[1]).
   RUN SharedTaxAmount(dTotals[2] * dDi,dValue,ttLink.percentage,OUTPUT dValues[2]).
   RUN SharedTaxAmount((dTotals[3] + dTotals[4]) * dDi,dValue,ttLink.percentage,OUTPUT dValues[3]).
   RUN StepMemory("tax",ttWork.id,ttLink.percentage). RUN UpsertPlan(ttWork.id,0,TRUE,0,cMemory).
   ASSIGN ttWork.done=TRUE lProgress=TRUE.
  END.
  IF NOT lProgress THEN RUN Fail("CONTAINER_TAX_CYCLE","Dependencias fiscais ciclicas.",422).
 END.
 /* Correctly traverse all bindings rather than overwrite PHP's source array. */
 FOR EACH ttLink WHERE ttLink.costId<>0:
  IF ttLink.costId=? OR NOT CAN-FIND(FIRST ttDef WHERE ttDef.id=ttLink.costId) OR CAN-FIND(FIRST ttWork WHERE ttWork.kind="cost" AND ttWork.targetId=ttLink.costId) THEN
   RUN Fail("CONTAINER_TAX_CONFIG","Destino de custo inexistente, desconhecido ou repetido.",422).
  IF ttLink.percentage=? OR ttLink.costPercentage=? THEN RUN Fail("CONTAINER_VALUE_UNKNOWN","Percentual do custo fiscal desconhecido.",422).
  IF ttLink.percentage=0 THEN RUN Fail("CONTAINER_ZERO_DENOMINATOR","Percentual do imposto zero impede custo nao recuperavel.",422).
  CREATE ttWork. ASSIGN ttWork.kind="cost" ttWork.id=ttLink.id ttWork.targetId=ttLink.costId.
 END.
 DO WHILE CAN-FIND(FIRST ttWork WHERE ttWork.kind="cost" AND NOT ttWork.done):
  lProgress=FALSE.
  FOR EACH ttWork WHERE ttWork.kind="cost" AND NOT ttWork.done BY ttWork.id:
   IF CAN-FIND(FIRST bWork WHERE bWork.kind="cost" AND bWork.targetId=ttWork.id AND NOT bWork.done) THEN NEXT.
   FIND ttLink WHERE ttLink.id=ttWork.id.
   lFound=UniqueExpense(ttWork.id).
   DO k=1 TO 3: dValues[k]=IF lFound THEN ttExpense.amount[k] / ttLink.percentage * ttLink.costPercentage ELSE 0. END.
   RUN StepMemory("nonrecoverable",ttWork.targetId,ttLink.costPercentage). RUN UpsertPlan(ttWork.targetId,0,TRUE,0,cMemory).
   ASSIGN ttWork.done=TRUE lProgress=TRUE.
  END.
  IF NOT lProgress THEN RUN Fail("CONTAINER_TAX_CYCLE","Dependencias de custo nao recuperavel ciclicas.",422).
 END.
END PROCEDURE.
PROCEDURE IpiPlan:
 IF iIpiId=0 OR NOT CAN-FIND(FIRST ttLink WHERE ttLink.id=iIpiId) THEN RETURN.
 DO k=1 TO 3: dBases[k]=0. END.
 FOR EACH ttBase WHERE ttBase.taxId=iIpiId:
  IF UniqueExpense(ttBase.baseId) THEN DO:
   dBases[1]=dBases[1] + (IF ttExpense.taxBase<>0 THEN ttExpense.taxBase ELSE ttExpense.amount[1]).
   DO k=2 TO 3: dBases[k]=dBases[k] + ttExpense.amount[k]. END.
  END.
 END.
 DO k=1 TO 3: dBases[k]=ROUND(dBases[k],2). dProducts[k]=dTotals[k] * (IF k=1 THEN dDi ELSE dBuy). END.
 FOR EACH ttItem BY ttItem.id:
  IF ttItem.ipi=TRUE THEN DO:
   IF ttItem.ipiPercentage=? THEN RUN Fail("CONTAINER_VALUE_UNKNOWN","Percentual de IPI desconhecido.",422).
   FIND ttBuy WHERE ttBuy.id=ttItem.buyId.
   DO k=1 TO 3:
    IF dProducts[k]=0 THEN RUN Fail("CONTAINER_ZERO_DENOMINATOR","Total zero impede rateio IPI por item.",422).
    dOriginal=ttBuy.price[k] * ttItem.shipped. IF dOriginal=0 THEN dOriginal=ttBuy.price[k] * ttItem.allocated.
    dOriginal=dOriginal * (IF k=1 THEN dDi ELSE dBuy).
    dFactor=dOriginal / dProducts[k].
    dValues[k]=ROUND((dOriginal + dBases[k] * dFactor) * ttItem.ipiPercentage / 100,2).
   END.
  END.
  ELSE DO k=1 TO 3: dValues[k]=0. END.
  IF dValues[1] + dValues[2] + dValues[3]>0 THEN DO:
   RUN StepMemory("ipi-item",iIpiId,ttItem.ipiPercentage). RUN UpsertPlan(iIpiId,ttItem.id,FALSE,0,cMemory).
  END.
  ELSE IF CAN-FIND(FIRST ttExpense WHERE ttExpense.expenseId=iIpiId AND ttExpense.itemId=ttItem.id) THEN
   jaWarnings:Add("IPI do item " + Num(ttItem.id) + ": valor persistido mantido conforme regra legada; recalculo zero ou desabilitado.").
 END.
END PROCEDURE.
PROCEDURE CalculatedPlan:
 FOR EACH ttExpense WHERE ttExpense.manual=FALSE:
  IF cOperation="selecionar_despesas" AND lSelectedCalculated AND NOT CAN-FIND(FIRST ttSelected WHERE ttSelected.id=ttExpense.expenseId AND ttSelected.calculated) THEN NEXT.
  FIND ttDef WHERE ttDef.id=ttExpense.expenseId NO-ERROR.
  IF AVAILABLE ttDef AND ttDef.calculated=TRUE AND NOT CAN-FIND(FIRST ttWork WHERE ttWork.kind="calculated" AND ttWork.id=ttDef.id) THEN DO:
   IF NOT CAN-FIND(FIRST ttLink WHERE ttLink.id=ttDef.id) THEN RUN Fail("CONTAINER_COMPANY_CONTEXT","Despesa calculada sem vinculo a empresa.",422).
   CREATE ttWork. ASSIGN ttWork.kind="calculated" ttWork.id=ttDef.id ttWork.ordinal=ttDef.ordinal.
   IF cOperation="selecionar_despesas" THEN DO: FIND ttSelectionOrder WHERE ttSelectionOrder.id=ttDef.id. ttWork.ordinal=ttSelectionOrder.position. END.
  END.
 END.
 DO WHILE CAN-FIND(FIRST ttWork WHERE ttWork.kind="calculated" AND NOT ttWork.done):
  lProgress=FALSE.
  FOR EACH ttWork WHERE ttWork.kind="calculated" AND NOT ttWork.done BY ttWork.ordinal BY ttWork.id:
   lReady=TRUE.
   IF cOperation<>"selecionar_despesas" THEN FOR EACH ttRel WHERE ttRel.id=ttWork.id:
    IF CAN-FIND(FIRST bWork WHERE bWork.kind="calculated" AND bWork.id=ttRel.baseId AND NOT bWork.done) THEN lReady=FALSE.
   END.
   IF NOT lReady THEN NEXT.
   FIND ttDef WHERE ttDef.id=ttWork.id.
   lFound=UniqueExpense(ttWork.id).
   IF lFound AND ttExpense.manual=FALSE THEN DO:
    IF ttDef.percentage=? THEN RUN Fail("CONTAINER_VALUE_UNKNOWN","Percentual da despesa calculada desconhecido.",422).
    DO k=1 TO 3: dBases[k]=0. END.
    FOR EACH ttRel WHERE ttRel.id=ttWork.id:
     IF UniqueExpense(ttRel.baseId) THEN DO:
      ASSIGN dBases[1]=dBases[1] + ttExpense.amount[1] dBases[2]=dBases[2] + ttExpense.amount[2]
       dBases[3]=dBases[3] + (IF ttExpense.amount[3]=0 THEN ttExpense.amount[1] ELSE ttExpense.amount[3]).
     END.
    END.
    DO k=1 TO 3:
     dOriginal=IF ttDef.productBase=TRUE THEN (dTotals[k] + (IF k=3 THEN dTotals[4] ELSE 0)) * dBuy ELSE 0.
     dValues[k]=(dOriginal + dBases[k]) * ttDef.percentage / 100.
    END.
    RUN StepMemory("calculated-expense",ttWork.id,ttDef.percentage). RUN UpsertPlan(ttWork.id,0,FALSE,ttDef.percentage,cMemory).
   END.
   ASSIGN ttWork.done=TRUE lProgress=TRUE.
  END.
  IF NOT lProgress THEN RUN Fail("CONTAINER_TAX_CYCLE","Dependencias de despesas calculadas ciclicas.",422).
 END.
END PROCEDURE.
PROCEDURE PersistPlan:
 DEFINE VARIABLE oldRow AS JsonObject NO-UNDO.
 IF cOperation="sincronizar" OR cOperation="calcular_impostos" OR cOperation="selecionar_despesas" THEN DO:
  RUN NextCalculoId IN phIdProvider (OUTPUT iCalcId).
  IF iCalcId=? OR iCalcId<1 THEN RUN Fail("CONTAINER_SEQUENCE_INVALID","Sequencia do calculo invalida.",409).
  IF NOT phCalcs:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Calculation creation failed.",0).
  ASSIGN phCalcs:BUFFER-FIELD("calc_imp_container_id"):BUFFER-VALUE=iCalcId phCalcs:BUFFER-FIELD("container_id"):BUFFER-VALUE=iContainer
   phCalcs:BUFFER-FIELD("dt_hr_calculo"):BUFFER-VALUE=NOW phCalcs:BUFFER-FIELD("usuario_id"):BUFFER-VALUE=iUser.
  joMemory=NEW JsonObject(). joMemory:Add("container_id",iContainer). joMemory:Add("dolar_di",dDi). joMemory:Add("dolar_compra",dBuy). joMemory:Add("steps",jaSteps).
  joMemory:Write(lcMemory). phCalcs:BUFFER-FIELD("desc_memoria_calc"):BUFFER-VALUE=STRING(lcMemory).
  IF NOT phCalcs:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Calculation validation failed.",0).
  joEvent=NEW JsonObject(). joEvent:Add("resource","calcs_imp_container"). joEvent:Add("operation","create"). joEvent:Add("recordId",iCalcId).
  joEvent:Add("before",NEW JsonObject()). joEvent:Add("after",Snapshot(phCalcs,"calc_imp_container_id,container_id,dt_hr_calculo,usuario_id,memoria_calculo,desc_memoria_calc")). jaEvents:Add(joEvent).
 END.
 FOR EACH ttExpense WHERE ttExpense.changed BY ttExpense.expenseId BY ttExpense.itemId:
  oldRow=NEW JsonObject().
  IF ttExpense.id<0 THEN DO:
   RUN NextDespesaId IN phIdProvider (OUTPUT iNewId).
   IF iNewId=? OR iNewId<1 THEN RUN Fail("CONTAINER_SEQUENCE_INVALID","Sequencia de despesa invalida.",409).
   IF NOT phExpenses:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Expense creation failed.",0).
   ASSIGN phExpenses:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE=iNewId phExpenses:BUFFER-FIELD("container_id"):BUFFER-VALUE=iContainer
    phExpenses:BUFFER-FIELD("despesa_id"):BUFFER-VALUE=ttExpense.expenseId phExpenses:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=ttExpense.itemId
    phExpenses:BUFFER-FIELD("log_manual"):BUFFER-VALUE=ttExpense.manual.
  END.
  ELSE DO:
   iNewId=ttExpense.id.
   IF NOT Found(phExpenses,phExpenses:NAME + ".despesa_container_id = " + Num(iNewId) + " AND " + phExpenses:NAME + ".container_id = " + Num(iContainer),TRUE) THEN RUN Fail("CONTAINER_EXPENSE_CHANGED","Despesa alterada durante calculo.",409).
   oldRow=CAST(joBefore:GetJsonObject(Num(iNewId)):Clone(),JsonObject).
  END.
  ASSIGN phExpenses:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=ttExpense.amount[1] phExpenses:BUFFER-FIELD("vl_proforma"):BUFFER-VALUE=ttExpense.amount[2]
   phExpenses:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=ttExpense.amount[3] phExpenses:BUFFER-FIELD("calc_imp_container_id"):BUFFER-VALUE=IF ttExpense.useNewCalc THEN iCalcId ELSE (IF cOperation="selecionar_despesas" THEN ttExpense.calcId ELSE 0)
   phExpenses:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE=(IF cOperation="selecionar_despesas" THEN ttExpense.ledgerId ELSE 0) phExpenses:BUFFER-FIELD("perc_calc"):BUFFER-VALUE=ttExpense.percentage
   phExpenses:BUFFER-FIELD("memoria_calculo"):BUFFER-VALUE=ttExpense.memoryText.
  IF cOperation="selecionar_despesas" THEN phExpenses:BUFFER-FIELD("log_utilizado"):BUFFER-VALUE=ttExpense.used.
  IF NOT phExpenses:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Expense validation failed.",0).
  joEvent=NEW JsonObject(). joEvent:Add("resource","despesas_container"). joEvent:Add("operation",IF ttExpense.id<0 THEN "create" ELSE "update"). joEvent:Add("recordId",iNewId).
  joEvent:Add("before",oldRow). joEvent:Add("after",Snapshot(phExpenses,"despesa_container_id,despesa_id,container_id,item_container_id,vl_prev,vl_proforma,vl_negociado,vl_base_imp,calc_imp_container_id,cta_corren_custo_distr_id,log_manual,log_utilizado,perc_calc,memoria_calculo")). jaEvents:Add(joEvent).
 END.
END PROCEDURE.

poResponse=NEW JsonObject(). lNested=TRANSACTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) OR NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phIdProvider)
  OR NOT VALID-HANDLE(phEmpresas) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phPurchaseItems) OR NOT VALID-HANDLE(phPurchases)
  OR NOT VALID-HANDLE(phDefs) OR NOT VALID-HANDLE(phLinks) OR NOT VALID-HANDLE(phTaxBases) OR NOT VALID-HANDLE(phRelations)
  OR NOT VALID-HANDLE(phCalcs) OR NOT VALID-HANDLE(phExpenses) THEN RUN Fail("CONTAINER_CONFIGURATION","Configuracao fiscal indisponivel.",500).
 IF NOT CAN-DO(phIdProvider:INTERNAL-ENTRIES,"NextCalculoId") OR NOT CAN-DO(phIdProvider:INTERNAL-ENTRIES,"NextDespesaId") THEN RUN Fail("CONTAINER_CONFIGURATION","Provider de sequencias indisponivel.",500).
 IF NOT poRequest:Has("operation") THEN RUN Fail("CONTAINER_OPERATION_INVALID","Informe operacao fiscal.",422).
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN RUN Fail("CONTAINER_OPERATION_INVALID","Operacao fiscal invalida.",422).
 cOperation=poRequest:GetCharacter("operation").
 IF cOperation<>"sincronizar" AND cOperation<>"calcular_impostos" AND cOperation<>"selecionar_despesas" AND cOperation<>"opcoes_despesas_selecao" AND cOperation<>"atualizar_despesas_calculadas" THEN RUN Fail("CONTAINER_OPERATION_INVALID","Operacao fiscal invalida.",422).
 cNames=poRequest:GetNames().
 DO i=1 TO EXTENT(cNames): cField=cNames[i]. IF cField<>"operation" AND cField<>"container_id" AND NOT (cOperation="selecionar_despesas" AND cField="despesa_ids") AND NOT ((cOperation="selecionar_despesas" OR cOperation="opcoes_despesas_selecao") AND (cField="ordem_campo" OR cField="ordem_direcao")) THEN RUN Fail("CONTAINER_VALIDATION","Campo nao permitido na operacao fiscal.",422). END.
 iContainer=Id(poRequest,"container_id"). IF iContainer=? THEN RUN Fail("CONTAINER_VALIDATION","Container deve ser inteiro positivo valido.",422).
 IF cOperation="selecionar_despesas" THEN RUN DefaultsSelectionInput.
 joBefore=NEW JsonObject(). jaSteps=NEW JsonArray(). jaEvents=NEW JsonArray(). jaWarnings=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  IF NOT Found(phContainer,phContainer:NAME + ".nr-container = " + Num(iContainer),cOperation<>"opcoes_despesas_selecao") THEN RUN Fail("CONTAINER_NOT_FOUND","Container nao encontrado.",404).
  IF cOperation="calcular_impostos" OR cOperation="selecionar_despesas" OR cOperation="opcoes_despesas_selecao" THEN DO:
   iTaxOnlyStarted=ETIME.
   DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
    RUN FiscalPlan. lTaxOnlyCompleted=TRUE.
   END.
   IF NOT lTaxOnlyCompleted THEN RUN Fail("CONTAINER_TAX_LIMIT","Tempo limite do comando fiscal excedido.",503).
  END.
  ELSE RUN FiscalPlan.
 END.
 IF cOperation="opcoes_despesas_selecao" THEN RETURN.
 /* Standalone: the real transaction ended. Nested: only the caller can confirm. */
 joData=NEW JsonObject(). joData:Add("container_id",iContainer). joData:Add("calc_imp_container_id",iCalcId).
 joData:Add("committed",NOT lNested). joData:Add("warnings",jaWarnings). joData:Add("changed",jaEvents:Length).
 poResponse:Add("success",TRUE). poResponse:Add("data",joData).
 joAudit=NEW JsonObject(). joAudit:Add("version",1). joAudit:Add("resource","container-impostos"). joAudit:Add("operation",cOperation).
 joAudit:Add("recordId",iContainer). joAudit:Add("actor",cActor). joAudit:Add("children",jaEvents).
 joAudit:Add("warnings",CAST(jaWarnings:Clone(),JsonArray)).
 IF lNested THEN DO:
  joAudit:Add("source","progress-transaction-pending"). poResponse:Add("pendingChanges",CAST(jaEvents:Clone(),JsonArray)). poResponse:Add("auditPending",joAudit).
 END.
 ELSE DO:
  joAudit:Add("source","progress-transaction"). poResponse:Add("audit",joAudit).
  IF CAN-DO(phIdProvider:INTERNAL-ENTRIES,"LogRule") THEN RUN LogRule IN phIdProvider ("INFO","Calculo fiscal confirmado para container " + Num(iContainer)) NO-ERROR.
 END.
 CATCH e AS Progress.Lang.Error:
  IF NOT poResponse:Has("error") THEN RUN BuildError("CONTAINER_PERSISTENCE_REJECTED","Calculo fiscal recusado. Nenhuma alteracao confirmada.",409).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hq) THEN DO: hq:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hq NO-ERROR. END.
  IF NOT lNested THEN DO:
   phContainer:BUFFER-RELEASE() NO-ERROR. phEmpresas:BUFFER-RELEASE() NO-ERROR. phItems:BUFFER-RELEASE() NO-ERROR.
   phPurchaseItems:BUFFER-RELEASE() NO-ERROR. phPurchases:BUFFER-RELEASE() NO-ERROR. phDefs:BUFFER-RELEASE() NO-ERROR.
   phLinks:BUFFER-RELEASE() NO-ERROR. phTaxBases:BUFFER-RELEASE() NO-ERROR. phRelations:BUFFER-RELEASE() NO-ERROR.
   phCalcs:BUFFER-RELEASE() NO-ERROR. phExpenses:BUFFER-RELEASE() NO-ERROR.
  END.
 END FINALLY.
END.
/* One shared planner/persister path. The new command deliberately skips IPI. */
PROCEDURE FiscalPlan:
 IF cOperation="opcoes_despesas_selecao" THEN DO:
  RUN DefaultsPolicy. RUN LoadCompany. RUN LoadCatalog. RUN DefaultsBuildOrder. RUN DefaultsOptions. RETURN.
 END.
 RUN CheckInputs. RUN LoadState.
 IF cOperation="sincronizar" THEN DO: RUN TaxPlan. RUN IpiPlan. END.
 ELSE IF cOperation="calcular_impostos" THEN RUN TaxPlan.
 ELSE IF cOperation="selecionar_despesas" THEN DO: RUN DefaultsBuildOrder. RUN DefaultsPlan. RUN CalculatedPlan. RUN TaxPlan. RUN IpiPlan. END.
 ELSE RUN CalculatedPlan.
 RUN PersistPlan.
END PROCEDURE.
PROCEDURE BuildError:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE e AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 poResponse=NEW JsonObject(). e=NEW JsonObject(). poResponse:Add("success",FALSE).
 e:Add("code",code). e:Add("message",messageText). e:Add("status",statusCode). poResponse:Add("error",e).
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN BuildError(code,messageText,statusCode). UNDO, THROW NEW Progress.Lang.AppError(code,0).
END PROCEDURE.

/* Only a trusted callback may prove ledger ownership. No request chooses policy. */
PROCEDURE CheckDistribution:
 DEFINE INPUT PARAMETER expenseId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER itemId AS INTEGER NO-UNDO.
 DEFINE VARIABLE ledger AS INTEGER NO-UNDO.
 DEFINE VARIABLE rowId AS INTEGER NO-UNDO.
 DEFINE VARIABLE managed AS LOGICAL NO-UNDO.
 DEFINE VARIABLE proof AS JsonObject NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 ledger=phExpenses:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE.
 rowId=phExpenses:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE.
 managed=iDistribution>0 AND expenseId=iDistribution AND ledger<>? AND ledger>0.
 IF managed THEN DO ON ERROR UNDO, THROW:
  IF LOOKUP("ValidateDistributionExpense",phIdProvider:INTERNAL-ENTRIES)=0 THEN RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Provider de comprovacao de distribuicao ausente.",422).
  RUN ValidateDistributionExpense IN phIdProvider(phContainer,phExpenses,OUTPUT proof).
  IF NOT VALID-OBJECT(proof) THEN RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Distribuicao nao comprovada.",422).
  names=proof:GetNames().
  IF EXTENT(names)<>4 OR rowId=? OR rowId<=0 THEN RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Comprovacao com campos ou chave invalidos.",422).
  IF NOT proof:Has("confirmed") OR NOT proof:Has("container_id") OR NOT proof:Has("despesa_container_id") OR NOT proof:Has("ledger_id") THEN RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Comprovacao incompleta.",422).
  IF proof:GetType("confirmed")<>JsonDataType:BOOLEAN OR proof:GetType("container_id")<>JsonDataType:NUMBER OR proof:GetType("despesa_container_id")<>JsonDataType:NUMBER OR proof:GetType("ledger_id")<>JsonDataType:NUMBER THEN RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Tipos invalidos na comprovacao.",422).
  IF proof:GetLogical("confirmed")<>TRUE OR proof:GetDecimal("container_id")<>iContainer OR proof:GetDecimal("despesa_container_id")<>rowId OR proof:GetDecimal("ledger_id")<>ledger THEN RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Comprovacao fora do contexto.",422).
  CATCH e AS Progress.Lang.Error:
   RUN Fail("CONTAINER_DISTRIBUTION_INVALID","Vinculo de distribuicao nao comprovado.",422).
  END CATCH.
  FINALLY: IF VALID-OBJECT(proof) THEN DELETE OBJECT proof NO-ERROR. END FINALLY.
 END.
 FOR EACH bExpense:
  IF managed AND bExpense.managed AND bExpense.ledgerId=ledger THEN RUN Fail("CONTAINER_EXPENSE_AMBIGUOUS","Lancamento de distribuicao repetido.",422).
  IF bExpense.expenseId=expenseId AND bExpense.itemId=itemId AND (NOT managed OR NOT bExpense.managed) THEN RUN Fail("CONTAINER_EXPENSE_AMBIGUOUS","Despesa/item duplicado sem comprovacao de distribuicao.",422).
 END.
END PROCEDURE.

/* Shared arithmetic only; container-specific collection and persistence unchanged. */
PROCEDURE SharedTaxAmount:
 DEFINE INPUT PARAMETER productBase AS DECIMAL NO-UNDO. DEFINE INPUT PARAMETER expenseBase AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER percentage AS DECIMAL NO-UNDO. DEFINE OUTPUT PARAMETER amountValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
 pathValue=SEARCH('sursum-api/programs/CiwTaxAmount.r').
 IF pathValue=? THEN RUN Fail('CONTAINER_TAX_CONFIGURATION','Calculador fiscal compartilhado nao publicado.',503).
 RUN VALUE(pathValue)(productBase,expenseBase,percentage,OUTPUT amountValue).
END PROCEDURE.

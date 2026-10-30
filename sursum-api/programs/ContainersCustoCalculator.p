/* Pure financial calculator. No DB, session, HTTP, sequence or business writes.
   ABI: INPUT JsonObject / OUTPUT JsonObject. See ContainersCustoCalculator.md.
   Source: grid_itens_container:15010,15262,20429; comparacao:14499. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE oContainer AS JsonObject NO-UNDO.
DEFINE VARIABLE oQuote AS JsonObject NO-UNDO.
DEFINE VARIABLE oPayments AS JsonObject NO-UNDO.
DEFINE VARIABLE oDiscounts AS JsonObject NO-UNDO.
DEFINE VARIABLE oExpenses AS JsonObject NO-UNDO.
DEFINE VARIABLE aItems AS JsonArray NO-UNDO.
DEFINE VARIABLE aResult AS JsonArray NO-UNDO.
DEFINE VARIABLE aWarnings AS JsonArray NO-UNDO.
DEFINE VARIABLE oMemory AS JsonObject NO-UNDO.
DEFINE VARIABLE oData AS JsonObject NO-UNDO.
DEFINE VARIABLE oTotals AS JsonObject NO-UNDO.
DEFINE VARIABLE oItem AS JsonObject NO-UNDO.
DEFINE VARIABLE oReal AS JsonObject NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE aSaldo AS JsonArray NO-UNDO.
DEFINE VARIABLE aCompra AS JsonArray NO-UNDO.
DEFINE VARIABLE aDi AS JsonArray NO-UNDO.
DEFINE VARIABLE cMode AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cCurrency AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cBasis AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cCostType AS CHARACTER NO-UNDO.
DEFINE VARIABLE cError AS CHARACTER NO-UNDO INITIAL "INVALID_REQUEST".
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iOther AS INTEGER NO-UNDO.
DEFINE VARIABLE dAlloc AS DECIMAL DECIMALS 10 EXTENT 3 NO-UNDO.
DEFINE VARIABLE dEmb AS DECIMAL DECIMALS 10 EXTENT 3 NO-UNDO.
DEFINE VARIABLE dBasis AS DECIMAL DECIMALS 10 EXTENT 3 NO-UNDO.
DEFINE VARIABLE dPrice AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dQty AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dAloc AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dConfirm AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dReceive AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSaldoRate AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dCompra AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDi AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dAverage AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dPaidReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dPaidDollar AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dPaidAverage AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dCreditReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dCreditDollar AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDiscountReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDiscountDollar AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dAverageBase AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dAverageDivisor AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSaldoDollar AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dTotalReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dAdjustment AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dItemNet AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dWeight AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dExpenseTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dExpense AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dExpenseWithout AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDistribution AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dMerch AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dFinal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dFinalWithout AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dFactor AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dRealMerch AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dRealExpense AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dRealDiscount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dRealCredit AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dRealTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSumPrev AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSumPrevWithout AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSumReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE lRealComplete AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE lNegotiated AS LOGICAL NO-UNDO.
DEFINE VARIABLE lFiscalInputs AS LOGICAL NO-UNDO.
DEFINE VARIABLE dtQuote AS DATE NO-UNDO.

FUNCTION TextValue RETURNS CHARACTER (o AS JsonObject, c AS CHARACTER):
 IF NOT VALID-OBJECT(o) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto necessario ausente.",1).
 IF NOT o:Has(c) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo necessario ausente: " + c,1).
 IF o:GetType(c)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Texto JSON necessario: " + c,1).
 RETURN o:GetCharacter(c).
END FUNCTION.
FUNCTION NumberValue RETURNS DECIMAL (o AS JsonObject, c AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto necessario ausente.",1).
 IF NOT o:Has(c) THEN UNDO, THROW NEW Progress.Lang.AppError("Numero necessario ausente: " + c,1).
 IF o:GetType(c)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Numero JSON necessario: " + c,1).
 d=o:GetDecimal(c).
 IF d=? THEN UNDO, THROW NEW Progress.Lang.AppError("Numero desconhecido: " + c,1).
 RETURN d.
END FUNCTION.
FUNCTION LogicalValue RETURNS LOGICAL (o AS JsonObject, c AS CHARACTER):
 IF NOT o:Has(c) THEN UNDO, THROW NEW Progress.Lang.AppError("Logico necessario ausente: " + c,1).
 IF o:GetType(c)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario: " + c,1).
 RETURN o:GetLogical(c).
END FUNCTION.
FUNCTION ObjectValue RETURNS JsonObject (o AS JsonObject, c AS CHARACTER):
 IF NOT o:Has(c) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto necessario ausente: " + c,1).
 IF o:GetType(c)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto JSON necessario: " + c,1).
 RETURN o:GetJsonObject(c).
END FUNCTION.
FUNCTION IdValue RETURNS INTEGER (o AS JsonObject, c AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 d=NumberValue(o,c).
 IF d<1 OR d>2147483647 OR d<>TRUNCATE(d,0) THEN
  UNDO, THROW NEW Progress.Lang.AppError("Identificador inteiro positivo necessario: " + c,1).
 RETURN INTEGER(d).
END FUNCTION.

DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError("Dados confirmados necessarios.",1).
 RUN Keys(poRequest,"mode,currency,calculationBasis,container,quotation,payments,discounts,expenses,items").
 ASSIGN cMode=TextValue(poRequest,"mode") cCurrency=TextValue(poRequest,"currency") cBasis=TextValue(poRequest,"calculationBasis").
 IF NOT (cMode="itens" OR cMode="comparativos" OR cMode="resumo" OR cMode="rastro" OR cMode="gerar_versao" OR cMode="fiscal_inputs") OR NOT (cCurrency="real" OR cCurrency="dolar") OR NOT (cBasis="current" OR cBasis="version") THEN
  UNDO, THROW NEW Progress.Lang.AppError("Modo, moeda ou base de calculo invalida.",1).
 lNegotiated=cMode="comparativos" OR cMode="gerar_versao".
 lFiscalInputs=cMode="fiscal_inputs".
 ASSIGN oContainer=ObjectValue(poRequest,"container") oQuote=ObjectValue(poRequest,"quotation")
        oPayments=ObjectValue(poRequest,"payments") oDiscounts=ObjectValue(poRequest,"discounts") oExpenses=ObjectValue(poRequest,"expenses").
 RUN Keys(oContainer,"nr-container,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar,vl-dolar-compra,vl_dolar_di,log_versao_custo_desatualizada").
 iId=IdValue(oContainer,"nr-container").
 IF LogicalValue(oContainer,"log_versao_custo_desatualizada") AND cBasis="version" THEN DO:
  cError="STALE_VERSION". UNDO, THROW NEW Progress.Lang.AppError("Versao de custo desatualizada.",1).
 END.
 RUN Keys(oQuote,"valor,data").
 dPrice=NumberValue(oQuote,"valor").
 IF dPrice<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Cotacao negativa.",1).
 RUN IsoDate(TextValue(oQuote,"data"),OUTPUT dtQuote).
 RUN Keys(oPayments,"real,dolar").
 ASSIGN dPaidReal=NumberValue(oPayments,"real") dPaidDollar=NumberValue(oPayments,"dolar").
 RUN Keys(oDiscounts,"credito_real,credito_dolar,total_real,total_dolar").
 ASSIGN dCreditReal=NumberValue(oDiscounts,"credito_real") dCreditDollar=NumberValue(oDiscounts,"credito_dolar")
        dDiscountReal=NumberValue(oDiscounts,"total_real") dDiscountDollar=NumberValue(oDiscounts,"total_dolar").
 RUN Keys(oExpenses,"tributado,proforma,negociado").
 DO i=1 TO 3: dPrice=NumberValue(oExpenses,ENTRY(i,"tributado,proforma,negociado")). END.
 IF NOT poRequest:Has("items") THEN UNDO, THROW NEW Progress.Lang.AppError("Itens confirmados necessarios.",1).
 IF poRequest:GetType("items")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Array de itens necessario.",1).
 aItems=poRequest:GetJsonArray("items").
 IF (aItems:Length=0 AND NOT lFiscalInputs) OR aItems:Length>10000 THEN UNDO, THROW NEW Progress.Lang.AppError("Quantidade de itens fora do limite permitido.",1).
 DO i=1 TO aItems:Length:
  IF aItems:GetType(i)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Item JSON invalido.",1).
  oItem=aItems:GetJsonObject(i).
  RUN Keys(oItem,"item_container_id,qt_alocada,qt_confirm_emb,qt_recbto_fisico,vl_base_tributacao,vl_custo_dolar,vl_negociado,despesa_item,distribuicao_real,desconto_real,desconto_dolar,erp_real").
  iId=IdValue(oItem,"item_container_id").
  DO j=1 TO i - 1:
   IF IdValue(aItems:GetJsonObject(j),"item_container_id")=iId THEN UNDO, THROW NEW Progress.Lang.AppError("Item duplicado.",1).
  END.
  ASSIGN dAloc=NumberValue(oItem,"qt_alocada") dConfirm=NumberValue(oItem,"qt_confirm_emb") dReceive=IF lFiscalInputs THEN 0 ELSE NumberValue(oItem,"qt_recbto_fisico").
  IF dAloc<0 OR dConfirm<0 OR dReceive<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Quantidade negativa.",1).
  IF NOT lFiscalInputs AND (IF dConfirm=0 THEN dAloc ELSE dConfirm)=0 THEN DO:
   cError="ZERO_DENOMINATOR". UNDO, THROW NEW Progress.Lang.AppError("Item sem quantidade para custo unitario.",1).
  END.
  DO j=1 TO 3:
   dPrice=NumberValue(oItem,ENTRY(j,"vl_base_tributacao,vl_custo_dolar,vl_negociado")).
   IF dPrice<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Preco negativo.",1).
   ASSIGN dAlloc[j]=dAlloc[j] + dPrice * dAloc dEmb[j]=dEmb[j] + dPrice * dConfirm.
  END.
  /* Fiscal rates only consume aggregate quantity/price inputs. No ERP cost,
     per-item expense, distribution or unit-cost eligibility is evaluated. */
  IF lFiscalInputs THEN NEXT.
  dPrice=NumberValue(oItem,"distribuicao_real"). dPrice=NumberValue(oItem,"desconto_real"). dPrice=NumberValue(oItem,"desconto_dolar").
  oReal=ObjectValue(oItem,"despesa_item"). RUN Keys(oReal,"tributado,proforma,negociado").
  DO j=1 TO 3: dPrice=NumberValue(oReal,ENTRY(j,"tributado,proforma,negociado")). END.
  IF NOT oItem:Has("erp_real") THEN UNDO, THROW NEW Progress.Lang.AppError("Estado ERP real necessario.",1).
  IF NOT oItem:IsNull("erp_real") THEN DO:
   oReal=ObjectValue(oItem,"erp_real"). RUN Keys(oReal,"vl_custo,vl_desp,perc_rateio").
   dPrice=NumberValue(oReal,"vl_custo"). dPrice=NumberValue(oReal,"vl_desp"). dPrice=NumberValue(oReal,"perc_rateio").
  END.
 END.
 DO i=1 TO 3: dBasis[i]=IF dEmb[i]=0 THEN dAlloc[i] ELSE dEmb[i]. END.
 ASSIGN cCostType=IF lNegotiated THEN "negociado" ELSE "tributado"
        dExpenseTotal=NumberValue(oExpenses,cCostType)
        dAverageBase=dBasis[1] + (IF cMode="rastro" OR lFiscalInputs THEN 0 ELSE MAXIMUM(dBasis[3] - dBasis[2],0))
        dAdjustment=IF cMode="rastro" OR lFiscalInputs THEN 0 ELSE MAXIMUM(dBasis[3] - dBasis[2],0).
 IF NOT lFiscalInputs AND (dBasis[1]<=0 OR (lNegotiated AND dBasis[3]<=0)) THEN DO:
  cError="ZERO_DENOMINATOR". UNDO, THROW NEW Progress.Lang.AppError("Base global de rateio zerada.",1).
 END.
 ASSIGN aWarnings=NEW JsonArray() aSaldo=NEW JsonArray() aCompra=NEW JsonArray() aDi=NEW JsonArray().
 IF cMode="resumo" THEN aWarnings:Add("Resumo: moeda nomeada explicita; chamada PHP com quatro argumentos diverge da assinatura de dois. Base tributada atual e totais separados; nenhum total ambiguo foi escolhido.").
 IF cBasis="current" AND oContainer:GetLogical("log_versao_custo_desatualizada") THEN aWarnings:Add("Calculo atual; a versao salva permanece desatualizada.").
 RUN Rate("compra",TRUE,0,aSaldo,OUTPUT dSaldoRate).
 IF dSaldoRate<=0 THEN DO:
  cError="MISSING_RATE". UNDO, THROW NEW Progress.Lang.AppError("Cotacao para saldo indisponivel.",1).
 END.
 IF dSaldoRate=1 THEN aWarnings:Add("Prioridades esgotadas em paridade 1 explicitamente recebida; regra PHP considera 1 nao encontrado. Origem preservada no rastro.").
 IF dPaidDollar>0 AND dPaidReal>0 THEN dPaidAverage=dPaidReal / dPaidDollar.
 IF dCreditReal=0 THEN dCreditReal=dCreditDollar * (IF dPaidAverage>0 THEN dPaidAverage ELSE dSaldoRate).
 IF dDiscountReal=0 THEN dDiscountReal=dDiscountDollar * (IF dPaidAverage>0 THEN dPaidAverage ELSE dSaldoRate).
 ASSIGN dSaldoDollar=dAverageBase - dCreditDollar - dDiscountDollar - dPaidDollar
        dTotalReal=dPaidReal + dCreditReal + dDiscountReal + (IF dSaldoDollar>0 THEN dSaldoDollar * dSaldoRate ELSE 0)
        dAverageDivisor=dAverageBase - (IF dSaldoDollar<0 THEN dSaldoDollar ELSE 0).
 IF dAverageDivisor<=0 AND NOT lFiscalInputs THEN DO:
  cError="ZERO_DENOMINATOR". UNDO, THROW NEW Progress.Lang.AppError("Denominador do dolar medio zerado.",1).
 END.
 IF dAverageDivisor>0 THEN dAverage=ROUND(dTotalReal / dAverageDivisor,5).
 IF dAverage<=0 AND NOT lFiscalInputs THEN DO:
  cError="MISSING_RATE". UNDO, THROW NEW Progress.Lang.AppError("Dolar medio sem componentes positivos confirmados.",1).
 END.
 RUN Rate("compra",FALSE,dAverage,aCompra,OUTPUT dCompra).
 RUN Rate("di",FALSE,dAverage,aDi,OUTPUT dDi).
 ASSIGN oMemory=NEW JsonObject() aResult=NEW JsonArray() oTotals=NEW JsonObject().
 oMemory:Add("source","grid_itens_container.calcularCustoGeralItem;grid_itens_container_comparacao.calcularCustoGeralItem").
 oMemory:Add("total_tributado_dolar",dBasis[1]). oMemory:Add("total_proforma_dolar",dBasis[2]). oMemory:Add("total_negociado_dolar",dBasis[3]).
 oMemory:Add("ajuste_negociado_proforma",dAdjustment). oMemory:Add("base_dolar_medio",dAverageBase).
 oMemory:Add("media_pagamentos",dPaidAverage). oMemory:Add("credito_real_convertido",dCreditReal). oMemory:Add("desconto_real_convertido",dDiscountReal).
 oMemory:Add("vl_saldo_dolar",dSaldoDollar). oMemory:Add("numerador_dolar_medio",dTotalReal). oMemory:Add("denominador_dolar_medio",dAverageDivisor).
 oMemory:Add("cotacao_data",dtQuote). oMemory:Add("saldo_attempts",aSaldo). oMemory:Add("compra_attempts",aCompra). oMemory:Add("di_attempts",aDi).
 oMemory:Add("distribution_enabled",cMode="resumo").
 oMemory:Add("dolar_medio_adjustment_origin",IF cMode="rastro" OR lFiscalInputs THEN "Panel direct buscarDolarMedio call uses default logSaldoNeg=false" ELSE "PHP passes non-empty string to boolean logSaldoNeg in cost modes").
 DO i=1 TO (IF lFiscalInputs THEN 0 ELSE aItems:Length):
  ASSIGN oItem=aItems:GetJsonObject(i) oRow=NEW JsonObject()
         dAloc=NumberValue(oItem,"qt_alocada") dConfirm=NumberValue(oItem,"qt_confirm_emb") dReceive=NumberValue(oItem,"qt_recbto_fisico")
         dQty=IF dConfirm=0 THEN dAloc ELSE dConfirm
         dPrice=NumberValue(oItem,IF lNegotiated THEN "vl_negociado" ELSE "vl_base_tributacao")
         dItemNet=dPrice * dQty - NumberValue(oItem,"desconto_dolar")
         dDistribution=IF cMode="resumo" THEN - NumberValue(oItem,"distribuicao_real") ELSE 0
         dWeight=0 dExpense=0 dExpenseWithout=0.
  IF dItemNet>0 THEN DO:
   dWeight=dItemNet / (IF lNegotiated THEN dBasis[3] ELSE dBasis[1]).
   IF dExpenseTotal>0 THEN ASSIGN dExpenseWithout=dWeight * dExpenseTotal dExpense=dExpenseWithout + dDistribution.
   ELSE ASSIGN dExpense=0 dExpenseWithout=dDistribution.
   dExpense=dExpense + NumberValue(oItem:GetJsonObject("despesa_item"),cCostType).
   dExpenseWithout=dExpenseWithout + NumberValue(oItem:GetJsonObject("despesa_item"),cCostType).
  END.
  ASSIGN dFactor=IF cCurrency="dolar" THEN dAverage ELSE 1
         dExpense=dExpense / dFactor dExpenseWithout=dExpenseWithout / dFactor
         dMerch=IF cCurrency="dolar" THEN dItemNet ELSE dItemNet * dAverage
         dFinal=dMerch + dExpense dFinalWithout=dMerch + dExpenseWithout
         dSumPrev=dSumPrev + dFinal dSumPrevWithout=dSumPrevWithout + dFinalWithout.
  oRow:Add("item_container_id",IdValue(oItem,"item_container_id")).
  oRow:Add("vl_desp_prev",ROUND(dExpense,10)). oRow:Add("vl_desp_prev_sem_distr_custo",ROUND(dExpenseWithout,10)).
  oRow:Add("vl_merc_prev",ROUND(dMerch,10)). oRow:Add("vl_total_prev",ROUND(dFinal,10)). oRow:Add("vl_total_prev_sem_distr_custo",ROUND(dFinalWithout,10)).
  oRow:Add("vl_unit_prev",ROUND(dFinal / dQty,10)). oRow:Add("vl_unit_prev_sem_distr_custo",ROUND(dFinalWithout / dQty,10)).
  oRow:Add("qt_saldo",IF dReceive=0 THEN dConfirm - dAloc ELSE dReceive - dAloc).
  oRow:Add("peso_rateio",ROUND(dWeight,10)). oRow:Add("quantidade_base",dQty).
  IF cMode="comparativos" OR cMode="rastro" THEN DO:
   DO j=1 TO 6: oRow:Add(ENTRY(j,"vl_desp_real,vl_merc_real,vl_desc_item,vl_desc_container,vl_total_real,vl_unit_real"),0). END.
   oRow:Add("actual_source","disabled_by_legacy_call").
  END.
  ELSE IF oItem:IsNull("erp_real") THEN DO:
   lRealComplete=FALSE.
   DO j=1 TO 6: oRow:AddNull(ENTRY(j,"vl_desp_real,vl_merc_real,vl_desc_item,vl_desc_container,vl_total_real,vl_unit_real")). END.
   oRow:Add("actual_source","confirmed_no_erp_record").
  END.
  ELSE DO:
   ASSIGN oReal=oItem:GetJsonObject("erp_real") dRealDiscount=NumberValue(oItem,"desconto_real") / dFactor
          dRealMerch=(NumberValue(oReal,"vl_custo") - NumberValue(oItem,"desconto_real")) / dFactor
          dRealExpense=NumberValue(oReal,"vl_desp") / dFactor
          dRealCredit=NumberValue(oDiscounts,"credito_real") * NumberValue(oReal,"perc_rateio") / dFactor
          dRealTotal=dRealMerch + dRealExpense - dRealDiscount + dRealCredit
          dSumReal=dSumReal + dRealTotal.
   oRow:Add("vl_desp_real",ROUND(dRealExpense,10)). oRow:Add("vl_merc_real",ROUND(dRealMerch,10)).
   oRow:Add("vl_desc_item",ROUND(dRealDiscount,10)). oRow:Add("vl_desc_container",ROUND(dRealCredit,10)). oRow:Add("vl_total_real",ROUND(dRealTotal,10)).
   oRow:Add("vl_unit_real",IF dRealTotal>0 AND dConfirm>0 THEN ROUND(dRealTotal / dConfirm,10) ELSE 0).
   oRow:Add("actual_source","confirmed_erp_components").
  END.
  aResult:Add(oRow).
 END.
 oTotals:Add("vl_total_prev",ROUND(dSumPrev,10)). oTotals:Add("vl_total_prev_sem_distr_custo",ROUND(dSumPrevWithout,10)).
 IF lRealComplete THEN oTotals:Add("vl_total_real",ROUND(dSumReal,10)). ELSE oTotals:AddNull("vl_total_real").
 oTotals:Add("actual_complete",lRealComplete).
 oData=NEW JsonObject().
 oData:Add("mode",cMode). oData:Add("currency",cCurrency). oData:Add("calculationBasis",cBasis). oData:Add("costType",cCostType).
 oData:Add("dolar_medio",dAverage). oData:Add("cotacao_saldo",dSaldoRate).
 IF dCompra>0 THEN oData:Add("dolar_compra",dCompra). ELSE oData:AddNull("dolar_compra").
 IF dDi>0 THEN oData:Add("dolar_di",dDi). ELSE oData:AddNull("dolar_di").
 oData:Add("memory",oMemory). oData:Add("items",aResult). oData:Add("totals",oTotals). oData:Add("warnings",aWarnings).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",oData).
 CATCH e AS Progress.Lang.Error:
  RUN Fail(cError,e:GetMessage(1)).
 END CATCH.
END.

PROCEDURE Keys:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER cAllowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE cName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE lKnown AS LOGICAL NO-UNDO.
 cNames=o:GetNames().
 DO n=1 TO EXTENT(cNames):
  ASSIGN cName=cNames[n] lKnown=FALSE.
  DO k=1 TO NUM-ENTRIES(cAllowed):
   IF cName=ENTRY(k,cAllowed) THEN lKnown=TRUE.
  END.
  IF NOT lKnown THEN UNDO, THROW NEW Progress.Lang.AppError("Campo desconhecido: " + cNames[n],1).
 END.
END PROCEDURE.
PROCEDURE IsoDate:
 DEFINE INPUT PARAMETER cDate AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER dt AS DATE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF LENGTH(cDate)<>10 OR SUBSTRING(cDate,5,1)<>"-" OR SUBSTRING(cDate,8,1)<>"-" THEN
  UNDO, THROW NEW Progress.Lang.AppError("Data ISO necessaria.",1).
 DO n=1 TO 10:
  IF n=5 OR n=8 THEN NEXT.
  IF INDEX("0123456789",SUBSTRING(cDate,n,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Data ISO invalida.",1).
 END.
 dt=DATE(INTEGER(SUBSTRING(cDate,6,2)),INTEGER(SUBSTRING(cDate,9,2)),INTEGER(SUBSTRING(cDate,1,4))) NO-ERROR.
 IF ERROR-STATUS:ERROR OR dt=? THEN UNDO, THROW NEW Progress.Lang.AppError("Data inexistente.",1).
END PROCEDURE.
PROCEDURE Rate:
 DEFINE INPUT PARAMETER cType AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER lSkipAverage AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER dMean AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER aTrace AS JsonArray NO-UNDO.
 DEFINE OUTPUT PARAMETER dRate AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE cOrder AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cPriority AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE dProjection AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE dKind AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE oAttempt AS JsonObject NO-UNDO.
 ASSIGN cOrder=TextValue(oContainer,"ordem_busca_dolar_" + cType) dProjection=NumberValue(oContainer,"vl_proj_dolar") dKind=NumberValue(oContainer,"cod_tipo_proj_dolar").
 IF LOOKUP(STRING(INTEGER(dKind)),"1,2,3")=0 OR dKind<>TRUNCATE(dKind,0) THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de projecao invalido.",1).
 IF cOrder="" THEN UNDO, THROW NEW Progress.Lang.AppError("Prioridades de dolar necessarias.",1).
 /* Validate the entire list even when the first rate is already available. */
 DO n=1 TO NUM-ENTRIES(cOrder):
  IF LOOKUP(ENTRY(n,cOrder),"1,2,3,4")=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Prioridade de dolar invalida.",1).
 END.
 DO n=1 TO NUM-ENTRIES(cOrder):
  cPriority=ENTRY(n,cOrder).
  IF LOOKUP(cPriority,"1,2,3,4")=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Prioridade de dolar invalida.",1).
  IF cPriority="3" AND lSkipAverage THEN NEXT.
  CASE cPriority:
   WHEN "1" THEN DO:
    dRate=NumberValue(oQuote,"valor").
    IF dKind=2 THEN dRate=dRate + dProjection.
    IF dKind=3 THEN dRate=dRate * (1 + dProjection / 100).
   END.
   WHEN "2" THEN dRate=NumberValue(oContainer,"vl-dolar-compra").
   WHEN "3" THEN dRate=dMean.
   WHEN "4" THEN dRate=NumberValue(oContainer,"vl_dolar_di").
  END CASE.
  IF dRate<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Cotacao calculada negativa.",1).
  oAttempt=NEW JsonObject(). oAttempt:Add("priority",INTEGER(cPriority)). oAttempt:Add("value",dRate). oAttempt:Add("accepted",dRate<>0 AND dRate<>1).
  aTrace:Add(oAttempt).
  IF dRate<>0 AND dRate<>1 THEN RETURN.
 END.
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER cCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER cMessage AS CHARACTER NO-UNDO.
 DEFINE VARIABLE oError AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). oError=NEW JsonObject().
 oError:Add("code",cCode). oError:Add("message",cMessage). oError:Add("status",422).
 poResponse:Add("success",FALSE). poResponse:Add("error",oError).
END PROCEDURE.



/* Public root with actual collector, calculator and closer. TT only. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItemCustoPhysicalFixture.i}
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE types AS JsonArray NO-UNDO.
DEFINE VARIABLE headerPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE versionBuffers AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE fiscalBuffers AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE closeBuffers AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE seqValue AS INTEGER NO-UNDO.
DEFINE VARIABLE seqCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failAt AS INTEGER NO-UNDO.
DEFINE VARIABLE logCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
RUN Seed. RUN Invoke.
RUN Check(response:GetLogical("success"),"actual close pipeline commits in public root").
RUN Check(NOT TRANSACTION,"close response after actual commit").
RUN Check(response:GetJsonObject("audit"):GetJsonArray("changes"):Length=4,"two costs and two physical links audited").
RUN Check(response:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(1):GetJsonObject("after"):GetInteger("container_id")=123,"new cost has trusted scope").
RUN Check(INDEX(response:GetJsonObject("data"):GetCharacter("message"),"501")>0 AND INDEX(response:GetJsonObject("data"):GetCharacter("message"),"502")>0,"message identifies both committed costs").
RUN Check(logCalls=1,"root queues exactly one confirmed log after commit").
FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71.
RUN Check(ttVersionItems.item_custo_id=501,"real snapshot points at real created cost"). RELEASE ttVersionItems.
RUN Seed. failAt=2. RUN Invoke.
RUN Check(NOT response:GetLogical("success") AND NOT response:Has("audit"),"second sequence failure returns no audit").
FIND ttVersionItems WHERE ttVersionItems.item_container_custo_id=71.
RUN Check(ttVersionItems.item_custo_id=0,"first pointer rolled back by public root"). RELEASE ttVersionItems.
FIND ttItemCosts WHERE ttItemCosts.item_custo_id=501 NO-ERROR.
RUN Check(NOT AVAILABLE ttItemCosts AND logCalls=0,"all created costs rolled back and no confirmed log").
OUTPUT TO VALUE("containers-processes-close-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; actual close pipeline TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Invoke:
 versionBuffers[1]=BUFFER ttMaster:HANDLE.
 ASSIGN closeBuffers[1]=BUFFER ttMaster:HANDLE closeBuffers[2]=BUFFER ttItems:HANDLE closeBuffers[3]=BUFFER ttPurchaseItems:HANDLE closeBuffers[4]=BUFFER ttVersions:HANDLE closeBuffers[5]=BUFFER ttVersionItems:HANDLE closeBuffers[6]=BUFFER ttItemCosts:HANDLE closeBuffers[7]=BUFFER ttNfs:HANDLE closeBuffers[8]=BUFFER ttLocations:HANDLE closeBuffers[9]=BUFFER ttLabels:HANDLE closeBuffers[10]=BUFFER ttStockIma:HANDLE closeBuffers[11]=BUFFER ttStockMed:HANDLE closeBuffers[12]=BUFFER ttMovementsMed:HANDLE closeBuffers[13]=BUFFER ttInvoicesIma:HANDLE closeBuffers[14]=BUFFER ttInvoicesMed:HANDLE.
 headerPolicy=NEW JsonObject(). actor=NEW JsonObject(). actor:Add("login","test-close"). headerPolicy:Add("actor",actor).
 request:Add("resource","custos").
 RUN ContainersProcessosService.p(versionBuffers,fiscalBuffers,closeBuffers,THIS-PROCEDURE,THIS-PROCEDURE,headerPolicy,policy,request,OUTPUT response).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER textValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + textValue + " " + STRING(response:GetJsonText()),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER textValue AS CHARACTER NO-UNDO.
 IF TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("log before root commit",1).
 logCalls=logCalls + 1.
END PROCEDURE.
PROCEDURE Seed:
 DO TRANSACTION:
  EMPTY TEMP-TABLE ttMaster.
  EMPTY TEMP-TABLE ttItems.
  EMPTY TEMP-TABLE ttPurchaseItems.
  EMPTY TEMP-TABLE ttVersions.
  EMPTY TEMP-TABLE ttVersionItems.
  EMPTY TEMP-TABLE ttItemCosts.
  EMPTY TEMP-TABLE ttNfs.
  EMPTY TEMP-TABLE ttLocations.
  EMPTY TEMP-TABLE ttLabels.
  EMPTY TEMP-TABLE ttStockIma.
  EMPTY TEMP-TABLE ttStockMed.
  EMPTY TEMP-TABLE ttMovementsMed.
  EMPTY TEMP-TABLE ttInvoicesIma.
  EMPTY TEMP-TABLE ttInvoicesMed.
  CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.log_liberar_custo_realizado=TRUE.
  CREATE ttVersions. ASSIGN ttVersions.versao_id=7 ttVersions.container_id=123 ttVersions.tipo_versao_id=2 ttVersions.ind_sit_versao=2.
  DO n=1 TO 2:
   CREATE ttItems. ASSIGN ttItems.item_container_id=n ttItems.container_id=123 ttItems.item_proc_compra_id=10 + n.
   CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=10 + n ttPurchaseItems.codigo_erp="ERP" + STRING(n).
   CREATE ttVersionItems. ASSIGN ttVersionItems.item_container_custo_id=70 + n ttVersionItems.versao_id=7 ttVersionItems.item_container_id=n ttVersionItems.it_codigo="ERP" + STRING(n)
    ttVersionItems.vl_unit_prev=19 + n ttVersionItems.vl_unit_realiz=29 + n ttVersionItems.qt_alocada=IF n=1 THEN 100 ELSE 80 ttVersionItems.qt_confirm_emb=IF n=1 THEN 80 ELSE 0.
   CREATE ttItemCosts. ASSIGN ttItemCosts.item_custo_id=4 + n ttItemCosts.it_codigo="ERP" + STRING(n) ttItemCosts.cod_tipo_custo=1 ttItemCosts.vl_unit_novo=IF n=1 THEN 10 ELSE 12.
   CREATE ttStockIma. ASSIGN ttStockIma.it-codigo="ERP" + STRING(n) ttStockIma.cod-estabel="1" ttStockIma.cod-depos="A" ttStockIma.qtidade-atu=IF n=1 THEN 50 ELSE 10.
   CREATE ttStockMed. ASSIGN ttStockMed.it-codigo="ERP" + STRING(n) ttStockMed.cod-estabel="501" ttStockMed.cod-depos="A" ttStockMed.qtidade-atu=IF n=1 THEN 70 ELSE 20.
   CREATE ttMovementsMed. ASSIGN ttMovementsMed.nr-trans=n ttMovementsMed.it-codigo="ERP" + STRING(n) ttMovementsMed.dt-trans=DATE(9,1,2026) ttMovementsMed.tipo-trans=1 ttMovementsMed.quantidade=IF n=1 THEN 100 ELSE 30.
  END.
  CREATE ttLocations. ASSIGN ttLocations.local_estoq_portal_id=1 ttLocations.cod_empresa="5" ttLocations.cod_estab="501" ttLocations.cod_depos="A".
  CREATE ttNfs. ASSIGN ttNfs.container_id=123 ttNfs.documento="NF1" ttNfs.serie="A" ttNfs.estab="501" ttNfs.nat_operacao="3102" ttNfs.cod_emitente=10.
  CREATE ttInvoicesMed. ASSIGN ttInvoicesMed.cod-estabel="501" ttInvoicesMed.nr-nota-fis="NF1" ttInvoicesMed.serie="A" ttInvoicesMed.dt-emis-nota=DATE(10,1,2026).
  CREATE ttLabels. ASSIGN ttLabels.it-codigo="ERP1" ttLabels.nr-container=123 ttLabels.situacao=3 ttLabels.quantidade=20.
  CREATE ttLabels. ASSIGN ttLabels.it-codigo="ERP1" ttLabels.nr-container=999 ttLabels.situacao=4 ttLabels.quantidade=30.
 END.
 ASSIGN seqValue=500 seqCalls=0 failAt=0 logCalls=0.
 policy=NEW JsonObject(). policy:Add("actor","test-close"). types=NEW JsonArray(). types:Add(4). types:Add(5). policy:Add("tipo_versao_valida_nf",types).
 request=NEW JsonObject(). request:Add("operation","fechar"). request:Add("container_id",123). request:Add("versao_id",7). request:Add("expected_latest_version_id",7). request:Add("log_priorizar_custo_previsto",FALSE).
END PROCEDURE.
PROCEDURE NextItemCustoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Sequence outside transaction",1).
 seqCalls=seqCalls + 1. IF failAt=seqCalls THEN UNDO, THROW NEW Progress.Lang.AppError("Injected sequence failure",1).
 seqValue=seqValue + 1. valueId=seqValue.
END PROCEDURE.

/* No DB, sequence, HTTP, or business mutation. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItensOptionsTestTables.i}
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE optionsValue AS JsonArray NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE ids AS CHARACTER NO-UNDO.
DEFINE VARIABLE badIds AS CHARACTER EXTENT 7 NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE handleValue AS HANDLE NO-UNDO.
DEFINE VARIABLE extraId AS INTEGER NO-UNDO.
RUN Seed. RUN Invoke.
RUN Check(resultValue:GetLogical("success"),"valid parent returns options").
optionsValue=resultValue:GetJsonArray("data").
DO n=1 TO optionsValue:Length: ids=ids + (IF ids="" THEN "" ELSE ",") + STRING(optionsValue:GetJsonObject(n):GetInteger("item_proc_compra_id")). END.
RUN Check(ids="1,3,7,9,10","ERP, parent FK, global saldo and own existing selection predicates").
RUN Check(optionsValue:GetJsonObject(1):GetCharacter("saldo_disponivel_texto")="10,00","allocations of other containers reduce available balance").
RUN Check(optionsValue:GetJsonObject(2):GetCharacter("saldo_disponivel_texto")="0,00" AND INDEX(optionsValue:GetJsonObject(2):GetCharacter("label"),"já alocado")>0,"zero balance own assignment remains selectable for readonly edit").
RUN Check(optionsValue:GetJsonObject(4):GetCharacter("saldo_disponivel_texto")="0,01","balance rounded to two places before eligibility and display").
RUN Check(optionsValue:GetJsonObject(5):GetCharacter("saldo_disponivel_texto")="-1,00","own overallocated assignment remains visible without inventing zero").
RUN Check(INDEX(optionsValue:GetJsonObject(3):GetCharacter("label"),"Empresa 9")>0 AND INDEX(optionsValue:GetJsonObject(3):GetCharacter("label"),"Fornecedor 999")>0,"foreign company and supplier remain eligible global selection").
RUN Check(INDEX(optionsValue:GetJsonObject(1):GetCharacter("label"),"Pedido 10")>0 AND INDEX(optionsValue:GetJsonObject(1):GetCharacter("label"),"ERP1")>0 AND INDEX(optionsValue:GetJsonObject(1):GetCharacter("label"),"Descrição á")>0,"label contains order, ERP and Unicode description").
requestValue:Set("container_id",999). RUN Invoke. optionsValue=resultValue:GetJsonArray("data").
RUN Check(optionsValue:GetJsonObject(2):GetInteger("item_proc_compra_id")=2,"other parent sees its own zero-balance current allocation").
ids="". DO n=1 TO optionsValue:Length: ids=ids + "," + STRING(optionsValue:GetJsonObject(n):GetInteger("item_proc_compra_id")) + ",". END.
RUN Check(INDEX(ids,",3,")=0 AND INDEX(ids,",10,")=0,"parent context does not expose zero-balance allocations belonging only to another CID").
RUN Seed. FIND ttPurchases WHERE ttPurchases.proc_compra_id=20. DELETE ttPurchases. RUN Invoke.
ids="". DO n=1 TO resultValue:GetJsonArray("data"):Length: ids=ids + "," + STRING(resultValue:GetJsonArray("data"):GetJsonObject(n):GetInteger("item_proc_compra_id")) + ",". END.
RUN Check(INDEX(ids,",7,")=0,"deleted purchase header cannot be offered").
RUN Seed. requestValue:Set("container_id",555). RUN Invoke. RUN Failure(404,"ITENS_OPTIONS_NOT_FOUND").
RUN Seed. requestValue:Add("resource","free"). RUN Invoke. RUN Failure(422,"ITENS_OPTIONS_INVALID_REQUEST").
RUN Seed. requestValue:Set("operation","READ"). RUN Invoke. RUN Failure(422,"ITENS_OPTIONS_INVALID_REQUEST").
badIds[1]='"123"'. badIds[2]='0'. badIds[3]='-1'. badIds[4]='1.5'. badIds[5]='true'. badIds[6]='null'. badIds[7]='2147483648'.
DO n=1 TO EXTENT(badIds):
 RUN Seed. parser=NEW ObjectModelParser(). requestValue=CAST(parser:Parse('~{"operation":"read","container_id":' + badIds[n] + '}'),JsonObject). DELETE OBJECT parser.
 RUN Invoke. RUN Failure(422,"ITENS_OPTIONS_INVALID_REQUEST").
END.
RUN Seed. handleValue=?. RUN CallService(handleValue). RUN Failure(503,"ITENS_OPTIONS_CONFIGURATION").
RUN Seed. handleValue=BUFFER ttMaster:HANDLE. RUN CallService(handleValue). RUN Failure(503,"ITENS_OPTIONS_CONFIGURATION").
RUN Seed. FIND ttItems WHERE ttItems.item_container_id=2. ttItems.qt_alocada=?. RUN Invoke. RUN Failure(422,"ITENS_OPTIONS_DATA_INVALID").
RUN Seed. FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=1. ttPurchaseItems.qt_comprada=?. RUN Invoke. RUN Failure(422,"ITENS_OPTIONS_DATA_INVALID").
RUN Seed. RUN Invoke.
RUN Check(resultValue:GetJsonArray("data"):GetJsonObject(1):GetCharacter("saldo_disponivel_texto")="10,00","fresh valid call after error has no cached balance").
RUN Seed. EMPTY TEMP-TABLE ttPurchaseItems. RUN Invoke.
RUN Check(resultValue:GetLogical("success") AND resultValue:GetJsonArray("data"):Length=0,"no eligible purchase items is a confirmed empty list").
RUN Seed.
DO extraId=11 TO 5005:
 CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=extraId ttPurchaseItems.proc_compra_id=10 ttPurchaseItems.codigo_erp="ERP" + STRING(extraId) ttPurchaseItems.descricao="Limite" ttPurchaseItems.qt_comprada=1.
END.
RUN Invoke. RUN Check(resultValue:GetLogical("success") AND resultValue:GetJsonArray("data"):Length=5000,"exact supported option boundary is complete").
CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=5006 ttPurchaseItems.proc_compra_id=10 ttPurchaseItems.codigo_erp="ERP5006" ttPurchaseItems.descricao="Acima do limite" ttPurchaseItems.qt_comprada=1.
RUN Invoke. RUN Failure(422,"ITENS_OPTIONS_RESULT_LIMIT").
RUN Check(INDEX(resultValue:GetJsonObject("error"):GetCharacter("message"),"truncada")>0,"large list is rejected explicitly instead of truncation").
OUTPUT TO VALUE("containers-itens-options-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; TT only, no sequence." SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + (IF VALID-OBJECT(resultValue) AND resultValue:Has("error") THEN " error=" + resultValue:GetJsonObject("error"):GetCharacter("message") ELSE ""),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE Failure:
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 RUN Check(resultValue:GetLogical("success")=FALSE AND NOT resultValue:Has("data"),"failed options has no partial data").
 RUN Check(resultValue:GetJsonObject("error"):GetInteger("status")=statusValue AND resultValue:GetJsonObject("error"):GetCharacter("code")=codeValue,"typed options failure " + codeValue).
END PROCEDURE.
PROCEDURE Invoke: handleValue=BUFFER ttItems:HANDLE. RUN CallService(handleValue). END PROCEDURE.
PROCEDURE CallService:
 DEFINE INPUT PARAMETER itemsHandle AS HANDLE NO-UNDO.
 RUN ContainersItensOptionsService.p(INPUT BUFFER ttMaster:HANDLE,itemsHandle,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,requestValue,OUTPUT resultValue).
END PROCEDURE.
PROCEDURE Seed:
 DEFINE VARIABLE seedNo AS INTEGER NO-UNDO.
 EMPTY TEMP-TABLE ttMaster. EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttPurchaseItems. EMPTY TEMP-TABLE ttPurchases.
 CREATE ttMaster. ttMaster.nr-container=123. ttMaster.cod-estabel="501". CREATE ttMaster. ttMaster.nr-container=999.
 CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=10 ttPurchases.empresa_id=1 ttPurchases.fornecedor_id=2.
 CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=20 ttPurchases.empresa_id=9 ttPurchases.fornecedor_id=999.
 DO seedNo=1 TO 10:
  CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=seedNo ttPurchaseItems.proc_compra_id=10 ttPurchaseItems.codigo_erp="ERP" + STRING(seedNo) ttPurchaseItems.descricao="Descrição á" ttPurchaseItems.qt_comprada=10.
 END.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=1. ttPurchaseItems.qt_comprada=100.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=2. ttPurchaseItems.qt_comprada=5.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=3. ttPurchaseItems.qt_comprada=5.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=5. ttPurchaseItems.codigo_erp="".
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=6. ttPurchaseItems.proc_compra_id=888.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=7. ttPurchaseItems.proc_compra_id=20.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=10. ttPurchaseItems.qt_comprada=0.
 CREATE ttItems. ASSIGN ttItems.item_container_id=1 ttItems.item_proc_compra_id=1 ttItems.container_id=123 ttItems.qt_alocada=10.
 CREATE ttItems. ASSIGN ttItems.item_container_id=2 ttItems.item_proc_compra_id=1 ttItems.container_id=999 ttItems.qt_alocada=80.
 CREATE ttItems. ASSIGN ttItems.item_container_id=3 ttItems.item_proc_compra_id=2 ttItems.container_id=999 ttItems.qt_alocada=5.
 CREATE ttItems. ASSIGN ttItems.item_container_id=4 ttItems.item_proc_compra_id=3 ttItems.container_id=123 ttItems.qt_alocada=5.
 CREATE ttItems. ASSIGN ttItems.item_container_id=5 ttItems.item_proc_compra_id=4 ttItems.container_id=999 ttItems.qt_alocada=10.004.
 CREATE ttItems. ASSIGN ttItems.item_container_id=6 ttItems.item_proc_compra_id=8 ttItems.container_id=999 ttItems.qt_alocada=9.996.
 CREATE ttItems. ASSIGN ttItems.item_container_id=7 ttItems.item_proc_compra_id=9 ttItems.container_id=999 ttItems.qt_alocada=9.994.
 CREATE ttItems. ASSIGN ttItems.item_container_id=8 ttItems.item_proc_compra_id=10 ttItems.container_id=123 ttItems.qt_alocada=1.
 requestValue=NEW JsonObject(). requestValue:Add("operation","read"). requestValue:Add("container_id",123).
END PROCEDURE.

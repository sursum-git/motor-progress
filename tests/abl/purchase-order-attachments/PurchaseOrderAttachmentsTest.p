BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttAttachments FIELD anexo_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD descricao AS CHARACTER FIELD tipos_anexo_id AS INTEGER FIELD caminho_arquivo AS CHARACTER FIELD dt_hr_arquivo AS DATETIME INDEX pk IS PRIMARY UNIQUE anexo_proc_compra_id.
DEFINE TEMP-TABLE ttItems FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttOrders FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttTypes FIELD tipo_anexo_id AS INTEGER FIELD descricao AS CHARACTER INDEX pk IS PRIMARY UNIQUE tipo_anexo_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE val AS JsonObject NO-UNDO. DEFINE VARIABLE d AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE seq AS INTEGER NO-UNDO INITIAL 100. DEFINE VARIABLE idValue AS INTEGER NO-UNDO. DEFINE VARIABLE stamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE referenceA AS CHARACTER NO-UNDO INITIAL 'ciwatt_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa_test.pdf'.
DEFINE VARIABLE referenceB AS CHARACTER NO-UNDO INITIAL 'ciwatt_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb_test.zip'.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO. DEFINE VARIABLE collision AS LOGICAL NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('order-attachments-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed.
 RUN Request('create'). val=NEW JsonObject(). val:Add('descricao','Documento geral'). val:Add('caminho_arquivo',referenceA). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'parent-only create must commit').
 d=res:GetJsonObject('data'). idValue=d:GetInteger('anexo_proc_compra_id'). stamp=d:GetCharacter('row_stamp').
 RUN Check(idValue=101 AND d:GetInteger('item_proc_compra_id')=0 AND d:GetInteger('proc_compra_id')=10,'parent creates a general attachment with generated identity').
 RUN Check(d:GetInteger('proc_compra_id_registro')=10 AND d:IsNull('arquivo_upload') AND NOT d:IsNull('dt_hr_arquivo'),'physical owner and server file date').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('actor'):GetCharacter('login')='teste' AND res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('item_proc_compra_id')=0,'authenticated actor and root image').
 RUN AddLegacy(1,10,11). RUN AddLegacy(2,10,?). RUN AddLegacy(3,20,0). RUN AddLegacy(4,10,999). RUN AddLegacy(5,10,21). RUN AddLegacy(6,999,11). RUN AddLegacy(7,10,-1).
 RUN Request('read'). req:Add('take',50). RUN Invoke. res:WriteFile('order-debug-read.json',TRUE). RUN Check(res:GetLogical('success') AND res:GetInteger('total')=3,'read only general and valid linked rows, no orphans or conflicting ownership').
 RUN Request('read'). req:Add('take',1). req:Add('skip',1). RUN Invoke. RUN Check(res:GetInteger('total')=3 AND res:GetJsonArray('data'):Length=1,'shared pagination').
 RUN Request('get'). req:Add('id',2). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):IsNull('item_proc_compra_id'),'legacy null item and date preserved').
 RUN Request('get'). req:Add('id',1). RUN Invoke. d=res:GetJsonObject('data').
 RUN Request('update'). req:Add('id',1). req:Add('row_stamp',d:GetCharacter('row_stamp')). val=NEW JsonObject(). val:Add('descricao','Item atualizado pelo processo'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('item_proc_compra_id')=11,'updating linked row never changes its item').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('item_proc_compra_id')=11 AND res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('item_proc_compra_id')=11,'linked before and after complete').
 RUN Request('get'). req:Add('id',3). RUN Invoke. RUN Status(404,'foreign process row blocked').
 RUN Request('get'). req:Add('id',4). RUN Invoke. RUN Status(404,'orphan item blocked').
 RUN Request('get'). req:Add('id',5). RUN Invoke. RUN Status(404,'item from other process blocked').
 RUN Request('get'). req:Add('id',6). RUN Invoke. RUN Status(404,'physical parent mismatch blocked without relinking').
 RUN Request('get'). req:Add('id',7). RUN Invoke. RUN Status(404,'negative historical item blocked').
 RUN Request('create'). req:Add('scope','item'). val=NEW JsonObject(). val:Add('caminho_arquivo',referenceA). req:Add('values',val). RUN Invoke. RUN Status(422,'browser scope cannot select adapter').
 RUN Request('create'). req:Add('item_proc_compra_id',11). val=NEW JsonObject(). val:Add('caminho_arquivo',referenceA). req:Add('values',val). RUN Invoke. RUN Status(422,'extra item context refused by parent adapter').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('item_proc_compra_id',11). req:Add('values',val). RUN Invoke. RUN Status(422,'item association is not writable').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('descricao','Atual'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('caminho_arquivo')=referenceA,'metadata-only edit preserves file reference').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('descricao')='Documento geral' AND res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('descricao')='Atual','before and after values').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('descricao','Stale'). req:Add('values',val). RUN Invoke. RUN Status(409,'stale stamp blocked').
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('descricao','Rollback'). val:Add('tipos_anexo_id',999). req:Add('values',val). RUN Invoke. RUN Status(422,'unknown type rolls back').
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. RUN Check(res:GetJsonObject('data'):GetCharacter('descricao')='Atual' AND res:GetJsonObject('data'):GetCharacter('row_stamp')=stamp,'metadata rollback confirmed').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('caminho_arquivo',referenceB). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('caminho_arquivo')=referenceA AND res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('caminho_arquivo')=referenceB,'replacement history retained'). stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('options'). req:Add('lookup','tipo_anexo'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=1,'shared contextual type lookup').
 RUN Request('delete'). req:Add('id',idValue). req:Add('row_stamp',stamp). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('item_proc_compra_id')=0 AND res:GetJsonObject('audit'):GetJsonArray('after'):Length=0,'general deletion full before absent after').
 RUN Check(NOT CAN-FIND(FIRST ttAttachments WHERE ttAttachments.anexo_proc_compra_id=idValue) AND CAN-FIND(FIRST ttAttachments WHERE ttAttachments.anexo_proc_compra_id=4),'unrelated and orphan rows untouched').
 RUN Request('read'). req:Remove('proc_compra_id'). req:Add('proc_compra_id',20). RUN Invoke. RUN Status(404,'non MED context blocked').
 RUN Request('read'). RUN InvokeItem. RUN Status(422,'old item API still requires item identity').
 RUN Request('read'). req:Add('item_proc_compra_id',0). RUN InvokeItem. RUN Status(422,'old item API never accepts header item0').
 RUN Request('read'). req:Add('item_proc_compra_id',11). req:Add('scope','order'). RUN InvokeItem. RUN Status(422,'old API refuses client scope override').
 DO TRANSACTION:
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=99 ttOrders.empresa_id=2.
  RUN Request('create'). val=NEW JsonObject(). val:Add('caminho_arquivo',referenceA). req:Add('values',val). RUN Invoke.
  RUN Status(409,'outer transaction refused without partial writes').
  UNDO, LEAVE.
 END.
 PUT UNFORMATTED 'PASS order attachments checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH err AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' err:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Status:
 DEFINE INPUT PARAMETER expected AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 RUN Check(NOT res:GetLogical('success') AND NOT res:GetLogical('committed') AND res:GetJsonObject('error'):GetInteger('status')=expected,msg).
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER operation AS CHARACTER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',operation). req:Add('proc_compra_id',10). 
END PROCEDURE.
PROCEDURE Invoke:
 RUN sursum-api/programs/PurchaseAttachmentsService.p(INPUT BUFFER ttAttachments:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttTypes:HANDLE,THIS-PROCEDURE,'teste','order',req,OUTPUT res).
END PROCEDURE.
PROCEDURE InvokeItem:
 RUN sursum-api/programs/PurchaseItemAttachmentsService.p(INPUT BUFFER ttAttachments:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttTypes:HANDLE,THIS-PROCEDURE,'teste',req,OUTPUT res).
END PROCEDURE.
PROCEDURE Seed:
 DO TRANSACTION:
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5.
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=1.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=20 ttOrders.empresa_id=3.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=11 ttItems.proc_compra_id=10.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=12 ttItems.proc_compra_id=10.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=21 ttItems.proc_compra_id=20.
  CREATE ttTypes. ASSIGN ttTypes.tipo_anexo_id=7 ttTypes.descricao='Documento'.
 END.
END PROCEDURE.
PROCEDURE AddLegacy:
 DEFINE INPUT PARAMETER rowId AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER orderId AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER childId AS INTEGER NO-UNDO.
 DO TRANSACTION: CREATE ttAttachments. ASSIGN ttAttachments.anexo_proc_compra_id=rowId ttAttachments.proc_compra_id=orderId ttAttachments.item_proc_compra_id=childId ttAttachments.descricao='Legado' ttAttachments.caminho_arquivo='antigo.pdf' ttAttachments.dt_hr_arquivo=?. END.
END PROCEDURE.
PROCEDURE NextRawPurchaseAttachmentId:
 DEFINE OUTPUT PARAMETER idOut AS INTEGER NO-UNDO. seq=seq + 1. idOut=seq.
END PROCEDURE.

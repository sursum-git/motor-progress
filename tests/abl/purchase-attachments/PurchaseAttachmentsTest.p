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
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('attachments-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed.
 RUN Request('create'). val=NEW JsonObject(). val:Add('descricao','Primeiro'). val:Add('tipos_anexo_id',7). val:Add('caminho_arquivo',referenceA). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'create committed').
 d=res:GetJsonObject('data'). idValue=d:GetInteger('anexo_proc_compra_id'). stamp=d:GetCharacter('row_stamp').
 RUN Check(idValue=101 AND d:GetInteger('proc_compra_id')=10 AND d:GetInteger('proc_compra_id_registro')=10 AND d:GetInteger('item_proc_compra_id')=11,'generated identity and owner').
 RUN Check(d:GetCharacter('caminho_arquivo')=referenceA AND NOT d:IsNull('dt_hr_arquivo') AND d:IsNull('arquivo_upload'),'server file reference date and empty browser token').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('actor'):GetCharacter('login')='teste' AND res:GetJsonObject('audit'):GetJsonArray('before'):Length=0,'actor and create image').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('owner_proc_compra_id')=10,'real owner audit').
 collision=TRUE. RUN Request('create'). val=NEW JsonObject(). val:Add('caminho_arquivo',referenceA). req:Add('values',val). RUN Invoke. RUN Status(409,'sequence collision blocked'). collision=FALSE.
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('descricao','Atual'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('caminho_arquivo')=referenceA,'metadata update preserves bytes reference').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('descricao')='Primeiro' AND res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('descricao')='Atual','before and after description').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('descricao','Stale'). req:Add('values',val). RUN Invoke. RUN Status(409,'stale update blocked').
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('descricao','Rollback'). val:Add('tipos_anexo_id',999). req:Add('values',val). RUN Invoke. RUN Status(422,'missing type rejected in root transaction').
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. RUN Check(res:GetJsonObject('data'):GetCharacter('descricao')='Atual' AND res:GetJsonObject('data'):GetCharacter('row_stamp')=stamp,'rollback preserves all metadata').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('caminho_arquivo',referenceB). val:AddNull('tipos_anexo_id'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('tipos_anexo_id')=0,'optional legacy type zero').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('caminho_arquivo')=referenceA AND res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('caminho_arquivo')=referenceB,'replacement preserves reference history'). stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('get'). req:Add('id',idValue). req:Remove('item_proc_compra_id'). req:Add('item_proc_compra_id',12). RUN Invoke. RUN Status(404,'foreign item blocked').
 RUN Request('get'). req:Add('id',idValue). req:Remove('proc_compra_id'). req:Add('proc_compra_id',20). RUN Invoke. RUN Status(404,'non MED blocked').
 RUN Request('create'). val=NEW JsonObject(). val:Add('descricao','Sem arquivo'). req:Add('values',val). RUN Invoke. RUN Status(422,'new file required').
 RUN Request('create'). val=NEW JsonObject(). val:Add('caminho_arquivo','../../etc/passwd'). req:Add('values',val). RUN Invoke. RUN Status(422,'path injection blocked').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',stamp). val=NEW JsonObject(). val:Add('dt_hr_arquivo','2020-01-01'). req:Add('values',val). RUN Invoke. RUN Status(422,'server date not writable').
 RUN Legacy.
 RUN Request('get'). req:Add('id',50). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('proc_compra_id')=10 AND res:GetJsonObject('data'):GetInteger('proc_compra_id_registro')=999,'legacy conflicting stored order retained with actual owner').
 RUN Check(res:GetJsonObject('data'):IsNull('dt_hr_arquivo'),'legacy null datetime retained').
 d=res:GetJsonObject('data'). RUN Request('update'). req:Add('id',50). req:Add('row_stamp',d:GetCharacter('row_stamp')). val=NEW JsonObject(). val:Add('descricao','Legado atualizado'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('proc_compra_id')=999 AND res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('proc_compra_id')=999,'legacy physical parent never silently repaired').
 RUN Request('read'). req:Add('take',1). req:Add('skip',0). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=2 AND res:GetJsonArray('data'):Length=1,'shared reader scope and paging').
 RUN Request('read'). val=NEW JsonObject(). val:Add('field','anexo_proc_compra_id'). val:Add('operator','eq'). val:Add('value',idValue). req:Add('filter',val). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'shared reader filter').
 RUN Request('options'). req:Add('lookup','tipo_anexo'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=1,'contextual type lookup').
 RUN Request('delete'). req:Add('id',idValue). req:Add('row_stamp',stamp). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('caminho_arquivo')=referenceB AND res:GetJsonObject('audit'):GetJsonArray('after'):Length=0,'delete before and absent after').
 RUN Check(NOT CAN-FIND(FIRST ttAttachments WHERE ttAttachments.anexo_proc_compra_id=idValue) AND CAN-FIND(FIRST ttAttachments WHERE ttAttachments.anexo_proc_compra_id=50),'only selected metadata removed').
 PUT UNFORMATTED 'PASS attachments checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
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
 req=NEW JsonObject(). req:Add('operation',operation). req:Add('proc_compra_id',10). req:Add('item_proc_compra_id',11).
END PROCEDURE.
PROCEDURE Invoke:
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
  CREATE ttTypes. ASSIGN ttTypes.tipo_anexo_id=7 ttTypes.descricao='Documento'.
 END.
END PROCEDURE.
PROCEDURE Legacy:
 DO TRANSACTION: CREATE ttAttachments. ASSIGN ttAttachments.anexo_proc_compra_id=50 ttAttachments.item_proc_compra_id=11 ttAttachments.proc_compra_id=999 ttAttachments.descricao='Legado' ttAttachments.caminho_arquivo='arquivo antigo.pdf' ttAttachments.dt_hr_arquivo=?. END.
END PROCEDURE.
PROCEDURE NextRawPurchaseAttachmentId:
 DEFINE OUTPUT PARAMETER idOut AS INTEGER NO-UNDO.
 IF collision THEN idOut=101. ELSE DO: seq=seq + 1. idOut=seq. END.
END PROCEDURE.

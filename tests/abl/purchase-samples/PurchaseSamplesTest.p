BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttSamples FIELD envio_amostra_repres_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD cod_rep AS INTEGER FIELD dt_envio AS DATE FIELD apont_amostra_id AS INTEGER INDEX pk IS PRIMARY UNIQUE envio_amostra_repres_id.
DEFINE TEMP-TABLE ttItems FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttOrders FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttReps FIELD cod-rep AS INTEGER FIELD nome-abrev AS CHARACTER FIELD ind-situacao AS INTEGER INDEX pk IS PRIMARY UNIQUE cod-rep.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE val AS JsonObject NO-UNDO. DEFINE VARIABLE dataValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO INITIAL 100. DEFINE VARIABLE idValue AS INTEGER NO-UNDO. DEFINE VARIABLE oldStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
DEFINE VARIABLE forceCollision AS LOGICAL NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('samples-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed.
 RUN Request('create'). val=NEW JsonObject(). val:Add('cod_rep',7). val:Add('dt_envio','2026-10-22'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'create commit').
 dataValue=res:GetJsonObject('data'). idValue=dataValue:GetInteger('envio_amostra_repres_id'). oldStamp=dataValue:GetCharacter('row_stamp').
 RUN Check(idValue=101 AND dataValue:GetInteger('proc_compra_id')=10 AND dataValue:GetInteger('item_proc_compra_id')=11,'generated key and actual owners').
 RUN Check(dataValue:GetCharacter('representante_nome')='Rep7' AND dataValue:GetInteger('apont_amostra_id')=0,'lookup and hidden field').
 RUN Check(res:GetJsonObject('audit'):GetJsonArray('before'):Length=0 AND res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('cod_rep')=7,'create complete audit').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('actor'):GetCharacter('login')='teste','authenticated actor').
 forceCollision=TRUE. RUN Request('create'). val=NEW JsonObject(). val:Add('cod_rep',8). req:Add('values',val). RUN Invoke. RUN Status(409,'sequence collision cannot overwrite an existing shipment'). forceCollision=FALSE.
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). val=NEW JsonObject(). val:AddNull('dt_envio'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):IsNull('dt_envio'),'nullable date update').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetCharacter('dt_envio')='2026-10-22' AND res:GetJsonObject('audit'):GetJsonObject('after'):IsNull('dt_envio'),'before after date').
 RUN Check(res:GetJsonObject('data'):GetCharacter('row_stamp')<>oldStamp,'stamp changes').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). val=NEW JsonObject(). val:Add('cod_rep',8). req:Add('values',val). RUN Invoke. RUN Status(409,'stale stamp rejected').
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('cod_rep')=7,'stale unchanged').
 oldStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Inactivate.
 RUN Request('options'). req:Add('lookup','representante'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=2 AND res:GetJsonArray('data'):GetJsonObject(2):GetInteger('value')=7,'native dropdown retains owned historical inactive representative').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). val=NEW JsonObject(). val:Add('cod_rep',7). val:Add('dt_envio','2026-10-23'). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success'),'historical inactive representative retained'). oldStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN HiddenLink.
 RUN Request('get'). req:Add('id',idValue). RUN Invoke. oldStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). val=NEW JsonObject(). val:Add('cod_rep',8). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('apont_amostra_id')=99,'unexposed fifth field preserved').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('apont_amostra_id')=99 AND res:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('apont_amostra_id')=99,'unexposed field audited'). oldStamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Request('get'). req:Add('id',idValue). req:Remove('item_proc_compra_id'). req:Add('item_proc_compra_id',12). RUN Invoke. RUN Status(404,'foreign item key rejected').
 RUN Request('get'). req:Add('id',idValue). req:Remove('proc_compra_id'). req:Add('proc_compra_id',20). RUN Invoke. RUN Status(404,'non MED parent rejected').
 RUN Request('update'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). val=NEW JsonObject(). val:Add('apont_amostra_id',42). req:Add('values',val). RUN Invoke. RUN Status(422,'hidden field not writable').
 RUN Request('create'). val=NEW JsonObject(). val:Add('cod_rep',7). req:Add('values',val). RUN Invoke. RUN Status(422,'inactive new representative rejected').
 RUN Request('create'). val=NEW JsonObject(). val:Add('cod_rep',8). val:Add('dt_envio','2026-02-30'). req:Add('values',val). RUN Invoke. RUN Status(422,'invalid date after create rolls back').
 RUN Check(NOT CAN-FIND(FIRST ttSamples WHERE ttSamples.envio_amostra_repres_id=103),'no partial row after rollback').
 RUN Request('create'). val=NEW JsonObject(). val:Add('cod_rep',8). req:Add('values',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('envio_amostra_repres_id')=104,'sequence gaps never reused').
 RUN ForeignRow.
 RUN Request('read'). req:Add('take',1). req:Add('skip',0). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=2 AND res:GetJsonArray('data'):Length=1,'shared reader paginates only selected item').
 RUN Check(res:GetJsonArray('data'):GetJsonObject(1):GetInteger('item_proc_compra_id')=11 AND res:GetJsonArray('data'):GetJsonObject(1):Has('row_stamp') AND NOT res:GetJsonArray('data'):GetJsonObject(1):Has('record_key'),'eight field projection uses integer identity').
 RUN Request('read'). val=NEW JsonObject(). val:Add('field','envio_amostra_repres_id'). val:Add('operator','eq'). val:Add('value',104). req:Add('filter',val). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1 AND res:GetJsonArray('data'):GetJsonObject(1):GetInteger('envio_amostra_repres_id')=104,'shared reader filter').
 RUN Request('options'). req:Add('lookup','representante'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=1 AND res:GetJsonArray('data'):GetJsonObject(1):GetInteger('value')=8,'only active lookup').
 RUN Request('delete'). req:Add('id',idValue). req:Add('row_stamp',oldStamp). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('audit'):GetJsonObject('before'):GetInteger('apont_amostra_id')=99 AND res:GetJsonObject('audit'):GetJsonArray('after'):Length=0,'delete complete before and empty after').
 RUN Check(NOT CAN-FIND(FIRST ttSamples WHERE ttSamples.envio_amostra_repres_id=idValue),'delete removes only target').
 PUT UNFORMATTED 'PASS samples checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
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
 RUN sursum-api/programs/PurchaseSamplesService.p(INPUT BUFFER ttSamples:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttReps:HANDLE,THIS-PROCEDURE,'teste',req,OUTPUT res).
END PROCEDURE.
PROCEDURE Seed:
 DO TRANSACTION:
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5.
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=1.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2.
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=20 ttOrders.empresa_id=3.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=11 ttItems.proc_compra_id=10.
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=12 ttItems.proc_compra_id=10.
  CREATE ttReps. ASSIGN ttReps.cod-rep=7 ttReps.nome-abrev='Rep7' ttReps.ind-situacao=1.
  CREATE ttReps. ASSIGN ttReps.cod-rep=8 ttReps.nome-abrev='Rep8' ttReps.ind-situacao=1.
 END.
END PROCEDURE.
PROCEDURE Inactivate: DO TRANSACTION: FIND ttReps WHERE ttReps.cod-rep=7. ttReps.ind-situacao=0. END. END PROCEDURE.
PROCEDURE HiddenLink: DO TRANSACTION: FIND ttSamples WHERE ttSamples.envio_amostra_repres_id=idValue. ttSamples.apont_amostra_id=99. END. END PROCEDURE.
PROCEDURE ForeignRow: DO TRANSACTION: CREATE ttSamples. ASSIGN ttSamples.envio_amostra_repres_id=900 ttSamples.item_proc_compra_id=12 ttSamples.cod_rep=8. END. END PROCEDURE.
PROCEDURE NextRawPurchaseSampleId: DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO. IF forceCollision THEN DO: valueId=101. RETURN. END. sequenceValue=sequenceValue + 1. valueId=sequenceValue. END PROCEDURE.

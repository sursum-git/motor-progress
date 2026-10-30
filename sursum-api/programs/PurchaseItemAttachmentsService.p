/* Metadata only. The shared PHP storage owns bytes; no file IO or formulas here. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phAttachments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTypes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdentity AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
servicePath=SEARCH('sursum-api/programs/PurchaseAttachmentsService.r').
IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Nucleo de anexos nao publicado.',1).
RUN VALUE(servicePath)(phAttachments,phItems,phOrders,phCompanies,phTypes,phIdentity,pcActor,'item',poRequest,OUTPUT poResponse).

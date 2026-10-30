/* Compatible six-parameter adapter. One shared CRUD core, private identity provider. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phReference1 AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phReference2 AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poDefinition AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE identityHandle AS HANDLE NO-UNDO. DEFINE VARIABLE corePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE providerPath AS CHARACTER NO-UNDO. DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF VALID-OBJECT(poDefinition) AND VALID-OBJECT(poRequest) THEN DO:
  IF poDefinition:Has('resource') AND poDefinition:GetType('resource')=JsonDataType:STRING AND poDefinition:GetCharacter('resource')='formatos_amostra' AND poRequest:Has('operation') AND poRequest:GetType('operation')=JsonDataType:STRING THEN DO:
   IF LOOKUP(poRequest:GetCharacter('operation'),'create,batch')>0 THEN DO:
    providerPath=SEARCH('sursum-api/programs/CiwCadastroSequenceIdentity.r').
    IF providerPath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Identity provider unavailable',1).
    RUN VALUE(providerPath) PERSISTENT SET identityHandle.
   END.
  END.
 END.
 corePath=SEARCH('sursum-api/programs/CiwCadastroCoreService.r').
 IF corePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('CRUD core unavailable',1).
 RUN VALUE(corePath)(phData,phReference1,phReference2,identityHandle,poDefinition,poRequest,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject().
  err:Add('code','CIW_CADASTRO_CONFIGURATION'). err:Add('status',503). err:Add('message','Cadastro indisponivel.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY: IF VALID-HANDLE(identityHandle) THEN DELETE PROCEDURE identityHandle. END FINALLY.
END.

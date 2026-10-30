USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO.
DEFINE VARIABLE webhooksValue AS DynamicQueryConsumerWebhooks NO-UNDO.
DEFINE VARIABLE configValue AS JsonObject NO-UNDO.
DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
DEFINE VARIABLE taskValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE payloadValue AS JsonObject NO-UNDO.
DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
DEFINE VARIABLE rootValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE jobIdValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.

rootValue='consumer-webhook-claim-tests-' + SUBSTRING(LC(HEX-ENCODE(GENERATE-UUID)),1,12).
OS-CREATE-DIR VALUE(rootValue + '.jobs') NO-ERROR.
configValue=NEW JsonObject().
configValue:Add('accessTokenStore',rootValue).
repositoryValue=NEW DynamicQueryConsumerJobRepository(rootValue + '.jobs').
jobValue=repositoryValue:createJob('~{~}','~{"consumerId":"owner"~}','~{~}','CONSUMER',3,'').
jobIdValue=jobValue:GetCharacter('jobId').
DELETE OBJECT jobValue.

jobValue=repositoryValue:getJob(jobIdValue).
jobValue:Set('status','completed').
jobValue:Set('resultPath',rootValue + '.jobs/' + jobIdValue + '.json').
payloadValue=NEW JsonObject().
payloadValue:Add('success',TRUE).
RUN Assert(payloadValue:WriteFile(rootValue + '.jobs/' + jobIdValue + '.json',FALSE),'write completed result').
RUN Assert(jobValue:WriteFile(rootValue + '.jobs/' + jobIdValue + '.job.json',FALSE),'write completed job').
DELETE OBJECT payloadValue.
DELETE OBJECT jobValue.

taskValue=NEW JsonObject().
taskValue:Add('consumerId','owner').
taskValue:Add('code','q').
taskValue:Add('url','https://example.invalid/webhook').
taskValue:Add('secret','secret').
taskValue:Add('version',1).
jobValue=repositoryValue:queueWebhook(jobIdValue,taskValue).

webhooksValue=NEW DynamicQueryConsumerWebhooks().
resultValue=webhooksValue:claim(configValue,OUTPUT statusValue).
RUN Assert(statusValue=200 AND resultValue:GetLogical('success'),'claim queued webhook').
RUN Assert(resultValue:GetCharacter('jobId')=jobIdValue,'claim preserves job id').
RUN Assert(resultValue:GetCharacter('lease')<>'' ,'claim returns webhook lease').
RUN Assert(resultValue:GetCharacter('url')='https://example.invalid/webhook','claim returns registered url').
payloadValue=resultValue:GetJsonObject('payload').
RUN Assert(payloadValue:GetLogical('success'),'claim returns completed payload').

DELETE OBJECT payloadValue.
DELETE OBJECT resultValue.
DELETE OBJECT webhooksValue.
DELETE OBJECT repositoryValue.
DELETE OBJECT configValue.
OS-DELETE VALUE(rootValue + '.jobs/' + jobIdValue + '.job.json') VALUE(rootValue + '.jobs/' + jobIdValue + '.json') VALUE(rootValue + '.jobs/queue.lock') NO-ERROR.
OS-DELETE VALUE(rootValue + '.jobs') NO-ERROR.
OUTPUT TO 'consumer-webhook-claim-tests.log'.
PUT UNFORMATTED 'PASS ' checks ' consumer webhook claim checks; NUMDBS=' NUM-DBS SKIP.
OUTPUT CLOSE.

PROCEDURE Assert:
 DEFINE INPUT PARAMETER conditionValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF conditionValue<>TRUE THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 checks=checks + 1.
END PROCEDURE.

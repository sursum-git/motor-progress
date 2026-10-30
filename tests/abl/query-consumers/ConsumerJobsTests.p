USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE jobs AS DynamicQueryConsumerJobs NO-UNDO.
DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE configValue AS JsonObject NO-UNDO.
DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO.
DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE metadataText AS LONGCHAR NO-UNDO.
jobs=NEW DynamicQueryConsumerJobs(). parserValue=NEW ObjectModelParser().
configValue=CAST(parserValue:Parse('~{"consumers":[~{"id":"owner","role":"consumer","active":true,"expiresAtEpoch":2000,"queries":["q"]~}]~}'),JsonObject).
RUN Assert(jobs:canAccess(configValue,'owner','q',1000),'owner permission').
RUN Assert(NOT jobs:canAccess(configValue,'other','q',1000),'other consumer').
RUN Assert(NOT jobs:canAccess(configValue,'Owner','q',1000),'case sensitive identity').
RUN Assert(NOT jobs:canAccess(configValue,'owner','other',1000),'other query').
RUN Assert(NOT jobs:canAccess(configValue,'owner','q',2000),'expiry').
metadataValue=CAST(parserValue:Parse('~{"kind":"consumer-query-v1","consumerId":"owner","code":"q","paginate":true~}'),JsonObject).
jobValue=NEW JsonObject(). jobValue:Add('success',TRUE). jobValue:Add('executionMode','CONSUMER').
jobValue:Add('jobId','JOB-20261028-000001-123456'). jobValue:Add('status','queued').
metadataValue:Write(metadataText,FALSE). jobValue:Add('planJson',metadataText).
jobValue:Add('requestJson','private'). jobValue:Add('resultPath','/private/file').
resultValue=jobs:publicStatus(jobValue,metadataValue).
RUN Assert(NOT resultValue:Has('planJson') AND NOT resultValue:Has('requestJson') AND NOT resultValue:Has('resultPath'),'no internal metadata').
RUN Assert(resultValue:GetCharacter('code')='q','own query code').
RUN Assert(jobs:isJobId('JOB-20261028-000001-123456'),'job id').
RUN Assert(NOT jobs:isJobId('../consumers'),'path traversal').
RUN Assert(NOT jobs:isJobId('JOB-20261028-000001-123456/result'),'suffix not job id').
metadataValue=CAST(parserValue:Parse('~{~"kind~":~"consumer-query-v1~",~"consumerId~":~"owner~",~"code~":~"q~",~"paginate~":false,~"parallel~":~{~"enabled~":true,~"totalPartitions~":1826,~"completedPartitions~":0,~"runningPartitions~":0,~"failedPartitions~":0}}'),JsonObject).
metadataValue:Write(metadataText,FALSE). jobValue:Set('planJson',metadataText).
resultValue=jobs:publicStatus(jobValue,metadataValue).
RUN Assert(resultValue:Has('parallel') AND resultValue:GetJsonObject('parallel'):GetInteger('totalPartitions')=1826,'parallel status is public without plan internals').
OUTPUT TO 'consumer-jobs-tests.log'. PUT UNFORMATTED 'PASS ' checks ' consumer jobs checks' SKIP. OUTPUT CLOSE.
PROCEDURE Assert:
 DEFINE INPUT PARAMETER expected AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF expected<>TRUE THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 checks=checks + 1.
END PROCEDURE.

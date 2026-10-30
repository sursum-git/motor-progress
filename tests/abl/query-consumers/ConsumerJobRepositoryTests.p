USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE firstRepo AS DynamicQueryConsumerJobRepository NO-UNDO.
DEFINE VARIABLE secondRepo AS DynamicQueryConsumerJobRepository NO-UNDO.
DEFINE VARIABLE optionsValue AS DynamicQueryWorkerOptions NO-UNDO.
DEFINE VARIABLE contextValue AS PasoeExecutionContext NO-UNDO.
DEFINE VARIABLE firstValue AS JsonObject NO-UNDO.
DEFINE VARIABLE secondValue AS JsonObject NO-UNDO.
DEFINE VARIABLE countsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE receiptValue AS JsonObject NO-UNDO.
DEFINE VARIABLE firstId AS CHARACTER NO-UNDO.
DEFINE VARIABLE secondId AS CHARACTER NO-UNDO.
DEFINE VARIABLE rootValue AS CHARACTER NO-UNDO INITIAL 'consumer-job-tests'.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
DEFINE VARIABLE thirdId AS CHARACTER NO-UNDO.
DEFINE VARIABLE orphanPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE beforeBytes AS INT64 NO-UNDO.
rootValue='consumer-job-tests-' + SUBSTRING(LC(HEX-ENCODE(GENERATE-UUID)),1,12).
OS-CREATE-DIR VALUE(rootValue) NO-ERROR.
firstRepo=NEW DynamicQueryConsumerJobRepository(rootValue). secondRepo=NEW DynamicQueryConsumerJobRepository(rootValue).
optionsValue=NEW DynamicQueryWorkerOptions(). contextValue=NEW PasoeExecutionContext().
firstValue=firstRepo:createJob('~{~}','~{"consumerId":"first"~}','~{~}','CONSUMER',3,''). firstId=firstValue:GetCharacter('jobId'). DELETE OBJECT firstValue.
secondValue=secondRepo:createJob('~{~}','~{"consumerId":"second"~}','~{~}','CONSUMER',3,''). secondId=secondValue:GetCharacter('jobId'). DELETE OBJECT secondValue.
countsValue=firstRepo:pendingConsumerJobs('first').
RUN Assert(countsValue:GetInteger('total')=2 AND countsValue:GetInteger('consumer')=1,'persisted quotas'). DELETE OBJECT countsValue.
firstValue=firstRepo:claimConsumerNext(optionsValue,contextValue). firstId=firstValue:GetCharacter('jobId').
secondValue=secondRepo:claimConsumerNext(optionsValue,contextValue). secondId=secondValue:GetCharacter('jobId').
RUN Assert(firstId<>secondId,'different workers claim different jobs').
countsValue=firstRepo:claimConsumerNext(optionsValue,contextValue).
RUN Assert(NOT countsValue:GetLogical('success'),'running not claimed twice'). DELETE OBJECT countsValue.
resultValue=NEW JsonObject(). resultValue:Add('success',TRUE). resultValue:Add('data',NEW JsonArray()).
RUN Assert(resultValue:WriteFile(firstRepo:temporaryResultPath(firstId),FALSE),'write isolated attempt result').
DO ON ERROR UNDO, THROW:
 receiptValue=secondRepo:completeJob(firstId,rootValue + '/' + firstId + '.json',0,FALSE,'').
 CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH.
END.
RUN Assert(rejected,'wrong lease cannot complete').
receiptValue=firstRepo:completeJob(firstId,rootValue + '/' + firstId + '.json',0,FALSE,'').
RUN Assert(receiptValue:GetCharacter('status')='completed','atomic result completion'). DELETE OBJECT receiptValue.
DO n=1 TO 3:
 receiptValue=secondRepo:failJob(secondId,'test','test','','').
 RUN Assert(receiptValue:GetCharacter('status')=(IF n<3 THEN 'queued' ELSE 'failed'),'bounded retries'). DELETE OBJECT receiptValue.
 IF n<3 THEN DO: DELETE OBJECT secondValue. secondValue=secondRepo:claimConsumerNext(optionsValue,contextValue). END.
END.
countsValue=firstRepo:pendingConsumerJobs('first'). RUN Assert(countsValue:GetInteger('total')=0,'terminal jobs not pending'). DELETE OBJECT countsValue.
countsValue=firstRepo:pendingConsumerJobs('first'). beforeBytes=countsValue:GetInt64('bytes'). DELETE OBJECT countsValue.
orphanPath=rootValue + '/' + firstId + '.' + FILL('a',32) + '.result.tmp'.
RUN Assert(resultValue:WriteFile(orphanPath,FALSE),'simulate abandoned temporary').
countsValue=firstRepo:pendingConsumerJobs('first'). RUN Assert(countsValue:GetInt64('bytes')>beforeBytes,'abandoned temporary counts against quota'). DELETE OBJECT countsValue.
DELETE OBJECT firstValue. firstValue=firstRepo:getJob(firstId). firstValue:Set('createdEpoch',INT64(0)).
RUN Assert(firstValue:WriteFile(rootValue + '/' + firstId + '.job.json',FALSE),'age own terminal fixture').
countsValue=firstRepo:claimConsumerNext(optionsValue,contextValue). DELETE OBJECT countsValue.
FILE-INFO:FILE-NAME=orphanPath. RUN Assert(FILE-INFO:FULL-PATHNAME=?,'old abandoned temporary pruned').
receiptValue=firstRepo:createJob('~{~}','~{"consumerId":"first"~}','~{~}','CONSUMER',3,''). thirdId=receiptValue:GetCharacter('jobId'). DELETE OBJECT receiptValue.
receiptValue=firstRepo:claimConsumerNext(optionsValue,contextValue). receiptValue:Set('leaseExpires',INT64(0)).
RUN Assert(receiptValue:WriteFile(rootValue + '/' + thirdId + '.job.json',FALSE),'expire own lease fixture'). DELETE OBJECT receiptValue.
receiptValue=secondRepo:claimConsumerNext(optionsValue,contextValue). RUN Assert(receiptValue:GetCharacter('jobId')=thirdId,'expired lease reclaimed'). DELETE OBJECT receiptValue.
rejected=FALSE.
DO ON ERROR UNDO, THROW:
 orphanPath=firstRepo:temporaryResultPath(thirdId).
 CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH.
END.
RUN Assert(rejected,'old worker cannot begin result write after reclaim').
OS-DELETE VALUE(rootValue + '/' + thirdId + '.job.json') NO-ERROR.
OS-DELETE VALUE(rootValue + '/' + firstId + '.job.json') VALUE(rootValue + '/' + firstId + '.json') VALUE(rootValue + '/' + secondId + '.job.json') NO-ERROR.
OS-DELETE VALUE(rootValue + '/queue.lock') NO-ERROR. OS-DELETE VALUE(rootValue) NO-ERROR.
OUTPUT TO 'consumer-job-repository-tests.log'. PUT UNFORMATTED 'PASS ' checks ' private queue checks; NUMDBS=' NUM-DBS SKIP. OUTPUT CLOSE.
PROCEDURE Assert:
 DEFINE INPUT PARAMETER conditionValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF conditionValue<>TRUE THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 checks=checks + 1.
END PROCEDURE.

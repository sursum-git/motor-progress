USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE planner AS DynamicQueryConsumerParallelJobs NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE parts AS JsonArray NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE planValue AS JsonObject NO-UNDO.
DEFINE VARIABLE claimValue AS JsonObject NO-UNDO.
DEFINE VARIABLE failureClaimValue AS JsonObject NO-UNDO.
DEFINE VARIABLE exporter AS DynamicQueryConsumerParallelExport NO-UNDO.
DEFINE VARIABLE exportValue AS JsonObject NO-UNDO.
DEFINE VARIABLE emptyPartValue AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
parser=NEW ObjectModelParser(). planner=NEW DynamicQueryConsumerParallelJobs().
cfg=CAST(parser:Parse('~{~"enabled~":true,~"partition~":~{~"strategy~":~"date-day~",~"startParameter~":~"dataInicial~",~"endParameter~":~"dataFinal~"},~"maxWorkers~":10,~"maxPartitions~":10,~"maxPartitionRecords~":100000,~"maxPartitionBytes~":268435456,~"maxResultBytes~":10737418240}'),JsonObject).
RUN Assert(planner:hasSafePartitionLimits(cfg),'configured record and byte ceilings are accepted').
cfg:Remove('maxPartitionRecords').
RUN Assert(NOT planner:hasSafePartitionLimits(cfg),'missing record ceiling is rejected').
cfg:Add('maxPartitionRecords',100000).
cfg:Set('maxResultBytes',1048576).
RUN Assert(NOT planner:hasSafePartitionLimits(cfg),'partition bytes cannot exceed final export ceiling').
cfg=CAST(parser:Parse('~{~"enabled~":true,~"partition~":~{~"strategy~":~"date-day~",~"startParameter~":~"dataInicial~",~"endParameter~":~"dataFinal~"},~"maxWorkers~":10,~"maxPartitions~":10,~"maxPartitionRecords~":100000,~"maxPartitionBytes~":268435456,~"maxResultBytes~":10737418240}'),JsonObject).
cfg:Add('workerSchedule',CAST(parser:Parse('~{~"timezone~":~"America/Sao_Paulo~",~"windows~":[~{~"start~":~"20:00~",~"end~":~"05:00~",~"maxWorkers~":8},~{~"start~":~"05:00~",~"end~":~"20:00~",~"maxWorkers~":4}]}'),JsonObject)).
RUN Assert(planner:hasSafePartitionLimits(cfg),'complete Sao Paulo worker schedule is accepted').
RUN Assert(planner:workerLimitAtMinute(cfg,1200)=8,'20:00 resolves to the night worker ceiling').
RUN Assert(planner:workerLimitAtMinute(cfg,300)=4,'05:00 resolves to the daytime worker ceiling').
request=CAST(parser:Parse('~{~"dataInicial~":~"2021-01-01~",~"dataFinal~":~"2021-01-03~"}'),JsonObject).
parts=planner:dateDayPartitions(cfg,request).
RUN Assert(parts:Length=3,'one partition per day').
RUN Assert(parts:GetJsonObject(1):GetCharacter('dataInicial')='2021-01-01','first partition start').
RUN Assert(parts:GetJsonObject(3):GetCharacter('dataFinal')='2021-01-03','last partition end').
request=CAST(parser:Parse('~{~"dataInicial~":~"2021-01-01~",~"dataFinal~":~"2025-12-31~"}'),JsonObject).
cfg:Set('maxPartitions',2000).
parts=planner:dateDayPartitions(cfg,request).
RUN Assert(parts:Length=1826,'five years fits the configured partition limit').
RUN Assert(planner:initializePlan('consumer-parallel-plan-tests', 'JOB-20261029-000001-123456', parts, planner:workerLimitAtMinute(cfg,1200)),'persist private master plan').
planValue=planner:readPlan('consumer-parallel-plan-tests','JOB-20261029-000001-123456').
RUN Assert(planValue:GetInteger('totalPartitions')=1826,'master plan tracks total partitions').
RUN Assert(planValue:GetInteger('maxWorkers')=8,'saved plan retains the resolved worker ceiling').
DO n=1 TO 8: claimValue=planner:claimPartition(planValue,7200). RUN Assert(claimValue:GetLogical('success'),'claim within worker limit'). END.
RUN Assert(planner:savePlan('consumer-parallel-plan-tests','JOB-20261029-000001-123456',planValue),'claimed plan persists atomically').
DELETE OBJECT planValue.
planValue=planner:readPlan('consumer-parallel-plan-tests','JOB-20261029-000001-123456').
RUN Assert(planValue:GetInteger('runningPartitions')=8,'reloaded plan preserves active count').
claimValue=planner:claimPartition(planValue,7200).
RUN Assert(NOT claimValue:GetLogical('success'),'ninth claim respects the night worker limit').
request=CAST(parser:Parse('~{~"dataInicial~":~"2021-01-01~",~"dataFinal~":~"2021-01-01~"}'),JsonObject).
parts=planner:dateDayPartitions(cfg,request).
RUN Assert(planner:initializePlan('consumer-parallel-plan-tests', 'JOB-20261029-000002-123456', parts, 1),'persist plan for failed partition').
planValue=planner:readPlan('consumer-parallel-plan-tests','JOB-20261029-000002-123456').
failureClaimValue=planner:claimPartition(planValue,7200).
RUN Assert(failureClaimValue:GetLogical('success'),'claim partition to record an explicit failure').
RUN Assert(planner:completePartition(planValue,failureClaimValue:GetJsonObject('partition'):GetInteger('partitionId'),failureClaimValue:GetJsonObject('partition'):GetCharacter('lease'),FALSE,'PARALLEL_PARTITION_RECORD_LIMIT'),'failed partition is completed with a sanitized cause').
RUN Assert(planValue:GetJsonArray('partitions'):GetJsonObject(1):GetCharacter('failureCode')='PARALLEL_PARTITION_RECORD_LIMIT','failed partition retains the explicit limit cause').
/* An empty but valid range is still an export: it must produce a gzip artifact,
   rather than leaving its job in the consolidation lease. The official
   compiler is Windows, while the production exporter deliberately calls the
   Linux gzip binary, so execute this artifact assertion in PASOE/Linux. */
IF OPSYS='UNIX' THEN DO:
 exporter=NEW DynamicQueryConsumerParallelExport().
 OS-CREATE-DIR VALUE('consumer-parallel-export-tests') NO-ERROR.
 emptyPartValue=CAST(parser:Parse('~{~"success~":true,~"data~":[]}'),JsonObject).
 RUN Assert(emptyPartValue:WriteFile('consumer-parallel-export-tests/JOB-20261029-000003-123456.part-1.json',FALSE),'write first empty partition').
 RUN Assert(emptyPartValue:WriteFile('consumer-parallel-export-tests/JOB-20261029-000003-123456.part-2.json',FALSE),'write second empty partition').
 exportValue=exporter:consolidate('consumer-parallel-export-tests','JOB-20261029-000003-123456',2,10737418240,268435456).
 RUN Assert(exportValue:GetLogical('success'),'empty partitions consolidate into an artifact').
 RUN Assert(exportValue:GetInteger('recordsReturned')=0,'empty partition export retains zero records').
 FILE-INFO:FILE-NAME='consumer-parallel-export-tests/JOB-20261029-000003-123456.ndjson.gz'.
 RUN Assert(FILE-INFO:FULL-PATHNAME<>? AND FILE-INFO:FILE-SIZE>0,'empty partition export writes nonempty gzip').
 OS-DELETE VALUE('consumer-parallel-export-tests/JOB-20261029-000003-123456.part-1.json') NO-ERROR.
 OS-DELETE VALUE('consumer-parallel-export-tests/JOB-20261029-000003-123456.part-2.json') NO-ERROR.
 OS-DELETE VALUE('consumer-parallel-export-tests/JOB-20261029-000003-123456.ndjson.gz') NO-ERROR.
 OS-DELETE VALUE('consumer-parallel-export-tests') NO-ERROR.
END.
OS-DELETE VALUE('consumer-parallel-plan-tests/JOB-20261029-000001-123456.parallel.json') NO-ERROR.
OS-DELETE VALUE('consumer-parallel-plan-tests/JOB-20261029-000002-123456.parallel.json') NO-ERROR.
OS-DELETE VALUE('consumer-parallel-plan-tests') NO-ERROR.
OUTPUT TO 'consumer-parallel-partition-tests.log'. PUT UNFORMATTED 'PASS ' checks ' parallel partition checks' SKIP. OUTPUT CLOSE.
PROCEDURE Assert:
 DEFINE INPUT PARAMETER conditionValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF conditionValue<>TRUE THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 checks=checks + 1.
END PROCEDURE.

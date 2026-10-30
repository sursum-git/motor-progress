DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
PROPATH = "C:\\Users\\tadeu.parreiras\\codex-movto-estoq-20261029,C:\\opencode\\motor-progress\\v2\\sursum-api\\sursum,C:\\opencode\\motor-progress\\v2\\sursum-api\\rest,C:\\opencode\\motor-progress\\v2\\sursum-api\\programs,C:\\Progress_12\\OE\\gui\\OpenEdge.Core.pl,C:\\Progress_12\\OE\\gui\\netlib\\OpenEdge.Net.pl,C:\\Progress_12\\OE\\gui,C:\\Progress_12\\OE," + PROPATH.
OUTPUT TO "consumer-parallel-stage-compile.log".
COMPILE "C:\\Users\\tadeu.parreiras\\codex-movto-estoq-20261029\\DynamicQueryWebHandler.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicQueryWebHandler.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "DynamicQueryConsumerParallelJobs.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicQueryConsumerParallelJobs.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "DynamicQueryConsumerParallelExport.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicQueryConsumerParallelExport.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "DynamicMultiTableQueryService.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicMultiTableQueryService.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "DynamicQueryConsumerJobRepository.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicQueryConsumerJobRepository.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "DynamicQueryConsumerJobs.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicQueryConsumerJobs.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "DynamicQueryConsumerWebhooks.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "DynamicQueryConsumerWebhooks.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
COMPILE "SecuredDynamicQueryWebHandler.cls" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED "SecuredDynamicQueryWebHandler.cls: " ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
IF COMPILER:ERROR THEN failed=TRUE.
PUT UNFORMATTED "COMPILER_ERROR=" failed SKIP.
OUTPUT CLOSE.
QUIT.

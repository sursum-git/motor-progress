DEFINE VARIABLE i AS INTEGER NO-UNDO.
PROPATH = "C:\\Users\\tadeu.parreiras\\codex-movto-estoq-20261029,C:\\opencode\\motor-progress\\v2\\sursum-api\\sursum,C:\\opencode\\motor-progress\\v2\\sursum-api\\rest,C:\\opencode\\motor-progress\\v2\\sursum-api\\programs,C:\\Progress_12\\OE\\gui\\OpenEdge.Core.pl,C:\\Progress_12\\OE\\gui\\netlib\\OpenEdge.Net.pl,C:\\Progress_12\\OE\\gui,C:\\Progress_12\\OE," + PROPATH.
OUTPUT TO "consumer-jobs-compile.log".
COMPILE "ConsumerJobsTests.p" SAVE NO-ERROR.
DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
PUT UNFORMATTED "COMPILER_ERROR=" COMPILER:ERROR SKIP.
IF COMPILER:ERROR THEN DO: OUTPUT CLOSE. QUIT. END.
OUTPUT CLOSE.
RUN ConsumerJobsTests.p.
QUIT.

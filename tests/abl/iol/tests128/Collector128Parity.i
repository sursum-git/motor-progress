/* Compiled only by Collector128ParityTest; all physical fixture writes rolled back. */
DEFINE VARIABLE hParityBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE hParityQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE nParitySource AS INTEGER NO-UNDO.
DEFINE VARIABLE cParityTable AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcBaseline AS LONGCHAR NO-UNDO.
DEFINE VARIABLE lcAggregate AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oAggregate AS JsonObject NO-UNDO.
DEFINE VARIABLE iParityCase AS INTEGER NO-UNDO.
IF NUM-DBS<>1 OR INDEX(PDBNAME(1),"aggregate-fixture")=0 THEN RETURN ERROR "FIXTURE_DATABASE_REQUIRED".
snapshotData:Write(lcBaseline).
DO TRANSACTION ON ERROR UNDO, THROW:
 DO nParitySource=8 TO 11 BY 3:
  cParityTable=IF nParitySource=8 THEN "espec.metas_repres" ELSE "espec.peds_web".
  CREATE BUFFER hParityBuffer FOR TABLE cParityTable.
  CREATE QUERY hParityQuery. hParityQuery:SET-BUFFERS(hSources[nParitySource]).
  hParityQuery:QUERY-PREPARE("FOR EACH " + hSources[nParitySource]:NAME).
  hParityQuery:QUERY-OPEN(). hParityQuery:GET-FIRST().
  DO WHILE NOT hParityQuery:QUERY-OFF-END:
   hParityBuffer:BUFFER-CREATE(). hParityBuffer:BUFFER-COPY(hSources[nParitySource]).
   hParityBuffer:BUFFER-RELEASE(). hParityQuery:GET-NEXT().
  END.
  hParityQuery:QUERY-CLOSE(). DELETE OBJECT hParityQuery. DELETE OBJECT hParityBuffer.
 END.
 DO iParityCase=1 TO 3:
  IF iParityCase=2 THEN DO:
   scopeData:Set("role",3). scopeData:Set("representative",9). scopeData:Set("hierarchy_type",3).
  END.
  IF iParityCase=3 THEN DO:
   scopeData:Set("role",4). scopeData:Set("general",TRUE). scopeData:Set("hierarchy_type",0).
   scopeData:Set("representatives",""). scopeData:Set("names","").
  END.
  RUN IolGerencialCollector.p(scopeData,DATE(10,16,2026),hSources,OUTPUT snapshotData).
  snapshotData:Write(lcBaseline).
  scopeData:Add("_aggregate_program","IolGerencialAggregate128.r").
  RUN IolGerencialCollector.p(scopeData,DATE(10,16,2026),hSources,OUTPUT oAggregate).
  oAggregate:Write(lcAggregate).
  scopeData:Remove("_aggregate_program").
  IF lcBaseline<>lcAggregate THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL collector 12.2/12.8 snapshot parity case=" + STRING(iParityCase),1).
  DELETE OBJECT oAggregate.
 END.
 UNDO, LEAVE.
END.
IF CAN-FIND(FIRST espec.metas_repres) OR CAN-FIND(FIRST espec.peds_web) THEN
 UNDO, THROW NEW Progress.Lang.AppError("FAIL parity fixture cleanup",1).
OUTPUT TO VALUE("collector-parity-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS collector full snapshot parity checks=3 seller/manager/general 12.2/12.8; cleanup=rollback" SKIP.
OUTPUT CLOSE.

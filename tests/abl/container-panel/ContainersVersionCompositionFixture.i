/* Extend shared real-cost fixture to complete undoable physical writer tables. */
PROCEDURE ExtendTable:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER extraFields AS CHARACTER NO-UNDO.
 DEFINE VARIABLE newTable AS HANDLE NO-UNDO.
 DEFINE VARIABLE newBuffer AS HANDLE NO-UNDO.
 DEFINE VARIABLE oldTable AS HANDLE NO-UNDO.
 DEFINE VARIABLE oldBuffer AS HANDLE NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldValue AS CHARACTER NO-UNDO.
 ASSIGN oldTable=ht[n] oldBuffer=hb[n]. CREATE TEMP-TABLE newTable.
 DO j=1 TO oldBuffer:NUM-FIELDS: newTable:ADD-LIKE-FIELD(oldBuffer:BUFFER-FIELD(j):NAME,oldBuffer:BUFFER-FIELD(j)). END.
 DO j=1 TO NUM-ENTRIES(extraFields):
  fieldValue=ENTRY(j,extraFields). f=oldBuffer:BUFFER-FIELD(ENTRY(1,fieldValue,":")) NO-ERROR.
  IF NOT VALID-HANDLE(f) THEN newTable:ADD-NEW-FIELD(ENTRY(1,fieldValue,":"),ENTRY(2,fieldValue,":"),IF NUM-ENTRIES(fieldValue,":")=3 THEN INTEGER(ENTRY(3,fieldValue,":")) ELSE 0).
 END.
 newTable:UNDO=TRUE. newTable:TEMP-TABLE-PREPARE("cmp" + STRING(n)). newBuffer=newTable:DEFAULT-BUFFER-HANDLE.
 CREATE QUERY q. q:SET-BUFFERS(oldBuffer). q:QUERY-PREPARE("FOR EACH " + oldBuffer:NAME). q:QUERY-OPEN(). q:GET-FIRST().
 DO WHILE NOT q:QUERY-OFF-END: newBuffer:BUFFER-CREATE(). newBuffer:BUFFER-COPY(oldBuffer). newBuffer:BUFFER-RELEASE(). q:GET-NEXT(). END.
 DELETE OBJECT q. DELETE OBJECT oldTable. ASSIGN ht[n]=newTable hb[n]=newBuffer.
END PROCEDURE.
PROCEDURE Setup:
 DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
 IF VALID-HANDLE(runtimeValue) THEN DELETE PROCEDURE runtimeValue.
 ASSIGN fiscalCalls=0 contextCalls=0 versionSequence=1000 itemSequence=2000 ledgerSequence=3000 expenseSequence=4000 modeValue="" thirdBlocked=FALSE.
 RUN Fixture.
 {ContainersVersionTestTables.i}
 DO i=1 TO 34:
  RUN ExtendTable(i,IF i=1 THEN cFields[1] ELSE IF i=14 THEN cFields[4] ELSE IF i=15 THEN cFields[3] ELSE IF i=30 THEN cFields[2] ELSE IF i>=31 THEN cFields[i - 26] ELSE "").
 END.
 RUN ExtendTable(3,"ind_distr_custo:integer").
 RUN ExtendTable(9,"data:date,item_container_custo_id:integer,historico:character,login:character,despesa_container_id:integer").
 RUN ExtendTable(8,"cta_corren_custo_distr_id:integer,log_utilizado:logical,log_manual:logical,perc_calc:decimal,memoria_calculo:character").
 hb[1]:FIND-FIRST(). hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original". hb[1]:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE=TRUE. hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE. hb[1]:BUFFER-RELEASE().
 hb[29]:FIND-FIRST(). hb[29]:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE=TRUE. hb[29]:BUFFER-RELEASE().
 hb[3]:FIND-FIRST(). hb[3]:BUFFER-FIELD("ind_distr_custo"):BUFFER-VALUE=1. hb[3]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=120. hb[3]:BUFFER-RELEASE().
 hb[8]:FIND-FIRST("WHERE " + hb[8]:NAME + ".despesa_container_id=1"). hb[8]:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=130. hb[8]:BUFFER-RELEASE().
 RUN Seed(7,'~{"despesa_id":99}'). RUN Seed(6,'~{"empresa_despesa_id":99,"empresa_id":1,"despesa_id":99,"log_custo":1,"percentual_custo":0}').
 RUN Seed(30,'~{"tipo_versao_custo_id":1,"descricao":"TT"}').
 DO i=1 TO 25: collectors[i]=hb[i]. END. DO i=1 TO 4: sources[i]=hb[i + 25]. END. DO i=1 TO 5: targets[i]=hb[i + 29]. END.
 policyValue=NEW JsonObject(). policyValue:Add("enable_distribution",TRUE). actorValue=NEW JsonObject(). actorValue:Add("login","TT-composition"). policyValue:Add("actor",actorValue).
 oReq=NEW JsonObject(). oReq:Add("operation","gerar"). oReq:Add("container_id",123). oReq:Add("tipo_versao_id",1). oReq:Add("descricao","TT COMPOSITION"). oReq:Add("expected_latest_version_id",0).
 RUN ContainersVersionRuntime.p PERSISTENT SET runtimeValue(THIS-PROCEDURE,THIS-PROCEDURE,collectors,sources,targets,THIS-PROCEDURE,policyValue,THIS-PROCEDURE).
END PROCEDURE.

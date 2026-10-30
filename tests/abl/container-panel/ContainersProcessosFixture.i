PROCEDURE Fixture:
 DEFINE VARIABLE tableNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldDefinition AS CHARACTER NO-UNDO.
 DEFINE VARIABLE keyFields AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(runtimeProvider) THEN DELETE PROCEDURE runtimeProvider.
 {ContainersVersionTestTables.i}
 DO tableNo=1 TO 8:
  IF VALID-HANDLE(ht[tableNo]) THEN DELETE OBJECT ht[tableNo].
  CREATE TEMP-TABLE ht[tableNo].
  DO fieldNo=1 TO NUM-ENTRIES(cFields[tableNo]):
   fieldDefinition=ENTRY(fieldNo,cFields[tableNo]).
   ht[tableNo]:ADD-NEW-FIELD(ENTRY(1,fieldDefinition,":"),ENTRY(2,fieldDefinition,":")).
  END.
  keyFields=ENTRY(tableNo,"nr-container;tipo_versao_custo_id;versao_id;item_container_custo_id;versao_id,despesa_id;versao_id,documento,serie,estab,nat_operacao,cod_emitente;versao_id,num_id_tit_ap;versao_id,desconto_importacao_id",";").
  ht[tableNo]:UNDO=TRUE. ht[tableNo]:ADD-NEW-INDEX("pk",TRUE,TRUE).
  DO fieldNo=1 TO NUM-ENTRIES(keyFields): ht[tableNo]:ADD-INDEX-FIELD("pk",ENTRY(fieldNo,keyFields)). END.
  ht[tableNo]:TEMP-TABLE-PREPARE("fxVersion" + STRING(tableNo)). hb[tableNo]=ht[tableNo]:DEFAULT-BUFFER-HANDLE.
 END.
 hb[1]:BUFFER-CREATE(). hb[1]:BUFFER-FIELD("nr-container"):BUFFER-VALUE=123.
 hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE. hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original". hb[1]:BUFFER-RELEASE().
 hb[2]:BUFFER-CREATE(). hb[2]:BUFFER-FIELD("tipo_versao_custo_id"):BUFFER-VALUE=1. hb[2]:BUFFER-RELEASE().
 RUN ContainersVersionFixture.p PERSISTENT SET runtimeProvider.
 RUN Parse('~{"actor":~{"login":"version-test","id":"opaque-user"}}',OUTPUT policyValue).
 RUN Parse('~{"resource":"versoes","operation":"gerar","container_id":123,"tipo_versao_id":1,"descricao":"TT VERSION TEST","expected_latest_version_id":0}',OUTPUT requestValue).
DO tableNo=1 TO 8: versionBuffers[tableNo]=hb[tableNo]. END.
END PROCEDURE.

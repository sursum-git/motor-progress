/* Prova por rota exclusiva desta entrega; nunca le payloads nem senhas. */
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE matches AS INTEGER NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
FOR EACH espec.sursum_req_pasoe NO-LOCK
 WHERE INDEX(espec.sursum_req_pasoe.rota_endpoint,"/CiwAuthentication")>0:
 matches=matches + 1.
END.
result=NEW JsonObject().
result:Add("matchingExecutions",matches).
result:Add("payloadsRead",FALSE).
result:Add("businessWrites",FALSE).
result:WriteFile("ciw-auth-no-payload.json",TRUE).
QUIT.

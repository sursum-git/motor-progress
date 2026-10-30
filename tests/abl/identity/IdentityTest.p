BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
OUTPUT TO "identity-tests.log".
DO ON ERROR UNDO, THROW:
  IF PasoeRuntimeIdentity:InstanceName("/dados/pasoe/sursum-api/") <> "sursum-api" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Instancia Linux invalida", 0).
  IF PasoeRuntimeIdentity:InstanceName("C:~\pasoe~\identity-test~\") <> "identity-test" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Instancia Windows invalida", 0).
  IF PasoeRuntimeIdentity:InstanceName(?) <> "" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Instancia desconhecida inventada", 0).
  IF PasoeRuntimeIdentity:AgentName("-b,-ASID 3,-T /dados/temp") <> "agent-3" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Agente real nao identificado", 0).
  IF PasoeRuntimeIdentity:AgentName("-b,-ASID   17,-T /dados/temp") <> "agent-17" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Espacos no ASID", 0).
  IF PasoeRuntimeIdentity:AgentName("-b,-ASID other,-T /dados/temp") <> "" THEN
    UNDO, THROW NEW Progress.Lang.AppError("ASID invalido aceito", 0).
  IF PasoeRuntimeIdentity:AgentName("-b,-ASID 2147483648") <> "" THEN
    UNDO, THROW NEW Progress.Lang.AppError("ASID fora do limite aceito", 0).
  IF PasoeRuntimeIdentity:AgentName("-b,-T /dados/temp") <> "" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Agente sem ASID inventado", 0).
  oContext = NEW PasoeExecutionContext().
  IF oContext:getPasoeInstance() <> "identity-test" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Instancia nao obtida de CATALINA_BASE", 0).
  oContext:setCurrentUser("admin").
  IF oContext:toJson():GetCharacter("currentUser") <> "admin" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Identidade do usuario nao preservada", 0).
  PUT UNFORMATTED "PASS: 10 verificacoes de identidade PASOE" SKIP.
  CATCH e AS Progress.Lang.Error:
    PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
  END CATCH.
  FINALLY:
    IF VALID-OBJECT(oContext) THEN DELETE OBJECT oContext.
  END FINALLY.
END.
OUTPUT CLOSE.
QUIT.

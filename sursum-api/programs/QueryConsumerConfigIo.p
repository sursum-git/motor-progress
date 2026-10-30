/* Atomic filesystem operations. The .lock is shared with query-consumers.cjs. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER actionValue AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER fileValue AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER temporaryValue AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER succeeded AS LOGICAL NO-UNDO.
DEFINE VARIABLE resultValue AS INTEGER NO-UNDO.
DEFINE VARIABLE descriptor AS INTEGER NO-UNDO.
succeeded=FALSE.
CASE actionValue:
 WHEN "readable" THEN DO:
  /* Unlike SEARCH, native access also resolves relative paths in the AVM cwd. */
  IF OPSYS="UNIX" THEN RUN access(fileValue,4,OUTPUT resultValue).
  ELSE RUN _access(fileValue,4,OUTPUT resultValue).
  succeeded=resultValue=0.
 END.
 WHEN "acquire" THEN DO:
  IF OPSYS="UNIX" THEN RUN open(fileValue + ".lock",193,384,OUTPUT descriptor).
  ELSE RUN _open(fileValue + ".lock",1281,384,OUTPUT descriptor).
  IF descriptor<0 THEN RETURN.
  IF OPSYS="UNIX" THEN RUN close(descriptor,OUTPUT resultValue).
  ELSE RUN _close(descriptor,OUTPUT resultValue).
  succeeded=TRUE.
 END.
 WHEN "release" THEN DO:
  OS-DELETE VALUE(fileValue + ".lock"). succeeded=OS-ERROR=0.
 END.
 WHEN "replace" THEN DO:
  IF OPSYS="UNIX" THEN DO:
   RUN chmod(temporaryValue,416,OUTPUT resultValue).
   IF resultValue<>0 THEN RETURN.
   RUN rename(temporaryValue,fileValue,OUTPUT resultValue).
   succeeded=resultValue=0.
  END.
  ELSE DO:
   RUN MoveFileExA(temporaryValue,fileValue,9,OUTPUT resultValue).
   succeeded=resultValue<>0.
  END.
 END.
END CASE.
PROCEDURE access EXTERNAL "libc.so.6" CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE _access EXTERNAL "msvcrt.dll" CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE open EXTERNAL "libc.so.6" CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER flags AS LONG.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE close EXTERNAL "libc.so.6" CDECL:
 DEFINE INPUT PARAMETER descriptor AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE chmod EXTERNAL "libc.so.6" CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE rename EXTERNAL "libc.so.6" CDECL:
 DEFINE INPUT PARAMETER oldName AS CHARACTER.
 DEFINE INPUT PARAMETER newName AS CHARACTER.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE _open EXTERNAL "msvcrt.dll" CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER flags AS LONG.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE _close EXTERNAL "msvcrt.dll" CDECL:
 DEFINE INPUT PARAMETER descriptor AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE MoveFileExA EXTERNAL "kernel32.dll" STDCALL:
 DEFINE INPUT PARAMETER oldName AS CHARACTER.
 DEFINE INPUT PARAMETER newName AS CHARACTER.
 DEFINE INPUT PARAMETER flags AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.

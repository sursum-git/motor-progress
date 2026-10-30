/* OS advisory lock: the kernel releases it if an AVM exits. A stale file does not block the queue. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER actionValue AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pathValue AS CHARACTER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER descriptor AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER succeeded AS LOGICAL NO-UNDO.
DEFINE VARIABLE returnValue AS INTEGER NO-UNDO.
succeeded=FALSE.
IF actionValue='acquire' THEN DO:
 IF OPSYS='UNIX' THEN RUN open(pathValue + '.lock',66,384,OUTPUT descriptor).
 ELSE RUN _open(pathValue + '.lock',33026,384,OUTPUT descriptor).
 IF descriptor<0 THEN RETURN.
 IF OPSYS='UNIX' THEN RUN flock(descriptor,6,OUTPUT returnValue).
 ELSE RUN _locking(descriptor,2,1,OUTPUT returnValue).
 IF returnValue=0 THEN DO: succeeded=TRUE. RETURN. END.
 IF OPSYS='UNIX' THEN RUN close(descriptor,OUTPUT returnValue).
 ELSE RUN _close(descriptor,OUTPUT returnValue).
 descriptor=-1.
END.
IF actionValue='release' AND descriptor>=0 THEN DO:
 IF OPSYS='UNIX' THEN DO: RUN flock(descriptor,8,OUTPUT returnValue). RUN close(descriptor,OUTPUT returnValue). END.
 ELSE DO: RUN _locking(descriptor,0,1,OUTPUT returnValue). RUN _close(descriptor,OUTPUT returnValue). END.
 descriptor=-1. succeeded=TRUE.
END.
PROCEDURE open EXTERNAL 'libc.so.6' CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER flagsValue AS LONG.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE flock EXTERNAL 'libc.so.6' CDECL:
 DEFINE INPUT PARAMETER fd AS LONG.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE close EXTERNAL 'libc.so.6' CDECL:
 DEFINE INPUT PARAMETER fd AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE _open EXTERNAL 'msvcrt.dll' CDECL:
 DEFINE INPUT PARAMETER filename AS CHARACTER.
 DEFINE INPUT PARAMETER flagsValue AS LONG.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE _locking EXTERNAL 'msvcrt.dll' CDECL:
 DEFINE INPUT PARAMETER fd AS LONG.
 DEFINE INPUT PARAMETER modeValue AS LONG.
 DEFINE INPUT PARAMETER byteCount AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.
PROCEDURE _close EXTERNAL 'msvcrt.dll' CDECL:
 DEFINE INPUT PARAMETER fd AS LONG.
 DEFINE RETURN PARAMETER resultValue AS LONG.
END.

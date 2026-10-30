/* CREATE BUFFER accepts an existing buffer handle for DB and temp-table
   sources. Clone only the trusted server-owned definition; never client names. */
PROCEDURE ContainerCreateSiblingBuffer:
 DEFINE INPUT PARAMETER sourceBuffer AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER siblingName AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER siblingBuffer AS HANDLE NO-UNDO.
 IF NOT VALID-HANDLE(sourceBuffer) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: buffer de origem ausente.",1).
 IF sourceBuffer:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: origem deve ser buffer.",1).
 CREATE BUFFER siblingBuffer FOR TABLE sourceBuffer BUFFER-NAME siblingName.
END PROCEDURE.

DEFINE VARIABLE oClass AS Progress.Lang.Class NO-UNDO.
DEFINE VARIABLE oMethod AS Progress.Reflect.Method NO-UNDO.
DEFINE VARIABLE oProperty AS Progress.Reflect.Property NO-UNDO.
DEFINE VARIABLE oMethods AS Progress.Reflect.Method EXTENT NO-UNDO.
DEFINE VARIABLE oProperties AS Progress.Reflect.Property EXTENT NO-UNDO.
DEFINE VARIABLE cClass AS CHARACTER NO-UNDO.
DEFINE VARIABLE iClass AS INTEGER NO-UNDO.
DEFINE VARIABLE iItem AS INTEGER NO-UNDO.

DO iClass = 1 TO 4:
    ASSIGN cClass = ENTRY(iClass, "OpenEdge.Web.WebRequest,OpenEdge.Web.WebResponse,OpenEdge.Web.WebResponseWriter,OpenEdge.Web.WebHandler").
    ASSIGN oClass = Progress.Lang.Class:GetClass(cClass) NO-ERROR.
    MESSAGE "CLASS=" + cClass.
    IF NOT VALID-OBJECT(oClass) THEN DO:
        MESSAGE "CLASS_NOT_FOUND".
        NEXT.
    END.
    ASSIGN oProperties = oClass:GetProperties().
    DO iItem = 1 TO EXTENT(oProperties):
        ASSIGN oProperty = oProperties[iItem].
        MESSAGE "PROPERTY=" + oProperty:Name.
    END.
    ASSIGN oMethods = oClass:GetMethods().
    DO iItem = 1 TO EXTENT(oMethods):
        ASSIGN oMethod = oMethods[iItem].
        MESSAGE "METHOD=" + oMethod:Name.
    END.
END.

QUIT.

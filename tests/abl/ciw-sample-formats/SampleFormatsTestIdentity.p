/* Isolated test provider, never published. Counter models sequence consumption. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE nextId AS INTEGER NO-UNDO INITIAL 14.
PROCEDURE NextCadastroId:
 DEFINE INPUT PARAMETER resourceValue AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF resourceValue<>'formatos_amostra' THEN UNDO, THROW NEW Progress.Lang.AppError('Test provider resource mismatch',1).
 idValue=nextId. nextId=nextId + 1.
END PROCEDURE.
PROCEDURE SetNext:
 DEFINE INPUT PARAMETER idValue AS INTEGER NO-UNDO. nextId=idValue.
END PROCEDURE.

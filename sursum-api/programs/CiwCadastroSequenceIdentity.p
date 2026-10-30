/* Fixed sequence provider shared by simple cadastros; no client sequence names. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
PROCEDURE NextCadastroId:
 DEFINE INPUT PARAMETER resourceValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF resourceValue<>'formatos_amostra' OR NOT CONNECTED('espec') OR NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Invalid identity context',1).
 idValue=DYNAMIC-NEXT-VALUE('seq_formatos_amostra','espec').
 IF idValue=? OR idValue<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Positive identity unavailable',1).
END PROCEDURE.

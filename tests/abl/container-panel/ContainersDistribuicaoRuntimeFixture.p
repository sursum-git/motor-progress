/* Local TT-only sequence double; never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE nextLedger AS INTEGER NO-UNDO.
DEFINE VARIABLE nextExpense AS INTEGER NO-UNDO.
DEFINE VARIABLE failureAfter AS INTEGER NO-UNDO.
DEFINE VARIABLE sequenceCalls AS INTEGER NO-UNDO.
PROCEDURE Reset: ASSIGN nextLedger=100 nextExpense=1000 failureAfter=0 sequenceCalls=0. END PROCEDURE.
PROCEDURE SetFailAfter: DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. failureAfter=n. END PROCEDURE.
PROCEDURE NextDistribuicaoId:
 DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. sequenceCalls=sequenceCalls + 1.
 IF failureAfter>0 AND sequenceCalls>failureAfter THEN UNDO, THROW NEW Progress.Lang.AppError("intentional sequence failure",1).
 nextLedger=nextLedger + 1. id=nextLedger.
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. sequenceCalls=sequenceCalls + 1.
 IF failureAfter>0 AND sequenceCalls>failureAfter THEN UNDO, THROW NEW Progress.Lang.AppError("intentional sequence failure",1).
 nextExpense=nextExpense + 1. id=nextExpense.
END PROCEDURE.
PROCEDURE LogRule: DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO. END PROCEDURE.

/* Validacao exclusiva da TT do chamador/adaptador; a BO usa setters. */
FIND FIRST ttFiltroDevolucoes NO-ERROR.
IF NOT AVAILABLE ttFiltroDevolucoes THEN
    UNDO, THROW NEW Progress.Lang.AppError("Informe exatamente um registro em ttFiltroDevolucoes", 1).
IF CAN-FIND(FIRST bOutroFiltro
    WHERE ROWID(bOutroFiltro) <> ROWID(ttFiltroDevolucoes)) THEN
    UNDO, THROW NEW Progress.Lang.AppError("Informe exatamente um registro em ttFiltroDevolucoes", 1).

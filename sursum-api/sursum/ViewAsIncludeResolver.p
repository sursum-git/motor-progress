DEFINE INPUT PARAMETER pcInclude AS CHARACTER NO-UNDO.

DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.

IF pcInclude = ? OR TRIM(pcInclude) = "" THEN
    RETURN "".

ASSIGN cInclude = LC(TRIM(ENTRY(1, pcInclude, " "))).

CASE cInclude:
    WHEN "adinc/i01ad098.i" THEN RETURN {adinc/i01ad098.i 3}.
    WHEN "adinc/i02ad098.i" THEN RETURN {adinc/i02ad098.i 3}.
    WHEN "adinc/i03ad098.i" THEN RETURN {adinc/i03ad098.i 3}.
    WHEN "adinc/i04ad098.i" THEN RETURN {adinc/i04ad098.i 3}.
    WHEN "adinc/i05ad098.i" THEN RETURN {adinc/i05ad098.i 3}.
    WHEN "adinc/i06ad098.i" THEN RETURN {adinc/i06ad098.i 3}.
    WHEN "adinc/i09ad098.i" THEN RETURN {adinc/i09ad098.i 3}.
    WHEN "adinc/i10ad098.i" THEN RETURN {adinc/i10ad098.i 3}.
    WHEN "adinc/i14ad098.i" THEN RETURN {adinc/i14ad098.i 3}.
    WHEN "adinc/i17ad098.i" THEN RETURN {adinc/i17ad098.i 3}.
    WHEN "adinc/i18ad098.i" THEN RETURN {adinc/i18ad098.i 3}.
    WHEN "adinc/i19ad098.i" THEN RETURN {adinc/i19ad098.i 3}.
    WHEN "adinc/i20ad098.i" THEN RETURN {adinc/i20ad098.i 3}.
    WHEN "adinc/i21ad098.i" THEN RETURN {adinc/i21ad098.i 3}.
    WHEN "adinc/i22ad098.i" THEN RETURN {adinc/i22ad098.i 3}.
    WHEN "adinc/i23ad098.i" THEN RETURN {adinc/i23ad098.i 3}.
    WHEN "adinc/i24ad098.i" THEN RETURN {adinc/i24ad098.i 3}.
    WHEN "adinc/i25ad098.i" THEN RETURN {adinc/i25ad098.i 3}.
    WHEN "adinc/i26ad098.i" THEN RETURN {adinc/i26ad098.i 3}.
    WHEN "adinc/i27ad098.i" THEN RETURN {adinc/i27ad098.i 3}.
    WHEN "adinc/i28ad098.i" THEN RETURN {adinc/i28ad098.i 3}.
    WHEN "adinc/i29ad098.i" THEN RETURN {adinc/i29ad098.i 3}.
    WHEN "adinc/i03ad209.i" THEN RETURN {adinc/i03ad209.i 3}.
    WHEN "cxinc/i01cx373.i" THEN RETURN "Ativo,Inativo".
    WHEN "diinc/i04di072.i" THEN RETURN {diinc/i04di072.i 3}.
    WHEN "ininc/i04in176.i" THEN RETURN {ininc/i04in176.i 3}.
END CASE.

RETURN "".

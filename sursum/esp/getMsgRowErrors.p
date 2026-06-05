{esp/util.i} 
{method/dbotterr.i}
DEFINE INPUT  PARAMETER TABLE FOR rowErrors.
DEFINE OUTPUT PARAMETER cErros AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER   NO-UNDO.

FOR EACH rowErrors:

    ASSIGN cErro = "- " + string(rowerrors.errorNumber)  + '-' + rowErrors.errorDescription .
    IF rowErrors.ErrorHelp <> '' THEN DO:
       ASSIGN cErro =   cErro + chr(13) + "(AJUDA:" + rowErrors.errorHelp + ")".
    END.
    RUN incrvalor(INPUT-OUTPUT cErros,cErro, CHR(13)).



END.

/*ErrorSequence	Integer	Indica a seqÅància do erro
ErrorNumber	Integer	ContÇm o n£mero do erro
ErrorDescription	Character	ContÇm a descriá∆o do erro
ErrorParameters	Character	ContÇm os parÉmetros do erro
ErrorType	Character	Indica o tipo do erro
ErrorHelp	Character	ContÇm o help do erro
ErrorSubType	Character	Indica o sub-tipo do erro
*/

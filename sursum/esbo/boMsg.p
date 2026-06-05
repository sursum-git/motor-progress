USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

{esbo\boMsg.i}
{esp\util.i}
DEFINE TEMP-TABLE ttOutput  LIKE ttMsg.
DEFINE VARIABLE iTransLogCalculo AS INT64       NO-UNDO.

PROCEDURE setTransacaoLogCalculo:
    DEFINE INPUT  PARAMETER iTransacao AS INTEGER     NO-UNDO. 
    ASSIGN iTransLogCalculo = iTransacao.

END PROCEDURE.

PROCEDURE setMsg:
    DEFINE INPUT  PARAMETER pCodigo     AS INTEGER     NO-UNDO.
    DEFINE INPUT  PARAMETER pDescricao  AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTipo       AS CHARACTER   NO-UNDO.

    CREATE ttMsg.
    ASSIGN ttMsg.cod = pCodigo
           ttMsg.descricao = pDescricao
           ttMsg.tipo = pTipo.

END PROCEDURE.




PROCEDURE  getTTMsg:
    DEFINE INPUT  PARAMETER pTipo AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER TABLE FOR ttOutput .
    DEFINE VARIABLE ctipoIni AS CHARACTER   NO-UNDO INIT ''.
    DEFINE VARIABLE ctipoFim AS CHARACTER   NO-UNDO INIT 'zzzzzzzzz'.
    IF pTipo <> '' THEN
       ASSIGN cTipoIni = pTipo
              cTipoFim = pTipo.
    EMPTY TEMP-TABLE ttOutput.
    FOR EACH ttMsg
        WHERE ttMsg.tipo >= cTipoIni
        AND   ttmsg.tipo <= cTipoFim.
        CREATE ttOutput.
        BUFFER-COPY ttMsg TO ttOutput.
    END.
END PROCEDURE.

PROCEDURE getErro:
    DEFINE OUTPUT PARAMETER lErro AS LOGICAL     NO-UNDO.
    FIND FIRST ttMsg
        WHERE ttMsg.tipo = 'erro' NO-ERROR.
    ASSIGN lErro = AVAIL ttmsg.

END PROCEDURE.

PROCEDURE getAviso:
    DEFINE OUTPUT PARAMETER lAviso AS LOGICAL     NO-UNDO.
    FIND FIRST ttMsg
        WHERE ttMsg.tipo = 'aviso' NO-ERROR.
    ASSIGN lAviso = AVAIL ttmsg.

END PROCEDURE.

PROCEDURE getErros:

    DEFINE OUTPUT PARAMETER cErro AS CHARACTER   NO-UNDO.
    FOR EACH ttMsg
        WHERE ttMsg.tipo = 'erro':
        RUN incrValor(INPUT-OUTPUT cErro, string(ttMsg.cod) + '-' + ttmsg.descricao , CHR(13)).
    END.

END PROCEDURE.

PROCEDURE limparTTMsg:
   EMPTY TEMP-TABLE ttMsg.

END PROCEDURE.

PROCEDURE expttMsg:

DEFINE INPUT  PARAMETER cArquivo AS CHARACTER FORMAT 'x(200)'   NO-UNDO.
OUTPUT TO VALUE(cArquivo + '_' + string(time) + '.csv') NO-CONVERT .
PUT "Codigo;Descri‡Æo;Tipo" SKIP. 
FOR EACH ttMsg:
    EXPORT DELIMITER ";" ttMsg.
END.
OUTPUT CLOSE.


END PROCEDURE.


PROCEDURE gravarLogCalculo:
    DEFINE INPUT  PARAMETER pCalculo AS INTEGER     NO-UNDO.
    DEFINE VARIABLE hBo     AS HANDLE      NO-UNDO.
    DEFINE VARIABLE iTipo   AS INTEGER     NO-UNDO.
    RUN esbo/boLogsCalculos.p PERSISTENT SET hBo.
    RUN iniciarBos IN hBo.
    IF iTransLogCalculo > 0 THEN DO:
       RUN setTransacao IN Hbo(iTransLogCalculo).
       RUN setCalculo IN hBo(pCalculo).
       FOR EACH ttMsg:
           RUN getDescrTipo(ttMsg.tipo,OUTPUT iTipo).
           RUN setTipo IN hBO(iTipo).
           RUN setDescricao IN hBO(string(ttMsg.cod) + '-' + ttMsg.descricao).
           RUN criarLog IN hBO.
       END.                    
    END.
    RUN finalizarBos IN hBo.
    IF VALID-HANDLE(hBo) THEN
       DELETE PROCEDURE hBo.

END PROCEDURE.


PROCEDURE getDescrTipo:

    DEFINE INPUT  PARAMETER pTp AS CHARACTER   NO-UNDO.
    DEFINE OUTPUT PARAMETER iTp AS INTEGER     NO-UNDO.

    CASE pTp:
        WHEN 'aviso' THEN 
            ASSIGN itp = 1.
        WHEN 'erro' THEN 
            ASSIGN itp = 2.
        WHEN 'log' THEN 
            ASSIGN itp = 3.

    END CASE.

END PROCEDURE.

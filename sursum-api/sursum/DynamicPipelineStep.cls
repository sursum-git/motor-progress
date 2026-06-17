/*
Representação mínima de um step de pipeline (preparação para versão 2.0).
*/

CLASS DynamicPipelineStep IMPLEMENTS IPipelineStep:

    DEFINE PRIVATE VARIABLE iStepOrder  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE cStepType   AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cPayload    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cRawPayload AS CHARACTER NO-UNDO.

    CONSTRUCTOR PUBLIC DynamicPipelineStep(
        INPUT piStepOrder AS INTEGER,
        INPUT pcStepType  AS CHARACTER,
        INPUT pcPayload   AS CHARACTER,
        INPUT pcRawPayload AS CHARACTER):
        ASSIGN iStepOrder  = piStepOrder
               cStepType   = TRIM(pcStepType)
               cPayload    = pcPayload
               cRawPayload = pcRawPayload.
    END CONSTRUCTOR.

    METHOD PUBLIC INTEGER getOrder():
        RETURN iStepOrder.
    END METHOD.

    METHOD PUBLIC CHARACTER getStepType():
        RETURN cStepType.
    END METHOD.

    METHOD PUBLIC CHARACTER getPayload():
        RETURN cPayload.
    END METHOD.

    METHOD PUBLIC CHARACTER getRawJson():
        RETURN cRawPayload.
    END METHOD.

END CLASS.

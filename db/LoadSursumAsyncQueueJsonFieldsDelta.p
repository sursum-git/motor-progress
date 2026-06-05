/*
Carrega os campos JSON como CHARACTER para validar a fila no sports2000 local.
*/

DEFINE VARIABLE cDf AS CHARACTER NO-UNDO.

ASSIGN cDf = "D:\opencode\motor-progress\db\sursum_async_queue_json_fields_delta.df".

RUN prodict/load_df.p (cDf + ",yes,NEW OBJECTS").

MESSAGE "SURSUM_ASYNC_QUEUE_JSON_FIELDS_DELTA_LOADED=" + cDf.
QUIT.

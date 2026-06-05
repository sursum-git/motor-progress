/*
Carrega delta do campo fisico jobStatus para bases que ja receberam
a primeira versao da fila com o nome reservado status.
*/

DEFINE VARIABLE cDf AS CHARACTER NO-UNDO.

ASSIGN cDf = "D:\opencode\motor-progress\db\sursum_async_queue_jobstatus_delta.df".

RUN prodict/load_df.p (cDf + ",yes,NEW OBJECTS").

MESSAGE "SURSUM_ASYNC_QUEUE_JOBSTATUS_DELTA_LOADED=" + cDf.
QUIT.

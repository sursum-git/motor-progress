/*
Carrega o schema da fila no banco conectado.
Executar conectado ao sports2000/DICTDB antes de usar async real.
*/

DEFINE VARIABLE cDf AS CHARACTER NO-UNDO.

ASSIGN cDf = "D:\opencode\motor-progress\db\sursum_async_queue.df".

RUN prodict/load_df.p (cDf + ",yes,NEW OBJECTS").

MESSAGE "SURSUM_ASYNC_QUEUE_DF_LOADED=" + cDf.
QUIT.

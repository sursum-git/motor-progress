//verifica se o registro existe para a tabela com a condi‡Æo passada
FIND {1} NO-LOCK
     {2} NO-ERROR.
RETURN string(AVAIL {1}).

TRIGGER PROCEDURE FOR DELETE OF pp-container.

IF pp-container.situacao = 3 THEN DO:
   MESSAGE "Container j  Fechado.Situa‡Æo nÆo permite exclusÆo!"
            VIEW-AS ALERT-BOX INFO BUTTONS OK.
   RETURN ERROR.
END.   
FIND FIRST pp-ped-venda OF pp-container NO-LOCK NO-ERROR.
IF AVAIL pp-ped-venda THEN DO:
   MESSAGE "Container Possui Pedidos de Venda.ExclusÆo nÆo permitida!"
            VIEW-AS ALERT-BOX INFO BUTTONS OK.
   RETURN ERROR.
END.

FOR EACH pp-it-container OF pp-container.
     DELETE pp-it-container.
END.



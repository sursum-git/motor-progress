
DEFINE VARIABLE protocolo AS CHARACTER EXTENT   NO-UNDO.
DEFINE VARIABLE cripto    AS CHARACTER EXTENT   NO-UNDO.


EXTENT(protocolo) = 10.
EXTENT(cripto) = 10.
                                                   
ASSIGN protocolo[1] = 'TLSv1.2'  
       protocolo[2] = 'TLSv1.1'
       cripto[1]  = 'AES128-SHA256'
       cripto[2]  = 'DHE-RSA-AES128-SHA256'
       cripto[3]  = 'AES128-GCM-SHA256' 
       cripto[4]  = 'DHE-RSA-AES128-GCM-SHA256'
       cripto[5]  = 'ADH-AES128-SHA256'
       cripto[6]  = 'ADH-AES128-GCM-SHA256'
       cripto[7]  = 'ADH-AES256-SHA256'
       cripto[8]  = 'AES256-SHA256' 
       cripto[9]  = 'DHE-RSA-AES256-SHA256'
       cripto[10] = 'AES128-SHA'
       .

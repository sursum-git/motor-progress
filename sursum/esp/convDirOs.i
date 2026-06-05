/******************************************************************************************
Programa:esp/convDirOs.p

Autor: Tadeu Silva Parreiras
   
Objetivo: Centralizar as convers‰es de diretorios necess†rias para programas que 
rodar∆o no appserver que a partir da vers∆o 12 do progress ficar† no linux.
Data: 11/2024

*****************************************************************************************/

 FUNCTION convDirOs RETURNS CHAR(caminhoCompleto AS CHAR,
                                 dirOri AS CHAR,
                                 dirSubst AS CHAR):

     DEFINE VARIABLE cNovoDir AS CHARACTER   NO-UNDO.

     IF OPSYS = 'UNIX' THEN DO:
        ASSIGN  cNovoDir = caminhoCompleto
                cNovoDir = REPLACE(cNovoDir,dirOri,dirSubst)
                cNovoDir = REPLACE(cNovoDir,"\","/").
        RETURN cNovoDir.
     END.               
     RETURN caminhoCompleto.



 END FUNCTION.

FUNCTION getSeparadorOS RETURNS CHAR ():

    IF OPSYS = 'unix' THEN
       RETURN "/".
    ELSE 
      RETURN "\".
    


END FUNCTION.

DEFINE TEMP-TABLE ttMsg   no-undo
       FIELD cod  AS  INT
       FIELD descricao AS CHAR FORMAT 'x(300)'
       FIELD tipo AS CHAR . // aviso ou erro 

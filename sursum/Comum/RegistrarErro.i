
/*------------------------------------------------------------------------
    File        : RegistrarErro.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : tadeu.parreiras
    Created     : Wed May 28 18:37:38 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
DEFINE {1} TEMP-TABLE ttErros NO-UNDO
    FIELD codErro       AS INT
    FIELD descErro      AS CHAR
    FIELD dtHr          AS DATETIME.
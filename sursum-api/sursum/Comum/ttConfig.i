
/*------------------------------------------------------------------------
    File        : ttChaveValor.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : user
    Created     : Tue Apr 15 10:31:00 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
DEFINE TEMP-TABLE ttConfig{1} NO-UNDO
    FIELD sessao AS CHARACTER
    FIELD chave  AS CHARACTER
    FIELD valor  AS CHARACTER    
    INDEX unico IS UNIQUE sessao chave
    .
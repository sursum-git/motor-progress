
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
define temp-table ttChaveValor{1} no-undo
    field chave     as character
    field valor     as character
    field ordem     as int
    index unico is unique chave
    index ind-ordem ordem.

/*------------------------------------------------------------------------
    File        : IColecaoLog.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : administrator
    Created     : Thu Apr 10 15:02:39 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table ttLog no-undo
    field id            as int
    field tipo          as int
    field descricao     as char
    field dtHr          as datetime
    field dtHrGracacao  as datetime.
    
    
    
    
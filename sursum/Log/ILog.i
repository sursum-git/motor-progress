
/*------------------------------------------------------------------------
    File        : ILog.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : administrator
    Created     : Mon Apr 14 10:58:57 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table ttRelacTipoMidia no-undo
    field tipo  as int
    field midia as int
    index primario is primary is unique tipo midia.

    
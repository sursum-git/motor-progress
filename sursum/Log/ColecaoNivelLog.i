
/*------------------------------------------------------------------------
    File        : ColecaoNivelLog.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : administrator
    Created     : Mon Apr 14 12:13:58 BRT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table ttNivelLog no-undo
    field nome              as char
    field posicaoInicial    as int
    field posicaoFinal      as int
    field mascara           as char
    index primario is primary is unique nome .
    
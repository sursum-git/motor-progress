
DEFINE INPUT  PARAMETER pEstab      AS CHARACTER   NO-UNDO.
DEFINE INPUT  PARAMETER pNota       AS CHARACTER   NO-UNDO FORMAT 'x(12)'.
DEFINE INPUT  PARAMETER pEspecie    AS CHARACTER   NO-UNDO.
DEFINE INPUT  PARAMETER pSerie      AS CHARACTER   NO-UNDO.
DEFINE INPUT  PARAMETER pParcela    AS CHARACTER   NO-UNDO.
DEFINE OUTPUT PARAMETER pValor      AS DECIMAL     NO-UNDO.
DEFINE OUTPUT PARAMETER pEncontrou  AS LOGICAL     NO-UNDO.

/* MESSAGE pEstab   SKIP                   */
/*         pNota    SKIP                   */
/*         pEspecie                        */
/*         pSerie                          */
/*         pParcela                        */
/*                                         */
/*     VIEW-AS ALERT-BOX INFO BUTTONS OK.  */

FIND FIRST ems5bkp.tit_acr
    WHERE tit_acr.cod_estab         = pEstab
    AND   tit_acr.cod_tit_acr       = pNota
    AND   tit_acr.cod_espec_docto   = 'DG'
    AND   tit_acr.cod_ser_docto     = pSerie
    AND   tit_acr.cod_parcela       = pParcela
    NO-LOCK NO-ERROR.

IF AVAIL ems5bkp.Tit_acr THEN DO:
   ASSIGN pValor = tit_acr.val_origin_tit_acr
          pEncontrou = YES.
END.
ELSE DO:
   ASSIGN pEncontrou = NO. 
END.


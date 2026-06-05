DEFINE INPUT  PARAMETER pNF AS ROWID       NO-UNDO.
DEFINE TEMP-TABLE ttDP
    FIELD codEstabel        AS CHAR
    FIELD nota              AS CHAR FORMAT 'x(12)'
    FIELD pedido            AS INT
    FIELD serie             AS CHAR
    FIELD especie           AS CHAR
    FIELD parcela           AS CHAR
    FIELD dtEmissao         AS DATE
    FIELD dtVenc            AS DATE
    FIELD valorDP           AS DECIMAL
    FIELD valorEMS5         AS DECIMAL
    FIELD valorBKP          AS DECIMAL
    FIELD LOG_integrado     AS LOGICAL
    FIELD LOG_ems5          AS LOGICAL
    FIELD LOG_bkp           AS LOGICAL
    FIELD perc_bkp          AS DECIMAL
    FIELD LOG_bkp_integrado AS LOGICAL
    FIELD vl_dif_EMS5       AS DECIMAL
    FIELD vl_dif_BKP        AS DECIMAL. 

DEFINE INPUT-OUTPUT PARAMETER TABLE FOR ttDP.
DEFINE VARIABLE cEstab AS CHARACTER   NO-UNDO.


FIND FIRST nota-fiscal
    WHERE ROWID(nota-fiscal) = pNF NO-LOCK NO-ERROR.
IF AVAIL nota-fiscal THEN DO:
   FIND FIRST ped-venda 
       WHERE ped-venda.cod-estabel = nota-fiscal.cod-estabel
       AND   ped-venda.nr-pedcli   = nota-fiscal.nr-pedcli
       AND   ped-venda.nome-abrev  = nota-fiscal.nome-ab-cli NO-LOCK NO-ERROR.
   
      

   FOR EACH fat-duplic 
       WHERE fat-duplic.nr-fatura  =  nota-fiscal.nr-fatura
       AND   fat-duplic.serie      =  nota-fiscal.serie
       AND   fat-duplic.cod-estabel = nota-fiscal.cod-estabel NO-LOCK:
       CREATE ttDP.
       ASSIGN ttDp.codEstabel   = nota-fiscal.cod-estabel 
              ttDP.nota         = nota-fiscal.nr-fatura
              ttDP.pedido       = int(nota-fiscal.nr-pedcli)
              ttDP.serie        = nota-fiscal.serie
              ttDP.especie      = fat-duplic.cod-esp
              ttDp.parcela      = fat-duplic.parcela
              ttDp.dtEmissao    = fat-duplic.dt-emissao
              ttDP.dtVenc       = fat-duplic.dt-venciment
              ttDP.valorDP      = fat-duplic.vl-parcela
              ttDp.LOG_integrado = fat-duplic.flag-atualiz .
       IF AVAIL ped-venda THEN DO:
          IF ped-venda.cod-priori = 10 THEN
             ASSIGN ttDP.LOG_bkp = NO.
          ELSE
            ASSIGN ttDp.LOG_bkp = YES
                   ttDp.perc_BKP = (20 - ped-venda.cod-priori) * 10.
       END.
       ASSIGN cEstab = IF nota-fiscal.cod-estabel = '5' THEN '501' ELSE '101'.
      
       FIND FIRST tit_acr
           WHERE tit_acr.cod_estab       = cEstab
           AND   tit_acr.cod_ser_docto   = nota-fiscal.serie
           AND   tit_acr.cod_tit_acr     = fat-duplic.nr-fatura
           AND   tit_acr.cod_parcela     = fat-duplic.parcela
           AND   tit_acr.cod_espec_docto = fat-duplic.cod-esp
           NO-LOCK NO-ERROR.
       IF AVAIL tit_acr THEN DO:
          ASSIGN ttDP.valorEMS5 = tit_acr.val_origin_tit_acr
                 ttDp.LOG_EMS5  = YES.
       END.
       ELSE DO:
         ASSIGN ttDP.LOG_ems5 = NO.
       END.
   END.    
END.


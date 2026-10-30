/* Persistencia exclusiva de nova pesquisa. Nunca remove pesquisas existentes. */
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esbo/boConsNotaFiscal.i}
DEFINE INPUT PARAMETER TABLE FOR tt-NF.
DEFINE INPUT PARAMETER login AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pagina AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER filtro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER codWp AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER inserted AS INTEGER NO-UNDO.
DEFINE VARIABLE newCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE rowCount AS INTEGER NO-UNDO.
DEFINE BUFFER bWp FOR espec.wp.
DEFINE BUFFER bNota FOR espec.wp_nota_fiscal.
FUNCTION originalNumber RETURNS INTEGER (c AS CHARACTER) FORWARD.
ASSIGN codWp = "" inserted = 0.
/* Sem este bloqueio o retorno poderia preceder o COMMIT do chamador. */
IF TRANSACTION THEN UNDO, THROW NEW AppError("Writer requer transacao raiz propria",0).
IF login = ? OR TRIM(login) = "" THEN UNDO, THROW NEW AppError("Informe login",0).
DO TRANSACTION ON ERROR UNDO, THROW:
 REPEAT:
  newCode = GUID(GENERATE-UUID).
  IF NOT CAN-FIND(FIRST bWp WHERE bWp.cod_wp = newCode)
   AND NOT CAN-FIND(FIRST bNota WHERE bNota.cod_wp = newCode) THEN LEAVE.
 END.
 CREATE bWp.
 ASSIGN bWp.cod_wp = newCode bWp.login = login bWp.data_hora = NOW
  bWp.pagina = pagina bWp.filtro = filtro bWp.tabela = "wp_nota_fiscal".
 FOR EACH tt-NF:
  IF tt-NF.tipo-nota = ? THEN UNDO, THROW NEW AppError("tipo-nota desconhecido",0).
  CREATE bNota.
  ASSIGN bNota.cod_wp = newCode
   bNota.tipo_nota = tt-NF.tipo-nota
   bNota.nr_nota_fis = tt-NF.nf
   bNota.serie = tt-NF.serie
   bNota.cod_emitente = tt-NF.cod-emitente
   bNota.no_ab_reppri = tt-NF.nome-ab-reppri
   bNota.cod_repres = tt-NF.cod-rep
   bNota.dt_emis_nota = tt-NF.dt-emis-nota
   bNota.vl_nota = tt-NF.vl-nota
   bNota.nr_nota_fis_original = originalNumber(tt-NF.nf-original)
   bNota.nr_pedcli = tt-NF.nr-pedcli
   bNota.vl_bruto = tt-NF.vl-bruto
   bNota.vl_desconto = tt-NF.vl-desconto
   bNota.preposto = tt-NF.preposto
   bNota.cidade = tt-NF.cidade
   bNota.estado = tt-NF.estado
   bNota.cod_estabel = tt-NF.cod-estabel
   bNota.desc_devol = tt-NF.descr-mot-dev.
  VALIDATE bNota.
  rowCount = rowCount + 1.
 END.
 VALIDATE bWp.
 RELEASE bNota.
 RELEASE bWp.
END.
/* A transacao ja foi confirmada; nenhum sucesso antes deste ponto. */
ASSIGN codWp = newCode inserted = rowCount.
FUNCTION originalNumber RETURNS INTEGER (c AS CHARACTER):
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE v AS INTEGER NO-UNDO.
 IF c = "" THEN RETURN 0.
 IF c = ? OR c = "-" OR c = "+" THEN UNDO, THROW NEW AppError("nf-original deve ser inteiro ou vazio",0).
 DO k = 1 TO LENGTH(c):
  IF k = 1 AND (SUBSTRING(c,k,1) = "-" OR SUBSTRING(c,k,1) = "+") THEN NEXT.
  IF INDEX("0123456789",SUBSTRING(c,k,1)) = 0 THEN UNDO, THROW NEW AppError("nf-original deve ser inteiro ou vazio",0).
 END.
 v = INTEGER(c) NO-ERROR.
 IF ERROR-STATUS:ERROR OR v = ? THEN UNDO, THROW NEW AppError("nf-original fora do intervalo INTEGER",0).
 RETURN v.
END FUNCTION.

/* Escopo tipo2 da referencia API: login recebido e metadado do consumidor.
   Consulta estatica NO-LOCK; nao autentica nem grava cadastros. */
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esapi/consulta-notas/ttFiltroDevolucoes.i}
DEFINE INPUT PARAMETER pcLogin AS CHARACTER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR ttFiltroDevolucoes.
DEFINE VARIABLE cNome AS CHARACTER NO-UNDO.
DEFINE BUFFER bUsuario FOR espec.user-web.
DEFINE BUFFER bRepresentante FOR ems2cad.repres.
IF pcLogin = ? OR TRIM(pcLogin) = "" THEN RETURN.
IF NOT CAN-FIND(FIRST bUsuario WHERE bUsuario.Login = TRIM(pcLogin) NO-LOCK) THEN RETURN.
FIND FIRST bUsuario WHERE bUsuario.Login = TRIM(pcLogin) NO-LOCK.
IF bUsuario.tp-usuario = ? OR bUsuario.tp-usuario <> 2 THEN RETURN.
cNome = bUsuario.nome-ab-cli.
IF cNome = ? OR TRIM(cNome) = "" THEN cNome = bUsuario.Login.
IF cNome = ? OR TRIM(cNome) = "" THEN
 UNDO, THROW NEW AppError("Usuario representante sem nome de representante",0).
FIND FIRST bRepresentante WHERE bRepresentante.nome-abrev = TRIM(cNome) NO-LOCK NO-ERROR.
IF NOT AVAILABLE bRepresentante THEN
 UNDO, THROW NEW AppError("Usuario tipo2 sem representante cadastrado",0).
IF bRepresentante.cod-rep = ? THEN
 UNDO, THROW NEW AppError("Representante do usuario tipo2 sem codigo",0).
FIND FIRST ttFiltroDevolucoes NO-ERROR.
IF NOT AVAILABLE ttFiltroDevolucoes THEN
 UNDO, THROW NEW AppError("Informe um registro de filtros para aplicar escopo",0).
ASSIGN ttFiltroDevolucoes.representante-de = bRepresentante.cod-rep
 ttFiltroDevolucoes.representante-ate = bRepresentante.cod-rep.

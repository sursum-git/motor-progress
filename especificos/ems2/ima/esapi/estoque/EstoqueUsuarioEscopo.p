/* Mesmo cadastro usado na consulta WP; nenhuma autenticacao por senha aqui.
   O consumidor deve autenticar o usuario antes de informar o login. */
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esbo/boSaldoPV.i}
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR ttFiltroSaldoPV.
DEFINE VARIABLE nome AS CHARACTER NO-UNDO.
DEFINE BUFFER usuario FOR espec.user-web.
DEFINE BUFFER representanteUsuario FOR ems2cad.repres.
FIND FIRST ttFiltroSaldoPV.
FIND FIRST usuario WHERE usuario.Login = ttFiltroSaldoPV.login NO-LOCK NO-ERROR.
IF NOT AVAILABLE usuario THEN UNDO, THROW NEW AppError("Usuario nao cadastrado",0).
IF usuario.tp-usuario = ? OR usuario.tp-usuario < 0 THEN
 UNDO, THROW NEW AppError("Tipo de usuario invalido",0).
ASSIGN ttFiltroSaldoPV.tipoUsuario = usuario.tp-usuario ttFiltroSaldoPV.representante = 0.
IF usuario.tp-usuario <> 2 THEN RETURN.
nome = usuario.nome-ab-cli.
IF nome = ? OR TRIM(nome) = "" THEN nome = usuario.Login.
FIND FIRST representanteUsuario WHERE representanteUsuario.nome-abrev = TRIM(nome) NO-LOCK NO-ERROR.
IF NOT AVAILABLE representanteUsuario THEN UNDO, THROW NEW AppError("Usuario tipo2 sem representante cadastrado",0).
IF representanteUsuario.cod-rep = ? OR representanteUsuario.cod-rep <= 0 THEN
 UNDO, THROW NEW AppError("Representante sem codigo valido",0).
ttFiltroSaldoPV.representante = representanteUsuario.cod-rep.

/* Segunda tentativa da etapa1; nao consulta saldos nem altera parametros. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER textoOriginal AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER textoCorrigido AS CHARACTER NO-UNDO.
DEFINE VARIABLE palavra AS CHARACTER NO-UNDO.
DEFINE VARIABLE caractere AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE BUFFER regra FOR espec.estoque_termo_busca.
DEFINE TEMP-TABLE ttRegra NO-UNDO
 FIELD origem AS CHARACTER FIELD destino AS CHARACTER
 INDEX chave IS PRIMARY UNIQUE origem.
{esbo/termosPesquisaEstoque.i}
FUNCTION substituir RETURNS CHARACTER (texto AS CHARACTER):
 IF texto = "" OR INDEX(texto,"%") > 0 OR INDEX(texto,"_") > 0 THEN RETURN texto.
 FIND ttRegra WHERE ttRegra.origem = CAPS(texto) NO-ERROR.
 IF AVAILABLE ttRegra THEN RETURN ttRegra.destino.
 RETURN texto.
END FUNCTION.
IF textoOriginal = ? THEN RETURN ERROR "Pesquisa de item desconhecida".
FOR EACH regra NO-LOCK WHERE regra.ativo = YES:
 IF termoBuscaNormalizado(regra.termo_digitado,50) = ?
 OR termoBuscaNormalizado(regra.termo_pesquisa,100) = ? THEN
  RETURN ERROR "Equivalencia de pesquisa invalida".
 CREATE ttRegra.
 ASSIGN ttRegra.origem = CAPS(TRIM(regra.termo_digitado))
  ttRegra.destino = CAPS(TRIM(regra.termo_pesquisa)).
END.
textoCorrigido = "".
DO i = 1 TO LENGTH(textoOriginal):
 caractere = SUBSTRING(textoOriginal,i,1).
 IF INDEX(" ," + CHR(9) + CHR(10) + CHR(13),caractere) > 0 THEN DO:
  ASSIGN textoCorrigido = textoCorrigido + substituir(palavra) + caractere palavra = "".
 END.
 ELSE palavra = palavra + caractere.
END.
textoCorrigido = textoCorrigido + substituir(palavra).

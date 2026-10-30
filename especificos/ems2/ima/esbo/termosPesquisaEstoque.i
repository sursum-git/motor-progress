/* Validacao comum ao editor e ao leitor de equivalencias. */
FUNCTION termoBuscaNumerico RETURNS LOGICAL (texto AS CHARACTER):
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE digitos AS INTEGER NO-UNDO.
 DEFINE VARIABLE ponto AS LOGICAL NO-UNDO.
 DEFINE VARIABLE expoente AS LOGICAL NO-UNDO.
 DO i = 1 TO LENGTH(texto):
  c = SUBSTRING(texto,i,1).
  IF INDEX("0123456789",c) > 0 THEN digitos = digitos + 1.
  ELSE IF (c = "+" OR c = "-") AND (i = 1 OR CAPS(SUBSTRING(texto,i - 1,1)) = "E") THEN NEXT.
  ELSE IF c = "." AND NOT ponto AND NOT expoente THEN ponto = YES.
  ELSE IF CAPS(c) = "E" AND NOT expoente AND digitos > 0 THEN ASSIGN expoente = YES digitos = 0.
  ELSE RETURN FALSE.
 END.
 RETURN digitos > 0.
END FUNCTION.
FUNCTION termoBuscaNormalizado RETURNS CHARACTER (texto AS CHARACTER, limite AS INTEGER):
 DEFINE VARIABLE normal AS CHARACTER NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE letras AS LOGICAL NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF texto = ? THEN RETURN ?.
 normal = CAPS(TRIM(texto)).
 IF normal = "" OR LENGTH(normal) > limite THEN RETURN ?.
 IF termoBuscaNumerico(normal) THEN RETURN ?.
 DO k = 1 TO LENGTH(normal):
  c = SUBSTRING(normal,k,1).
  IF NOT COMPARE(CAPS(c),"EQ",LC(c),"RAW") THEN letras = YES.
  ELSE IF INDEX("0123456789.-'",c) = 0 THEN RETURN ?.
 END.
 IF NOT letras THEN RETURN ?.
 RETURN normal.
END FUNCTION.

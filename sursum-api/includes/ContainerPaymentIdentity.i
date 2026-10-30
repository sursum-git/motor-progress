/* Same stable payment identity for queries, commands and transaction logs. */
FUNCTION ContainerPaymentPart RETURNS CHARACTER (valueText AS CHARACTER):
 IF valueText=? THEN RETURN "N:".
 RETURN "V" + TRIM(STRING(LENGTH(valueText),"->>>>>>>>>9")) + ":" + valueText.
END FUNCTION.
FUNCTION ContainerPaymentKey RETURNS CHARACTER (containerId AS INTEGER,establishment AS CHARACTER,titleId AS INTEGER):
 DEFINE VARIABLE canonicalText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE digestText AS CHARACTER NO-UNDO.
 canonicalText=ContainerPaymentPart(TRIM(STRING(containerId,"->>>>>>>>>9")))
  + ContainerPaymentPart(establishment) + ContainerPaymentPart(TRIM(STRING(titleId,"->>>>>>>>>9"))).
 digestText=CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",canonicalText))).
 RETURN "p_" + digestText.
END FUNCTION.

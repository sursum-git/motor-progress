{sursum-api/includes/PurchaseJsonContract.i}
/* Shared physical image plus resolved owner; no business formulas. */
FUNCTION SampleFields RETURNS CHARACTER():
 RETURN 'envio_amostra_repres_id,item_proc_compra_id,cod_rep,dt_envio,apont_amostra_id'.
END FUNCTION.
FUNCTION SampleId RETURNS INTEGER(o AS JsonObject,n AS CHARACTER): RETURN PurchaseJsonId(o,n). END FUNCTION.
FUNCTION SampleSnapshot RETURNS JsonObject(h AS HANDLE,pid AS INTEGER):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 o=NEW JsonObject().
 DO k=1 TO NUM-ENTRIES(SampleFields()):
  f=h:BUFFER-FIELD(ENTRY(k,SampleFields())).
  IF f:BUFFER-VALUE=? THEN o:AddNull(f:NAME).
  ELSE IF f:DATA-TYPE='DATE' THEN o:Add(f:NAME,ISO-DATE(DATE(f:BUFFER-VALUE))).
  ELSE IF f:DATA-TYPE='INTEGER' THEN o:Add(f:NAME,INTEGER(f:BUFFER-VALUE)).
  ELSE UNDO, THROW NEW Progress.Lang.AppError('Schema de envios inesperado.',1).
 END.
 o:Add('proc_compra_id',pid). RETURN o.
END FUNCTION.
FUNCTION SampleStamp RETURNS CHARACTER(o AS JsonObject): RETURN PurchaseJsonStamp(o). END FUNCTION.
FUNCTION SampleData RETURNS JsonObject(h AS HANDLE,pid AS INTEGER,repName AS CHARACTER):
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=SampleSnapshot(h,pid). o:Add('row_stamp',SampleStamp(o)). o:Add('representante_nome',IF repName=? THEN '' ELSE repName). RETURN o.
END FUNCTION.

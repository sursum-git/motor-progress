/* Shared physical header image and optimistic stamp. No business rules here. */
FUNCTION PurchaseItemFields RETURNS CHARACTER():
 RETURN 'item_proc_compra_id,descricao,codigo_erp,qt_dias_producao,vl_base_tributacao,unid_medida,proc_compra_id,qt_comprada,vl_custo_dolar,composicao,peso,largura,rolo,dt_prev_envio_desenhos,dt_real_envio_desenhos,log_aprov_so_ld,dt_prev_recbto_so_ld,dt_prev_aprov_so_ld,dt_real_aprov_so_ld,coloracao_id,dt_maxima_producao,dt_mostruario,log_mostruario,formato_amostra_id,ind_producao_no_prazo,ind_relat_semanal_producao,ind_qualid_emb,ind_laudo_antes_embarque,ind_prod_conf_pi,ind_rec_amostra_antes_emb,ind_qt_conf_proforma,ind_tamanho_pecas_correto,observacao,dt_cheg_amostras_emb,dt_termino_producao,vl_cubagem,dt_recbto_laudo,dt_recbto_embalagem,dt_real_recbto_so_ld,dt_prev_termino_producao,qt_dias_calc_so_ld,shrinkage,ind_distr_custo,vl_negociado,item_estacao,dt_item_certificacao'.
END FUNCTION.
FUNCTION PurchaseItemSnapshot RETURNS JsonObject(h AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO.
 o=NEW JsonObject().
 DO i=1 TO NUM-ENTRIES(PurchaseItemFields()):
  f=h:BUFFER-FIELD(ENTRY(i,PurchaseItemFields())).
  IF f:BUFFER-VALUE=? THEN o:AddNull(f:NAME).
  ELSE CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN o:Add(f:NAME,STRING(f:BUFFER-VALUE)).
   WHEN 'INTEGER' THEN o:Add(f:NAME,INTEGER(f:BUFFER-VALUE)).
   WHEN 'DECIMAL' THEN o:Add(f:NAME,DECIMAL(f:BUFFER-VALUE)).
   WHEN 'LOGICAL' THEN o:Add(f:NAME,LOGICAL(f:BUFFER-VALUE)).
   WHEN 'DATE' THEN o:Add(f:NAME,ISO-DATE(DATE(f:BUFFER-VALUE))).
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError('Tipo inesperado no cabecalho do pedido.',1).
  END CASE.
 END. RETURN o.
END FUNCTION.
FUNCTION PurchaseItemStamp RETURNS CHARACTER(o AS JsonObject):
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO. DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
 o:Write(textValue,FALSE). hashValue=HEX-ENCODE(MESSAGE-DIGEST('SHA-256',textValue)). RETURN CAPS(hashValue).
END FUNCTION.
/* Presentation-only GM: one shared formula; source CHARACTER fields stay intact.
   Parse civil decimal strings without depending on SESSION:NUMERIC-FORMAT. */
FUNCTION PurchaseItemTextNumber RETURNS DECIMAL(rawValue AS CHARACTER):
 DEFINE VARIABLE resultValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE divisor AS DECIMAL DECIMALS 10 NO-UNDO INITIAL 1.
 DEFINE VARIABLE fractionValue AS LOGICAL NO-UNDO. DEFINE VARIABLE negativeValue AS LOGICAL NO-UNDO.
 DEFINE VARIABLE ch AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE digits AS INTEGER NO-UNDO.
 IF rawValue=? THEN RETURN ?. rawValue=TRIM(rawValue). IF rawValue='' OR LENGTH(rawValue)>30 THEN RETURN ?.
 IF SUBSTRING(rawValue,1,1)='-' THEN DO: negativeValue=TRUE. rawValue=SUBSTRING(rawValue,2). END.
 DO k=1 TO LENGTH(rawValue):
  ch=SUBSTRING(rawValue,k,1).
  IF ch='.' OR ch=',' THEN DO: IF fractionValue THEN RETURN ?. fractionValue=TRUE. NEXT. END.
  IF INDEX('0123456789',ch)=0 THEN RETURN ?.
  digits=digits + 1.
  IF fractionValue THEN DO:
   divisor=divisor * 10. IF divisor>10000000000 THEN RETURN ?.
   resultValue=resultValue + INTEGER(ch) / divisor.
  END.
  ELSE resultValue=resultValue * 10 + INTEGER(ch).
 END.
 IF digits=0 THEN RETURN ?. RETURN IF negativeValue THEN - resultValue ELSE resultValue.
END FUNCTION.
FUNCTION PurchaseItemGm RETURNS DECIMAL(h AS HANDLE):
 DEFINE VARIABLE weightValue AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE widthValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE resultValue AS DECIMAL DECIMALS 10 NO-UNDO.
 weightValue=PurchaseItemTextNumber(STRING(h:BUFFER-FIELD('peso'):BUFFER-VALUE)). widthValue=PurchaseItemTextNumber(STRING(h:BUFFER-FIELD('largura'):BUFFER-VALUE)).
 IF weightValue=? OR widthValue=? THEN RETURN ?.
 ASSIGN resultValue=weightValue * widthValue / 100 NO-ERROR.
 IF ERROR-STATUS:ERROR THEN RETURN ?. RETURN resultValue.
END FUNCTION.
FUNCTION PurchaseItemData RETURNS JsonObject(h AS HANDLE,allocated AS DECIMAL):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE bought AS DECIMAL NO-UNDO.
 o=PurchaseItemSnapshot(h). o:Add('row_stamp',PurchaseItemStamp(o)). o:Add('qt_alocada',allocated). o:Add('calc_gm',PurchaseItemGm(h)).
 bought=h:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE.
 IF bought=? THEN o:AddNull('qt_saldo'). ELSE o:Add('qt_saldo',bought - allocated). RETURN o.
END FUNCTION.

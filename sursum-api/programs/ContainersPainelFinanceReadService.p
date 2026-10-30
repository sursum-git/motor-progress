/* Read-only payment/NF tabs. All ten handles and policy originate in a fixed
   authenticated wrapper. This is NOT the cost collector's payment total rule.
   No client table, database, policy or ABL expression is accepted. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItensContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItensProcCompra AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phProcsCompra AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPagtos AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTitAp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phValTitAp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDocumEst AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/ContainerPaymentIdentity.i}
{sursum-api/includes/ContainerNfLinkContract.i}
DEFINE TEMP-TABLE ttSuppliers NO-UNDO
  FIELD supplierId AS INTEGER INDEX pk IS UNIQUE PRIMARY supplierId.
DEFINE TEMP-TABLE ttSeen NO-UNDO
  FIELD recordKey AS CHARACTER CASE-SENSITIVE INDEX pk IS UNIQUE PRIMARY recordKey.
DEFINE TEMP-TABLE ttOption NO-UNDO FIELD titleId AS INTEGER FIELD sourceRow AS ROWID FIELD globalCount AS INTEGER
  INDEX pk IS UNIQUE PRIMARY titleId.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cId AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cKeyField AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCompany AS CHARACTER NO-UNDO.
DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE iLookup AS INTEGER NO-UNDO.
DEFINE VARIABLE iTitle AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE dtStart AS DATE NO-UNDO.
DEFINE VARIABLE dtCandidate AS DATE NO-UNDO.
DEFINE VARIABLE cDateOrigin AS CHARACTER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMatched AS LOGICAL NO-UNDO.
DEFINE VARIABLE hLinks AS HANDLE NO-UNDO.
DEFINE VARIABLE hDocuments AS HANDLE NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE joSelected AS JsonObject NO-UNDO.
DEFINE VARIABLE iSelectedTitle AS INTEGER NO-UNDO.
DEFINE VARIABLE cOptionError AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOptionMessage AS CHARACTER NO-UNDO.
DEFINE TEMP-TABLE ttNfExcluded NO-UNDO FIELD documentValue AS CHARACTER FIELD documentHash AS CHARACTER CASE-SENSITIVE INDEX pk IS PRIMARY UNIQUE documentHash.
DEFINE VARIABLE iNfStarted AS INTEGER NO-UNDO.
DEFINE VARIABLE iNfReads AS INTEGER NO-UNDO.
DEFINE VARIABLE cNfError AS CHARACTER NO-UNDO.
DEFINE VARIABLE iNfStatus AS INTEGER NO-UNDO.
/* Internal projection comes only from NfRow. The original JSON is the output;
   typed columns exist solely for the shared reader's filter/order/page engine. */
DEFINE TEMP-TABLE ttNfPage NO-UNDO
 FIELD container_id AS INTEGER FIELD nf_key AS CHARACTER CASE-SENSITIVE
 FIELD documento_localizado AS LOGICAL FIELD estab AS CHARACTER FIELD documento AS CHARACTER
 FIELD serie AS CHARACTER FIELD cod_emitente AS INTEGER FIELD nat_operacao AS CHARACTER
 FIELD especie AS INTEGER FIELD dt_emissao AS DATE FIELD dt_trans AS DATE
 FIELD tot_valor AS DECIMAL DECIMALS 10 FIELD despesa_nota AS DECIMAL DECIMALS 10
 FIELD valor_embal AS DECIMAL DECIMALS 10 FIELD valor_frete AS DECIMAL DECIMALS 10
 FIELD valor_mercad AS DECIMAL DECIMALS 10 FIELD valor_outras AS DECIMAL DECIMALS 10
 FIELD valor_seguro AS DECIMAL DECIMALS 10 FIELD nf_original_json AS CLOB
 INDEX pk IS PRIMARY UNIQUE nf_key.
DEFINE VARIABLE joNfPageResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE iNfPageRows AS INTEGER NO-UNDO.

FUNCTION FindFirst RETURNS LOGICAL (phBuffer AS HANDLE,pcCondition AS CHARACTER):
  DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  lValue=phBuffer:FIND-FIRST("WHERE " + pcCondition,NO-LOCK) NO-ERROR.
  DO k=1 TO ERROR-STATUS:NUM-MESSAGES:
    IF ERROR-STATUS:GET-NUMBER(k)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer read failed.",0).
  END.
  RETURN lValue.
END FUNCTION.
FUNCTION ReadId RETURNS INTEGER (pcName AS CHARACTER):
  DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  IF NOT poRequest:Has(pcName) OR poRequest:IsNull(pcName) THEN RETURN ?.
  CASE poRequest:GetType(pcName):
    WHEN JsonDataType:STRING THEN cText=poRequest:GetCharacter(pcName).
    WHEN JsonDataType:NUMBER THEN cText=poRequest:GetJsonText(pcName).
    OTHERWISE RETURN ?.
  END CASE.
  IF LENGTH(cText)=0 OR LENGTH(cText)>10 THEN RETURN ?.
  DO k=1 TO LENGTH(cText): IF INDEX("0123456789",SUBSTRING(cText,k,1))=0 THEN RETURN ?. END.
  dValue=DECIMAL(cText).
  IF dValue<1 OR dValue>2147483647 THEN RETURN ?.
  RETURN INTEGER(dValue).
END FUNCTION.
FUNCTION ValidKey RETURNS LOGICAL (pcKey AS CHARACTER):
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE cStart AS CHARACTER CASE-SENSITIVE NO-UNDO.
  cStart=IF cResource="pagamentos" THEN "p_" ELSE "nf_".
  IF LENGTH(pcKey)<>LENGTH(cStart) + 64 OR SUBSTRING(pcKey,1,LENGTH(cStart))<>cStart THEN RETURN FALSE.
  DO k=LENGTH(cStart) + 1 TO LENGTH(pcKey):
    IF INDEX("0123456789ABCDEF",SUBSTRING(pcKey,k,1))=0 THEN RETURN FALSE.
  END.
  RETURN TRUE.
END FUNCTION.
FUNCTION AllowedName RETURNS LOGICAL (pcName AS CHARACTER):
  DEFINE VARIABLE cName AS CHARACTER CASE-SENSITIVE NO-UNDO.
  cName=pcName.
  RETURN (cResource="nfs-disponiveis" AND cOperation="read"
    AND (cName="skip" OR cName="take" OR cName="filter" OR cName="sort"))
    OR cName="operation" OR cName="resource" OR cName="container_id" OR cName="id"
    OR (cResource<>"pagamentos-disponiveis" AND cOperation="get" AND cName=cKeyField).
END FUNCTION.
FUNCTION KeyPart RETURNS CHARACTER (pcValue AS CHARACTER):
  IF pcValue=? THEN RETURN "N:".
  RETURN "V" + TRIM(STRING(LENGTH(pcValue))) + ":" + pcValue.
END FUNCTION.
FUNCTION AblQuote RETURNS CHARACTER (pcValue AS CHARACTER):
  /* QUOTER alone leaves tilde escapes meaningful in dynamic ABL predicates.
     Escape the ABL escape character before quotes/control characters. */
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  IF pcValue=? THEN RETURN "?".
  cValue=REPLACE(pcValue,CHR(126),CHR(126) + CHR(126)).
  cValue=REPLACE(cValue,CHR(34),CHR(126) + CHR(34)).
  cValue=REPLACE(cValue,CHR(10),CHR(126) + "n").
  cValue=REPLACE(cValue,CHR(13),CHR(126) + "r").
  cValue=REPLACE(cValue,CHR(9),CHR(126) + "t").
  RETURN CHR(34) + cValue + CHR(34).
END FUNCTION.
FUNCTION PaymentKey RETURNS CHARACTER ():
  RETURN ContainerPaymentKey(iContainer,phTitAp:BUFFER-FIELD("cod_estab"):BUFFER-VALUE,
    phTitAp:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE).
END FUNCTION.
FUNCTION NfKey RETURNS CHARACTER (plLocated AS LOGICAL):
  DEFINE VARIABLE cCanonical AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cHash AS CHARACTER NO-UNDO.
  cCanonical=KeyPart(TRIM(STRING(iContainer))).
  IF plLocated THEN cCanonical=cCanonical
    + KeyPart(phDocumEst:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE)
    + KeyPart(phDocumEst:BUFFER-FIELD("serie-docto"):BUFFER-VALUE)
    + KeyPart(phDocumEst:BUFFER-FIELD("nro-docto"):BUFFER-VALUE)
    + KeyPart(phDocumEst:BUFFER-FIELD("nat-operacao"):BUFFER-VALUE)
    + KeyPart(TRIM(STRING(phDocumEst:BUFFER-FIELD("cod-emitente"):BUFFER-VALUE))).
  ELSE cCanonical=cCanonical
    + KeyPart(phNfs:BUFFER-FIELD("estab"):BUFFER-VALUE)
    + KeyPart(phNfs:BUFFER-FIELD("serie"):BUFFER-VALUE)
    + KeyPart(phNfs:BUFFER-FIELD("documento"):BUFFER-VALUE)
    + KeyPart(phNfs:BUFFER-FIELD("nat_operacao"):BUFFER-VALUE)
    + KeyPart(TRIM(STRING(phNfs:BUFFER-FIELD("cod_emitente"):BUFFER-VALUE))).
  cHash=CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cCanonical))).
  RETURN "nf_" + cHash.
END FUNCTION.
FUNCTION InPolicy RETURNS LOGICAL (pcGroup AS CHARACTER,pcSpecies AS CHARACTER):
  DEFINE VARIABLE a AS JsonArray NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
  a=poPolicy:GetJsonArray(pcGroup).
  DO k=1 TO a:Length:
    cValue=a:GetCharacter(k).
    IF cValue=pcSpecies THEN RETURN TRUE.
  END.
  RETURN FALSE.
END FUNCTION.
PROCEDURE CheckPolicy:
  DEFINE VARIABLE a AS JsonArray NO-UNDO.
  DEFINE VARIABLE cGroup AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE m AS INTEGER NO-UNDO.
  DEFINE VARIABLE p AS INTEGER NO-UNDO.
  DEFINE VARIABLE cPolicyNames AS CHARACTER EXTENT NO-UNDO.
  IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Missing internal policy.",0).
  cPolicyNames=poPolicy:GetNames().
  IF EXTENT(cPolicyNames)<>2 OR NOT poPolicy:Has("adiantamentos") OR NOT poPolicy:Has("titulos") THEN
    UNDO, THROW NEW Progress.Lang.AppError("Invalid internal policy.",0).
  DO k=1 TO 2:
    cGroup=ENTRY(k,"adiantamentos,titulos").
    IF poPolicy:GetType(cGroup)<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid internal species.",0).
    a=poPolicy:GetJsonArray(cGroup).
    IF a:Length<1 OR a:Length>100 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid internal species count.",0).
    DO m=1 TO a:Length:
      IF a:GetType(m)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid internal species type.",0).
      cValue=a:GetCharacter(m).
      IF LENGTH(cValue)<1 OR LENGTH(cValue)>3 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid internal species length.",0).
      DO p=1 TO LENGTH(cValue):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(cValue,p,1))=0 THEN
          UNDO, THROW NEW Progress.Lang.AppError("Invalid internal species code.",0).
      END.
    END.
  END.
END PROCEDURE.
PROCEDURE OptionFail:
  DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
  ASSIGN cOptionError=codeValue cOptionMessage=messageValue.
  UNDO, THROW NEW Progress.Lang.AppError(messageValue,1).
END PROCEDURE.
FUNCTION OptionMode RETURNS CHARACTER ():
  DEFINE VARIABLE supplier AS INTEGER NO-UNDO.
  DEFINE VARIABLE issueDate AS DATE NO-UNDO.
  DEFINE VARIABLE company AS CHARACTER NO-UNDO.
  DEFINE VARIABLE species AS CHARACTER NO-UNDO.
  DEFINE VARIABLE kindValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE flagValue AS LOGICAL NO-UNDO.
  supplier=phTitAp:BUFFER-FIELD("cdn_fornecedor"):BUFFER-VALUE.
  issueDate=phTitAp:BUFFER-FIELD("dat_emis_docto"):BUFFER-VALUE.
  company=phTitAp:BUFFER-FIELD("cod_empresa"):BUFFER-VALUE.
  species=phTitAp:BUFFER-FIELD("cod_espec_docto"):BUFFER-VALUE.
  kindValue=phTitAp:BUFFER-FIELD("ind_tip_espec_docto"):BUFFER-VALUE.
  flagValue=phTitAp:BUFFER-FIELD("log_tit_ap_estordo"):BUFFER-VALUE.
  IF flagValue=? OR flagValue THEN RETURN "".
  IF company=? OR company<>cCompany OR issueDate=? OR issueDate<dtStart THEN RETURN "".
  IF supplier=? OR NOT CAN-FIND(ttSuppliers WHERE ttSuppliers.supplierId=supplier) THEN RETURN "".
  IF species=? OR kindValue=? THEN RETURN "".
  IF SUBSTRING(kindValue,1,8)="antecipa" THEN DO:
    IF InPolicy("adiantamentos",species) THEN RETURN "adiantamento".
  END.
  ELSE DO:
    flagValue=phTitAp:BUFFER-FIELD("log_sdo_tit_ap"):BUFFER-VALUE.
    IF flagValue=? OR flagValue THEN RETURN "".
    IF InPolicy("titulos",species) THEN RETURN "apos_di".
  END.
  RETURN "".
END FUNCTION.
FUNCTION OptionText RETURNS CHARACTER (rowValue AS JsonObject,fieldValue AS CHARACTER):
  IF rowValue:IsNull(fieldValue) THEN RETURN "indisponivel".
  IF rowValue:GetType(fieldValue)=JsonDataType:STRING THEN RETURN rowValue:GetCharacter(fieldValue).
  RETURN STRING(rowValue:GetJsonText(fieldValue)).
END FUNCTION.
FUNCTION OptionLinkAllows RETURNS LOGICAL ():
  IF cOperation="get" THEN RETURN NOT FindFirst(phPagtos,phPagtos:NAME + ".num_id_tit_ap=" + TRIM(STRING(iTitle))).
  /* Form read can retain its own current value. Another container's value
     remains unavailable; get is always strict and cannot prove this selectable. */
  RETURN NOT FindFirst(phPagtos,phPagtos:NAME + ".num_id_tit_ap=" + TRIM(STRING(iTitle))
    + " AND " + phPagtos:NAME + ".container_id<>" + TRIM(STRING(iContainer))).
END FUNCTION.
PROCEDURE AvailablePayments:
  DEFINE VARIABLE countOptions AS INTEGER NO-UNDO.
  DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE labelValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE queryText AS CHARACTER NO-UNDO.
  queryText=phTitAp:NAME + ".cod_empresa=" + AblQuote(cCompany).
  IF cOperation="get" THEN queryText=queryText + " AND " + phTitAp:NAME + ".num_id_tit_ap=" + TRIM(STRING(iSelectedTitle)).
  RUN OpenQuery(hDocuments,phTitAp,queryText,"BY " + phTitAp:NAME + ".num_id_tit_ap BY " + phTitAp:NAME + ".cod_estab").
  DO WHILE NOT hDocuments:QUERY-OFF-END:
    iTitle=phTitAp:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
    modeValue=OptionMode().
    IF iTitle<>? AND iTitle>0 AND modeValue<>"" THEN DO:
      IF OptionLinkAllows() THEN DO:
        IF CAN-FIND(ttOption WHERE ttOption.titleId=iTitle) THEN RUN OptionFail("CONTAINER_PAYMENT_AMBIGUOUS","ID do titulo corresponde a mais de um registro EMS5.").
        countOptions=countOptions + 1.
        IF countOptions>5000 THEN RUN OptionFail("CONTAINER_OPTIONS_LIMIT","Mais de 5000 pagamentos disponiveis neste container; listagem excede o limite.").
        CREATE ttOption. ASSIGN ttOption.titleId=iTitle ttOption.sourceRow=phTitAp:ROWID.
      END.
    END.
    hDocuments:GET-NEXT().
  END.
  hDocuments:QUERY-CLOSE().
  /* Legacy links carry only the numeric title ID. Scan ERP once, rather than
     an unindexed full scan per candidate, to reject duplicates in ANY company
     or establishment without retaining unrelated ERP rows in memory. */
  IF CAN-FIND(FIRST ttOption) THEN DO:
    hDocuments:SET-BUFFERS(phTitAp).
    IF NOT hDocuments:QUERY-PREPARE("FOR EACH " + phTitAp:NAME + " FIELDS(num_id_tit_ap) NO-LOCK") THEN
      UNDO, THROW NEW Progress.Lang.AppError("Title uniqueness query preparation failed.",0).
    hDocuments:QUERY-OPEN(). hDocuments:GET-FIRST().
    DO WHILE NOT hDocuments:QUERY-OFF-END:
      iTitle=phTitAp:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
      FIND ttOption WHERE ttOption.titleId=iTitle NO-ERROR.
      IF AVAILABLE ttOption THEN DO:
        ttOption.globalCount=ttOption.globalCount + 1.
        IF ttOption.globalCount>1 THEN RUN OptionFail("CONTAINER_PAYMENT_AMBIGUOUS","ID do titulo corresponde a mais de um registro EMS5.").
      END.
      hDocuments:GET-NEXT().
    END.
    hDocuments:QUERY-CLOSE().
  END.
  FOR EACH ttOption BY ttOption.titleId:
    IF NOT phTitAp:FIND-BY-ROWID(ttOption.sourceRow,NO-LOCK) THEN RUN OptionFail("CONTAINER_PAYMENT_CHANGED","Titulo deixou de existir durante a consulta.").
    iTitle=phTitAp:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
    modeValue=OptionMode().
    IF modeValue="" OR iTitle<>ttOption.titleId OR NOT OptionLinkAllows() THEN NEXT.
    RUN PaymentRow(OUTPUT joRow).
    joRow:Add("value",iTitle). joRow:Add("modalidade",modeValue).
    labelValue=(IF modeValue="adiantamento" THEN "Adiantamento" ELSE "Apos DI/NF")
      + " | " + OptionText(joRow,"cod_estab") + " | " + OptionText(joRow,"cod_espec_docto")
      + "/" + OptionText(joRow,"cod_ser_docto") + "/" + OptionText(joRow,"cod_tit_ap") + "/" + OptionText(joRow,"cod_parcela")
      + " | R$ " + OptionText(joRow,"valor_real") + " | USD " + OptionText(joRow,"valor_dolar").
    IF cOperation="read" AND FindFirst(phPagtos,phPagtos:NAME + ".num_id_tit_ap=" + TRIM(STRING(iTitle))
      + " AND " + phPagtos:NAME + ".container_id=" + TRIM(STRING(iContainer))) THEN labelValue="Já associado | " + labelValue.
    joRow:Add("label",labelValue).
    IF cOperation="read" THEN jaRows:Add(joRow).
    ELSE ASSIGN joSelected=joRow lMatched=TRUE.
  END.
END PROCEDURE.
/* Same NF row/key mapper as linked NFs; only this new read selection differs. */
/* Exact ASCII opaque-key bytes; invoked only by nfs-disponiveis guards.
   Hex text has no blank-padding/case ambiguity from ABL character comparison. */
FUNCTION NfKeyBytes RETURNS CHARACTER (pcValue AS CHARACTER):
 DEFINE VARIABLE bytesValue AS MEMPTR NO-UNDO.
 DEFINE VARIABLE hexValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE positionValue AS INTEGER NO-UNDO.
 IF pcValue=? THEN RETURN "".
 IF NOT ValidKey(pcValue) THEN RETURN "".
 IF LENGTH(pcValue,"RAW")<>67 THEN RETURN "".
 DO positionValue=1 TO 67: IF ASC(SUBSTRING(pcValue,positionValue,1))>127 THEN RETURN "". END.
 DO ON ERROR UNDO, THROW:
  SET-SIZE(bytesValue)=68.
  PUT-STRING(bytesValue,1)=pcValue.
  hexValue=SUBSTRING(HEX-ENCODE(bytesValue),1,134).
  FINALLY: SET-SIZE(bytesValue)=0. END FINALLY.
 END.
 RETURN hexValue.
END FUNCTION.
FUNCTION NfDocumentHash RETURNS CHARACTER (pcValue AS CHARACTER):
 DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
 hashValue=CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",pcValue))).
 RETURN hashValue.
END FUNCTION.
FUNCTION NfDocumentAmbiguous RETURNS LOGICAL (pcValue AS CHARACTER):
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF pcValue=? OR LENGTH(pcValue)=0 THEN RETURN FALSE.
 /* A refusal gate, never a normalization or a substitute SQL collation. */
 IF INDEX(CHR(9) + CHR(10) + CHR(13) + " ",SUBSTRING(pcValue,1,1))>0
  OR INDEX(CHR(9) + CHR(10) + CHR(13) + " ",SUBSTRING(pcValue,LENGTH(pcValue),1))>0 THEN RETURN TRUE.
 DO k=1 TO LENGTH(pcValue): IF ASC(SUBSTRING(pcValue,k,1))>127 THEN RETURN TRUE. END.
 RETURN FALSE.
END FUNCTION.
PROCEDURE NfFail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 ASSIGN cNfError=codeValue iNfStatus=statusValue.
 UNDO, THROW NEW Progress.Lang.AppError("Available NF selection refused.",1).
END PROCEDURE.
PROCEDURE NfReadBound:
 IF ETIME - iNfStarted>=10000 THEN RUN NfFail("CONTAINER_NF_QUERY_TIMEOUT",503).
 IF iNfReads>=50000 THEN RUN NfFail("CONTAINER_NF_SOURCE_LIMIT",503).
 iNfReads=iNfReads + 1.
END PROCEDURE.
PROCEDURE AvailableNfs:
 DEFINE VARIABLE supplierValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE estabValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cNfDocument AS CHARACTER NO-UNDO.
 DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
 DEFINE VARIABLE hasExclusions AS LOGICAL NO-UNDO.
 DEFINE VARIABLE hasAmbiguousExclusions AS LOGICAL NO-UNDO.
 DEFINE VARIABLE excluded AS LOGICAL NO-UNDO.
 DEFINE VARIABLE documentHashValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE finished AS LOGICAL NO-UNDO.
 supplierValue=phContainer:BUFFER-FIELD("cod-emit-forn"):BUFFER-VALUE.
 estabValue=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
 IF supplierValue=? THEN RUN NfFail("CONTAINER_NF_SUPPLIER_REQUIRED",422).
 ASSIGN iNfStarted=ETIME iNfReads=0.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  RUN OpenQuery(hLinks,phNfs,phNfs:NAME + ".container_id=" + TRIM(STRING(iContainer)),"").
  DO WHILE NOT hLinks:QUERY-OFF-END:
   RUN NfReadBound.
   cNfDocument=phNfs:BUFFER-FIELD("documento"):BUFFER-VALUE.
   /* The source interpolates PHP NULL as an empty SQL string, with no TRIM. */
   IF cNfDocument=? THEN cNfDocument="".
   documentHashValue=NfDocumentHash(cNfDocument).
   IF NOT CAN-FIND(ttNfExcluded WHERE ttNfExcluded.documentHash=documentHashValue) THEN DO:
    CREATE ttNfExcluded. ASSIGN ttNfExcluded.documentHash=documentHashValue ttNfExcluded.documentValue=cNfDocument. RELEASE ttNfExcluded.
   END.
   IF NfDocumentAmbiguous(cNfDocument) THEN hasAmbiguousExclusions=TRUE.
   hasExclusions=TRUE. hLinks:GET-NEXT().
  END.
  hLinks:QUERY-CLOSE().
  cWhere=phDocumEst:NAME + ".cod-estabel=" + AblQuote(estabValue)
   + " AND " + phDocumEst:NAME + ".cod-emitente=" + TRIM(STRING(supplierValue))
   + " AND " + phDocumEst:NAME + ".nat-operacao BEGINS ~"3~""
   + " AND " + phDocumEst:NAME + ".idi-sit-nf-eletro=3".
  RUN OpenQuery(hDocuments,phDocumEst,cWhere,"BY " + phDocumEst:NAME + ".nro-docto BY " + phDocumEst:NAME + ".serie-docto BY " + phDocumEst:NAME + ".nat-operacao").
  DO WHILE NOT hDocuments:QUERY-OFF-END AND NOT lMatched:
   RUN NfReadBound.
   cNfDocument=phDocumEst:BUFFER-FIELD("nro-docto"):BUFFER-VALUE.
   excluded=FALSE.
   IF hasExclusions THEN DO:
    /* SQL <> any associated document excludes an unknown candidate value. */
    IF cNfDocument=? THEN excluded=TRUE.
    ELSE DO:
     documentHashValue=NfDocumentHash(cNfDocument).
     IF CAN-FIND(ttNfExcluded WHERE ttNfExcluded.documentHash=documentHashValue) THEN excluded=TRUE.
     ELSE IF hasAmbiguousExclusions OR NfDocumentAmbiguous(cNfDocument)
      OR CAN-FIND(ttNfExcluded WHERE ttNfExcluded.documentValue=cNfDocument) THEN RUN NfFail("CONTAINER_NF_COLLATION_UNPROVEN",422).
    END.
   END.
   IF NOT excluded THEN DO:
    countRows=countRows + 1.
    RUN NfRow(TRUE,OUTPUT joRow). RUN AcceptRow(joRow).
   END.
   hDocuments:GET-NEXT().
  END.
  hDocuments:QUERY-CLOSE().
  /* One outer deadline includes collection AND the common reader. Its own
     deadline cannot extend this request to collection10 + reader10 seconds. */
  IF cOperation="read" THEN RUN NfPage.
  finished=TRUE.
 END.
 IF NOT finished OR ETIME - iNfStarted>=10000 THEN RUN NfFail("CONTAINER_NF_QUERY_TIMEOUT",503).
END PROCEDURE.
PROCEDURE KeepNfPage:
 DEFINE INPUT PARAMETER originalRow AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldsValue AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE dateText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE serialized AS LONGCHAR NO-UNDO.
 CREATE ttNfPage. iNfPageRows=iNfPageRows + 1. fieldsValue=originalRow:GetNames().
 DO k=1 TO EXTENT(fieldsValue):
  f=BUFFER ttNfPage:HANDLE:BUFFER-FIELD(fieldsValue[k]).
  IF originalRow:IsNull(fieldsValue[k]) THEN f:BUFFER-VALUE=?.
  ELSE CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN f:BUFFER-VALUE=originalRow:GetCharacter(fieldsValue[k]).
   WHEN "INTEGER" THEN f:BUFFER-VALUE=originalRow:GetInteger(fieldsValue[k]).
   WHEN "DECIMAL" THEN f:BUFFER-VALUE=originalRow:GetDecimal(fieldsValue[k]).
   WHEN "LOGICAL" THEN f:BUFFER-VALUE=originalRow:GetLogical(fieldsValue[k]).
   WHEN "DATE" THEN DO:
    dateText=originalRow:GetCharacter(fieldsValue[k]).
    f:BUFFER-VALUE=DATE(INTEGER(SUBSTRING(dateText,6,2)),INTEGER(SUBSTRING(dateText,9,2)),INTEGER(SUBSTRING(dateText,1,4))).
   END.
   OTHERWISE RUN NfFail("CONTAINER_NF_PROJECTION_INVALID",503).
  END CASE.
 END.
 originalRow:Write(serialized,FALSE). COPY-LOB FROM serialized TO ttNfPage.nf_original_json.
 RELEASE ttNfPage. DELETE OBJECT originalRow.
END PROCEDURE.
PROCEDURE NfPage:
 DEFINE VARIABLE queryValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
 IF iNfPageRows>iNfReads OR iNfReads>50000 THEN RUN NfFail("CONTAINER_NF_SOURCE_LIMIT",503).
 queryValue=CAST(poRequest:Clone(),JsonObject).
 queryValue:Remove("resource"). queryValue:Remove("container_id").
 readerPath=SEARCH("sursum-api/programs/CiwErpReadService.r").
 IF readerPath=? THEN RUN NfFail("CONTAINER_NF_READER_REQUIRED",503).
 RUN VALUE(readerPath)(INPUT BUFFER ttNfPage:HANDLE,INPUT "container_nfs_disponiveis",INPUT "",INPUT queryValue,OUTPUT joNfPageResponse).
 DELETE OBJECT queryValue.
 IF NOT joNfPageResponse:GetLogical("success") THEN DO:
  IF joNfPageResponse:GetJsonObject("error"):GetCharacter("code")="CIW_ERP_QUERY_TIMEOUT" THEN RUN NfFail("CONTAINER_NF_QUERY_TIMEOUT",503).
  RUN NfFail(joNfPageResponse:GetJsonObject("error"):GetCharacter("code"),joNfPageResponse:GetJsonObject("error"):GetInteger("status")).
 END.
 IF joNfPageResponse:GetInteger("total")>iNfPageRows THEN RUN NfFail("CONTAINER_NF_PROJECTION_INVALID",503).
END PROCEDURE.
PROCEDURE OpenQuery:
  DEFINE INPUT PARAMETER phQuery AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER phBuffer AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER pcWhere AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcOrder AS CHARACTER NO-UNDO.
  phQuery:SET-BUFFERS(phBuffer).
  IF NOT phQuery:QUERY-PREPARE("FOR EACH " + phBuffer:NAME + " NO-LOCK WHERE " + pcWhere + " " + pcOrder) THEN
    UNDO, THROW NEW Progress.Lang.AppError("Query preparation failed.",0).
  phQuery:QUERY-OPEN(). phQuery:GET-FIRST().
END PROCEDURE.
PROCEDURE AddField:
  DEFINE INPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE INPUT PARAMETER phBuffer AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER pcField AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcPublic AS CHARACTER NO-UNDO.
  DEFINE VARIABLE h AS HANDLE NO-UNDO.
  DEFINE VARIABLE c AS CHARACTER NO-UNDO.
  DEFINE VARIABLE v AS INTEGER NO-UNDO.
  DEFINE VARIABLE d AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dt AS DATE NO-UNDO.
  DEFINE VARIABLE l AS LOGICAL NO-UNDO.
  IF NOT phBuffer:AVAILABLE THEN DO: poRow:AddNull(pcPublic). RETURN. END.
  h=phBuffer:BUFFER-FIELD(pcField).
  IF h:BUFFER-VALUE=? THEN DO: poRow:AddNull(pcPublic). RETURN. END.
  CASE h:DATA-TYPE:
    WHEN "CHARACTER" THEN DO: c=h:BUFFER-VALUE. poRow:Add(pcPublic,c). END.
    WHEN "INTEGER" THEN DO: v=h:BUFFER-VALUE. poRow:Add(pcPublic,v). END.
    WHEN "DECIMAL" THEN DO: d=h:BUFFER-VALUE. poRow:Add(pcPublic,d). END.
    WHEN "DATE" THEN DO: dt=h:BUFFER-VALUE. poRow:Add(pcPublic,dt). END.
    WHEN "LOGICAL" THEN DO: l=h:BUFFER-VALUE. poRow:Add(pcPublic,l). END.
    OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Unexpected finance field type.",0).
  END CASE.
END PROCEDURE.
PROCEDURE CompanyContext:
  DEFINE VARIABLE h AS HANDLE NO-UNDO.
  DEFINE VARIABLE countCompany AS INTEGER NO-UNDO.
  DEFINE VARIABLE iEms5 AS INTEGER NO-UNDO.
  cPrefix=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
  IF cPrefix=? OR LENGTH(cPrefix)=0 THEN RETURN.
  cPrefix=SUBSTRING(cPrefix,1,1).
  IF INDEX("0123456789",cPrefix)=0 THEN RETURN.
  DO ON ERROR UNDO, THROW:
    CREATE QUERY h.
    RUN OpenQuery(h,phEmpresas,phEmpresas:NAME + ".cod_emp_ems2 = " + cPrefix,"").
    DO WHILE NOT h:QUERY-OFF-END:
      countCompany=countCompany + 1.
      iEms5=phEmpresas:BUFFER-FIELD("cod_emp_ems5"):BUFFER-VALUE.
      h:GET-NEXT().
    END.
    IF countCompany=1 THEN DO:
      IF cResource="nfs" THEN cCompany="espec-only".
      ELSE IF iEms5<>? THEN cCompany=TRIM(STRING(iEms5)).
    END.
    FINALLY:
      IF VALID-HANDLE(h) THEN DO: h:QUERY-CLOSE() NO-ERROR. DELETE OBJECT h NO-ERROR. END.
    END FINALLY.
  END.
END PROCEDURE.
PROCEDURE SupplierDateContext:
  DEFINE VARIABLE h AS HANDLE NO-UNDO.
  DEFINE VARIABLE iId AS INTEGER NO-UNDO.
  DEFINE VARIABLE supplier AS INTEGER NO-UNDO.
  DEFINE VARIABLE l AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
    CREATE QUERY h.
    RUN OpenQuery(h,phItensContainer,phItensContainer:NAME + ".container_id = " + TRIM(STRING(iContainer)),"").
    DO WHILE NOT h:QUERY-OFF-END:
      iId=phItensContainer:BUFFER-FIELD("item_proc_compra_id"):BUFFER-VALUE.
      IF iId<>? THEN DO:
        l=FindFirst(phItensProcCompra,phItensProcCompra:NAME + ".item_proc_compra_id = " + TRIM(STRING(iId))).
        IF l THEN DO:
          iId=phItensProcCompra:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE.
          IF iId<>? THEN DO:
            l=FindFirst(phProcsCompra,phProcsCompra:NAME + ".proc_compra_id = " + TRIM(STRING(iId))).
            IF l THEN DO:
              supplier=phProcsCompra:BUFFER-FIELD("fornecedor_id"):BUFFER-VALUE.
              IF supplier<>? AND NOT CAN-FIND(ttSuppliers WHERE ttSuppliers.supplierId=supplier) THEN DO:
                CREATE ttSuppliers. ttSuppliers.supplierId=supplier.
              END.
              dtCandidate=phProcsCompra:BUFFER-FIELD("dt_registro"):BUFFER-VALUE.
              IF dtCandidate<>? AND (dtStart=? OR dtCandidate<dtStart) THEN dtStart=dtCandidate.
            END.
          END.
        END.
      END.
      h:GET-NEXT().
    END.
    IF NOT CAN-FIND(FIRST ttSuppliers) THEN DO:
      supplier=phContainer:BUFFER-FIELD("cod-emit-forn"):BUFFER-VALUE.
      IF supplier<>? THEN DO: CREATE ttSuppliers. ttSuppliers.supplierId=supplier. END.
    END.
    cDateOrigin=IF dtStart=? THEN "padrao_2005" ELSE "pedidos".
    IF dtStart=? THEN dtStart=DATE(1,1,2005).
    FINALLY:
      IF VALID-HANDLE(h) THEN DO: h:QUERY-CLOSE() NO-ERROR. DELETE OBJECT h NO-ERROR. END.
    END FINALLY.
  END.
END PROCEDURE.
PROCEDURE CurrencyValue:
  DEFINE INPUT PARAMETER pcPurpose AS CHARACTER NO-UNDO.
  DEFINE OUTPUT PARAMETER pdValue AS DECIMAL NO-UNDO.
  DEFINE OUTPUT PARAMETER pcOrigin AS CHARACTER NO-UNDO.
  DEFINE OUTPUT PARAMETER piRows AS INTEGER NO-UNDO.
  DEFINE VARIABLE h AS HANDLE NO-UNDO.
  DEFINE VARIABLE dOriginal AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dPaid AS DECIMAL NO-UNDO.
  DEFINE VARIABLE cSpecies AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cCondition AS CHARACTER NO-UNDO.
  ASSIGN pdValue=0 pcOrigin="ausente" piRows=0.
  DO ON ERROR UNDO, THROW:
    CREATE QUERY h.
    cCondition=phValTitAp:NAME + ".num_id_tit_ap = " + TRIM(STRING(iTitle))
      + " AND " + phValTitAp:NAME + ".cod_estab = " + AblQuote(phTitAp:BUFFER-FIELD("cod_estab"):BUFFER-VALUE)
      + " AND " + phValTitAp:NAME + ".cod_finalid_econ = " + AblQuote(pcPurpose).
    RUN OpenQuery(h,phValTitAp,cCondition,"BY " + phValTitAp:NAME + ".num_id_movto_tit_ap BY "
      + phValTitAp:NAME + ".cod_unid_negoc BY " + phValTitAp:NAME + ".cod_tip_fluxo_financ").
    DO WHILE NOT h:QUERY-OFF-END:
      piRows=piRows + 1.
      IF piRows=1 THEN ASSIGN dOriginal=phValTitAp:BUFFER-FIELD("val_origin_tit_ap"):BUFFER-VALUE
                              dPaid=phValTitAp:BUFFER-FIELD("val_pagto_tit_ap"):BUFFER-VALUE.
      h:GET-NEXT().
    END.
    IF piRows>0 THEN DO:
      ASSIGN pdValue=0 pcOrigin="fallback" cSpecies=phTitAp:BUFFER-FIELD("cod_espec_docto"):BUFFER-VALUE.
      IF InPolicy("adiantamentos",cSpecies) THEN ASSIGN pdValue=dOriginal pcOrigin="original".
      /* Two independent legacy ifs: titles classification overrides advance. */
      IF InPolicy("titulos",cSpecies) THEN ASSIGN pdValue=dPaid pcOrigin="pago".
      IF pdValue=0 THEN DO:
        ASSIGN pdValue=dPaid pcOrigin="pago_fallback".
        IF pdValue=0 THEN ASSIGN pdValue=dOriginal pcOrigin="original_fallback".
      END.
    END.
    FINALLY:
      IF VALID-HANDLE(h) THEN DO: h:QUERY-CLOSE() NO-ERROR. DELETE OBJECT h NO-ERROR. END.
    END FINALLY.
  END.
END PROCEDURE.
PROCEDURE PaymentRow:
  DEFINE OUTPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
  DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
  DEFINE VARIABLE cOrigin AS CHARACTER NO-UNDO.
  DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
  poRow=NEW JsonObject(). poRow:Add("container_id",iContainer). poRow:Add("pagamento_key",PaymentKey()).
  cFields="num_id_tit_ap,cod_estab,cod_empresa,cod_espec_docto,cod_ser_docto,cdn_fornecedor,cod_tit_ap,cod_parcela,dat_emis_docto,dat_vencto_tit_ap,cod_indic_econ,val_origin_tit_ap".
  DO k=1 TO NUM-ENTRIES(cFields): cField=ENTRY(k,cFields). RUN AddField(poRow,phTitAp,cField,cField). END.
  DO k=1 TO 2:
    RUN CurrencyValue(ENTRY(k,"corrente,dolar"),OUTPUT dValue,OUTPUT cOrigin,OUTPUT countRows).
    cField=ENTRY(k,"valor_real,valor_dolar").
    IF dValue=? THEN poRow:AddNull(cField). ELSE poRow:Add(cField,dValue).
    poRow:Add(cField + "_origem",cOrigin). poRow:Add(cField + "_registros",countRows).
  END.
  poRow:Add("data_inicio_filtro",dtStart). poRow:Add("data_inicio_origem",cDateOrigin).
END PROCEDURE.
PROCEDURE NfRow:
  DEFINE INPUT PARAMETER plLocated AS LOGICAL NO-UNDO.
  DEFINE OUTPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  DEFINE VARIABLE cPhysical AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cPublic AS CHARACTER NO-UNDO.
  poRow=NEW JsonObject(). poRow:Add("container_id",iContainer). poRow:Add("nf_key",NfKey(plLocated)).
  poRow:Add("documento_localizado",plLocated).
  IF plLocated THEN DO:
    RUN AddField(poRow,phDocumEst,"cod-estabel","estab"). RUN AddField(poRow,phDocumEst,"nro-docto","documento"). RUN AddField(poRow,phDocumEst,"serie-docto","serie").
    RUN AddField(poRow,phDocumEst,"cod-emitente","cod_emitente"). RUN AddField(poRow,phDocumEst,"nat-operacao","nat_operacao").
  END.
  ELSE DO:
    RUN AddField(poRow,phNfs,"estab","estab"). RUN AddField(poRow,phNfs,"documento","documento"). RUN AddField(poRow,phNfs,"serie","serie").
    RUN AddField(poRow,phNfs,"cod_emitente","cod_emitente"). RUN AddField(poRow,phNfs,"nat_operacao","nat_operacao").
  END.
  DO k=1 TO 10:
    cPhysical=ENTRY(k,"esp-docto,dt-emissao,dt-trans,tot-valor,despesa-nota,valor-embal,valor-frete,valor-mercad,valor-outras,valor-seguro").
    cPublic=IF k=1 THEN "especie" ELSE REPLACE(cPhysical,"-","_").
    IF plLocated THEN RUN AddField(poRow,phDocumEst,cPhysical,cPublic).
    ELSE poRow:AddNull(cPublic).
  END.
END PROCEDURE.
PROCEDURE AcceptRow:
  DEFINE INPUT PARAMETER poRow AS JsonObject NO-UNDO.
  DEFINE VARIABLE cKey AS CHARACTER CASE-SENSITIVE NO-UNDO.
  cKey=poRow:GetCharacter(cKeyField).
  IF CAN-FIND(ttSeen WHERE ttSeen.recordKey=cKey) THEN DO: DELETE OBJECT poRow. RETURN. END.
  CREATE ttSeen. ttSeen.recordKey=cKey.
  IF cResource="nfs-disponiveis" AND cOperation="read" THEN RUN KeepNfPage(poRow).
  ELSE IF cOperation="read" THEN jaRows:Add(poRow).
  ELSE IF cKey=cId THEN ASSIGN joSelected=poRow lMatched=TRUE.
  ELSE DELETE OBJECT poRow.
END PROCEDURE.

poResponse=NEW JsonObject().
DO ON ERROR UNDO, THROW:
  IF NOT VALID-HANDLE(phContainer) OR NOT VALID-OBJECT(poRequest) THEN DO:
    RUN Fail("CONTAINER_CONFIGURATION","Consulta financeira indisponivel.",500). RETURN.
  END.
  IF NOT poRequest:Has("operation") THEN DO: RUN Fail("CONTAINER_OPERATION_INVALID","Informe read ou get.",422). RETURN. END.
  IF poRequest:GetType("operation")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_OPERATION_INVALID","Operacao invalida.",422). RETURN. END.
  cOperation=poRequest:GetCharacter("operation").
  IF cOperation<>"read" AND cOperation<>"get" THEN DO: RUN Fail("CONTAINER_OPERATION_INVALID","A consulta aceita somente read e get.",422). RETURN. END.
  IF NOT poRequest:Has("resource") THEN DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Informe recurso.",422). RETURN. END.
  IF poRequest:GetType("resource")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Recurso invalido.",422). RETURN. END.
  cResource=poRequest:GetCharacter("resource").
  CASE cResource:
    WHEN "pagamentos" THEN cKeyField="pagamento_key".
    WHEN "pagamentos-disponiveis" THEN cKeyField="value".
    WHEN "nfs" THEN cKeyField="nf_key".
    WHEN "nfs-disponiveis" THEN cKeyField="nf_key".
    OTHERWISE DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Recurso invalido.",422). RETURN. END.
  END CASE.
  cNames=poRequest:GetNames().
  DO i=1 TO EXTENT(cNames):
    IF NOT AllowedName(cNames[i]) THEN DO:
      RUN Fail("CONTAINER_VALIDATION","Campo nao permitido.",422). RETURN.
    END.
  END.
  iContainer=ReadId("container_id").
  IF iContainer=? THEN DO: RUN Fail("CONTAINER_VALIDATION","Informe container_id inteiro positivo valido.",422). RETURN. END.
  IF cOperation="read" AND poRequest:Has("id") THEN DO: RUN Fail("CONTAINER_VALIDATION","id exige get.",422). RETURN. END.
  IF cOperation="get" THEN DO:
    IF cResource="pagamentos-disponiveis" THEN DO:
      iSelectedTitle=ReadId("id").
      IF iSelectedTitle=? THEN DO: RUN Fail("CONTAINER_VALIDATION","Informe ID inteiro positivo do titulo.",422). RETURN. END.
    END.
    ELSE DO:
    IF NOT poRequest:Has("id") THEN DO: RUN Fail("CONTAINER_VALIDATION","Informe chave do registro.",422). RETURN. END.
    IF poRequest:GetType("id")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_VALIDATION","Chave invalida.",422). RETURN. END.
    cId=poRequest:GetCharacter("id").
    IF NOT ValidKey(cId) THEN DO: RUN Fail("CONTAINER_VALIDATION","Chave invalida.",422). RETURN. END.
    IF cResource="nfs-disponiveis" AND cId<>("nf_" + CAPS(SUBSTRING(cId,4))) THEN DO: RUN Fail("CONTAINER_VALIDATION","Chave invalida.",422). RETURN. END.
    IF poRequest:Has(cKeyField) THEN DO:
      IF poRequest:GetType(cKeyField)<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_VALIDATION","Alias da chave invalido.",422). RETURN. END.
      IF cResource="nfs-disponiveis" AND NfKeyBytes(poRequest:GetCharacter(cKeyField))<>NfKeyBytes(cId) THEN DO: RUN Fail("CONTAINER_VALIDATION","Alias da chave conflitante.",422). RETURN. END.
      IF poRequest:GetCharacter(cKeyField)<>cId THEN DO: RUN Fail("CONTAINER_VALIDATION","Alias da chave conflitante.",422). RETURN. END.
    END.
    END.
  END.
  IF NOT FindFirst(phContainer,phContainer:NAME + ".nr-container = " + TRIM(STRING(iContainer))) THEN DO:
    RUN Fail("CONTAINER_NOT_FOUND","Container nao encontrado.",404). RETURN.
  END.
  IF cResource="nfs-disponiveis" THEN DO:
    cPrefix=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
    IF cPrefix=? OR NOT cPrefix BEGINS "5" THEN DO: RUN Fail("CONTAINER_NF_MED_REQUIRED","NFs disponiveis exigem container MED.",422). RETURN. END.
  END.
  ELSE DO:
  IF NOT VALID-HANDLE(phEmpresas) THEN UNDO, THROW NEW Progress.Lang.AppError("Missing company buffer.",0).
  RUN CompanyContext.
  IF cCompany="" THEN DO: RUN Fail("CONTAINER_COMPANY_CONTEXT","Empresa do estabelecimento ausente ou ambigua.",422). RETURN. END.
  END.
  jaRows=NEW JsonArray().
  CREATE QUERY hLinks. CREATE QUERY hDocuments.
  IF cResource="pagamentos" OR cResource="pagamentos-disponiveis" THEN DO:
    IF NOT VALID-HANDLE(phItensContainer) OR NOT VALID-HANDLE(phItensProcCompra) OR NOT VALID-HANDLE(phProcsCompra)
      OR NOT VALID-HANDLE(phPagtos) OR NOT VALID-HANDLE(phTitAp) OR NOT VALID-HANDLE(phValTitAp) THEN
      UNDO, THROW NEW Progress.Lang.AppError("Missing payment buffers.",0).
    RUN CheckPolicy. RUN SupplierDateContext.
    IF cResource="pagamentos-disponiveis" THEN RUN AvailablePayments.
    ELSE DO:
    RUN OpenQuery(hLinks,phPagtos,phPagtos:NAME + ".container_id = " + TRIM(STRING(iContainer)),"BY " + phPagtos:NAME + ".num_id_tit_ap").
    DO WHILE NOT hLinks:QUERY-OFF-END AND NOT lMatched:
      iTitle=phPagtos:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
      IF iTitle<>? THEN DO:
        RUN OpenQuery(hDocuments,phTitAp,phTitAp:NAME + ".num_id_tit_ap = " + TRIM(STRING(iTitle)),"BY " + phTitAp:NAME + ".cod_estab").
        DO WHILE NOT hDocuments:QUERY-OFF-END AND NOT lMatched:
          ASSIGN lFound=FALSE iLookup=phTitAp:BUFFER-FIELD("cdn_fornecedor"):BUFFER-VALUE
            dtCandidate=phTitAp:BUFFER-FIELD("dat_emis_docto"):BUFFER-VALUE.
          IF iLookup<>? THEN lFound=CAN-FIND(ttSuppliers WHERE ttSuppliers.supplierId=iLookup).
          IF phTitAp:BUFFER-FIELD("log_tit_ap_estordo"):BUFFER-VALUE=FALSE
             AND phTitAp:BUFFER-FIELD("cod_empresa"):BUFFER-VALUE=cCompany
             AND dtCandidate<>? AND dtCandidate>=dtStart AND lFound THEN DO:
            RUN PaymentRow(OUTPUT joRow). RUN AcceptRow(joRow).
          END.
          hDocuments:GET-NEXT().
        END.
        hDocuments:QUERY-CLOSE().
      END.
      hLinks:GET-NEXT().
    END.
    END.
  END.
  ELSE DO:
    IF NOT VALID-HANDLE(phNfs) OR NOT VALID-HANDLE(phDocumEst) THEN
      UNDO, THROW NEW Progress.Lang.AppError("Missing NF buffers.",0).
    IF cResource="nfs-disponiveis" THEN RUN AvailableNfs.
    ELSE DO:
    RUN OpenQuery(hLinks,phNfs,phNfs:NAME + ".container_id = " + TRIM(STRING(iContainer)),"BY " + phNfs:NAME + ".documento BY "
      + phNfs:NAME + ".serie BY " + phNfs:NAME + ".estab BY " + phNfs:NAME + ".nat_operacao BY " + phNfs:NAME + ".cod_emitente").
    DO WHILE NOT hLinks:QUERY-OFF-END AND NOT lMatched:
      cWhere=phDocumEst:NAME + ".nro-docto = " + AblQuote(phNfs:BUFFER-FIELD("documento"):BUFFER-VALUE)
        + " AND " + phDocumEst:NAME + ".serie-docto = " + AblQuote(phNfs:BUFFER-FIELD("serie"):BUFFER-VALUE)
        + " AND " + phDocumEst:NAME + ".cod-estabel = " + AblQuote(phNfs:BUFFER-FIELD("estab"):BUFFER-VALUE)
        + " AND SUBSTRING(" + phDocumEst:NAME + ".nat-operacao,1,1) = ~"3~"".
      RUN OpenQuery(hDocuments,phDocumEst,cWhere,"BY " + phDocumEst:NAME + ".cod-emitente BY " + phDocumEst:NAME + ".nat-operacao").
      lFound=FALSE.
      DO WHILE NOT hDocuments:QUERY-OFF-END AND NOT lMatched:
        lFound=TRUE. RUN NfRow(TRUE,OUTPUT joRow). RUN AcceptRow(joRow).
        hDocuments:GET-NEXT().
      END.
      hDocuments:QUERY-CLOSE().
      IF NOT lFound THEN DO: RUN NfRow(FALSE,OUTPUT joRow). RUN AcceptRow(joRow). END.
      hLinks:GET-NEXT().
    END.
    END.
  END.
  IF cOperation="get" THEN DO:
    IF NOT lMatched THEN DO: RUN Fail("CONTAINER_CHILD_NOT_FOUND","Registro nao encontrado neste container.",404). RETURN. END.
    poResponse:Add("success",TRUE). poResponse:Add("data",joSelected).
  END.
  ELSE IF cResource="nfs-disponiveis" THEN DO:
    DELETE OBJECT poResponse. poResponse=joNfPageResponse.
  END.
  ELSE DO:
   poResponse:Add("success",TRUE). poResponse:Add("data",jaRows).
   IF cResource="nfs" THEN poResponse:Add("nf_stamp",ContainerNfLinkStamp(phNfs,iContainer)).
  END.
  CATCH e AS Progress.Lang.Error:
    IF cResource="nfs-disponiveis" AND cNfError<>"" THEN RUN Fail(cNfError,"Consulta de NFs disponiveis recusada; contexto ou limite invalido.",iNfStatus).
    ELSE IF cResource="pagamentos-disponiveis" AND cOptionError<>"" THEN RUN Fail(cOptionError,cOptionMessage,422).
    ELSE RUN Fail("CONTAINER_INTERNAL","Nao foi possivel consultar dados financeiros do container.",500).
  END CATCH.
  FINALLY:
    IF VALID-HANDLE(hLinks) THEN DO: hLinks:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hLinks NO-ERROR. END.
    IF VALID-HANDLE(hDocuments) THEN DO: hDocuments:QUERY-CLOSE() NO-ERROR. DELETE OBJECT hDocuments NO-ERROR. END.
  END FINALLY.
END.
PROCEDURE Fail:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  DEFINE VARIABLE joError AS JsonObject NO-UNDO.
  IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
  poResponse=NEW JsonObject(). joError=NEW JsonObject(). poResponse:Add("success",FALSE).
  joError:Add("code",pcCode). joError:Add("message",pcMessage). joError:Add("status",piStatus). poResponse:Add("error",joError).
END PROCEDURE.

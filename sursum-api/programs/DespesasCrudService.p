/* Buffers exclusivamente do wrapper. Nomes de tabela/campo nunca vem do cliente. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phDespesa AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVinculo AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresa AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRelacao AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phImposto AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompra AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phHistorico AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttValue NO-UNDO
 FIELD fieldName AS CHARACTER FIELD fieldType AS CHARACTER FIELD textValue AS CHARACTER
 FIELD numValue AS DECIMAL FIELD boolValue AS LOGICAL FIELD nullValue AS LOGICAL
 INDEX pk IS PRIMARY UNIQUE fieldName.
DEFINE TEMP-TABLE ttSelected NO-UNDO FIELD itemId AS INTEGER INDEX pk IS PRIMARY UNIQUE itemId.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCollection AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cType AS CHARACTER NO-UNDO.
DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChildWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE hData AS HANDLE NO-UNDO.
DEFINE VARIABLE hRefDesp AS HANDLE NO-UNDO.
DEFINE VARIABLE hRefEmp AS HANDLE NO-UNDO.
DEFINE VARIABLE hOtherVinc AS HANDLE NO-UNDO.
DEFINE VARIABLE hRelRead AS HANDLE NO-UNDO.
DEFINE VARIABLE hImpRead AS HANDLE NO-UNDO.
DEFINE VARIABLE hAnchor AS HANDLE NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE hScan AS HANDLE NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
DEFINE VARIABLE iId AS INTEGER NO-UNDO.
DEFINE VARIABLE iDesp AS INTEGER NO-UNDO.
DEFINE VARIABLE iEmpresa AS INTEGER NO-UNDO.
DEFINE VARIABLE iNextRel AS INTEGER NO-UNDO.
DEFINE VARIABLE iFilter AS INTEGER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE lCollection AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOption AS LOGICAL NO-UNDO.
DEFINE VARIABLE jaInput AS JsonArray NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE joResult AS JsonObject NO-UNDO.
DEFINE VARIABLE joBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE joAudit AS JsonObject NO-UNDO.

FUNCTION FindFailed RETURNS LOGICAL():
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DO k = 1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(k) <> 565 THEN RETURN TRUE.
 END.
 RETURN FALSE.
END FUNCTION.
FUNCTION EqId RETURNS CHARACTER(INPUT h AS HANDLE, INPUT f AS CHARACTER, INPUT v AS INTEGER):
 RETURN h:NAME + "." + f + " = " + TRIM(STRING(v)).
END FUNCTION.
FUNCTION NumberValue RETURNS DECIMAL(INPUT o AS JsonObject, INPUT f AS CHARACTER, INPUT places AS INTEGER, INPUT maxVal AS DECIMAL):
 DEFINE VARIABLE s AS CHARACTER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE dots AS INTEGER NO-UNDO.
 DEFINE VARIABLE fractionalDigits AS INTEGER NO-UNDO.
 DEFINE VARIABLE divisor AS DECIMAL NO-UNDO INITIAL 1.
 DEFINE VARIABLE digit AS INTEGER NO-UNDO.
 IF o:IsNull(f) THEN RUN Fail("DESPESAS_VALIDATION", "Campo numerico nao aceita null: " + f, 422).
 IF o:GetType(f) = JsonDataType:NUMBER THEN s = o:GetJsonText(f).
 ELSE IF o:GetType(f) = JsonDataType:STRING THEN s = TRIM(o:GetCharacter(f)).
 ELSE RUN Fail("DESPESAS_VALIDATION", "Informe numero valido: " + f, 422).
 IF LENGTH(s) = 0 OR LENGTH(s) > 30 THEN RUN Fail("DESPESAS_VALIDATION", "Numero invalido: " + f, 422).
 DO k = 1 TO LENGTH(s):
  IF SUBSTRING(s,k,1) = "." THEN dots = dots + 1.
  ELSE IF INDEX("0123456789",SUBSTRING(s,k,1)) = 0 THEN RUN Fail("DESPESAS_VALIDATION", "Numero invalido: " + f, 422).
  ELSE IF dots > 0 THEN DO:
   fractionalDigits = fractionalDigits + 1.
   IF fractionalDigits > places AND SUBSTRING(s,k,1) <> "0" THEN RUN Fail("DESPESAS_VALIDATION", "Numero fora da precisao: " + f, 422).
  END.
 END.
 IF dots > 1 OR (dots > 0 AND places = 0) OR s = "." THEN RUN Fail("DESPESAS_VALIDATION", "Numero invalido: " + f, 422).
 /* JSON usa ponto invariavel. DECIMAL(texto) depende de NUMERIC-FORMAT e
    em EUROPEAN transformava 12.3456 em123456. O get tipado preserva NUMBER.
    STRING ja validada em ASCII e lida digito a digito, sem mudar SESSION. */
 IF o:GetType(f) = JsonDataType:NUMBER THEN DO:
  d = o:GetDecimal(f) NO-ERROR.
  IF ERROR-STATUS:ERROR OR d = ? THEN RUN Fail("DESPESAS_VALIDATION", "Numero invalido: " + f, 422).
 END.
 ELSE DO:
  ASSIGN d = 0 dots = 0 fractionalDigits = 0.
  DO k = 1 TO LENGTH(s):
   IF SUBSTRING(s,k,1) = "." THEN dots = 1.
   ELSE DO:
    digit = INDEX("0123456789",SUBSTRING(s,k,1)) - 1.
    IF dots = 0 THEN d = d * 10 + digit.
    ELSE DO:
     fractionalDigits = fractionalDigits + 1.
     /* Casas excedentes sao somente zeros, conferidos acima. */
     IF fractionalDigits <= places THEN DO:
      divisor = divisor * 10.
      d = d + digit / divisor.
     END.
    END.
   END.
  END.
 END.
 IF d < 0 OR d > maxVal OR ROUND(d,places) <> d THEN RUN Fail("DESPESAS_VALIDATION", "Numero fora do limite ou precisao: " + f, 422).
 RETURN d.
END FUNCTION.
FUNCTION ReadId RETURNS INTEGER(INPUT o AS JsonObject, INPUT f AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT o:Has(f) THEN RUN Fail("DESPESAS_VALIDATION", "Informe o ID: " + f, 422).
 d = NumberValue(o,f,0,2147483647).
 IF d < 1 THEN RUN Fail("DESPESAS_VALIDATION", "ID deve ser positivo: " + f, 422).
 RETURN INTEGER(d).
END FUNCTION.
FUNCTION Found RETURNS LOGICAL(INPUT h AS HANDLE, INPUT w AS CHARACTER, INPUT writeLock AS LOGICAL):
 DEFINE VARIABLE ok AS LOGICAL NO-UNDO.
 ok = h:FIND-FIRST("WHERE " + w, IF writeLock THEN EXCLUSIVE-LOCK ELSE NO-LOCK, NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail("DESPESAS_BUSY", "Registro em uso. Tente novamente.", 409).
 IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao consultar registro",0).
 RETURN ok.
END FUNCTION.
FUNCTION HasDependency RETURNS LOGICAL(INPUT h AS HANDLE, INPUT f AS CHARACTER, INPUT valueId AS INTEGER):
 RETURN Found(h,EqId(h,f,valueId),FALSE).
END FUNCTION.
FUNCTION MaxId RETURNS INTEGER(INPUT h AS HANDLE, INPUT f AS CHARACTER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE hMax AS HANDLE NO-UNDO.
 DEFINE VARIABLE resultId AS INTEGER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 /* Buffer separado conserva o lock de alocacao do chamador. */
 CREATE BUFFER hMax FOR TABLE h BUFFER-NAME "bDespMaxId".
 CREATE QUERY q. q:SET-BUFFERS(hMax).
 q:QUERY-PREPARE("FOR EACH " + hMax:NAME + " NO-LOCK BY " + hMax:NAME + "." + f + " DESCENDING").
 q:QUERY-OPEN(). q:GET-FIRST().
 IF NOT q:QUERY-OFF-END THEN DO:
  d = hMax:BUFFER-FIELD(f):BUFFER-VALUE.
  IF d = ? OR d < 0 OR d >= 2147483647 THEN DO:
   q:QUERY-CLOSE(). DELETE OBJECT q. DELETE OBJECT hMax.
   RUN Fail("DESPESAS_ID_LIMIT", "Limite de IDs atingido ou ID existente invalido.",409).
  END.
  resultId = INTEGER(d).
 END.
 q:QUERY-CLOSE(). DELETE OBJECT q. DELETE OBJECT hMax.
 RETURN resultId.
END FUNCTION.
FUNCTION CollectionJson RETURNS JsonArray(INPUT forDesp AS INTEGER, INPUT forEmpresa AS INTEGER):
 DEFINE VARIABLE a AS JsonArray NO-UNDO.
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE w AS CHARACTER NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 a = NEW JsonArray().
 ASSIGN h = IF cResource = "despesas" THEN hRelRead ELSE hImpRead
        f = IF cResource = "despesas" THEN "despesa_id_base" ELSE "imposto_id"
        w = EqId(h,"despesa_id",forDesp).
 IF cResource = "empresas_despesa" THEN w = w + " AND " + EqId(h,"empresa_id",forEmpresa).
 CREATE QUERY q. q:SET-BUFFERS(h).
 q:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + w + " NO-LOCK BY " + h:NAME + "." + f).
 q:QUERY-OPEN(). q:GET-FIRST().
 DO WHILE NOT q:QUERY-OFF-END:
  valueId = h:BUFFER-FIELD(f):BUFFER-VALUE.
  IF valueId = ? THEN a:AddNull(). ELSE a:Add(valueId).
  q:GET-NEXT().
 END.
 q:QUERY-CLOSE(). DELETE OBJECT q.
 RETURN a.
END FUNCTION.
FUNCTION RecordJson RETURNS JsonObject():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 DEFINE VARIABLE intVal AS INTEGER NO-UNDO.
 DEFINE VARIABLE b AS LOGICAL NO-UNDO.
 DEFINE VARIABLE s AS CHARACTER NO-UNDO.
 DEFINE VARIABLE recDesp AS INTEGER NO-UNDO.
 DEFINE VARIABLE recEmpresa AS INTEGER NO-UNDO.
 o = NEW JsonObject().
 DO k = 1 TO NUM-ENTRIES(cFields):
  f = ENTRY(k,cFields). h = hData:BUFFER-FIELD(f).
  IF h:BUFFER-VALUE = ? THEN o:AddNull(f).
  ELSE CASE h:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: s = h:BUFFER-VALUE. o:Add(f,s). END.
   WHEN "LOGICAL" THEN DO: b = h:BUFFER-VALUE. o:Add(f,b). END.
   WHEN "INTEGER" THEN DO: intVal = h:BUFFER-VALUE. o:Add(f,intVal). END.
   OTHERWISE DO: d = h:BUFFER-VALUE. o:Add(f,d). END.
  END CASE.
 END.
 recDesp = hData:BUFFER-FIELD("despesa_id"):BUFFER-VALUE.
 IF cResource = "empresas_despesa" THEN DO:
  recEmpresa = hData:BUFFER-FIELD("empresa_id"):BUFFER-VALUE.
  IF recEmpresa <> ? AND Found(hRefEmp,EqId(hRefEmp,"empresa_id",recEmpresa),FALSE) THEN DO:
   s = hRefEmp:BUFFER-FIELD("nome"):BUFFER-VALUE.
   IF s = ? THEN o:AddNull("empresa_nome"). ELSE o:Add("empresa_nome",s).
  END. ELSE o:AddNull("empresa_nome").
  IF recDesp <> ? AND Found(hRefDesp,EqId(hRefDesp,"despesa_id",recDesp),FALSE) THEN DO:
   s = hRefDesp:BUFFER-FIELD("descricao"):BUFFER-VALUE.
   IF s = ? THEN o:AddNull("descricao_despesa"). ELSE o:Add("descricao_despesa",s).
   intVal = hRefDesp:BUFFER-FIELD("log_imposto"):BUFFER-VALUE.
   IF intVal = ? THEN o:AddNull("eh_imposto"). ELSE o:Add("eh_imposto",intVal = 1).
  END. ELSE DO: o:AddNull("descricao_despesa"). o:AddNull("eh_imposto"). END.
 END.
 o:Add(cCollection,CollectionJson(recDesp,recEmpresa)).
 RETURN o.
END FUNCTION.

PROCEDURE ParseValues:
 DEFINE VARIABLE scaleVal AS INTEGER NO-UNDO.
 DEFINE VARIABLE maxVal AS DECIMAL NO-UNDO.
 DEFINE VARIABLE textLimit AS INTEGER NO-UNDO.
 DEFINE VARIABLE itemNumber AS DECIMAL NO-UNDO.
 DO i = 1 TO EXTENT(cNames):
  cName = cNames[i].
  IF LOOKUP(cName,"resource,operation,id") > 0 THEN NEXT.
  IF cName = cCollection THEN DO:
   lCollection = TRUE.
   IF poRequest:IsNull(cName) OR poRequest:GetType(cName) <> JsonDataType:ARRAY THEN RUN Fail("DESPESAS_VALIDATION", "Selecao deve ser uma lista de IDs.",422).
   jaInput = poRequest:GetJsonArray(cName).
   IF jaInput:Length > 100 THEN RUN Fail("DESPESAS_VALIDATION", "Selecione no maximo 100 IDs.",422).
   DO k = 1 TO jaInput:Length:
    IF jaInput:GetType(k) <> JsonDataType:NUMBER THEN RUN Fail("DESPESAS_VALIDATION", "Selecao requer IDs inteiros numericos.",422).
    itemNumber = jaInput:GetDecimal(k).
    IF itemNumber = ? OR itemNumber < 1 OR itemNumber > 2147483647 OR ROUND(itemNumber,0) <> itemNumber THEN RUN Fail("DESPESAS_VALIDATION", "Selecao requer IDs inteiros positivos int32.",422).
    valueId = INTEGER(itemNumber).
    IF CAN-FIND(ttSelected WHERE ttSelected.itemId = valueId) THEN RUN Fail("DESPESAS_VALIDATION", "IDs repetidos na selecao.",422).
    CREATE ttSelected. ttSelected.itemId = valueId.
   END.
   NEXT.
  END.
  IF LOOKUP(cName,cFields) = 0 THEN RUN Fail("DESPESAS_FIELD_INVALID", "Campo nao permitido: " + cName,422).
  /* Alias da chave ja validado contra id no envelope; nunca e gravado. */
  IF cName = cKey THEN NEXT.
  IF cName = "perc_custo" THEN RUN Fail("DESPESAS_FIELD_READONLY", "perc_custo e um campo legado somente leitura.",422).
  CREATE ttValue. ASSIGN ttValue.fieldName = cName ttValue.fieldType = hData:BUFFER-FIELD(cName):DATA-TYPE.
  IF ttValue.fieldType = "CHARACTER" THEN DO:
   ttValue.nullValue = poRequest:IsNull(cName).
   IF NOT ttValue.nullValue THEN DO:
    IF poRequest:GetType(cName) <> JsonDataType:STRING THEN RUN Fail("DESPESAS_VALIDATION", "Campo deve ser texto: " + cName,422).
    ttValue.textValue = poRequest:GetCharacter(cName).
    textLimit = IF cName = "descricao" THEN 100 ELSE 12.
    IF LENGTH(ttValue.textValue) > textLimit THEN RUN Fail("DESPESAS_VALIDATION", "Texto excede limite: " + cName,422).
   END.
  END.
  ELSE IF ttValue.fieldType = "LOGICAL" THEN DO:
   IF poRequest:IsNull(cName) OR poRequest:GetType(cName) <> JsonDataType:BOOLEAN THEN RUN Fail("DESPESAS_VALIDATION", "Campo deve ser boolean: " + cName,422).
   ttValue.boolValue = poRequest:GetLogical(cName).
  END.
  ELSE DO:
   ASSIGN scaleVal = 0 maxVal = 2147483647.
   CASE cName:
    WHEN "log_imposto" THEN maxVal = 1.
    WHEN "log_ativo" THEN maxVal = 1.
    WHEN "log_custo" THEN maxVal = 1.
    WHEN "ind_imposto" THEN maxVal = 5.
    WHEN "ordem" THEN maxVal = 9999.
    WHEN "perc_calculo" THEN ASSIGN scaleVal = 4 maxVal = 999999999999999.9999.
    WHEN "vl_padrao" THEN ASSIGN scaleVal = 2 maxVal = 99999999.99.
    WHEN "percentual" THEN ASSIGN scaleVal = 4 maxVal = 999999.9999.
    WHEN "percentual_custo" THEN ASSIGN scaleVal = 4 maxVal = 9999.9999.
   END CASE.
   /* FORMAT e apresentacao. DECIMALS e a precisao fisica; validar antes
      de BUFFER-VALUE para nunca aceitar arredondamento silencioso. */
   IF ttValue.fieldType = "DECIMAL" THEN
    scaleVal = MINIMUM(scaleVal,hData:BUFFER-FIELD(cName):DECIMALS).
   /* Limpar NumericTextBox envia null; o legado grava zero para numericos
      opcionais vazios. ReadId e colecoes continuam estritos. FK zero e
      recusada por ValidateLink; campos omitidos nao entram em ttValue. */
   IF poRequest:IsNull(cName) THEN ttValue.numValue = 0.
   ELSE IF poRequest:GetType(cName) = JsonDataType:STRING AND TRIM(poRequest:GetCharacter(cName)) = "" THEN ttValue.numValue = 0.
   ELSE ttValue.numValue = NumberValue(poRequest,cName,scaleVal,maxVal).
  END.
 END.
END PROCEDURE.

PROCEDURE ReadRows:
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE w AS CHARACTER NO-UNDO.
 DEFINE VARIABLE valId AS INTEGER NO-UNDO.
 DEFINE VARIABLE s AS CHARACTER NO-UNDO.
 DEFINE VARIABLE flag AS INTEGER NO-UNDO.
 jaRows = NEW JsonArray().
 ASSIGN h = hData f = cKey w = "".
 IF lOption THEN DO:
  h = IF cOperation = "opcoes_empresas" THEN hRefEmp ELSE hRefDesp.
  f = IF cOperation = "opcoes_empresas" THEN "empresa_id" ELSE "despesa_id".
  IF cOperation = "opcoes_impostos" THEN w = " WHERE " + EqId(h,"log_imposto",1).
  IF cOperation = "opcoes_custo" THEN w = " WHERE " + EqId(h,"log_imposto",0).
  IF cOperation <> "opcoes_empresas" AND iFilter > 0 THEN w = w + (IF w = "" THEN " WHERE " ELSE " AND ") + h:NAME + ".despesa_id <> " + TRIM(STRING(iFilter)).
 END.
 ELSE IF cResource = "empresas_despesa" AND iFilter > 0 THEN w = " WHERE " + EqId(h,"despesa_id",iFilter).
 CREATE QUERY q. q:SET-BUFFERS(h).
 q:QUERY-PREPARE("FOR EACH " + h:NAME + w + " NO-LOCK BY " + h:NAME + "." + f).
 q:QUERY-OPEN(). q:GET-FIRST().
 DO WHILE NOT q:QUERY-OFF-END:
  IF lOption THEN DO:
   o = NEW JsonObject(). valId = h:BUFFER-FIELD(f):BUFFER-VALUE.
   IF valId = ? THEN o:AddNull(f). ELSE o:Add(f,valId).
   f = IF cOperation = "opcoes_empresas" THEN "nome" ELSE "descricao".
   s = h:BUFFER-FIELD(f):BUFFER-VALUE.
   IF s = ? THEN o:AddNull(f). ELSE o:Add(f,s).
   IF cOperation <> "opcoes_empresas" THEN DO:
    flag = h:BUFFER-FIELD("log_imposto"):BUFFER-VALUE.
    IF flag = ? THEN o:AddNull("log_imposto"). ELSE o:Add("log_imposto",flag).
   END.
   f = IF cOperation = "opcoes_empresas" THEN "empresa_id" ELSE "despesa_id".
  END.
  ELSE o = RecordJson().
  jaRows:Add(o). q:GET-NEXT().
 END.
 q:QUERY-CLOSE(). DELETE OBJECT q.
 poResponse:Add("success",TRUE). poResponse:Add("data",jaRows).
END PROCEDURE.

PROCEDURE CheckExpenseDelete:
 IF HasDependency(hOtherVinc,"despesa_id",iId) OR HasDependency(hOtherVinc,"despesa_custo_id",iId)
  OR HasDependency(phCompra,"despesa_id",iId) OR HasDependency(phContainer,"despesa_id",iId)
  OR HasDependency(phHistorico,"despesa_id",iId) OR HasDependency(hImpRead,"imposto_id",iId)
  OR HasDependency(hRelRead,"despesa_id_base",iId) THEN RUN Fail("DESPESAS_IN_USE", "Despesa possui vinculos, bases, impostos ou historico associado.",409).
 /* Impostos cujo pai despesa/empresa nao existe nao podem ser apagados por este CRUD. */
 IF HasDependency(hImpRead,"despesa_id",iId) THEN RUN Fail("DESPESAS_IN_USE", "Despesa possui relacoes de impostos associadas.",409).
END PROCEDURE.
PROCEDURE DeleteChildren:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER w AS CHARACTER NO-UNDO.
 DO WHILE Found(h,w,TRUE):
  IF NOT h:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao excluir relacao",0).
 END.
END PROCEDURE.
PROCEDURE SyncChildren:
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE w AS CHARACTER NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE flag AS INTEGER NO-UNDO.
 ASSIGN h = IF cResource = "despesas" THEN phRelacao ELSE phImposto
        f = IF cResource = "despesas" THEN "despesa_id_base" ELSE "imposto_id"
        w = EqId(h,"despesa_id",iDesp).
 IF cResource = "empresas_despesa" THEN w = w + " AND " + EqId(h,"empresa_id",iEmpresa).
 /* Remove somente ausentes; preserva IDs das relacoes mantidas. */
 CREATE QUERY q. q:SET-BUFFERS(h).
 q:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + w + " NO-LOCK").
 q:QUERY-OPEN(). q:GET-FIRST(EXCLUSIVE-LOCK,NO-WAIT).
 DO WHILE NOT q:QUERY-OFF-END:
  IF h:LOCKED OR NOT h:AVAILABLE THEN DO:
   q:QUERY-CLOSE(). DELETE OBJECT q. RUN Fail("DESPESAS_BUSY","Relacao em uso. Tente novamente.",409).
  END.
  valueId = h:BUFFER-FIELD(f):BUFFER-VALUE.
  IF NOT CAN-FIND(ttSelected WHERE ttSelected.itemId = valueId) THEN
   IF NOT h:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao remover relacao",0).
  q:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT).
 END.
 q:QUERY-CLOSE(). DELETE OBJECT q.
 iNextRel = IF cResource = "despesas" THEN MaxId(hRelRead,"relac_desp_calculada_id") ELSE 0.
 FOR EACH ttSelected BY ttSelected.itemId:
  IF ttSelected.itemId = iDesp THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Uma despesa nao pode referenciar a si mesma.",422).
  IF NOT Found(hRefDesp,EqId(hRefDesp,"despesa_id",ttSelected.itemId),TRUE) THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Despesa selecionada inexistente.",422).
  flag = hRefDesp:BUFFER-FIELD("log_imposto"):BUFFER-VALUE.
  IF cResource = "empresas_despesa" AND (flag = ? OR flag <> 1) THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Selecione somente despesas de imposto.",422).
  IF NOT Found(h,w + " AND " + EqId(h,f,ttSelected.itemId),TRUE) THEN DO:
   IF cResource = "despesas" THEN DO:
    IF iNextRel >= 2147483647 THEN RUN Fail("DESPESAS_ID_LIMIT","Limite de IDs de relacao atingido.",409).
    iNextRel = iNextRel + 1.
   END.
   IF NOT h:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao criar relacao",0).
   h:BUFFER-FIELD("despesa_id"):BUFFER-VALUE = iDesp.
   h:BUFFER-FIELD(f):BUFFER-VALUE = ttSelected.itemId.
   IF cResource = "despesas" THEN h:BUFFER-FIELD("relac_desp_calculada_id"):BUFFER-VALUE = iNextRel.
   ELSE h:BUFFER-FIELD("empresa_id"):BUFFER-VALUE = iEmpresa.
   IF NOT h:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Relacao recusada",0).
  END.
 END.
END PROCEDURE.
PROCEDURE ValidateLink:
 DEFINE VARIABLE costId AS INTEGER NO-UNDO.
 DEFINE VARIABLE costPct AS DECIMAL NO-UNDO.
 DEFINE VARIABLE flag AS INTEGER NO-UNDO.
 iDesp = phVinculo:BUFFER-FIELD("despesa_id"):BUFFER-VALUE.
 iEmpresa = phVinculo:BUFFER-FIELD("empresa_id"):BUFFER-VALUE.
 IF iDesp = ? OR iDesp < 1 OR NOT Found(hRefDesp,EqId(hRefDesp,"despesa_id",iDesp),TRUE) THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Despesa inexistente.",422).
 IF iEmpresa = ? OR iEmpresa < 1 OR NOT Found(hRefEmp,EqId(hRefEmp,"empresa_id",iEmpresa),TRUE) THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Empresa inexistente.",422).
 IF Found(hOtherVinc,EqId(hOtherVinc,"despesa_id",iDesp) + " AND " + EqId(hOtherVinc,"empresa_id",iEmpresa) + " AND " + hOtherVinc:NAME + ".empresa_despesa_id <> " + TRIM(STRING(iId)),FALSE) THEN RUN Fail("DESPESAS_DUPLICATE","Ja existe um vinculo para esta empresa e despesa.",409).
 costId = phVinculo:BUFFER-FIELD("despesa_custo_id"):BUFFER-VALUE.
 costPct = phVinculo:BUFFER-FIELD("percentual_custo"):BUFFER-VALUE.
 IF costId = ? THEN costId = 0.
 IF costPct = ? THEN costPct = 0.
 IF (costId = 0 AND costPct <> 0) OR (costId <> 0 AND costPct = 0) THEN RUN Fail("DESPESAS_COST_PAIR_REQUIRED","Preencha Despesa Custo e % Custo em conjunto.",422).
 IF costId > 0 THEN DO:
  IF NOT Found(hRefDesp,EqId(hRefDesp,"despesa_id",costId),TRUE) THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Despesa de custo inexistente.",422).
  flag = hRefDesp:BUFFER-FIELD("log_imposto"):BUFFER-VALUE.
  IF flag = ? OR flag <> 0 THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Despesa de custo deve ser uma despesa sem imposto.",422).
 END.
END PROCEDURE.

DO ON ERROR UNDO, THROW:
 poResponse = NEW JsonObject().
 IF NOT VALID-OBJECT(poRequest) OR NOT VALID-HANDLE(phDespesa) OR NOT VALID-HANDLE(phVinculo)
  OR NOT VALID-HANDLE(phEmpresa) OR NOT VALID-HANDLE(phRelacao) OR NOT VALID-HANDLE(phImposto)
  OR NOT VALID-HANDLE(phCompra) OR NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phHistorico) THEN RUN Fail("DESPESAS_CONFIGURATION","API indisponivel.",500).
 IF NOT poRequest:Has("resource") OR poRequest:GetType("resource") <> JsonDataType:STRING THEN RUN Fail("DESPESAS_RESOURCE_INVALID","Informe o recurso.",422).
 cResource = poRequest:GetCharacter("resource").
 IF cResource <> "despesas" AND cResource <> "empresas_despesa" THEN RUN Fail("DESPESAS_RESOURCE_INVALID","Recurso invalido.",422).
 IF NOT poRequest:Has("operation") OR poRequest:GetType("operation") <> JsonDataType:STRING THEN RUN Fail("DESPESAS_OPERATION_INVALID","Informe a operacao.",422).
 cOperation = poRequest:GetCharacter("operation").
 IF LOOKUP(cOperation,"read,get,create,update,delete,opcoes_despesas,opcoes_impostos,opcoes_empresas,opcoes_custo") = 0 THEN RUN Fail("DESPESAS_OPERATION_INVALID","Operacao invalida.",422).
 ASSIGN hData = IF cResource = "despesas" THEN phDespesa ELSE phVinculo
  cKey = IF cResource = "despesas" THEN "despesa_id" ELSE "empresa_despesa_id"
  cCollection = IF cResource = "despesas" THEN "md_relacs_desp" ELSE "impostos"
  cFields = IF cResource = "despesas" THEN "despesa_id,descricao,log_imposto,ordem,log_calculada,perc_calculo,log_vl_prod_base_calculo,log_calc_por_item,ind_imposto"
   ELSE "empresa_despesa_id,despesa_id,empresa_id,codigo_desp_erp,vl_padrao,percentual,cod_nat_operacao,log_ativo,perc_custo,percentual_custo,despesa_custo_id,log_custo"
  lOption = INDEX(cOperation,"opcoes_") = 1.
 /* CREATE BUFFER aceita o buffer-handle de DB ou TT. TABLE-HANDLE so
    existe para TT e retorna? para DB; nao extrair nomes do cliente. */
 CREATE BUFFER hRefDesp FOR TABLE phDespesa BUFFER-NAME "bDespRef".
 CREATE BUFFER hRefEmp FOR TABLE phEmpresa BUFFER-NAME "bEmpresaRef".
 CREATE BUFFER hOtherVinc FOR TABLE phVinculo BUFFER-NAME "bOutroVinc".
 CREATE BUFFER hRelRead FOR TABLE phRelacao BUFFER-NAME "bRelRead".
 CREATE BUFFER hImpRead FOR TABLE phImposto BUFFER-NAME "bImpRead".
 CREATE BUFFER hAnchor FOR TABLE phDespesa BUFFER-NAME "bDespAnchor".
 cNames = poRequest:GetNames().
 IF cOperation = "read" OR lOption THEN DO:
  DO i = 1 TO EXTENT(cNames):
   IF LOOKUP(cNames[i],"resource,operation,id,despesa_id") = 0 THEN RUN Fail("DESPESAS_FIELD_INVALID","Campo nao permitido na consulta.",422).
  END.
  IF poRequest:Has("id") THEN iFilter = ReadId(poRequest,"id").
  IF poRequest:Has("despesa_id") THEN iFilter = ReadId(poRequest,"despesa_id").
  RUN ReadRows. RETURN.
 END.
 IF cOperation <> "create" THEN DO:
  iId = ReadId(poRequest,"id").
  /* O cliente PHP envia id e a chave primaria do recurso. Aceitar somente
     alias identico, sem alterar request nem permitir trocar o registro alvo. */
  IF poRequest:Has(cKey) THEN
   IF ReadId(poRequest,cKey) <> iId THEN RUN Fail("DESPESAS_ID_IMMUTABLE","Alias da chave primaria deve corresponder ao id.",422).
 END.
 ELSE IF poRequest:Has("id") OR poRequest:Has(cKey) THEN RUN Fail("DESPESAS_ID_IMMUTABLE","ID e gerado pelo servidor.",422).
 IF cOperation = "get" OR cOperation = "delete" THEN DO:
  DO i = 1 TO EXTENT(cNames):
   IF LOOKUP(cNames[i],"resource,operation,id") = 0 AND cNames[i] <> cKey THEN RUN Fail("DESPESAS_FIELD_INVALID","Campo nao permitido para esta operacao.",422).
  END.
 END. ELSE RUN ParseValues.
 IF cOperation = "get" THEN DO:
  IF NOT Found(hData,EqId(hData,cKey,iId),FALSE) THEN RUN Fail("DESPESAS_NOT_FOUND","Registro nao encontrado.",404).
  poResponse:Add("success",TRUE). poResponse:Add("data",RecordJson()). RETURN.
 END.
 DO TRANSACTION ON ERROR UNDO, THROW:
  joBefore = NEW JsonObject().
  /* relac_desp_calculada_id nao e unico no schema. Uma ancora de despesas
     serializa alocacao de IDs de relacoes entre pais distintos, sem schema novo.
     ID continua calculado explicitamente pelo campo, nunca FIND-LAST primario. */
  IF cResource = "despesas" AND lCollection THEN DO:
   lFound = hAnchor:FIND-FIRST("",EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
   IF hAnchor:LOCKED THEN RUN Fail("DESPESAS_BUSY","Outra gravacao de bases em andamento. Tente novamente.",409).
   IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao serializar relacoes",0).
  END.
  IF cOperation = "create" THEN DO:
   /* Chave primaria unica serializa a alocacao; indice unico cobre tabela vazia. */
   lFound = hData:FIND-LAST("",EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
   IF hData:LOCKED THEN RUN Fail("DESPESAS_BUSY","Outra inclusao em andamento. Tente novamente.",409).
   IF FindFailed() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na alocacao de ID",0).
   iId = MaxId(hData,cKey) + 1.
   IF NOT hData:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Inclusao recusada",0).
   hData:BUFFER-FIELD(cKey):BUFFER-VALUE = iId.
  END.
  ELSE IF NOT Found(hData,EqId(hData,cKey,iId),TRUE) THEN RUN Fail("DESPESAS_NOT_FOUND","Registro nao encontrado.",404).
  /* Snapshot do banco sob o mesmo bloqueio da escrita. Nunca vem do request. */
  IF cOperation <> "create" THEN DO:
   DELETE OBJECT joBefore.
   joBefore = RecordJson().
  END.
  IF cOperation = "delete" THEN DO:
   IF cResource = "despesas" THEN DO:
    RUN CheckExpenseDelete.
    RUN DeleteChildren(phRelacao,EqId(phRelacao,"despesa_id",iId)).
   END.
   ELSE DO:
    iDesp = phVinculo:BUFFER-FIELD("despesa_id"):BUFFER-VALUE.
    iEmpresa = phVinculo:BUFFER-FIELD("empresa_id"):BUFFER-VALUE.
    IF iDesp = ? OR iEmpresa = ? THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Chave do vinculo desconhecida; exclusao bloqueada.",409).
    IF NOT Found(hRefDesp,EqId(hRefDesp,"despesa_id",iDesp),TRUE) THEN RUN Fail("DESPESAS_REFERENCE_INVALID","Despesa do vinculo inexistente; exclusao bloqueada.",409).
    RUN DeleteChildren(phImposto,EqId(phImposto,"despesa_id",iDesp) + " AND " + EqId(phImposto,"empresa_id",iEmpresa)).
   END.
   IF NOT hData:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao recusada",0).
  END.
  ELSE DO:
   FOR EACH ttValue:
    IF cResource = "despesas" AND ttValue.fieldName = "log_imposto" AND
      (hData:BUFFER-FIELD("log_imposto"):BUFFER-VALUE = ? OR
       hData:BUFFER-FIELD("log_imposto"):BUFFER-VALUE <> ttValue.numValue) THEN DO:
     IF ttValue.numValue = 0 AND HasDependency(hImpRead,"imposto_id",iId) THEN
      RUN Fail("DESPESAS_IN_USE","Despesa usada como imposto nao pode perder essa classificacao.",409).
     IF ttValue.numValue = 1 AND HasDependency(hOtherVinc,"despesa_custo_id",iId) THEN
      RUN Fail("DESPESAS_IN_USE","Despesa usada como custo nao pode passar a ser imposto.",409).
    END.
    IF cResource = "empresas_despesa" AND cOperation = "update" AND LOOKUP(ttValue.fieldName,"despesa_id,empresa_id") > 0 THEN
     IF hData:BUFFER-FIELD(ttValue.fieldName):BUFFER-VALUE <> ttValue.numValue OR hData:BUFFER-FIELD(ttValue.fieldName):BUFFER-VALUE = ? THEN RUN Fail("DESPESAS_KEYS_IMMUTABLE","Empresa e despesa do vinculo nao podem ser alteradas. Crie outro vinculo.",422).
    CASE ttValue.fieldType:
     WHEN "CHARACTER" THEN hData:BUFFER-FIELD(ttValue.fieldName):BUFFER-VALUE = IF ttValue.nullValue THEN ? ELSE ttValue.textValue.
     WHEN "LOGICAL" THEN hData:BUFFER-FIELD(ttValue.fieldName):BUFFER-VALUE = ttValue.boolValue.
     OTHERWISE hData:BUFFER-FIELD(ttValue.fieldName):BUFFER-VALUE = ttValue.numValue.
    END CASE.
   END.
   IF cResource = "empresas_despesa" THEN RUN ValidateLink.
   ELSE iDesp = iId.
   IF NOT hData:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Gravacao recusada",0).
   IF lCollection THEN RUN SyncChildren.
   joResult = RecordJson().
  END.
 END.
 poResponse:Add("success",TRUE).
 IF cOperation <> "delete" THEN poResponse:Add("data",joResult).
 /* Publicar somente apos o DO TRANSACTION terminar sem erro. */
 joAudit = NEW JsonObject().
 joAudit:Add("version",1).
 joAudit:Add("source","progress-transaction").
 joAudit:Add("resource",cResource).
 joAudit:Add("operation",cOperation).
 joAudit:Add("recordId",iId).
 joAudit:Add("before",joBefore).
 IF cOperation = "delete" THEN joAudit:Add("after",NEW JsonObject()).
 ELSE joAudit:Add("after",CAST(joResult:Clone(),JsonObject)).
 poResponse:Add("audit",joAudit).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) THEN poResponse = NEW JsonObject().
  IF NOT poResponse:Has("error") THEN RUN BuildError("DESPESAS_PERSISTENCE_REJECTED","Operacao recusada pelo banco. Nenhuma alteracao confirmada.",409).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hData) THEN hData:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phRelacao) THEN phRelacao:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phImposto) THEN phImposto:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(hRefDesp) THEN DELETE OBJECT hRefDesp NO-ERROR.
  IF VALID-HANDLE(hRefEmp) THEN DELETE OBJECT hRefEmp NO-ERROR.
  IF VALID-HANDLE(hOtherVinc) THEN DELETE OBJECT hOtherVinc NO-ERROR.
  IF VALID-HANDLE(hRelRead) THEN DELETE OBJECT hRelRead NO-ERROR.
  IF VALID-HANDLE(hImpRead) THEN DELETE OBJECT hImpRead NO-ERROR.
  IF VALID-HANDLE(hAnchor) THEN DELETE OBJECT hAnchor NO-ERROR.
  IF VALID-HANDLE(phCompra) THEN phCompra:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phContainer) THEN phContainer:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phHistorico) THEN phHistorico:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE BuildError:
 DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
 DEFINE VARIABLE e AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 poResponse = NEW JsonObject(). e = NEW JsonObject().
 poResponse:Add("success",FALSE). e:Add("code",pcCode). e:Add("message",pcMessage). e:Add("status",piStatus). poResponse:Add("error",e).
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
 RUN BuildError(pcCode,pcMessage,piStatus).
 UNDO, THROW NEW Progress.Lang.AppError(pcCode,0).
END PROCEDURE.

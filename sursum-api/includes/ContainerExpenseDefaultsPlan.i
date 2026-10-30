/* Private plans using the fiscal service's sole catalog, arithmetic and persistence. */
FUNCTION DefaultsEligible RETURNS LOGICAL(defId AS INTEGER):
 FIND FIRST ttDef WHERE ttDef.id=defId NO-ERROR.
 IF NOT AVAILABLE ttDef THEN RETURN FALSE.
 FIND FIRST ttLink WHERE ttLink.id=defId NO-ERROR.
 IF NOT AVAILABLE ttLink THEN RETURN FALSE.
 IF ttLink.active=? OR ttDef.tax=? THEN RETURN FALSE.
 RETURN ttLink.active=1 AND ttDef.tax=0 AND defId<>iDistribution AND NOT CAN-FIND(FIRST bLink WHERE bLink.costId=defId).
END FUNCTION.
PROCEDURE DefaultsSelectionInput:
 DEFINE VARIABLE valuesArray AS JsonArray NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT poRequest:Has('despesa_ids') THEN RUN Fail('CONTAINER_SELECTION_INVALID','Selecao obrigatoria.',422).
 IF poRequest:GetType('despesa_ids')<>JsonDataType:ARRAY THEN RUN Fail('CONTAINER_SELECTION_INVALID','Selecao deve ser lista de IDs.',422).
 valuesArray=poRequest:GetJsonArray('despesa_ids').
 IF valuesArray:Length<1 OR valuesArray:Length>100 THEN RUN Fail('CONTAINER_SELECTION_INVALID','Selecione de1a100despesas.',422).
 DO j=1 TO valuesArray:Length:
  IF valuesArray:GetType(j)<>JsonDataType:NUMBER THEN RUN Fail('CONTAINER_SELECTION_INVALID','ID deve ser inteiro positivo.',422).
  d=valuesArray:GetDecimal(j).
  IF d=? OR d<1 OR d>2147483647 OR d<>TRUNCATE(d,0) OR CAN-FIND(FIRST ttSelected WHERE ttSelected.id=INTEGER(d)) THEN RUN Fail('CONTAINER_SELECTION_INVALID','ID invalido ou repetido.',422).
  CREATE ttSelected. ASSIGN ttSelected.id=INTEGER(d) ttSelected.ordinal=j.
 END.
END PROCEDURE.
PROCEDURE DefaultsBuildOrder:
 DEFINE VARIABLE fieldValue AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE directionValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE mappedValue AS CHARACTER NO-UNDO. DEFINE VARIABLE qOrder AS HANDLE NO-UNDO. DEFINE VARIABLE p AS INTEGER NO-UNDO.
 DEFINE VARIABLE subsetPresent AS LOGICAL NO-UNDO. DEFINE VARIABLE relevant AS LOGICAL NO-UNDO.
 ASSIGN fieldValue='ordem' directionValue='asc'.
 IF poRequest:Has('ordem_campo') THEN DO:
  IF poRequest:GetType('ordem_campo')<>JsonDataType:STRING THEN RUN Fail('CONTAINER_SELECTION_ORDER','Campo de ordenacao invalido.',422).
  fieldValue=poRequest:GetCharacter('ordem_campo').
 END.
 IF poRequest:Has('ordem_direcao') THEN DO:
  IF poRequest:GetType('ordem_direcao')<>JsonDataType:STRING THEN RUN Fail('CONTAINER_SELECTION_ORDER','Direcao invalida.',422).
  directionValue=poRequest:GetCharacter('ordem_direcao').
 END.
 CASE fieldValue:
  WHEN 'ordem' THEN mappedValue='ordinal'. WHEN 'despesa_id' THEN mappedValue='id'.
  WHEN 'descricao' THEN mappedValue='description'. WHEN 'log_calculada' THEN mappedValue='calculated'. WHEN 'perc_calculo' THEN mappedValue='percentage'.
  OTHERWISE RUN Fail('CONTAINER_SELECTION_ORDER','Coluna fora da lista fechada.',422).
 END CASE.
 IF directionValue<>'asc' AND directionValue<>'desc' THEN RUN Fail('CONTAINER_SELECTION_ORDER','Direcao fora da lista fechada.',422).
 /* Text SQL collation was not proven; do not silently choose ABL collation. */
 IF fieldValue='descricao' THEN RUN Fail('CONTAINER_SELECTION_ORDER_UNPROVEN','Ordenacao por descricao ainda nao esta disponivel.',422).
 FOR EACH ttSelected:
  FIND ttDef WHERE ttDef.id=ttSelected.id NO-ERROR.
  IF AVAILABLE ttDef THEN IF ttDef.calculated=TRUE THEN subsetPresent=TRUE.
 END.
 FOR EACH ttDef:
  relevant=DefaultsEligible(ttDef.id).
  IF cOperation='selecionar_despesas' AND NOT subsetPresent AND ttDef.calculated=TRUE THEN DO:
   IF CAN-FIND(FIRST ttExpense WHERE ttExpense.expenseId=ttDef.id AND ttExpense.manual=FALSE) THEN relevant=TRUE.
   IF CAN-FIND(FIRST ttLink WHERE ttLink.id=ttDef.id AND ttLink.active=1) AND ttDef.percentage<>? AND ttDef.percentage<>0 THEN relevant=TRUE.
  END.
  IF NOT relevant THEN NEXT.
  IF (fieldValue='ordem' AND ttDef.ordinal=?) OR (fieldValue='log_calculada' AND ttDef.calculated=?) OR (fieldValue='perc_calculo' AND ttDef.percentage=?) THEN RUN Fail('CONTAINER_SELECTION_ORDER_UNPROVEN','Ordenacao com valores desconhecidos ainda nao esta disponivel.',422).
 END.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY qOrder. qOrder:SET-BUFFERS(BUFFER ttDef:HANDLE).
  IF NOT qOrder:QUERY-PREPARE('FOR EACH ttDef BY ttDef.' + mappedValue + (IF directionValue='desc' THEN ' DESCENDING' ELSE '') + ' BY ttDef.id') THEN RUN Fail('CONTAINER_SELECTION_ORDER','Ordenacao interna indisponivel.',503).
  qOrder:QUERY-OPEN(). qOrder:GET-FIRST().
  DO WHILE NOT qOrder:QUERY-OFF-END:
   p=p + 1. CREATE ttSelectionOrder. ASSIGN ttSelectionOrder.id=ttDef.id ttSelectionOrder.position=p. qOrder:GET-NEXT().
  END.
  FINALLY: IF VALID-HANDLE(qOrder) THEN DO: qOrder:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qOrder NO-ERROR. END. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE DefaultsPolicy:
 IF NOT VALID-OBJECT(poPolicy) THEN RUN Fail('CONTAINER_INPUT_INVALID','Politica interna ausente.',422).
 IF NOT poPolicy:Has('despesa_distr_custo') THEN RUN Fail('CONTAINER_INPUT_INVALID','Parametro interno de distribuicao ausente.',422).
 IF poPolicy:GetType('despesa_distr_custo')<>JsonDataType:NUMBER THEN RUN Fail('CONTAINER_INPUT_INVALID','Parametro interno invalido.',422).
 dValue=poPolicy:GetDecimal('despesa_distr_custo').
 IF dValue=? OR dValue<0 OR dValue>2147483647 OR dValue<>TRUNCATE(dValue,0) THEN RUN Fail('CONTAINER_INPUT_INVALID','Parametro interno invalido.',422).
 iDistribution=INTEGER(dValue).
END PROCEDURE.
PROCEDURE DefaultsValidateSelection:
 FOR EACH ttSelected:
  IF NOT DefaultsEligible(ttSelected.id) THEN RUN Fail('CONTAINER_SELECTION_STALE','Despesa selecionada nao esta mais disponivel. Recarregue a selecao.',409).
  ttSelected.calculated=ttDef.calculated=TRUE.
  FIND ttSelectionOrder WHERE ttSelectionOrder.id=ttSelected.id. ttSelected.ordinal=ttSelectionOrder.position.
 END.
 lSelectedCalculated=CAN-FIND(FIRST ttSelected WHERE ttSelected.calculated).
END PROCEDURE.
PROCEDURE DefaultsPlan:
 RUN DefaultsValidateSelection.
 FOR EACH ttLink WHERE ttLink.active=1:
  FIND ttDef WHERE ttDef.id=ttLink.id.
  IF ttDef.tax<>0 THEN NEXT.
  IF ttLink.defaultValue=? OR ttDef.percentage=? THEN RUN Fail('CONTAINER_VALUE_UNKNOWN','Default ou percentual desconhecido.',422).
  ASSIGN dValues[1]=ttLink.defaultValue dValues[2]=0 dValues[3]=0.
  RUN UpsertPlan(ttLink.id,0,FALSE,ttDef.percentage,'').
 END.
 /* The source marks every row of a selected definition, including item rows. */
 FOR EACH ttExpense:
  IF CAN-FIND(FIRST ttSelected WHERE ttSelected.id=ttExpense.expenseId) THEN ASSIGN ttExpense.used=TRUE ttExpense.changed=TRUE.
 END.
END PROCEDURE.
PROCEDURE DefaultsOptions:
 DEFINE VARIABLE rows AS JsonArray NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE labelValue AS CHARACTER NO-UNDO. DEFINE VARIABLE positionValue AS INTEGER NO-UNDO.
 rows=NEW JsonArray().
 FOR EACH ttSelectionOrder BY ttSelectionOrder.position:
  FIND ttDef WHERE ttDef.id=ttSelectionOrder.id.
  IF NOT DefaultsEligible(ttDef.id) THEN NEXT.
  positionValue=positionValue + 1. IF positionValue>200 THEN RUN Fail('CONTAINER_SELECTION_OPTIONS_LIMIT','Mais de200opcoes; selecao nativa nao sera truncada.',503).
  rowValue=NEW JsonObject(). rowValue:Add('container_id',iContainer). rowValue:Add('despesa_id',ttDef.id). rowValue:Add('position',positionValue).
  IF ttDef.description=? THEN rowValue:AddNull('descricao'). ELSE rowValue:Add('descricao',ttDef.description).
  IF ttDef.ordinal=? THEN rowValue:AddNull('ordem'). ELSE rowValue:Add('ordem',ttDef.ordinal).
  IF ttDef.calculated=? THEN rowValue:AddNull('log_calculada'). ELSE rowValue:Add('log_calculada',ttDef.calculated).
  IF ttDef.percentage=? THEN rowValue:AddNull('perc_calculo'). ELSE rowValue:Add('perc_calculo',ttDef.percentage).
  labelValue=Num(positionValue) + '. ' + Num(ttDef.id) + ' - ' + (IF ttDef.description=? THEN '[descricao desconhecida]' ELSE ttDef.description).
  rowValue:Add('label',labelValue). rows:Add(rowValue).
 END.
 poResponse:Add('success',TRUE). poResponse:Add('data',rows). poResponse:Add('total',rows:Length).
END PROCEDURE.

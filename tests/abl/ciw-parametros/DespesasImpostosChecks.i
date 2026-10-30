/* Compor no final de DespesasCrudTest.p; usa somente as mesmas TTs isoladas. */
DEFINE VARIABLE ciwOtherVinc AS INTEGER NO-UNDO.
DO k=1001 TO 1003:
 CREATE ttDesp. ASSIGN ttDesp.despesa_id=k ttDesp.descricao="CODEx-" + STRING(k) ttDesp.log_imposto=IF k=1002 THEN 1 ELSE 0. VALIDATE ttDesp.
END. RELEASE ttDesp.
DO k=1001 TO 1002:
 CREATE ttEmpresa. ASSIGN ttEmpresa.empresa_id=k ttEmpresa.nome="CODEx-" + STRING(k). VALIDATE ttEmpresa.
END. RELEASE ttEmpresa.
RUN NewReq("empresas_despesa","create",0). req:Add("despesa_id",1001). req:Add("empresa_id",1001).
arr=NEW JsonArray(). arr:Add(1002). req:Add("impostos",arr). RUN CallService.
RUN Check(res:GetLogical("success"),"CIW cria relacao na empresa1"). vincId=res:GetJsonObject("data"):GetInteger("empresa_despesa_id").
RUN NewReq("empresas_despesa","create",0). req:Add("despesa_id",1001). req:Add("empresa_id",1002).
arr=NEW JsonArray(). arr:Add(1002). req:Add("impostos",arr). RUN CallService.
RUN Check(res:GetLogical("success"),"CIW mesma despesa e imposto na empresa2"). ciwOtherVinc=res:GetJsonObject("data"):GetInteger("empresa_despesa_id").
RUN Check(CAN-FIND(ttImp WHERE ttImp.despesa_id=1001 AND ttImp.imposto_id=1002 AND ttImp.empresa_id=1001) AND CAN-FIND(ttImp WHERE ttImp.despesa_id=1001 AND ttImp.imposto_id=1002 AND ttImp.empresa_id=1002),"CIW identidade composta distingue empresas").
RUN NewReq("empresas_despesa","update",vincId). arr=NEW JsonArray(). req:Add("impostos",arr). RUN CallService.
RUN Check(res:GetLogical("success"),"CIW remove relacao selecionada").
RUN Check(NOT CAN-FIND(ttImp WHERE ttImp.despesa_id=1001 AND ttImp.empresa_id=1001) AND CAN-FIND(ttImp WHERE ttImp.despesa_id=1001 AND ttImp.imposto_id=1002 AND ttImp.empresa_id=1002),"CIW exclusao preserva outra empresa").
RUN NewReq("empresas_despesa","update",ciwOtherVinc). arr=NEW JsonArray(). arr:Add(1002). req:Add("impostos",arr). RUN CallService.
RUN Check(res:GetLogical("success"),"CIW atribuicao idempotente").
RUN NewReq("empresas_despesa","update",vincId). arr=NEW JsonArray(). arr:Add(1002). arr:Add(1003). req:Add("impostos",arr). RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
RUN Check(NOT CAN-FIND(ttImp WHERE ttImp.despesa_id=1001 AND ttImp.empresa_id=1001),"CIW imposto valido anterior ao invalido sofre rollback").
RUN Check(CAN-FIND(ttImp WHERE ttImp.despesa_id=1001 AND ttImp.imposto_id=1002 AND ttImp.empresa_id=1002),"CIW falha nao altera outra empresa").
RUN NewReq("empresas_despesa","delete",vincId). RUN CallService. RUN Check(res:GetLogical("success"),"CIW limpeza pai1").
RUN NewReq("empresas_despesa","delete",ciwOtherVinc). RUN CallService. RUN Check(res:GetLogical("success"),"CIW limpeza pai2").
RUN Check(NOT CAN-FIND(ttImp WHERE ttImp.despesa_id=1001),"CIW limpeza dos filhos da fixture").

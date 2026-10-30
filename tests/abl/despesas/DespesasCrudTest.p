BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
/* Somente temp-tables undoable. Nenhum banco operacional e acessado. */
DEFINE TEMP-TABLE ttDesp
 FIELD despesa_id AS INTEGER FIELD descricao AS CHARACTER FIELD log_imposto AS INTEGER
 FIELD ordem AS INTEGER FIELD log_calculada AS LOGICAL FIELD perc_calculo AS DECIMAL DECIMALS 4
 FIELD log_vl_prod_base_calculo AS LOGICAL FIELD log_calc_por_item AS LOGICAL FIELD ind_imposto AS INTEGER
 INDEX pk IS PRIMARY UNIQUE despesa_id.
DEFINE TEMP-TABLE ttVinc
 FIELD empresa_despesa_id AS INTEGER FIELD despesa_id AS INTEGER FIELD empresa_id AS INTEGER
 FIELD codigo_desp_erp AS INTEGER FIELD vl_padrao AS DECIMAL DECIMALS 2 FIELD percentual AS DECIMAL DECIMALS 4
 FIELD cod_nat_operacao AS CHARACTER FIELD log_ativo AS INTEGER FIELD perc_custo AS INTEGER
 FIELD percentual_custo AS DECIMAL DECIMALS 4 FIELD despesa_custo_id AS INTEGER FIELD log_custo AS INTEGER
 INDEX pk IS PRIMARY UNIQUE empresa_despesa_id.
DEFINE TEMP-TABLE ttEmpresa FIELD empresa_id AS INTEGER FIELD nome AS CHARACTER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttRel FIELD relac_desp_calculada_id AS INTEGER FIELD despesa_id AS INTEGER FIELD despesa_id_base AS INTEGER
 INDEX primario IS PRIMARY relac_desp_calculada_id INDEX par IS UNIQUE despesa_id despesa_id_base.
DEFINE TEMP-TABLE ttImp FIELD despesa_id AS INTEGER FIELD imposto_id AS INTEGER FIELD empresa_id AS INTEGER
 INDEX pk IS PRIMARY UNIQUE despesa_id imposto_id empresa_id.
DEFINE TEMP-TABLE ttCompra FIELD despesa_id AS INTEGER.
DEFINE TEMP-TABLE ttContainer FIELD despesa_id AS INTEGER.
DEFINE TEMP-TABLE ttHist FIELD despesa_id AS INTEGER.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE arr AS JsonArray NO-UNDO.
DEFINE VARIABLE obj AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE vincId AS INTEGER NO-UNDO.
DEFINE VARIABLE originalFormat AS CHARACTER NO-UNDO.
DEFINE VARIABLE precisionBuffer AS HANDLE NO-UNDO.
originalFormat = SESSION:NUMERIC-FORMAT.
OUTPUT TO "despesas-tests.log".
PUT UNFORMATTED "FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
DO ON ERROR UNDO, THROW:
 IF SEARCH("DespesasCrudService.p") = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico despesas ainda nao implementado",0).
 DO k=1 TO 4:
  CREATE ttDesp. ASSIGN ttDesp.despesa_id=k ttDesp.descricao="Despesa " + STRING(k)
   ttDesp.log_imposto=IF k=2 THEN 1 ELSE 0. VALIDATE ttDesp.
 END. RELEASE ttDesp.
 CREATE ttEmpresa. ASSIGN ttEmpresa.empresa_id=1 ttEmpresa.nome="Empresa Um". VALIDATE ttEmpresa. RELEASE ttEmpresa.
 CREATE ttEmpresa. ASSIGN ttEmpresa.empresa_id=2 ttEmpresa.nome="Empresa Dois". VALIDATE ttEmpresa. RELEASE ttEmpresa.
 CREATE ttRel. ASSIGN ttRel.relac_desp_calculada_id=90 ttRel.despesa_id=4 ttRel.despesa_id_base=3. VALIDATE ttRel. RELEASE ttRel.
 CREATE ttRel. ASSIGN ttRel.relac_desp_calculada_id=2 ttRel.despesa_id=1 ttRel.despesa_id_base=3. VALIDATE ttRel. RELEASE ttRel.

 RUN NewReq("despesas","update",1). req:Add("descricao","São José").
 arr=NEW JsonArray(). arr:Add(3). arr:Add(2). req:Add("md_relacs_desp",arr).
 req:Add("perc_calculo",12.3456). req:Add("log_calculada",FALSE).
 RUN CallService. RUN Check(res:GetLogical("success"),"update despesa e bases").
 RUN Check(res:Has("audit"),"update retorna snapshot transacional confirmado").
 audit=res:GetJsonObject("audit").
 RUN Check(audit:GetInteger("version")=1 AND audit:GetCharacter("source")="progress-transaction","proveniencia do snapshot").
 RUN Check(audit:GetCharacter("resource")="despesas" AND audit:GetCharacter("operation")="update" AND audit:GetInteger("recordId")=1,"snapshot vinculado ao recurso operacao e ID").
 RUN Check(audit:GetJsonObject("before"):GetCharacter("descricao")="Despesa 1","anterior vem do buffer antes da atribuicao").
 RUN Check(audit:GetJsonObject("after"):GetCharacter("descricao")="São José","posterior vem do buffer gravado").
 RUN Check(audit:GetJsonObject("before"):GetJsonArray("md_relacs_desp"):Length=1 AND audit:GetJsonObject("after"):GetJsonArray("md_relacs_desp"):Length=2,"snapshot inclui colecao antes e depois").
 obj=res:GetJsonObject("data"). RUN Check(obj:GetJsonArray("md_relacs_desp"):Length=2,"colecao retornada").
 RUN Check(obj:GetDecimal("perc_calculo")=12.3456,"quatro decimais preservados mesmo calculada false").
 RUN Check(SESSION:NUMERIC-FORMAT=originalFormat,"servico preserva formato da sessao apos JSONNUMBER").
 RUN NewReq("despesas","update",1). req:Add("perc_calculo","12.3456"). RUN CallService.
 RUN Check(res:GetLogical("success"),"string decimal invariante aceita").
 RUN Check(res:GetJsonObject("data"):GetDecimal("perc_calculo")=12.3456,"string decimal preserva quatro casas nas duas culturas").
 RUN Check(SESSION:NUMERIC-FORMAT=originalFormat,"servico preserva formato da sessao apos STRING").
 RUN NewReq("despesas","update",1). req:Add("descricao","São José"). RUN CallService.
 RUN Check(res:GetJsonObject("data"):GetDecimal("perc_calculo")=12.3456,"numero omitido preserva valor").
 RUN NewReq("despesas","update",1). req:AddNull("perc_calculo"). RUN CallService.
 RUN Check(res:GetLogical("success"),"campo numerico opcional null pode ser limpo").
 RUN Check(res:GetJsonObject("data"):GetDecimal("perc_calculo")=0,"limpar numerico null persiste zero").
 RUN NewReq("despesas","update",1). req:Add("perc_calculo",9.8765). RUN CallService.
 RUN NewReq("despesas","update",1). req:Add("perc_calculo",""). RUN CallService.
 RUN Check(res:GetLogical("success"),"campo numerico opcional string vazia pode ser limpo").
 RUN Check(res:GetJsonObject("data"):GetDecimal("perc_calculo")=0,"limpar numerico vazio persiste zero").
 FIND ttRel WHERE ttRel.despesa_id=1 AND ttRel.despesa_id_base=2 NO-LOCK.
 RUN Check(ttRel.relac_desp_calculada_id=91,"max relacao explicito independe indice primario nao unico"). RELEASE ttRel.
 RUN NewReq("despesas","get",1). req:Add("despesa_id",1). RUN CallService.
 RUN Check(res:GetLogical("success"),"get aceita alias PK igual ao id").
 RUN Check(req:Has("despesa_id") AND req:GetInteger("despesa_id")=1,"servico nao remove alias do request").
 RUN NewReq("despesas","update",1). req:Add("despesa_id",1). req:Add("descricao","São José"). RUN CallService.
 RUN Check(res:GetLogical("success"),"update aceita alias PK igual ao id").
 RUN NewReq("despesas","update",1). req:Add("despesa_id",2). req:Add("descricao","Alias nao pode mover").
 arr=NEW JsonArray(). req:Add("md_relacs_desp",arr). RUN CallService. RUN Err("DESPESAS_ID_IMMUTABLE").
 FIND ttDesp WHERE ttDesp.despesa_id=1 NO-LOCK. RUN Check(ttDesp.descricao="São José","alias divergente preserva pai"). RELEASE ttDesp.
 RUN Check(CAN-FIND(ttRel WHERE ttRel.despesa_id=1 AND ttRel.despesa_id_base=2),"alias divergente preserva colecao").
 RUN NewReq("despesas","get",1). req:Add("despesa_id",2). RUN CallService. RUN Err("DESPESAS_ID_IMMUTABLE").
 RUN NewReq("despesas","delete",1). req:Add("despesa_id",2). RUN CallService. RUN Err("DESPESAS_ID_IMMUTABLE").
 RUN Check(CAN-FIND(ttDesp WHERE ttDesp.despesa_id=1),"delete alias divergente preserva registro").
 RUN NewReq("despesas","create",0). req:Add("despesa_id",1). RUN CallService. RUN Err("DESPESAS_ID_IMMUTABLE").

 RUN NewReq("despesas","update",1). req:Add("descricao","Nao confirmar").
 arr=NEW JsonArray(). arr:Add(4). arr:Add(999). req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
 FIND ttDesp WHERE ttDesp.despesa_id=1 NO-LOCK. RUN Check(ttDesp.descricao="São José","rollback pai apos falha tardia colecao"). RELEASE ttDesp.
 RUN Check(CAN-FIND(ttRel WHERE ttRel.despesa_id=1 AND ttRel.despesa_id_base=3),"rollback exclusao relacao anterior").
 RUN Check(NOT CAN-FIND(ttRel WHERE ttRel.despesa_id=1 AND ttRel.despesa_id_base=4),"rollback inclusao primeira relacao").

 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). arr:Add(1). req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). arr:Add(3). arr:Add(3). req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). arr:Add("3"). req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:Add("perc_calculo",0.00001).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","create",0). req:Add("descricao",FILL("ã",100)). req:Add("ind_imposto",0).
 RUN CallService. RUN Check(res:GetLogical("success"),"create unicode100").
 audit=res:GetJsonObject("audit").
 RUN Check(audit:GetCharacter("operation")="create" AND audit:GetInteger("recordId")=5,"snapshot inclusao vincula ID gerado").
 RUN Check(NOT audit:GetJsonObject("before"):Has("despesa_id") AND audit:GetJsonObject("after"):GetInteger("despesa_id")=5,"inclusao nao inventa estado anterior").
 RUN Check(res:GetJsonObject("data"):GetInteger("despesa_id")=5,"id gerado").
 RUN NewReq("despesas","create",0). req:Add("descricao",FILL("x",101)). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","create",0). req:Add("sql","invalido"). RUN CallService. RUN Err("DESPESAS_FIELD_INVALID").
 RUN NewReq("despesas","update",1). req:Add("log_imposto",TRUE). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:Add("ind_imposto",6). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:Add("ordem",-1). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:Add("log_calculada",1). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). arr:Add(2147483648). req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). arr:Add(1.5). req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). DO k=1 TO 101: arr:Add(k). END. req:Add("md_relacs_desp",arr).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:AddNull("md_relacs_desp"). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:AddNull("descricao"). RUN CallService.
 RUN Check(res:GetJsonObject("data"):IsNull("descricao"),"texto desconhecido preservado").
 RUN NewReq("despesas","update",1). req:Add("descricao","São José"). RUN CallService.

 RUN NewReq("empresas_despesa","create",0). req:Add("despesa_id",1). req:Add("empresa_id",1).
 req:Add("vl_padrao",0). req:Add("percentual",0). req:Add("percentual_custo",1.2345). req:Add("despesa_custo_id",3).
 arr=NEW JsonArray(). arr:Add(2). req:Add("impostos",arr).
 RUN CallService. RUN Check(res:GetLogical("success"),"vinculo sem exigir funcao morta valor padrao positivo").
 obj=res:GetJsonObject("data"). vincId=obj:GetInteger("empresa_despesa_id").
 RUN Check(obj:GetCharacter("empresa_nome")="Empresa Um","nome virtual").
 RUN Check(obj:GetLogical("eh_imposto")=FALSE,"eh_imposto boolean").
 RUN Check(obj:GetJsonArray("impostos"):GetInteger(1)=2,"imposto retornado").
 RUN NewReq("empresas_despesa","get",vincId). req:Add("empresa_despesa_id",vincId). RUN CallService.
 RUN Check(res:GetLogical("success"),"get vinculo aceita alias PK igual").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("empresa_despesa_id",vincId). req:Add("log_ativo",1). RUN CallService.
 RUN Check(res:GetLogical("success"),"update vinculo aceita alias PK igual").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("empresa_despesa_id",vincId + 1). req:Add("log_ativo",0). RUN CallService.
 RUN Err("DESPESAS_ID_IMMUTABLE").
 FIND ttVinc WHERE ttVinc.empresa_despesa_id=vincId NO-LOCK. RUN Check(ttVinc.log_ativo=1,"alias divergente preserva vinculo"). RELEASE ttVinc.
 RUN NewReq("empresas_despesa","create",0). req:Add("empresa_despesa_id",vincId). RUN CallService. RUN Err("DESPESAS_ID_IMMUTABLE").
 RUN NewReq("despesas","update",2). req:Add("descricao","Nao confirmar imposto"). req:Add("log_imposto",0).
 RUN CallService. RUN Err("DESPESAS_IN_USE").
 FIND ttDesp WHERE ttDesp.despesa_id=2 NO-LOCK.
 RUN Check(ttDesp.log_imposto=1 AND ttDesp.descricao="Despesa " + STRING(2),"rollback troca classificacao imposto e descricao"). RELEASE ttDesp.
 RUN NewReq("despesas","update",3). req:Add("descricao","Nao confirmar custo"). req:Add("log_imposto",1).
 RUN CallService. RUN Err("DESPESAS_IN_USE").
 FIND ttDesp WHERE ttDesp.despesa_id=3 NO-LOCK.
 RUN Check(ttDesp.log_imposto=0 AND ttDesp.descricao="Despesa " + STRING(3),"rollback troca classificacao custo e descricao"). RELEASE ttDesp.
 RUN NewReq("despesas","update",5). req:Add("log_imposto",1). RUN CallService.
 RUN Check(res:GetLogical("success"),"troca para imposto livre permitida").
 RUN NewReq("despesas","update",5). req:Add("log_imposto",0). RUN CallService.
 RUN Check(res:GetLogical("success"),"troca para nao imposto livre permitida").
 FIND ttVinc WHERE ttVinc.empresa_despesa_id=vincId EXCLUSIVE-LOCK.
 ttVinc.perc_custo=17. VALIDATE ttVinc. RELEASE ttVinc.
 RUN NewReq("empresas_despesa","update",vincId). req:Add("codigo_desp_erp",2147483647). RUN CallService.
 RUN Check(res:GetLogical("success"),"inteiro int32 max aceito").
 RUN Check(res:GetJsonObject("data"):GetInteger("perc_custo")=17,"legado perc_custo preservado").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("empresa_id",2). RUN CallService. RUN Err("DESPESAS_KEYS_IMMUTABLE").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("despesa_id",3). RUN CallService. RUN Err("DESPESAS_KEYS_IMMUTABLE").
 RUN NewReq("empresas_despesa","create",0). req:Add("despesa_id",1). req:Add("empresa_id",1). RUN CallService. RUN Err("DESPESAS_DUPLICATE").
 RUN NewReq("empresas_despesa","create",0). req:Add("despesa_id",1). req:Add("empresa_id",999). RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("percentual_custo",0). RUN CallService. RUN Err("DESPESAS_COST_PAIR_REQUIRED").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("despesa_custo_id",2). RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("codigo_desp_erp",7).
 arr=NEW JsonArray(). arr:Add(3). req:Add("impostos",arr). RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
 FIND ttVinc WHERE ttVinc.empresa_despesa_id=vincId NO-LOCK. RUN Check(ttVinc.codigo_desp_erp=2147483647,"rollback vinculo"). RELEASE ttVinc.
 RUN Check(CAN-FIND(ttImp WHERE ttImp.despesa_id=1 AND ttImp.imposto_id=2 AND ttImp.empresa_id=1),"rollback impostos removidos").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("cod_nat_operacao",FILL("n",13)). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("vl_padrao",1.123). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("perc_custo",0). RUN CallService. RUN Err("DESPESAS_FIELD_READONLY").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("eh_imposto",FALSE). RUN CallService. RUN Err("DESPESAS_FIELD_INVALID").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("despesa_custo_id",0). RUN CallService. RUN Err("DESPESAS_COST_PAIR_REQUIRED").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("codigo_desp_erp",2147483648). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("empresas_despesa","update",vincId). req:Add("vl_padrao",5.25). req:Add("percentual",4.1234). RUN CallService.
 RUN NewReq("empresas_despesa","update",vincId). req:AddNull("vl_padrao"). req:Add("percentual",""). RUN CallService.
 RUN Check(res:GetLogical("success"),"limpar numeros opcionais do vinculo").
 RUN Check(res:GetJsonObject("data"):GetDecimal("vl_padrao")=0 AND res:GetJsonObject("data"):GetDecimal("percentual")=0,"null e vazio opcionais viram zero").
 RUN NewReq("empresas_despesa","create",0). req:Add("despesa_id",1). req:AddNull("empresa_id"). RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").
 RUN NewReq("despesas","get",0). req:AddNull("id"). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("despesas","update",1). req:Add("ordem",NEW JsonObject()). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 RUN NewReq("empresas_despesa","create",0). req:Add("empresa_id",2). req:Add("despesa_id",2).
 req:Add("percentual",1.2345). req:Add("cod_nat_operacao","123456789012").
 RUN CallService. RUN Check(res:GetLogical("success"),"funcao morta XOR nao aplicada").
 RUN Check(res:GetJsonObject("data"):GetLogical("eh_imposto"),"eh_imposto verdadeiro").
 RUN Check(res:GetJsonObject("data"):GetInteger("perc_custo")=0,"create perc_custo zero").
 RUN NewReq("empresas_despesa","update",res:GetJsonObject("data"):GetInteger("empresa_despesa_id")).
 arr=NEW JsonArray(). arr:Add(2). req:Add("impostos",arr). RUN CallService. RUN Err("DESPESAS_REFERENCE_INVALID").

 RUN NewReq("despesas","delete",1). RUN CallService. RUN Err("DESPESAS_IN_USE").
 RUN NewReq("despesas","delete",2). RUN CallService. RUN Err("DESPESAS_IN_USE").
 RUN NewReq("despesas","delete",3). RUN CallService. RUN Err("DESPESAS_IN_USE").
 RUN NewReq("despesas","opcoes_impostos",0). RUN CallService.
 RUN Check(res:GetJsonArray("data"):Length=1,"opcoes somente impostos").
 RUN NewReq("despesas","opcoes_despesas",1). RUN CallService.
 RUN Check(res:GetJsonArray("data"):Length=4,"opcoes excluem propria despesa").
 RUN NewReq("despesas","opcoes_custo",0). RUN CallService.
 RUN Check(res:GetJsonArray("data"):Length=4,"opcoes custo somente nao impostos").
 RUN NewReq("despesas","opcoes_empresas",0). RUN CallService.
 RUN Check(res:GetJsonArray("data"):Length=2,"opcoes empresas").
 RUN NewReq("empresas_despesa","read",0). req:Add("despesa_id",3). RUN CallService.
 RUN Check(res:GetJsonArray("data"):Length=0,"consulta contextual").
 RUN NewReq("empresas_despesa","delete",vincId). req:Add("empresa_despesa_id",vincId). RUN CallService. RUN Check(res:GetLogical("success"),"exclui vinculo com alias PK igual").
 audit=res:GetJsonObject("audit").
 RUN Check(audit:GetJsonObject("before"):GetInteger("empresa_despesa_id")=vincId AND NOT audit:GetJsonObject("after"):Has("empresa_despesa_id"),"exclusao preserva estado anterior do vinculo").
 RUN Check(audit:GetJsonObject("before"):GetJsonArray("impostos"):Length=1,"exclusao captura colecao antes de remover filhos").
 RUN Check(NOT CAN-FIND(ttImp WHERE ttImp.despesa_id=1 AND ttImp.empresa_id=1),"remove filhos proprios").
 RUN NewReq("despesas","update",1). arr=NEW JsonArray(). req:Add("md_relacs_desp",arr). RUN CallService.
 RUN Check(res:GetJsonObject("data"):GetJsonArray("md_relacs_desp"):Length=0,"array vazio limpa").
 CREATE ttCompra. ttCompra.despesa_id=1. VALIDATE ttCompra. RELEASE ttCompra.
 RUN NewReq("despesas","delete",1). RUN CallService. RUN Err("DESPESAS_IN_USE").
 FOR EACH ttCompra: DELETE ttCompra. END.
 CREATE ttContainer. ttContainer.despesa_id=1. VALIDATE ttContainer. RELEASE ttContainer.
 RUN NewReq("despesas","delete",1). RUN CallService. RUN Err("DESPESAS_IN_USE").
 FOR EACH ttContainer: DELETE ttContainer. END.
 CREATE ttHist. ttHist.despesa_id=1. VALIDATE ttHist. RELEASE ttHist.
 RUN NewReq("despesas","delete",1). RUN CallService. RUN Err("DESPESAS_IN_USE").
 FOR EACH ttHist: DELETE ttHist. END.
 RUN NewReq("despesas","delete",1). req:Add("despesa_id",1). RUN CallService. RUN Check(res:GetLogical("success"),"exclui despesa liberada com alias PK igual").
 audit=res:GetJsonObject("audit").
 RUN Check(audit:GetCharacter("operation")="delete" AND audit:GetJsonObject("before"):GetInteger("despesa_id")=1 AND NOT audit:GetJsonObject("after"):Has("despesa_id"),"exclusao despesa captura registro original").
 /* Reproduz armazenamento fisico com2casas sem tocar schema de banco.
    As146verificacoes anteriores seguem executadas com TT DECIMALS4. */
 precisionBuffer = BUFFER ttDesp:HANDLE.
 precisionBuffer:BUFFER-FIELD("perc_calculo"):DECIMALS = 2.
 RUN Check(precisionBuffer:BUFFER-FIELD("perc_calculo"):DECIMALS=2,"TT reproduz escala fisica2").
 RUN NewReq("despesas","update",5). req:Add("descricao","Nao confirmar precisao"). req:Add("perc_calculo",12.3456).
 RUN CallService. RUN Err("DESPESAS_VALIDATION").
 FIND ttDesp WHERE ttDesp.despesa_id=5 NO-LOCK.
 RUN Check(ttDesp.perc_calculo=0 AND ttDesp.descricao=FILL("ã",100),"escala2 rejeita4casas sem alterar pai"). RELEASE ttDesp.
 RUN NewReq("despesas","update",5). req:Add("perc_calculo",12.34). RUN CallService.
 RUN Check(res:GetLogical("success"),"escala2 aceita2casas").
 RUN Check(res:GetJsonObject("data"):GetDecimal("perc_calculo")=12.34,"escala2 persiste sem arredondamento silencioso").
 precisionBuffer:BUFFER-FIELD("perc_calculo"):DECIMALS = 4.
 precisionBuffer = BUFFER ttVinc:HANDLE.
 precisionBuffer:BUFFER-FIELD("percentual"):DECIMALS = 2.
 FIND ttVinc WHERE ttVinc.despesa_id=2 AND ttVinc.empresa_id=2 NO-LOCK.
 vincId = ttVinc.empresa_despesa_id. RELEASE ttVinc.
 RUN NewReq("empresas_despesa","update",vincId). req:Add("percentual",8.7654). RUN CallService. RUN Err("DESPESAS_VALIDATION").
 FIND ttVinc WHERE ttVinc.empresa_despesa_id=vincId NO-LOCK.
 RUN Check(ttVinc.percentual=1.2345,"escala2 rejeita4casas e preserva vinculo"). RELEASE ttVinc.
 RUN NewReq("empresas_despesa","update",vincId). req:Add("percentual",8.76). RUN CallService.
 RUN Check(res:GetLogical("success") AND res:GetJsonObject("data"):GetDecimal("percentual")=8.76,"percentual fisico2 aceita2casas sem arredondar").
 precisionBuffer:BUFFER-FIELD("percentual"):DECIMALS = 4.
 PUT UNFORMATTED "PASS: " n " verificacoes despesas e relacoes" SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
  IF VALID-OBJECT(res) AND res:Has("error") THEN PUT UNFORMATTED res:GetJsonObject("error"):GetCharacter("code") " " res:GetJsonObject("error"):GetCharacter("message") SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
QUIT.
PROCEDURE NewReq:
 DEFINE INPUT PARAMETER r AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER o AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER id AS INTEGER NO-UNDO.
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 req=NEW JsonObject(). req:Add("resource",r). req:Add("operation",o).
 IF id>0 THEN req:Add("id",id).
END PROCEDURE.
PROCEDURE CallService:
 IF VALID-OBJECT(res) THEN DELETE OBJECT res.
 RUN DespesasCrudService.p (INPUT BUFFER ttDesp:HANDLE, INPUT BUFFER ttVinc:HANDLE, INPUT BUFFER ttEmpresa:HANDLE,
  INPUT BUFFER ttRel:HANDLE, INPUT BUFFER ttImp:HANDLE, INPUT BUFFER ttCompra:HANDLE, INPUT BUFFER ttContainer:HANDLE,
  INPUT BUFFER ttHist:HANDLE, INPUT req, OUTPUT res).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(pcLabel,0).
 n = n + 1.
END PROCEDURE.
PROCEDURE Err:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 RUN Check(res:Has("error"),"erro esperado " + code).
 RUN Check(res:GetJsonObject("error"):GetCharacter("code")=code,"codigo esperado " + code).
 RUN Check(NOT res:Has("audit"),"falha nao publica snapshot de gravacao confirmada").
END PROCEDURE.

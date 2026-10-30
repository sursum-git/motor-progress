BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttNf
 FIELD cod-estabel AS CHARACTER FIELD serie AS CHARACTER FIELD nr-nota-fis AS CHARACTER
 FIELD cod-emitente AS INTEGER FIELD nat-operacao AS CHARACTER FIELD dt-emis-nota AS DATE
 FIELD vl-tot-nota AS DECIMAL DECIMALS 5 FIELD vl-mercad AS DECIMAL DECIMALS 5
 FIELD val-desp-outros AS DECIMAL DECIMALS 5 FIELD val-desp-outros-inf AS DECIMAL DECIMALS 5.
DEFINE TEMP-TABLE ttTitle
 FIELD cod_estab AS CHARACTER FIELD cod_espec_docto AS CHARACTER FIELD cod_ser_docto AS CHARACTER
 FIELD cdn_fornecedor AS INTEGER FIELD cod_tit_ap AS CHARACTER FIELD cod_parcela AS CHARACTER
 FIELD dat_emis_docto AS DATE FIELD dat_vencto_tit_ap AS DATE FIELD cod_indic_econ AS CHARACTER
 FIELD val_origin_tit_ap AS DECIMAL DECIMALS 5 FIELD cod_empresa AS CHARACTER FIELD num_id_tit_ap AS INTEGER
 FIELD log_tit_ap_estordo AS LOGICAL FIELD ind_tip_espec_docto AS CHARACTER.
DEFINE TEMP-TABLE ttCompany FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE f AS JsonObject NO-UNDO.
DEFINE VARIABLE a AS JsonArray NO-UNDO.
DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE h AS HANDLE NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER NO-UNDO INITIAL 'notas_fiscais_med'.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE originalCulture AS CHARACTER NO-UNDO.
DEFINE VARIABLE companyCode AS CHARACTER NO-UNDO.
OUTPUT TO VALUE('erp-read-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Check(NUM-DBS=0,'suite exige zero bancos').
 originalCulture=SESSION:NUMERIC-FORMAT.
 DO n=1 TO 4:
  CREATE ttNf. ASSIGN ttNf.cod-estabel=IF n=2 THEN '502' ELSE '501' ttNf.serie=IF n=3 THEN '02' ELSE '01' ttNf.nr-nota-fis='0001'
   ttNf.cod-emitente=n ttNf.nat-operacao=IF n=4 THEN '5102' ELSE '3102' ttNf.dt-emis-nota=DATE(10,n,2026) ttNf.vl-tot-nota=n + 0.12345.
 END.
 /* terceira NF tem outra serie, garantindo chave composta. */
 RELEASE ttNf.
 h=BUFFER ttNf:HANDLE.
 RUN NewReq('read'). req:Add('take',1). req:Add('skip',0). RUN CallService. RUN Success.
 RUN Check(res:GetInteger('total')=3,'natureza3 fixa e total exato').
 RUN Check(res:GetJsonArray('data'):Length=1,'pagina limitada').
 keyValue=res:GetJsonArray('data'):GetJsonObject(1):GetCharacter('record_key').
 RUN NewReq('get'). req:Add('id',keyValue). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject('data'):GetCharacter('cod_estabel')='501','chave completa').
 RUN Check(res:GetJsonObject('data'):GetDecimal('vl_tot_nota')=1.12345,'decimal independente de cultura').
 RUN NewReq('get'). req:Add('id',keyValue). req:Add('record_key',keyValue). RUN CallService. RUN Success.
 RUN NewReq('get'). req:Add('id',keyValue). req:Add('record_key','{}'). RUN CallService. RUN Err(422).
 RUN NewReq('read'). req:Add('skip',1). req:Add('take',1). RUN CallService. RUN Success.
 RUN Check(res:GetJsonArray('data'):GetJsonObject(1):GetCharacter('record_key')<>keyValue,'paginacao estavel').
 RUN NewReq('read'). f=NEW JsonObject(). f:Add('field','cod_emitente'). f:Add('operator','eq'). f:Add('value',2). req:Add('filter',f). RUN CallService. RUN Success.
 RUN Check(res:GetInteger('total')=1,'filtro tipado no servidor').
 RUN NewReq('read'). f=NEW JsonObject(). f:Add('field','vl_tot_nota'). f:Add('operator','eq'). f:Add('value',1.12345). req:Add('filter',f). RUN CallService. RUN Success. RUN Check(res:GetInteger('total')=1,'filtro decimal independente de cultura').
 RUN NewReq('read'). f=NEW JsonObject(). f:Add('field','dt_emis_nota'). f:Add('operator','eq'). f:Add('value','2026-10-02'). req:Add('filter',f). RUN CallService. RUN Success. RUN Check(res:GetInteger('total')=1,'filtro data ISO independente de cultura').
 RUN Check(SESSION:NUMERIC-FORMAT=originalCulture,'cultura da sessao restaurada').
 RUN NewReq('read'). a=NEW JsonArray(). f=NEW JsonObject(). f:Add('field','cod_emitente'). f:Add('dir','desc'). a:Add(f). req:Add('sort',a). req:Add('take',1). RUN CallService. RUN Success.
 RUN Check(res:GetJsonArray('data'):GetJsonObject(1):GetInteger('cod_emitente')=3,'ordenacao no servidor').
 RUN NewReq('read'). req:Add('skip',99). req:Add('take',20). RUN CallService. RUN Success. RUN Check(res:GetInteger('total')=3 AND res:GetJsonArray('data'):Length=0,'pagina alem do fim nao altera total').
 RUN NewReq('read'). f=NEW JsonObject(). f:Add('logic','or'). a=NEW JsonArray().
 DO n=1 TO 2: res=NEW JsonObject(). res:Add('field','cod_emitente'). res:Add('operator','eq'). res:Add('value',n). a:Add(res). END.
 f:Add('filters',a). req:Add('filter',f). RUN CallService. RUN Success. RUN Check(res:GetInteger('total')=2,'grupo OR preservado').
 RUN NewReq('read'). f=NEW JsonObject(). f:Add('field','nr_nota_fis'). f:Add('operator','eq'). f:Add('value',"x' OR TRUE"). req:Add('filter',f). RUN CallService. RUN Success. RUN Check(res:GetInteger('total')=0,'texto nao vira expressao').
 RUN NewReq('read'). req:Add('take',201). RUN CallService. RUN Err(422).
 RUN NewReq('read'). req:Add('skip',-1). RUN CallService. RUN Err(422).
 RUN NewReq('create'). RUN CallService. RUN Err(405).
 RUN NewReq('read'). req:Add('table','auth_user'). RUN CallService. RUN Err(422).
 RUN NewReq('read'). f=NEW JsonObject(). f:Add('field','cod_emitente'). f:Add('operator','eq'). f:Add('value','1 OR TRUE'). req:Add('filter',f). RUN CallService. RUN Err(422).
 RUN NewReq('get'). req:Add('id','{}'). RUN CallService. RUN Err(422).
 CREATE ttNf. ASSIGN ttNf.cod-estabel='501' ttNf.serie='01' ttNf.nr-nota-fis='0001' ttNf.nat-operacao='3102'. RELEASE ttNf.
 RUN NewReq('get'). req:Add('id',keyValue). RUN CallService. RUN Err(409).
 EMPTY TEMP-TABLE ttNf.
 DO n=1 TO 5:
  CREATE ttTitle. ASSIGN ttTitle.cod_empresa=IF n=3 THEN 'OTHER' ELSE 'MED_CODE_TEST'
   ttTitle.cod_estab='501' ttTitle.num_id_tit_ap=n ttTitle.cod_tit_ap='T' + STRING(n) ttTitle.cod_parcela='01'
   ttTitle.cod_ser_docto='' ttTitle.cod_espec_docto='AD' ttTitle.cdn_fornecedor=1 ttTitle.val_origin_tit_ap=10
   ttTitle.ind_tip_espec_docto=IF n=4 THEN 'normal' ELSE 'antecipacao' ttTitle.log_tit_ap_estordo=n=5.
 END.
 RELEASE ttTitle. ASSIGN h=BUFFER ttTitle:HANDLE resourceName='titulos_pagar_med'.
 RUN NewReq('read'). RUN CallService. RUN Success. RUN Check(res:GetInteger('total')=2,'empresa e elegibilidade fixas').
 RUN Check(res:GetJsonArray('data'):GetJsonObject(1):GetInteger('num_id_tit_ap')=1,'inteiro real').
 RUN Check(NOT res:Has('audit'),'consulta nao simula auditoria de escrita').
 CREATE ttCompany. ASSIGN ttCompany.cod_emp_ems2=5 ttCompany.cod_emp_ems5=7. RELEASE ttCompany.
 RUN CiwMedCompanyContext.p(INPUT BUFFER ttCompany:HANDLE,OUTPUT companyCode). RUN Check(companyCode='7','EMS5 resolvido no cadastro, nao presumido').
 RUN Check(SESSION:NUMERIC-FORMAT=originalCulture,'resolver preserva cultura').
 EMPTY TEMP-TABLE ttCompany. EMPTY TEMP-TABLE ttTitle. PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE NewReq:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',op).
END PROCEDURE.
PROCEDURE CallService:
 RUN CiwErpReadService.p(h,resourceName,'MED_CODE_TEST',req,OUTPUT res).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE Success: RUN Check(res:Has('success') AND res:GetLogical('success'),'sucesso esperado'). END PROCEDURE.
PROCEDURE Err:
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN Check(res:Has('error'),'erro esperado'). RUN Check(res:GetJsonObject('error'):GetInteger('status')=statusCode,'status esperado').
END PROCEDURE.

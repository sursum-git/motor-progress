BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
/* Exclusivamente TTs undoable; nenhuma conexao operacional. */
DEFINE TEMP-TABLE ttHist FIELD hist_cotacao_bc_id AS INTEGER FIELD data AS DATE
 FIELD serie AS INTEGER FIELD valor AS DECIMAL DECIMALS 5 FIELD dt_hr_busca AS DATETIME
 FIELD nome_serie AS CHARACTER FIELD log_ok AS LOGICAL FIELD log_manual AS LOGICAL
 INDEX pk IS PRIMARY hist_cotacao_bc_id.
DEFINE TEMP-TABLE ttContainer FIELD nr-container AS INTEGER FIELD situacao AS INTEGER
 FIELD ordem_busca_dolar_compra AS CHARACTER FIELD log_versao_custo_desatualizada AS LOGICAL
 FIELD dt_hr_ult_alt_versao_custo AS DATETIME INDEX pk IS PRIMARY nr-container.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE nextId AS INTEGER NO-UNDO INITIAL 100.
DEFINE VARIABLE id AS INTEGER NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE oldStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
OUTPUT TO VALUE('cotacoes-tests-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Check(SEARCH('CiwCotacoesService.p')<>?,'servico de cotacoes ausente').
 RUN Check(NUM-DBS=0,'suite exige zero bancos conectados').
 CREATE ttContainer. ASSIGN ttContainer.nr-container=1 ttContainer.situacao=1 ttContainer.ordem_busca_dolar_compra='1'.
 CREATE ttContainer. ASSIGN ttContainer.nr-container=2 ttContainer.situacao=1 ttContainer.ordem_busca_dolar_compra='1,2'.
 CREATE ttContainer. ASSIGN ttContainer.nr-container=3 ttContainer.situacao=3 ttContainer.ordem_busca_dolar_compra='1'. RELEASE ttContainer.
 CREATE ttContainer. ASSIGN ttContainer.nr-container=5 ttContainer.situacao=1 ttContainer.ordem_busca_dolar_compra='1 '. RELEASE ttContainer.
 RUN NewRequest('create'). req:Add('data','2026-10-21'). req:Add('serie',1). req:Add('valor',5.12345). req:Add('dt_hr_busca','2026-10-21T15:30:45.123Z'). RUN CallService. RUN Success.
 id=res:GetJsonObject('data'):GetInteger('hist_cotacao_bc_id'). stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN Check(id=101,'ID vem do callback privado').
 RUN Check(res:GetJsonObject('data'):GetDecimal('valor')=5.12345,'cinco casas preservadas').
 RUN Check(res:GetJsonObject('data'):GetLogical('log_manual'),'inclusao sempre manual').
 RUN Check(NOT res:GetJsonObject('data'):IsNull('dt_hr_busca'),'UTC funciona sem override SESSION:TIMEZONE').
 RUN Check(res:GetJsonObject('audit'):GetJsonArray('changes'):Length=0,'serie comum sem invalidacao').
 RUN Check(NOT res:GetJsonObject('audit'):GetJsonObject('before'):Has('hist_cotacao_bc_id'),'create sem anterior').
 RUN NewRequest('get'). req:Add('id',id). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject('data'):GetCharacter('data')='2026-10-21','data ISO independente de cultura').
 RUN NewRequest('get'). req:Add('id',id). req:Add('hist_cotacao_bc_id',id + 1). RUN CallService. RUN Err('CIW_COTACAO_KEY_IMMUTABLE',422).
 RUN NewRequest('update'). req:Add('id',id). req:Add('valor',6). RUN CallService. RUN Err('CIW_COTACAO_ORIGINAL_REQUIRED',422).
 RUN NewRequest('update'). req:Add('id',id). req:Add('row_stamp',stamp). req:Add('valor',5.123456). RUN CallService. RUN Err('CIW_COTACAO_VALIDATION',422).
 RUN NewRequest('update'). req:Add('id',id). req:Add('row_stamp',stamp). req:Add('serie',1.1). RUN CallService. RUN Err('CIW_COTACAO_VALIDATION',422).
 RUN NewRequest('create'). req:Add('data','2026-02-30'). req:Add('serie',1). req:Add('valor',1). RUN CallService. RUN Err('CIW_COTACAO_VALIDATION',422).
 RUN NewRequest('create'). req:Add('data','2026-10-21'). req:Add('serie',1). req:Add('valor','5,00'). RUN CallService. RUN Err('CIW_COTACAO_VALIDATION',422).
 RUN NewRequest('create'). req:Add('data','2026-10-21'). req:Add('serie',1). req:Add('valor',1). req:Add('log_manual',FALSE). RUN CallService. RUN Err('CIW_COTACAO_FIELD_INVALID',422).
 RUN NewRequest('create'). req:Add('data','2026-10-21'). req:Add('serie',1). req:Add('valor',1). req:Add('program','x'). RUN CallService. RUN Err('CIW_COTACAO_FIELD_INVALID',422).
 SESSION:TIMEZONE=-180.
 RUN NewRequest('update'). req:Add('id',id). req:Add('row_stamp',stamp). req:Add('valor',6). req:Add('serie',9999). req:Add('dt_hr_busca','2026-10-21T15:30:45.123Z'). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject('data'):GetCharacter('dt_hr_busca')='2026-10-21T12:30:45.123','UTC do Kendo convertido ao horario local DATETIME').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('before'):GetDecimal('valor')=5.12345,'anterior exato').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetDecimal('valor')=6,'atual exato').
 changes=res:GetJsonObject('audit'):GetJsonArray('changes'). RUN Check(changes:Length=1,'somente container legado elegivel').
 RUN Check(changes:GetJsonObject(1):GetInteger('recordId')=1,'FK de evento filho').
 FIND ttContainer WHERE ttContainer.nr-container=1 NO-LOCK. RUN Check(ttContainer.log_versao_custo_desatualizada,'versao invalidada').
 RUN Check(ttContainer.dt_hr_ult_alt_versao_custo<>?,'timestamp invalidacao'). RELEASE ttContainer.
 oldStamp=stamp. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN NewRequest('delete'). req:Add('id',id). req:Add('row_stamp',oldStamp). RUN CallService. RUN Err('CIW_COTACAO_CHANGED',409).
 /* Container inconsistente ordenado apos o primeiro: erro deve desfazer todos os efeitos. */
 FIND ttContainer WHERE ttContainer.nr-container=1. ttContainer.dt_hr_ult_alt_versao_custo=DATETIME(1,1,2001,0,0,0,0). RELEASE ttContainer.
 CREATE ttContainer. ASSIGN ttContainer.nr-container=? ttContainer.situacao=1 ttContainer.ordem_busca_dolar_compra='1'. RELEASE ttContainer.
 RUN NewRequest('update'). req:Add('id',id). req:Add('row_stamp',stamp). req:Add('valor',7). RUN CallService. RUN Err('CIW_COTACAO_PERSISTENCE_REJECTED',409).
 FIND ttHist WHERE ttHist.hist_cotacao_bc_id=id NO-LOCK. RUN Check(ttHist.valor=6,'rollback preserva cotacao'). RELEASE ttHist.
 FIND ttContainer WHERE ttContainer.nr-container=1 NO-LOCK. RUN Check(ttContainer.dt_hr_ult_alt_versao_custo=DATETIME(1,1,2001,0,0,0,0),'rollback preserva primeiro filho'). RELEASE ttContainer.
 RUN NewRequest('delete'). req:Add('id',id). req:Add('row_stamp',stamp). req:Add('data','2026-10-21'). req:Add('serie',9999). req:Add('valor',6). RUN CallService. RUN Success.
 RUN Check(res:GetJsonObject('audit'):GetJsonArray('changes'):Length=0,'delete nao invalida como no legado').
 RUN Check(NOT res:GetJsonObject('audit'):GetJsonObject('after'):Has('hist_cotacao_bc_id'),'delete sem atual').
 CREATE ttHist. ASSIGN ttHist.hist_cotacao_bc_id=900 ttHist.data=TODAY ttHist.serie=1 ttHist.valor=1 ttHist.log_manual=FALSE. RELEASE ttHist.
 RUN NewRequest('get'). req:Add('id',900). RUN CallService. RUN Success. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN NewRequest('update'). req:Add('id',900). req:Add('row_stamp',stamp). req:Add('valor',9). RUN CallService. RUN Err('CIW_COTACAO_NOT_MANUAL',409).
 RUN NewRequest('delete'). req:Add('id',900). req:Add('row_stamp',stamp). RUN CallService. RUN Err('CIW_COTACAO_NOT_MANUAL',409).
 CREATE ttHist. ASSIGN ttHist.hist_cotacao_bc_id=900 ttHist.serie=2 ttHist.valor=2. RELEASE ttHist.
 RUN NewRequest('get'). req:Add('id',900). RUN CallService. RUN Err('CIW_COTACAO_AMBIGUOUS',409).
 RUN NewRequest('read'). RUN CallService. RUN Err('CIW_COTACAO_AMBIGUOUS',409).
 EMPTY TEMP-TABLE ttHist. EMPTY TEMP-TABLE ttContainer.
 /* Importacao BC: somente TT; nenhuma chamada HTTP/banco de negocio. */
 RUN NewRequest('import-bc'). req:Add('data','2026-10-20'). req:Add('serie',1). req:Add('valor',5.12345). req:Add('nome_serie','Dolar americano (venda) - diario'). RUN CallService. RUN Success.
 id=res:GetJsonObject('audit'):GetInteger('recordId'). stamp=res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('row_stamp').
 RUN Check(res:GetJsonObject('data'):GetCharacter('type')='message','retorno nativo de processo').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetLogical('log_manual')=FALSE,'BC nunca manual').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetLogical('log_ok')=TRUE,'BC sucesso confirmado').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('data')='2026-10-20','data do BC preservada').
 RUN Check(res:GetJsonObject('audit'):GetJsonArray('changes'):Length=0,'importacao BC nao invalida custos').
 RUN NewRequest('update'). req:Add('id',id). req:Add('row_stamp',stamp). req:Add('valor',6). RUN CallService. RUN Err('CIW_COTACAO_NOT_MANUAL',409).
 RUN NewRequest('delete'). req:Add('id',id). req:Add('row_stamp',stamp). RUN CallService. RUN Err('CIW_COTACAO_NOT_MANUAL',409).
 RUN NewRequest('import-bc'). req:Add('data','2026-10-20'). req:Add('serie',9999). req:Add('valor',5). req:Add('nome_serie','Dolar'). RUN CallService. RUN Err('CIW_COTACAO_VALIDATION',422).
 RUN NewRequest('import-bc'). req:Add('data','2026-10-20'). req:Add('serie',1). req:Add('valor',0). req:Add('nome_serie','Dolar'). RUN CallService. RUN Err('CIW_COTACAO_VALIDATION',422).
 RUN NewRequest('create'). req:Add('data','2026-10-20'). req:Add('serie',1). req:Add('valor',5). req:Add('nome_serie','Injetado'). RUN CallService. RUN Err('CIW_COTACAO_FIELD_INVALID',422).
 EMPTY TEMP-TABLE ttHist. EMPTY TEMP-TABLE ttContainer.
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE NextCotacaoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 ASSIGN nextId=nextId + 1 valueId=nextId.
END PROCEDURE.
PROCEDURE NewRequest:
 DEFINE INPUT PARAMETER op AS CHARACTER NO-UNDO.
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 req=NEW JsonObject(). req:Add('operation',op).
END PROCEDURE.
PROCEDURE CallService:
 IF VALID-OBJECT(res) THEN DELETE OBJECT res.
 RUN CiwCotacoesService.p(INPUT BUFFER ttHist:HANDLE,INPUT BUFFER ttContainer:HANDLE,INPUT THIS-PROCEDURE,INPUT req,OUTPUT res).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError(labelValue,0).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE Success: RUN Check(res:Has('success') AND res:GetLogical('success'),'sucesso esperado'). END PROCEDURE.
PROCEDURE Err:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN Check(res:Has('error'),'erro esperado ' + code).
 RUN Check(res:GetJsonObject('error'):GetCharacter('code')=code,'codigo ' + code).
 RUN Check(res:GetJsonObject('error'):GetInteger('status')=statusCode,'status esperado').
 RUN Check(NOT res:Has('audit'),'falha sem auditoria confirmada').
END PROCEDURE.

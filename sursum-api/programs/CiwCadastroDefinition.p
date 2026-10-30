BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER pcResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE OUTPUT PARAMETER poDefinition AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
FIX-CODEPAGE(textValue) = "UTF-8".
CASE pcResource:
 WHEN "formatos_amostra" THEN textValue="~{~"resource~":~"formatos_amostra~",~"primaryKey~":~"formato_amostra_id~",~"fields~":[~{~"name~":~"descricao~",~"type~":~"character~",~"maxLength~":40,~"allowedCharacters~":~"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,\r\n~"~},~{~"name~":~"log_inativo~",~"type~":~"logical~",~"default~":false~}]~}".
 WHEN "coloracoes" THEN textValue="~{~"resource~":~"coloracoes~",~"primaryKey~":~"coloracao_id~",~"fields~":[~{~"name~":~"descricao~",~"type~":~"character~",~"maxLength~":50~},~{~"name~":~"log_inativo~",~"type~":~"logical~"~}]~}".
 WHEN "situacoes_container" THEN textValue="~{~"resource~":~"situacoes_container~",~"primaryKey~":~"situacao_container_id~",~"fields~":[~{~"name~":~"descricao~",~"type~":~"character~",~"maxLength~":100~},~{~"name~":~"log_gerar_saldo_a_pagar~",~"type~":~"logical~"~},~{~"name~":~"log_gerar_distr_custo~",~"type~":~"logical~"~},~{~"name~":~"num_ordem~",~"type~":~"integer~"~}]~}".
 WHEN "tipos_versao_custo" THEN textValue="~{~"resource~":~"tipos_versao_custo~",~"primaryKey~":~"tipo_versao_custo_id~",~"fields~":[~{~"name~":~"descricao~",~"type~":~"character~",~"maxLength~":100~}]~}".
 WHEN "motivos_desconto" THEN textValue="~{~"resource~":~"motivos_desconto~",~"primaryKey~":~"motivo_desconto_id~",~"fields~":[~{~"name~":~"descricao~",~"type~":~"character~",~"maxLength~":100~},~{~"name~":~"log_considerar_custo~",~"type~":~"integer~",~"binaryFlag~":true~}]~}".
 OTHERWISE UNDO,THROW NEW Progress.Lang.AppError("Recurso invalido",0).
END CASE.
parser=NEW ObjectModelParser().
poDefinition=CAST(parser:Parse(textValue),JsonObject).
DELETE OBJECT parser.

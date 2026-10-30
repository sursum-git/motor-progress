USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE helper AS DynamicQueryConsumerPagination NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE queryValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
helper=NEW DynamicQueryConsumerPagination(). parser=NEW ObjectModelParser().
RUN Check('~{~}',TRUE).
RUN Check('~{"paginationMode":"cursor","pageSize":5~}',TRUE).
RUN Check('~{"paginationMode":"cursor","cursor":""~}',TRUE).
RUN Check('~{"paginationMode":"cursor","page":1~}',FALSE).
RUN Check('~{"paginationMode":"cursor","paginate":false~}',FALSE).
RUN Check('~{"paginationMode":"cursor","cursor":null~}',FALSE).
RUN Check('~{"paginationMode":"cursor","cursor":"bad"~}',FALSE).
RUN Check('~{"paginationMode":"bad"~}',FALSE).
RUN Check('~{"cursor":""~}',FALSE).
RUN Check('~{"paginate":false~}',TRUE).
RUN Check('~{"paginate":true~}',TRUE).
RUN Check('~{"paginate":"false"~}',FALSE).
RUN Check('~{"paginate":0~}',FALSE).
RUN Check('~{"paginate":null~}',FALSE).
RUN Check('~{"page":2,"pageSize":1000~}',TRUE).
RUN Check('~{"page":1000000,"pageSize":1~}',TRUE).
RUN Check('~{"page":1.0,"pageSize":100.0~}',TRUE).
RUN Check('~{"page":0~}',FALSE).
RUN Check('~{"page":-1~}',FALSE).
RUN Check('~{"page":1000001~}',FALSE).
RUN Check('~{"page":1.5~}',FALSE).
RUN Check('~{"page":"2"~}',FALSE).
RUN Check('~{"page":null~}',FALSE).
RUN Check('~{"page":true~}',FALSE).
RUN Check('~{"page":[]~}',FALSE).
RUN Check('~{"pageSize":0~}',FALSE).
RUN Check('~{"pageSize":-1~}',FALSE).
RUN Check('~{"pageSize":1001~}',FALSE).
RUN Check('~{"pageSize":2.5~}',FALSE).
RUN Check('~{"pageSize":"100"~}',FALSE).
RUN Check('~{"pageSize":null~}',FALSE).
RUN Check('~{"pageSize":true~}',FALSE).
RUN Check('~{"pageSize":1e100~}',FALSE).
RUN Applied('~{~}','~{"page":2,"pageSize":100~}',2,100).
RUN Applied('~{~}','~{"pageSize":5000~}',1,1000).
RUN Applied('~{"page":3,"pageSize":5~}','~{"pageSize":100~}',3,5).
RUN Applied('~{"paginate":false,"page":3,"pageSize":5~}','~{"pageSize":100~}',1,5).
RUN Applied('~{~}','~{"pageSize":null,"page":null~}',1,50).
RUN Applied('~{"page":3,"pageSize":5~}','~{"pageSize":null~}',3,5).
queryValue=NEW JsonObject().
DEFINE VARIABLE pipelineValue AS JsonArray NO-UNDO.
DEFINE VARIABLE stepValue AS JsonObject NO-UNDO.
DEFINE VARIABLE serialized AS LONGCHAR NO-UNDO.
pipelineValue=NEW JsonArray(). stepValue=NEW JsonObject().
stepValue:Add('type','limit'). stepValue:Add('payload','~{"page":1,"pageSize":5000~}').
pipelineValue:Add(stepValue). queryValue:Add('pipeline',pipelineValue).
queryValue:Write(serialized).
RUN Applied('~{~}',STRING(serialized),1,1000).
RUN Applied('~{"page":2,"pageSize":5~}',STRING(serialized),2,5).
RUN DefinitionCheck('~{~}',TRUE).
RUN Check('~{"execution":"sync"~}',TRUE).
RUN Check('~{"execution":"async"~}',TRUE).
RUN Check('~{"execution":"auto"~}',FALSE).
RUN Check('~{"execution":null~}',FALSE).
RUN Check('~{"execution":"async","paginationMode":"cursor"~}',FALSE).
RUN DefinitionCheck('~{"pipeline":[]~}',TRUE).
RUN DefinitionCheck('~{"pipeline":[~{"type":"filter"~}]~}',TRUE).
RUN DefinitionCheck('~{"pipeline":[~{"type":"distinct"~}]~}',FALSE).
RUN DefinitionCheck('~{"pipeline":[~{"type":"group"~}]~}',FALSE).
RUN DefinitionCheck('~{"pipeline":[~{"type":"aggregate"~}]~}',FALSE).
RUN DefinitionCheck('~{"pipeline":"invalid"~}',FALSE).
OUTPUT TO 'pagination-tests.log'. PUT UNFORMATTED 'PASS ' checks ' pagination checks; NUMDBS=' NUM-DBS SKIP. OUTPUT CLOSE.
PROCEDURE DefinitionCheck:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expected AS LOGICAL NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 IF helper:isCursorDefinitionSupported(requestValue)<>expected THEN UNDO,THROW NEW Progress.Lang.AppError('cursor definition guard',0).
 checks=checks + 1. DELETE OBJECT requestValue.
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expected AS LOGICAL NO-UNDO.
 DEFINE VARIABLE actual AS LOGICAL NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 actual=helper:isValid(requestValue).
 IF actual<>expected THEN UNDO,THROW NEW Progress.Lang.AppError('pagination case ' + STRING(checks + 1),0).
 checks=checks + 1. DELETE OBJECT requestValue.
END PROCEDURE.

PROCEDURE Applied:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER definitionValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expectedPage AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER expectedSize AS INTEGER NO-UNDO.
 DEFINE VARIABLE serializerValue AS DynamicQueryRequestSerializer NO-UNDO.
 DEFINE VARIABLE modelValue AS DynamicQueryRequestModel NO-UNDO.
 DEFINE VARIABLE localQuery AS JsonObject NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 localQuery=CAST(parser:Parse(definitionValue),JsonObject).
 serializerValue=NEW DynamicQueryRequestSerializer(). modelValue=serializerValue:fromJsonObject(localQuery).
 resultValue=helper:applyPagination(requestValue,modelValue).
 IF VALID-OBJECT(resultValue) OR modelValue:getPage()<>expectedPage OR modelValue:getPageSize()<>expectedSize THEN UNDO,THROW NEW Progress.Lang.AppError('applied case ' + STRING(checks + 1),0).
 checks=checks + 1.
 DELETE OBJECT requestValue. DELETE OBJECT localQuery. DELETE OBJECT modelValue. DELETE OBJECT serializerValue.
END PROCEDURE.

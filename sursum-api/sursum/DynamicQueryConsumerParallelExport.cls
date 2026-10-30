USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.

/* Builds one private NDJSON gzip artifact without materializing all partitions in memory. */
CLASS DynamicQueryConsumerParallelExport:
 METHOD PRIVATE CHARACTER partPath(INPUT rootValue AS CHARACTER,INPUT jobIdValue AS CHARACTER,INPUT partitionIdValue AS INTEGER):
  RETURN rootValue + '/' + jobIdValue + '.part-' + STRING(partitionIdValue) + '.json'.
 END METHOD.
 METHOD PRIVATE CHARACTER resultPath(INPUT rootValue AS CHARACTER,INPUT jobIdValue AS CHARACTER):
  RETURN rootValue + '/' + jobIdValue + '.ndjson.gz'.
 END METHOD.
 METHOD PRIVATE CHARACTER digest(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE outputValue AS CHARACTER NO-UNDO.
  INPUT THROUGH VALUE('/usr/bin/sha256sum -- "' + pathValue + '"') NO-ECHO.
  IMPORT UNFORMATTED outputValue.
  INPUT CLOSE.
  RETURN LC(ENTRY(1,outputValue,' ')).
 END METHOD.
 METHOD PUBLIC JsonObject consolidate(INPUT rootValue AS CHARACTER,INPUT jobIdValue AS CHARACTER,INPUT partitionsValue AS INTEGER,INPUT maxBytesValue AS INT64,INPUT maxPartitionBytesValue AS INT64):
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE partValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE dataValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE rowText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE rawPath AS CHARACTER NO-UNDO.
  DEFINE VARIABLE gzipPath AS CHARACTER NO-UNDO.
  DEFINE VARIABLE temporaryPath AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE r AS INTEGER NO-UNDO.
  DEFINE VARIABLE recordCount AS INT64 NO-UNDO.
  DEFINE VARIABLE byteCount AS INT64 NO-UNDO.
  DEFINE VARIABLE completed AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF rootValue=? OR rootValue='' OR jobIdValue=? OR jobIdValue='' OR partitionsValue<1 OR maxBytesValue<maxPartitionBytesValue OR maxPartitionBytesValue<1048576 OR maxPartitionBytesValue>1073741824 THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_EXPORT_INVALID',0).
   rawPath=rootValue + '/' + jobIdValue + '.ndjson.tmp'. gzipPath=THIS-OBJECT:resultPath(rootValue,jobIdValue). temporaryPath=gzipPath + '.' + LC(HEX-ENCODE(GENERATE-UUID)) + '.tmp'.
   OS-DELETE VALUE(rawPath) VALUE(temporaryPath) NO-ERROR.
   /* Ensure an empty, valid range produces an empty NDJSON stream for gzip. */
   OUTPUT TO VALUE(rawPath) BINARY NO-ECHO.
   OUTPUT CLOSE.
   parserValue=NEW ObjectModelParser().
   DO n=1 TO partitionsValue:
    FILE-INFO:FILE-NAME=THIS-OBJECT:partPath(rootValue,jobIdValue,n).
    IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE>maxPartitionBytesValue THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_RESULT_UNAVAILABLE',0).
    partValue=CAST(parserValue:ParseFile(FILE-INFO:FULL-PATHNAME),JsonObject).
    IF NOT partValue:GetLogical('success') OR NOT partValue:Has('data') OR partValue:GetType('data')<>JsonDataType:ARRAY THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_RESULT_INVALID',0).
    dataValue=partValue:GetJsonArray('data').
    DO r=1 TO dataValue:Length:
     rowValue=dataValue:GetJsonObject(r). FIX-CODEPAGE(rowText)='UTF-8'. rowValue:Write(rowText,FALSE).
     byteCount=byteCount + LENGTH(rowText,'RAW') + 1.
     IF byteCount>maxBytesValue THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_RESULT_LIMIT',0).
     rowText=rowText + '~n'.
     COPY-LOB FROM rowText TO FILE rawPath APPEND NO-CONVERT.
     recordCount=recordCount + 1. rowText=''.
    END.
    DELETE OBJECT partValue. partValue=? . dataValue=? .
   END.
   OS-COMMAND SILENT VALUE('/usr/bin/gzip -c -- "' + rawPath + '" > "' + temporaryPath + '"').
   FILE-INFO:FILE-NAME=temporaryPath.
   IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE<1 OR FILE-INFO:FILE-SIZE>maxBytesValue THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_GZIP_FAILED',0).
   OS-RENAME VALUE(temporaryPath) VALUE(gzipPath).
   FILE-INFO:FILE-NAME=gzipPath.
   IF FILE-INFO:FULL-PATHNAME=? THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_GZIP_FAILED',0).
   resultValue=NEW JsonObject(). resultValue:Add('success',TRUE). resultValue:Add('resultPath',gzipPath). resultValue:Add('recordsReturned',recordCount).
   resultValue:Add('bytes',FILE-INFO:FILE-SIZE). resultValue:Add('sha256',THIS-OBJECT:digest(gzipPath)). resultValue:Add('format','ndjson+gzip').
   completed=TRUE. RETURN resultValue.
   FINALLY:
    IF NOT completed THEN OS-DELETE VALUE(temporaryPath) VALUE(gzipPath) NO-ERROR.
    OS-DELETE VALUE(rawPath) NO-ERROR.
    IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue. IF VALID-OBJECT(partValue) THEN DELETE OBJECT partValue.
   END FINALLY.
  END.
 END METHOD.
END CLASS.

@echo off
setlocal

set "REQUEST_FILE=%~1"
set "OUTPUT_FILE=%~2"

if "%REQUEST_FILE%"=="" (
  set "REQUEST_FILE=%~dp0customer-pipeline-advanced-request.json"
)

if "%OUTPUT_FILE%"=="" (
  set "OUTPUT_FILE=%~dp0..\output\extracts\customer-pipeline-advanced-result.json"
)

"C:\Progress\OpenEdge\bin\_progres.exe" -b ^
  -db "D:\opencode\motor-progress\db\sports2000" -1 -ld DICTDB ^
  -p "D:\opencode\motor-progress\runners\RunDynamicQueryFromJson.p" ^
  -param "request=%REQUEST_FILE%;output=%OUTPUT_FILE%"

if errorlevel 1 (
  echo Erro ao executar extracao.
  exit /b 1
)

echo Resultado salvo em:
echo %OUTPUT_FILE%

endlocal

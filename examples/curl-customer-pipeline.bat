@echo off
setlocal

set "PASOE_URL=http://localhost:8890/web/SursumDynamicQuery/query"
set "REQUEST_FILE=%~dp0customer-pipeline-request.json"
set "OUT_DIR=%~dp0responses"
set "OUT_FILE=%OUT_DIR%\customer-pipeline-response.json"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

curl -sS -X POST "%PASOE_URL%" ^
  -H "Content-Type: application/json" ^
  -o "%OUT_FILE%" ^
  --data-binary "@%REQUEST_FILE%"

if errorlevel 1 (
  echo Erro ao chamar a API PASOE.
  exit /b 1
)

echo Resposta salva em:
echo %OUT_FILE%

endlocal

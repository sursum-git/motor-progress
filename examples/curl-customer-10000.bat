@echo off
setlocal EnableDelayedExpansion

set "PASOE_URL=http://localhost:8890/web/SursumDynamicQuery/query"
set "OUT_DIR=%~dp0responses"
set "TMP_DIR=%OUT_DIR%\customer-10000-pages"
set "OUT_FILE=%OUT_DIR%\customer-10000.json"
set "PAGE_SIZE=500"
set "TOTAL_PAGES=20"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

del /q "%TMP_DIR%\page-*.json" >nul 2>nul
del /q "%OUT_FILE%" >nul 2>nul

echo Consultando Customer em %TOTAL_PAGES% paginas de %PAGE_SIZE% registros...

for /L %%P in (1,1,%TOTAL_PAGES%) do (
  set "PAGE=%%P"
  set "PAGE_FILE=%TMP_DIR%\page-!PAGE!.json"

  echo Pagina !PAGE!...

  curl -sS -X POST "%PASOE_URL%" ^
    -H "Content-Type: application/json" ^
    -o "!PAGE_FILE!" ^
    --data-binary "{\"execution\":\"sync\",\"sources\":[{\"nome\":\"Customer\",\"alias\":\"customer\",\"campos\":\"CustNum,Name\"}],\"select\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"outputAlias\":\"codigo\"},{\"sourceAlias\":\"customer\",\"field\":\"Name\",\"outputAlias\":\"nome\"}],\"orderBy\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"direction\":\"ASC\"}],\"page\":!PAGE!,\"pageSize\":%PAGE_SIZE%}"

  if errorlevel 1 (
    echo Erro ao chamar a API PASOE na pagina !PAGE!.
    exit /b 1
  )
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $files=Get-ChildItem -LiteralPath '%TMP_DIR%' -Filter 'page-*.json' | Sort-Object {[int]($_.BaseName -replace 'page-','')}; $data=@(); foreach($file in $files){ $json=Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json; if(-not $json.success){ throw ('API retornou erro em ' + $file.Name + ': ' + $json.error.code + ' - ' + $json.error.message) }; $data += @($json.data) }; $out=[ordered]@{ success=$true; execution='sync-paginated'; pageSize=[int]'%PAGE_SIZE%'; pages=[int]'%TOTAL_PAGES%'; recordsReturned=$data.Count; hasMore=$true; data=$data }; $out | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath '%OUT_FILE%' -Encoding UTF8"

if errorlevel 1 (
  echo Erro ao consolidar o JSON final.
  exit /b 1
)

echo Resposta consolidada salva em:
echo %OUT_FILE%

endlocal

@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0curl-customer-10000-keyrange.ps1"

if errorlevel 1 (
  echo Erro ao executar consulta por faixa de chave.
  exit /b 1
)

endlocal

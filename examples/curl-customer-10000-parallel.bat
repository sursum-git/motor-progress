@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0curl-customer-10000-parallel.ps1"

if errorlevel 1 (
  echo Erro ao executar consulta paralela.
  exit /b 1
)

endlocal

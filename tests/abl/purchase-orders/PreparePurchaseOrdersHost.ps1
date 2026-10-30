# PRIVATE TT host generation. Run only inside isolated compile/test staging.
# Never publish this file or ContainersItensRuntimeHost.p/.r.
$ErrorActionPreference='Stop'
$source=Get-Content -LiteralPath './ContainersItensRuntime.p' -Raw -Encoding UTF8
$pattern='(?s)PROCEDURE NextLedgerId:.*?END PROCEDURE\.'
if(([regex]::Matches($source,$pattern)).Count -ne 1){throw 'Exactly one sequence method required'}
$replacement=@'
PROCEDURE NextLedgerId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 RUN NextLedgerId IN phBaseRuntime(OUTPUT valueId).
END PROCEDURE.
'@
$hostSource=[regex]::Replace($source,$pattern,$replacement)
$hostPath=Join-Path (Get-Location).Path 'ContainersItensRuntimeHost.p'
$hostText='/* PRIVATE TT HOST: only ledger sequence callback substituted. */'+[Environment]::NewLine+$hostSource
[IO.File]::WriteAllText($hostPath,$hostText,(New-Object Text.UTF8Encoding($false)))
if(-not (Test-Path -LiteralPath $hostPath -PathType Leaf)){throw 'Private host was not written in staging'}
$hostBytes=[IO.File]::ReadAllBytes($hostPath)
if($hostBytes.Length -lt 2 -or $hostBytes[0] -ne 47 -or $hostBytes[1] -ne 42){throw 'Private host must start with /* without BOM'}

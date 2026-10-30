# PRIVATE TT staging only. Never publish generated hosts or fixtures.
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot '../purchase-orders/PreparePurchaseOrdersHost.ps1')
$hostPath=Join-Path (Get-Location).Path 'ContainersItensRuntimeHost.p'
$hostText=[IO.File]::ReadAllText($hostPath)
$identityCall="valueId=DYNAMIC-NEXT-VALUE('seq_itens_proc_compra','espec')."
if(($hostText.Split([string[]]@($identityCall),[StringSplitOptions]::None).Count-1) -ne 1){throw 'Exactly one private purchase item identity substitution required'}
$hostText=$hostText.Replace($identityCall,'RUN NextPurchaseItemId IN phBaseRuntime(OUTPUT valueId).')
[IO.File]::WriteAllText($hostPath,$hostText,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path (Get-Location).Path 'PurchaseItemsRuntimeHost.p'),$hostText,[Text.UTF8Encoding]::new($false))

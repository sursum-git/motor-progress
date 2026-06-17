$ErrorActionPreference = "Stop"

$pasoeUrl = "http://localhost:8890/web/SursumDynamicQuery/query"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $scriptDir "responses"
$tmpDir = Join-Path $outDir "customer-10000-parallel-pages"
$outFile = Join-Path $outDir "customer-10000-parallel.json"
$pageSize = 500
$totalPages = 20
$maxParallel = 2

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

Get-ChildItem -LiteralPath $tmpDir -Filter "page-*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $tmpDir -Filter "page-*.request.json" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue

Write-Host "Consultando Customer em $totalPages paginas de $pageSize registros, com ate $maxParallel curls paralelos..."

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = @()

for ($page = 1; $page -le $totalPages; $page++) {
    while (@($jobs | Where-Object { $_.State -eq "Running" }).Count -ge $maxParallel) {
        Start-Sleep -Milliseconds 50
        $jobs = @($jobs | Where-Object { $_.State -eq "Running" -or $_.State -eq "NotStarted" })
    }

    $pageFile = Join-Path $tmpDir ("page-" + $page + ".json")
    $bodyFile = Join-Path $tmpDir ("page-" + $page + ".request.json")

    $payload = @{
        execution = "sync"
        sources = @(
            @{
                nome = "Customer"
                alias = "customer"
                campos = "CustNum,Name"
            }
        )
        select = @(
            @{
                sourceAlias = "customer"
                field = "CustNum"
                outputAlias = "codigo"
            },
            @{
                sourceAlias = "customer"
                field = "Name"
                outputAlias = "nome"
            }
        )
        orderBy = @(
            @{
                sourceAlias = "customer"
                field = "CustNum"
                direction = "ASC"
            }
        )
        page = $page
        pageSize = $pageSize
    } | ConvertTo-Json -Depth 10 -Compress

    Set-Content -LiteralPath $bodyFile -Value $payload -Encoding ASCII -NoNewline

    $jobs += Start-Job -ScriptBlock {
        param($url, $bodyFile, $file)

        $bodyArg = "@" + $bodyFile
        curl.exe -sS -X POST $url -H "Content-Type: application/json" -o $file --data-binary $bodyArg

        if ($LASTEXITCODE -ne 0) {
            throw "curl falhou com exit code $LASTEXITCODE"
        }
    } -ArgumentList $pasoeUrl, $bodyFile, $pageFile
}

Wait-Job -Job $jobs | Out-Null

$failed = @($jobs | Where-Object { $_.State -ne "Completed" })
if ($failed.Count -gt 0) {
    Receive-Job -Job $failed -ErrorAction SilentlyContinue
    throw "$($failed.Count) jobs curl falharam"
}

$data = @()

for ($page = 1; $page -le $totalPages; $page++) {
    $file = Join-Path $tmpDir ("page-" + $page + ".json")
    $json = Get-Content -Raw -LiteralPath $file | ConvertFrom-Json

    if (-not $json.success) {
        throw "API retornou erro na pagina $page`: $($json.error.code) - $($json.error.message)"
    }

    $data += @($json.data)
}

$sw.Stop()

$out = [ordered]@{
    success = $true
    execution = "sync-parallel-curl"
    maxParallel = $maxParallel
    elapsedMilliseconds = $sw.ElapsedMilliseconds
    elapsedSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
    pageSize = $pageSize
    pages = $totalPages
    recordsReturned = $data.Count
    hasMore = $true
    data = $data
}

$out | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $outFile -Encoding UTF8

Write-Host "Tempo total: $($sw.ElapsedMilliseconds) ms"
Write-Host "Registros: $($data.Count)"
Write-Host "Resposta consolidada salva em:"
Write-Host $outFile

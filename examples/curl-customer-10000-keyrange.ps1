$ErrorActionPreference = "Stop"

$pasoeUrl = "http://localhost:8890/web/SursumDynamicQuery/query"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $scriptDir "responses"
$tmpDir = Join-Path $outDir "customer-10000-keyrange-pages"
$outFile = Join-Path $outDir "customer-10000-keyrange.json"
$pageSize = 500
$targetRecords = 10000
$rangeSize = 500
$totalRanges = 20
$maxParallel = 4

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

Get-ChildItem -LiteralPath $tmpDir -Filter "range-*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $tmpDir -Filter "range-*.request.json" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue

Write-Host "Consultando Customer por faixas de CustNum: $totalRanges ranges de $rangeSize, ate $maxParallel curls paralelos..."

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = @()

for ($range = 1; $range -le $totalRanges; $range++) {
    while (@($jobs | Where-Object { $_.State -eq "Running" }).Count -ge $maxParallel) {
        Start-Sleep -Milliseconds 25
        $jobs = @($jobs | Where-Object { $_.State -eq "Running" -or $_.State -eq "NotStarted" })
    }

    $fromCustNum = (($range - 1) * $rangeSize) + 1
    $toCustNum = $range * $rangeSize
    $rangeFile = Join-Path $tmpDir ("range-" + $range + ".json")
    $bodyFile = Join-Path $tmpDir ("range-" + $range + ".request.json")

    $payload = '{' +
        '"execution":"sync",' +
        '"sources":[{"nome":"Customer","alias":"customer","campos":"CustNum,Name"}],' +
        '"select":[' +
            '{"sourceAlias":"customer","field":"CustNum","outputAlias":"codigo"},' +
            '{"sourceAlias":"customer","field":"Name","outputAlias":"nome"}' +
        '],' +
        '"filters":[' +
            '{"sourceAlias":"customer","field":"CustNum","operator":">=","value":"' + $fromCustNum + '"},' +
            '{"sourceAlias":"customer","field":"CustNum","operator":"<=","value":"' + $toCustNum + '"}' +
        '],' +
        '"orderBy":[{"sourceAlias":"customer","field":"CustNum","direction":"ASC"}],' +
        '"page":1,' +
        '"pageSize":' + $pageSize +
    '}'

    Set-Content -LiteralPath $bodyFile -Value $payload -Encoding ASCII -NoNewline

    $jobs += Start-Job -ScriptBlock {
        param($url, $bodyFile, $file)

        $bodyArg = "@" + $bodyFile
        curl.exe -sS -X POST $url -H "Content-Type: application/json" -o $file --data-binary $bodyArg

        if ($LASTEXITCODE -ne 0) {
            throw "curl falhou com exit code $LASTEXITCODE"
        }
    } -ArgumentList $pasoeUrl, $bodyFile, $rangeFile
}

Wait-Job -Job $jobs | Out-Null

$failed = @($jobs | Where-Object { $_.State -ne "Completed" })
if ($failed.Count -gt 0) {
    Receive-Job -Job $failed -ErrorAction SilentlyContinue
    throw "$($failed.Count) jobs curl falharam"
}

$data = @()

for ($range = 1; $range -le $totalRanges; $range++) {
    $file = Join-Path $tmpDir ("range-" + $range + ".json")
    $json = Get-Content -Raw -LiteralPath $file | ConvertFrom-Json

    if (-not $json.success) {
        throw "API retornou erro no range $range`: $($json.error.code) - $($json.error.message)"
    }

    $data += @($json.data)
}

$data = @($data | Sort-Object {[int]$_.codigo} | Select-Object -First $targetRecords)
$sw.Stop()

$out = [ordered]@{
    success = $true
    execution = "sync-parallel-keyrange"
    partitionField = "CustNum"
    maxParallel = $maxParallel
    rangeSize = $rangeSize
    ranges = $totalRanges
    elapsedMilliseconds = $sw.ElapsedMilliseconds
    elapsedSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
    recordsReturned = $data.Count
    data = $data
}

$out | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $outFile -Encoding UTF8

Write-Host "Tempo total: $($sw.ElapsedMilliseconds) ms"
Write-Host "Registros: $($data.Count)"
Write-Host "Resposta consolidada salva em:"
Write-Host $outFile

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "game"
$godotExe = Get-Command Godot_v4.6.3-stable_win64.exe -ErrorAction SilentlyContinue

if ($null -eq $godotExe) {
    $fallback = "C:\Users\renar\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
    if (-not (Test-Path $fallback)) {
        throw "Godot 4.6 executable not found."
    }
    $godotPath = $fallback
} else {
    $godotPath = $godotExe.Source
}

$reportDir = Join-Path $repoRoot "builds\qa\vertical_slice"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$logPath = Join-Path $reportDir "vertical_slice_contract.log"
if (Test-Path -LiteralPath $logPath) {
    Remove-Item -LiteralPath $logPath -Force
}

$output = & $godotPath --headless --path $projectPath --script res://tests/vertical_slice_contract.gd --log-file $logPath 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }

$logText = ""
for ($attempt = 0; $attempt -lt 120; $attempt++) {
    if (Test-Path -LiteralPath $logPath) {
        $logText = Get-Content -LiteralPath $logPath -Raw
        if ($logText -match "KENOSIS_VERTICAL_SLICE_CONTRACT_OK|Vertical slice contract failed|SCRIPT ERROR|Parser Error") {
            break
        }
    }
    Start-Sleep -Milliseconds 100
}

if (-not [string]::IsNullOrWhiteSpace($logText)) {
    Write-Output $logText
}

$combined = ($output -join "`n") + "`n" + $logText
if ($combined -match "SCRIPT ERROR|Parser Error|Vertical slice contract failed") {
    throw "Kenosis vertical slice contract failed."
}

if ($combined -notmatch "KENOSIS_VERTICAL_SLICE_CONTRACT_OK") {
    throw "Kenosis vertical slice contract did not emit its success marker."
}

exit $exitCode

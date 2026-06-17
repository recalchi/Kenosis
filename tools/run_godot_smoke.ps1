$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "game"
$godotExe = Get-Command Godot_v4.6.3-stable_win64.exe -ErrorAction SilentlyContinue

if ($null -eq $godotExe) {
    $fallback = "C:\Users\renar\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
    if (Test-Path $fallback) {
        $godotPath = $fallback
    } else {
        throw "Godot 4.6 executable not found in PATH or fallback path."
    }
} else {
    $godotPath = $godotExe.Source
}

$startedAt = Get-Date
$godotOutput = & $godotPath --headless --path $projectPath --script res://tests/smoke_test.gd 2>&1
$exitCode = $LASTEXITCODE

$godotOutput | ForEach-Object { Write-Output $_ }

$logRoot = Join-Path $env:APPDATA "Godot\app_userdata\Kenosis\logs"
$activeLogPath = Join-Path $logRoot "godot.log"
$logText = ""
for ($attempt = 0; $attempt -lt 120; $attempt++) {
    if (Test-Path -LiteralPath $activeLogPath) {
        $logFile = Get-Item -LiteralPath $activeLogPath
        if ($logFile.LastWriteTime -ge $startedAt.AddSeconds(-1)) {
            $logText = Get-Content -LiteralPath $activeLogPath -Raw
            if ($logText -match "KENOSIS_SMOKE_OK|SCRIPT ERROR|ERROR:") {
                break
            }
        }
    }
    Start-Sleep -Milliseconds 250
}

if (-not [string]::IsNullOrWhiteSpace($logText)) {
    Write-Output $logText
}

$combinedOutput = ($godotOutput -join "`n") + "`n" + $logText
if ($combinedOutput -match "SCRIPT ERROR|ERROR:") {
    throw "Godot smoke test reported errors."
}

if ($combinedOutput -notmatch "KENOSIS_SMOKE_OK") {
    throw "Godot smoke test did not emit its success marker."
}

exit 0

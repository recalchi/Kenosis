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

$startedAt = Get-Date
$output = & $godotPath --headless --path $projectPath --script res://tests/auto_qa_contract_test.gd 2>&1
$output | ForEach-Object { Write-Output $_ }

$logPath = Join-Path $env:APPDATA "Godot\app_userdata\Kenosis\logs\godot.log"
$logText = ""
for ($attempt = 0; $attempt -lt 80; $attempt++) {
    if (Test-Path -LiteralPath $logPath) {
        $logFile = Get-Item -LiteralPath $logPath
        if ($logFile.LastWriteTime -ge $startedAt.AddSeconds(-1)) {
            $logText = Get-Content -LiteralPath $logPath -Raw
            if ($logText -match "KENOSIS_AUTO_QA_CONTRACT_OK|SCRIPT ERROR|ERROR:") {
                break
            }
        }
    }
    Start-Sleep -Milliseconds 100
}

$combined = ($output -join "`n") + "`n" + $logText
if ($combined -match "SCRIPT ERROR|ERROR:") {
    throw "Kenosis Auto QA contract reported errors."
}
if ($combined -notmatch "KENOSIS_AUTO_QA_CONTRACT_OK") {
    throw "Kenosis Auto QA contract did not emit its success marker."
}

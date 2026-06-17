$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "game"
$godotExe = Get-Command Godot_v4.6.3-stable_win64.exe -ErrorAction SilentlyContinue
$godotPath = if ($null -ne $godotExe) {
    $godotExe.Source
} else {
    "C:\Users\renar\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
}

$startedAt = Get-Date
$output = & $godotPath --headless --path $projectPath --script res://tests/expansion_test.gd 2>&1
$output | ForEach-Object { Write-Output $_ }

$logRoot = Join-Path $env:APPDATA "Godot\app_userdata\Kenosis\logs"
$activeLogPath = Join-Path $logRoot "godot.log"
$logText = ""
for ($attempt = 0; $attempt -lt 120; $attempt++) {
    if (Test-Path -LiteralPath $activeLogPath) {
        $logFile = Get-Item -LiteralPath $activeLogPath
        if ($logFile.LastWriteTime -ge $startedAt.AddSeconds(-1)) {
            $logText = Get-Content -LiteralPath $activeLogPath -Raw
            if ($logText -match "KENOSIS_EXPANSION_OK|SCRIPT ERROR|ERROR:") {
                break
            }
        }
    }
    Start-Sleep -Milliseconds 250
}

if (-not [string]::IsNullOrWhiteSpace($logText)) {
    Write-Output $logText
}

$combinedOutput = ($output -join "`n") + "`n" + $logText
if ($combinedOutput -match "SCRIPT ERROR|ERROR:") {
    throw "Kenosis expansion test reported errors."
}
if ($combinedOutput -notmatch "KENOSIS_EXPANSION_OK") {
    throw "Kenosis expansion test did not emit its success marker."
}

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
$arguments = @("--headless", "--path", $projectPath, "--script", "res://tests/story_regions_test.gd")
$process = Start-Process -FilePath $godotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait

$logPath = Join-Path $env:APPDATA "Godot\app_userdata\Kenosis\logs\godot.log"
$logText = ""
for ($attempt = 0; $attempt -lt 80; $attempt++) {
    if (Test-Path -LiteralPath $logPath) {
        $logFile = Get-Item -LiteralPath $logPath
        if ($logFile.LastWriteTime -ge $startedAt.AddSeconds(-1)) {
            $logText = Get-Content -LiteralPath $logPath -Raw
            if ($logText -match "KENOSIS_STORY_REGIONS_OK|SCRIPT ERROR|ERROR:") {
                break
            }
        }
    }
    Start-Sleep -Milliseconds 250
}
Write-Output $logText

if ($logText -match "SCRIPT ERROR|ERROR:") {
    throw "Kenosis story regions test reported errors."
}
if ($logText -notmatch "KENOSIS_STORY_REGIONS_OK") {
    throw "Kenosis story regions test did not emit its success marker."
}

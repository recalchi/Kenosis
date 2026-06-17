param([switch]$Visible)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "game"
$reportDir = Join-Path $repoRoot "builds\qa\mapbot"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$logPath = Join-Path $reportDir "map_auto_qa_latest.log"
$reportPath = Join-Path $reportDir "latest_report.json"
$godotExe = Get-Command Godot_v4.6.3-stable_win64.exe -ErrorAction SilentlyContinue
$godotPath = if ($null -eq $godotExe) { "C:\Users\renar\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe" } else { $godotExe.Source }
if (-not (Test-Path $godotPath)) { throw "Godot 4.6 executable not found." }

$startedAt = Get-Date
$arguments = @("--path", $projectPath, "--script", "res://tests/map_auto_qa_runner.gd", "--log-file", $logPath)
if (-not $Visible) { $arguments = @("--headless") + $arguments }
$process = Start-Process -FilePath $godotPath -ArgumentList $arguments -WindowStyle ($(if ($Visible) { "Normal" } else { "Hidden" })) -PassThru
if (-not $process.WaitForExit(90000)) {
    Stop-Process -Id $process.Id -Force
    throw "Map Auto QA timed out."
}
if (-not (Test-Path $reportPath) -or (Get-Item $reportPath).LastWriteTime -lt $startedAt.AddSeconds(-1)) {
    throw "Map Auto QA did not generate a fresh report."
}
$logText = Get-Content -LiteralPath $logPath -Raw
if ($logText -match "SCRIPT ERROR|ERROR:|Parser Error|WARNING:") {
    Write-Output $logText
    throw "Map Auto QA log contains errors or warnings."
}
$reportText = Get-Content -LiteralPath $reportPath -Raw
$report = $reportText | ConvertFrom-Json
$reportText
if (-not [bool]$report.passed) { throw "Map Auto QA failed." }

param([switch]$Visible)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "game"
$reportDir = Join-Path $repoRoot "builds\qa\visualbot"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$logPath = Join-Path $reportDir "visual_auto_qa_latest.log"
$reportPath = Join-Path $reportDir "latest_report.json"
$godotExe = Get-Command Godot_v4.6.3-stable_win64.exe -ErrorAction SilentlyContinue
$godotPath = if ($null -eq $godotExe) { "C:\Users\renar\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe" } else { $godotExe.Source }
if (-not (Test-Path $godotPath)) { throw "Godot 4.6 executable not found." }

$startedAt = Get-Date
$arguments = @("--path", $projectPath, "--script", "res://tests/visual_auto_qa_runner.gd", "--log-file", $logPath)
$windowStyle = if ($Visible) { "Normal" } else { "Hidden" }
$process = Start-Process -FilePath $godotPath -ArgumentList $arguments -WindowStyle $windowStyle -PassThru
if (-not $process.WaitForExit(120000)) {
    Stop-Process -Id $process.Id -Force
    throw "Visual Auto QA timed out."
}
if (-not (Test-Path $reportPath) -or (Get-Item $reportPath).LastWriteTime -lt $startedAt.AddSeconds(-1)) {
    throw "Visual Auto QA did not generate a fresh report."
}
$logText = Get-Content -LiteralPath $logPath -Raw
if ($logText -match "SCRIPT ERROR|ERROR:|Parser Error|WARNING:") {
    Write-Output $logText
    throw "Visual Auto QA log contains errors or warnings."
}
$reportText = Get-Content -LiteralPath $reportPath -Raw
$report = $reportText | ConvertFrom-Json
$reportText
if (-not [bool]$report.passed) { throw "Visual Auto QA failed." }

param(
    [ValidateRange(0, 1000)]
    [int]$Cycles = 3,
    [switch]$Visible
)

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

$previousCycles = $env:KENOSIS_QA_CYCLES
$env:KENOSIS_QA_CYCLES = [string]$Cycles
$startedAt = Get-Date
try {
    $reportDir = Join-Path $repoRoot "builds\qa\autobot"
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
    $logPath = Join-Path $reportDir "auto_qa_latest.log"
    $arguments = @("--path", $projectPath, "--script", "res://tests/auto_qa_runner.gd")
    if (-not $Visible) {
        $arguments = @("--headless") + $arguments
    }
    $arguments += @("--log-file", $logPath)
    $windowStyle = if ($Visible) { "Normal" } else { "Hidden" }
    $process = Start-Process -FilePath $godotPath -ArgumentList $arguments -WindowStyle $windowStyle -PassThru
    $timeoutMilliseconds = [Math]::Max(60000, [Math]::Max(1, $Cycles) * 30000)
    if (-not $process.WaitForExit($timeoutMilliseconds)) {
        Stop-Process -Id $process.Id -Force
        throw "Kenosis Auto QA timed out after $timeoutMilliseconds ms."
    }
} finally {
    $env:KENOSIS_QA_CYCLES = $previousCycles
}

$reportPath = Join-Path $repoRoot "builds\qa\autobot\latest_report.json"
for ($attempt = 0; $attempt -lt 1800; $attempt++) {
    if (Test-Path -LiteralPath $reportPath) {
        $reportFile = Get-Item -LiteralPath $reportPath
        if ($reportFile.LastWriteTime -ge $startedAt.AddSeconds(-1)) {
            break
        }
    }
    Start-Sleep -Milliseconds 100
}

if (-not (Test-Path -LiteralPath $reportPath)) {
    throw "Kenosis Auto QA did not generate its report."
}
$reportFile = Get-Item -LiteralPath $reportPath
if ($reportFile.LastWriteTime -lt $startedAt.AddSeconds(-1)) {
    throw "Kenosis Auto QA timed out before generating a fresh report."
}
$logText = Get-Content -LiteralPath $logPath -Raw
if ($logText -match "SCRIPT ERROR|ERROR:|Parser Error|WARNING:") {
    Write-Output $logText
    throw "Kenosis Auto QA log contains errors or warnings."
}

$reportText = Get-Content -LiteralPath $reportPath -Raw
$report = $reportText | ConvertFrom-Json
$reportText
if ([int]$report.summary.failed_cycles -gt 0) {
    throw "Kenosis Auto QA found one or more failed cycles."
}

param()

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputRoot = Join-Path $repoRoot "game\assets\sprites\interactables"
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

function New-Bitmap {
    param([int]$Width, [int]$Height)
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Save-Bitmap {
    param([System.Drawing.Bitmap]$Bitmap, [string]$Name)
    $path = Join-Path $outputRoot $Name
    $Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bitmap.Dispose()
    Write-Output $path
}

function Fill-Rect {
    param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [System.Drawing.Color]$Color)
    $brush = [System.Drawing.SolidBrush]::new($Color)
    $Graphics.FillRectangle($brush, $X, $Y, $W, $H)
    $brush.Dispose()
}

function Draw-Rect {
    param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [System.Drawing.Color]$Color, [int]$Width = 2)
    $pen = [System.Drawing.Pen]::new($Color, $Width)
    $Graphics.DrawRectangle($pen, $X, $Y, $W, $H)
    $pen.Dispose()
}

function Draw-Ellipse {
    param($Graphics, [int]$X, [int]$Y, [int]$W, [int]$H, [System.Drawing.Color]$Color)
    $brush = [System.Drawing.SolidBrush]::new($Color)
    $Graphics.FillEllipse($brush, $X, $Y, $W, $H)
    $brush.Dispose()
}

$source = New-Bitmap 64 96
$g = [System.Drawing.Graphics]::FromImage($source)
$g.Clear([System.Drawing.Color]::Transparent)
Fill-Rect $g 27 20 10 58 ([System.Drawing.Color]::FromArgb(255, 55, 105, 118))
Draw-Ellipse $g 12 8 40 40 ([System.Drawing.Color]::FromArgb(255, 72, 212, 235))
Draw-Ellipse $g 22 18 20 20 ([System.Drawing.Color]::FromArgb(255, 215, 250, 255))
Fill-Rect $g 18 76 28 10 ([System.Drawing.Color]::FromArgb(255, 43, 73, 79))
$g.Dispose()
Save-Bitmap $source "exorigem_source.png" | Out-Null

$receiver = New-Bitmap 70 106
$g = [System.Drawing.Graphics]::FromImage($receiver)
$g.Clear([System.Drawing.Color]::Transparent)
Fill-Rect $g 18 18 34 72 ([System.Drawing.Color]::FromArgb(255, 42, 48, 64))
Draw-Rect $g 18 18 34 72 ([System.Drawing.Color]::FromArgb(255, 120, 220, 245)) 3
Draw-Ellipse $g 25 40 20 20 ([System.Drawing.Color]::FromArgb(255, 180, 245, 255))
Fill-Rect $g 10 90 50 8 ([System.Drawing.Color]::FromArgb(255, 29, 34, 45))
$g.Dispose()
Save-Bitmap $receiver "resonance_receiver.png" | Out-Null

$gate = New-Bitmap 64 150
$g = [System.Drawing.Graphics]::FromImage($gate)
$g.Clear([System.Drawing.Color]::Transparent)
Fill-Rect $g 12 8 40 132 ([System.Drawing.Color]::FromArgb(255, 70, 27, 39))
Draw-Rect $g 12 8 40 132 ([System.Drawing.Color]::FromArgb(255, 160, 70, 82)) 3
Fill-Rect $g 24 18 16 112 ([System.Drawing.Color]::FromArgb(255, 35, 18, 27))
$g.Dispose()
Save-Bitmap $gate "resonance_gate.png" | Out-Null

$hazard = New-Bitmap 96 42
$g = [System.Drawing.Graphics]::FromImage($hazard)
$g.Clear([System.Drawing.Color]::Transparent)
Fill-Rect $g 4 22 88 12 ([System.Drawing.Color]::FromArgb(255, 180, 22, 45))
for ($i = 0; $i -lt 6; $i++) {
    $x = 8 + ($i * 14)
    Fill-Rect $g $x 10 8 22 ([System.Drawing.Color]::FromArgb(255, 220, 34, 60))
}
$g.Dispose()
Save-Bitmap $hazard "failure_hazard.png" | Out-Null

$completion = New-Bitmap 86 120
$g = [System.Drawing.Graphics]::FromImage($completion)
$g.Clear([System.Drawing.Color]::Transparent)
Fill-Rect $g 32 18 22 82 ([System.Drawing.Color]::FromArgb(180, 35, 120, 78))
Draw-Rect $g 18 8 50 100 ([System.Drawing.Color]::FromArgb(255, 76, 210, 132)) 4
Draw-Ellipse $g 26 30 34 34 ([System.Drawing.Color]::FromArgb(120, 160, 255, 200))
$g.Dispose()
Save-Bitmap $completion "completion_exit.png" | Out-Null

Write-Output "Generated gameplay placeholder sprites in $outputRoot"

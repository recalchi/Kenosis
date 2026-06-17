$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = "C:\Users\renar\Downloads\Kenosis_Agent_Docs_StarterKit\Asseds"
$gameAssets = Join-Path $repoRoot "game\assets"

function Ensure-Directory {
    param([string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Copy-Region {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Rectangle]$Rect
    )
    $output = [System.Drawing.Bitmap]::new($Rect.Width, $Rect.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    $graphics.DrawImage(
        $Source,
        [System.Drawing.Rectangle]::new(0, 0, $Rect.Width, $Rect.Height),
        $Rect,
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $graphics.Dispose()
    return $output
}

function Get-Alpha-Bounds {
    param([System.Drawing.Bitmap]$Image)
    $minX = $Image.Width
    $minY = $Image.Height
    $maxX = -1
    $maxY = -1
    for ($y = 0; $y -lt $Image.Height; $y++) {
        for ($x = 0; $x -lt $Image.Width; $x++) {
            if ($Image.GetPixel($x, $y).A -gt 12) {
                $minX = [Math]::Min($minX, $x)
                $minY = [Math]::Min($minY, $y)
                $maxX = [Math]::Max($maxX, $x)
                $maxY = [Math]::Max($maxY, $y)
            }
        }
    }
    if ($maxX -lt 0) {
        return [System.Drawing.Rectangle]::new(0, 0, $Image.Width, $Image.Height)
    }
    return [System.Drawing.Rectangle]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
}

function Keep-Largest-Alpha-Component {
    param([System.Drawing.Bitmap]$Image)
    $width = $Image.Width
    $height = $Image.Height
    $visited = New-Object 'bool[,]' $width, $height
    $largest = New-Object System.Collections.Generic.List[System.Drawing.Point]

    for ($startY = 0; $startY -lt $height; $startY++) {
        for ($startX = 0; $startX -lt $width; $startX++) {
            if ($visited[$startX, $startY] -or $Image.GetPixel($startX, $startY).A -le 12) {
                continue
            }
            $component = New-Object System.Collections.Generic.List[System.Drawing.Point]
            $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
            $queue.Enqueue([System.Drawing.Point]::new($startX, $startY))
            $visited[$startX, $startY] = $true
            while ($queue.Count -gt 0) {
                $point = $queue.Dequeue()
                $component.Add($point)
                foreach ($neighbor in @(
                    [System.Drawing.Point]::new($point.X - 1, $point.Y),
                    [System.Drawing.Point]::new($point.X + 1, $point.Y),
                    [System.Drawing.Point]::new($point.X, $point.Y - 1),
                    [System.Drawing.Point]::new($point.X, $point.Y + 1)
                )) {
                    if ($neighbor.X -lt 0 -or $neighbor.X -ge $width -or $neighbor.Y -lt 0 -or $neighbor.Y -ge $height) {
                        continue
                    }
                    if ($visited[$neighbor.X, $neighbor.Y] -or $Image.GetPixel($neighbor.X, $neighbor.Y).A -le 12) {
                        continue
                    }
                    $visited[$neighbor.X, $neighbor.Y] = $true
                    $queue.Enqueue($neighbor)
                }
            }
            if ($component.Count -gt $largest.Count) {
                $largest = $component
            }
        }
    }

    $keep = New-Object 'bool[,]' $width, $height
    foreach ($point in $largest) {
        $keep[$point.X, $point.Y] = $true
    }
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            if (-not $keep[$x, $y]) {
                $Image.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }
}

function Remove-Edge-Background {
    param(
        [System.Drawing.Bitmap]$Image,
        [ValidateSet("light", "dark")] [string]$Mode
    )
    $width = $Image.Width
    $height = $Image.Height
    $visited = New-Object 'bool[,]' $width, $height
    $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
    for ($x = 0; $x -lt $width; $x++) {
        $queue.Enqueue([System.Drawing.Point]::new($x, 0))
        $queue.Enqueue([System.Drawing.Point]::new($x, $height - 1))
    }
    for ($y = 0; $y -lt $height; $y++) {
        $queue.Enqueue([System.Drawing.Point]::new(0, $y))
        $queue.Enqueue([System.Drawing.Point]::new($width - 1, $y))
    }

    while ($queue.Count -gt 0) {
        $point = $queue.Dequeue()
        if ($point.X -lt 0 -or $point.X -ge $width -or $point.Y -lt 0 -or $point.Y -ge $height) {
            continue
        }
        if ($visited[$point.X, $point.Y]) {
            continue
        }
        $visited[$point.X, $point.Y] = $true
        $color = $Image.GetPixel($point.X, $point.Y)
        $max = [Math]::Max($color.R, [Math]::Max($color.G, $color.B))
        $min = [Math]::Min($color.R, [Math]::Min($color.G, $color.B))
        $isBackground = if ($Mode -eq "light") {
            $color.A -le 12 -or ($color.R -gt 205 -and $color.G -gt 198 -and $color.B -gt 184 -and ($max - $min) -lt 48)
        } else {
            $color.A -le 12 -or ($color.R -lt 48 -and $color.G -lt 52 -and $color.B -lt 66)
        }
        if (-not $isBackground) {
            continue
        }
        $Image.SetPixel($point.X, $point.Y, [System.Drawing.Color]::Transparent)
        $queue.Enqueue([System.Drawing.Point]::new($point.X - 1, $point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X + 1, $point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y - 1))
        $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y + 1))
    }
}

function Export-Crop {
    param(
        [System.Drawing.Bitmap]$Atlas,
        [string]$OutputPath,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [ValidateSet("none", "light", "dark")] [string]$Background = "none",
        [bool]$Trim = $true
    )
    Ensure-Directory (Split-Path -Parent $OutputPath)
    $crop = Copy-Region $Atlas ([System.Drawing.Rectangle]::new($X, $Y, $Width, $Height))
    if ($Background -ne "none") {
        Remove-Edge-Background $crop $Background
    }
    if ($Trim) {
        $bounds = Get-Alpha-Bounds $crop
        $trimmed = Copy-Region $crop $bounds
        $crop.Dispose()
        $crop = $trimmed
    }
    $crop.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

function Export-EnemyFrame {
    param(
        [System.Drawing.Bitmap]$Atlas,
        [string]$OutputPath,
        [int[]]$Rect,
        [int]$CanvasWidth,
        [int]$CanvasHeight,
        [bool]$KeepLargest = $true
    )
    $crop = Copy-Region $Atlas ([System.Drawing.Rectangle]::new($Rect[0], $Rect[1], $Rect[2], $Rect[3]))
    Remove-Edge-Background $crop "dark"
    if ($KeepLargest) {
        Keep-Largest-Alpha-Component $crop
    }
    $bounds = Get-Alpha-Bounds $crop
    $trimmed = Copy-Region $crop $bounds
    $crop.Dispose()
    $canvas = [System.Drawing.Bitmap]::new($CanvasWidth, $CanvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $targetX = [int][Math]::Round(($CanvasWidth - $trimmed.Width) * 0.5)
    $targetY = $CanvasHeight - $trimmed.Height - 3
    $graphics.DrawImageUnscaled($trimmed, $targetX, $targetY)
    $graphics.Dispose()
    Ensure-Directory (Split-Path -Parent $OutputPath)
    $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    $trimmed.Dispose()
}

function Export-EnemySet {
    param(
        [string]$SourceName,
        [string]$EnemyId,
        [hashtable]$Animations,
        [int]$CanvasWidth,
        [int]$CanvasHeight,
        [bool]$KeepLargest = $true
    )
    $sourcePath = Join-Path $sourceRoot $SourceName
    $targetRoot = Join-Path $gameAssets "sprites\enemies\$EnemyId"
    $enemySourceRoot = Join-Path $gameAssets "sprites\enemies\source"
    Ensure-Directory $targetRoot
    Ensure-Directory $enemySourceRoot
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $enemySourceRoot "$EnemyId-atlas.png") -Force
    $atlas = [System.Drawing.Bitmap]::FromFile($sourcePath)
    foreach ($animationName in $Animations.Keys) {
        $rects = $Animations[$animationName]
        for ($index = 0; $index -lt $rects.Count; $index++) {
            Export-EnemyFrame $atlas (Join-Path $targetRoot ("{0}_{1}.png" -f $animationName, $index)) $rects[$index] $CanvasWidth $CanvasHeight $KeepLargest
        }
    }
    $atlas.Dispose()
}

$abomination = @{
    idle = @(@(302, 48, 72, 105), @(380, 48, 72, 105), @(458, 48, 72, 105), @(530, 48, 72, 105))
    move = @(@(580, 48, 88, 108), @(670, 48, 88, 108), @(760, 48, 88, 108), @(850, 48, 94, 108))
    alert = @(@(302, 184, 82, 112), @(390, 184, 82, 112), @(478, 184, 82, 112))
    attack = @(@(1040, 350, 94, 122), @(1134, 350, 94, 122), @(1228, 350, 98, 122), @(1325, 350, 112, 122))
    damage = @(@(302, 706, 82, 116), @(390, 706, 82, 116), @(478, 706, 84, 116))
    death = @(@(575, 706, 92, 116), @(670, 706, 92, 116), @(765, 706, 92, 116), @(860, 706, 96, 116))
    respawn = @(@(1160, 706, 84, 116), @(1248, 706, 84, 116), @(1336, 706, 92, 116))
}

$unstable = @{
    idle = @(@(310, 48, 82, 108), @(400, 48, 82, 108), @(490, 48, 82, 108), @(580, 48, 82, 108))
    move = @(@(1060, 48, 82, 108), @(1150, 48, 82, 108), @(1240, 48, 82, 108), @(1330, 48, 92, 108))
    alert = @(@(310, 184, 86, 112), @(405, 184, 86, 112), @(500, 184, 86, 112), @(595, 184, 86, 112))
    attack = @(@(1060, 184, 86, 118), @(1155, 184, 86, 118), @(1250, 184, 86, 118), @(1340, 184, 100, 118))
    damage = @(@(310, 604, 92, 108), @(410, 604, 92, 108), @(510, 604, 92, 108))
    death = @(@(640, 604, 88, 108), @(730, 604, 88, 108), @(820, 604, 88, 108), @(910, 604, 88, 108))
    respawn = @(@(1040, 604, 88, 108), @(1135, 604, 88, 108), @(1230, 604, 88, 108), @(1325, 604, 100, 108))
}

$sentinel = @{
    idle = @(@(325, 48, 72, 112), @(405, 48, 72, 112), @(485, 48, 72, 112), @(565, 48, 72, 112))
    move = @(@(650, 48, 76, 112), @(735, 48, 76, 112), @(820, 48, 76, 112), @(905, 48, 76, 112))
    alert = @(@(325, 184, 76, 112), @(410, 184, 76, 112), @(495, 184, 76, 112), @(580, 184, 76, 112))
    attack = @(@(790, 448, 82, 118), @(880, 448, 82, 118), @(970, 448, 82, 118), @(1060, 448, 110, 118))
    damage = @(@(325, 610, 82, 112), @(415, 610, 82, 112), @(505, 610, 82, 112), @(595, 610, 82, 112))
    death = @(@(720, 610, 88, 112), @(812, 610, 88, 112), @(904, 610, 88, 112), @(996, 610, 88, 112))
    respawn = @(@(1085, 610, 78, 112), @(1170, 610, 78, 112), @(1255, 610, 78, 112), @(1340, 610, 86, 112))
}

$shadow = @{
    idle = @(@(300, 42, 76, 86), @(382, 42, 76, 86), @(464, 42, 76, 86), @(546, 42, 76, 86))
    move = @(@(620, 42, 82, 86), @(708, 42, 82, 86), @(796, 42, 82, 86), @(884, 42, 82, 86))
    alert = @(@(300, 166, 78, 86), @(384, 166, 78, 86), @(468, 166, 78, 86), @(552, 166, 78, 86))
    attack = @(@(820, 404, 88, 92), @(914, 404, 88, 92), @(1008, 404, 88, 92), @(1102, 404, 94, 92))
    damage = @(@(300, 610, 84, 96), @(390, 610, 84, 96), @(480, 610, 84, 96), @(570, 610, 84, 96))
    death = @(@(710, 610, 88, 96), @(804, 610, 88, 96), @(898, 610, 88, 96), @(992, 610, 88, 96))
    respawn = @(@(1110, 610, 84, 96), @(1200, 610, 84, 96), @(1290, 610, 96, 96))
}

Export-EnemySet "AbominacaoAncetral.png" "ancestral_abomination" $abomination 220 180
Export-EnemySet "EnergiaaInstavel.png" "unstable_energy" $unstable 180 160
Export-EnemySet "SentinelaMistica.png" "mystic_sentinel" $sentinel 180 170
Export-EnemySet "SombradaQueda.png" "fallen_shadow" $shadow 190 180 $false

$backgroundTarget = Join-Path $gameAssets "sprites\backgrounds\expansion"
$backgroundSource = Join-Path $gameAssets "sprites\backgrounds\source"
Ensure-Directory $backgroundTarget
Ensure-Directory $backgroundSource

$distantPath = Join-Path $sourceRoot "DistantArchiteccture1.png"
Copy-Item $distantPath (Join-Path $backgroundSource "distant-architecture-atlas.png") -Force
$distant = [System.Drawing.Bitmap]::FromFile($distantPath)
Export-Crop $distant (Join-Path $backgroundTarget "day_sky.png") 28 140 212 49 "none" $false
Export-Crop $distant (Join-Path $backgroundTarget "day_cloud_modules.png") 258 140 180 206 "light" $true
Export-Crop $distant (Join-Path $backgroundTarget "distant_mountains.png") 450 140 172 205 "light" $true
Export-Crop $distant (Join-Path $backgroundTarget "day_haze.png") 28 370 248 96 "none" $false
Export-Crop $distant (Join-Path $backgroundTarget "distant_towers.png") 638 112 354 366 "light" $true
$distant.Dispose()

$midPath = Join-Path $sourceRoot "midground3.png"
Copy-Item $midPath (Join-Path $backgroundSource "midground-machines-atlas.png") -Force
$mid = [System.Drawing.Bitmap]::FromFile($midPath)
Export-Crop $mid (Join-Path $backgroundTarget "night_sky.png") 20 128 220 204 "none" $false
Export-Crop $mid (Join-Path $backgroundTarget "night_mountains.png") 445 130 178 215 "light" $true
Export-Crop $mid (Join-Path $backgroundTarget "night_machines.png") 638 108 342 350 "light" $true
Export-Crop $mid (Join-Path $backgroundTarget "midground_ruins.png") 18 468 950 178 "light" $true
$mid.Dispose()

$foregroundPath = Join-Path $sourceRoot "foreground1.png"
Copy-Item $foregroundPath (Join-Path $backgroundSource "foreground-atlas.png") -Force
$foreground = [System.Drawing.Bitmap]::FromFile($foregroundPath)
Export-Crop $foreground (Join-Path $backgroundTarget "foreground_rocks.png") 35 210 855 92 "light" $true
Export-Crop $foreground (Join-Path $backgroundTarget "foreground_roots.png") 38 350 715 70 "light" $true
Export-Crop $foreground (Join-Path $backgroundTarget "foreground_shadows.png") 35 450 485 50 "light" $true
Export-Crop $foreground (Join-Path $backgroundTarget "foreground_modules.png") 925 210 460 88 "light" $true
$foreground.Dispose()

$atmospherePath = Join-Path $sourceRoot "atmosphere3.png"
Copy-Item $atmospherePath (Join-Path $backgroundSource "atmosphere-atlas.png") -Force
$atmosphere = [System.Drawing.Bitmap]::FromFile($atmospherePath)
Export-Crop $atmosphere (Join-Path $backgroundTarget "atmosphere_particles.png") 50 202 735 86 "light" $true
Export-Crop $atmosphere (Join-Path $backgroundTarget "atmosphere_light.png") 810 202 580 88 "light" $true
Export-Crop $atmosphere (Join-Path $backgroundTarget "atmosphere_fog.png") 50 520 550 132 "light" $true
Export-Crop $atmosphere (Join-Path $backgroundTarget "atmosphere_modules.png") 835 520 555 132 "light" $true
$atmosphere.Dispose()

$mapTarget = Join-Path $gameAssets "maps"
Ensure-Directory $mapTarget
Copy-Item -LiteralPath (Join-Path $sourceRoot "mapa central.png") -Destination (Join-Path $mapTarget "central_map.png") -Force

$vfxDefinitions = @(
    @("AbominacaoAncetral.png", "combat\abomination_claw.png", 450, 910, 84, 90),
    @("AbominacaoAncetral.png", "corruption\abomination_burst.png", 535, 910, 90, 90),
    @("EnergiaaInstavel.png", "corruption\unstable_explosion.png", 540, 925, 90, 90),
    @("EnergiaaInstavel.png", "arcane\unstable_ring.png", 400, 925, 80, 90),
    @("SentinelaMistica.png", "arcane\sentinel_scan.png", 450, 920, 120, 95),
    @("SentinelaMistica.png", "arcane\sentinel_flash.png", 570, 920, 80, 95),
    @("SombradaQueda.png", "shadow\fallen_pressure.png", 500, 920, 100, 95),
    @("SombradaQueda.png", "shadow\fallen_slash.png", 340, 920, 90, 95)
)
foreach ($definition in $vfxDefinitions) {
    $atlas = [System.Drawing.Bitmap]::FromFile((Join-Path $sourceRoot $definition[0]))
    Export-Crop $atlas (Join-Path (Join-Path $gameAssets "vfx") $definition[1]) $definition[2] $definition[3] $definition[4] $definition[5] "dark" $true
    $atlas.Dispose()
}

Write-Output "Expansion assets sliced and organized."

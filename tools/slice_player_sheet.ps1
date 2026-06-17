param(
    [string]$SourcePath = "C:\Users\renar\Downloads\Kenosis_Agent_Docs_StarterKit\Asseds\Player.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$playerRoot = Join-Path $repoRoot "game\assets\sprites\player"
$sourceRoot = Join-Path $playerRoot "source"
$framesRoot = Join-Path $playerRoot "frames"
$configRoot = Join-Path $repoRoot "game\data\config"

New-Item -ItemType Directory -Force -Path $sourceRoot, $framesRoot, $configRoot | Out-Null
Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $sourceRoot "player_sheet.png") -Force

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

function Remove-Light-Background {
    param([System.Drawing.Bitmap]$Bitmap)

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $color = $Bitmap.GetPixel($x, $y)
            $max = [Math]::Max($color.R, [Math]::Max($color.G, $color.B))
            $min = [Math]::Min($color.R, [Math]::Min($color.G, $color.B))
            $neutral = ($max - $min) -lt 20
            if ($neutral -and $color.R -gt 155 -and $color.G -gt 155 -and $color.B -gt 155) {
                $Bitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }
}

function Get-Alpha-Bounds {
    param([System.Drawing.Bitmap]$Bitmap)

    $minX = $Bitmap.Width
    $minY = $Bitmap.Height
    $maxX = -1
    $maxY = -1

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            if ($Bitmap.GetPixel($x, $y).A -gt 12) {
                $minX = [Math]::Min($minX, $x)
                $minY = [Math]::Min($minY, $y)
                $maxX = [Math]::Max($maxX, $x)
                $maxY = [Math]::Max($maxY, $y)
            }
        }
    }

    if ($maxX -lt 0) {
        return [System.Drawing.Rectangle]::new(0, 0, $Bitmap.Width, $Bitmap.Height)
    }

    $padding = 3
    $left = [Math]::Max(0, $minX - $padding)
    $top = [Math]::Max(0, $minY - $padding)
    $right = [Math]::Min($Bitmap.Width - 1, $maxX + $padding)
    $bottom = [Math]::Min($Bitmap.Height - 1, $maxY + $padding)
    return [System.Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function Remove-Side-Connected-Noise {
    param([System.Drawing.Bitmap]$Bitmap)

    $width = $Bitmap.Width
    $height = $Bitmap.Height
    $visited = New-Object 'bool[,]' $width, $height
    $starts = New-Object System.Collections.Generic.List[System.Drawing.Point]
    for ($y = 0; $y -lt $height; $y++) {
        $starts.Add([System.Drawing.Point]::new(0, $y))
        $starts.Add([System.Drawing.Point]::new($width - 1, $y))
    }

    foreach ($start in $starts) {
        if ($visited[$start.X, $start.Y] -or $Bitmap.GetPixel($start.X, $start.Y).A -le 12) {
            continue
        }
        $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
        $component = New-Object System.Collections.Generic.List[System.Drawing.Point]
        $queue.Enqueue($start)
        $visited[$start.X, $start.Y] = $true
        $minX = $start.X
        $maxX = $start.X

        while ($queue.Count -gt 0) {
            $point = $queue.Dequeue()
            $component.Add($point)
            $minX = [Math]::Min($minX, $point.X)
            $maxX = [Math]::Max($maxX, $point.X)
            foreach ($neighbor in @(
                [System.Drawing.Point]::new($point.X - 1, $point.Y),
                [System.Drawing.Point]::new($point.X + 1, $point.Y),
                [System.Drawing.Point]::new($point.X, $point.Y - 1),
                [System.Drawing.Point]::new($point.X, $point.Y + 1)
            )) {
                if ($neighbor.X -lt 0 -or $neighbor.X -ge $width -or $neighbor.Y -lt 0 -or $neighbor.Y -ge $height) {
                    continue
                }
                if ($visited[$neighbor.X, $neighbor.Y] -or $Bitmap.GetPixel($neighbor.X, $neighbor.Y).A -le 12) {
                    continue
                }
                $visited[$neighbor.X, $neighbor.Y] = $true
                $queue.Enqueue($neighbor)
            }
        }

        if (($maxX - $minX + 1) -lt 45) {
            foreach ($point in $component) {
                $Bitmap.SetPixel($point.X, $point.Y, [System.Drawing.Color]::Transparent)
            }
        }
    }
}

function Keep-Largest-Alpha-Component {
    param([System.Drawing.Bitmap]$Bitmap)

    $width = $Bitmap.Width
    $height = $Bitmap.Height
    $visited = New-Object 'bool[,]' $width, $height
    $largest = New-Object System.Collections.Generic.List[System.Drawing.Point]

    for ($startY = 0; $startY -lt $height; $startY++) {
        for ($startX = 0; $startX -lt $width; $startX++) {
            if ($visited[$startX, $startY] -or $Bitmap.GetPixel($startX, $startY).A -le 12) {
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
                    if ($visited[$neighbor.X, $neighbor.Y] -or $Bitmap.GetPixel($neighbor.X, $neighbor.Y).A -le 12) {
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
                $Bitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }
}

function Export-Sequence {
    param(
        [System.Drawing.Bitmap]$Sheet,
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$FrameCount,
        [int]$FramePadding = 2
    )

    $frameWidth = [double]$Width / $FrameCount
    $framePaths = @()

    for ($index = 0; $index -lt $FrameCount; $index++) {
        $left = [Math]::Max($X, [int][Math]::Round($X + ($index * $frameWidth)) - $FramePadding)
        $right = [Math]::Min($X + $Width, [int][Math]::Round($X + (($index + 1) * $frameWidth)) + $FramePadding)
        $rect = [System.Drawing.Rectangle]::new($left, $Y, $right - $left, $Height)
        $frame = Copy-Region -Source $Sheet -Rect $rect
        Remove-Light-Background -Bitmap $frame
        for ($topY = 0; $topY -lt [Math]::Min(14, $frame.Height); $topY++) {
            for ($topX = 0; $topX -lt $frame.Width; $topX++) {
                $frame.SetPixel($topX, $topY, [System.Drawing.Color]::Transparent)
            }
        }
        $bounds = Get-Alpha-Bounds -Bitmap $frame
        $trimmed = Copy-Region -Source $frame -Rect $bounds
        $canvas = [System.Drawing.Bitmap]::new(150, 135, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $canvasGraphics = [System.Drawing.Graphics]::FromImage($canvas)
        $targetX = [int][Math]::Round(($canvas.Width - $trimmed.Width) * 0.5)
        $targetY = $canvas.Height - $trimmed.Height - 3
        $canvasGraphics.DrawImageUnscaled($trimmed, $targetX, $targetY)
        $canvasGraphics.Dispose()
        $outputName = "player_{0}_{1}.png" -f $Name, $index
        $outputPath = Join-Path $framesRoot $outputName
        $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $framePaths += "res://assets/sprites/player/frames/$outputName"
        $canvas.Dispose()
        $trimmed.Dispose()
        $frame.Dispose()
    }

    return [ordered]@{
        name = $Name
        frame_count = $FrameCount
        paths = $framePaths
    }
}

function Export-Exact-Frame {
    param(
        [System.Drawing.Bitmap]$Sheet,
        [string]$Name,
        [int]$Index,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $frame = Copy-Region -Source $Sheet -Rect ([System.Drawing.Rectangle]::new($X, $Y, $Width, $Height))
    Remove-Light-Background -Bitmap $frame
    Keep-Largest-Alpha-Component -Bitmap $frame
    $bounds = Get-Alpha-Bounds -Bitmap $frame
    $trimmed = Copy-Region -Source $frame -Rect $bounds
    $canvas = [System.Drawing.Bitmap]::new(150, 135, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $targetX = [int][Math]::Round(($canvas.Width - $trimmed.Width) * 0.5)
    $targetY = $canvas.Height - $trimmed.Height - 3
    $graphics.DrawImageUnscaled($trimmed, $targetX, $targetY)
    $graphics.Dispose()
    $canvas.Save((Join-Path $framesRoot ("player_{0}_{1}.png" -f $Name, $Index)), [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    $trimmed.Dispose()
    $frame.Dispose()
}

$sheet = [System.Drawing.Bitmap]::FromFile($SourcePath)
$sequences = @(
    @{ name = "idle"; x = 16; y = 42; width = 665; height = 132; frames = 7 },
    @{ name = "walk"; x = 700; y = 42; width = 733; height = 132; frames = 8 },
    @{ name = "run"; x = 16; y = 218; width = 732; height = 137; frames = 8 },
    @{ name = "turn"; x = 761; y = 218; width = 322; height = 137; frames = 4 },
    @{ name = "jump_start"; x = 1060; y = 218; width = 373; height = 137; frames = 3; padding = 4 },
    @{ name = "jump_rise"; x = 16; y = 397; width = 278; height = 106; frames = 3; padding = 8 },
    @{ name = "apex"; x = 323; y = 397; width = 194; height = 106; frames = 2; padding = 2 },
    @{ name = "fall"; x = 533; y = 397; width = 445; height = 106; frames = 4; padding = 8 },
    @{ name = "land"; x = 994; y = 397; width = 440; height = 106; frames = 4 },
    @{ name = "crouch"; x = 16; y = 544; width = 374; height = 120; frames = 4 },
    @{ name = "crouch_stealth"; x = 407; y = 544; width = 538; height = 120; frames = 5 },
    @{ name = "interact"; x = 961; y = 544; width = 354; height = 120; frames = 3 },
    @{ name = "resonance"; x = 16; y = 703; width = 826; height = 113; frames = 7 },
    @{ name = "damage_hit"; x = 858; y = 703; width = 576; height = 113; frames = 4; padding = 10 },
    @{ name = "death"; x = 16; y = 856; width = 569; height = 110; frames = 6; padding = 10 },
    @{ name = "respawn"; x = 656; y = 856; width = 778; height = 110; frames = 8; padding = 6 },
    @{ name = "silhouette_shadow"; x = 16; y = 1006; width = 522; height = 74; frames = 4 }
)

$metadata = @()
foreach ($sequence in $sequences) {
    $metadata += Export-Sequence `
        -Sheet $sheet `
        -Name $sequence.name `
        -X $sequence.x `
        -Y $sequence.y `
        -Width $sequence.width `
        -Height $sequence.height `
        -FrameCount $sequence.frames `
        -FramePadding $(if ($sequence.ContainsKey("padding")) { $sequence.padding } else { 2 })
}

Export-Exact-Frame $sheet "jump_start" 0 1102 224 100 128
Export-Exact-Frame $sheet "jump_start" 1 1202 224 112 128
Export-Exact-Frame $sheet "jump_start" 2 1288 224 145 128
Export-Exact-Frame $sheet "jump_rise" 0 16 405 96 98
Export-Exact-Frame $sheet "jump_rise" 1 104 405 98 98
Export-Exact-Frame $sheet "jump_rise" 2 196 405 98 98
Export-Exact-Frame $sheet "apex" 0 323 405 101 98
Export-Exact-Frame $sheet "apex" 1 421 405 96 98
Export-Exact-Frame $sheet "fall" 0 533 405 120 98
Export-Exact-Frame $sheet "fall" 1 648 405 117 98
Export-Exact-Frame $sheet "fall" 2 758 405 118 98
Export-Exact-Frame $sheet "fall" 3 868 405 110 98
Export-Exact-Frame $sheet "land" 0 994 405 111 98
Export-Exact-Frame $sheet "land" 1 1104 405 111 98
Export-Exact-Frame $sheet "land" 2 1214 405 111 98
Export-Exact-Frame $sheet "land" 3 1324 405 110 98

$sheet.Dispose()
$metadata | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $configRoot "player_sprites.json")
Write-Output ("Generated {0} complete player animation sequences in {1}" -f $metadata.Count, $framesRoot)

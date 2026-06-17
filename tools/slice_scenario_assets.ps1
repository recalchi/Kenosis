$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = "C:\Users\renar\Downloads\Kenosis_Agent_Docs_StarterKit\Asseds"
$sourceFile = Get-ChildItem -LiteralPath $sourceDir -Filter "Assets de cen*rio.png" | Select-Object -First 1
$sourcePath = if ($null -ne $sourceFile) { $sourceFile.FullName } else { "" }
$projectAssets = Join-Path $repoRoot "game\assets\sprites"
$atlasTargetDir = Join-Path $projectAssets "tilesets\source"
$tilesTargetDir = Join-Path $projectAssets "tilesets\scenario"
$propsTargetDir = Join-Path $projectAssets "props\scenario"
$interactablesTargetDir = Join-Path $projectAssets "interactables"

if ($sourcePath -eq "" -or -not (Test-Path $sourcePath)) {
    throw "Scenario atlas not found in: $sourceDir"
}

New-Item -ItemType Directory -Force -Path $atlasTargetDir, $tilesTargetDir, $propsTargetDir, $interactablesTargetDir | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $atlasTargetDir "scenario_atlas.png") -Force

Add-Type -AssemblyName System.Drawing

$atlas = [System.Drawing.Bitmap]::FromFile($sourcePath)

function Test-BackgroundPixel {
    param([System.Drawing.Color] $Color)

    $nearWhite = $Color.R -gt 205 -and $Color.G -gt 200 -and $Color.B -gt 190
    $balanced = ([Math]::Abs($Color.R - $Color.G) -lt 38) -and ([Math]::Abs($Color.G - $Color.B) -lt 46)
    return $nearWhite -and $balanced
}

function Convert-BackgroundToTransparent {
    param([System.Drawing.Bitmap] $Image)

    for ($y = 0; $y -lt $Image.Height; $y++) {
        for ($x = 0; $x -lt $Image.Width; $x++) {
            $pixel = $Image.GetPixel($x, $y)
            if (Test-BackgroundPixel $pixel) {
                $Image.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $pixel.R, $pixel.G, $pixel.B))
            }
        }
    }
}

function Get-OpaqueBounds {
    param([System.Drawing.Bitmap] $Image)

    $minX = $Image.Width
    $minY = $Image.Height
    $maxX = -1
    $maxY = -1

    for ($y = 0; $y -lt $Image.Height; $y++) {
        for ($x = 0; $x -lt $Image.Width; $x++) {
            if ($Image.GetPixel($x, $y).A -gt 12) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($maxX -lt 0 -or $maxY -lt 0) {
        return New-Object System.Drawing.Rectangle(0, 0, $Image.Width, $Image.Height)
    }

    return New-Object System.Drawing.Rectangle($minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1))
}

function Keep-Largest-Alpha-Component {
    param([System.Drawing.Bitmap] $Image)

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

function Export-Crop {
    param(
        [string] $Name,
        [string] $TargetDir,
        [int] $X,
        [int] $Y,
        [int] $Width,
        [int] $Height,
        [bool] $Trim = $true,
        [bool] $KeepLargest = $false
    )

    $rect = New-Object System.Drawing.Rectangle($X, $Y, $Width, $Height)
    $crop = $atlas.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Convert-BackgroundToTransparent $crop
    if ($KeepLargest) {
        Keep-Largest-Alpha-Component $crop
    }

    if ($Trim) {
        $bounds = Get-OpaqueBounds $crop
        $trimmed = $crop.Clone($bounds, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $crop.Dispose()
        $crop = $trimmed
    }

    $outputPath = Join-Path $TargetDir $Name
    $crop.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

Export-Crop "ground_grass_long.png" $tilesTargetDir 16 82 192 62
Export-Crop "ground_grass_small.png" $tilesTargetDir 220 82 60 62
Export-Crop "ground_corner_left.png" $tilesTargetDir 16 161 106 100
Export-Crop "wall_stone_moss.png" $tilesTargetDir 452 82 54 195
Export-Crop "wall_block_grey.png" $tilesTargetDir 510 82 54 114
Export-Crop "platform_floating_grass.png" $tilesTargetDir 1160 82 140 54
Export-Crop "platform_wood_bridge.png" $tilesTargetDir 1164 172 154 50
Export-Crop "platform_stone_bridge.png" $tilesTargetDir 1160 258 122 48
Export-Crop "resonance_bridge.png" $tilesTargetDir 1160 258 122 48
Export-Crop "tree_oak.png" $propsTargetDir 459 369 46 127 $true $true
Export-Crop "tree_broad.png" $propsTargetDir 585 368 73 127 $true $true
Export-Crop "bush_round.png" $propsTargetDir 672 388 66 58 $true $true
Export-Crop "vine_cluster.png" $propsTargetDir 759 469 78 116
Export-Crop "stone_well.png" $propsTargetDir 748 574 88 62
Export-Crop "lamp_post.png" $propsTargetDir 1044 495 58 95
Export-Crop "log_moss.png" $propsTargetDir 898 568 67 32 $true $true
Export-Crop "energized_block.png" $interactablesTargetDir 16 694 60 58
Export-Crop "resonance_receiver_relic.png" $interactablesTargetDir 90 694 60 60
Export-Crop "exorigem_source_relic.png" $interactablesTargetDir 96 842 68 80
Export-Crop "completion_gate_relic.png" $interactablesTargetDir 351 840 58 82
Export-Crop "corrupted_block.png" $interactablesTargetDir 452 695 72 60
Export-Crop "corrupted_pillar.png" $interactablesTargetDir 674 823 52 80

$atlas.Dispose()

Write-Output "Scenario atlas sliced into transparent, trimmed PNGs."

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = "C:\Users\renar\Downloads\Kenosis_Agent_Docs_StarterKit\Asseds"
$sourceFile = Get-ChildItem -LiteralPath $sourceDir -Filter "backgroundsParallax-versaoDia.png" | Select-Object -First 1
$sourcePath = if ($null -ne $sourceFile) { $sourceFile.FullName } else { "" }
$targetRoot = Join-Path $repoRoot "game\assets\sprites\backgrounds\day"
$sourceRoot = Join-Path $repoRoot "game\assets\sprites\backgrounds\source"

if ($sourcePath -eq "" -or -not (Test-Path $sourcePath)) {
    throw "Parallax atlas not found in: $sourceDir"
}

New-Item -ItemType Directory -Force -Path $targetRoot, $sourceRoot | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceRoot "backgrounds_parallax_day_atlas.png") -Force

Add-Type -AssemblyName System.Drawing
$atlas = [System.Drawing.Bitmap]::FromFile($sourcePath)

function Test-PaperPixel {
    param([System.Drawing.Color] $Color)
    return $Color.R -gt 224 -and $Color.G -gt 217 -and $Color.B -gt 204 -and
        [Math]::Abs($Color.R - $Color.G) -lt 32 -and
        [Math]::Abs($Color.G - $Color.B) -lt 40
}

function Make-Transparent {
    param([System.Drawing.Bitmap] $Image)
    for ($y = 0; $y -lt $Image.Height; $y++) {
        for ($x = 0; $x -lt $Image.Width; $x++) {
            $pixel = $Image.GetPixel($x, $y)
            if (Test-PaperPixel $pixel) {
                $Image.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $pixel.R, $pixel.G, $pixel.B))
            }
        }
    }
}

function Remove-Edge-Backdrop {
    param([System.Drawing.Bitmap] $Image)

    $width = $Image.Width
    $height = $Image.Height
    $visited = New-Object 'bool[,]' $width, $height
    $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]

    function Test-BackdropPixel {
        param([System.Drawing.Color] $Color)
        $max = [Math]::Max($Color.R, [Math]::Max($Color.G, $Color.B))
        $min = [Math]::Min($Color.R, [Math]::Min($Color.G, $Color.B))
        return $Color.A -le 12 -or (
            $Color.R -gt 190 -and $Color.G -gt 200 -and $Color.B -gt 204 -and
            ($max - $min) -lt 42
        )
    }

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
        $pixel = $Image.GetPixel($point.X, $point.Y)
        if (-not (Test-BackdropPixel $pixel)) {
            continue
        }

        $Image.SetPixel($point.X, $point.Y, [System.Drawing.Color]::Transparent)
        $queue.Enqueue([System.Drawing.Point]::new($point.X - 1, $point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X + 1, $point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y - 1))
        $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y + 1))
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

function Export-Crop {
    param(
        [string] $Name,
        [int] $X,
        [int] $Y,
        [int] $Width,
        [int] $Height,
        [bool] $Transparent = $true,
        [bool] $Trim = $true
    )

    $rect = [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height)
    $crop = $atlas.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    if ($Transparent) {
        Make-Transparent $crop
        Remove-Edge-Backdrop $crop
    }

    if ($Trim) {
        $bounds = Get-OpaqueBounds $crop
        $trimmed = $crop.Clone($bounds, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $crop.Dispose()
        $crop = $trimmed
    }

    $crop.Save((Join-Path $targetRoot $Name), [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

Export-Crop "sky_day.png" 25 147 238 48 $false $false
Export-Crop "sky_clouds_day.png" 25 198 238 48 $false $false
Export-Crop "cloud_bank.png" 278 154 202 173 $true $true
Export-Crop "mountains_far.png" 492 154 177 35 $true $true
Export-Crop "mountains_near.png" 492 256 177 39 $true $true
Export-Crop "architecture_towers.png" 699 132 228 86 $true $true
Export-Crop "architecture_ruins.png" 699 250 229 83 $true $true
Export-Crop "midground_arch.png" 22 506 173 106 $true $true
Export-Crop "midground_shrine.png" 306 578 205 99 $true $true
Export-Crop "midground_ruins.png" 512 572 207 105 $true $true
Export-Crop "foreground_bushes.png" 27 844 208 103 $true $true
Export-Crop "menu_field_background.png" 1018 140 405 166 $false $false

$atlas.Dispose()
Write-Output "Parallax atlas sliced into validated runtime layers."

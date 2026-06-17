$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = "C:\Users\renar\Downloads\Kenosis_Agent_Docs_StarterKit\Asseds\UIHUBRef.png"
$targetRoot = Join-Path $repoRoot "game\assets\ui\reference"
$sourceRoot = Join-Path $repoRoot "game\assets\ui\source"

if (-not (Test-Path $sourcePath)) {
    throw "UI reference atlas not found: $sourcePath"
}

New-Item -ItemType Directory -Force -Path $targetRoot, $sourceRoot | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $sourceRoot "ui_hub_reference_atlas.png") -Force

Add-Type -AssemblyName System.Drawing
$atlas = [System.Drawing.Bitmap]::FromFile($sourcePath)

function Test-PaperPixel {
    param([System.Drawing.Color] $Color)
    return $Color.R -gt 225 -and $Color.G -gt 220 -and $Color.B -gt 211 -and
        [Math]::Abs($Color.R - $Color.G) -lt 26 -and
        [Math]::Abs($Color.G - $Color.B) -lt 32
}

function Prepare-TransparentCrop {
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
    param([string] $Name, [int] $X, [int] $Y, [int] $Width, [int] $Height)
    $rect = [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height)
    $crop = $atlas.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Prepare-TransparentCrop $crop
    $bounds = Get-OpaqueBounds $crop
    $trimmed = $crop.Clone($bounds, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $crop.Dispose()
    $trimmed.Save((Join-Path $targetRoot $Name), [System.Drawing.Imaging.ImageFormat]::Png)
    $trimmed.Dispose()
}

Export-Crop "kenosis_logo.png" 478 4 470 58
Export-Crop "resonance_bar_empty.png" 18 129 124 53
Export-Crop "resonance_bar_full.png" 157 129 186 53
Export-Crop "resonance_orb_empty.png" 18 228 64 58
Export-Crop "resonance_orb_full.png" 218 228 64 58
Export-Crop "interaction_e.png" 593 142 37 38
Export-Crop "interaction_f.png" 642 142 37 38
Export-Crop "checkpoint_active.png" 743 745 57 91
Export-Crop "checkpoint_complete.png" 738 775 68 70
Export-Crop "status_memory.png" 310 770 42 45
Export-Crop "status_resonance.png" 190 770 45 45
Export-Crop "hud_frame_ornament.png" 557 526 61 57
Export-Crop "button_primary_normal.png" 1000 468 108 34
Export-Crop "button_primary_hover.png" 1120 468 108 34
Export-Crop "button_primary_pressed.png" 1238 468 108 34
Export-Crop "button_primary_disabled.png" 1340 468 96 34
Export-Crop "button_secondary_normal.png" 1000 518 108 34
Export-Crop "dialogue_frame.png" 981 219 412 122
Export-Crop "pause_panel.png" 15 451 190 250
Export-Crop "map_checkpoint_marker.png" 820 771 72 83

$atlas.Dispose()
Write-Output "UI reference atlas sliced into runtime components."

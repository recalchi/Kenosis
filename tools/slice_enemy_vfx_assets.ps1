$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = "C:\Users\renar\Downloads\Kenosis_Agent_Docs_StarterKit\Asseds"
$enemySource = Join-Path $sourceDir "patrulheiroCorrompido.png"
$vfxSource = Join-Path $sourceDir "guiaRefVFX.png"
$enemyRoot = Join-Path $repoRoot "game\assets\sprites\enemies\corrupted_patroller"
$vfxRoot = Join-Path $repoRoot "game\assets\sprites\vfx"
$sourceRoot = Join-Path $repoRoot "game\assets\sprites\enemies\source"

New-Item -ItemType Directory -Force -Path $enemyRoot, $vfxRoot, $sourceRoot | Out-Null
Copy-Item -LiteralPath $enemySource -Destination (Join-Path $sourceRoot "corrupted_patroller_atlas.png") -Force
Copy-Item -LiteralPath $vfxSource -Destination (Join-Path $sourceRoot "vfx_reference_atlas.png") -Force

Add-Type -AssemblyName System.Drawing

function Export-Dark-Crop {
    param(
        [System.Drawing.Bitmap] $Atlas,
        [string] $OutputPath,
        [int] $X,
        [int] $Y,
        [int] $Width,
        [int] $Height
    )

    $rect = [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height)
    $crop = $Atlas.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $background = $crop.GetPixel(0, 0)

    for ($yPos = 0; $yPos -lt $crop.Height; $yPos++) {
        for ($xPos = 0; $xPos -lt $crop.Width; $xPos++) {
            $pixel = $crop.GetPixel($xPos, $yPos)
            $distance = [Math]::Sqrt(
                [Math]::Pow($pixel.R - $background.R, 2) +
                [Math]::Pow($pixel.G - $background.G, 2) +
                [Math]::Pow($pixel.B - $background.B, 2)
            )
            if ($distance -lt 28 -and $pixel.R -lt 65 -and $pixel.G -lt 62 -and $pixel.B -lt 78) {
                $crop.SetPixel($xPos, $yPos, [System.Drawing.Color]::Transparent)
            }
        }
    }

    $minX = $crop.Width
    $minY = $crop.Height
    $maxX = -1
    $maxY = -1
    for ($yPos = 0; $yPos -lt $crop.Height; $yPos++) {
        for ($xPos = 0; $xPos -lt $crop.Width; $xPos++) {
            if ($crop.GetPixel($xPos, $yPos).A -gt 12) {
                $minX = [Math]::Min($minX, $xPos)
                $minY = [Math]::Min($minY, $yPos)
                $maxX = [Math]::Max($maxX, $xPos)
                $maxY = [Math]::Max($maxY, $yPos)
            }
        }
    }

    if ($maxX -ge 0) {
        $bounds = [System.Drawing.Rectangle]::new($minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)
        $trimmed = $crop.Clone($bounds, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $crop.Dispose()
        $crop = $trimmed
    }

    $crop.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

$enemy = [System.Drawing.Bitmap]::FromFile($enemySource)
$enemyFrames = @{
    "idle_0.png" = @(350, 61, 82, 126)
    "idle_1.png" = @(443, 64, 78, 123)
    "idle_2.png" = @(526, 61, 80, 126)
    "idle_3.png" = @(614, 63, 78, 124)
    "walk_0.png" = @(711, 66, 98, 122)
    "walk_1.png" = @(824, 66, 101, 122)
    "walk_2.png" = @(938, 64, 104, 124)
    "walk_3.png" = @(1043, 64, 105, 124)
    "alert_0.png" = @(1174, 58, 96, 132)
    "alert_1.png" = @(1280, 61, 84, 128)
    "alert_2.png" = @(1394, 56, 88, 134)
    "crouch_0.png" = @(344, 280, 94, 82)
    "crouch_1.png" = @(444, 280, 94, 82)
    "crouch_2.png" = @(544, 280, 94, 82)
    "attack_0.png" = @(342, 450, 94, 112)
    "attack_1.png" = @(447, 448, 100, 114)
    "attack_2.png" = @(552, 448, 102, 114)
    "attack_3.png" = @(655, 446, 102, 116)
    "damage_0.png" = @(344, 635, 106, 101)
    "damage_1.png" = @(452, 635, 104, 101)
    "damage_2.png" = @(556, 635, 106, 101)
    "death_0.png" = @(683, 650, 112, 86)
    "death_1.png" = @(800, 648, 130, 88)
    "death_2.png" = @(936, 625, 108, 111)
    "death_3.png" = @(1046, 619, 112, 117)
    "respawn_0.png" = @(1240, 637, 92, 103)
    "respawn_1.png" = @(1342, 637, 90, 103)
    "respawn_2.png" = @(1448, 637, 88, 103)
}
foreach ($frameName in $enemyFrames.Keys) {
    $crop = $enemyFrames[$frameName]
    Export-Dark-Crop $enemy (Join-Path $enemyRoot $frameName) $crop[0] $crop[1] $crop[2] $crop[3]
}

Copy-Item (Join-Path $enemyRoot "idle_0.png") (Join-Path $enemyRoot "idle.png") -Force
Copy-Item (Join-Path $enemyRoot "walk_0.png") (Join-Path $enemyRoot "walk.png") -Force
Copy-Item (Join-Path $enemyRoot "alert_0.png") (Join-Path $enemyRoot "alert.png") -Force
Copy-Item (Join-Path $enemyRoot "crouch_0.png") (Join-Path $enemyRoot "crouch.png") -Force
Copy-Item (Join-Path $enemyRoot "attack_0.png") (Join-Path $enemyRoot "attack.png") -Force
Copy-Item (Join-Path $enemyRoot "damage_0.png") (Join-Path $enemyRoot "damage.png") -Force
Copy-Item (Join-Path $enemyRoot "death_0.png") (Join-Path $enemyRoot "death.png") -Force
Copy-Item (Join-Path $enemyRoot "respawn_0.png") (Join-Path $enemyRoot "respawn.png") -Force
$enemy.Dispose()

$vfx = [System.Drawing.Bitmap]::FromFile($vfxSource)
Export-Dark-Crop $vfx (Join-Path $vfxRoot "resonance_burst.png") 338 110 84 106
Export-Dark-Crop $vfx (Join-Path $vfxRoot "cooldown_ring.png") 632 140 44 27
Export-Dark-Crop $vfx (Join-Path $vfxRoot "corruption_aura.png") 27 455 74 79
Export-Dark-Crop $vfx (Join-Path $vfxRoot "memory_reveal.png") 1077 292 40 73
Export-Dark-Crop $vfx (Join-Path $vfxRoot "checkpoint_inactive.png") 967 454 63 79
Export-Dark-Crop $vfx (Join-Path $vfxRoot "checkpoint_charge.png") 1045 436 91 101
Export-Dark-Crop $vfx (Join-Path $vfxRoot "checkpoint_active.png") 1235 434 91 103
Export-Dark-Crop $vfx (Join-Path $vfxRoot "alert_hit.png") 130 295 82 70
$vfx.Dispose()

Write-Output "Enemy and VFX sprites generated."

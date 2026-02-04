Add-Type -AssemblyName System.Drawing

$inputPath = "c:\Projects\Firstpass\LLM-Base\assets\tilesets\biomes\Biome 01\01 - Tileset_transparent.png"
$outputDir = "c:\Projects\Firstpass\LLM-Base\assets\tilesets\biomes\Biome 01\tiles_16x16"
$tileSize = 16

# Create output directory
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Write-Host "Loading image: $inputPath"
$bitmap = [System.Drawing.Bitmap]::FromFile($inputPath)
$width = $bitmap.Width
$height = $bitmap.Height

$cols = [Math]::Floor($width / $tileSize)
$rows = [Math]::Floor($height / $tileSize)

Write-Host "Image: ${width}x${height}, Grid: ${cols}x${rows} tiles (${tileSize}x${tileSize} each)"
Write-Host ""

$tileId = 0
$nonEmptyTiles = @()

for ($row = 0; $row -lt $rows; $row++) {
    for ($col = 0; $col -lt $cols; $col++) {
        $x = $col * $tileSize
        $y = $row * $tileSize

        # Check if tile has any non-transparent pixels
        $hasContent = $false
        for ($py = 0; $py -lt $tileSize -and !$hasContent; $py++) {
            for ($px = 0; $px -lt $tileSize -and !$hasContent; $px++) {
                $pixel = $bitmap.GetPixel($x + $px, $y + $py)
                if ($pixel.A -gt 10) {
                    $hasContent = $true
                }
            }
        }

        if ($hasContent) {
            $tileId++

            # Extract tile
            $tileRect = [System.Drawing.Rectangle]::new($x, $y, $tileSize, $tileSize)
            $tileBitmap = $bitmap.Clone($tileRect, $bitmap.PixelFormat)

            $filename = "tile_{0:D3}_r{1}_c{2}.png" -f $tileId, $row, $col
            $outputPath = Join-Path $outputDir $filename
            $tileBitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $tileBitmap.Dispose()

            $nonEmptyTiles += @{
                Id = $tileId
                Row = $row
                Col = $col
                X = $x
                Y = $y
            }
        }
    }
}

$bitmap.Dispose()

Write-Host "=== TILE GRID MAP ==="
Write-Host "Total non-empty tiles: $($nonEmptyTiles.Count)"
Write-Host ""

# Create a visual grid map
Write-Host "Grid visualization (# = has content, . = empty):"
for ($row = 0; $row -lt $rows; $row++) {
    $line = "Row {0:D2} (y={1:D3}): " -f $row, ($row * $tileSize)
    for ($col = 0; $col -lt $cols; $col++) {
        $hasTile = $nonEmptyTiles | Where-Object { $_.Row -eq $row -and $_.Col -eq $col }
        if ($hasTile) {
            $line += "#"
        } else {
            $line += "."
        }
    }
    Write-Host $line
}

Write-Host ""
Write-Host "Tiles saved to: $outputDir"
Write-Host ""
Write-Host "=== GODOT RECT2 COORDINATES ==="
Write-Host "Copy these for AtlasTexture regions:"
Write-Host ""

foreach ($t in $nonEmptyTiles | Select-Object -First 30) {
    Write-Host "Tile $($t.Id) (row $($t.Row), col $($t.Col)): Rect2($($t.X), $($t.Y), $tileSize, $tileSize)"
}

if ($nonEmptyTiles.Count -gt 30) {
    Write-Host "... and $($nonEmptyTiles.Count - 30) more tiles"
}

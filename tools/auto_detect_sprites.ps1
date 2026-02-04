Add-Type -AssemblyName System.Drawing

$inputPath = "c:\Projects\Firstpass\LLM-Base\assets\tilesets\biomes\Biome 01\01 - Tileset_transparent.png"
$outputDir = "c:\Projects\Firstpass\LLM-Base\assets\tilesets\biomes\Biome 01\sprites"

# Create output directory
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Write-Host "Loading image: $inputPath"
$bitmap = [System.Drawing.Bitmap]::FromFile($inputPath)
$width = $bitmap.Width
$height = $bitmap.Height

Write-Host "Image size: ${width}x${height}"

# Track visited pixels
$visited = New-Object 'bool[,]' $width, $height

# Find all connected components (sprites)
$sprites = @()
$spriteId = 0

function FloodFill {
    param($startX, $startY, $bitmap, $visited, $width, $height)

    $minX = $startX
    $maxX = $startX
    $minY = $startY
    $maxY = $startY

    $stack = New-Object System.Collections.Generic.Stack[System.Drawing.Point]
    $stack.Push([System.Drawing.Point]::new($startX, $startY))

    while ($stack.Count -gt 0) {
        $p = $stack.Pop()
        $x = $p.X
        $y = $p.Y

        if ($x -lt 0 -or $x -ge $width -or $y -lt 0 -or $y -ge $height) { continue }
        if ($visited[$x, $y]) { continue }

        $pixel = $bitmap.GetPixel($x, $y)
        if ($pixel.A -lt 10) { continue }  # Skip transparent pixels

        $visited[$x, $y] = $true

        # Update bounds
        if ($x -lt $minX) { $minX = $x }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($y -gt $maxY) { $maxY = $y }

        # Add neighbors
        $stack.Push([System.Drawing.Point]::new($x + 1, $y))
        $stack.Push([System.Drawing.Point]::new($x - 1, $y))
        $stack.Push([System.Drawing.Point]::new($x, $y + 1))
        $stack.Push([System.Drawing.Point]::new($x, $y - 1))
    }

    return @{
        MinX = $minX
        MaxX = $maxX
        MinY = $minY
        MaxY = $maxY
        Width = $maxX - $minX + 1
        Height = $maxY - $minY + 1
    }
}

Write-Host "Scanning for sprites..."

for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        if ($visited[$x, $y]) { continue }

        $pixel = $bitmap.GetPixel($x, $y)
        if ($pixel.A -lt 10) {
            $visited[$x, $y] = $true
            continue
        }

        # Found a new sprite - flood fill to find its bounds
        $bounds = FloodFill -startX $x -startY $y -bitmap $bitmap -visited $visited -width $width -height $height

        # Only save sprites larger than 8x8
        if ($bounds.Width -gt 8 -and $bounds.Height -gt 8) {
            $spriteId++

            # Extract and save sprite
            $spriteRect = [System.Drawing.Rectangle]::new($bounds.MinX, $bounds.MinY, $bounds.Width, $bounds.Height)
            $spriteBitmap = $bitmap.Clone($spriteRect, $bitmap.PixelFormat)

            $filename = "sprite_{0:D3}_x{1}_y{2}_w{3}_h{4}.png" -f $spriteId, $bounds.MinX, $bounds.MinY, $bounds.Width, $bounds.Height
            $outputPath = Join-Path $outputDir $filename
            $spriteBitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $spriteBitmap.Dispose()

            Write-Host "  Sprite $spriteId : Rect2($($bounds.MinX), $($bounds.MinY), $($bounds.Width), $($bounds.Height))"

            $sprites += @{
                Id = $spriteId
                X = $bounds.MinX
                Y = $bounds.MinY
                Width = $bounds.Width
                Height = $bounds.Height
            }
        }
    }

    if ($y % 100 -eq 0) {
        Write-Host "  Scanned row $y / $height"
    }
}

$bitmap.Dispose()

Write-Host "`n=== SPRITE COORDINATES ==="
Write-Host "Found $($sprites.Count) sprites:`n"

foreach ($s in $sprites | Sort-Object { $_.Y }, { $_.X }) {
    Write-Host "Sprite $($s.Id): Rect2($($s.X), $($s.Y), $($s.Width), $($s.Height))"
}

Write-Host "`nSprites saved to: $outputDir"

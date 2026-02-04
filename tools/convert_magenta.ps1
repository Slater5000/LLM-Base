Add-Type -AssemblyName System.Drawing

$inputPath = "c:\Projects\Firstpass\LLM-Base\assets\tilesets\biomes\Biome 01\01 - Tileset.png"
$outputPath = "c:\Projects\Firstpass\LLM-Base\assets\tilesets\biomes\Biome 01\01 - Tileset_transparent.png"

Write-Host "Loading image: $inputPath"
$bitmap = [System.Drawing.Bitmap]::FromFile($inputPath)

Write-Host "Creating new bitmap with transparency support..."
$newBitmap = New-Object System.Drawing.Bitmap($bitmap.Width, $bitmap.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

Write-Host "Processing pixels... (this may take a moment)"
$pixelsChanged = 0

for ($y = 0; $y -lt $bitmap.Height; $y++) {
    for ($x = 0; $x -lt $bitmap.Width; $x++) {
        $pixel = $bitmap.GetPixel($x, $y)
        # Check for magenta (255, 0, 255)
        if ($pixel.R -gt 250 -and $pixel.G -lt 5 -and $pixel.B -gt 250) {
            $newBitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            $pixelsChanged++
        } else {
            $newBitmap.SetPixel($x, $y, $pixel)
        }
    }
    # Progress indicator every 100 rows
    if ($y % 100 -eq 0) {
        Write-Host "  Row $y / $($bitmap.Height)"
    }
}

Write-Host "Saving to: $outputPath"
$bitmap.Dispose()
$newBitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$newBitmap.Dispose()

Write-Host "Done! Changed $pixelsChanged pixels to transparent."

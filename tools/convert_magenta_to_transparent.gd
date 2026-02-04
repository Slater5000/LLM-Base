@tool
extends EditorScript
## Run this script in Godot Editor: Project > Tools > Convert Magenta to Transparent
## Or run from script editor: File > Run (Ctrl+Shift+X)
##
## This converts all magenta (#FF00FF) pixels to transparent in the biome tilesets.

func _run() -> void:
	print("Converting magenta to transparency...")

	var biome_paths := [
		"res://assets/tilesets/biomes/Biome 01/01 - Tileset.png",
		"res://assets/tilesets/biomes/Biome 02/02 - Tileset.png",
		"res://assets/tilesets/biomes/Biome 03/03 - Tileset.png",
		# Add more as needed
	]

	for path in biome_paths:
		convert_file(path)

	print("Done! Reimport the textures in Godot.")


func convert_file(path: String) -> void:
	print("Processing: ", path)

	# Load the image
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		print("  ERROR: Could not load ", path)
		return

	# Convert to RGBA if needed
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	var width := image.get_width()
	var height := image.get_height()
	var magenta := Color(1.0, 0.0, 1.0, 1.0)  # #FF00FF
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	var pixels_changed := 0

	# Process each pixel
	for y in range(height):
		for x in range(width):
			var pixel := image.get_pixel(x, y)
			# Check if pixel is magenta (with some tolerance)
			if pixel.r > 0.95 and pixel.g < 0.05 and pixel.b > 0.95:
				image.set_pixel(x, y, transparent)
				pixels_changed += 1

	# Save back to file
	var global_path := ProjectSettings.globalize_path(path)
	var err := image.save_png(global_path)
	if err == OK:
		print("  Converted %d pixels, saved to %s" % [pixels_changed, path])
	else:
		print("  ERROR saving: ", err)

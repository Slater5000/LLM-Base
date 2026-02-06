extends Node2D
## Comparison test for all three blob terrain approaches

@onready var terrain_v2: Node2D = $TerrainV2  # 8-neighbor algorithm
@onready var terrain_v3: Node2D = $TerrainV3  # Overlay blending
@onready var terrain_v4: Node2D = $TerrainV4  # Hand-crafted patterns

const MAP_WIDTH := 12
const MAP_HEIGHT := 10


func _ready() -> void:
	await get_tree().process_frame

	# Same ASCII pattern for V2 and V3
	var ascii_map := """
............
...###......
..#####.....
..#####.....
...###......
............
.##########.
.##########.
............
............
"""

	print("=== BLOB TERRAIN COMPARISON ===")
	print("")

	# Approach A: 8-neighbor algorithm
	print("Rendering V2 (8-neighbor)...")
	terrain_v2.position = Vector2(0, 0)
	terrain_v2.load_from_ascii(ascii_map)
	await terrain_v2.render()
	_add_label(terrain_v2, "A: 8-Neighbor")

	# Approach B: Overlay blending
	print("Rendering V3 (Overlay)...")
	terrain_v3.position = Vector2(MAP_WIDTH * 32 + 32, 0)
	terrain_v3.load_from_ascii(ascii_map)
	await terrain_v3.render()
	_add_label(terrain_v3, "B: Overlay")

	# Approach C: Hand-crafted patterns
	print("Rendering V4 (Hand-crafted)...")
	terrain_v4.position = Vector2((MAP_WIDTH * 32 + 32) * 2, 0)
	terrain_v4.fill_base(MAP_WIDTH, MAP_HEIGHT)
	# Manually place patterns to match the ASCII layout
	terrain_v4.place_blob(3, 1, 1.2)  # Top circular patch (scaled up slightly)
	terrain_v4.place_horizontal_strip(1, 7, 10)  # Bottom strip
	_add_label(terrain_v4, "C: Hand-crafted")

	print("")
	print("Compare the three approaches!")
	print("- A: Automatic 8-neighbor (may have inner corner issues)")
	print("- B: Scaled blob overlays (stretchy but smooth)")
	print("- C: Strategic placement (most control)")


func _add_label(parent: Node2D, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, -24)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)

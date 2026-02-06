@tool
extends Node2D
## Demonstration of all procedural generation techniques.
##
## Attach to a Node2D and run in editor (@tool) or at runtime.
## Each technique is demonstrated with visualization.

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_category("Demo Settings")
@export var demo_seed: int = 12345
@export var tile_size: int = 16
@export var map_width: int = 40
@export var map_height: int = 30

@export_category("Technique Selection")
@export var show_noise: bool = true
@export var show_poisson: bool = true
@export var show_bsp: bool = true
@export var show_lsystem: bool = true
@export var show_wfc: bool = true

@export_category("Actions")
@export var regenerate: bool = false:
	set(value):
		if value:
			_regenerate()
			regenerate = false

# ============================================================================
# DEMO DATA
# ============================================================================

var _noise_grid: Array[Array] = []
var _poisson_points: Array[Vector2] = []
var _bsp_result: BSPDungeon.DungeonResult
var _lsystem_segments: Array[LSystem.Segment] = []
var _wfc_grid: Array[Array] = []

# Offsets for showing each technique
const DEMO_SPACING := 700

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_regenerate()


func _regenerate() -> void:
	_demo_noise()
	_demo_poisson()
	_demo_bsp()
	_demo_lsystem()
	_demo_wfc()
	queue_redraw()


# ============================================================================
# NOISE DEMO
# ============================================================================

func _demo_noise() -> void:
	if not show_noise:
		_noise_grid = []
		return

	var noise_gen := NoiseTerrain.new(demo_seed)
	noise_gen.apply_preset(NoiseTerrain.NoisePreset.GRASS_PATCHES)

	_noise_grid = []
	for x in range(map_width):
		var column: Array[float] = []
		for y in range(map_height):
			column.append(noise_gen.sample(x * 2, y * 2))  # Scale for visibility
		_noise_grid.append(column)


# ============================================================================
# POISSON DEMO
# ============================================================================

func _demo_poisson() -> void:
	if not show_poisson:
		_poisson_points = []
		return

	var sampler := PoissonDisk.new(demo_seed)
	var bounds := Rect2(0, 0, map_width * tile_size, map_height * tile_size)
	_poisson_points = sampler.generate(bounds, 24.0)


# ============================================================================
# BSP DEMO
# ============================================================================

func _demo_bsp() -> void:
	if not show_bsp:
		_bsp_result = null
		return

	var dungeon := BSPDungeon.new(demo_seed)
	dungeon.configure(map_width, map_height, 5, 10, 0, 1, 1)
	_bsp_result = dungeon.generate(map_width, map_height)
	dungeon.tag_special_rooms(_bsp_result)


# ============================================================================
# L-SYSTEM DEMO
# ============================================================================

func _demo_lsystem() -> void:
	if not show_lsystem:
		_lsystem_segments = []
		return

	var lsys := LSystem.new(demo_seed)
	lsys.set_river_preset()
	lsys.step_length = 30.0

	var start_pos := Vector2(map_width * tile_size / 2, 0)
	_lsystem_segments = lsys.generate_and_interpret(start_pos, Vector2.DOWN)


# ============================================================================
# WFC DEMO
# ============================================================================

func _demo_wfc() -> void:
	if not show_wfc:
		_wfc_grid = []
		return

	var wfc := WFCSimple.new(demo_seed)
	wfc.setup_basic_terrain()
	_wfc_grid = wfc.generate(20, 15)  # Smaller for WFC (it's slower)


# ============================================================================
# DRAWING
# ============================================================================

func _draw() -> void:
	var y_offset := 0

	if show_noise:
		_draw_noise(Vector2(0, y_offset))
		_draw_label(Vector2(0, y_offset - 20), "1. NOISE-BASED TERRAIN")
		_draw_label(Vector2(0, y_offset + map_height * tile_size + 5),
			"Grass density from Perlin noise. Green = grass, Dark = empty.")
		y_offset += map_height * tile_size + 60

	if show_poisson:
		_draw_poisson(Vector2(0, y_offset))
		_draw_label(Vector2(0, y_offset - 20), "2. POISSON DISK SAMPLING")
		_draw_label(Vector2(0, y_offset + map_height * tile_size + 5),
			"Even point distribution. Perfect for trees, NPCs, items.")
		y_offset += map_height * tile_size + 60

	if show_bsp:
		_draw_bsp(Vector2(0, y_offset))
		_draw_label(Vector2(0, y_offset - 20), "3. BSP DUNGEON")
		_draw_label(Vector2(0, y_offset + map_height * tile_size + 5),
			"Rooms + corridors. Green=entrance, Red=boss, Yellow=treasure.")
		y_offset += map_height * tile_size + 60

	if show_lsystem:
		_draw_lsystem(Vector2(0, y_offset))
		_draw_label(Vector2(0, y_offset - 20), "4. L-SYSTEM (River)")
		_draw_label(Vector2(0, y_offset + map_height * tile_size + 5),
			"Branching river pattern. Wider = main flow, thinner = tributaries.")
		y_offset += map_height * tile_size + 60

	if show_wfc:
		_draw_wfc(Vector2(0, y_offset))
		_draw_label(Vector2(0, y_offset - 20), "5. WAVE FUNCTION COLLAPSE")
		_draw_label(Vector2(0, y_offset + 15 * tile_size + 5),
			"Tile-based generation respecting adjacency rules.")


func _draw_label(pos: Vector2, text: String) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


func _draw_noise(offset: Vector2) -> void:
	if _noise_grid.is_empty():
		return

	# Background
	draw_rect(Rect2(offset, Vector2(map_width * tile_size, map_height * tile_size)), Color(0.1, 0.1, 0.1))

	for x in range(_noise_grid.size()):
		for y in range(_noise_grid[x].size()):
			var value: float = _noise_grid[x][y]
			var rect := Rect2(
				offset + Vector2(x * tile_size, y * tile_size),
				Vector2(tile_size, tile_size)
			)

			# Color based on noise value (grass tiers)
			var color: Color
			if value > 0.6:
				color = Color(0.2, 0.6, 0.2)  # Tall grass
			elif value > 0.3:
				color = Color(0.3, 0.5, 0.3)  # Short grass
			else:
				color = Color(0.15, 0.2, 0.15)  # Ground

			draw_rect(rect, color)


func _draw_poisson(offset: Vector2) -> void:
	# Background
	draw_rect(Rect2(offset, Vector2(map_width * tile_size, map_height * tile_size)), Color(0.15, 0.15, 0.15))

	for point in _poisson_points:
		draw_circle(offset + point, 4, Color(0.3, 0.7, 0.3))
		# Draw spacing ring
		draw_arc(offset + point, 12, 0, TAU, 16, Color(0.2, 0.4, 0.2, 0.3), 1)


func _draw_bsp(offset: Vector2) -> void:
	if _bsp_result == null:
		return

	# Background (walls)
	draw_rect(Rect2(offset, Vector2(map_width * tile_size, map_height * tile_size)), Color(0.2, 0.2, 0.25))

	# Draw rooms
	for i in range(_bsp_result.room_nodes.size()):
		var node: BSPDungeon.BSPNode = _bsp_result.room_nodes[i]
		var room := node.room
		var rect := Rect2(
			offset + Vector2(room.position.x * tile_size, room.position.y * tile_size),
			Vector2(room.size.x * tile_size, room.size.y * tile_size)
		)

		var color: Color
		match node.room_type:
			"entrance":
				color = Color(0.3, 0.6, 0.3)
			"boss":
				color = Color(0.6, 0.2, 0.2)
			"treasure":
				color = Color(0.7, 0.6, 0.2)
			_:
				color = Color(0.4, 0.35, 0.3)

		draw_rect(rect, color)

	# Draw corridors
	for corridor in _bsp_result.corridors:
		var rect := Rect2(
			offset + Vector2(corridor.position.x * tile_size, corridor.position.y * tile_size),
			Vector2(corridor.size.x * tile_size, corridor.size.y * tile_size)
		)
		draw_rect(rect, Color(0.35, 0.3, 0.28))


func _draw_lsystem(offset: Vector2) -> void:
	# Background
	draw_rect(Rect2(offset, Vector2(map_width * tile_size, map_height * tile_size)), Color(0.15, 0.2, 0.15))

	for segment in _lsystem_segments:
		var start := offset + segment.start
		var end := offset + segment.end

		# Color based on depth (lighter = tributary)
		var alpha := 1.0 - (segment.depth * 0.15)
		var color := Color(0.2, 0.4, 0.7, alpha)

		draw_line(start, end, color, segment.width)


func _draw_wfc(offset: Vector2) -> void:
	if _wfc_grid.is_empty():
		return

	var wfc_colors := {
		"grass": Color(0.3, 0.5, 0.3),
		"path": Color(0.5, 0.45, 0.4),
		"dirt": Color(0.45, 0.35, 0.25),
		"sand": Color(0.8, 0.75, 0.5),
		"water": Color(0.2, 0.4, 0.7)
	}

	for x in range(_wfc_grid.size()):
		for y in range(_wfc_grid[x].size()):
			var tile_id: String = _wfc_grid[x][y]
			var rect := Rect2(
				offset + Vector2(x * tile_size, y * tile_size),
				Vector2(tile_size, tile_size)
			)

			var color: Color = wfc_colors.get(tile_id, Color.MAGENTA)
			draw_rect(rect, color)


# ============================================================================
# USAGE EXAMPLES (Copy these into your own scripts)
# ============================================================================

## Example: Generate grass patches for a route
static func example_grass_generation() -> void:
	var noise := NoiseTerrain.new()
	noise.configure_grass_patches(0.05, 0.3, 0.6)

	# For each tile in your map:
	var x := 10
	var y := 20
	var grass_type := noise.sample_grass(x, y)
	match grass_type:
		NoiseTerrain.GrassType.TALL:
			pass  # Place tall grass, high encounter rate
		NoiseTerrain.GrassType.SHORT:
			pass  # Place short grass, low encounter rate
		NoiseTerrain.GrassType.NONE:
			pass  # No grass


## Example: Place trees naturally
static func example_tree_placement() -> Array[Vector2]:
	var sampler := PoissonDisk.new()
	var map_bounds := Rect2(0, 0, 1024, 768)

	# Basic even distribution
	var tree_positions := sampler.generate(map_bounds, 48.0)

	# Or with variable density (more trees where noise is high)
	var density_noise := NoiseTerrain.new()
	density_noise.apply_preset(NoiseTerrain.NoisePreset.FOREST_DENSITY)

	var variable_positions := sampler.generate_variable_density(
		map_bounds, 32.0, 96.0, density_noise
	)

	return variable_positions


## Example: Generate a cave system
static func example_cave_generation() -> BSPDungeon.DungeonResult:
	var dungeon := BSPDungeon.new()
	dungeon.corridor_width = 2  # Wider tunnels
	dungeon.min_room_size = 4
	dungeon.max_room_size = 8

	var result := dungeon.generate(32, 24)

	# Tag special rooms
	dungeon.tag_special_rooms(result)

	# Add some loops for non-linear exploration
	dungeon.add_loops(result, 2)

	# Get organic cave shapes instead of rectangles
	var organic_grid := dungeon.make_organic(result, 32, 24)

	return result


## Example: Generate a river
static func example_river_generation() -> Array[Vector2i]:
	var river := LSystem.new()
	river.set_river_preset()

	var start := Vector2(512, 0)  # Top of map
	var segments := river.generate_and_interpret(start, Vector2.DOWN)

	# Convert to tiles
	var tiles := river.segments_to_tiles(segments, 16.0)
	return tiles


## Example: Generate terrain with WFC
static func example_wfc_terrain() -> Array[Array]:
	var wfc := WFCSimple.new()
	wfc.setup_basic_terrain()

	# Force water on one edge
	var constraints := {
		Vector2i(0, 7): "water",
		Vector2i(0, 8): "water",
		Vector2i(1, 7): "sand",
		Vector2i(1, 8): "sand",
	}

	var grid := wfc.generate_with_constraints(20, 15, constraints)
	return grid


## Example: Combined generation (realistic route)
static func example_combined_route() -> Dictionary:
	var seed_value := 12345
	var width := 40
	var height := 30
	var tile_sz := 16

	# 1. Base terrain with noise
	var terrain_noise := NoiseTerrain.new(seed_value)
	terrain_noise.apply_preset(NoiseTerrain.NoisePreset.GRASS_PATCHES)

	# 2. River with L-system
	var river := LSystem.new(seed_value + 1)
	river.set_river_preset()
	var river_segments := river.generate_and_interpret(
		Vector2(width * tile_sz / 2, 0), Vector2.DOWN
	)
	var river_tiles := river.segments_to_tiles(river_segments, tile_sz)

	# 3. Trees with Poisson (avoiding river)
	var tree_sampler := PoissonDisk.new(seed_value + 2)
	var tree_bounds := Rect2(0, 0, width * tile_sz, height * tile_sz)

	var river_set := {}
	for tile in river_tiles:
		river_set[tile] = true

	var is_valid_tree_spot := func(pos: Vector2) -> bool:
		var tile := Vector2i(int(pos.x / tile_sz), int(pos.y / tile_sz))
		# Not in river, and in "forest" noise area
		return not river_set.has(tile) and terrain_noise.sample(pos.x, pos.y) > 0.5

	var tree_positions := tree_sampler.generate_filtered(
		tree_bounds, 48.0, is_valid_tree_spot
	)

	return {
		"terrain_noise": terrain_noise,
		"river_tiles": river_tiles,
		"tree_positions": tree_positions
	}

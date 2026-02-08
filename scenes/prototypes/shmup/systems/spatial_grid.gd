extends RefCounted
## Spatial hash grid for fast radius queries over enemies.
## Divides world into cells; insert entities each frame, then
## query_radius or get_nearest in O(cells_checked) instead of O(n).

const CELL_SIZE := 100.0
const INV_CELL := 1.0 / CELL_SIZE

# Dictionary[Vector2i, Array[Area2D]]
var _cells: Dictionary = {}


func clear() -> void:
	_cells.clear()


func insert(entity: Area2D, pos: Vector2) -> void:
	var key := Vector2i(
		floori(pos.x * INV_CELL),
		floori(pos.y * INV_CELL),
	)
	if _cells.has(key):
		_cells[key].append(entity)
	else:
		_cells[key] = [entity]


## Return all entities within radius of pos.
func query_radius(
	pos: Vector2, radius: float,
) -> Array:
	var results: Array = []
	var r_sq := radius * radius
	var min_c := Vector2i(
		floori((pos.x - radius) * INV_CELL),
		floori((pos.y - radius) * INV_CELL),
	)
	var max_c := Vector2i(
		floori((pos.x + radius) * INV_CELL),
		floori((pos.y + radius) * INV_CELL),
	)
	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var key := Vector2i(cx, cy)
			if not _cells.has(key):
				continue
			var arr: Array = _cells[key]
			for e in arr:
				var ent: Area2D = e as Area2D
				if not ent:
					continue
				var d_sq := pos.distance_squared_to(
					ent.position,
				)
				if d_sq <= r_sq:
					results.append(ent)
	return results


## Return the nearest entity within radius, or null.
func get_nearest(
	pos: Vector2, radius: float,
) -> Area2D:
	var best: Area2D = null
	var best_sq := radius * radius
	var min_c := Vector2i(
		floori((pos.x - radius) * INV_CELL),
		floori((pos.y - radius) * INV_CELL),
	)
	var max_c := Vector2i(
		floori((pos.x + radius) * INV_CELL),
		floori((pos.y + radius) * INV_CELL),
	)
	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var key := Vector2i(cx, cy)
			if not _cells.has(key):
				continue
			var arr: Array = _cells[key]
			for e in arr:
				var ent: Area2D = e as Area2D
				if not ent:
					continue
				var d_sq := pos.distance_squared_to(
					ent.position,
				)
				if d_sq < best_sq:
					best_sq = d_sq
					best = ent
	return best

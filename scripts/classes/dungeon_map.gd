class_name DungeonMap
extends TileMapLayer

const TILE_SIZE: int = 32
const GRID_WIDTH: int = 36
const GRID_HEIGHT: int = 20

var astar: AStarGrid2D
var walkable_cells: Array[Vector2i] = []

func _ready() -> void:
	_setup_tileset()
	build_arena()

func _setup_tileset() -> void:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load("res://assets/sprites/tileset.png")
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_source(source, 0)

	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.create_tile(Vector2i(2, 0))

	var wall_data: TileData = source.get_tile_data(Vector2i(2, 0), 0)
	wall_data.add_collision_polygon(0)
	var half: float = TILE_SIZE / 2.0
	wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half)
	]))

	tile_set = ts

func build_arena() -> void:
	clear()
	walkable_cells.clear()

	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT)
	astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	var pillar_rects: Array[Rect2i] = [
		Rect2i(7, 4, 2, 3),
		Rect2i(27, 4, 2, 3),
		Rect2i(7, 13, 2, 3),
		Rect2i(27, 13, 2, 3),
		Rect2i(14, 6, 2, 2),
		Rect2i(20, 6, 2, 2),
		Rect2i(14, 12, 2, 2),
		Rect2i(20, 12, 2, 2)
	]

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell: Vector2i = Vector2i(x, y)
			var is_border: bool = (x == 0 or x == GRID_WIDTH - 1 or y <= 1 or y == GRID_HEIGHT - 1)
			var is_pillar: bool = false
			for rect in pillar_rects:
				if rect.has_point(cell):
					is_pillar = true
					break

			if is_border or is_pillar:
				set_cell(cell, 0, Vector2i(2, 0))
				astar.set_point_solid(cell, true)
			else:
				var atlas_coord: Vector2i = Vector2i(0, 0)
				if (x + y) % 5 == 0:
					atlas_coord = Vector2i(1, 0)
				set_cell(cell, 0, atlas_coord)
				astar.set_point_solid(cell, false)
				walkable_cells.append(cell)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var gx: int = clampi(int(world_pos.x / float(TILE_SIZE)), 0, GRID_WIDTH - 1)
	var gy: int = clampi(int(world_pos.y / float(TILE_SIZE)), 0, GRID_HEIGHT - 1)
	return Vector2i(gx, gy)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		float(cell.x * TILE_SIZE) + float(TILE_SIZE) * 0.5,
		float(cell.y * TILE_SIZE) + float(TILE_SIZE) * 0.5
	)

func get_navigation_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	if astar == null:
		return PackedVector2Array()
	var start_cell: Vector2i = _find_nearest_walkable(world_to_cell(from_world))
	var end_cell: Vector2i = _find_nearest_walkable(world_to_cell(to_world))
	var raw_path: PackedVector2Array = astar.get_point_path(start_cell, end_cell)
	var world_path: PackedVector2Array = PackedVector2Array()
	var half_offset: Vector2 = Vector2(float(TILE_SIZE) * 0.5, float(TILE_SIZE) * 0.5)
	for pt in raw_path:
		world_path.append(pt + half_offset)
	return world_path

func _find_nearest_walkable(cell: Vector2i) -> Vector2i:
	if not astar.is_point_solid(cell):
		return cell
	for radius in range(1, 5):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var candidate: Vector2i = Vector2i(
					clampi(cell.x + dx, 1, GRID_WIDTH - 2),
					clampi(cell.y + dy, 2, GRID_HEIGHT - 2)
				)
				if not astar.is_point_solid(candidate):
					return candidate
	return Vector2i(18, 10)

func get_random_free_world_pos(avoid_pos: Vector2, min_dist: float) -> Vector2:
	if walkable_cells.is_empty():
		return Vector2(576.0, 320.0)
	for _attempt in range(40):
		var cell: Vector2i = walkable_cells[randi() % walkable_cells.size()]
		var pos: Vector2 = cell_to_world(cell)
		if pos.distance_to(avoid_pos) >= min_dist:
			return pos
	var fallback_cell: Vector2i = walkable_cells[randi() % walkable_cells.size()]
	return cell_to_world(fallback_cell)

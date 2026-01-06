extends Node2D

# --- Map generation settings ---
var width = 100
var height = 100
var fill_chance = 0.55
var smooth_iterations = 4
var current_map = []
var tile_variations = []

# --- TileMap settings ---
const TILEMAP_LAYER = 0
const FLOOR_SOURCE_ID = 0
const WALL_SOURCE_ID = 1

@onready var tilemap: TileMap = $TileMap

# --- Player ---
var player_scene = preload("res://player.tscn")
var player_instance = null
var enemy_scene = preload("res://enemy/enemy.tscn")

# --- Visibility tracking ---
var revealed: Array = []

func _ready():
	tile_variations = []
	for y in range(height):
		tile_variations.append([])
		for x in range(width):
			tile_variations[y].append(-1)
	# Initialize revealed array
	revealed = []
	for y in range(height):
		revealed.append([])
		for x in range(width):
			revealed[y].append(false)
	
	current_map = generate_map(width, height)
	current_map = smooth_map(current_map, smooth_iterations)
	
	spawn_player(current_map) 
	spawn_enemies(current_map, enemy_scene, 10)
	spawn_enemy_near_player(enemy_scene, Vector2(50, 0))  # spawn 10 enemies
	draw_map_from_array(current_map)
	player_instance.connect("request_tile_break", Callable(self, "destroy_tile_at_world_pos"))

func spawn_enemy_near_player(enemy_scene: PackedScene, offset: Vector2 = Vector2(50, 0)) -> void:


	var enemy_instance = enemy_scene.instantiate()
	# Place it relative to the player
	enemy_instance.global_position = player_instance.global_position + offset
	add_child(enemy_instance)
# --- Map generation ---

func generate_map(map_width: int, map_height: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var map = []
	for y in range(map_height):
		map.append([])
		for x in range(map_width):
			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				map[y].append(1)
			else:
				map[y].append(1 if rng.randf() < fill_chance else 0)
	return map

func smooth_map(map: Array, iterations: int) -> Array:
	var map_width = map[0].size()
	var map_height = map.size()
	var current_map = map.duplicate(true)
	
	for i in range(iterations):
		var new_map = []
		for y in range(map_height):
			new_map.append([])
			for x in range(map_width):
				var wall_count = count_walls_around(current_map, x, y)
				if wall_count > 4:
					new_map[y].append(1)
				elif wall_count < 4:
					new_map[y].append(0)
				else:
					new_map[y].append(current_map[y][x])
		current_map = new_map
	return current_map
	
func spawn_enemies(map: Array, enemy_scene: PackedScene, count: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var spawned = 0
	var attempts = 0
	var max_attempts = count * 10  # avoid infinite loops

	while spawned < count and attempts < max_attempts:
		attempts += 1
		var x = rng.randi_range(0, width - 1)
		var y = rng.randi_range(0, height - 1)
		
		# Only spawn on floor tiles and not on walls
		if map[y][x] != 0:
			continue
		
		# Optional: don't spawn too close to player
		var player_cell = tilemap.local_to_map(player_instance.position)
		if Vector2i(x, y).distance_to(player_cell) < 5:
			continue
		
		# Instantiate enemy
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.position = tilemap.map_to_local(Vector2i(x, y))
		add_child(enemy_instance)
		spawned += 1
	

func count_walls_around(map: Array, x: int, y: int) -> int:
	var count = 0
	var map_width = map[0].size()
	var map_height = map.size()
	for ny in range(y - 1, y + 2):
		for nx in range(x - 1, x + 2):
			if nx == x and ny == y:
				continue
			if nx < 0 or ny < 0 or nx >= map_width or ny >= map_height:
				count += 1
			elif map[ny][nx] == 1:
				count += 1
	return count

# --- Flood-fill visibility ---

func reveal_area_from(pos: Vector2i, map: Array):
	var queue = [pos]
	while queue.size() > 0:
		var current = queue.pop_front()
		var x = current.x
		var y = current.y
		
		if x < 0 or y < 0 or x >= width or y >= height:
			continue
		if revealed[y][x]:
			continue
		if map[y][x] == 1:
			continue  # wall
		
		revealed[y][x] = true
		
		# Add neighboring tiles
		queue.append(Vector2i(x + 1, y))
		queue.append(Vector2i(x - 1, y))
		queue.append(Vector2i(x, y + 1))
		queue.append(Vector2i(x, y - 1))

# --- Drawing ---

func draw_map_from_array(map: Array) -> void:
	tilemap.clear_layer(TILEMAP_LAYER)
	
	for y in range(map.size()):
		for x in range(map[0].size()):
			if revealed[y][x]:
				# --- Floor tiles ---
				if map[y][x] == 0:
					# Assign variation if not already set
					if tile_variations[y][x] == -1:
						tile_variations[y][x] = 1 + randi() % 7
					var alt_id = tile_variations[y][x]
					tilemap.set_cell(TILEMAP_LAYER, Vector2i(x, y), FLOOR_SOURCE_ID, Vector2i(0, 0), alt_id)
				
				# --- Wall tiles around this floor ---
				for ny in range(y - 1, y + 2):
					for nx in range(x - 1, x + 2):
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							continue
						if map[ny][nx] == 1:
							# Assign wall variation if not already set
							if tile_variations[ny][nx] == -1:
								tile_variations[ny][nx] = 1 + randi() % 7
							var wall_alt_id = tile_variations[ny][nx]
							tilemap.set_cell(TILEMAP_LAYER, Vector2i(nx, ny), WALL_SOURCE_ID, Vector2i(0, 0), wall_alt_id)

# --- Player spawn ---

func spawn_player(map: Array):
	if player_instance:
		player_instance.queue_free()
	
	player_instance = player_scene.instantiate()
	add_child(player_instance)
	
	var spawn_pos = find_valid_spawn_point(map)
	player_instance.position = tilemap.map_to_local(spawn_pos)
	
	# Reveal connected area immediately
	reveal_area_from(spawn_pos, map)

func find_valid_spawn_point(map: Array) -> Vector2i:
	var start_x = width / 2
	var start_y = height / 2
	
	for r in range(max(width, height)):
		for y in range(start_y - r, start_y + r + 1):
			for x in range(start_x - r, start_x + r + 1):
				if x >= 0 and x < width and y >= 0 and y < height:
					if map[y][x] == 0:
						return Vector2i(x, y)
	
	return Vector2i(1, 1)
	
func destroy_tile_at_world_pos(world_pos: Vector2) -> void:
	var local_pos = tilemap.to_local(world_pos)
	var cell : Vector2i = tilemap.local_to_map(local_pos)

	# Check if there is a wall in the map array, not just the TileMap
	if current_map[cell.y][cell.x] != WALL_SOURCE_ID:
		print("No wall tile at ", cell)
		return
	if cell.x == 0 or cell.y == 0 or cell.x == width - 1 or cell.y == height - 1:
		print("Cannot destroy border tile at ", cell)
		return	

	# Update the map array
	current_map[cell.y][cell.x] = FLOOR_SOURCE_ID

	# Update the TileMap visually
	tilemap.set_cell(TILEMAP_LAYER, cell, FLOOR_SOURCE_ID)

	# Reveal newly accessible area from this tile
	reveal_area_from(cell, current_map)

	# Redraw all revealed tiles
	draw_map_from_array(current_map)

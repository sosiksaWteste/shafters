extends Node2D

# --- Map generation settings ---
var width = 100
var height = 100
var fill_chance = 0.55
var smooth_iterations = 4

# --- TileMap settings ---
const TILEMAP_LAYER = 0
const FLOOR_SOURCE_ID = 0
const WALL_SOURCE_ID = 1

@onready var tilemap: TileMap = $TileMap

# --- Player ---
var player_scene = preload("res://player.tscn")
var player_instance = null

# --- Visibility tracking ---
var revealed: Array = []

func _ready():
	# Initialize revealed array
	revealed = []
	for y in range(height):
		revealed.append([])
		for x in range(width):
			revealed[y].append(false)
	
	var map = generate_map(width, height)
	map = smooth_map(map, smooth_iterations)
	
	spawn_player(map)   # spawn first to get spawn_pos
	draw_map_from_array(map)  # draw revealed tiles

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
				# Draw the floor
				if map[y][x] == 0:
					var alt_id = 1 + randi() % 7
					tilemap.set_cell(TILEMAP_LAYER, Vector2i(x, y), FLOOR_SOURCE_ID, Vector2i(0, 0), alt_id)
				
				# Also draw walls around this tile
				for ny in range(y - 1, y + 2):
					for nx in range(x - 1, x + 2):
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							continue
						if map[ny][nx] == 1:
							var wall_alt_id = 1 + randi() % 7
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

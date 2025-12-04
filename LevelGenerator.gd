extends Node2D

# --- Настройки генерации ---
var width = 100
var height = 100
var fill_chance = 0.55
var smooth_iterations = 4

# --- Настройки TileMap ---
const TILEMAP_LAYER = 0
# Твои настройки (Пол = 0, Стена = 1)
const FLOOR_SOURCE_ID = 0 
const WALL_SOURCE_ID = 1
const TILE_COORDS = Vector2i(0, 0)

@onready var tilemap: TileMap = $TileMap

# --- Игрок ---
var player_scene = preload("res://player.tscn")
var player_instance = null

func _ready():
	var map = generate_map(width, height)
	map = smooth_map(map, smooth_iterations)
	
	draw_map_from_array(map)
	spawn_player(map)
	# Мы убрали center_and_zoom_map(), камера теперь на игроке

# --- Генерация ---

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

# --- Отрисовка ---

func draw_map_from_array(map: Array) -> void:
	tilemap.clear_layer(TILEMAP_LAYER)
	
	for y in range(map.size()):
		for x in range(map[0].size()):
			if map[y][x] == 1:
				# СТЕНА (ID 1)
				tilemap.set_cell(TILEMAP_LAYER, Vector2i(x, y), WALL_SOURCE_ID, TILE_COORDS)
			else:
				# ПОЛ (ID 0)
				tilemap.set_cell(TILEMAP_LAYER, Vector2i(x, y), FLOOR_SOURCE_ID, TILE_COORDS)

# --- Спавн игрока ---

func spawn_player(map: Array):
	if player_instance:
		player_instance.queue_free()
	
	player_instance = player_scene.instantiate()
	add_child(player_instance)
	
	var spawn_pos = find_valid_spawn_point(map)
	player_instance.position = tilemap.map_to_local(spawn_pos)

func find_valid_spawn_point(map: Array) -> Vector2i:
	var start_x = width / 2
	var start_y = height / 2
	
	for r in range(max(width, height)):
		for y in range(start_y - r, start_y + r + 1):
			for x in range(start_x - r, start_x + r + 1):
				if x >= 0 and x < width and y >= 0 and y < height:
					# Ищем 0 (пол)
					if map[y][x] == 0:
						return Vector2i(x, y)
	
	return Vector2i(1, 1)

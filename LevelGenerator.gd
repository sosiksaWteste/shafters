extends Node2D 
var pickup_scene = preload("res://items/pickup/pickup.tscn")
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
const GOLD_SOURCE_ID = 3

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
	#spawn_enemy_near_player(enemy_scene)
	var total_gold = 0
	while total_gold < 280:
		total_gold += generate_gold_veins(current_map, 1, 5, 12)
	print("Total gold tiles generated: ", total_gold)
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
	
func generate_gold_veins(map: Array, vein_count: int = 5, min_vein_length: int = 5, max_vein_length: int = 15) -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var gold_tiles = 0  # total gold counter

	for v in range(vein_count):
		# Pick a random wall tile (ignore borders)
		var x = rng.randi_range(1, width - 2)
		var y = rng.randi_range(1, height - 2)
		while map[y][x] != WALL_SOURCE_ID:
			x = rng.randi_range(1, width - 2)
			y = rng.randi_range(1, height - 2)

		var vein_tiles = [Vector2i(x, y)]
		var vein_length = rng.randi_range(min_vein_length, max_vein_length)

		for i in range(vein_length):
			if vein_tiles.size() == 0:
				break

			var index = rng.randi_range(0, vein_tiles.size() - 1)
			var tile = vein_tiles[index]

			# Replace with gold if still a wall
			if map[tile.y][tile.x] == WALL_SOURCE_ID:
				map[tile.y][tile.x] = GOLD_SOURCE_ID
				gold_tiles += 1

			# Add neighboring walls
			var neighbors = [
				Vector2i(tile.x + 1, tile.y),
				Vector2i(tile.x - 1, tile.y),
				Vector2i(tile.x, tile.y + 1),
				Vector2i(tile.x, tile.y - 1)
			]

			for n in neighbors:
				if n.x > 0 and n.x < width - 1 and n.y > 0 and n.y < height - 1:
					if map[n.y][n.x] == WALL_SOURCE_ID:
						vein_tiles.append(n)

			# Remove the processed tile
			vein_tiles.remove_at(index)

	return gold_tiles

	
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
		if map[y][x] == WALL_SOURCE_ID or map[y][x] == GOLD_SOURCE_ID:
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
				var tile_id = map[y][x]

				# --- Floor tiles ---
				if tile_id == FLOOR_SOURCE_ID:
					if tile_variations[y][x] == -1:
						tile_variations[y][x] = 1 + randi() % 7
					var alt_id = tile_variations[y][x]
					tilemap.set_cell(TILEMAP_LAYER, Vector2i(x, y), FLOOR_SOURCE_ID, Vector2i(0, 0), alt_id)

				# --- Walls and gold adjacent to floors ---
				for ny in range(y - 1, y + 2):
					for nx in range(x - 1, x + 2):
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							continue

						var neighbor_id = map[ny][nx]

						if neighbor_id == WALL_SOURCE_ID or neighbor_id == GOLD_SOURCE_ID:
							if tile_variations[ny][nx] == -1:
								tile_variations[ny][nx] = 1 + randi() % 7
							var alt_id = tile_variations[ny][nx]

							if neighbor_id == WALL_SOURCE_ID:
								tilemap.set_cell(TILEMAP_LAYER, Vector2i(nx, ny), WALL_SOURCE_ID, Vector2i(0, 0), alt_id)
							else: # GOLD_SOURCE_ID
								tilemap.set_cell(TILEMAP_LAYER, Vector2i(nx, ny), GOLD_SOURCE_ID, Vector2i(0, 0), alt_id)

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

	if cell.x <= 0 or cell.y <= 0 or cell.x >= width - 1 or cell.y >= height - 1:
		print("Cannot destroy border tile at ", cell)
		return	
	# Check if there is a wall in the map array, not just the TileMap
	var tile_id = current_map[cell.y][cell.x]

	# Only destroy walls or gold
	if tile_id != WALL_SOURCE_ID and tile_id != GOLD_SOURCE_ID:
		print("No wall or gold tile at ", cell)
		return
		
	if tile_id == GOLD_SOURCE_ID:
		drop_gold_at(cell)  # drop the gold pickup

	#if tile_id == GOLD_SOURCE_ID:
		

	# Update the map array
	current_map[cell.y][cell.x] = FLOOR_SOURCE_ID

	# Update the TileMap visually
	tilemap.set_cell(TILEMAP_LAYER, cell, FLOOR_SOURCE_ID)

	# Reveal newly accessible area from this tile
	reveal_area_from(cell, current_map)

	# Redraw all revealed tiles
	draw_map_from_array(current_map)
	
func restart_scene():
	get_tree().reload_current_scene()
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			restart_scene()	
			
func drop_gold_at(cell: Vector2i):
	if not pickup_scene:
		return

	var pickup = pickup_scene.instantiate()
	
	# Set the item type to a gold resource (create an ItemData for gold if you don't have one)
	var gold_item = preload("res://items/resources/goldOre.tres")  # or whatever your gold item is
	pickup.item_data = gold_item

	# Place pickup in the world (center of tile + optional random offset)
	var tile_pos = tilemap.map_to_local(cell)
	var random_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	pickup.global_position = tile_pos + random_offset

	# Add to scene
	get_parent().add_child(pickup)

	# Temporarily disable pickup (if your Pickup has that function)
	if pickup.has_method("disable_pickup_temporarily"):
		pickup.disable_pickup_temporarily(0.7)

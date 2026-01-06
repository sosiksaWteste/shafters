extends StaticBody2D # или Area2D

@onready var inventory = $Inventory
var current_user = null

# Зона взаимодействия (если используешь Area2D для клика или подхода)
# Допустим, используем input_event как у Генератора
func _ready():
	input_pickable = true

func _process(delta):
	# Если сундук кем-то открыт
	if current_user != null:
		var distance = global_position.distance_to(current_user.global_position)
		# Если отошли дальше 150 пикселей (настрой под себя)
		if distance > 150:
			close_chest()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().current_scene.get_node("Player") # Или как ты находишь игрока
		if global_position.distance_to(player.global_position) < 100:
			toggle_chest(player)

func toggle_chest(player):
	var ui = player.inventory_ui
	
	# Если мы уже открыли ЭТОТ сундук
	if ui.external_panel.visible and ui.external_inventory_ref == inventory:
		close_chest()
	else:
		open_chest(player)

func open_chest(player):
	current_user = player
	player.inventory_ui.open_external_inventory(inventory)

func close_chest():
	if current_user:
		current_user.inventory_ui.close_external_inventory()
		current_user = null
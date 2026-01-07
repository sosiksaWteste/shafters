extends StaticBody2D

signal lamp_toggled(is_on: bool)
signal clicked(lamp)

const FUEL_CONSUMPTION_RATE = 0.5  # Fuel per second when lamp is on

var is_on = false
var player_in_range = false
var connected_generator = null  # Reference to connected generator
var is_connected = false  # Whether lamp is connected to a generator

@onready var interaction_area = $InteractionArea
@onready var light = $LampPointLight2D
@onready var light2 = $LampPointLight2D2
var light_area: Area2D
var light_collision: CollisionShape2D

func _ready() -> void:
	# Connect interaction area signals

	if ConnectionManager:
		clicked.connect(ConnectionManager.on_lamp_clicked)
	
	light_area = Area2D.new()
	light_area.name = "LightArea2D"
	light_area.monitorable = true
	light_area.monitoring = is_on
	add_child(light_area)
	light_area.add_to_group("light_areas")  # enemies can find all lights

	light_collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	light_collision.shape = circle
	light_area.add_child(light_collision)
	light_collision.disabled = not is_on  # off when lamp off
	update_visual()
	

func _draw():
	# Draw small 8x8 rectangle lamp
	var lamp_color = Color.YELLOW if is_on else Color.DARK_GRAY
	draw_rect(Rect2(-4, -4, 8, 8), lamp_color)

func _process(delta: float) -> void:
	# Handle player interaction input
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		toggle()

func toggle():
	is_on = !is_on
	update_visual()
	lamp_toggled.emit(is_on)

func turn_on():
	if not is_on:
		is_on = true
		update_visual()
		lamp_toggled.emit(true)

func turn_off():
	if is_on:
		is_on = false
		update_visual()
		lamp_toggled.emit(false)

func update_visual():
	queue_redraw()  # redraw lamp rectangle
	
	if light:
		light.enabled = is_on
		light2.enabled = is_on
		if is_on:
			light.color = Color.YELLOW
			light.energy = 4.0
			light2.color = Color.YELLOW
			light2.energy = 0.15

	# --- Sync the collision area ---
	if light_area and light_collision:
		light_area.monitoring = is_on
		light_collision.disabled = not is_on
		# Update radius to match visual light energy
		var circle = light_collision.shape as CircleShape2D
		circle.radius = light.energy * 35


func on_generator_state_changed(generator_is_on: bool):
	# Called when connected generator changes state
	if is_connected:
		if generator_is_on:
			turn_on()
		else:
			turn_off()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Lamp clicked at: ", global_position)
			clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click to disconnect from generator
			if is_connected and connected_generator:
				print("Disconnecting lamp from generator")
				ConnectionManager.disconnect_wire(connected_generator, self)

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

func _ready() -> void:
	# Connect interaction area signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	if ConnectionManager:
		clicked.connect(ConnectionManager.on_lamp_clicked)
	
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
	queue_redraw()  # Redraw the rectangle
	
	if light:
		light.enabled = is_on
		light2.enabled = is_on
		if is_on:
			light.color = Color.YELLOW
			light.energy = 4.0
			light2.color = Color.YELLOW
			light2.energy = 0.15

func on_generator_state_changed(generator_is_on: bool):
	# Called when connected generator changes state
	if is_connected:
		if generator_is_on:
			turn_on()
		else:
			turn_off()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

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

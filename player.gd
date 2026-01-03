extends CharacterBody2D

const SPEED = 150.0
@export var affliction_ui: AfflictionDisplay
const MAX_FLASHLIGHT_ENERGY = 4.0
const MIN_FLASHLIGHT_ENERGY = 0.5
const POWER_DRAIN_RATE = 5.0  # Power per second when flashlight is on

var flashlight_power = 100.0  # 0-100%
var flashlight_on = true

@onready var flashlight = $FlashlightPointLight2D
@onready var flashlight2 = $FlashlightPointLight2D2
@onready var power_bar = $CanvasLayer/MarginContainer/VBoxContainer/ProgressBar

func _ready():
	var bleed := Bleed.new(21)
	$Limbs/Lleg.add_affliction(bleed)
	affliction_ui = get_tree().current_scene.get_node("CanvasLayer/AfflictionsUI")
	queue_redraw()
	update_flashlight()

func _physics_process(delta):
	# Handle flashlight power
	if flashlight_on and flashlight_power > 0:
		flashlight_power -= POWER_DRAIN_RATE * delta
		flashlight_power = max(0, flashlight_power)
		update_flashlight()
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	look_at(get_global_mouse_position())

	move_and_slide()

func update_flashlight():
	# Update power bar
	power_bar.value = flashlight_power
	
	if flashlight_power <= 0:
		# Turn off flashlight at 0%
		flashlight.enabled = false
		flashlight2.enabled = false
	else:
		flashlight.enabled = true
		flashlight2.enabled = true
		
		var energy
		if flashlight_power > 10:
			# 100% -> 10%: scale from 4.0 to 2.0
			var normalized = (flashlight_power - 10) / 90.0  # 0 to 1 range
			energy = lerp(1.5, MAX_FLASHLIGHT_ENERGY, normalized)
		else:
			# 10% -> 0%: scale from 2.0 to 0.5
			var normalized = flashlight_power / 10.0  # 0 to 1 range
			energy = lerp(MIN_FLASHLIGHT_ENERGY, 1.5, normalized)
		
		flashlight.energy = energy
		# Scale the second flashlight proportionally (it was 0.15 relative to 4.0)
		flashlight2.energy = energy * 0.05

func _draw():
	draw_circle(Vector2.ZERO, 15, Color.RED)
	
func _input(event: InputEvent):
	if event.is_action_pressed("HealthUI"):
		if affliction_ui:
			affliction_ui.toggle_for_player(self)

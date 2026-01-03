extends CharacterBody2D

const SPEED = 150.0
const MAX_FLASHLIGHT_ENERGY = 4.0
const MIN_FLASHLIGHT_ENERGY = 0.5
const POWER_DRAIN_RATE = 5.0  # Power per second when flashlight is on

var flashlight_power = 100.0  # 0-100%
var flashlight_on = true

@onready var flashlight = $FlashlightPointLight2D
@onready var flashlight2 = $FlashlightPointLight2D2

func _ready():
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
	if flashlight_power <= 0:
		# Turn off flashlight at 0%
		flashlight.enabled = false
		flashlight2.enabled = false
	else:
		flashlight.enabled = true
		flashlight2.enabled = true
		
		# Scale energy from MAX (4.0) at 100% to MIN (2.0) at 0%
		var power_percent = flashlight_power / 100.0
		var energy = lerp(MIN_FLASHLIGHT_ENERGY, MAX_FLASHLIGHT_ENERGY, power_percent)
		
		flashlight.energy = energy
		# Scale the second flashlight proportionally (it was 0.15 relative to 4.0)
		flashlight2.energy = energy * 0.0375

func _draw():
	draw_circle(Vector2.ZERO, 12, Color.RED)

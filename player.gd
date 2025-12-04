extends CharacterBody2D

const SPEED = 150.0

func _ready():
	queue_redraw()

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _draw():
	draw_circle(Vector2.ZERO, 15, Color.RED)

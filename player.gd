extends CharacterBody2D

const SPEED = 150.0
@export var affliction_ui: AfflictionDisplay

func _ready():
	var bleed := Bleed.new(21)
	$Limbs/Lleg.add_affliction(bleed)
	affliction_ui = get_tree().current_scene.get_node("CanvasLayer/AfflictionsUI")
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
	
func _input(event: InputEvent):
	if event.is_action_pressed("HealthUI"):
		if affliction_ui:
			affliction_ui.toggle_for_player(self)

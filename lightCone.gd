extends Area2D

@export var cone_length = 512
@export var cone_width = 320

func _ready():
	add_to_group("light_areas")
	# Define triangle points relative to the Area2D origin
	var half_width = cone_width / 2
	var points = [
		Vector2.ZERO,                  # tip of the cone (player/light origin)
		Vector2(cone_length, -half_width),  # left corner
		Vector2(cone_length, half_width)    # right corner
	]
	$CollisionPolygon2D.polygon = points

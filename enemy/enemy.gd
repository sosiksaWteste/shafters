extends CharacterBody2D

@export var speed: float = 120           # speed toward player
@export var flee_speed: float = 200      # speed when fleeing light
@export var flee_duration: float = 2.0   # seconds to keep fleeing after leaving light

var is_fleeing: bool = false
var flee_target: Vector2 = Vector2.ZERO
var flee_timer: float = 0.0              # counts down when fleeing

@onready var player_instance = get_tree().current_scene.get_node("Player")  # adjust path if needed

func _physics_process(delta):
	if not player_instance:
		return

	# check if enemy is in any light
	var light_info = check_lights()
	var in_light = light_info[0]
	var closest_light_pos = light_info[1]

	if in_light:
		# started fleeing or refreshed timer
		is_fleeing = true
		flee_target = closest_light_pos
		flee_timer = flee_duration
	elif flee_timer > 0:
		# keep fleeing for remaining time
		flee_timer -= delta
	else:
		# done fleeing
		is_fleeing = false

	if is_fleeing:
		move_away_from_light()
	else:
		chase_player()


# -----------------------
# Light detection using Area2D collisions
# -----------------------
func check_lights() -> Array:
	var in_light: bool = false
	var closest_pos: Vector2 = Vector2.ZERO
	var min_dist: float = INF

	for light_area in get_tree().get_nodes_in_group("light_areas"):
		if light_area.get_overlapping_bodies().has(self):
			var dist = global_position.distance_to(light_area.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_pos = light_area.global_position
				in_light = true

	return [in_light, closest_pos]


# -----------------------
# Movement logic
# -----------------------
func chase_player():
	var dir = (player_instance.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()


func move_away_from_light():
	var dir = (global_position - flee_target).normalized()
	velocity = dir * flee_speed
	move_and_slide()

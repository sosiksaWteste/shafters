extends Affliction
class_name Bleed

# Chance for hurt sound and blood effect to occur each update (0.0 - 1.0)
const HURT_CHANCE := 0.001

# Preload blood scene
var BloodScene = preload("res://Blood.tscn")

func _init(_severity := 0.0):
	id = "bleeding"
	severity = _severity

func update(limb, delta):
	if severity >= 100.0:
		limb.kill()

	if severity < 20.0:
		severity -= 0.1 * delta
	else:
		severity += 0.1 * delta

	# Only trigger if severity is high
	if severity > 80.0:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		
		if rng.randf() < HURT_CHANCE:
			var player = limb.get_parent().get_parent()

			# Play hurt sound if available and not already playing
			if player.has_node("Hurt"):
				var hurt_sound = player.get_node("Hurt") as AudioStreamPlayer2D
				if not hurt_sound.playing:
					hurt_sound.play()
			
			# Spawn blood splat at player's position
			if BloodScene:
				var blood_instance = BloodScene.instantiate()
				blood_instance.global_position = player.global_position

				# Randomize rotation and scale for variety
				blood_instance.rotation = rng.randf_range(0.0, TAU)
				blood_instance.scale = Vector2.ONE * rng.randf_range(0.8, 1.2)

				# Add to the scene (world-level, not attached to player)
				player.get_parent().add_child(blood_instance)

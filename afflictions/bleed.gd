extends Affliction
class_name Bleed

func _init(_severity := 0.0):
	id = "bleeding"
	severity = _severity

func update(limb, delta):
	if severity < 20:
		severity -= 0.1 * delta
	else:
		severity += 0.1 * delta

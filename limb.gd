extends Node
class_name Limb

var afflictions: Array[Affliction] = []

func _process(delta):
	for i in range(afflictions.size() - 1, -1, -1):
		var aff = afflictions[i]
		
		aff.update(self, delta)
		if aff.severity <= 0:
			afflictions.remove_at(i)


func add_affliction(new_aff: Affliction):
	for a in afflictions:
		if a.id == new_aff.id:
			a.severity += new_aff.severity
			if new_aff.duration > 0:
				a.duration = max(a.duration, new_aff.duration)
			return
	afflictions.append(new_aff)

func remove_affliction(id: String, amount: float):
	for a in afflictions:
		if a.id == id:
			a.severity -= amount
			if a.severity <= 0:
				afflictions.erase(a)
			return

func has_affliction(id: String) -> bool:
	for a in afflictions:
		if a.id == id:
			return true
	return false

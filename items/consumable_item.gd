extends ItemData
class_name ConsumableItem

@export var heal_amount: float = 10.0
@export var cures_bleed: bool = false

func use(target: Node) -> void:
	print("Использован расходник: ", name)
	# Тут позже допишем лечение через target.get_node("Limbs")
# FlashlightBattery.gd
extends ConsumableItem
class_name FlashlightBattery

@export var charge_amount: float = 100.0  # Amount of battery restored

func use(target: Node) -> void:
	target.flashlight_power = charge_amount
	target.update_flashlight()
	print("Flashlight recharged to ", charge_amount, "% for ", target.name)

# BleedCureItem.gd
extends ConsumableItem
class_name Bandage

@export var bleed_reduction: float = 40.0
	
func use(target: Node) -> void:
	print("Bleed Cure used on ", target.name)
	
	if target.has_node("Limbs"):
		var limbs_node = target.get_node("Limbs")
		var limb_order = ["Head", "Torso", "Lleg", "Rleg", "Larm", "Rarm"]
		
		for limb_name in limb_order:
			if limbs_node.has_node(limb_name):
				var limb = limbs_node.get_node(limb_name)
				if limb.has_affliction("bleeding"):
					limb.remove_affliction("bleeding", bleed_reduction)
					print("Bleed severity reduced by ", bleed_reduction, " on ", limb_name)
					return
		print("No bleeding found on any limb")

extends Resource
class_name ItemData

# The name of the item displayed in the UI
@export var name: String = "Item"
@export var stackable: bool = false
@export var max_stack_size: int = 1

# Description for tooltips or info panels
@export_multiline var description: String = ""

# The icon texture for the inventory slot
@export var icon: Texture2D

# Virtual function: implementation will depend on specific item types
# target: The Node that uses the item (usually the Player)
func use(target: Node) -> void:
	pass
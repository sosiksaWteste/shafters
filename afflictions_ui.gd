extends Control
class_name AfflictionDisplay

var player_reference: Node = null
var selected_limb: Limb = null

@onready var button_container := $Panel/HBoxContainer/VBoxContainer
@onready var afflictions_container := $Panel/HBoxContainer/VBoxContainer2

func _ready():
	visible = false

	for limb_name in ["Head", "Torso", "Larm", "Rarm", "Lleg", "Rleg"]:
		var button = Button.new()
		button.text = limb_name
		button_container.add_child(button)
		button.connect("pressed", Callable(self, "_on_limb_button_pressed").bind(limb_name))

func toggle_for_player(player: Node):
	visible = not visible
	player_reference = player
	if visible and selected_limb == null and player_reference.has_node("Head"):
		selected_limb = player_reference.get_node("Head")

func _process(delta):
	if not visible or selected_limb == null:
		return

	for child in afflictions_container.get_children():
		child.queue_free()

	for aff in selected_limb.afflictions:
		var label = Label.new()
		label.text = "%s: %.1f" % [aff.id, aff.severity]
		afflictions_container.add_child(label)

func _on_limb_button_pressed(limb_name: String):
	if player_reference == null:
		return
	var limbs_node = player_reference.get_node("Limbs")
	if limbs_node.has_node(limb_name):
		selected_limb = limbs_node.get_node(limb_name)
	else:
		print("Limb not found:", limb_name)

extends Node

# Connection state
var first_clicked_object = null  # First clicked generator or lamp
var connections: Dictionary = {}  # Generator -> Array of Lamps
var wires: Dictionary = {}  # Connection pair -> Wire node

# Wire scene
var wire_scene = preload("res://props/wire.tscn")

func _ready():
	print("ConnectionManager initialized")

func on_generator_clicked(generator):
	print("ConnectionManager: Generator clicked")
	
	if first_clicked_object == null:
		# First click - select generator
		first_clicked_object = generator
		highlight_object(generator, true)
		print("Selected generator, click a lamp to connect")
	elif first_clicked_object == generator:
		# Clicked same generator - deselect
		highlight_object(generator, false)
		first_clicked_object = null
		print("Deselected generator")
	else:
		# Second click - try to connect
		if first_clicked_object is StaticBody2D and first_clicked_object.has_signal("lamp_toggled"):
			# First was lamp, second is generator
			create_connection(generator, first_clicked_object)
			highlight_object(first_clicked_object, false)
			first_clicked_object = null

func on_lamp_clicked(lamp):
	print("ConnectionManager: Lamp clicked")
	
	if first_clicked_object == null:
		# First click - select lamp
		first_clicked_object = lamp
		highlight_object(lamp, true)
		print("Selected lamp, click a generator to connect")
	elif first_clicked_object == lamp:
		# Clicked same lamp - deselect
		highlight_object(lamp, false)
		first_clicked_object = null
		print("Deselected lamp")
	else:
		# Second click - try to connect
		if first_clicked_object is StaticBody2D and first_clicked_object.has_signal("generator_state_changed"):
			# First was generator, second is lamp
			create_connection(first_clicked_object, lamp)
			highlight_object(first_clicked_object, false)
			first_clicked_object = null

func create_connection(generator, lamp):
	print("Creating connection: Generator -> Lamp")
	
	# Add lamp to generator's connected lamps array
	if not connections.has(generator):
		connections[generator] = []
	
	if lamp in connections[generator]:
		print("Already connected!")
		return
	
	connections[generator].append(lamp)
	
	# Set lamp's connected generator
	lamp.connected_generator = generator
	lamp.is_connected = true
	
	# Connect generator state signal to lamp
	if not generator.generator_state_changed.is_connected(lamp.on_generator_state_changed):
		generator.generator_state_changed.connect(lamp.on_generator_state_changed)
	
	# Connect signal to update wire color
	if not generator.generator_state_changed.is_connected(_on_generator_state_changed.bind(generator)):
		generator.generator_state_changed.connect(_on_generator_state_changed.bind(generator))
	
	# Add lamp to generator's connected_lamps array
	if not lamp in generator.connected_lamps:
		generator.connected_lamps.append(lamp)
	
	# Create visual wire (will implement later)
	create_wire(generator, lamp)
	
	# Update lamp state based on generator
	if generator.is_on:
		lamp.turn_on()
	else:
		lamp.turn_off()
	
	print("Connection created successfully!")

func create_wire(generator, lamp):
	if not wire_scene:
		print("Wire scene not loaded!")
		return
	
	# Create wire instance
	var wire = wire_scene.instantiate()
	
	# Add to scene tree (as child of level/world)
	var level = generator.get_parent()
	level.add_child(wire)
	
	# Setup wire connection
	wire.setup(generator, lamp)
	
	# Store wire reference
	var connection_key = str(generator.get_instance_id()) + "_" + str(lamp.get_instance_id())
	wires[connection_key] = wire
	
	# Set initial power state
	wire.set_powered(generator.is_on)
	
	print("Wire visual created!")

func highlight_object(obj, enabled: bool):
	# Visual feedback for selected object
	if enabled:
		obj.modulate = Color(1.5, 1.5, 1.5)  # Brighten
	else:
		obj.modulate = Color(1, 1, 1)  # Normal

func get_total_lamp_consumption(generator) -> float:
	if not connections.has(generator):
		return 0.0
	
	var total = 0.0
	for lamp in connections[generator]:
		if lamp.is_on:
			total += lamp.FUEL_CONSUMPTION_RATE
	
	return total

func disconnect_wire(generator, lamp):
	print("Disconnecting generator from lamp")
	
	# Remove from connections
	if connections.has(generator):
		connections[generator].erase(lamp)
		if connections[generator].is_empty():
			connections.erase(generator)
	
	# Remove from generator's connected lamps
	if lamp in generator.connected_lamps:
		generator.connected_lamps.erase(lamp)
	
	# Disconnect signal
	if generator.generator_state_changed.is_connected(lamp.on_generator_state_changed):
		generator.generator_state_changed.disconnect(lamp.on_generator_state_changed)
	
	# Reset lamp state
	lamp.connected_generator = null
	lamp.is_connected = false
	lamp.turn_off()
	
	# Remove wire visual
	var connection_key = str(generator.get_instance_id()) + "_" + str(lamp.get_instance_id())
	if wires.has(connection_key):
		var wire = wires[connection_key]
		wire.queue_free()
		wires.erase(connection_key)
	
	print("Disconnection complete!")

func _on_generator_state_changed(is_on: bool, generator):
	# Update all wires connected to this generator
	if not connections.has(generator):
		return
	
	for lamp in connections[generator]:
		var connection_key = str(generator.get_instance_id()) + "_" + str(lamp.get_instance_id())
		if wires.has(connection_key):
			wires[connection_key].set_powered(is_on)

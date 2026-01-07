extends Node2D

var start_object = null  # Generator or lamp
var end_object = null    # Generator or lamp
var is_powered = false

@onready var line = $Line2D

func _ready():
	update_wire()

func setup(from_obj, to_obj):
	start_object = from_obj
	end_object = to_obj
	update_wire()

func _process(delta):
	# Update wire position every frame to follow objects
	update_wire()

func update_wire():
	if not start_object or not end_object or not line:
		return
	
	var start_pos = start_object.global_position
	var end_pos = end_object.global_position
	
	# Calculate rope sag (catenary-like curve)
	var points = calculate_rope_points(start_pos, end_pos)
	
	line.clear_points()
	for point in points:
		line.add_point(to_local(point))
	
	# Update color based on power state
	if is_powered:
		line.default_color = Color(1.0, 0.3, 0.3, 1.0)  # Bright red when powered
	else:
		line.default_color = Color(0.6, 0.1, 0.1, 0.8)  # Dark red when off

func calculate_rope_points(start: Vector2, end: Vector2) -> Array:
	var points = []
	var num_segments = 8  # More segments = smoother curve
	
	var distance = start.distance_to(end)
	var sag_amount = distance * 0.1  # 10% of distance for sag
	
	for i in range(num_segments + 1):
		var t = float(i) / float(num_segments)
		
		# Linear interpolation between start and end
		var point = start.lerp(end, t)
		
		# Add parabolic sag in the middle
		var sag = sin(t * PI) * sag_amount
		point.y += sag
		
		points.append(point)
	
	return points

func set_powered(powered: bool):
	is_powered = powered
	update_wire()

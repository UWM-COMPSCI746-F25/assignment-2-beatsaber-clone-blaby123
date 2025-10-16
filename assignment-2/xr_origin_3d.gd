extends XROrigin3D

signal pose_recentered

# ADD THESE VARIABLES
var spawn_timer: float = 0.0
var spawn_interval: float = 0.5  # Spawn every 0.5 seconds
var cube_speed: float = 6.0      # Speed, idk the units lol

func _ready():
	print("Laser swords ready! Left: Blue, Right: Red")
	set_lasers_active(true)
	
	# Connect button signals
	$left.button_pressed.connect(_on_left_button_pressed)
	$right.button_pressed.connect(_on_right_button_pressed)

func _process(delta):
	# Check left controller hits
	check_controller_hits($left, "blue")
	# Check right controller hits  
	check_controller_hits($right, "red")
	
	# Cube spawning and movement
	spawn_cubes(delta)
	move_cubes(delta)

func check_controller_hits(controller: XRController3D, sword_color: String):
	var raycast = controller.get_node("SwordRaycast") as RayCast3D
	if raycast and raycast.is_colliding():
		var hit_object = raycast.get_collider()
		if hit_object and hit_object.is_in_group("cubes"):
			handle_cube_hit(hit_object, sword_color)

func handle_cube_hit(cube, sword_color: String):
	# Get the cube node and its color
	var cube_node = cube.get_parent()
	var cube_color = cube_node.get_meta("cube_color")
	
	# ONLY destroy if colors match
	if cube_color == sword_color:
		cube_node.queue_free()
		$AudioStreamPlayer3D.play()
		print("SUCCESS: ", cube_color, " cube destroyed!")
	else:
		print("WRONG COLOR: ", cube_color, " cube hit with ", sword_color, " sword")

func set_lasers_active(active: bool):
	var left_visual = $left.get_node("LaserVisual")
	var left_raycast = $left.get_node("SwordRaycast")
	var right_visual = $right.get_node("LaserVisual")
	var right_raycast = $right.get_node("SwordRaycast")
	
	left_visual.visible = active
	left_raycast.enabled = active
	right_visual.visible = active
	right_raycast.enabled = active

# SPAWN CUBES OVER TIME
func spawn_cubes(delta: float):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		create_flying_cube()

# CREATE FLYING CUBES (like your test cube but moving)
func create_flying_cube():
	# Create the cube visual
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.mesh.size = Vector3(0.3, 0.3, 0.3)
	
	# Create collision
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(0.3, 0.3, 0.3)
	
	var static_body = StaticBody3D.new()
	static_body.add_child(collision)
	cube.add_child(static_body)
	
	# RANDOM POSITION at far end (>10 meters away)
	cube.position = Vector3(
		randf_range(-1.0, 1.0),   # Random X (-1 to 1 meters)
		randf_range(1.0, 2.0),    # Random Y (1 to 2 meters height)  
		-10.0                     # 10 meters away
	)
	
	# RANDOM COLOR (blue or red)
	var cube_color = "blue" if randf() > 0.5 else "red"
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE if cube_color == "blue" else Color.RED
	cube.material_override = material
	
	# Store color for hit detection
	cube.set_meta("cube_color", cube_color)
	
	# Add to cubes group
	static_body.add_to_group("cubes")
	
	add_child(cube)
	print("Spawned ", cube_color, " cube")

# MOVE ALL CUBES TOWARD PLAYER
func move_cubes(delta: float):
	for child in get_children():
		# Only move cubes (not controllers, camera, etc)
		if child is MeshInstance3D and child != $left.get_node("LaserVisual") and child != $right.get_node("LaserVisual"):
			child.position.z += cube_speed * delta
			
			# Destroy if it goes past the player (Step 8)
			if child.position.z > 2.0:
				child.queue_free()
				print("Cube missed!")


# ADD THIS FUNCTION - Proper OpenXR button detection
func _on_left_button_pressed(name: String) -> void:
	if name == "ax_button":  # X button on left controller
		toggle_single_laser($left, "left")

# ADD THIS FUNCTION TOO - For right controller
func _on_right_button_pressed(name: String) -> void:
	if name == "ax_button":  # A button on right controller  
		toggle_single_laser($right, "right")

# ADD THIS TOGGLE FUNCTION
func toggle_single_laser(controller: XRController3D, side: String):
	var visual = controller.get_node("LaserVisual")
	var raycast = controller.get_node("SwordRaycast")
	
	var new_state = !visual.visible
	visual.visible = new_state
	raycast.enabled = new_state
	
	print(side, " laser: ", "ON" if new_state else "OFF")

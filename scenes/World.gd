extends Node3D

@export var world_size := 2000
@export var seed := 12345

func _ready():
	randomize()
	generate_ground()
	generate_airport()
	generate_forests()
	generate_cities()

func generate_ground():
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	
	var mesh = MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.mesh.size = Vector2(world_size, world_size)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(world_size, 2, world_size)
	
	ground.add_child(mesh)
	ground.add_child(col)
	add_child(ground)

func generate_airport():
	var airport = Node3D.new()
	airport.name = "Airport"
	add_child(airport)
	
	var runway = preload("res://scenes/Runway.tscn").instantiate()
	runway.position = Vector3(0, 0, -200)
	runway.add_to_group("no_trees")
	runway.add_to_group("no_city")
	airport.add_child(runway)
	
	var terminal = preload("res://scenes/Runway.tscn").instantiate()
	terminal.position = Vector3(30, 0, -180)
	terminal.add_to_group("no_trees")
	terminal.add_to_group("no_city")
	airport.add_child(terminal)

func generate_forests():
	var forest_parent = Node3D.new()
	forest_parent.name = "Forests"
	add_child(forest_parent)
	
	for i in range(2000):
		var pos = random_world_position()
		
		if is_blocked(pos):
			continue
		
		var tree = preload("res://scenes/Tree.tscn").instantiate()
		tree.position = pos
		forest_parent.add_child(tree)

func is_blocked(pos: Vector3) -> bool:
	for node in get_tree().get_nodes_in_group("no_trees"):
		if node.global_position.distance_to(pos) < 30:
			return true
	return false

func generate_cities():
	var city_parent = Node3D.new()
	city_parent.name = "Cities"
	add_child(city_parent)
	
	for i in range(300):
		var pos = random_world_position()
		
		if pos.distance_to(Vector3.ZERO) < 400:
			continue
		
		var building = preload("res://scenes/Terminal.tscn").instantiate()
		building.position = pos
		city_parent.add_child(building)

func random_world_position() -> Vector3:
	return Vector3(
		randf_range(-world_size * 0.5, world_size * 0.5),
		0,
		randf_range(-world_size * 0.5, world_size * 0.5)
	)

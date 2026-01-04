extends Node3D

var chunk_coord: Vector2i
const SIZE := 256

var noise := FastNoiseLite.new()

func generate(coord: Vector2i):
	noise.seed = 12345
	noise.frequency = 0.002
	
	chunk_coord = coord
	position = Vector3(
		coord.x * SIZE,
		0,
		coord.y * SIZE
	)
	
	generate_ground()
	generate_content()

func generate_ground():
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	
	var mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh.mesh = plane
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.6, 0.2)
	mat.roughness = 1.0
	mesh.material_override = mat
	
	var col = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(SIZE, 2, SIZE)
	col.shape = shape
	
	ground.add_child(mesh)
	ground.add_child(col)
	add_child(ground)

func generate_content():
	var world_x = chunk_coord.x * SIZE
	var world_z = chunk_coord.y * SIZE
	
	var n = noise.get_noise_2d(world_x, world_z)
	
	if n < -0.2:
		generate_sea()
	elif n < 0.2:
		generate_forest()
	else:
		generate_city()

func generate_sea():
	var water = MeshInstance3D.new()
	water.mesh = PlaneMesh.new()
	water.mesh.size = Vector2(SIZE, SIZE)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#1e90ff")
	water.material_override = mat
	
	water.position.y = -1
	add_child(water)

func generate_forest():
	var forest := get_or_create("Forest")
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for x in range(0, SIZE, 10):
		for z in range(0, SIZE, 10):
			var wx = chunk_coord.x * SIZE + x
			var wz = chunk_coord.y * SIZE + z
			
			var density = noise.get_noise_2d(wx * 0.01, wz * 0.01)
			
			density = (density + 1.0) * 0.5
			
			if density > 0.45:
				var tree = tree_scene.instantiate()
				tree.position = Vector3(
					x + rng.randf_range(-3, 3),
					0,
					z + rng.randf_range(-3, 3)
				)
				tree.scale *= rng.randf_range(0.9, 1.4)
				forest.add_child(tree)

func generate_city():
	var city = $City
	var building_scene = preload("res://scenes/Terminal.tscn")
	
	for i in range(10):
		var b = building_scene.instantiate()
		b.position = Vector3(
			randf_range(0, SIZE),
			0,
			randf_range(0, SIZE)
		)
		city.add_child(b)

func get_or_create(name: String) -> Node3D:
	if has_node(name):
		return get_node(name) as Node3D
	
	var n := Node3D.new()
	n.name = name
	add_child(n)
	return n

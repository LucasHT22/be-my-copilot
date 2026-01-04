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
	
	var mesh = MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.mesh.size = Vector2(SIZE, SIZE)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(SIZE, 2, SIZE)
	
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
	var forest = $Forest
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for i in range(40):
		var tree = tree_scene.instantiate()
		tree.position = Vector3(
			rng.randf_range(0, SIZE),
			0,
			rng.randf_range(0, SIZE)
		)
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

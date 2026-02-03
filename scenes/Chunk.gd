extends Node3D

var chunk_coord: Vector2i
const SIZE := 256
const AIRPORT_RADIUS := 120

var noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()
var height_noise := FastNoiseLite.new()

func _ready():
	noise.seed = 12345
	noise.frequency = 0.002
	
	biome_noise.seed = 9999
	biome_noise.frequency = 0.08
	
	height_noise.seed = 4242
	height_noise.frequency = 0.01

func generate(coord: Vector2i):
	chunk_coord = coord
	position = Vector3(
		coord.x * SIZE,
		0,
		coord.y * SIZE
	)
	
	generate_ground()
	generate_content()
	
	if has_airport():
		generate_airport()

func has_airport() -> bool:
	return (chunk_coord.x * 73856093 ^ chunk_coord.y * 19349663) % 40 == 0

func is_airport_zone(x: float, z: float) -> bool:
	var cx = SIZE * 0.5
	var cz = SIZE * 0.5
	return Vector2(x, z).distance_to(Vector2(cx, cz)) < AIRPORT_RADIUS

func get_biome() -> String:
	var elevation = height_noise.get_noise_2d(
		chunk_coord.x * SIZE,
		chunk_coord.y * SIZE
	)
	
	var moisture = biome_noise.get_noise_2d(
		chunk_coord.x * 0.15,
		chunk_coord.y * 0.15
	)
	
	if elevation < -0.15:
		return "sea"
	
	if moisture > 0.35:
		return "forest"
	
	if moisture > 0.15:
		return "plains"
	
	return "dry"

func should_generate_city() -> bool:
	var v := biome_noise.get_noise_2d(
		chunk_coord.x * 2.0,
		chunk_coord.y * 2.0
	)
	return v > 0.35

func generate_content():
	var biome = get_biome()
	print("Chunk", chunk_coord, "biome:", biome)
	
	match biome:
		"sea":
			generate_sea()
		"forest":
			generate_forest()
		"plains":
			generate_plains()
			if should_generate_city():
				generate_city()

func generate_plains():
	var plains := Node3D.new()
	add_child(plains)
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for i in range(80):
		var x = rng.randf_range(0, SIZE)
		var z = rng.randf_range(0, SIZE)
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		if is_airport_zone(x, z):
			continue
		
		var density = noise.get_noise_2d(wx * 0.015, wz * 0.015)
		if density < 0.35:
			continue
		
		var tree = tree_scene.instantiate()
		tree.position = Vector3(x, 0, z)
		tree.scale *= rng.randf_range(0.7, 1.2)
		plains.add_child(tree)

func generate_ground():
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh.mesh = plane
	mesh.rotation_degrees.x = -90
	
	var wx = chunk_coord.x * SIZE
	var wz = chunk_coord.y * SIZE
	var h = height_noise.get_noise_2d(wx, wz) * 20.0
	
	mesh.position.y = h
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.55, 0.2)
	mat.roughness = 1.0
	mesh.material_override = mat
	
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(SIZE, 4, SIZE)
	col.shape = shape
	col.position.y = h - 2
	
	ground.add_child(mesh)
	ground.add_child(col)
	add_child(ground)

func generate_city():
	var city := Node3D.new()
	add_child(city)
	
	var building_scene := preload("res://scenes/Terminal.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	var block_size = 40
	
	for x in range(block_size, SIZE - block_size, block_size):
		for z in range(block_size, SIZE - block_size, block_size):
			var wx = chunk_coord.x * SIZE + x
			var wz = chunk_coord.y * SIZE + z
			
			if is_airport_zone(wx, wz):
				continue
			
			if rng.randf() < 0.5:
				continue
			
			var b = building_scene.instantiate()
			b.position = Vector3(x, 0, z)
			b.scale = Vector3(
				rng.randf_range(0.9, 1.4),
				rng.randf_range(1.2, 6.0),
				rng.randf_range(0.9, 1.4)
			)
			city.add_child(b)

func generate_forest():
	var forest := Node3D.new()
	add_child(forest)
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for i in range(300):
		var x = rng.randf_range(0, SIZE)
		var z = rng.randf_range(0, SIZE)
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		if is_airport_zone(wx, wz):
			continue
		
		var density = noise.get_noise_2d(wx * 0.02, wz * 0.02)
		if density < 0.2:
			continue
		
		var tree = tree_scene.instantiate()
		tree.position = Vector3(x, 0, z)
		tree.scale *= rng.randf_range(0.8, 1.6)
		forest.add_child(tree)

func generate_sea():
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	water.mesh = plane
	water.rotation_degrees.x = -90
	water.position.y = -3
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.35, 0.75)
	mat.roughness = 0.05
	water.material_override = mat
	
	water.position.y = -3
	add_child(water)

func generate_airport():
	var airport_scene = preload("res://scenes/Airport.tscn")
	var airport = airport_scene.instantiate()
	var h = height_noise.get_noise_2d(
		chunk_coord.x * SIZE,
		chunk_coord.y * SIZE
	) * 20.0
	airport.position = Vector3(SIZE * 0.5, h, SIZE * 0.5)
	add_child(airport)

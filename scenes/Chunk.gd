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
	return abs(chunk_coord.x) % 15 == 0 and abs(chunk_coord.y) % 15 == 0

func is_airport_zone(x: float, z: float) -> bool:
	var cx = chunk_coord.x * SIZE + SIZE / 2
	var cz = chunk_coord.y * SIZE + SIZE / 2
	return Vector2(x, z).distance_to(Vector2(cx, cz)) < AIRPORT_RADIUS

func get_biome() -> String:
	var biome_noise = biome_noise.get_noise_2d(chunk_coord.x, chunk_coord.y)
	
	if biome_noise < -0.3:
		return "forest"
	elif biome_noise < 0.2:
		return "forest"
	else:
		return "plains"

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
			if should_generate_city():
				generate_city()

func generate_ground():
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh.mesh = plane
	
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
	city.name = "City"
	add_child(city)
	
	var building_scene := preload("res://scenes/Terminal.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for x in range(40, SIZE - 40, 40):
		for z in range(40, SIZE - 40, 40):
			var wx = chunk_coord.x * SIZE + x
			var wz = chunk_coord.y * SIZE + z
			
			if is_airport_zone(wx, wz):
				continue
			
			if rng.randf() < 0.6:
				continue
			
			var b = building_scene.instantiate()
			b.position = Vector3(x, 0, z)
			b.scale = Vector3(
				rng.randf_range(0.8, 1.3),
				rng.randf_range(1.0, 4.0),
				rng.randf_range(0.8, 1.3)
			)
			city.add_child(b)

func generate_forest():
	var forest := Node3D.new()
	forest.name = "Forest"
	add_child(forest)
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for x in range(0, SIZE, 10):
		for z in range(0, SIZE, 10):
			var wx = chunk_coord.x * SIZE + x
			var wz = chunk_coord.y * SIZE + z
			
			if is_airport_zone(wx, wz):
				continue
			
			var cluster = noise.get_noise_2d(wx, wz)
			if cluster > 0.25:
				var tree = tree_scene.instantiate()
				tree.position = Vector3(x, 0, z)
				tree.scale *= rng.randf_range(0.9, 1.4)
				forest.add_child(tree)

func generate_sea():
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	water.mesh = plane
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.35, 0.75)
	mat.roughness = 0.05
	water.material_override = mat
	
	water.position.y = -3
	add_child(water)

func generate_airport():
	var airport_scene = preload("res://scenes/Airport.tscn")
	var airport = airport_scene.instantiate()
	airport.position = Vector3(SIZE / 2, 0, SIZE / 2)
	add_child(airport)

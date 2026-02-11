extends Node3D

var chunk_coord: Vector2i
var lod_level := 2 # (0 for high, 1 for mid, 2 for low)
const SIZE := 256
const AIRPORT_RADIUS := 120

var noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var temperature_noise := FastNoiseLite.new()

func _ready():
	noise.seed = 12345
	noise.frequency = 0.002
	
	biome_noise.seed = 9999
	biome_noise.frequency = 0.08
	
	moisture_noise.seed = 5555
	moisture_noise.frequency = 0.05
	moisture_noise.fractal_octaves = 3
	
	temperature_noise.seed = 7777
	temperature_noise.frequency = 0.04
	temperature_noise.fractal_octaves = 2

func generate(coord: Vector2i, lod := 0):
	chunk_coord = coord
	lod_level = lod
	position = Vector3(
		coord.x * SIZE,
		0,
		coord.y * SIZE
	)
	
	generate_ground()
	
	if lod_level == 2:
		generate_content()
		if has_airport():
			generate_airport()

func has_airport() -> bool:
	return (chunk_coord.x * 73856093 ^ chunk_coord.y * 19349663) % 40 == 0

func get_biome() -> String:
	var wx = chunk_coord.x * SIZE + SIZE * 0.5
	var wz = chunk_coord.y * SIZE + SIZE * 0.5
	
	var moisture = moisture_noise.get_noise_2d(wx, wz)
	var temperature = temperature_noise.get_noise_2d(wx, wz)
	var base = biome_noise.get_noise_2d(chunk_coord.x * 0.15, chunk_coord.y * 0.15)
	
	if base < -0.2:
		return "sea"
	
	if temperature > 0.3 and  moisture < -0.1:
		return "desert"
	
	if temperature < -0.1 and moisture > 0.2:
		return "forest"
	
	if moisture > 0.0 and temperature > -0.2 and temperature < 0.3:
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
			print("		GEN SEAS")
			generate_sea()
		"forest":
			print("		GEN FOREST")
			generate_forest()
		"plains":
			print("		GEN PLAIN")
			generate_plains()
			if should_generate_city():
				print("		GEN CITY")
				generate_city()
		"desert":
			print("		GEN DESERT")
			generate_desert()
		"dry":
			print("		GEN DRY")
			generate_dry()

var pooled_objects := []

func generate_plains():
	var plains := Node3D.new()
	plains.name = "Plains"
	add_child(plains)
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for i in range(80):
		var x = rng.randf_range(0, SIZE)
		var z = rng.randf_range(0, SIZE)
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		var density = noise.get_noise_2d(wx * 0.015, wz * 0.015)
		if density < 0.0:
			continue
		
		var tree = tree_scene.instantiate()
		tree.position = Vector3(x, 0, z)
		tree.scale *= rng.randf_range(0.7, 1.2)
		plains.add_child(tree)

func generate_desert():
	var desert := Node3D.new()
	desert.name = "Desert"
	add_child(desert)
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for i in range(5):
		var x = rng.randf_range(0, SIZE)
		var z = rng.randf_range(0, SIZE)
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		var density = noise.get_noise_2d(wx * 0.008, wz * 0.008)
		if density < 0.7:
			continue
		
		var tree = tree_scene.instantiate()
		tree.position = Vector3(x, 0, z)
		tree.scale *= rng.randf_range(0.4, 0.7)
		desert.add_child(tree)

func generate_dry():
	var dry := Node3D.new()
	dry.name = "Dry"
	add_child(dry)
	
	var tree_scene = preload("res://scenes/Tree.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	for i in range(20):
		var x = rng.randf_range(0, SIZE)
		var z = rng.randf_range(0, SIZE)
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		var density = noise.get_noise_2d(wx * 0.01, wz * 0.01)
		if density < 0.0:
			continue
		
		var tree = tree_scene.instantiate()
		tree.position = Vector3(x, 0, z)
		tree.scale *= rng.randf_range(0.5, 0.9)
		dry.add_child(tree)

func generate_ground():
	var bedrock := StaticBody3D.new()
	bedrock.name = "Bedrock"
	
	var bedrock_col := CollisionShape3D.new()
	var bedrock_shape := BoxShape3D.new()
	bedrock_shape.size = Vector3(SIZE, 10, SIZE)
	bedrock_col.shape = bedrock_shape
	bedrock_col.position.y = -5.0
	
	bedrock.add_child(bedrock_col)
	add_child(bedrock)
	
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh_instance.mesh = plane
	
	var mat := StandardMaterial3D.new()
	var biome = get_biome()
	
	match biome:
		"sea":
			mat.albedo_color = Color(0.2, 0.4, 0.3)
		"forest":
			mat.albedo_color = Color(0.1, 0.4, 0.15)
		"plains":
			mat.albedo_color = Color(0.2, 0.6, 0.25)
		"desert":
			mat.albedo_color = Color(0.85, 0.75, 0.5)
		"dry":
			mat.albedo_color = Color(0.7, 0.6, 0.4)
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
			print("WARNING: Unknown biome '", biome, "' at chunk ", chunk_coord)
	
	mat.roughness = 1.0
	mesh_instance.material_override = mat
	
	
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE, 0.1, SIZE)
	collision.shape = box
	
	ground.add_child(mesh_instance)
	ground.add_child(collision)
	add_child(ground)

func generate_city():
	var city := Node3D.new()
	city.name = "City"
	add_child(city)
	
	var building_scene := preload("res://scenes/Terminal.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_coord)
	
	var block_size = 40
	
	for x in range(block_size, SIZE - block_size, block_size):
		for z in range(block_size, SIZE - block_size, block_size):
			if rng.randf() < 0.3:
				continue
			
			var b = building_scene.instantiate()
			b.position = Vector3(x, 0, z)
			b.scale = Vector3(
				rng.randf_range(0.9, 1.4),
				rng.randf_range(1.2, 8.0),
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
		
		var density = noise.get_noise_2d(wx * 0.02, wz * 0.02)
		if density < 0.15:
			continue
		
		var tree = tree_scene.instantiate()
		tree.position = Vector3(x, 0, z)
		tree.scale *= rng.randf_range(0.9, 1.8)
		forest.add_child(tree)

func generate_sea():
	var water := StaticBody3D.new()
	water.name = "Water"
	
	var water_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	water_mesh.mesh = plane
	water_mesh.position.y = 0.0
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.35, 0.75, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.3
	water_mesh.material_override = mat
	
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE, 15.0, SIZE)
	col.shape = box
	col.position.y = -7.5
	
	water.add_child(water_mesh)
	water.add_child(col)
	add_child(water)

func generate_airport():
	var airport_scene = preload("res://scenes/Airport.tscn")
	var airport = airport_scene.instantiate()
	
	print("Airport at chunk ", chunk_coord, " height: ", 0)
	
	airport.position = Vector3(SIZE * 0.5, 0, SIZE * 0.5)
	add_child(airport)

extends Node3D

var chunk_coord: Vector2i
const SIZE := 256
const AIRPORT_RADIUS := 120
const TERRAIN_SUBDIVISIONS := 32

var noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()
var height_noise := FastNoiseLite.new()

func _ready():
	noise.seed = 12345
	noise.frequency = 0.002
	
	biome_noise.seed = 9999
	biome_noise.frequency = 0.08
	
	height_noise.seed = 4242
	height_noise.frequency = 0.005
	height_noise.fractal_octaves = 2
	height_noise.fractal_lacunarity = 2.0
	height_noise.fractal_gain = 0.4

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

func get_height_at(world_x: float, world_z: float) -> float:
	var noise_val = height_noise.get_noise_2d(world_x, world_z)
	var base_height = (noise_val * 3.0) + 0.5
	if has_airport():
		var cx = chunk_coord.x * SIZE + SIZE * 0.5
		var cz = chunk_coord.y * SIZE + SIZE * 0.5
		var local_x = world_x - chunk_coord.x * SIZE
		var local_z = world_z - chunk_coord.y * SIZE
		var dist = Vector2(local_x, local_z).distance_to(Vector2(SIZE * 0.5, SIZE * 0.5))
		
		if dist < AIRPORT_RADIUS * 1.5:
			var center_noise = height_noise.get_noise_2d(cx, cz)
			var center_height = (center_noise * 3.0) + 0.5
			var blend = clamp(dist / (AIRPORT_RADIUS * 1.5), 0.0, 1.0)
			blend = blend * blend * (3.0 - 2.0 * blend)
			
			return lerp(center_height, base_height, blend)
	
	return base_height

func get_biome() -> String:
	var wx = chunk_coord.x * SIZE + SIZE * 0.5
	var wz = chunk_coord.y * SIZE + SIZE * 0.5
	var elevation = height_noise.get_noise_2d(wx, wz)
	
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
		"dry":
			generate_dry()

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
		
		if is_airport_zone(x, z):
			continue
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		var density = noise.get_noise_2d(wx * 0.015, wz * 0.015)
		if density < 0.35:
			continue
		
		var tree = tree_scene.instantiate()
		var height = get_height_at(wx, wz)
		tree.position = Vector3(x, height, z)
		tree.scale *= rng.randf_range(0.7, 1.2)
		plains.add_child(tree)

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
		
		if is_airport_zone(x, z):
			continue
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		var density = noise.get_noise_2d(wx * 0.01, wz * 0.01)
		if density < 0.6:
			continue
		
		var tree = tree_scene.instantiate()
		var height = get_height_at(wx, wz)
		tree.position = Vector3(x, height, z)
		tree.scale *= rng.randf_range(0.5, 0.9)
		dry.add_child(tree)

func generate_ground():
	var bedrock := StaticBody3D.new()
	bedrock.name = "Bedrock"
	
	var bedrock_mesh := MeshInstance3D.new()
	var bedrock_plane := BoxMesh.new()
	bedrock_plane.size = Vector3(SIZE, 10, SIZE)
	bedrock_mesh.mesh = bedrock_plane
	bedrock_mesh.position.y = -10
	
	var bedrock_mat := StandardMaterial3D.new()
	bedrock_mat.albedo_color = Color(0.2, 0.2, 0.2)
	bedrock_mesh.material_override = bedrock_mat
	
	var bedrock_col := CollisionShape3D.new()
	var bedrock_shape := BoxShape3D.new()
	bedrock_shape.size = Vector3(SIZE, 10, SIZE)
	bedrock_col.shape = bedrock_shape
	bedrock_col.position.y = -10
	
	bedrock.add_child(bedrock_mesh)
	bedrock.add_child(bedrock_col)
	add_child(bedrock)
	
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	
	var mesh_instance := MeshInstance3D.new()
	var surface_tool := SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var step = SIZE / float(TERRAIN_SUBDIVISIONS)
	var terrain_bottom = -5.0
	
	var top_vertices = []
	
	for iz in range(TERRAIN_SUBDIVISIONS + 1):
		for ix in range(TERRAIN_SUBDIVISIONS + 1):
			var x = ix * step
			var z = iz * step
			
			var wx = chunk_coord.x * SIZE + x
			var wz = chunk_coord.y * SIZE + z
			var h = get_height_at(wx, wz)
			
			var vertex = Vector3(x, h, z)
			var uv = Vector2(float(ix) / TERRAIN_SUBDIVISIONS, float(iz) / TERRAIN_SUBDIVISIONS)
			
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(vertex)
	
	for iz in range(TERRAIN_SUBDIVISIONS):
		for ix in range(TERRAIN_SUBDIVISIONS):
			var i0 = iz * (TERRAIN_SUBDIVISIONS + 1) + ix
			var i1 = i0 + 1
			var i2 = i0 + (TERRAIN_SUBDIVISIONS + 1)
			var i3 = i2 + 1
			
			surface_tool.add_index(i0)
			surface_tool.add_index(i2)
			surface_tool.add_index(i1)
			
			surface_tool.add_index(i1)
			surface_tool.add_index(i2)
			surface_tool.add_index(i3)
	
	var bottom_start_index = (TERRAIN_SUBDIVISIONS + 1) * (TERRAIN_SUBDIVISIONS + 1)
	for iz in range(TERRAIN_SUBDIVISIONS + 1):
		for ix in range(TERRAIN_SUBDIVISIONS + 1):
			var x = ix * step
			var z = iz * step
			var vertex = Vector3(x, terrain_bottom, z)
			var uv = Vector2(float(ix) / TERRAIN_SUBDIVISIONS, float(iz) / TERRAIN_SUBDIVISIONS)
			
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(vertex)
	
	for iz in range(TERRAIN_SUBDIVISIONS):
		for ix in range(TERRAIN_SUBDIVISIONS):
			var i0 = bottom_start_index + iz * (TERRAIN_SUBDIVISIONS + 1) + ix
			var i1 = i0 + 1
			var i2 = i0 + (TERRAIN_SUBDIVISIONS + 1)
			var i3 = i2 + 1
			
			surface_tool.add_index(i0)
			surface_tool.add_index(i1)
			surface_tool.add_index(i2)
			
			surface_tool.add_index(i1)
			surface_tool.add_index(i3)
			surface_tool.add_index(i2)
	
	var side_start_index = bottom_start_index + (TERRAIN_SUBDIVISIONS + 1) * (TERRAIN_SUBDIVISIONS + 1)
	
	for ix in range(TERRAIN_SUBDIVISIONS + 1):
		var x = ix * step
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + 0
		var h = get_height_at(wx, wz)
		
		surface_tool.set_uv(Vector2(float(ix) / TERRAIN_SUBDIVISIONS, 0))
		surface_tool.add_vertex(Vector3(x, h, 0))
		surface_tool.set_uv(Vector2(float(ix) / TERRAIN_SUBDIVISIONS, 1))
		surface_tool.add_vertex(Vector3(x, terrain_bottom, 0))
	
	for ix in range(TERRAIN_SUBDIVISIONS):
		var base = side_start_index + ix * 2
		surface_tool.add_index(base)
		surface_tool.add_index(base + 2)
		surface_tool.add_index(base + 1)
		
		surface_tool.add_index(base + 1)
		surface_tool.add_index(base + 2)
		surface_tool.add_index(base + 3)
	
	side_start_index += (TERRAIN_SUBDIVISIONS + 1) * 2
	
	for ix in range(TERRAIN_SUBDIVISIONS + 1):
		var x = ix * step
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + SIZE
		var h = get_height_at(wx, wz)
		
		surface_tool.set_uv(Vector2(float(ix) / TERRAIN_SUBDIVISIONS, 0))
		surface_tool.add_vertex(Vector3(x, h, SIZE))
		surface_tool.set_uv(Vector2(float(ix) / TERRAIN_SUBDIVISIONS, 1))
		surface_tool.add_vertex(Vector3(x, terrain_bottom, SIZE))
	
	for ix in range(TERRAIN_SUBDIVISIONS):
		var base = side_start_index + ix * 2
		surface_tool.add_index(base)
		surface_tool.add_index(base + 1)
		surface_tool.add_index(base + 2)
		
		surface_tool.add_index(base + 1)
		surface_tool.add_index(base + 3)
		surface_tool.add_index(base + 2)
	
	side_start_index += (TERRAIN_SUBDIVISIONS + 1) * 2
	
	for iz in range(TERRAIN_SUBDIVISIONS + 1):
		var z = iz * step
		var wx = chunk_coord.x * SIZE + 0
		var wz = chunk_coord.y * SIZE + z
		var h = get_height_at(wx, wz)
		
		surface_tool.set_uv(Vector2(float(iz) / TERRAIN_SUBDIVISIONS, 0))
		surface_tool.add_vertex(Vector3(0, h, z))
		surface_tool.set_uv(Vector2(float(iz) / TERRAIN_SUBDIVISIONS, 1))
		surface_tool.add_vertex(Vector3(0, terrain_bottom, z))
	
	for iz in range(TERRAIN_SUBDIVISIONS):
		var base = side_start_index + iz * 2
		surface_tool.add_index(base)
		surface_tool.add_index(base + 1)
		surface_tool.add_index(base + 2)
		
		surface_tool.add_index(base + 1)
		surface_tool.add_index(base + 3)
		surface_tool.add_index(base + 2)
	
	side_start_index += (TERRAIN_SUBDIVISIONS + 1) * 2
	
	for iz in range(TERRAIN_SUBDIVISIONS + 1):
		var z = iz * step
		var wx = chunk_coord.x * SIZE + SIZE
		var wz = chunk_coord.y * SIZE + z
		var h = get_height_at(wx, wz)
		
		surface_tool.set_uv(Vector2(float(iz) / TERRAIN_SUBDIVISIONS, 0))
		surface_tool.add_vertex(Vector3(SIZE, h, z))
		surface_tool.set_uv(Vector2(float(iz) / TERRAIN_SUBDIVISIONS, 1))
		surface_tool.add_vertex(Vector3(SIZE, terrain_bottom, z))
	
	for iz in range(TERRAIN_SUBDIVISIONS):
		var base = side_start_index + iz * 2
		surface_tool.add_index(base)
		surface_tool.add_index(base + 2)
		surface_tool.add_index(base + 1)
		
		surface_tool.add_index(base + 1)
		surface_tool.add_index(base + 2)
		surface_tool.add_index(base + 3)
	
	surface_tool.generate_normals()
	var array_mesh = surface_tool.commit()
	mesh_instance.mesh = array_mesh
	
	var mat := StandardMaterial3D.new()
	var biome = get_biome()
	match  biome:
		"sea":
			mat.albedo_color = Color(0.2, 0.4, 0.3)
		"forest":
			mat.albedo_color = Color(0.1, 0.4, 0.15)
		"plains":
			mat.albedo_color = Color(0.2, 0.6, 0.25)
		"dry":
			mat.albedo_color = Color(0.7, 0.6, 0.4)
	
	mat.roughness = 1.0
	mesh_instance.material_override = mat
	
	var col := CollisionShape3D.new()
	mesh_instance.create_trimesh_collision()
	
	ground.add_child(mesh_instance)
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
			if is_airport_zone(x, z):
				continue
			
			if rng.randf() < 0.5:
				continue
			
			var wx = chunk_coord.x * SIZE + x
			var wz = chunk_coord.y * SIZE + z
			var height = get_height_at(wx, wz)
			
			var b = building_scene.instantiate()
			b.position = Vector3(x, height, z)
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
		
		if is_airport_zone(x, z):
			continue
		
		var wx = chunk_coord.x * SIZE + x
		var wz = chunk_coord.y * SIZE + z
		
		var density = noise.get_noise_2d(wx * 0.02, wz * 0.02)
		if density < 0.2:
			continue
		
		var tree = tree_scene.instantiate()
		var height = get_height_at(wx, wz)
		tree.position = Vector3(x, height, z)
		tree.scale *= rng.randf_range(0.8, 1.6)
		forest.add_child(tree)

func generate_sea():
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	water.mesh = plane
	
	var sea_level = 0.0
	water.position.y = sea_level
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.35, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.3
	water.material_override = mat
	
	add_child(water)

func generate_airport():
	var airport_scene = preload("res://scenes/Airport.tscn")
	var airport = airport_scene.instantiate()
	
	var cx = chunk_coord.x * SIZE + SIZE * 0.5
	var cz = chunk_coord.y * SIZE + SIZE * 0.5
	
	var center_noise = height_noise.get_noise_2d(cx, cz)
	var h = (center_noise * 3.0) + 0.5
	
	airport.position = Vector3(SIZE * 0.5, h, SIZE * 0.5)
	add_child(airport)

extends Node3D

@export var player: Node3D
@export var chunk_scene: PackedScene
@export var view_distance := 7
@export var unload_distance := 4

const CHUNK_SIZE := 256
var chunks := {}
var last_player_chunk := Vector2i(-999, -999)
var fog_environment: Environment

func _ready():
	setup_fog()

func setup_fog():
	var world_env = get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
	
	fog_environment = Environment.new()
	
	fog_environment.volumetric_fog_enabled = true
	fog_environment.volumetric_fog_density = 0.01
	fog_environment.volumetric_fog_albedo = Color(0.7, 0.8, 0.9)
	fog_environment.volumetric_fog_emission_energy = 0.0
	
	fog_environment.fog_enabled = true
	fog_environment.fog_light_color = Color(0.7, 0.8, 0.9)
	fog_environment.fog_light_energy = 1.0
	fog_environment.fog_density = 0.0008
	fog_environment.fog_height = -10.0
	fog_environment.fog_height_density = 0.5
	
	fog_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	fog_environment.ambient_light_color = Color(0.7, 0.8, 0.9)
	fog_environment.ambient_light_energy = 0.5
	
	world_env.environment = fog_environment

func _process(_delta):
	if player == null:
		return
	
	var player_chunk = get_player_chunk()
	
	if player_chunk != last_player_chunk:
		last_player_chunk = player_chunk
		update_chunks(player_chunk)

func update_chunks(player_chunk: Vector2i):
	for x in range(
		player_chunk.x - view_distance,
		player_chunk.x + view_distance + 1
	):
		for z in range(
			player_chunk.y - view_distance,
			player_chunk.y + view_distance + 1
		):
			var key = Vector2i(x, z)
			if not chunks.has(key):
				spawn_chunk(key)
	
	var chunks_to_remove = []
	for coord in chunks.keys():
		var dist = max(abs(coord.x - player_chunk.x), abs(coord.y - player_chunk.y))
		
		if dist > unload_distance:
			chunks_to_remove.append(coord)
	
	for coord in chunks_to_remove:
		unload_chunk(coord)

func spawn_chunk(coord: Vector2i):
	var player_chunk = get_player_chunk()
	var dist = max(abs(coord.x - player_chunk.x), abs(coord.y - player_chunk.y))
	
	var lod = 0
	if dist > 2:
		lod = 2
	elif dist > 1:
		lod = 1
	
	var chunk = chunk_scene.instantiate()
	add_child(chunk)
	chunk.generate(coord, lod)
	chunks[coord] = chunk

func unload_chunk(coord: Vector2i):
	if chunks.has(coord):
		var chunk = chunks[coord]
		chunk.queue_free()
		chunks.erase(coord)

func get_player_chunk() -> Vector2i:
	var p = player.global_position
	return Vector2i(
		floor(p.x / CHUNK_SIZE),
		floor(p.z / CHUNK_SIZE)
	)

func _on_quit_pressed():
	get_tree().quit()

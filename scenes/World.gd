extends Node3D

@export var player: Node3D
@export var chunk_scene: PackedScene
@export var view_distance := 7
@export var unload_distance := 4

const CHUNK_SIZE := 256
var chunks := {}
var last_player_chunk := Vector2i(-999, -999)
var generation_queue := []
var active_threads := {}
#var fog_environment: Environment
#
#func _ready():
	#setup_fog()
#
#func setup_fog():
	#var world_env = get_node_or_null("WorldEnvironment")
	#if not world_env:
		#world_env = WorldEnvironment.new()
		#world_env.name = "WorldEnvironment"
		#add_child(world_env)
	#
	#fog_environment = Environment.new()
	#
	#fog_environment.volumetric_fog_enabled = true
	#fog_environment.volumetric_fog_density = 0.01
	#fog_environment.volumetric_fog_albedo = Color(0.7, 0.8, 0.9)
	#fog_environment.volumetric_fog_emission_energy = 0.0
	#
	#fog_environment.fog_enabled = true
	#fog_environment.fog_light_color = Color(0.7, 0.8, 0.9)
	#fog_environment.fog_light_energy = 1.0
	#fog_environment.fog_density = 0.0008
	#fog_environment.fog_height = -10.0
	#fog_environment.fog_height_density = 0.5
	#
	#fog_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	#fog_environment.ambient_light_color = Color(0.7, 0.8, 0.9)
	#fog_environment.ambient_light_energy = 0.5
	#
	#world_env.environment = fog_environment

func _process(_delta):
	if player == null:
		return
	
	check_finished_threads()
	
	var player_chunk = get_player_chunk()
	
	if player_chunk != last_player_chunk:
		last_player_chunk = player_chunk
		update_chunks(player_chunk)

func check_finished_threads():
	var finished := []
	for coord in active_threads.keys():
		var thread: Thread = active_threads[coord]
		if not thread.is_alive():
			var chunk = thread.wait_to_finish()
			add_child(chunk)
			chunks[coord] = chunk
			finished.append(coord)
	
	for coord in finished:
		active_threads.erase(coord)

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
			if not chunks.has(key) and not active_threads.has(key):
				spawn_chunk(key)
	
	var chunks_to_remove = []
	for coord in chunks.keys():
		var dist_x = abs(coord.x - player_chunk.x)
		var dist_z = abs(coord.y - player_chunk.y)
		
		if dist_x > unload_distance or dist_z > unload_distance:
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
	
	var thread = Thread.new()
	thread.start(_generate_chunk_threaded.bind(coord, lod))
	active_threads[coord] = thread

func _generate_chunk_threaded(coord: Vector2i, lod: int):
	var chunk = chunk_scene.instantiate()
	chunk.generate(coord, lod)
	return chunk

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


func _on_free_flight_pressed():
	pass # Replace with function body.


func _on_quit_pressed():
	pass # Replace with function body.

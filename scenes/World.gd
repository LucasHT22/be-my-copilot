extends Node3D

@export var player: Node3D
@export var chunk_scene: PackedScene
@export var view_distance := 2

const CHUNK_SIZE := 256
var chunks := {}

func _process(_delta):
	if player == null:
		return
	
	var player_chunk = get_player_chunk()
	
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

func spawn_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	chunk.generate(coord)
	add_child(chunk)
	chunks[coord] = chunk

func get_player_chunk() -> Vector2i:
	var p = player.global_position
	return Vector2i(
		floor(p.x / CHUNK_SIZE),
		floor(p.z / CHUNK_SIZE)
	)

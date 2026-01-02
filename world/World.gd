extends Node3D

@export var chunk_scene: PackedScene
@export var plane: Node3D
@export var view_distance := 2

var chunks := {}

func _process(_dt):
	if plane == null:
		return

	var cx = floor(plane.global_position.x / Chunk.SIZE)
	var cz = floor(plane.global_position.z / Chunk.SIZE)

	for x in range(cx - view_distance, cx + view_distance + 1):
		for z in range(cz - view_distance, cz + view_distance + 1):
			var key = Vector2i(x, z)
			if not chunks.has(key):
				spawn_chunk(key)

func spawn_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	add_child(chunk)

	chunk.position = Vector3(
		coord.x * Chunk.SIZE,
		0,
		coord.y * Chunk.SIZE
	)

	chunks[coord] = chunk

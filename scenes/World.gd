extends Node3D

@export var plane: Node3D
const CHUNK_SIZE := 256
const VIEW_DISTANCE := 2

var chunks := {}
var chunk_scene := preload("res://scenes/Chunk.tscn")

func world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(pos.x / CHUNK_SIZE),
		floor(pos.z / CHUNK_SIZE)
	)

func _process(_delta):
	var center = world_to_chunk(plane.global_position)
	
	for x in range(center.x - VIEW_DISTANCE, center.x + VIEW_DISTANCE + 1):
		for z in range(center.y - VIEW_DISTANCE, center.y + VIEW_DISTANCE + 1):
			var coord = Vector2i(x, z)
			if not chunks.has(coord):
				load_chunk(coord)
	
	unload_far_chunks(center)

func load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	$Chunks.add_child(chunk)
	chunk.generate(coord)
	chunks[coord] = chunk

func unload_far_chunks(center: Vector2i):
	for coord in chunks.keys():
		var d = abs(coord.x - center.x) + abs(coord.y - center.y)
		if d > VIEW_DISTANCE:
			chunks[coord].queue_free()
			chunks.erase(coord)

func _ready():
	var airport = preload("res://scenes/Airport.tscn").instantiate()
	airport.position = Vector3.ZERO
	add_child(airport)

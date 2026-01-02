extends Node3D
class_name Chunk

@export var tree_scene: PackedScene

const SIZE := 256
var noise := FastNoiseLite.new()

func _ready():
	noise.seed = 12345
	noise.frequency = 0.01
	generate_ground()
	generate_trees()

func generate_ground():
	var ground := StaticBody3D.new()
	add_child(ground)

	# visual
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh.mesh = plane
	mesh.rotation.x = -PI / 2
	ground.add_child(mesh)

	# collision
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(SIZE, 2, SIZE)
	col.shape = shape
	col.position.y = -1
	ground.add_child(col)

func land_type(x: float, z: float) -> String:
	var n = noise.get_noise_2d(x, z)
	
	if n < -0.2:
		return "plains"
	elif n < 0.2:
		return "grass"
	else:
		return "forest"

func generate_trees():
	for i in range(40):
		var lx = randf_range(-SIZE/2, SIZE/2)
		var lz = randf_range(-SIZE/2, SIZE/2)
		
		var wx = global_position.x + lx
		var wz = global_position.z + lz
		
		if land_type(wx * 0.01, wz * 0.01) != "forest":
			continue
		
		var tree = tree_scene.instantiate()
		add_child(tree)
		tree.position = Vector3(lx, 0, lz)
		tree.rotation.y = randf() * TAU
		tree.scale *= randf_range(0.8, 1.3)

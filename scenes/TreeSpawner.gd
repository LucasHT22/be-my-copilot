extends Node3D

@export var tree_scene: PackedScene
@export var count := 500
@export var area_size := 400

@onready var check_area := $CheckArea

func _ready():
	if tree_scene == null:
		push_error("Tree scene not assigned")
		return
	
	var spawned := 0
	var space_state = get_world_3d().direct_space_state
	
	while spawned < count:
		var pos = Vector3(
			randf_range(-area_size, area_size),
			0,
			randf_range(-area_size, area_size)
		)
	
		check_area.global_position = pos
	
		await get_tree().physics_frame
		
		var bad := false
		for body in check_area.get_overlapping_bodies():
			if body.is_in_group("no_trees"):
				bad = true
				break
	
		if bad:
			continue
	
		var tree = tree_scene.instantiate()
		add_child(tree)
		tree.position = pos
		tree.rotation.y = randf() * TAU
		tree.scale *= randf_range(0.8, 1.3)
	
		spawned += 1

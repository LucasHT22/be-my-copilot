extends Camera3D

@export var airplane: Node3D
@export var offset := Vector3(0, 2, 8)

func _process(delta):
	if airplane == null:
		return
	
	var target_pos = airplane.global_position
	var desired_pos = target_pos + airplane.global_transform.basis * offset
	
	global_position = global_position.lerp(desired_pos, 0.1)
	look_at(target_pos, Vector3.UP)

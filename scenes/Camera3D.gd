extends Camera3D

@export var airplane: Node3D
@export var follow_offset := Vector3(0, 3, 12)
@export var follow_speed := 6.0
@export var look_speed := 10.0

func _physics_process(delta):
	if airplane == null:
		return
	
	var desired_pos: Vector3 = airplane.global_transform.origin \
		+ airplane.global_transform.basis * follow_offset
	
	global_position = global_position.lerp(
		desired_pos,
		follow_speed * delta
	)
	
	var look_target: Vector3 = airplane.global_transform.origin \
		- airplane.global_transform.basis.z * 10.0

	global_transform = global_transform.looking_at(
		look_target,
		Vector3.UP
	)

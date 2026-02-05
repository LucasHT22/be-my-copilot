extends Camera3D

@export var airplane: RigidBody3D
@export var follow_offset := Vector3(0, 3, 12)
@export var follow_speed := 6.0
@export var look_speed := 5.0

func _physics_process(delta):
	if not airplane:
		return
	
	var basis := airplane.global_transform.basis
	
	var forward := -basis.z
	forward.y = 0.0
	forward = forward.normalized()
	
	var right := forward.cross(Vector3.UP).normalized()
	var up := Vector3.UP
	
	var no_roll_basis := Basis(right, up, -forward)
	
	var desired_pos := airplane.global_position + no_roll_basis * follow_offset
	
	global_position = global_position.lerp(
		desired_pos,
		follow_speed * delta
	)
	
	var look_target := airplane.global_position + forward * 10.0
	var target_basis := Basis().looking_at(
		look_target - global_position,
		Vector3.UP
	)
	
	global_transform.basis = global_transform.basis.slerp(
		target_basis,
		look_speed * delta
	)

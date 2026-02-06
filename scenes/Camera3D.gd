extends Camera3D

@export var airplane: RigidBody3D
@export var follow_offset := Vector3(0, 3, 12)
@export var follow_speed := 6.0

func _physics_process(delta):
	if not airplane:
		return
	
	var desired_pos := airplane.global_position + airplane.global_basis * follow_offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	
	var look_dir := airplane.global_position - global_position
	if look_dir.length() > 0.01:
		look_at(airplane.global_position, Vector3.UP)

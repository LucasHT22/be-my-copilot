extends Camera3D

@export var airplane: Node3D
@export var distance := 10.0
@export var height := 3.0
@export var follow_speed := 6.0
@export var look_speed := 8.0

func _physics_process(delta):
	if airplane == null:
		return
	
	var forward = -airplane.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var desired_pos = airplane.global_position \
		- forward * distance \
		+ Vector3.UP * height
	
	global_position = global_position.lerp(
		desired_pos,
		follow_speed * delta
	)
	
	var look_target = airplane.global_position + forward * 5
	transform = transform.looking_at(
		look_target,
		Vector3.UP
	)

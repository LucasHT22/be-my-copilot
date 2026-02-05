extends  RigidBody3D

@export var engine_power := 12000.0
@export var max_speed := 75.0
@export var lift_coefficient := 1.4
@export var drag_coefficient := 0.045
@export var stall_speed := 22.0

@export var pitch_power := 1200.0
@export var roll_power := 1800.0
@export var yaw_power := 700.0

@export var flap_lift_bonus := 0.35
@export var flap_drag_bonus := 0.4

@export var wheel_friction := 2.8
@export var brake_power := 900.0

@export var propwash_power := 0.35
@export var turbulence_strength := 40.0

var throttle := 0.0
var flaps := false
var stalled := false

func _physics_process(delta):
	handle_input(delta)
	apply_thrust()
	apply_aerodynamics()
	apply_controls()
	apply_ground_physics()
	apply_turbulence()
	
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func handle_input(delta):
	throttle += (Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")) * delta
	throttle = clamp(throttle, 0.0, 1.0)
	
	if Input.is_action_just_pressed("ui_accept"):
		flaps = !flaps

func apply_thrust():
	var forward := -transform.basis.z
	apply_central_force(forward * engine_power * throttle)

func apply_aerodynamics():
	var v := linear_velocity
	var speed := v.length()
	if speed < 0.5:
		return
	
	var vel_dir := v.normalized()
	var forward := -transform.basis.z
	var up := transform.basis.y
	
	var aoa: float = clamp(forward.dot(vel_dir), -1.0, 1.0)
	
	var lift: float = lift_coefficient * speed * speed * max(aoa, 0.0)
	if flaps:
		lift *= (1.0 + flap_lift_bonus)
	
	stalled = speed < stall_speed
	if stalled:
		lift *= 0.3
		apply_torque(Vector3(-pitch_power * 0.6, 0, 0))
	
	apply_central_force(up * lift)
	
	var drag: Vector3 = -vel_dir * drag_coefficient * speed * speed
	if flaps:
		drag *= (1.0 + flap_drag_bonus)
	
	apply_central_force(drag)

func apply_controls():
	var speed := linear_velocity.length()
	var control_factor: float = clamp(speed / stall_speed, 0.2, 1.0)
	
	var pitch := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var roll := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var yaw := Input.get_action_strength("ui_page_down") - Input.get_action_strength("ui_page_up")
	
	var torque: Vector3 = Vector3(
		pitch * pitch_power,
		yaw * yaw_power,
		-roll * roll_power
	) * control_factor
	
	torque.x += pitch * pitch_power * throttle * propwash_power
	torque.y += roll * yaw_power * 0.35
	apply_torque(torque)

func apply_ground_physics():
	if not is_grounded():
		return
	
	var lateral := transform.basis.x * linear_velocity.dot(transform.basis.x)
	apply_central_force(-lateral * wheel_friction)
	
	if Input.is_action_pressed("ui_select"):
		if linear_velocity.length() > 0.5:
			apply_central_force(-linear_velocity.normalized() * brake_power)

func apply_turbulence():
	if not is_grounded():
		var gust: Vector3 = Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.5),
			randf_range(-1, 1)
		) * turbulence_strength
		
		apply_central_force(gust)

func is_grounded() -> bool:
	return abs(linear_velocity.y) < 1.0 and global_position.y < 1.2

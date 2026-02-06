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
@export var propwash_factor := 0.35

var throttle := 0.0
var flaps := false
var stalled := false

func _ready():
	angular_damp = 4.0
	linear_damp = 0.1

func _physics_process(delta):
	handle_input(delta)
	apply_thrust()
	apply_aerodynamics(delta)
	apply_controls()
	apply_ground_physics()
	
	if not linear_velocity.is_finite() or not angular_velocity.is_finite():
		print("⚠ Physics reset (NaN detected)")
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState3D):
	state.linear_velocity = state.linear_velocity.limit_length(max_speed * 1.3)
	state.angular_velocity = state.angular_velocity.limit_length(6.0)

func handle_input(delta):
	if Input.is_action_pressed("ui_page_up"):
		throttle += delta
	if Input.is_action_pressed("ui_page_down"):
		throttle -= delta
	throttle = clamp(throttle, 0.0, 1.0)
	
	if Input.is_action_just_pressed("ui_accept"):
		flaps = !flaps

func apply_thrust():
	var forward := -transform.basis.z
	apply_central_force(forward * engine_power * throttle)

func apply_aerodynamics(delta):
	var speed := linear_velocity.length()
	if speed < 0.5:
		return
	
	var vel_dir := linear_velocity.normalized()
	var forward := -global_basis.z
	var up := global_basis.y
	
	var aoa := forward.signed_angle_to(vel_dir, global_basis.x)
	aoa = clamp(aoa, -0.4, 0.4)
	
	var airspeed := speed + (throttle * 18.0 * (1.0 - speed / max_speed))
	
	var lift := lift_coefficient * airspeed * airspeed * sin(aoa)
	if flaps:
		lift *= (1.0 + flap_lift_bonus)
	
	stalled = speed < stall_speed and abs(aoa) > 0.3
	if stalled:
		lift *= 0.3
	
	apply_central_force(up * lift)
	
	var drag := -vel_dir * drag_coefficient * speed * speed
	if flaps:
		drag *= (1.0 + flap_drag_bonus)
	
	apply_central_force(drag)

func apply_controls():
	var speed := linear_velocity.length()
	if speed < 6.0:
		return
	
	var control_authority: float = clamp(speed / stall_speed, 0.0, 1.0)
	
	var pitch := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var roll := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var yaw := Input.get_action_strength("ui_select") - Input.get_action_strength("ui_cancel") # Example
	
	var pitch_with_propwash: float = pitch * (1.0 + throttle * propwash_factor)
	
	var torque: Vector3 = Vector3(
		pitch_with_propwash * pitch_power,
		yaw * yaw_power,
		-roll * roll_power
	) * control_authority
	
	apply_torque(torque)
	print("ROLL:", rad_to_deg(global_rotation.z))

func apply_ground_physics():
	if not is_grounded():
		return
	
	var lateral := global_basis.x * linear_velocity.dot(global_basis.x)
	apply_central_force(-lateral * wheel_friction)
	
	if Input.is_action_pressed("ui_home") and linear_velocity.length() > 0.5:
		apply_central_force(-linear_velocity.normalized() * brake_power)

func is_grounded() -> bool:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 2.0)
	var result := space_state.intersect_ray(query)
	return result.size() > 0 and abs(linear_velocity.y) < 1.0

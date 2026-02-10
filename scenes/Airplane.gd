extends  RigidBody3D

@export var engine_power := 15000.0
@export var max_rpm := 2700.0

@export var wing_area := 16.0
@export var wing_chord := 1.5
@export var max_lift_coefficient := 1.8
@export var zero_lift_aoa := -2.0
@export var stall_aoa := 15.0
@export var drag_coefficient_zero := 0.025
@export var induced_drag_factor := 0.05

@export var elevator_authority := 2.5
@export var aileron_authority := 3.0
@export var rudder_authority := 1.5
@export var control_speed_threshold := 15.0

@export var flap_lift_increase := 0.6
@export var flap_drag_increase := 0.8
@export var flaps_extended := false

@export var gear_friction := 3.5
@export var brake_force := 1200.0

var elevator_trim := 0.0
var throttle := 0.0

var indicated_airspeed := 0.0
var angle_of_attack := 0.0
var is_stalled := false

func _ready():
	mass = 1200.0
	angular_damp = 2.5
	linear_damp = 0.05
	elevator_trim = 0.1

func _physics_process(delta):
	handle_input(delta)
	calculate_airspeed()
	apply_engine_thrust()
	apply_aerodynamics()
	apply_control_surfaces()
	apply_ground_forces()
	
	if global_position.y < -2.0:
		print("FALLING THROUGH! Pos: ", global_position, " Vel: ", linear_velocity)
	
	if not linear_velocity.is_finite():
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState3D):
	state.linear_velocity = state.linear_velocity.limit_length(120.0)
	state.angular_velocity = state.angular_velocity.limit_length(4.0)

func handle_input(delta):
	if Input.is_action_pressed("ui_page_up"):
		throttle = min(throttle + delta * 0.5, 1.0)
	if Input.is_action_pressed("ui_page_down"):
		throttle = max(throttle - delta * 0.5, 0.0)
	
	if Input.is_action_just_pressed("ui_accept"):
		flaps_extended = !flaps_extended
	
	if Input.is_action_pressed("ui_home"):
		elevator_trim += delta * 0.3
	if Input.is_action_pressed("ui_end"):
		elevator_trim -= delta * 0.3
	elevator_trim = clamp(elevator_trim, -0.3, 0.3)

func calculate_airspeed():
	var velocity_local := global_basis.inverse() * linear_velocity
	indicated_airspeed = velocity_local.length()
	
	if indicated_airspeed > 1.0:
		var forward_speed := -velocity_local.z
		var vertical_speed := velocity_local.y
		angle_of_attack = rad_to_deg(atan2(vertical_speed, forward_speed))
	else:
		angle_of_attack = 0.0

func apply_engine_thrust():
	var prop_efficiency := 1.0 - (indicated_airspeed / 80.0)
	prop_efficiency = clamp(prop_efficiency, 0.3, 1.0)
	
	var thrust := engine_power * throttle * prop_efficiency
	var forward := -global_basis.z
	
	apply_central_force(forward * thrust)

func apply_aerodynamics():
	if indicated_airspeed < 0.5:
		return
	
	var air_density := 1.225
	var dynamic_pressure := 0.5 * air_density * indicated_airspeed * indicated_airspeed
	
	var effective_aoa := angle_of_attack - zero_lift_aoa
	if flaps_extended:
		effective_aoa += 5.0
	
	var cl := 0.0
	if effective_aoa < stall_aoa:
		cl = max_lift_coefficient * sin(deg_to_rad(effective_aoa * 2.0))
	else:
		cl = max_lift_coefficient * 0.4
		is_stalled = true
	
	if flaps_extended:
		cl *= (1.0 + flap_lift_increase)
	
	var lift := dynamic_pressure * wing_area * cl
	apply_central_force(global_basis.y * lift)
	
	var cd_parasite := drag_coefficient_zero
	if flaps_extended:
		cd_parasite *= (1.0 + flap_drag_increase)
	
	var cd_induced := induced_drag_factor * cl * cl
	
	var total_cd := cd_parasite + cd_induced
	var drag := dynamic_pressure * wing_area * total_cd
	
	var drag_direction := -linear_velocity.normalized()
	apply_central_force(drag_direction * drag)
	
	is_stalled = abs(angle_of_attack) > stall_aoa and indicated_airspeed < 35.0

func apply_control_surfaces():
	if indicated_airspeed < 5.0:
		return
	
	var authority: float = clamp(indicated_airspeed / control_speed_threshold, 0.0, 1.0)
	
	var elevator := (Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
	elevator += elevator_trim
	
	var aileron := (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"))
	
	var rudder := 0.0
	if Input.is_action_pressed("ui_focus_prev"):
		rudder = -1.0
	if Input.is_action_pressed("ui_focus_next"):
		rudder = 1.0
	
	var torque := Vector3(
		elevator * elevator_authority * 1000.0,
		rudder * rudder_authority * 800.0,
		-aileron * aileron_authority * 1200.0
	) * authority
	
	torque.y += aileron * 0.3 * authority * 400.0
	
	apply_torque(torque)

func apply_ground_forces():
	if not is_on_ground():
		return
	
	var lateral_vel := global_basis.x * linear_velocity.dot(global_basis.x)
	apply_central_force(-lateral_vel * gear_friction)
	
	var forward_vel := global_basis.z * linear_velocity.dot(global_basis.z)
	apply_central_force(-forward_vel * 0.3)
	
	if Input.is_action_pressed("ui_select"):
		var brake_dir := -linear_velocity.normalized()
		apply_central_force(brake_dir * brake_force)
	
	if linear_velocity.y < 0:
		linear_velocity.y *= 0.5

func is_on_ground() -> bool:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.DOWN * 2.5
	)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	return result.size() > 0

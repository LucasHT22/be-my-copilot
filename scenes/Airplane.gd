extends CharacterBody3D

@export var mass: float = 1200.0
@export var engine_power: float = 55.0
@export var max_speed: float = 95.0

@export var lift_coefficient: float = 22.0
@export var drag_coefficient: float = 0.0025
@export var gravity: float = 9.81

@export var stall_speed: float = 18.0
@export var flap_lift_multiplier: float = 1.6
@export var flap_drag_multiplier: float = 1.4

@export var pitch_rate: float = 1.6
@export var roll_rate: float = 2.4
@export var yaw_rate: float = 0.6

@export var angular_damping: float = 1.9
@export var max_pitch_deg: float = 30.0
@export var max_roll_deg: float = 60.0

var speed: float = 0.0
var throttle: float = 0.0
var flaps: bool = false
var stalled: bool = false

var angular_velocity: Vector3 = Vector3.ZERO

# HUD
var airspeed: float
var vertical_speed: float
var altitude: float
var stall_warning: bool

func _ready():
	floor_snap_length = 1.5

func _physics_process(delta):
	handle_input(delta)
	apply_flight_physics(delta)
	move_and_slide()
	update_hud_data()

func handle_input(delta):
	# throttle
	if Input.is_action_pressed("ui_up"):
		throttle += delta
	if Input.is_action_pressed("ui_down"):
		throttle -= delta
	throttle = clamp(throttle, 0.0, 1.0)
	
	# flaps
	if Input.is_action_just_pressed("ui_focus_next"):
		flaps = !flaps
	
	# pitch
	var pitch_input := Input.get_action_strength("ui_accept") - Input.get_action_strength("ui_cancel")
	angular_velocity.x += pitch_input * pitch_rate * delta
	
	# roll
	var roll_input := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_cancel")
	angular_velocity.z += roll_input * roll_rate * delta
	
	# yaw
	var yaw_input := roll_input
	if not is_on_floor():
		yaw_input *= 0.35
	angular_velocity.y += yaw_input * yaw_rate * delta

func apply_flight_physics(delta):
	# rotation
	rotation += angular_velocity * delta
	angular_velocity *= exp(-angular_damping * delta)
	
	rotation.x = clamp(rotation.x, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))
	rotation.z = clamp(rotation.z, deg_to_rad(-max_roll_deg), deg_to_rad(max_roll_deg))
	
	# thrust
	speed += engine_power * throttle * delta
	
	# drag
	var drag := drag_coefficient * speed * speed
	if flaps:
		drag *= flap_drag_multiplier
	speed -= drag * delta
	speed = clamp(speed, 0.0, max_speed)
	
	# direction
	var forward := -transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	
	# lift
	stalled = false
	if not is_on_floor():
		var aoa := forward.dot(Vector3.UP)
		var lift_factor: float = clamp((speed / stall_speed) * aoa, 0.0, 1.5)
		
		var lift: float = lift_coefficient * lift_factor
		if flaps:
			lift *= flap_lift_multiplier
		
		# stall
		if speed < stall_speed:
			stalled = true
			lift *= 0.35
			angular_velocity.x += deg_to_rad(12.0) * delta
			angular_velocity.z += randf_range(-0.4, 0.4) * delta
		
		velocity.y += lift * delta
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		speed *= 0.985
	
	# banked turn force
	var bank := sin(rotation.z)
	velocity += transform.basis.x * bank * speed * 0.025

func update_hud_data():
	airspeed = speed
	vertical_speed = velocity.y
	altitude = global_position.y
	stall_warning = stalled or (speed < stall_speed * 1.15 and not is_on_floor())

extends CharacterBody3D

@export var thrust_power := 25.0
@export var max_speed := 60.0

@export var lift_power := 18.0
@export var gravity := 9.8

@export var base_drag := 0.985
@export var flap_drag := 0.96
@export var ground_drag := 0.90

@export var turn_speed_air := 1.5
@export var turn_speed_ground := 0.6
@export var pitch_speed := 1.2

@export var max_pitch := 25.0
@export var max_roll := 30.0

@export var flap_lift_multiplier := 1.5

@export var stall_speed := 14.0
@export var brake_power := 30.0

var speed := 0.0
var flaps := false

func _ready():
	floor_snap_length = 1.5

func _physics_process(delta):
	handle_input(delta)
	apply_movement(delta)
	move_and_slide()

func handle_input(delta):
	if Input.is_action_pressed("ui_up"):
		speed += thrust_power * delta
	if Input.is_action_pressed("ui_down"):
		speed -= thrust_power * delta
	
	speed = clamp(speed, 0.0, 60.0)
	
	if Input.is_action_just_pressed("ui_focus_next"):
		flaps = !flaps
	
	var turn_input := 0.0
	if Input.is_action_pressed("ui_left"):
		turn_input += 1
	if Input.is_action_pressed("ui_right"):
		turn_input -= 1
	
	var turn_speed = turn_speed_ground if is_on_floor() else turn_speed_air
	rotate_y(turn_input * turn_speed * delta)
	
	var target_roll = turn_input * deg_to_rad(max_roll)
	rotation.z = lerp(rotation.z, target_roll, 5.0 * delta)
	
	var pitch_input := 0.0
	if Input.is_action_pressed("ui_accept"):
		pitch_input += 1
	if Input.is_action_pressed("ui_cancel"):
		pitch_input -= 1
	
	rotation.x = clamp(
		rotation.x + pitch_input * pitch_speed * delta,
		deg_to_rad(-max_pitch),
		deg_to_rad(max_pitch)
	)

func apply_movement(delta):
	var forward = -transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	
	if not is_on_floor():
		var lift_factor: float = clamp(speed / stall_speed, 0.0, 1.2)
		var lift: float = lift_power * lift_factor


		if flaps:
			lift *= flap_lift_multiplier

		velocity.y += lift * delta
		
		if speed < stall_speed:
			rotation.x += deg_to_rad(25) * delta
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	
	if is_on_floor():
		speed *= ground_drag
	elif flaps:
		speed *= flap_drag
	else:
		speed *= base_drag
	
	if is_on_floor() and Input.is_action_pressed("ui_select"):
		speed = max(speed - brake_power * delta, 0.0)

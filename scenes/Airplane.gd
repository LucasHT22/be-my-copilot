extends CharacterBody3D

@export var thrust_power := 25.0
@export var lift_power := 18.0
@export var drag := 0.98
@export var gravity := 9.8

var speed := 0.0

func _physics_process(delta):
	if Input.is_action_pressed("ui_up"):
		speed += thrust_power * delta
	if Input.is_action_pressed("ui_down"):
		speed -= thrust_power * delta
	
	speed = clamp(speed, 0.0, 60.0)
	
	velocity = -transform.basis.z * speed
	
	if speed > 15:
		velocity.y += (speed / 60.0) * lift_power
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	speed *= drag
	
	move_and_slide()

func _ready():
	floor_snap_length = 1.5

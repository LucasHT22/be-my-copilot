extends CanvasLayer

@export var plane: NodePath

@onready var speed_label: Label = $VBoxContainer/SpeedLabel
@onready var flaps_label: Label = $VBoxContainer/FlapsLabel
@onready var stall_label: Label = $VBoxContainer/StallLabel
@onready var altitude_label: Label = $VBoxContainer/AltitudeLabel
@onready var aoa_label: Label = $VBoxContainer/AoALabel
@onready var throttle_label: Label = $VBoxContainer/ThrottleLabel
@onready var trim_label: Label = $VBoxContainer/TrimLabel

var plane_ref: RigidBody3D

func _ready():
	plane_ref = get_node(plane) as RigidBody3D
	stall_label.visible = false

func _process(_delta):
	if not plane_ref:
		return
	
	var speed_knots: float = plane_ref.indicated_airspeed * 1.94384
	speed_label.text = "IAS: %.0f kt" % speed_knots
	
	var altitude_feet: float = plane_ref.global_position.y * 3.28084
	altitude_label.text = "ALT: %.0f ft" % altitude_feet
	
	aoa_label.text = "AoA: %.1f°" % plane_ref.angle_of_attack
	if abs(plane_ref.angle_of_attack) > 12.0:
		aoa_label.modulate = Color.ORANGE
	else:
		aoa_label.modulate = Color.WHITE
	
	throttle_label.text = "THR: %d%%" % int(plane_ref.throttle * 100)
	
	flaps_label.text = "FLAPS: " + ("DOWN" if plane_ref.flaps_extended else "UP")
	
	var trim_percent: float = plane_ref.elevator_trim / 0.3 * 100.0
	trim_label.text = "TRIM: %+.0f%%" % trim_percent
	
	if stall_label:
		if plane_ref.is_stalled:
			stall_label.visible = true
			stall_label.text = "⚠ STALL WARNING"
			stall_label.modulate = Color.RED
			stall_label.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5
		else:
			stall_label.visible = false

extends CanvasLayer

@export var plane: NodePath

@onready var speed_label: Label = $VBoxContainer/SpeedLabel
@onready var flaps_label: Label = $VBoxContainer/FlapsLabel
@onready var stall_label: Label = $VBoxContainer/StallLabel
@onready var altitude_label: Label = $VBoxContainer/AltitudeLabel

var plane_ref

func _ready():
	plane_ref = get_node(plane)
	stall_label.visible = false

func _process(_delta):
	if not plane_ref:
		return
	
	speed_label.text = "Speed: %.1f" % plane_ref.speed
	flaps_label.text = "Flaps: " + ("ON" if plane_ref.flaps else "OFF")
	altitude_label.text = "Altitude: %.1f m" % plane_ref.global_position.y
	
	if plane_ref.stalled:
		stall_label.visible = true
		stall_label.text = "⚠ STALL"
		stall_label.modulate = Color.RED
	else:
		stall_label.visible = false

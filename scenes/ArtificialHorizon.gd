extends Control

@export var plane_path: NodePath
@export var minimap: Control
@export var spacing := 20

var plane_ref: RigidBody3D

func _ready():
	if plane_path:
		plane_ref = get_node(plane_path) as RigidBody3D
	
	position_next_to_minimap()

func _process(delta):
	if plane_ref:
		queue_redraw()

func position_next_to_minimap():
	if minimap:
		size = minimap.size
		
		position = Vector2(
			minimap.position.x - size.x - spacing,
			minimap.position.y
		)

func _draw():
	if not plane_ref:
		return
	
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - 10
	
	var velocity_local = plane_ref.global_basis.inverse() * plane_ref.linear_velocity
	var pitch = 0.0
	if velocity_local.length() > 1.0:
		pitch = rad_to_deg(atan2(velocity_local.y, -velocity_local.z))
	
	var roll = -plane_ref.rotation.z
	
	draw_circle(center, radius + 5, Color(0.1, 0.1, 0.1, 0.9))
	draw_arc(center, radius + 5, 0, TAU, 64, Color(0.3, 0.3, 0.3), 2.0)
	
	var display_pitch = clamp(pitch, -30, 30)
	var pitch_offset = display_pitch * (radius / 30.0)
	
	var sky_points = PackedVector2Array()
	for i in range(65):
		var angle = PI + (PI * i / 64.0)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		sky_points.append(point)
	
	var horizon_left = center + Vector2(-radius, pitch_offset).rotated(roll)
	var horizon_right = center + Vector2(radius, pitch_offset).rotated(roll)
	sky_points.append(horizon_right)
	sky_points.append(horizon_left)
	
	draw_colored_polygon(sky_points, Color(0.3, 0.6, 1.0, 0.8))
	
	draw_line(horizon_left, horizon_right, Color.WHITE, 3.0)
	
	for pitch_line in [-20, -10, 10, 20]:
		var line_offset = pitch_offset + (pitch_line * (radius / 30.0))
		var line_length = 40 if pitch_line % 20 == 0 else 30
		
		var left = center + Vector2(-line_length, line_offset).rotated(roll)
		var right = center + Vector2(line_length, line_offset).rotated(roll)
		
		var line_color = Color.WHITE if pitch_line > 0 else Color(0.8, 0.8, 0.8)
		draw_line(left, right, line_color, 2.0)
		
		var label = str(abs(pitch_line))
		draw_string(ThemeDB.fallback_font, left + Vector2(-20, 5).rotated(roll), label, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, line_color)
		draw_string(ThemeDB.fallback_font, right + Vector2(10, 5).rotated(roll), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, line_color)
	
	var aircraft_width = 60
	var aircraft_height = 8
	
	draw_line(center + Vector2(-aircraft_width, 0), center + Vector2(-15, 0), Color.YELLOW, 4.0)
	draw_line(center + Vector2(15, 0), center + Vector2(aircraft_width, 0), Color.YELLOW, 4.0)
	
	draw_circle(center, 4, Color.YELLOW)
	
	draw_line(center, center + Vector2(0, -15), Color.YELLOW, 3.0)
	
	draw_roll_indicator(center, radius)

func draw_roll_indicator(center: Vector2, radius: float):
	var roll = -plane_ref.rotation.z
	
	for angle_deg in [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]:
		var angle_rad = deg_to_rad(angle_deg)
		var mark_start = center + Vector2(0, -radius - 10).rotated(angle_rad)
		var mark_length = 15 if angle_deg % 30 == 0 else 10
		var mark_end = center + Vector2(0, -radius - 10 - mark_length).rotated(angle_rad)
		
		var mark_color = Color.YELLOW if angle_deg == 0 else Color.WHITE
		var mark_width = 3.0 if angle_deg == 0 else 2.0
		draw_line(mark_start, mark_end, mark_color, mark_width)
	
	var pointer_pos = center + Vector2(0, -radius - 5).rotated(roll)
	var triangle = PackedVector2Array([
		pointer_pos,
		pointer_pos + Vector2(-8, -12).rotated(roll),
		pointer_pos + Vector2(8, -12).rotated(roll)
	])
	draw_colored_polygon(triangle, Color.YELLOW)

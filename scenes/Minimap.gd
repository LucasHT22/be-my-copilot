extends Control

@export var world: Node3D
@export var player: Node3D
@export var map_size := 200
@export var map_range := 2000.0
@export var update_interval := 0.5

var update_timer := 0.0

func _ready():
	position = Vector2(
		get_viewport().size.x - map_size - 20,
		get_viewport().size.y - map_size - 20
	)
	size = Vector2(map_size, map_size)

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		queue_redraw()

func _draw():
	if player == null or world == null:
		return
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.3), false, 2.0)
	
	var center = size / 2
	var player_pos = player.global_position
	
	for i in range(1, 4):
		var radius = (size.x / 2) * (i / 3.0)
		draw_arc(center, radius, 0, TAU, 32, Color(0.2, 0.2, 0.2, 0.5), 1.0)
		
		draw_line(Vector2(center.x, 5), Vector2(center.x, 15), Color(0.5, 0.5, 0.5))
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 5, 25), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
		
	if world.chunks:
		for coord in world.chunks.keys():
			if is_airport_chunk(coord):
				var airport_world_pos = Vector3(
					coord.x * 256 + 128,
					0,
					coord.y * 256 + 128
				)
				
				var relative_pos = airport_world_pos -  player_pos
				var distance = Vector2(relative_pos.x, relative_pos.z).length()
				
				if distance < map_range:
					var map_pos = world_to_map(relative_pos)
					
					var airport_color = Color(1.0, 0.5, 0.0)
					draw_circle(map_pos, 4, airport_color)
					draw_arc(map_pos, 5, 0, TAU, 16, Color.WHITE, 1.5)
					
					var dist_nm = int(distance * 0.0054)
					var label = str(dist_nm) + "nm"
					draw_string(ThemeDB.fallback_font, map_pos + Vector2(8, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	
	draw_player_icon(center)

func draw_player_icon(pos: Vector2):
	var heading = -player.rotation.y
	var size_icon = 8.0
	
	var points = PackedVector2Array([
		pos + Vector2(0, -size_icon).rotated(heading),
		pos + Vector2(-size_icon * 0.6, size_icon * 0.6).rotated(heading),
		pos + Vector2(size_icon * 0.6, size_icon * 0.6).rotated(heading)
	])
	
	draw_colored_polygon(points, Color(0.2, 0.8, 1.0))
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.5)

func world_to_map(world_offset: Vector3) -> Vector2:
	var center = size / 2
	var scale_factor = (size.x / 2) / map_range
	
	return Vector2(
		center.x + world_offset.x * scale_factor,
		center.y + world_offset.z * scale_factor
	)

func is_airport_chunk(coord: Vector2i) -> bool:
	return (coord.x * 73856093 ^ coord.y * 19349663) % 40 == 0

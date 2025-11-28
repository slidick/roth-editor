extends Control

var jump: int = 1
var data: Array = []
var play_position: float = 0
var start_position: float = 0
var end_position: float = 0

func setup(p_entry: Dictionary, p_reset: bool = false) -> void:
	data = p_entry.data
	if p_reset:
		start_position = 0
		play_position = 0
		if is_equal_approx(size.x, 0):
			await get_tree().process_frame
		end_position = size.x
	jump = max(roundi(len(data) / 10000.0), 1)
	queue_redraw()


func update_position(p_play_position: float) -> void:
	play_position = p_play_position
	queue_redraw()


func update_start_marker(p_start_position: float) -> void:
	start_position = p_start_position
	queue_redraw()


func update_end_marker(p_end_position: float) -> void:
	end_position = p_end_position
	queue_redraw()


func _draw() -> void:
	var vertices := []
	for i in range(0, len(data), jump):
		var v1 := Vector2(
			(float(i) / len(data)) * float(size.x),
			(size.y / 2) + (data[i].x * (size.y/2)),
		)
		vertices.append(v1)
	if not vertices.is_empty():
		draw_polyline(vertices, Color.WEB_GREEN, 1.0, true)
	
	if play_position != 0:
		var x: float = play_position * (size.x - (size.x - %EndMarker.position.x - %EndMarker.size.x/2))
		draw_dashed_line(Vector2(x, 0), Vector2(x, size.y), Color.LIGHT_STEEL_BLUE, 2, 10, false, true)
	
	if start_position != 0:
		draw_line(Vector2(start_position, 0), Vector2(start_position, size.y), Color.BROWN, 2, true)
		draw_rect(Rect2(0,0,start_position-2,size.y), Color(0.5, 0.5, 0.5, 0.5))
	
	if roundi(end_position) != size.x and end_position != 0:
		draw_line(Vector2(end_position, 0), Vector2(end_position, size.y), Color.BROWN, 2, true)
		draw_rect(Rect2(end_position+2,0,size.x-end_position-2,size.y), Color(0.5, 0.5, 0.5, 0.5))

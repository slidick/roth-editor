extends TextureRect

var draw_size: int = 1

func _draw() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	if %RotateCanvasCheckBox.button_pressed:
		mouse_pos.x = mouse_pos.y
		mouse_pos.y = get_global_mouse_position().x
	var _draw_size: int = draw_size - 1
	var vertex_1 := Vector2i(floori(mouse_pos.x)-int(_draw_size/2.0), floori(mouse_pos.y)-int(_draw_size/2.0))
	var vertex_2 := Vector2i(ceili(mouse_pos.x)+roundi(_draw_size/2.0), floori(mouse_pos.y)-int(_draw_size/2.0))
	var vertex_3 := Vector2i(ceili(mouse_pos.x)+roundi(_draw_size/2.0), ceili(mouse_pos.y)+roundi(_draw_size/2.0))
	var vertex_4 := Vector2i(floori(mouse_pos.x)-int(_draw_size/2.0), ceili(mouse_pos.y)+roundi(_draw_size/2.0))
	draw_dashed_line(vertex_1, vertex_2, Color.GHOST_WHITE, -1, 0.1)
	draw_dashed_line(vertex_2, vertex_3, Color.GHOST_WHITE, -1, 0.1)
	draw_dashed_line(vertex_3, vertex_4, Color.GHOST_WHITE, -1, 0.1)
	draw_dashed_line(vertex_4, vertex_1, Color.GHOST_WHITE, -1, 0.1)

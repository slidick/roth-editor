extends Node2D

var vertices: Array = []
var ctrl_pressed: bool = false


func _draw() -> void:
	draw_box()


func _on_free_shape_check_box_pressed() -> void:
	%FreeOptionsContainer.show()


func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_CTRL:
		if event.pressed:
			ctrl_pressed = true
		else:
			ctrl_pressed = false
	
	if len(vertices) > 0:
		if event is InputEventMouseMotion:
			queue_redraw()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			vertices.pop_back()
			queue_redraw()
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					var vertex: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
					if len(vertices) > 2 and vertex == vertices[0]:
						finalize()
					else:
						if ctrl_pressed and len(vertices) > 0:
							if abs(vertex.x - vertices[-1].x) < abs(vertex.y - vertices[-1].y):
								vertex.x = vertices[-1].x
							else:
								vertex.y = vertices[-1].y
						vertices.append(vertex)
						queue_redraw()
	
	if event is InputEventKey:
		if event.keycode == KEY_ENTER:
			if len(vertices) < 3:
				return
			finalize()


func finalize() -> void:
	var scaled_vertices: Array = []
	for i in range(len(vertices)):
		scaled_vertices.append(vertices[i] * Roth.SCALE_2D_WORLD)
	
	if Geometry2D.is_polygon_clockwise(scaled_vertices):
		scaled_vertices.reverse()
	
	var new_sector: Sector = %Map2D.map.add_sector(scaled_vertices, %DrawModeContainer.get_sector_options())
	vertices.clear()
	%BoxSizeLabel.hide()
	%Map2D.queue_redraw()
	%Map2D.check_for_merges([new_sector])
	%Map2D.show_vertices(false, [new_sector])
	Roth.editor_action.emit(%Map2D.map.map_info, "Draw Free Sector")


func draw_box() -> void:
	if len(vertices) == 0:
		%BoxSizeLabel.hide()
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	
	if len(vertices) > 1:
		for i in range(len(vertices)-1):
			draw_line(vertices[i], vertices[i+1], Color.GHOST_WHITE, %Map2D.line_width, true)
	
	if ctrl_pressed:
		if abs(current_mouse.x - vertices[-1].x) < abs(current_mouse.y - vertices[-1].y):
			current_mouse.x = vertices[-1].x
		else:
			current_mouse.y = vertices[-1].y
	
	draw_line(vertices[-1], current_mouse, Color.GHOST_WHITE, %Map2D.line_width, true)
	var length: Vector2 = current_mouse - vertices[-1]
	%BoxSizeLabel.text = "%.0f x %.0f \n %.0f" % [length.x * Roth.SCALE_2D_WORLD, length.y * Roth.SCALE_2D_WORLD, length.length() * Roth.SCALE_2D_WORLD]
	%BoxSizeLabel.show()
	%BoxSizeLabel.position = (%SubViewportContainer2D.size / 2) - (%BoxSizeLabel.size / 2) - (%Camera2D.global_position - (vertices[-1] + current_mouse) / 2) * %Camera2D.zoom.x

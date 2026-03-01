extends Node2D

var vertices: Array = []


func _draw() -> void:
	draw_box()


func _on_free_shape_check_box_pressed() -> void:
	%FreeOptionsContainer.show()


func handle_input(event: InputEvent) -> void:
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
						vertices.append(vertex)
	
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
	
	%Map2D.queue_redraw()
	
	# Check for merges
	for sector: Sector in %Map2D.map.sectors:
		for face_ref: WeakRef in sector.faces:
			var face: Face = face_ref.get_ref()
			for new_face_ref: WeakRef in new_sector.faces:
				var new_face: Face = new_face_ref.get_ref()
				if face.sister and face.sister.get_ref() == new_face:
					pass
				elif new_face.v2 == face.v1 and new_face.v1 == face.v2:
					face.sister = weakref(new_face)
					new_face.sister = weakref(face)
					face.initialize_mesh()
					new_face.initialize_mesh()
	
	%Map2D.show_vertices(false, [new_sector])
	Roth.editor_action.emit(%Map2D.map.map_info, "Draw Free Sector")


func draw_box() -> void:
	if len(vertices) == 0:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	
	if len(vertices) > 1:
		for i in range(len(vertices)-1):
			draw_line(vertices[i], vertices[i+1], Color.GHOST_WHITE, %Map2D.line_width, true)
	draw_line(vertices[-1], current_mouse, Color.GHOST_WHITE, %Map2D.line_width, true)

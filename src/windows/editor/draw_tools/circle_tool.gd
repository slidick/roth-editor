extends Node2D

var start_draw: bool = false
var start_position := Vector2.ZERO


func _draw() -> void:
	draw_box()


func _on_circle_shape_check_box_pressed() -> void:
	%CircleOptionsContainer.show()


func handle_input(event: InputEvent) -> void:
	if start_draw:
		if event is InputEventMouseMotion:
			queue_redraw()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			start_draw = false
			start_position = Vector2.ZERO
			%BoxSizeLabel.hide()
			queue_redraw()
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					start_draw = true
					start_position = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
				else:
					if start_draw == false:
						return
					
					var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
					var size: Vector2 = (current_mouse - start_position).snappedf(%Map2D.snap)
					var radius: float = size.length()
					
					if is_equal_approx(radius, 0.0):
						start_draw = false
						start_position = Vector2.ZERO
						%BoxSizeLabel.hide()
						queue_redraw()
						return
					
					var vertex_count := int(%CircleToolVerticesSpinBox.value)
					var angle_increment: float = 2 * PI / vertex_count
					var starting_angle: float = -PI/2
					var vertices: Array = []
					for i in range(vertex_count):
						var angle: float = (i * angle_increment) + starting_angle
						var pos := Vector2(cos(angle), sin(angle)) * radius + start_position
						vertices.append(pos*Roth.SCALE_2D_WORLD)
					
					var new_sector: Sector = %Map2D.map.add_sector(vertices, %DrawModeContainer.get_sector_options())
					start_draw = false
					start_position = Vector2.ZERO
					%BoxSizeLabel.hide()
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
					Roth.editor_action.emit(%Map2D.map.map_info, "Draw Circle Sector")


func draw_box() -> void:
	if not start_draw:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	var size: Vector2 = (current_mouse - start_position).snappedf(%Map2D.snap)
	var radius: float = size.length()
	var vertex_count := int(%CircleToolVerticesSpinBox.value)
	var angle_increment: float = 2 * PI / vertex_count
	var starting_angle: float = -PI/2
	var vertices: Array = []
	for i in range(vertex_count):
		var angle: float = (i * angle_increment) + starting_angle
		var pos := Vector2(cos(angle), sin(angle)) * radius + start_position
		vertices.append(pos)
	
	for i in range(len(vertices)):
		draw_line(vertices[i], vertices[(i+1)%len(vertices)], Color.GHOST_WHITE, %Map2D.line_width, true)
		draw_circle(vertices[i], 2, Color.GHOST_WHITE, false, %Map2D.line_width, true)
	
	%BoxSizeLabel.text = "Radius: %.0f" % (size.length() * Roth.SCALE_2D_WORLD)
	%BoxSizeLabel.show()
	%BoxSizeLabel.position = (%SubViewportContainer2D.size / 2) - (%BoxSizeLabel.size / 2) - (%Camera2D.global_position - start_position) * %Camera2D.zoom.x

extends Node2D

var start_box_draw: bool = false
var start_box_position := Vector2.ZERO


func _draw() -> void:
	draw_box()


func _on_box_shape_check_box_pressed() -> void:
	%BoxOptionsContainer.show()


func handle_input(event: InputEvent) -> void:
	if start_box_draw:
		if event is InputEventMouseMotion:
			queue_redraw()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			start_box_draw = false
			start_box_position = Vector2.ZERO
			%BoxSizeLabel.hide()
			queue_redraw()
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					start_box_draw = true
					start_box_position = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
				else:
					if start_box_draw == false:
						return
					
					if (start_box_position.x == (get_global_mouse_position() + global_position).snappedf(%Map2D.snap).x or 
							start_box_position.y == (get_global_mouse_position() + global_position).snappedf(%Map2D.snap).y
					):
						start_box_draw = false
						start_box_position = Vector2.ZERO
						%BoxSizeLabel.hide()
						queue_redraw()
						return
					
					var new_sector: Sector = %Map2D.map.add_sector(start_box_position * Roth.SCALE_2D_WORLD, (get_global_mouse_position() + global_position).snappedf(%Map2D.snap) * Roth.SCALE_2D_WORLD, %DrawModeContainer.get_sector_options())
					start_box_draw = false
					start_box_position = Vector2.ZERO
					%BoxSizeLabel.hide()
					queue_redraw()
					%Map2D.show_vertices(false)
					
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
									%Map2D.show_vertices(false)
									queue_redraw()
					
					Roth.editor_action.emit(%Map2D.map.map_info, "Draw Box Sector")


func draw_box() -> void:
	if not start_box_draw:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	var size: Vector2 = (current_mouse - start_box_position).snappedf(%Map2D.snap)
	draw_rect(Rect2(start_box_position.x, start_box_position.y, size.x, size.y), Color.GHOST_WHITE, false, %Map2D.line_width, true)
	%BoxSizeLabel.text = "%.0f x %.0f" % [size.x * Roth.SCALE_2D_WORLD, size.y * Roth.SCALE_2D_WORLD]
	%BoxSizeLabel.show()
	%BoxSizeLabel.position = (%SubViewportContainer2D.size / 2) - (%BoxSizeLabel.size / 2) - (%Camera2D.global_position - (start_box_position + current_mouse) / 2) * %Camera2D.zoom.x

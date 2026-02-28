extends Node2D

var start_draw: bool = false
var start_position := Vector2.ZERO


func _draw() -> void:
	draw_box()


func _on_stair_shape_check_box_pressed() -> void:
	%StairOptionsContainer.show()


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
					
					if (start_position.x == (get_global_mouse_position() + global_position).snappedf(%Map2D.snap).x or 
							start_position.y == (get_global_mouse_position() + global_position).snappedf(%Map2D.snap).y
					):
						start_draw = false
						start_position = Vector2.ZERO
						%BoxSizeLabel.hide()
						queue_redraw()
						return
					
					var stair_options: Dictionary = {
						"orientation": "horizontal" if %StairHorizontalCheckBox.button_pressed else "vertical",
						"steps": int(%StepsSpinBox.value),
						"height": int(%StepHeightSpinBox.value),
						"stepped_ceiling": %SteppedCeilingCheckBox2.button_pressed,
					}
					
					var new_sectors: Array = %Map2D.map.add_stairs(start_position * Roth.SCALE_2D_WORLD, (get_global_mouse_position() + global_position).snappedf(%Map2D.snap) * Roth.SCALE_2D_WORLD, %DrawModeContainer.get_sector_options(), stair_options)
					start_draw = false
					start_position = Vector2.ZERO
					%BoxSizeLabel.hide()
					queue_redraw()
					%Map2D.show_vertices(false)
					
					# Check for merges
					for sector: Sector in %Map2D.map.sectors:
						for face_ref: WeakRef in sector.faces:
							var face: Face = face_ref.get_ref()
							for new_sector: Sector in new_sectors:
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
					
					Roth.editor_action.emit(%Map2D.map.map_info, "Draw Stairs")


func draw_box() -> void:
	if not start_draw:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	var size: Vector2 = (current_mouse - start_position).snappedf(%Map2D.snap)
	draw_rect(Rect2(start_position.x, start_position.y, size.x, size.y), Color.GHOST_WHITE, false, %Map2D.line_width, true)
	
	var number_of_steps: int = int(%StepsSpinBox.value)
	if %StairHorizontalCheckBox.button_pressed:
		for i in range(number_of_steps-1):
			draw_line(Vector2(start_position.x + size.x * (i+1) / number_of_steps, start_position.y), Vector2(start_position.x + size.x * (i+1) /number_of_steps, current_mouse.y), Color.GHOST_WHITE, %Map2D.line_width, true)
	else:
		for i in range(number_of_steps-1):
			draw_line(Vector2(start_position.x, start_position.y + size.y * (i+1) / number_of_steps), Vector2(current_mouse.x, start_position.y + size.y * (i+1) /number_of_steps), Color.GHOST_WHITE, %Map2D.line_width, true)
	
	%BoxSizeLabel.text = "%.0f x %.0f" % [size.x * Roth.SCALE_2D_WORLD, size.y * Roth.SCALE_2D_WORLD]
	%BoxSizeLabel.show()
	%BoxSizeLabel.position = (%SubViewportContainer2D.size / 2) - (%BoxSizeLabel.size / 2) - (%Camera2D.global_position - (start_position + current_mouse) / 2) * %Camera2D.zoom.x

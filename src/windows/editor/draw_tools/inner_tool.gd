extends Node2D

var start_draw: bool = false
var start_position := Vector2.ZERO


func _on_inner_shape_check_box_pressed() -> void:
	%InnerOptionsControl.show()


func _draw() -> void:
	if not start_draw:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	var size: Vector2 = (current_mouse - start_position).snappedf(%Map2D.snap)
	var ratio: float = %InnerToolRatioSpinBox.value
	
	draw_rect(Rect2(start_position.x, start_position.y, size.x, size.y), Color.GHOST_WHITE, false, %Map2D.line_width, true)
	draw_rect(Rect2(start_position.x + (size.x * ratio / 2), start_position.y + (size.y * ratio / 2), size.x * (1-ratio), size.y * (1-ratio)), Color.GHOST_WHITE, false, %Map2D.line_width, true)
	
	draw_line(start_position, Vector2(start_position.x + (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)), Color.GHOST_WHITE, %Map2D.line_width, true)
	draw_line(Vector2(start_position.x + size.x, start_position.y), Vector2(start_position.x + size.x - (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)), Color.GHOST_WHITE, %Map2D.line_width, true)
	draw_line(Vector2(start_position.x, start_position.y + size.y), Vector2(start_position.x + (size.x * ratio / 2) , start_position.y + size.y - (size.y * ratio / 2)), Color.GHOST_WHITE, %Map2D.line_width, true)
	draw_line(Vector2(start_position.x + size.x, start_position.y + size.y), Vector2(start_position.x + size.x - (size.x * ratio / 2) , start_position.y + size.y - (size.y * ratio / 2)), Color.GHOST_WHITE, %Map2D.line_width, true)
	
	%BoxSizeLabel.text = "%.0f x %.0f" % [size.x * Roth.SCALE_2D_WORLD, size.y * Roth.SCALE_2D_WORLD]
	%BoxSizeLabel.show()
	%BoxSizeLabel.position = (%SubViewportContainer2D.size / 2) - (%BoxSizeLabel.size / 2) - (%Camera2D.global_position - (start_position + current_mouse) / 2) * %Camera2D.zoom.x


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
					
					var new_sectors: Array = []
					var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
					var size: Vector2 = (current_mouse - start_position).snappedf(%Map2D.snap)
					var ratio: float = %InnerToolRatioSpinBox.value
					
					# Top
					var vertices: Array = [
						start_position * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + size.x, start_position.y) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + size.x - (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD
					]
					new_sectors.append(%Map2D.map.add_sector(vertices, %DrawModeContainer.get_sector_options()))
					
					# Right
					vertices = [
						Vector2(start_position.x + size.x, start_position.y) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + size.x, start_position.y + size.y) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + size.x - (size.x * ratio / 2) , start_position.y + size.y - (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + size.x - (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
					]
					new_sectors.append(%Map2D.map.add_sector(vertices, %DrawModeContainer.get_sector_options()))
					
					# Bottom
					vertices = [
						Vector2(start_position.x + size.x, start_position.y + size.y) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x, start_position.y + size.y) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + (size.x * ratio / 2), start_position.y + size.y - (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + size.x - (size.x * ratio / 2) , start_position.y + size.y - (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
					]
					new_sectors.append(%Map2D.map.add_sector(vertices, %DrawModeContainer.get_sector_options()))
					
					# Left
					vertices = [
						Vector2(start_position.x, start_position.y + size.y) * Roth.SCALE_2D_WORLD,
						start_position * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
						Vector2(start_position.x + (size.x * ratio / 2), start_position.y + size.y - (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
					]
					new_sectors.append(%Map2D.map.add_sector(vertices, %DrawModeContainer.get_sector_options()))
					
					# Center
					if %InnerHollowCheckBox.button_pressed:
						vertices = [
							Vector2(start_position.x + (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
							Vector2(start_position.x + size.x - (size.x * ratio / 2), start_position.y + (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
							Vector2(start_position.x + size.x - (size.x * ratio / 2) , start_position.y + size.y - (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
							Vector2(start_position.x + (size.x * ratio / 2) , start_position.y + size.y - (size.y * ratio / 2)) * Roth.SCALE_2D_WORLD,
						]
						new_sectors.append(%Map2D.map.add_sector(vertices, %DrawModeContainer.get_sector_options()))
					


	
					
					
					start_draw = false
					start_position = Vector2.ZERO
					%BoxSizeLabel.hide()
					%Map2D.queue_redraw()
					
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
					
					%Map2D.show_vertices(false, new_sectors)
					Roth.editor_action.emit(%Map2D.map.map_info, "Draw Inner Sector")

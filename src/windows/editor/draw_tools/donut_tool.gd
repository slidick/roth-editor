extends Node2D

var start_draw: bool = false
var start_position := Vector2.ZERO


func _on_donut_shape_check_box_pressed() -> void:
	%DonutOptionsControl.show()


func _draw() -> void:
	if not start_draw:
		return
	var current_mouse: Vector2 = (get_global_mouse_position() + global_position).snappedf(%Map2D.snap)
	var size: Vector2 = (current_mouse - start_position).snappedf(%Map2D.snap)
	var radius: float = size.length()
	var vertex_count := int(%DonutToolVerticesSpinBox.value)
	var angle_increment: float = 2 * PI / vertex_count
	var starting_angle: float = -PI/2 + deg_to_rad(%DonutToolRotationSpinBox.value)
	var ratio: float = %DonutToolRatioSpinBox.value
	var vertices: Array = []
	var inner_vertices: Array = []
	for i in range(vertex_count):
		var angle: float = (i * angle_increment) + starting_angle
		var pos := Vector2(cos(angle), sin(angle)) * radius + start_position
		vertices.append(pos)
		inner_vertices.append(Vector2(cos(angle), sin(angle)) * radius * ratio + start_position)
	
	for i in range(len(vertices)):
		draw_line(vertices[i], vertices[(i+1)%len(vertices)], Color.GHOST_WHITE, %Map2D.line_width, true)
		draw_line(inner_vertices[i], inner_vertices[(i+1)%len(inner_vertices)], Color.GHOST_WHITE, %Map2D.line_width, true)
		
		draw_line(vertices[i], vertices[(i+1)%len(vertices)], Color.GHOST_WHITE, %Map2D.line_width, true)
		draw_line(vertices[(i+1)%len(vertices)], inner_vertices[(i+1)%len(inner_vertices)], Color.GHOST_WHITE, %Map2D.line_width, true)
		draw_line(inner_vertices[(i+1)%len(inner_vertices)], inner_vertices[i], Color.GHOST_WHITE, %Map2D.line_width, true)
		draw_line(inner_vertices[i], vertices[i], Color.GHOST_WHITE, %Map2D.line_width, true)
	
	%BoxSizeLabel.text = "Radius: %.0f" % (size.length() * Roth.SCALE_2D_WORLD)
	%BoxSizeLabel.show()
	%BoxSizeLabel.position = (%SubViewportContainer2D.size / 2) - (%BoxSizeLabel.size / 2) - (%Camera2D.global_position - start_position) * %Camera2D.zoom.x


func handle_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.ctrl_pressed and not event.alt_pressed:
		%DonutToolRatioSpinBox.set_value_no_signal(%DonutToolRatioSpinBox.value + 0.01)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.ctrl_pressed and not event.alt_pressed:
		%DonutToolRatioSpinBox.set_value_no_signal(%DonutToolRatioSpinBox.value - 0.01)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.alt_pressed and not event.ctrl_pressed:
		%DonutToolVerticesSpinBox.set_value_no_signal(%DonutToolVerticesSpinBox.value + 1)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.alt_pressed and not event.ctrl_pressed:
		%DonutToolVerticesSpinBox.set_value_no_signal(%DonutToolVerticesSpinBox.value - 1)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.alt_pressed and event.ctrl_pressed:
		%DonutToolRotationSpinBox.set_value_no_signal(%DonutToolRotationSpinBox.value + 1)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.alt_pressed and event.ctrl_pressed:
		%DonutToolRotationSpinBox.set_value_no_signal(%DonutToolRotationSpinBox.value - 1)
		queue_redraw()
	
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
					var radius: float = size.length()
					var vertex_count := int(%DonutToolVerticesSpinBox.value)
					var angle_increment: float = 2 * PI / vertex_count
					var starting_angle: float = -PI/2 + deg_to_rad(%DonutToolRotationSpinBox.value)
					var ratio: float = %DonutToolRatioSpinBox.value
					var vertices: Array = []
					var inner_vertices: Array = []
					for i in range(vertex_count):
						var angle: float = (i * angle_increment) + starting_angle
						var pos := Vector2(cos(angle), sin(angle)) * radius + start_position
						vertices.append(pos)
						inner_vertices.append(Vector2(cos(angle), sin(angle)) * radius * ratio + start_position)
					
					for i in range(len(vertices)):
						var vertices_scaled: Array = [
							vertices[i] * Roth.SCALE_2D_WORLD,
							vertices[(i+1)%len(vertices)] * Roth.SCALE_2D_WORLD,
							inner_vertices[(i+1)%len(vertices)] * Roth.SCALE_2D_WORLD,
							inner_vertices[i] * Roth.SCALE_2D_WORLD,
						]
						new_sectors.append(%Map2D.map.add_sector(vertices_scaled, %DrawModeContainer.get_sector_options()))
					
					if %DonutHollowCheckBox.button_pressed:
						new_sectors.append(%Map2D.map.add_sector(inner_vertices.map(func (v: Vector2) -> Vector2: return v * Roth.SCALE_2D_WORLD), %DrawModeContainer.get_sector_options()))
					
					start_draw = false
					start_position = Vector2.ZERO
					%BoxSizeLabel.hide()
					%Map2D.queue_redraw()
					%Map2D.check_for_merges(new_sectors)
					%Map2D.show_vertices(false, new_sectors)
					Roth.editor_action.emit(%Map2D.map.map_info, "Draw Donut Sector")

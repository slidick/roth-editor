extends MarginContainer

var das: Dictionary = {}
var selected_rects: Array :
	get():
		return get_tree().get_nodes_in_group("palette_color_buttons").filter(func (color_rect: ColorRectButton) -> bool: return color_rect.selected)
var mouse_pressed: bool = false
var shift_pressed: bool = false
var start_box_draw: bool = false :
	set(p_start_box_draw):
		start_box_draw = p_start_box_draw
		queue_redraw()
var start_box_select_position := Vector2.ZERO


func load_das(p_das: Dictionary) -> void:
	das = p_das
	var node: Node = _create_palette_node(p_das.palette)
	if node:
		%DefaultPalette.add_child(node)


func reset() -> void:
	das = {}
	for child: Control in %DefaultPalette.get_children():
		child.queue_free()


func reload_original() -> void:
	get_tree().get_nodes_in_group("palette_color_buttons").all(
		func (color_rect: ColorRectButton) -> bool:
			color_rect.color = color_rect.original_color
			color_rect.hue_start_color = color_rect.original_color
			return true
	)
	update_palette()


func update_original() -> void:
	get_tree().get_nodes_in_group("palette_color_buttons").all(
		func (color_rect: ColorRectButton) -> bool:
			color_rect.original_color = color_rect.color
			return true
	)


func update_hue_start() -> void:
	get_tree().get_nodes_in_group("palette_color_buttons").all(
		func (color_rect: ColorRectButton) -> bool:
			color_rect.hue_start_color = color_rect.color
			return true
	)

func update_palette() -> void:
	var palette: Array = []
	var raw_palette: Array = []
	for vbox: Control in %DefaultPalette.get_child(0).get_child(0).get_children():
		for color_rect: ColorRectButton in vbox.get_children():
			raw_palette.append(floori(color_rect.color.r8/4.0))
			raw_palette.append(floori(color_rect.color.g8/4.0))
			raw_palette.append(floori(color_rect.color.b8/4.0))
			palette.append([color_rect.color.r8,color_rect.color.g8,color_rect.color.b8])
	das.raw_palette = raw_palette
	das.palette = palette


func _input(event: InputEvent) -> void:
	if start_box_draw and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		start_box_draw = false
		get_tree().get_nodes_in_group("palette_color_buttons").all(
			func (color_rect: ColorRectButton) -> bool:
				color_rect.hovered = false
				return true
		)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.ctrl_pressed:
				if not event.shift_pressed:
					selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
						color_rect_button.selected = false
						return true
					)
				start_box_draw = true
				start_box_select_position = get_global_mouse_position()
			else:
				mouse_pressed = true
				if event.shift_pressed:
					shift_pressed = true
				else:
					shift_pressed = false
		else:
			mouse_pressed = false
			if start_box_draw:
				get_tree().get_nodes_in_group("palette_color_buttons").all(
					func (color_rect: ColorRectButton) -> bool:
						var point_2 := Vector2(get_global_mouse_position().x, start_box_select_position.y)
						var point_4 := Vector2(start_box_select_position.x, get_global_mouse_position().y)
						if Geometry2D.is_point_in_polygon(color_rect.global_position+color_rect.size/2, [start_box_select_position, point_2, get_global_mouse_position(), point_4] ):
							color_rect.hovered = false
							color_rect.selected = true
						return true
				)
				start_box_draw = false
	
	if event is InputEventMouseMotion and start_box_draw and %SlowdownTimer.is_stopped():
		%SlowdownTimer.start()
		get_tree().get_nodes_in_group("palette_color_buttons").all(
			func (color_rect: ColorRectButton) -> bool:
				var point_2 := Vector2(get_global_mouse_position().x, start_box_select_position.y)
				var point_4 := Vector2(start_box_select_position.x, get_global_mouse_position().y)
				if Geometry2D.is_point_in_polygon(color_rect.global_position+color_rect.size/2, [start_box_select_position, point_2, get_global_mouse_position(), point_4] ):
					color_rect.hovered = true
				else:
					color_rect.hovered = false
				return true
		)
		queue_redraw()


func _draw() -> void:
	if start_box_draw:
		var current_mouse: Vector2 = (get_global_mouse_position())-global_position
		var start_box_select_position_use: Vector2 = start_box_select_position-global_position
		draw_dashed_line(start_box_select_position_use, Vector2(current_mouse.x, start_box_select_position_use.y), Color.GRAY, -1, 1.0, true)
		draw_dashed_line(start_box_select_position_use, Vector2(start_box_select_position_use.x, current_mouse.y), Color.GRAY, -1, 1.0, true)
		draw_dashed_line(current_mouse, Vector2(current_mouse.x, start_box_select_position_use.y), Color.GRAY, -1, 1.0, true)
		draw_dashed_line(current_mouse, Vector2(start_box_select_position_use.x, current_mouse.y), Color.GRAY, -1, 1.0, true)



func _create_palette_node(palette: Array) -> Control:
	if palette.is_empty():
		return
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var i: int = 0
	for j in range(16):
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for k in range(16):
			var color_rect := ColorRectButton.new()
			color_rect.color = Color(palette[i][0] / float(255), palette[i][1] / float(255), palette[i][2] / float(255))
			color_rect.original_color = color_rect.color
			color_rect.hue_start_color = color_rect.color
			color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			color_rect.add_to_group("palette_color_buttons")
			color_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			if j == 0 and k == 0:
				color_rect.selected = true
				%ColorPicker.color = color_rect.color
				%HueSlider.set_value_no_signal(color_rect.color.h)
			color_rect.mouse_entered.connect(
				func () -> void:
					if mouse_pressed:
						if not shift_pressed:
							selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
								color_rect_button.selected = false
								return true
							)
						color_rect.selected = true
			)
			color_rect.gui_input.connect(
				func (event: InputEvent) -> void:
					if event is InputEventWithModifiers and event.ctrl_pressed:
						return
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						if color_rect in selected_rects:
							color_rect.selected = false
							if not event.shift_pressed:
								selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
									color_rect_button.selected = false
									return true
								)
						else:
							if not event.shift_pressed:
								selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
									color_rect_button.selected = false
									return true
								)
							color_rect.selected = true
							%ColorPicker.color = color_rect.color
							%HueSlider.set_value_no_signal(color_rect.color.h)
			)
			vbox.add_child(color_rect)
			i += 1
		hbox.add_child(vbox)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(hbox)
	return margin


func _on_color_picker_color_changed(color: Color) -> void:
	selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
		color_rect_button.color = color
		return true
	)
	update_palette()


func _on_hue_shift_slider_value_changed(value: float) -> void:
	selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
		color_rect_button.color.h = color_rect_button.hue_start_color.h + value
		return true
	)
	update_palette()


func _on_reset_palette_button_pressed() -> void:
	reload_original()


func _on_hue_shift_slider_drag_ended(_value_changed: bool) -> void:
	%HueShiftSlider.set_value_no_signal(0)
	update_hue_start()


func _on_randomize_button_pressed() -> void:
	selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
		color_rect_button.color.r = randf()
		color_rect_button.color.g = randf()
		color_rect_button.color.b = randf()
		color_rect_button.hue_start_color = color_rect_button.color
		return true
	)


func _on_hue_slider_value_changed(value: float) -> void:
	selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
		color_rect_button.color.h = value
		return true
	)
	%ColorPicker.color.h = value
	update_palette()


func _on_reset_selected_button_pressed() -> void:
	selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
		color_rect_button.color = color_rect_button.original_color
		color_rect_button.hue_start_color = color_rect_button.original_color
		return true
	)


func _on_hue_slider_drag_ended(_value_changed: bool) -> void:
	update_hue_start()

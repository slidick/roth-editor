extends MarginContainer

var das: Dictionary = {}
var palette: Array = []
var selected_rects: Array :
	get():
		return get_tree().get_nodes_in_group("palette_color_remap_buttons").filter(func (color_rect: ColorRectButton) -> bool: return color_rect.selected)
var selected_color_rects: Array :
	get():
		return get_tree().get_nodes_in_group("palette_color_remap_color_buttons").filter(func (color_rect: ColorRectButton) -> bool: return color_rect.selected)
var mouse_pressed: bool = false


func load_das(p_das: Dictionary) -> void:
	das = p_das
	palette = p_das.palette.duplicate(true)
	var node: Node = _create_palette_node(p_das.palette)
	if node:
		%DefaultPalette.add_child(node)
		%PaletteSlider.set_value_no_signal(0)
		_on_palette_slider_value_changed(0)


func reload() -> void:
	if palette != das.palette:
		palette = das.palette.duplicate(true)
		for child: Control in %DefaultPalette.get_children():
			child.queue_free()
		var node: Node = _create_palette_node(das.palette)
		if node:
			%DefaultPalette.add_child(node)
			for child: Control in %ShadedPalette.get_children():
				child.queue_free()
			_on_palette_slider_value_changed(%PaletteSlider.value)


func reset() -> void:
	das = {}
	for child: Control in %DefaultPalette.get_children():
		child.queue_free()
	for child: Control in %ShadedPalette.get_children():
		child.queue_free()



func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed = true
		else:
			mouse_pressed = false


func _create_palette_node(p_palette: Array) -> Control:
	if p_palette.is_empty():
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
			color_rect.color = Color(p_palette[i][0] / float(255), p_palette[i][1] / float(255), p_palette[i][2] / float(255))
			color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			color_rect.add_to_group("palette_color_remap_color_buttons")
			color_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			color_rect.mouse_entered.connect(
				func () -> void:
					if mouse_pressed:
						selected_color_rects.all(func (color_rect_button: ColorRectButton) -> bool:
							color_rect_button.selected = false
							return true
						)
						color_rect.selected = true
						selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
							color_rect_button.color = color_rect.color
							color_rect_button.palette_index = i
							das["palette_shading"][%PaletteSlider.value][color_rect_button.index] = i
							return true
						)
			)
			color_rect.gui_input.connect(
				func (event: InputEvent) -> void:
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						if color_rect not in selected_color_rects:
							selected_color_rects.all(func (color_rect_button: ColorRectButton) -> bool:
								color_rect_button.selected = false
								return true
							)
							color_rect.selected = true
							selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
								color_rect_button.color = color_rect.color
								color_rect_button.palette_index = i
								das["palette_shading"][%PaletteSlider.value][color_rect_button.index] = i
								return true
							)
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


func _create_palette_remap_node(p_palette_remap: Array) -> Control:
	var p_palette: Array = p_palette_remap.map(func (r:int) -> Array: return das.palette[r]+[r])
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var i: int = 0
	for j in range(16):
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for k in range(16):
			var color_rect := ColorRectButton.new()
			color_rect.color = Color(p_palette[i][0] / float(255), p_palette[i][1] / float(255), p_palette[i][2] / float(255))
			color_rect.palette_index = p_palette[i][3]
			color_rect.index = i
			color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			color_rect.add_to_group("palette_color_remap_buttons")
			color_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			if j == 0 and k == 0:
				color_rect.selected = true
				select_cooresponding_palette_color(color_rect.palette_index)
			color_rect.mouse_entered.connect(
				func () -> void:
					if mouse_pressed:
						selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
							color_rect_button.selected = false
							return true
						)
						color_rect.selected = true
						select_cooresponding_palette_color(color_rect.palette_index)
			)
			color_rect.gui_input.connect(
				func (event: InputEvent) -> void:
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						selected_rects.all(func (color_rect_button: ColorRectButton) -> bool:
							color_rect_button.selected = false
							return true
						)
						color_rect.selected = true
						select_cooresponding_palette_color(color_rect.palette_index)
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


func _on_palette_slider_value_changed(value: float) -> void:
	for child: Control in %ShadedPalette.get_children():
		child.queue_free()
	
	var append_text := ""
	if %PaletteSlider.value < 32:
		append_text = "Distance Shading"
	elif %PaletteSlider.value < 64:
		append_text = "Tinted Shading"
	elif %PaletteSlider.value < 320:
		append_text = "Transparency Blend"
	elif %PaletteSlider.value < 321:
		append_text = "Blue-Tinted Darken"
	elif %PaletteSlider.value < 322:
		append_text = "Color Cooling"
	%PaletteLabel.text = "%d / 322 -- %s" % [(%PaletteSlider.value + 1), append_text]
	if das["palette_shading"].is_empty():
		return
	var palette_remap: Array = das["palette_shading"][%PaletteSlider.value]
	var palette_control: Control = _create_palette_remap_node(palette_remap)
	%ShadedPalette.add_child(palette_control)


func select_cooresponding_palette_color(palette_index: int) -> void:
	var index: int = 0
	for vbox_palette: Control in %DefaultPalette.get_child(0).get_child(0).get_children():
		for palette_rect: ColorRectButton in vbox_palette.get_children():
			if palette_index == index:
				palette_rect.selected = true
			else:
				palette_rect.selected = false
			index += 1

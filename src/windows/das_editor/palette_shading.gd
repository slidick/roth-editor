extends MarginContainer

var das: Dictionary = {}


func load_das(p_das: Dictionary) -> void:
	das = p_das
	var node: Node = _create_palette_node(p_das.palette)
	if node:
		%DefaultPalette.add_child(node)
		%PaletteSlider.set_value_no_signal(0)
		_on_palette_slider_value_changed(0)


func reset() -> void:
	das = {}
	for child: Control in %DefaultPalette.get_children():
		child.queue_free()
	for child: Control in %ShadedPalette.get_children():
		child.queue_free()


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
			var color_rect := ColorRect.new()
			color_rect.color = Color(palette[i][0] / float(255), palette[i][1] / float(255), palette[i][2] / float(255))
			color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	var palette_control: Control = _create_palette_node(palette_remap.map(func (r:int) -> Array: return das.palette[r]))
	%ShadedPalette.add_child(palette_control)

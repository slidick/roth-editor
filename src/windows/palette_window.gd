extends BaseWindow

signal color_selected(index: int)

func _fade_out() -> void:
	super._fade_out()
	color_selected.emit(-1)

func show_palette(palette: Array) -> void:
	for child: Node in %MainContainer.get_children():
		child.queue_free()
	
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
			color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			color_rect.gui_input.connect(
				func (event: InputEvent) -> void:
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						color_selected.emit(i)
						toggle(false)
			)
			vbox.add_child(color_rect)
			i += 1
		hbox.add_child(vbox)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(hbox)
	%MainContainer.add_child(margin)
	
	toggle(true)


class ColorRectButton extends ColorRect:
	var border: ColorRect
	func _ready() -> void:
		border = ColorRect.new()
		border.color = Color.WHITE_SMOKE
		border.anchor_left = 0
		border.anchor_top = 0
		border.anchor_right = 1
		border.anchor_bottom = 1
		border.offset_left = -2
		border.offset_top = -2
		border.offset_right = 2
		border.offset_bottom = 2
		border.show_behind_parent = true
		border.visible = false
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(border)
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	
	func _on_mouse_entered() -> void:
		border.visible = true
		
	func _on_mouse_exited() -> void:
		border.visible = false

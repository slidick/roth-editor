extends BaseWindow

const ZOOM_SPEED : float = 1.10
const MAX_ZOOM : int = 10
const MIN_ZOOM : float = .05
const COLOR_PICKER_CURSOR: Texture2D = preload("uid://cgxhrl6daxi3u")

signal done(image: Variant)

enum Mode {
	DRAW,
	COLOR_PICKER,
}
var current_mode := Mode.DRAW

var color_rects: Array = []
var image: Image
var original_image: Image
var selected_rect: ColorRectButton
var canvas_has_focus: bool = false
var draw_enabled: bool = false
var additional_zoom: float = 1
var zooming: bool = false
var mouse_drag_enabled: bool = false


func _input(event: InputEvent) -> void:
	if canvas_has_focus:
		if event.is_action_pressed("map_2d_zoom_in"):
			additional_zoom *= ZOOM_SPEED
			additional_zoom = clamp(additional_zoom, MIN_ZOOM, MAX_ZOOM)
			zooming = true
			adjust_zoom()
		
		if event.is_action_pressed("map_2d_zoom_out"):
			additional_zoom /= ZOOM_SPEED
			additional_zoom = clamp(additional_zoom, MIN_ZOOM, MAX_ZOOM)
			zooming = true
			adjust_zoom()
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
				mouse_drag_enabled = true
	
	if mouse_drag_enabled:
		if event is InputEventMouseMotion:
			%Camera2D.position.x -= event.relative.x / %Camera2D.zoom.x
			%Camera2D.position.y -= event.relative.y / %Camera2D.zoom.y
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			mouse_drag_enabled = false


func adjust_zoom() -> void:
	while %Camera2D.get_viewport().size.y < 5:
		await get_tree().process_frame
	var zoom_y: float = %Camera2D.get_viewport().size.y / float(image.get_height())
	var zoom_x: float = %Camera2D.get_viewport().size.x / float(image.get_width())
	var zoom: float = min(zoom_x, zoom_y) * 0.90
	var mouse_pos: Vector2 = %TextureRect.get_global_mouse_position()
	%Camera2D.zoom = Vector2.ONE * zoom * additional_zoom
	if zooming:
		await get_tree().process_frame
	if zooming:
		var new_mouse_pos: Vector2 = %TextureRect.get_global_mouse_position()
		%Camera2D.position += mouse_pos - new_mouse_pos
		zooming = false



func update_camera_center() -> void:
	%Camera2D.position = image.get_size() / 2.0



func edit_image(p_image: Image) -> Variant:
	image = p_image.duplicate(true)
	original_image = p_image.duplicate(true)
	var texture := ImageTexture.create_from_image(image)
	%TextureRect.texture = texture
	%PreviewTextureRect.texture = texture
	load_palette(Das.DEFAULT_PALETTE)
	update_camera_center()
	additional_zoom = 1
	adjust_zoom()
	current_mode = Mode.DRAW
	toggle(true)
	var new_image: Variant = await done
	toggle(false)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS)
	return new_image


func _on_cancel_button_pressed() -> void:
	done.emit(null)


func _on_reset_button_pressed() -> void:
	image = original_image.duplicate(true)
	var texture := ImageTexture.create_from_image(image)
	%TextureRect.texture = texture
	%PreviewTextureRect.texture = texture


func _on_save_button_pressed() -> void:
	done.emit(image)


func load_palette(palette: Array) -> void:
	for child: Node in %PaletteContainer.get_children():
		child.queue_free()
	color_rects.clear()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var i: int = 0
	for j in range(16):
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		for k in range(16):
			var color_rect := ColorRectButton.new()
			if i == 0:
				selected_rect = color_rect
				color_rect.selected = true
				color_rect.queue_redraw()
			color_rect.palette_index = i
			if i == 0:
				color_rect.color = Color(palette[i][0] / float(255), palette[i][1] / float(255), palette[i][2] / float(255), 0.0)
			else:
				color_rect.color = Color(palette[i][0] / float(255), palette[i][1] / float(255), palette[i][2] / float(255))
			
			color_rect.custom_minimum_size = Vector2(20,20)
			color_rect.gui_input.connect(
				func (event: InputEvent) -> void:
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						if selected_rect:
							selected_rect.selected = false
							selected_rect.queue_redraw()
						selected_rect = color_rect
						color_rect.selected = true
						color_rect.queue_redraw()
			)
			vbox.add_child(color_rect)
			color_rects.append(color_rect)
			i += 1
		hbox.add_child(vbox)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(hbox)
	%PaletteContainer.add_child(margin)


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		%PositionLabel.text = "X: %d Y: %d" % [event.position.x+1, event.position.y+1]
		if current_mode == Mode.DRAW and draw_enabled:
			if event.position.x >= 0 and event.position.y >= 0 and event.position.x < image.get_width() and event.position.y < image.get_height():
				image.set_pixelv(event.position, selected_rect.color)
				var texture := ImageTexture.create_from_image(image)
				%TextureRect.texture = texture
				%PreviewTextureRect.texture = texture
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		match current_mode:
			Mode.DRAW:
				if event.pressed:
					draw_enabled = true
					image.set_pixelv(event.position, selected_rect.color)
					var texture := ImageTexture.create_from_image(image)
					%TextureRect.texture = texture
					%PreviewTextureRect.texture = texture
				else:
					draw_enabled = false
			Mode.COLOR_PICKER:
				if event.pressed:
					select_color(image.get_pixelv(event.position))


func _on_texture_rect_mouse_exited() -> void:
	%PositionLabel.text = ""


func _on_sub_viewport_container_mouse_entered() -> void:
	canvas_has_focus = true


func _on_sub_viewport_container_mouse_exited() -> void:
	canvas_has_focus = false


func _on_color_picker_button_pressed() -> void:
	if not current_mode == Mode.COLOR_PICKER:
		current_mode = Mode.COLOR_PICKER
		Input.set_custom_mouse_cursor(COLOR_PICKER_CURSOR, Input.CURSOR_ARROW, Vector2(6,26))
		Input.set_custom_mouse_cursor(COLOR_PICKER_CURSOR, Input.CURSOR_CROSS, Vector2(6,26))
	else:
		enter_draw_mode()


func enter_draw_mode() -> void:
	current_mode = Mode.DRAW
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS)


func select_color(color: Color) -> void:
	for color_rect: ColorRect in color_rects:
		if color_rect.color == color:
			if selected_rect:
				selected_rect.selected = false
				selected_rect.queue_redraw()
			selected_rect = color_rect
			color_rect.selected = true
			color_rect.queue_redraw()
	
	enter_draw_mode()

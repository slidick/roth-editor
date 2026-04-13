extends BaseWindow

const ZOOM_SPEED : float = 1.10
const MAX_ZOOM : int = 10
const MIN_ZOOM : float = .05
const COLOR_PICKER_CURSOR: Texture2D = preload("uid://cgxhrl6daxi3u")

signal done(texture: Dictionary)
enum Mode {
	DRAW,
	COLOR_PICKER,
}
var current_mode := Mode.DRAW

var color_rects: Array = []
var image: Image
var selected_rect: ColorRectButton
var canvas_has_focus: bool = false
var draw_enabled: bool = false
var zoom: float = 1.0
var additional_zoom: float = 1.0
var zooming: bool = false
var mouse_drag_enabled: bool = false
var original_texture_data: Dictionary = {}
var texture_data: Dictionary = {}
var palette: Array = []
var force_partial_alpha: bool = false

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


func init_zoom() -> void:
	while %Camera2D.get_viewport().size.y < 5:
		await get_tree().process_frame
	var zoom_y: float = %Camera2D.get_viewport().size.y / float(image.get_height())
	var zoom_x: float = %Camera2D.get_viewport().size.x / float(image.get_width())
	if %RotateCanvasCheckBox.button_pressed:
		zoom_y = %Camera2D.get_viewport().size.y / float(image.get_width())
		zoom_x = %Camera2D.get_viewport().size.x / float(image.get_height())
	zoom = min(zoom_x, zoom_y) * 0.90
	adjust_zoom()


func adjust_zoom() -> void:
	var mouse_pos: Vector2 = %TextureRect.get_global_mouse_position()
	%Camera2D.zoom = Vector2.ONE * zoom * additional_zoom
	if zooming:
		await get_tree().process_frame
	if zooming:
		var new_mouse_pos: Vector2 = %TextureRect.get_global_mouse_position()
		%Camera2D.position += mouse_pos - new_mouse_pos
		zooming = false


func update_camera_center() -> void:
	if %RotateCanvasCheckBox.button_pressed:
		var _size := Vector2.ZERO
		_size.x = image.get_size().y
		_size.y = image.get_size().x
		%Camera2D.position = _size / 2.0
	else:
		%Camera2D.position = image.get_size() / 2.0


func edit_image(p_texture_data: Dictionary, p_raw_palette: Array, p_force_partial_alpha: bool = false) -> Dictionary:
	original_texture_data = p_texture_data.duplicate(true)
	texture_data = p_texture_data.duplicate(true)
	force_partial_alpha = p_force_partial_alpha
	if palette != p_raw_palette:
		palette = p_raw_palette
		load_palette(palette)
	_on_reset_button_pressed()
	update_camera_center()
	additional_zoom = 1
	current_mode = Mode.DRAW
	toggle(true)
	var new_texture: Dictionary = await done
	toggle(false)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS)
	return new_texture


func _on_cancel_button_pressed() -> void:
	done.emit({})


func _on_reset_button_pressed() -> void:
	texture_data = original_texture_data.duplicate(true)
	update_dimensions()
	redraw_image()
	update_camera_center()
	additional_zoom = 1
	init_zoom()


func redraw_image() -> void:
	var is_transparent: bool = texture_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or texture_data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0 or force_partial_alpha
	var is_fully_transparent: bool = texture_data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
	image = Image.create_from_data(
		texture_data.width,
		texture_data.height,
		false,
		Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8,
		Utility.convert_palette_image(palette, texture_data.raw_image, is_transparent, is_fully_transparent)
	)
	var texture := ImageTexture.create_from_image(image)
	%TextureRect.texture = texture
	%PreviewTextureRect.texture = texture
	%BackgroundCanvas.queue_redraw()


func update_dimensions() -> void:
	if %RotateCanvasCheckBox.button_pressed:
		%WidthSpinBox.set_value_no_signal(texture_data.height)
		%WidthSpinBox.get_line_edit().text = str(texture_data.height)
		%HeightSpinBox.set_value_no_signal(texture_data.width)
		%HeightSpinBox.get_line_edit().text = str(texture_data.width)
		%HeightSpinBox.max_value = int(65536 / texture_data.height)
		%WidthSpinBox.max_value = int(65536 / texture_data.width)
	else:
		%WidthSpinBox.set_value_no_signal(texture_data.width)
		%WidthSpinBox.get_line_edit().text = str(texture_data.width)
		%HeightSpinBox.set_value_no_signal(texture_data.height)
		%HeightSpinBox.get_line_edit().text = str(texture_data.height)
		%HeightSpinBox.max_value = int(65536 / texture_data.width)
		%WidthSpinBox.max_value = int(65536 / texture_data.height)


func _on_save_button_pressed() -> void:
	done.emit(texture_data)


func load_palette(p_raw_palette: Array) -> void:
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
				color_rect.color = Color(((p_raw_palette[3*i+0] * 259 + 33) >> 6) / float(255), ((p_raw_palette[3*i+1] * 259 + 33) >> 6) / float(255), ((p_raw_palette[3*i+2] * 259 + 33) >> 6) / float(255), 0.0)
			else:
				color_rect.color = Color(((p_raw_palette[3*i+0] * 259 + 33) >> 6) / float(255), ((p_raw_palette[3*i+1] * 259 + 33) >> 6) / float(255), ((p_raw_palette[3*i+2] * 259 + 33) >> 6) / float(255))
			
			color_rect.custom_minimum_size = Vector2(20,20)
			color_rect.gui_input.connect(
				func (event: InputEvent) -> void:
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						if selected_rect:
							selected_rect.selected = false
						selected_rect = color_rect
						color_rect.selected = true
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
		if event.position.x >= 0 and event.position.y >= 0 and event.position.x < image.get_width() and event.position.y < image.get_height():
			if %RotateCanvasCheckBox.button_pressed:
				%PositionLabel.text = "X: %d Y: %d" % [event.position.y+1, event.position.x+1]
			else:
				%PositionLabel.text = "X: %d Y: %d" % [event.position.x+1, event.position.y+1]
		else:
			%PositionLabel.text = ""
		if current_mode == Mode.DRAW:
			%TextureRect.queue_redraw()
			if draw_enabled:
				var mouse_pos: Vector2 = event.position
				var _draw_size: int = int(%DrawSizeSpinBox.value) - 1
				var vertex_1 := Vector2i(floori(mouse_pos.x)-int(_draw_size/2.0), floori(mouse_pos.y)-int(_draw_size/2.0))
				var vertex_2 := Vector2i(ceili(mouse_pos.x)+roundi(_draw_size/2.0), floori(mouse_pos.y)-int(_draw_size/2.0))
				var vertex_3 := Vector2i(ceili(mouse_pos.x)+roundi(_draw_size/2.0), ceili(mouse_pos.y)+roundi(_draw_size/2.0))
				for x in range(vertex_1.x, vertex_2.x):
					for y in range(vertex_1.y, vertex_3.y):
						if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
							texture_data.raw_image[y * texture_data.width + x] = selected_rect.palette_index
				redraw_image()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		match current_mode:
			Mode.DRAW:
				if event.pressed:
					draw_enabled = true
					var mouse_pos: Vector2 = event.position
					var _draw_size: int = int(%DrawSizeSpinBox.value) - 1
					var vertex_1 := Vector2i(floori(mouse_pos.x)-int(_draw_size/2.0), floori(mouse_pos.y)-int(_draw_size/2.0))
					var vertex_2 := Vector2i(ceili(mouse_pos.x)+roundi(_draw_size/2.0), floori(mouse_pos.y)-int(_draw_size/2.0))
					var vertex_3 := Vector2i(ceili(mouse_pos.x)+roundi(_draw_size/2.0), ceili(mouse_pos.y)+roundi(_draw_size/2.0))
					for x in range(vertex_1.x, vertex_2.x):
						for y in range(vertex_1.y, vertex_3.y):
							if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
								texture_data.raw_image[y * texture_data.width + x] = selected_rect.palette_index
					redraw_image()
				else:
					draw_enabled = false
			Mode.COLOR_PICKER:
				if event.pressed:
					if event.position.x >= 0 and event.position.y >= 0 and event.position.x < image.get_width() and event.position.y < image.get_height():
						var new_palette_index: int = texture_data.raw_image[int(event.position.y) * texture_data.width + int(event.position.x)]
						select_color(new_palette_index)


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


func select_color(palette_index: int) -> void:
	for color_rect: ColorRect in color_rects:
		if color_rect.palette_index == palette_index:
			if selected_rect:
				selected_rect.selected = false
				selected_rect.queue_redraw()
			selected_rect = color_rect
			color_rect.selected = true
			color_rect.queue_redraw()
	
	enter_draw_mode()


func _on_draw_size_spin_box_value_changed(value: float) -> void:
	%TextureRect.draw_size = int(value)


func _on_rotate_canvas_check_box_toggled(toggled_on: bool) -> void:
	%RotationContainer.enabled = toggled_on
	%RotationPreviewContainer.enabled = toggled_on
	update_dimensions()


func _on_width_spin_box_value_changed(value: float) -> void:
	if %RotateCanvasCheckBox.button_pressed:
		update_height(value)
	else:
		update_width(value)
	%HeightSpinBox.max_value = int(65536 / value)


func update_width(value: float) -> void:
	var old_width: int = texture_data.width
	if int(value) == old_width:
		return
	texture_data.width = int(value)
	var new_raw_image := []
	if value > old_width:
		var index: int = 0
		for i in range(texture_data.height):
			for j in range(old_width):
				new_raw_image.append(texture_data.raw_image[index])
				index += 1
			for j in range(value-old_width):
				new_raw_image.append(0)
	if value < old_width:
		var index: int = 0
		for i in range(texture_data.height):
			for j in range(value):
				new_raw_image.append(texture_data.raw_image[index])
				index += 1
			for j in range(old_width-value):
				index += 1
	
	texture_data.raw_image = new_raw_image
	redraw_image()


func _on_height_spin_box_value_changed(value: float) -> void:
	if %RotateCanvasCheckBox.button_pressed:
		update_width(value)
	else:
		update_height(value)
	%WidthSpinBox.max_value = int(65536 / value)


func update_height(value: float) -> void:
	var old_height: int = texture_data.height
	if int(value) == old_height:
		return
	texture_data.height = int(value)
	var new_raw_image := []
	if value > old_height:
		var index: int = 0
		for i in range(old_height):
			for j in range(texture_data.width):
				new_raw_image.append(texture_data.raw_image[index])
				index += 1
		for i in range(value-old_height):
			for j in range(texture_data.width):
				new_raw_image.append(0)
	if value < old_height:
		var index: int = 0
		for i in range(value):
			for j in range(texture_data.width):
				new_raw_image.append(texture_data.raw_image[index])
				index += 1
	
	texture_data.raw_image = new_raw_image
	redraw_image()


func _on_browse_button_pressed() -> void:
	%FileDialog.popup()


func _on_file_dialog_file_selected(path: String) -> void:
	var import_image: Image = Image.load_from_file(path)
	
	if %FileDialog.get_selected_options()["Rotate on Import"]:
		import_image.flip_x()
		import_image.rotate_90(COUNTERCLOCKWISE)
		%RotateCanvasCheckBox.button_pressed = true
	else:
		%RotateCanvasCheckBox.button_pressed = false
	
	
	#if import_image.get_size().x > 256:
		#import_image.resize(256, roundi((256.0/import_image.get_size().x) * import_image.get_size().y), Image.INTERPOLATE_NEAREST)
	#if import_image.get_size().y > 256:
		#import_image.resize(roundi((256.0/import_image.get_size().y) * import_image.get_size().x), 256, Image.INTERPOLATE_NEAREST)
	
	var import_raw_image: PackedByteArray = await RLE.convert_to_paletted_image(import_image, palette)
	
	var new_texture_data: Dictionary = {}
	if "modifier" in texture_data:
		new_texture_data["modifier"] = texture_data.modifier
	
	new_texture_data["image_type"] = texture_data.image_type
	new_texture_data["width"] = import_image.get_size().x
	new_texture_data["height"] = import_image.get_size().y
	new_texture_data["raw_image"] = import_raw_image
	texture_data = new_texture_data
	%WidthSpinBox.set_value_no_signal(texture_data.width)
	%WidthSpinBox.get_line_edit().text = str(texture_data.width)
	%HeightSpinBox.set_value_no_signal(texture_data.height)
	%HeightSpinBox.get_line_edit().text = str(texture_data.height)
	redraw_image()
	update_camera_center()
	additional_zoom = 1
	init_zoom()

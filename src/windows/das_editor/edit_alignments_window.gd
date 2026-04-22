extends BaseWindow

signal done(data: Dictionary)

const SELECTABLE_TEXTURE_RECT_SCRIPT := preload("uid://4erj4n54vwf3")
const EYE_ICON: Texture2D = preload("uid://crb7de5pvofid")
const EYE_CLOSED_ICON: Texture2D = preload("uid://d8l1uefa8sbq")
const ZOOM_SPEED : float = 1.10
const MAX_ZOOM : int = 10
const MIN_ZOOM : float = 1

var animation_data: Dictionary = {}
var raw_palette: PackedByteArray = []
var zoom: float = 1.0
var additional_zoom: float = 1.0
var zooming: bool = false
var mouse_drag_enabled: bool = false


func edit_alignments(p_animation_data: Dictionary, p_raw_palette: PackedByteArray) -> Dictionary:
	animation_data = p_animation_data.duplicate(true)
	raw_palette = p_raw_palette
	
	for child: Node in %RotationContainer.get_children():
		child.queue_free()
	
	var background_image := Image.create_empty(animation_data.data.width, animation_data.data.height, false, Image.FORMAT_RGB8)
	background_image.fill(Color.WHITE)
	var background := TextureRect.new()
	background.texture = ImageTexture.create_from_image(background_image)
	background.stretch_mode = TextureRect.STRETCH_KEEP
	%RotationContainer.add_child(background)
	%WidthSpinBox.set_value_no_signal(animation_data.data.height)
	%HeightSpinBox.set_value_no_signal(animation_data.data.width)
	
	%XOffsetSpinBox.editable = false
	%YOffsetSpinBox.editable = false
	%XOffsetSpinBox.set_value_no_signal(0)
	%YOffsetSpinBox.set_value_no_signal(0)
	
	var is_transparent: bool = animation_data.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0 or animation_data.data.image_type & Das.IMAGE_TYPE.PALETTE_ZERO_OPAQUE == 0
	var is_fully_transparent: bool = animation_data.data.image_type & Das.IMAGE_TYPE.TRANSPARENT > 0
	
	%Tree.clear()
	var root_item: TreeItem = %Tree.create_item()
	for i in range(len(animation_data.data.animation_2)):
		var frame: Dictionary = animation_data.data.animation_2[i]
		var tree_item: TreeItem = root_item.create_child()
		tree_item.set_text(0, str(i))
		tree_item.set_metadata(0, frame)
		tree_item.add_button(0, EYE_ICON)
		
		var image := Image.create_from_data(
			frame.width,
			frame.height,
			false,
			Image.FORMAT_RGBA8 if is_transparent else Image.FORMAT_RGB8,
			Utility.convert_palette_image(raw_palette, frame.raw_image, is_transparent, is_fully_transparent)
		)
		var texture_rect := TextureRect.new()
		texture_rect.set_script(SELECTABLE_TEXTURE_RECT_SCRIPT)
		texture_rect.texture = ImageTexture.create_from_image(image)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.position = Vector2(frame.y_offset, frame.x_offset)
		texture_rect.focus_mode = Control.FOCUS_ALL
		texture_rect.focus_neighbor_bottom = "."
		texture_rect.focus_neighbor_left = "."
		texture_rect.focus_neighbor_right = "."
		texture_rect.focus_neighbor_top = "."
		texture_rect.connect.call_deferred("clicked", _on_texture_rect_clicked.bind(i))
		texture_rect.connect.call_deferred("move_right", _on_texture_rect_move_right.bind(i))
		texture_rect.connect.call_deferred("move_left", _on_texture_rect_move_left.bind(i))
		texture_rect.connect.call_deferred("move_up", _on_texture_rect_move_up.bind(i))
		texture_rect.connect.call_deferred("move_down", _on_texture_rect_move_down.bind(i))
		%RotationContainer.add_child(texture_rect)
	
	update_camera_center()
	additional_zoom = 1
	init_zoom()
	
	toggle(true)
	var data: Dictionary = await done
	animation_data = {}
	raw_palette = []
	toggle(false)
	return data


func update_camera_center() -> void:
	var _size := Vector2.ZERO
	_size.x = animation_data.data.height
	_size.y = animation_data.data.width
	%Camera2D.position = _size / 2.0


func init_zoom() -> void:
	while %Camera2D.get_viewport().size.y < 5:
		await get_tree().process_frame
	var zoom_y: float = %Camera2D.get_viewport().size.y / float(animation_data.data.width)
	var zoom_x: float = %Camera2D.get_viewport().size.x / float(animation_data.data.height)
	zoom = min(zoom_x, zoom_y) * 0.98
	adjust_zoom()


func adjust_zoom() -> void:
	var mouse_pos: Vector2 = %RotationContainer.get_global_mouse_position()
	%Camera2D.zoom = Vector2.ONE * zoom * additional_zoom
	if zooming:
		await get_tree().process_frame
	if zooming:
		var new_mouse_pos: Vector2 = %RotationContainer.get_global_mouse_position()
		%Camera2D.position += mouse_pos - new_mouse_pos
		zooming = false


func _on_cancel_button_pressed() -> void:
	toggle(false)
	done.emit({})


func _on_save_button_pressed() -> void:
	done.emit(animation_data.duplicate(true))


func _on_tree_button_clicked(clicked_item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	var current_icon := EYE_ICON
	if clicked_item.get_button(0, id) != EYE_ICON:
		current_icon = EYE_CLOSED_ICON
	
	var item: TreeItem = %Tree.get_next_selected(null)
	var selected_items: Array = []
	while item:
		selected_items.append(item)
		item = %Tree.get_next_selected(item)
	
	if clicked_item not in selected_items:
		selected_items = [clicked_item]
	
	for each_item: TreeItem in selected_items:
		if current_icon == EYE_ICON:
			each_item.set_button(0, id, EYE_CLOSED_ICON)
			%RotationContainer.get_child(each_item.get_index()+1).hide()
		else:
			each_item.set_button(0, id, EYE_ICON)
			%RotationContainer.get_child(each_item.get_index()+1).show()
		each_item = %Tree.get_next_selected(each_item)


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
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


func _on_x_offset_spin_box_value_changed(_value: float) -> void:
	update_offset()


func _on_y_offset_spin_box_value_changed(_value: float) -> void:
	update_offset()


func update_offset() -> void:
	var selected_items: Array = []
	var item: TreeItem = %Tree.get_next_selected(null)
	while item:
		selected_items.append(item)
		item = %Tree.get_next_selected(item)
	if len(selected_items) == 1:
		var frame: Dictionary = selected_items[0].get_metadata(0)
		frame.y_offset = int(%XOffsetSpinBox.value)
		frame.x_offset = int(%YOffsetSpinBox.value)
		%RotationContainer.get_child(selected_items[0].get_index()+1).position = Vector2(frame.y_offset, frame.x_offset)


func update_canvas_size() -> void:
	animation_data.data.width = int(%HeightSpinBox.value)
	animation_data.data.height = int(%WidthSpinBox.value)
	var background_image := Image.create_empty(animation_data.data.width, animation_data.data.height, false, Image.FORMAT_RGB8)
	background_image.fill(Color.WHITE)
	%RotationContainer.get_child(0).texture.set_image(background_image)
	update_camera_center()
	additional_zoom = 1
	init_zoom()


func _on_width_spin_box_value_changed(_value: float) -> void:
	update_canvas_size()


func _on_height_spin_box_value_changed(_value: float) -> void:
	update_canvas_size()


func _on_texture_rect_clicked(shift_pressed: bool, index: int) -> void:
	if not shift_pressed:
		%Tree.deselect_all()
	%Tree.get_root().get_child(index).select(0)
	%Tree.scroll_to_item(%Tree.get_selected())
	_on_tree_cell_selected()


func _on_texture_rect_move_right(_index: int) -> void:
	%XOffsetSpinBox.value = %XOffsetSpinBox.value + 1


func _on_texture_rect_move_left(_index: int) -> void:
	%XOffsetSpinBox.value = %XOffsetSpinBox.value - 1


func _on_texture_rect_move_up(_index: int) -> void:
	%YOffsetSpinBox.value = %YOffsetSpinBox.value - 1


func _on_texture_rect_move_down(_index: int) -> void:
	%YOffsetSpinBox.value = %YOffsetSpinBox.value + 1


func _on_tree_cell_selected() -> void:
	await get_tree().process_frame
	var selected_items: Array = []
	var item: TreeItem = %Tree.get_next_selected(null)
	while item:
		selected_items.append(item)
		item = %Tree.get_next_selected(item)
	if len(selected_items) == 1 and %Tree.get_selected() in selected_items:
		var frame: Dictionary = selected_items[0].get_metadata(0)
		%XOffsetSpinBox.set_value_no_signal(frame.y_offset)
		%YOffsetSpinBox.set_value_no_signal(frame.x_offset)
		%XOffsetSpinBox.editable = true
		%YOffsetSpinBox.editable = true
		if %RotationContainer.get_child(selected_items[0].get_index()+1).visible:
			%RotationContainer.get_child(selected_items[0].get_index()+1).grab_focus()
	else:
		%XOffsetSpinBox.editable = false
		%YOffsetSpinBox.editable = false
		%Tree.grab_focus()
	
	item = %Tree.get_root().get_first_child()
	while item:
		if item in selected_items:
			%RotationContainer.get_child(item.get_index()+1).selected = true
		else:
			%RotationContainer.get_child(item.get_index()+1).selected = false
		item = item.get_next()

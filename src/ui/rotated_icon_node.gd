extends MarginContainer
class_name RotatedIconNode

signal selected(index: int)
signal activated(index: int)
signal context_option_selected(index: int, context_index: int)

var index: int
var text: String
var texture: Texture2D
var rotated: bool = false
var rotation_container: RotationContainer
var popup_menu: PopupMenu
var metadata: Variant
var texture_rect: TextureRect
var hover_background: ColorRect
var select_background: ColorRect
var icon_size: Vector2 :
	set(new_value):
		icon_size = new_value
		if texture_rect:
			texture_rect.custom_minimum_size = icon_size
var context_options: Array[String]

func _init(p_index: int, p_text: String, p_texture: Texture2D, p_rotated: bool, p_icon_size: Vector2, p_context_options: Array[String]) -> void:
	index = p_index
	text = p_text
	texture = p_texture
	rotated = p_rotated
	icon_size = p_icon_size
	context_options = p_context_options


func set_rotated(_bool: bool) -> void:
	if rotation_container:
		rotation_container.enabled = _bool


func set_metadata(p_metadata: Variant) -> void:
	metadata = p_metadata


func get_metadata() -> Variant:
	return metadata


func _ready() -> void:
	texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.custom_minimum_size = icon_size
	
	rotation_container = RotationContainer.new()
	rotation_container.enabled = rotated
	rotation_container.add_child(texture_rect)
	
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var vbox_layout := VBoxContainer.new()
	vbox_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_layout.add_child(rotation_container)
	vbox_layout.add_child(label)
	
	add_child(vbox_layout)
	
	hover_background = ColorRect.new()
	hover_background.hide()
	hover_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_background.color = Color(0, 0, 0, 0.2)
	hover_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	hover_background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hover_background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(hover_background)
	
	mouse_entered.connect(func () -> void:
		if not select_background.visible:
			hover_background.show()
	)
	mouse_exited.connect(func () -> void:
		hover_background.hide()
	)
	
	select_background = ColorRect.new()
	select_background.hide()
	select_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_background.color = Color(0, 0, 0, 0.4)
	select_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	select_background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	select_background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(select_background)
	
	if not context_options.is_empty():
		popup_menu = PopupMenu.new()
		for option: String in context_options:
			popup_menu.add_item(option)
		popup_menu.index_pressed.connect(_on_popup_menu_index_pressed)
		popup_menu.mouse_passthrough = true
		add_child(popup_menu)

func deselect() -> void:
	select_background.hide()


func select() -> void:
	hover_background.hide()
	select_background.show()
	selected.emit(index)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				select()
				if event.double_click:
					activated.emit(index)
			MOUSE_BUTTON_RIGHT:
				select()
				if popup_menu:
					popup_menu.popup(Rect2i(int(event.global_position.x), int(event.global_position.y), 0, 0))


func _on_popup_menu_index_pressed(p_index: int) -> void:
	context_option_selected.emit(index, p_index)

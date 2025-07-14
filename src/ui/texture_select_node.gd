extends MarginContainer
class_name TextureSelectNode

signal selected(index: int)
signal add_to_favorites_selected(texture_data: Dictionary)

var texture_data: Dictionary = {}
var rotated: bool = false
var rotation_container: RotationContainer
var popup_menu: PopupMenu

func _init(p_texture_data: Dictionary, p_rotated: bool = false) -> void:
	texture_data = p_texture_data
	rotated = p_rotated

func set_rotated(_bool: bool) -> void:
	if rotation_container:
		rotation_container.enabled = _bool
	

func _ready() -> void:
	var texture_rect := TextureRect.new()
	texture_rect.texture = texture_data.image[0] if typeof(texture_data.image) == TYPE_ARRAY else texture_data.image
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.custom_minimum_size = Vector2(150,150)
	
	rotation_container = RotationContainer.new()
	rotation_container.enabled = rotated
	rotation_container.add_child(texture_rect)
	
	var label := Label.new()
	label.text = "%s: %s" % [texture_data.index, texture_data.name]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var vbox_layout := VBoxContainer.new()
	vbox_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_layout.add_child(rotation_container)
	vbox_layout.add_child(label)
	
	add_child(vbox_layout)
	
	var background := ColorRect.new()
	background.hide()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.color = Color(0, 0, 0, 0.4)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(background)
	
	mouse_entered.connect(func () -> void:
		background.show()
	)
	mouse_exited.connect(func () -> void:
		background.hide()
	)
	
	popup_menu = PopupMenu.new()
	popup_menu.add_item("Add to Favorites")
	popup_menu.index_pressed.connect(_on_popup_menu_index_pressed)
	add_child(popup_menu)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.double_click:
					selected.emit(texture_data.index)
			MOUSE_BUTTON_RIGHT:
				popup_menu.popup(Rect2i(int(event.global_position.x), int(event.global_position.y), 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			add_to_favorites_selected.emit(texture_data)

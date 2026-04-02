extends MarginContainer
signal jump_to_collision_pressed(index: int)
signal jump_to_filename_pressed(filename: Dictionary)

var das: Dictionary = {}
var key: String = ""


func _ready() -> void:
	%FATContainer.jump_to_collision_pressed.connect(func () -> void:
		jump_to_collision_pressed.emit(%ItemList.get_selected_items()[0])
	)
	%FATContainer.jump_to_filename_pressed.connect(func (filename: Dictionary) -> void:
		jump_to_filename_pressed.emit(filename)
	)

func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%FATContainer.reset()


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		var idx: int = %ItemList.add_item(str(p_starting_index + i))
		%ItemList.set_item_metadata(idx, das[key][i])


func _on_item_list_item_selected(index: int) -> void:
	%FATContainer.reset()
	%FATContainer.load_das(das[key], index, das.raw_palette, true if key == "fat_3" else false)


func select_index(index: int) -> bool:
	for i in range(%ItemList.item_count):
		if %ItemList.get_item_text(i) == str(index):
			%ItemList.select(i)
			%ItemList.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			return true
	return false


func _on_popup_menu_index_pressed(index: int) -> void:
	var item_index: int = %ItemList.get_selected_items()[0]
	match index:
		0:
			var data: Dictionary = das[key][item_index]
			owner.copy_data(data)
		1:
			das[key][item_index] = owner.copied_data.duplicate(true)
			_on_item_list_item_selected(item_index)
		2:
			if await Dialog.confirm("Clear selected data?", "Confirm", false, Vector2(400,200)):
				das[key][item_index] = {
					"offset": 0,
					"size": 0,
					"flags_1": 0,
					"flags_2": 0,
				}
				_on_item_list_item_selected(item_index)


func _on_item_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		if owner.copied_data.is_empty():
			%PopupMenu.set_item_disabled(1, true)
		else:
			%PopupMenu.set_item_disabled(1, false)
		%PopupMenu.popup(Rect2(%ItemList.global_position.x + at_position.x, %ItemList.global_position.y + at_position.y, 0, 0))


func select(index: int) -> void:
	if %ItemList.item_count > index:
		%ItemList.select(index)
		_on_item_list_item_selected(index)

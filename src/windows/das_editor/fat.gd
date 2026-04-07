extends MarginContainer

signal jump_to_collision_pressed(index: int)
signal jump_to_filename_pressed(filename: Dictionary)

var das: Dictionary = {}
var key: String = ""


func _ready() -> void:
	%GenericContainer.jump_to_collision_pressed.connect(func () -> void:
		jump_to_collision_pressed.emit(%ItemList.get_selected_items()[0])
	)
	%GenericContainer.jump_to_filename_pressed.connect(func (filename: Dictionary) -> void:
		jump_to_filename_pressed.emit(filename)
	)
	%StandardImageContainer.jump_to_collision_pressed.connect(func () -> void:
		jump_to_collision_pressed.emit(%ItemList.get_selected_items()[0])
	)
	%StandardImageContainer.jump_to_filename_pressed.connect(func (filename: Dictionary) -> void:
		jump_to_filename_pressed.emit(filename)
	)

func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%GenericContainer.reset()


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		%ItemList.add_item(str(p_starting_index + i))


func _on_item_list_item_selected(index: int) -> void:
	%GenericContainer.hide()
	%StandardImageContainer.hide()
	if "data" in das[key][index] and "raw_image" in das[key][index].data:
		%StandardImageContainer.show()
		%StandardImageContainer.load_image_data(das[key][index], das.raw_palette, true if key == "fat_3" else false)
	else:
		%GenericContainer.show()
		%GenericContainer.reset()
		%GenericContainer.load_das(das[key], index, das.raw_palette, true if key == "fat_3" else false)


func select_index(index: int) -> bool:
	for i in range(%ItemList.item_count):
		if %ItemList.get_item_text(i) == str(index):
			%ItemList.select(i)
			%ItemList.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			return true
	return false


func select(index: int) -> void:
	if index < %ItemList.item_count:
		%ItemList.select(index)
		%ItemList.ensure_current_is_visible()
		_on_item_list_item_selected(index)


func _on_popup_menu_index_pressed(index: int) -> void:
	var item_index: int = %ItemList.get_selected_items()[0]
	match index:
		0:
			var data: Dictionary = das[key][item_index]
			owner.copy_data(data)
		1:
			if das[key][item_index].offset != 0:
				if not await Dialog.confirm("Paste over selected data?", "Confirm", false, Vector2(400,200)):
					return
			das[key][item_index] = owner.copied_data.duplicate(true)
			_on_item_list_item_selected(item_index)
		2:
			if await Dialog.confirm("Clear selected data?", "Confirm", false, Vector2(400,200)):
				das[key][item_index].offset = 0
				das[key][item_index].size = 0
				das[key][item_index].flags_1 = 0
				das[key][item_index].flags_2 = 0
				das[key][item_index].erase("data")
				das[key][item_index].erase("filename")
				_on_item_list_item_selected(item_index)
		3:
			var data := {
				"modifier": 0,
				"image_type": 0,
				"width": 1,
				"height": 1,
				"raw_image": PackedByteArray([0]),
			}
			das[key][item_index]["offset"] = 1
			das[key][item_index]["data"] = data
			_on_item_list_item_selected(item_index)


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		if owner.copied_data.is_empty():
			%PopupMenu.set_item_disabled(1, true)
		else:
			%PopupMenu.set_item_disabled(1, false)
		if das[key][index].offset == 0:
			%PopupMenu.set_item_disabled(3, false)
		else:
			%PopupMenu.set_item_disabled(3, true)
		%PopupMenu.popup(Rect2(%ItemList.global_position.x + at_position.x, %ItemList.global_position.y + at_position.y, 0, 0))


func _on_find_empty_button_pressed() -> void:
	for i in range(%ItemList.item_count):
		var fat_data: Dictionary = das[key][i]
		if fat_data.offset == 0:
			%ItemList.select(i)
			%ItemList.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			break

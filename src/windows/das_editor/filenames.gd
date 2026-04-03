extends MarginContainer

signal jump_to_index_pressed(index: int)

var das: Dictionary = {}
var key: String = ""


func reset() -> void:
	das = {}
	%ItemList.clear()
	%FilenamesContainer.hide()
	%IndexEdit.text = ""
	%NameEdit.text = ""
	%DescEdit.text = ""


func load_das(p_das: Dictionary, p_key: String) -> void:
	das = p_das
	key = p_key
	for filename_info: Dictionary in p_das[key]:
		var idx: int = %ItemList.add_item(filename_info.name)
		%ItemList.set_item_metadata(idx, filename_info)


func select(filename: Dictionary) -> bool:
	for i in range(%ItemList.item_count):
		var item_filename: Dictionary = %ItemList.get_item_metadata(i)
		if filename == item_filename:
			%ItemList.select(i)
			_on_item_list_item_selected(i)
			%ItemList.ensure_current_is_visible()
			return true
	return false


func _on_add_button_pressed(fat_index: int = 0) -> Dictionary:
	var filename_info := {
		"name": "NAME",
		"desc": "Description",
		"index": fat_index,
		"size": 21,
	}
	das[key].append(filename_info)
	var idx: int = %ItemList.add_item(filename_info.name)
	%ItemList.set_item_metadata(idx, filename_info)
	%ItemList.select(idx)
	%ItemList.ensure_current_is_visible()
	_on_item_list_item_selected(idx)
	return filename_info


func _on_item_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%PopupMenu.popup(Rect2(%ItemList.global_position.x + at_position.x, %ItemList.global_position.y + at_position.y, 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var filename_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
			das[key].erase(filename_info)
			%ItemList.remove_item(%ItemList.get_selected_items()[0])
			%FilenamesContainer.hide()


func _on_item_list_item_selected(index: int) -> void:
	%FilenamesContainer.show()
	var filename_info: Dictionary = %ItemList.get_item_metadata(index)
	%IndexEdit.text = str(filename_info.index)
	%NameEdit.text = str(filename_info.name)
	%DescEdit.text = str(filename_info.desc)


func _on_jump_to_index_button_pressed() -> void:
	var filename_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	jump_to_index_pressed.emit(filename_info.index)


func _on_index_edit_text_changed(new_text: String) -> void:
	var filename_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	filename_info.index = int(new_text)


func _on_name_edit_text_changed(new_text: String) -> void:
	var filename_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	filename_info.name = new_text


func _on_desc_edit_text_changed(new_text: String) -> void:
	var filename_info: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	filename_info.desc = new_text

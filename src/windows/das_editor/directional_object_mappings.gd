extends MarginContainer

signal jump_to_index_pressed(index: int)

var das: Dictionary = {}
var key: String = ""


func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%Container.hide()
	%HeaderEdit.text = ""
	%Dir1Edit.text = ""
	%Dir2Edit.text = ""
	%Dir3Edit.text = ""
	%Dir4Edit.text = ""
	%Dir5Edit.text = ""
	%Dir6Edit.text = ""
	%Dir7Edit.text = ""
	%Dir8Edit.text = ""


func load_das(p_das: Dictionary, p_key: String) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		var idx: int = %ItemList.add_item(str(i))
		%ItemList.set_item_metadata(idx, das[key][i])


func _on_add_button_pressed() -> void:
	var directional_mapping: Dictionary = {
		"header": 32784,
		"dir_1_fat_idx": 0,
		"dir_2_fat_idx": 0,
		"dir_3_fat_idx": 0,
		"dir_4_fat_idx": 0,
		"dir_5_fat_idx": 0,
		"dir_6_fat_idx": 0,
		"dir_7_fat_idx": 0,
		"dir_8_fat_idx": 0,
	}
	das[key].append(directional_mapping)
	var idx: int = %ItemList.add_item(str(%ItemList.item_count))
	%ItemList.set_item_metadata(idx, directional_mapping)
	%ItemList.select(idx)
	%ItemList.ensure_current_is_visible()
	_on_item_list_item_selected(idx)


func _on_item_list_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%PopupMenu.popup(Rect2(%ItemList.global_position.x + at_position.x, %ItemList.global_position.y + at_position.y, 0, 0))


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			var selected: int = %ItemList.get_selected_items()[0]
			das[key].pop_at(selected)
			%ItemList.remove_item(selected)
			%ItemList.clear()
			%Container.hide()
			for i in range(len(das[key])):
				var idx: int = %ItemList.add_item(str(i))
				%ItemList.set_item_metadata(idx, das[key][i])


func _on_item_list_item_selected(index: int) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(index)
	%Container.show()
	%HeaderEdit.text = str(directional_mapping.header)
	if das.das_info.is_ademo:
		%Dir1Edit.text = str((directional_mapping.dir_1_fat_idx & 0x7FFF) - 4608)
		%Dir2Edit.text = str((directional_mapping.dir_2_fat_idx & 0x7FFF) - 4608)
		%Dir3Edit.text = str((directional_mapping.dir_3_fat_idx & 0x7FFF) - 4608)
		%Dir4Edit.text = str((directional_mapping.dir_4_fat_idx & 0x7FFF) - 4608)
		%Dir5Edit.text = str((directional_mapping.dir_5_fat_idx & 0x7FFF) - 4608)
		%Dir6Edit.text = str((directional_mapping.dir_6_fat_idx & 0x7FFF) - 4608)
		%Dir7Edit.text = str((directional_mapping.dir_7_fat_idx & 0x7FFF) - 4608)
		%Dir8Edit.text = str((directional_mapping.dir_8_fat_idx & 0x7FFF) - 4608)
		%Dir1MirrorCheckBox.button_pressed = directional_mapping.dir_1_fat_idx & 0x8000
		%Dir2MirrorCheckBox.button_pressed = directional_mapping.dir_2_fat_idx & 0x8000
		%Dir3MirrorCheckBox.button_pressed = directional_mapping.dir_3_fat_idx & 0x8000
		%Dir4MirrorCheckBox.button_pressed = directional_mapping.dir_4_fat_idx & 0x8000
		%Dir5MirrorCheckBox.button_pressed = directional_mapping.dir_5_fat_idx & 0x8000
		%Dir6MirrorCheckBox.button_pressed = directional_mapping.dir_6_fat_idx & 0x8000
		%Dir7MirrorCheckBox.button_pressed = directional_mapping.dir_7_fat_idx & 0x8000
		%Dir8MirrorCheckBox.button_pressed = directional_mapping.dir_8_fat_idx & 0x8000
	else:
		%Dir1Edit.text = str(directional_mapping.dir_1_fat_idx & 0x7FFF)
		%Dir2Edit.text = str(directional_mapping.dir_2_fat_idx & 0x7FFF)
		%Dir3Edit.text = str(directional_mapping.dir_3_fat_idx & 0x7FFF)
		%Dir4Edit.text = str(directional_mapping.dir_4_fat_idx & 0x7FFF)
		%Dir5Edit.text = str(directional_mapping.dir_5_fat_idx & 0x7FFF)
		%Dir6Edit.text = str(directional_mapping.dir_6_fat_idx & 0x7FFF)
		%Dir7Edit.text = str(directional_mapping.dir_7_fat_idx & 0x7FFF)
		%Dir8Edit.text = str(directional_mapping.dir_8_fat_idx & 0x7FFF)
		%Dir1MirrorCheckBox.button_pressed = directional_mapping.dir_1_fat_idx & 0x8000
		%Dir2MirrorCheckBox.button_pressed = directional_mapping.dir_2_fat_idx & 0x8000
		%Dir3MirrorCheckBox.button_pressed = directional_mapping.dir_3_fat_idx & 0x8000
		%Dir4MirrorCheckBox.button_pressed = directional_mapping.dir_4_fat_idx & 0x8000
		%Dir5MirrorCheckBox.button_pressed = directional_mapping.dir_5_fat_idx & 0x8000
		%Dir6MirrorCheckBox.button_pressed = directional_mapping.dir_6_fat_idx & 0x8000
		%Dir7MirrorCheckBox.button_pressed = directional_mapping.dir_7_fat_idx & 0x8000
		%Dir8MirrorCheckBox.button_pressed = directional_mapping.dir_8_fat_idx & 0x8000


func _on_header_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	directional_mapping.header = int(new_text)


func _on_dir_1_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_1_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_1_fat_idx = int(new_text) | (0x8000 if %Dir1MirrorCheckBox.button_pressed else 0)


func _on_dir_2_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_2_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_2_fat_idx = int(new_text) | (0x8000 if %Dir2MirrorCheckBox.button_pressed else 0)


func _on_dir_3_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_3_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_3_fat_idx = int(new_text) | (0x8000 if %Dir3MirrorCheckBox.button_pressed else 0)


func _on_dir_4_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_4_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_4_fat_idx = int(new_text) | (0x8000 if %Dir4MirrorCheckBox.button_pressed else 0)


func _on_dir_5_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_5_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_5_fat_idx = int(new_text) | (0x8000 if %Dir5MirrorCheckBox.button_pressed else 0)


func _on_dir_6_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_6_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_6_fat_idx = int(new_text) | (0x8000 if %Dir6MirrorCheckBox.button_pressed else 0)


func _on_dir_7_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_7_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_7_fat_idx = int(new_text) | (0x8000 if %Dir7MirrorCheckBox.button_pressed else 0)


func _on_dir_8_edit_text_changed(new_text: String) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		directional_mapping.dir_8_fat_idx = int(new_text) + 4608
	else:
		directional_mapping.dir_8_fat_idx = int(new_text) | (0x8000 if %Dir8MirrorCheckBox.button_pressed else 0)


func _on_dir_1_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_1_fat_idx |= 0x8000
	else:
		directional_mapping.dir_1_fat_idx &= ~0x8000


func _on_dir_2_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_2_fat_idx |= 0x8000
	else:
		directional_mapping.dir_2_fat_idx &= ~0x8000


func _on_dir_3_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_3_fat_idx |= 0x8000
	else:
		directional_mapping.dir_3_fat_idx &= ~0x8000


func _on_dir_4_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_4_fat_idx |= 0x8000
	else:
		directional_mapping.dir_4_fat_idx &= ~0x8000


func _on_dir_5_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_5_fat_idx |= 0x8000
	else:
		directional_mapping.dir_5_fat_idx &= ~0x8000


func _on_dir_6_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_6_fat_idx |= 0x8000
	else:
		directional_mapping.dir_6_fat_idx &= ~0x8000


func _on_dir_7_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_7_fat_idx |= 0x8000
	else:
		directional_mapping.dir_7_fat_idx &= ~0x8000


func _on_dir_8_mirror_check_box_toggled(toggled_on: bool) -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if toggled_on:
		directional_mapping.dir_8_fat_idx |= 0x8000
	else:
		directional_mapping.dir_8_fat_idx &= ~0x8000


func _on_jump_to_1_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_1_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_1_fat_idx & 0x7FFF)


func _on_jump_to_2_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_2_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_2_fat_idx & 0x7FFF)


func _on_jump_to_3_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_3_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_3_fat_idx & 0x7FFF)


func _on_jump_to_4_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_4_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_4_fat_idx & 0x7FFF)


func _on_jump_to_5_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_5_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_5_fat_idx & 0x7FFF)


func _on_jump_to_6_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_6_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_6_fat_idx & 0x7FFF)


func _on_jump_to_7_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_7_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_7_fat_idx & 0x7FFF)


func _on_jump_to_8_button_pressed() -> void:
	var directional_mapping: Dictionary = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
	if das.das_info.is_ademo:
		jump_to_index_pressed.emit((directional_mapping.dir_8_fat_idx & 0x7FFF) - 4608)
	else:
		jump_to_index_pressed.emit(directional_mapping.dir_8_fat_idx & 0x7FFF)

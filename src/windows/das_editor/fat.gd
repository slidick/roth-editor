extends MarginContainer

signal jump_to_collision_pressed(index: int)
signal jump_to_filename_pressed(filename: Dictionary)

var das: Dictionary = {}
var key: String = ""


func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%GenericContainer.reset()
	%EmptyContainer.show()


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int) -> void:
	das = p_das
	key = p_key
	
	for i in range(len(das[key])):
		var fat_name: String = str(p_starting_index + i)
		if "data" in das[key][i]:
			if "raw_image" in das[key][i].data:
				fat_name += "  -  Image"
			if "faces" in das[key][i].data:
				fat_name += "  -  3D"
			if "animation" in das[key][i].data or "animation_2" in das[key][i].data:
				fat_name += "  -  Animation"
			if "image_pack" in das[key][i].data:
				fat_name += "  -  Pack"
		if das[key][i].flags_1 & 32 > 0 and das[key][i].flags_1 & 4 > 0 :
			fat_name += "  -  Monster"
		elif das[key][i].flags_1 & 32 > 0:
			fat_name += "  -  Directional"
		var idx: int = %ItemList.add_item(fat_name)
		%ItemList.set_item_metadata(idx, das[key][i])


func _on_item_list_item_selected(index: int) -> void:
	if "data" in das[key][index] and "raw_image" in das[key][index].data:
		%StandardImageContainer.show()
		%StandardImageContainer.load_image_data(das[key][index], das.raw_palette, true if key == "fat_3" else false)
	elif "data" in das[key][index] and "animation" in das[key][index].data:
		%AnimationContainer.show()
		%AnimationContainer.load_animation_data(das[key][index], das.raw_palette, true if key == "fat_3" else false)
	elif "data" in das[key][index] and "image_pack" in das[key][index].data:
		%ImagePackContainer.show()
		%ImagePackContainer.load_pack_data(das[key][index], das.raw_palette, true if key == "fat_3" else false)
	elif das[key][index].size == 0:
		%EmptyContainer.show()
	else:
		%GenericContainer.show()
		%GenericContainer.reset()
		%GenericContainer.load_das(das[key], index, das.raw_palette, true if key == "fat_3" else false)


func select_index(index: int) -> bool:
	for i in range(%ItemList.item_count):
		if %ItemList.get_item_metadata(i).index == index:
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
			var fat_index: int = das[key][item_index].index
			das[key][item_index] = owner.copied_data.duplicate(true)
			das[key][item_index].index = fat_index
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
			var raw_image := PackedByteArray()
			raw_image.resize(16*16)
			var data := {
				"modifier": 0,
				"image_type": 0,
				"width": 16,
				"height": 16,
				"raw_image": raw_image,
			}
			das[key][item_index]["offset"] = 1
			das[key][item_index]["data"] = data
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 0
			%ItemList.set_item_text(item_index, "%d - Image" % item_index)
			_on_item_list_item_selected(item_index)
		4:
			var raw_image := PackedByteArray()
			raw_image.resize(16*16)
			var data := {
				"modifier": 0,
				"image_type": 1,
				"width": 16,
				"height": 16,
				"unk_0x0E": 0xFFFF,
				"unk_0x10": 0xFF,
				"animation_speed": 8,
				"animation": [raw_image],
				"offsets_array": [],
			}
			das[key][item_index]["offset"] = 1
			das[key][item_index]["data"] = data
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 1
			%ItemList.set_item_text(item_index, "%d - Animation" % item_index)
			_on_item_list_item_selected(item_index)
		5:
			var raw_image := PackedByteArray()
			raw_image.resize(16*16)
			var data := {
				"modifier": 1 << 6,
				"image_type": 0,
				"width": 16,
				"height": 16,
				"pack_type": 64,
				"offsets_index": [0],
				"offsets_flipped": [false],
				"image_pack": [
					{
						"modifier": 0,
						"image_type": 0,
						"width": 16,
						"height": 16,
						"raw_image": raw_image,
					},
				],
			}
			das[key][item_index]["offset"] = 1
			das[key][item_index]["data"] = data
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 0
			%ItemList.set_item_text(item_index, "%d - Pack" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		if owner.copied_data.is_empty():
			%PopupMenu.set_item_disabled(1, true)
		else:
			%PopupMenu.set_item_disabled(1, false)
		if das[key][index].offset == 0:
			%PopupMenu.set_item_disabled(3, false)
			%PopupMenu.set_item_disabled(4, false)
			%PopupMenu.set_item_disabled(5, false)
		else:
			%PopupMenu.set_item_disabled(3, true)
			%PopupMenu.set_item_disabled(4, true)
			%PopupMenu.set_item_disabled(5, true)
		%PopupMenu.popup(Rect2(%ItemList.global_position.x + at_position.x, %ItemList.global_position.y + at_position.y, 0, 0))


func _on_find_empty_button_pressed() -> void:
	for i in range(%ItemList.item_count):
		var fat_data: Dictionary = das[key][i]
		if fat_data.offset == 0:
			%ItemList.select(i)
			%ItemList.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			break


func _on_jump_to_filename_pressed(filename: Dictionary) -> void:
	jump_to_filename_pressed.emit(filename)


func _on_jump_to_collision_pressed() -> void:
	jump_to_collision_pressed.emit(%ItemList.get_selected_items()[0])

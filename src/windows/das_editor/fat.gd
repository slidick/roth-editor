extends MarginContainer

signal jump_to_index_pressed(index: int)

enum InitMenu {
	COPY,
	PASTE,
	CLEAR,
	STANDARD,
	ANIMATION,
	ANIMATION_2,
	IMAGE_PACK,
	DIRECTIONAL,
	MONSTER,
}

var das: Dictionary = {}
var key: String = ""
var starting_index: int = -1


func reset() -> void:
	das = {}
	key = ""
	%ItemList.clear()
	%GenericContainer.reset()
	%EmptyContainer.show()


func load_das(p_das: Dictionary, p_key: String, p_starting_index: int) -> void:
	das = p_das
	key = p_key
	starting_index = p_starting_index
	
	if name == "Fat4":
		%AddButton.show()
	else:
		%AddButton.hide()
	
	for i in range(len(das[key])):
		var fat_name: String = str(p_starting_index + i)
		if "data" in das[key][i]:
			if "raw_image" in das[key][i].data:
				fat_name += "  -  Image"
			if "faces" in das[key][i].data:
				fat_name += "  -  3D"
			if "animation" in das[key][i].data:
				fat_name += "  -  Animation"
			if "animation_2" in das[key][i].data:
				fat_name += "  -  Animation2"
			if "image_pack" in das[key][i].data:
				fat_name += "  -  Pack"
		if das[key][i].flags_1 & 32 > 0 and das[key][i].flags_1 & 4 > 0:
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
	elif "data" in das[key][index] and "animation_2" in das[key][index].data:
		%Animation2Container.show()
		%Animation2Container.load_animation_data(das[key][index], das.raw_palette, true if key == "fat_3" else false)
	elif "data" in das[key][index] and "image_pack" in das[key][index].data:
		%ImagePackContainer.show()
		%ImagePackContainer.load_pack_data(das[key][index], das.raw_palette, true if key == "fat_3" else false)
	elif "data" in das[key][index] and "faces" in das[key][index].data:
		%"3DObjectContainer".show()
		%"3DObjectContainer".load_3d_object_data(das[key][index], das.raw_palette)
	elif das[key][index].flags_1 & 32 > 0 and das[key][index].flags_1 & 4 == 0:
		%DirectionalContainer.show()
		%DirectionalContainer.load_directional_data(das[key][index], true if key == "fat_3" else false, das)
	elif das[key][index].flags_1 & 32 > 0 and das[key][index].flags_1 & 4 > 0:
		%MonsterContainer.show()
		%MonsterContainer.load_monster_data(das[key][index], das)
	elif das[key][index].size == 0:
		%EmptyContainer.show()
	else:
		assert(false)


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
		InitMenu.COPY:
			var data: Dictionary = das[key][item_index]
			owner.copy_data(data)
		InitMenu.PASTE:
			if das[key][item_index].offset != 0:
				if not await Dialog.confirm("Paste over selected data?", "Confirm", false, Vector2(400,200)):
					return
			var fat_index: int = das[key][item_index].index
			das[key][item_index] = owner.copied_data.duplicate(true)
			var original_filename: Dictionary = das[key][item_index].filename
			das[key][item_index].index = fat_index
			if name == "Fat3":
				if "object_collision" in das[key][item_index]:
					das.object_collisions[item_index].raw_data = das[key][item_index].object_collision.raw_data
				das[key][item_index].object_collision = das.object_collisions[item_index]
			else:
				das[key][item_index].erase("object_collision")
			
			das[key][item_index]["filename"] = {
				"name": "%s (COPY)" % original_filename.name,
				"desc": original_filename.desc,
				"index": das[key][item_index].index,
				"size": 4,
			}
			
			if "data" in das[key][item_index]:
				if "animation" in das[key][item_index].data:
					%ItemList.set_item_text(item_index, "%d - Animation" % das[key][item_index].index)
				elif "animation_2" in das[key][item_index].data:
					%ItemList.set_item_text(item_index, "%d - Animation2" % das[key][item_index].index)
				elif "image_pack" in das[key][item_index].data:
					%ItemList.set_item_text(item_index, "%d - Pack" % das[key][item_index].index)
				elif "faces" in das[key][item_index].data:
					%ItemList.set_item_text(item_index, "%d - 3D" % das[key][item_index].index)
				else:
					%ItemList.set_item_text(item_index, "%d - Image" % das[key][item_index].index)
			if das[key][item_index].flags_1 & 32 > 0 and das[key][item_index].flags_1 & 4 > 0:
				%ItemList.set_item_text(item_index, "%d - Monster" % das[key][item_index].index)
			elif das[key][item_index].flags_1 & 32 > 0:
				%ItemList.set_item_text(item_index, "%d - Directional" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)
		InitMenu.CLEAR:
			if await Dialog.confirm("Clear selected data?", "Confirm", false, Vector2(400,200)):
				das[key][item_index].offset = 0
				das[key][item_index].size = 0
				das[key][item_index].flags_1 = 0
				das[key][item_index].flags_2 = 0
				das[key][item_index].erase("data")
				das[key][item_index].erase("filename")
				das[key][item_index].erase("directional_mapping")
				das[key][item_index].erase("monster_mapping")
				%ItemList.set_item_text(item_index, "%d" % das[key][item_index].index)
				_on_item_list_item_selected(item_index)
		InitMenu.STANDARD:
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
			das[key][item_index]["size"] = 1
			das[key][item_index]["data"] = data
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 0
			das[key][item_index]["filename"] = {
				"name": "NEW_IMAGE",
				"desc": "",
				"index": das[key][item_index].index,
				"size": 4,
			}
			%ItemList.set_item_text(item_index, "%d - Image" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)
		InitMenu.ANIMATION:
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
			das[key][item_index]["size"] = 1
			das[key][item_index]["data"] = Das.compile_animation(data)
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 1
			das[key][item_index]["filename"] = {
				"name": "NEW_ANIMATION",
				"desc": "",
				"index": das[key][item_index].index,
				"size": 4,
			}
			%ItemList.set_item_text(item_index, "%d - Animation" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)
		InitMenu.ANIMATION_2:
			var raw_image := PackedByteArray()
			raw_image.resize(16*16)
			var data := {
				"modifier": 0,
				"image_type": 1,
				"width": 16,
				"height": 16,
				"first_image_offset": 8, # speed
				"animation_2": [],
			}
			var sub_data := {
				"sub_image_type": 0x17,
				"width": 16,
				"x_offset": 0,
				"height": 16,
				"y_offset": 0,
				"raw_image": raw_image,
			}
			sub_data["rle_image"] = RLE.encode_rle_img(sub_data)
			data.animation_2.append(sub_data)
			das[key][item_index]["offset"] = 1
			das[key][item_index]["size"] = 1
			das[key][item_index]["data"] = data
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 2
			das[key][item_index]["filename"] = {
				"name": "NEW_ANIMATION2",
				"desc": "",
				"index": das[key][item_index].index,
				"size": 4,
			}
			%ItemList.set_item_text(item_index, "%d - Animation2" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)
		InitMenu.IMAGE_PACK:
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
			das[key][item_index]["size"] = 1
			das[key][item_index]["data"] = data
			das[key][item_index].flags_1 = 0
			das[key][item_index].flags_2 = 0
			das[key][item_index]["filename"] = {
				"name": "NEW_PACK",
				"desc": "",
				"index": das[key][item_index].index,
				"size": 4,
			}
			%ItemList.set_item_text(item_index, "%d - Pack" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)
		InitMenu.DIRECTIONAL:
			das[key][item_index]["offset"] = 1
			das[key][item_index]["size"] = 1
			das[key][item_index].flags_1 = 32
			das[key][item_index].flags_2 = 0
			das[key][item_index].directional_mapping = {
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
			das[key][item_index]["filename"] = {
				"name": "NEW_DIRECTIONAL",
				"desc": "",
				"index": das[key][item_index].index,
				"size": 4,
			}
			
			%ItemList.set_item_text(item_index, "%d - Directional" % das[key][item_index].index)
			_on_item_list_item_selected(item_index)
		InitMenu.MONSTER:
			das[key][item_index]["offset"] = 1
			das[key][item_index]["size"] = 1
			das[key][item_index].flags_1 = 36
			das[key][item_index].flags_2 = 0
			das[key][item_index].monster_mapping = {
				"unk_0x00": 0,
				"flying_back": 0,
				"flying_back_right": 0,
				"flying_right": 0,
				"flying_front_right": 0,
				"flying_front": 0,
				"flying_front_left": 0,
				"flying_left": 0,
				"flying_back_left": 0,
				"walking_back": 0,
				"walking_back_right": 0,
				"walking_right": 0,
				"walking_front_right": 0,
				"walking_front": 0,
				"walking_front_left": 0,
				"walking_left": 0,
				"walking_back_left": 0,
				"attack1_back": 0,
				"attack1_back_right": 0,
				"attack1_right": 0,
				"attack1_front_right": 0,
				"attack1_front": 0,
				"attack1_front_left": 0,
				"attack1_left": 0,
				"attack1_back_left": 0,
				"attack2_back": 0,
				"attack2_back_right": 0,
				"attack2_right": 0,
				"attack2_front_right": 0,
				"attack2_front": 0,
				"attack2_front_left": 0,
				"attack2_left": 0,
				"attack2_back_left": 0,
				"on_damage_back": 0,
				"on_damage_back_right": 0,
				"on_damage_right": 0,
				"on_damage_front_right": 0,
				"on_damage_front": 0,
				"on_damage_front_left": 0,
				"on_damage_left": 0,
				"on_damage_back_left": 0,
				"dying_normal": 0,
				"dead_normal": 0,
				"dying_crit": 0,
				"dead_crit": 0,
				"spawn": 0,
				"unk_0x5E": 0,
				"unk_0x60": 0,
				"unk_0x64": 0,
			}
			das[key][item_index]["filename"] = {
				"name": "NEW_MONSTER",
				"desc": "",
				"index": das[key][item_index].index,
				"size": 4,
			}
			%ItemList.set_item_text(item_index, "%d - Monster" % das[key][item_index].index)
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
			if name != "Fat3" and name != "Fat4":
				%PopupMenu.set_item_disabled(5, true)
			else:
				%PopupMenu.set_item_disabled(5, false)
			if name != "Fat4":
				%PopupMenu.set_item_disabled(6, false)
			else:
				%PopupMenu.set_item_disabled(6, true)
			if name == "Fat3":
				%PopupMenu.set_item_disabled(7, false)
				if das.das_info.is_ademo:
					%PopupMenu.set_item_disabled(8, false)
				else:
					%PopupMenu.set_item_disabled(8, true)
			else:
				%PopupMenu.set_item_disabled(7, true)
				%PopupMenu.set_item_disabled(8, true)
		else:
			%PopupMenu.set_item_disabled(3, true)
			%PopupMenu.set_item_disabled(4, true)
			%PopupMenu.set_item_disabled(5, true)
			%PopupMenu.set_item_disabled(6, true)
			%PopupMenu.set_item_disabled(7, true)
			%PopupMenu.set_item_disabled(8, true)
		%PopupMenu.popup(Rect2(%ItemList.global_position.x + at_position.x, %ItemList.global_position.y + at_position.y, 0, 0))


func _on_find_empty_button_pressed() -> void:
	for i in range(%ItemList.item_count):
		var fat_data: Dictionary = das[key][i]
		if fat_data.offset == 0:
			%ItemList.select(i)
			%ItemList.ensure_current_is_visible()
			_on_item_list_item_selected(i)
			break


func _on_jump_to_index_pressed(index: int) -> void:
	jump_to_index_pressed.emit(index)


func _on_add_button_pressed() -> void:
	var new_index: int = -1
	if len(das[key]) == 0:
		new_index = starting_index
	else:
		new_index = das[key][-1].index + 1
	var fat_entry: Dictionary = {
		"offset": 0,
		"size": 0,
		"flags_1": 0,
		"flags_2": 0,
		"index": new_index,
	}
	das[key].append(fat_entry)
	var idx: int = %ItemList.add_item(str(new_index))
	%ItemList.set_item_metadata(idx, das[key][len(das[key])-1])
	%ItemList.select(idx)
	%ItemList.ensure_current_is_visible()


#func _on_directional_object_added() -> void:
	#directional_object_added.emit()

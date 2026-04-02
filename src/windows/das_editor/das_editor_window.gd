extends BaseWindow

var das: Dictionary = {}
var original_das: Dictionary = {}
var save_tween: Tween
var copied_data: Dictionary

func _ready() -> void:
	super._ready()
	Roth.settings_loaded.connect(_on_settings_loaded)
	Roth.edit_texture.connect(_on_edit_texture)
	window_title = "Manage DAS Files"
	%ListContainer.show()
	%EditContainer.hide()
	for child: Node in %DASTabContainer.get_children():
		%SectionItemList.add_item(child.name)
	%SectionItemList.select(0)
	%SuccessLabel.modulate.a = 0.0


func _on_settings_loaded() -> void:
	%EditDASButton.disabled = true
	%DASList.clear()
	for das_info: Dictionary in Roth.das_packs:
		var idx: int = %DASList.add_item(das_info.name)
		%DASList.set_item_metadata(idx, das_info)
	%DAS2List.clear()
	for das_info: Dictionary in Roth.das2_packs:
		var idx: int = %DAS2List.add_item(das_info.name+" (Active)" if das_info.active else das_info.name)
		%DAS2List.set_item_metadata(idx, das_info)


#region DASList
func _on_das_list_item_selected(_index: int) -> void:
	%DAS2List.deselect_all()
	var das_info: Dictionary = %DASList.get_item_metadata(%DASList.get_selected_items()[0])
	if "vanilla" in das_info:
		%EditDASButton.disabled = true
	else:
		%EditDASButton.disabled = false


func _on_das_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if "vanilla" in %DASList.get_item_metadata(index):
				%DASListPopupMenu.set_item_disabled(0, true)
				%DASListPopupMenu.set_item_disabled(1, true)
			else:
				%DASListPopupMenu.set_item_disabled(0, false)
				%DASListPopupMenu.set_item_disabled(1, false)
			%DASListPopupMenu.popup(Rect2(%DASList.global_position.x+at_position.x, %DASList.global_position.y+at_position.y, 0, 0))


func _on_das_list_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			print("RENAME")
		1:
			var das_info: Dictionary = %DASList.get_item_metadata(%DASList.get_selected_items()[0])
			if not await Dialog.confirm("Are you sure you wish to delete:\n%s" % das_info.filepath, "Deleting DAS File: %s" % das_info.name, false, Vector2(400,150)):
				return
			Roth.delete_das_pack(das_info)
		2:
			var das_info: Dictionary = %DASList.get_item_metadata(%DASList.get_selected_items()[0])
			var err: String = "init"
			var results: Array = [false, ""]
			while not err.is_empty():
				results = await Dialog.input("New Name:", "Duplicating DAS File: %s" % das_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
				if not results[0]:
					return
				err = Roth.check_das_pack_name(results[1])
			Roth.duplicate_das_pack(das_info, results[1])
			%DASList.select(%DASList.item_count - 1)
			_on_das_list_item_selected(%DASList.item_count - 1)


func _on_das_list_item_activated(_index: int) -> void:
	_edit_das(%DASList.get_item_metadata(%DASList.get_selected_items()[0]))
#endregion


#region DASList2
func _on_das_2_list_item_selected(_index: int) -> void:
	%DASList.deselect_all()
	var das_info: Dictionary = %DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0])
	if "vanilla" in das_info:
		%EditDASButton.disabled = true
	else:
		%EditDASButton.disabled = false


func _on_das_2_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_RIGHT:
			if "vanilla" in %DAS2List.get_item_metadata(index):
				%DAS2ListPopupMenu.set_item_disabled(0, true)
				%DAS2ListPopupMenu.set_item_disabled(1, true)
			else:
				%DAS2ListPopupMenu.set_item_disabled(0, false)
				%DAS2ListPopupMenu.set_item_disabled(1, false)
			if %DAS2List.get_item_metadata(index).active:
				%DAS2ListPopupMenu.set_item_disabled(3, true)
			else:
				%DAS2ListPopupMenu.set_item_disabled(3, false)
			%DAS2ListPopupMenu.popup(Rect2(%DAS2List.global_position.x+at_position.x, %DAS2List.global_position.y+at_position.y, 0, 0))


func _on_das_2_list_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			print("RENAME")
		1:
			var das_info: Dictionary = %DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0])
			if not await Dialog.confirm("Are you sure you wish to delete:\n%s" % das_info.filepath, "Deleting DAS File: %s" % das_info.name, false, Vector2(400,150)):
				return
			Roth.delete_das2_pack(das_info)
		2:
			var das_info: Dictionary = %DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0])
			var err: String = "init"
			var results: Array = [false, ""]
			while not err.is_empty():
				results = await Dialog.input("New Name:", "Duplicating DAS File: %s" % das_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
				if not results[0]:
					return
				err = Roth.check_das_pack_name(results[1])
			Roth.duplicate_das2_pack(das_info, results[1])
			%DAS2List.select(%DAS2List.item_count - 1)
			_on_das_2_list_item_selected(%DAS2List.item_count - 1)
		3:
			var new_index: int = %DAS2List.get_selected_items()[0]
			for i in range(%DAS2List.item_count):
				var das_info: Dictionary = %DAS2List.get_item_metadata(i)
				if i == new_index:
					das_info.active = true
					%DAS2List.set_item_text(i, das_info.name+" (Active)")
					Settings.update_settings("options", {"active_ademo": das_info.name})
				else:
					das_info.active = false
					%DAS2List.set_item_text(i, das_info.name)


func _on_das_2_list_item_activated(_index: int) -> void:
	_edit_das(%DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0]))
#endregion


func _on_edit_das_button_pressed() -> void:
	if len(%DASList.get_selected_items()) != 0:
		_edit_das(%DASList.get_item_metadata(%DASList.get_selected_items()[0]))
	if len(%DAS2List.get_selected_items()) != 0:
		_edit_das(%DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0]))


func _on_edit_texture(p_das_info: Dictionary, p_index: int) -> void:
	#print("Edit index: %d DAS: %s" % [p_index, p_das_info.name])
	toggle(true)
	if not das.is_empty():
		if das.das_info == p_das_info:
			_on_filenames_jump_to_index_pressed(p_index)
		else:
			if await _on_cancel_button_pressed():
				_edit_das(p_das_info)
				_on_filenames_jump_to_index_pressed(p_index)
	else:
		_edit_das(p_das_info)
		_on_filenames_jump_to_index_pressed(p_index)


func _edit_das(das_info: Dictionary) -> void:
	if "vanilla" in das_info:
		return
	
	das = Das.parse_das(das_info)
	if das.is_empty():
		return
	
	original_das = das.duplicate(true)
	
	window_title = "Editing DAS - %s" % das["das_info"].name
	
	load_das(das)
	
	%ListContainer.hide()
	%EditContainer.show()


func _on_cancel_button_pressed() -> bool:
	if original_das != das:
		if not await Dialog.confirm("There are unsaved changes!\nAre you sure?", "Changes will be lost!", false, Vector2(400,200)):
			return false
	das = {}
	original_das = {}
	%ListContainer.show()
	%EditContainer.hide()
	window_title = "Manage DAS Files"
	reset_das()
	return true


func _on_save_button_pressed() -> void:
	var bytes: PackedByteArray = Das.compile(das)
	if bytes.is_empty():
		return
	var file := FileAccess.open(das.das_info.filepath, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()
	original_das = das.duplicate(true)
	%Palette.update_original()
	if save_tween:
		save_tween.kill()
	%SuccessLabel.modulate.a = 1.0
	save_tween = get_tree().create_tween()
	save_tween.tween_property(%SuccessLabel, "modulate:a", 1.0, 0.5)
	save_tween.tween_property(%SuccessLabel, "modulate:a", 0.0, 2.0)


func reset_das() -> void:
	for child: Node in %DASTabContainer.get_children():
		child.reset()


func _on_section_item_list_item_selected(index: int) -> void:
	%DASTabContainer.current_tab = index
	if %DASTabContainer.get_child(index).has_method("reload"):
		%DASTabContainer.get_child(index).reload()


func load_das(p_das: Dictionary) -> void:
	%Header.load_das(p_das)
	%Palette.load_das(p_das)
	%PaletteShading.load_das(p_das)
	%Unk0x10.load_das(p_das, "unk_0x10_section")
	%Fat1.load_das(p_das, "fat_1", 0)
	%Fat2.load_das(p_das, "fat_2", len(p_das["fat_1"]))
	%Fat3.load_das(p_das, "fat_3", len(p_das["fat_1"])+len(p_das["fat_2"]))
	%Fat4.load_das(p_das, "fat_4", len(p_das["fat_1"])+len(p_das["fat_2"])+len(p_das["fat_3"]))
	%DirectionalObjectMappings.load_das(p_das, "directional_object_mappings")
	%ObjectCollisions.load_das(p_das, "object_collisions")
	%MonsterMappings.load_das(p_das, "monster_mappings")
	%Unk0x38.load_das(p_das, "unk_0x38_section")
	%Unk0x40.load_das(p_das, "unk_0x40_section")
	%Filenames1.load_das(p_das, "filenames_1")
	%Filenames2.load_das(p_das, "filenames_2")


func _on_filenames_jump_to_index_pressed(index: int) -> void:
	if %Fat1.select_index(index):
		%SectionItemList.select(4)
		_on_section_item_list_item_selected(4)
	if %Fat2.select_index(index):
		%SectionItemList.select(5)
		_on_section_item_list_item_selected(5)
	if %Fat3.select_index(index):
		%SectionItemList.select(6)
		_on_section_item_list_item_selected(6)
	if %Fat4.select_index(index):
		%SectionItemList.select(7)
		_on_section_item_list_item_selected(7)


func edit_image(p_texture_data: Dictionary, p_raw_palette: PackedByteArray) -> Variant:
	return await %ImageEditor.edit_image(p_texture_data, p_raw_palette)


func copy_data(p_data: Dictionary) -> void:
	copied_data = p_data.duplicate(true)


func _on_jump_to_collision_pressed(index: int) -> void:
	%SectionItemList.select(9)
	_on_section_item_list_item_selected(9)
	%ObjectCollisions.select(index)


func _on_jump_to_object_pressed(index: int) -> void:
	%SectionItemList.select(6)
	_on_section_item_list_item_selected(6)
	%Fat3.select(index)


func _on_jump_to_filename_pressed(filename: Dictionary) -> void:
	if %Filenames1.select(filename):
		%SectionItemList.select(13)
		_on_section_item_list_item_selected(13)
	if %Filenames2.select(filename):
		%SectionItemList.select(14)
		_on_section_item_list_item_selected(14)

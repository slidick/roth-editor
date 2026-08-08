extends BaseWindow

enum Page {
	PALETTE,
	PALETTE_SHADING,
	FAT_1,
	FAT_2,
	FAT_3,
	FAT_4,
	UNK_0x10,
	UNK_0X38,
	UNK_0X40,
}

var das: Dictionary = {}
var original_das: Dictionary = {}
var save_tween: Tween
var copied_data: Dictionary

func _ready() -> void:
	super._ready()
	Roth.settings_updated.connect(_on_settings_updated)
	Roth.edit_texture.connect(_on_edit_texture)
	window_title = "Manage DAS Files"
	%ListContainer.show()
	%EditContainer.hide()
	for child: Node in %DASTabContainer.get_children():
		var item_name: String = child.name
		if item_name == "Fat1":
			item_name = "Fat1 - Textures"
		if item_name == "Fat2":
			item_name = "Fat2 - Textures"
		if item_name == "Fat3":
			item_name = "Fat3 - Objects"
		if item_name == "Fat4":
			item_name = "Fat4 - Directional"
		%SectionItemList.add_item(item_name)
	%SectionItemList.select(0)
	%SuccessLabel.modulate.a = 0.0


func _on_settings_updated() -> void:
	%EditDASButton.disabled = true
	%DASList.clear()
	for das_info: Dictionary in DASPack.das_packs:
		var idx: int = %DASList.add_item(das_info.name)
		%DASList.set_item_metadata(idx, das_info)
	%DAS2List.clear()
	for das_info: Dictionary in DASPack.das2_packs:
		var idx: int = %DAS2List.add_item(das_info.name)
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
			DASPack.delete_das_pack(das_info)
		2:
			var das_info: Dictionary = %DASList.get_item_metadata(%DASList.get_selected_items()[0])
			var err: String = "init"
			var results: Array = [false, ""]
			while not err.is_empty():
				results = await Dialog.input("New Name:", "Duplicating DAS File: %s" % das_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
				if not results[0]:
					return
				err = DASPack.check_name(results[1])
			DASPack.duplicate_das_pack(das_info, results[1])
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
			%DAS2ListPopupMenu.popup(Rect2(%DAS2List.global_position.x+at_position.x, %DAS2List.global_position.y+at_position.y, 0, 0))


func _on_das_2_list_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			print("RENAME")
		1:
			var das_info: Dictionary = %DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0])
			if not await Dialog.confirm("Are you sure you wish to delete:\n%s" % das_info.filepath, "Deleting DAS File: %s" % das_info.name, false, Vector2(400,150)):
				return
			DASPack.delete_das2_pack(das_info)
		2:
			var das_info: Dictionary = %DAS2List.get_item_metadata(%DAS2List.get_selected_items()[0])
			var err: String = "init"
			var results: Array = [false, ""]
			while not err.is_empty():
				results = await Dialog.input("New Name:", "Duplicating DAS File: %s" % das_info.name, results[1], err if err != "init" else "", false, Vector2(400,150))
				if not results[0]:
					return
				err = DASPack.check_name(results[1])
			DASPack.duplicate_das2_pack(das_info, results[1])
			%DAS2List.select(%DAS2List.item_count - 1)
			_on_das_2_list_item_selected(%DAS2List.item_count - 1)


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
			_on_jump_to_index_pressed(p_index)
		else:
			if await _on_cancel_button_pressed():
				await _edit_das(p_das_info)
				_on_jump_to_index_pressed(p_index)
	else:
		await _edit_das(p_das_info)
		_on_jump_to_index_pressed(p_index)


func _edit_das(das_info: Dictionary) -> void:
	if "vanilla" in das_info:
		return
	%Loading.toggle(true)
	das = await Das.parse_das(das_info)
	if das.is_empty():
		return
	
	original_das = das.duplicate(true)
	
	window_title = "Editing DAS - %s" % das["das_info"].name
	
	load_das(das)
	
	%ListContainer.hide()
	%EditContainer.show()
	%Loading.toggle(false)


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
	%Saving.toggle(true)
	var bytes: PackedByteArray = await Das.compile(das)
	if bytes.is_empty():
		return
	var file := FileAccess.open(das.das_info.filepath, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()
	%Saving.toggle(false)
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
	if %DASTabContainer.get_child(index).has_method("reload_palette"):
		%DASTabContainer.get_child(index).reload_palette()


func load_das(p_das: Dictionary) -> void:
	%Palette.load_das(p_das)
	%PaletteShading.load_das(p_das)
	%Unk0x10.load_das(p_das, "unk_0x10_section")
	%Fat1.load_das(p_das, "fat_1", 0)
	%Fat2.load_das(p_das, "fat_2", len(p_das["fat_1"]))
	%Fat3.load_das(p_das, "fat_3", len(p_das["fat_1"])+len(p_das["fat_2"]))
	%Fat4.load_das(p_das, "fat_4", len(p_das["fat_1"])+len(p_das["fat_2"])+len(p_das["fat_3"]))
	%Unk0x38.load_das(p_das, "unk_0x38_section")
	%Unk0x40.load_das(p_das, "unk_0x40_section")


func _on_jump_to_index_pressed(index: int) -> void:
	if %Fat1.select_index(index):
		%SectionItemList.select(Page.FAT_1)
		_on_section_item_list_item_selected(Page.FAT_1)
	if %Fat2.select_index(index):
		%SectionItemList.select(Page.FAT_2)
		_on_section_item_list_item_selected(Page.FAT_2)
	if %Fat3.select_index(index):
		%SectionItemList.select(Page.FAT_3)
		_on_section_item_list_item_selected(Page.FAT_3)
	if %Fat4.select_index(index):
		%SectionItemList.select(Page.FAT_4)
		_on_section_item_list_item_selected(Page.FAT_4)


func edit_image(p_texture_data: Dictionary, p_raw_palette: PackedByteArray, p_lock_size: bool = false) -> Variant:
	return await %ImageEditor.edit_image(p_texture_data, p_raw_palette, false, p_lock_size)


func copy_data(p_data: Dictionary) -> void:
	copied_data = p_data.duplicate(true)


func import_sprite_sheet(p_raw_palette: PackedByteArray) -> Dictionary:
	return await %SpriteSheetImporter.import_sprite_sheet(p_raw_palette)


func edit_animation_2_alignments(animation_image: Dictionary, raw_palette: PackedByteArray) -> Dictionary:
	return await %EditAlignments.edit_alignments(animation_image, raw_palette)


func _on_set_new_sky(old_index: int) -> void:
	if old_index < len(das.fat_1):
		%Fat1.remove_old_sky(old_index)
	elif old_index < len(das.fat_1)+len(das.fat_2):
		%Fat2.remove_old_sky(old_index-len(das.fat_1))
	elif old_index < len(das.fat_1)+len(das.fat_2)+len(das.fat_3):
		%Fat3.remove_old_sky(old_index-len(das.fat_1)-len(das.fat_2))
	elif old_index < len(das.fat_1)+len(das.fat_2)+len(das.fat_3)+len(das.fat_4):
		%Fat4.remove_old_sky(old_index-len(das.fat_1)-len(das.fat_2)-len(das.fat_3))
	else:
		assert(false)

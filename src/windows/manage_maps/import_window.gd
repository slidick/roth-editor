extends BaseWindow


var map_data: Dictionary = {}

func import_map() -> void:
	%FileDialog.popup_centered()


func clear() -> void:
	%NameLabel.text = ""
	%VersionLabel.text = ""
	%TitleLabel.text = ""
	%ReleaseLabel.text = ""
	%DescriptionLabel.text = ""
	%StoryLabel.text = ""
	%ImportButton.disabled = true
	for child: Node in %MapsContainer.get_children():
		child.queue_free()
	%DBaseCheckBox.text = ""
	%DBaseEdit.clear()
	%DBaseWarningLabel.hide()
	%DBaseInvalidLabel.hide()
	%SFXCheckBox.text = ""
	%SFXEdit.clear()
	%SFXWarningLabel.hide()
	%SFXInvalidLabel.hide()
	map_data = {}


func _on_file_dialog_file_selected(_path: String) -> void:
	var reader := ZIPReader.new()
	var err := reader.open(%FileDialog.current_path)
	if err != OK:
		Dialog.information("Can't read file", "Error", false, Vector2(400,150))
		return
	map_data = JSON.parse_string(reader.read_file("data.json").get_string_from_utf8())
	reader.close()
	
	#print(JSON.stringify(map_data, '\t'))
	
	%NameLabel.text = map_data.get("name")
	%VersionLabel.text = map_data.get("version")
	%TitleLabel.text = map_data.get("title")
	%ReleaseLabel.text = map_data.get("release")
	%DescriptionLabel.text = map_data.get("description")
	%StoryLabel.text = map_data.get("story")
	
	if "maps" in map_data:
		%MapsImportContainer.show()
		for map_info: Dictionary in map_data.get("maps"):
			var hbox := HBoxContainer.new()
			
			var checkbox := CheckBox.new()
			checkbox.text = map_info.name
			checkbox.custom_minimum_size.x = 170
			checkbox.button_pressed = true
			map_info["import"] = true
			hbox.add_child(checkbox)
			
			if map_info.name in Roth.maps.map(func (m: Dictionary) -> String:
				if "vanilla" in m:
					return m.name
				return ""
			):
				var label := Label.new()
				label.text = "Can't import vanilla maps!"
				label.add_theme_color_override("font_color", Color.RED)
				checkbox.button_pressed = false
				checkbox.disabled = true
				map_info["import"] = false
				hbox.add_child(label)
			elif map_info.name in Roth.maps.map(func (m: Dictionary) -> String:
				if "vanilla" in m:
					return ""
				return m.name
			):
				var label := Label.new()
				label.text = "Map exists locally and will be overwritten on import!"
				label.add_theme_color_override("font_color", Color.RED)
				checkbox.button_pressed = false
				map_info["import"] = false
				hbox.add_child(label)
			
			checkbox.toggled.connect(func (toggled: bool) -> void:
				map_info["import"] = toggled
				check_for_allow_import()
			)
			
			%MapsContainer.add_child(hbox)
	else:
		%MapsImportContainer.hide()
	
	if "dbase_pack" in map_data:
		%DBaseImportContainer.show()
		%DBaseCheckBox.text = map_data.dbase_pack.name
		%DBaseCheckBox.button_pressed = true
		check_for_dbase_collision(map_data.dbase_pack.name)
	else:
		%DBaseImportContainer.hide()
		%DBaseCheckBox.button_pressed = false
	
	if "sfx_pack" in map_data:
		%SFXImportContainer.show()
		%SFXCheckBox.text = map_data.sfx_pack.name
		%SFXCheckBox.button_pressed = true
		check_for_sfx_collision(map_data.sfx_pack.name)
	else:
		%SFXImportContainer.hide()
		%SFXCheckBox.button_pressed = false
	
	check_for_allow_import()
	
	toggle(true)


func check_for_allow_import() -> void:
	if %DBaseCheckBox.button_pressed:
		if not %DBaseEdit.text.is_empty():
			var err: String = Roth.check_dbase_pack_name(%DBaseEdit.text)
			if not err.is_empty():
				%ImportButton.disabled = true
				%DBaseInvalidLabel.show()
				return
			%ImportButton.disabled = false
			return
		else:
			%ImportButton.disabled = false
			return
	else:
		%DBaseInvalidLabel.hide()
	
	if %SFXCheckBox.button_pressed:
		if not %SFXEdit.text.is_empty():
			var err: String = Roth.check_sfx_pack_name(%SFXEdit.text)
			if not err.is_empty():
				%ImportButton.disabled = true
				%SFXInvalidLabel.show()
				return
			%ImportButton.disabled = false
			return
		else:
			%ImportButton.disabled = false
			return
	else:
		%SFXInvalidLabel.hide()
	
	for child_hbox: HBoxContainer in %MapsContainer.get_children():
		var checkbox: CheckBox = child_hbox.get_child(0)
		if checkbox.button_pressed:
			%ImportButton.disabled = false
			return

	%ImportButton.disabled = true


func _on_import_button_pressed() -> void:
	if "maps" in map_data:
		for map_info: Dictionary in map_data.maps:
			if map_info.import:
				var map_raw := Marshalls.base64_to_raw(map_info.raw)
				map_info.erase("raw")
				map_info.erase("import")
				map_info["filepath"] = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.name.to_upper() + ".RAW")
				map_info["filepath_json"] = Roth.ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.name.to_upper() + ".json")
				Roth.close_map.emit(map_info)
				Roth.save_raw(map_info, map_raw)
	if %DBaseCheckBox.button_pressed and "dbase_pack" in map_data:
		var dbase_name: String = map_data.dbase_pack.name
		if not %DBaseEdit.text.is_empty():
			dbase_name = %DBaseEdit.text
		DirAccess.make_dir_recursive_absolute(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_name))
		var reader := ZIPReader.new()
		for filename: String in ["DBASE100.DAT", "DBASE200.DAT", "DBASE300.DAT", "DBASE400.DAT", "DBASE500.DAT"]:
			reader.open(%FileDialog.current_path)
			var data := reader.read_file(filename)
			var file := FileAccess.open(Roth.ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_name).path_join(filename), FileAccess.WRITE)
			file.store_buffer(data)
			file.close()
		reader.close()
		if dbase_name not in Roth.dbase_packs.map(func (d: Dictionary) -> String: return d.name):
			Roth.import_dbase_pack(dbase_name)
	if %SFXCheckBox.button_pressed and "sfx_pack" in map_data:
		var sfx_name: String = map_data.sfx_pack.name
		if not %SFXEdit.text.is_empty():
			sfx_name = %SFXEdit.text
		DirAccess.make_dir_recursive_absolute(Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(sfx_name))
		var reader := ZIPReader.new()
		reader.open(%FileDialog.current_path)
		var data := reader.read_file("FXSCRIPT.SFX")
		var file := FileAccess.open(Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(sfx_name).path_join("FXSCRIPT.SFX"), FileAccess.WRITE)
		file.store_buffer(data)
		file.close()
		reader.close()
		if sfx_name not in Roth.sfx_packs.map(func (d: Dictionary) -> String: return d.name):
			Roth.import_sfx_pack(sfx_name)
	clear()
	toggle(false)
	Roth.settings_loaded.emit()
	await Dialog.information("Successfully imported map data!", "Import Success", false, Vector2(400,170))


func _on_cancel_button_pressed() -> void:
	clear()
	toggle(false)


func _on_dbase_edit_text_changed(new_text: String) -> void:
	%DBaseInvalidLabel.hide()
	if new_text.is_empty():
		check_for_dbase_collision(map_data.dbase_pack.name)
	else:
		check_for_dbase_collision(new_text)
	check_for_allow_import()


func _on_sfx_edit_text_changed(new_text: String) -> void:
	%SFXInvalidLabel.hide()
	if new_text.is_empty():
		check_for_sfx_collision(map_data.sfx_pack.name)
	else:
		check_for_sfx_collision(new_text)
	check_for_allow_import()


func check_for_dbase_collision(new_text: String) -> void:
	if new_text.to_upper() in Roth.dbase_packs.map(func (d: Dictionary) -> String: return d.name.to_upper()):
		%DBaseWarningLabel.show()
	else:
		%DBaseWarningLabel.hide()


func check_for_sfx_collision(new_text: String) -> void:
	if new_text.to_upper() in Roth.sfx_packs.map(func (d: Dictionary) -> String: return d.name.to_upper()):
		%SFXWarningLabel.show()
	else:
		%SFXWarningLabel.hide()


func _on_d_base_check_box_toggled(_toggled_on: bool) -> void:
	check_for_allow_import()


func _on_sfx_check_box_toggled(_toggled_on: bool) -> void:
	check_for_allow_import()

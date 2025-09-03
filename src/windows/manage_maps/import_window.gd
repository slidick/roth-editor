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
	for child: Node in %MapsContainer.get_children():
		child.queue_free()
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
			)
			
			%MapsContainer.add_child(hbox)
	else:
		%MapsImportContainer.hide()
	
	
	toggle(true)


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
	
	clear()
	toggle(false)
	Roth.settings_loaded.emit()
	await Dialog.information("Successfully imported map data!", "Import Success", false, Vector2(400,170))
	


func _on_cancel_button_pressed() -> void:
	clear()
	toggle(false)

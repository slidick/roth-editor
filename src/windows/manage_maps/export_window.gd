extends BaseWindow

var export_presets: Array = []

func _ready() -> void:
	super._ready()
	%MapsTree.create_item()
	%MapsTree.set_column_title(0, "Map")
	%MapsTree.set_column_title(1, "Das")
	export_presets = Settings.settings.get("export", {}).get("presets", [])
	
	for preset: Dictionary in export_presets:
		%PresetOption.add_item(preset.name)
		%PresetOption.set_item_metadata(%PresetOption.item_count-1, preset)


func export_maps(p_maps: Array) -> void:
	for map: Dictionary in p_maps:
		var tree_item: TreeItem = %MapsTree.get_root().create_child()
		tree_item.set_text(0, map.name)
		tree_item.set_text(1, map.das)
		tree_item.set_metadata(0, map)
	
	toggle(true)


func reset() -> void:
	for tree_item: TreeItem in %MapsTree.get_root().get_children():
		tree_item.free()


func _on_cancel_button_pressed() -> void:
	reset()
	toggle(false)


func _on_export_button_pressed() -> void:
	if %PresetOption.selected == 0:
		%FileDialog.current_file = %NameEdit.text
	%FileDialog.popup_centered()


func _on_file_dialog_file_selected(_path: String) -> void:
	var writer := ZIPPacker.new()
	var err := writer.open(%FileDialog.current_path)
	
	if err != OK:
		await Dialog.information("Permission denied.", "Error", false, Vector2(400,150), "Close")
		%FileDialog.show()
		return
	
	var info: Dictionary
	if %PresetOption.selected == 0:
		info = {
			"name": %NameEdit.text,
			"version": %VersionEdit.text,
			"title": %TitleEdit.text,
			"release": %ReleaseDateEdit.text,
			"description": %DescriptionEdit.text,
			"story": %StoryEdit.text,
			"export_path": %FileDialog.current_path,
		}
		%PresetOption.add_item(info.name)
		%PresetOption.set_item_metadata(%PresetOption.item_count-1, info)
		%PresetOption.select(%PresetOption.item_count-1)
		_on_preset_option_item_selected(%PresetOption.item_count-1)
		export_presets.append(info)
		Settings.update_settings("export", {"presets": export_presets})
	else:
		info = %PresetOption.get_item_metadata(%PresetOption.selected)
		info.name = %NameEdit.text
		info.version = %VersionEdit.text
		info.title = %TitleEdit.text
		info.release = %ReleaseDateEdit.text
		info.description = %DescriptionEdit.text
		info.story = %StoryEdit.text
		info.export_path = %FileDialog.current_path
		Settings.update_settings("export", {"presets": export_presets})
		%PresetOption.set_item_text(%PresetOption.selected, info.name)
	
	var export_info: Dictionary = info.duplicate()
	export_info.maps = []
	for tree_item: TreeItem in %MapsTree.get_root().get_children():
		var map_info: Dictionary = tree_item.get_metadata(0).duplicate()
		map_info["raw"] = Marshalls.raw_to_base64(Roth.get_map(map_info).compile())
		map_info.erase("filepath")
		map_info.erase("filepath_json")
		map_info.erase("vanilla")
		export_info.maps.append(map_info)
	
	
	writer.start_file("data.json")
	writer.write_file(JSON.stringify(export_info, '\t').to_utf8_buffer())
	writer.close_file()
	writer.close()
	toggle(false)
	await Dialog.information("Exported successfully to:\n%s" % %FileDialog.current_path, "Success!", true, Vector2(400, 170), "Close")
	reset()


func _on_preset_option_item_selected(index: int) -> void:
	if index == 0:
		%DeletePresetButton.hide()
		%NameEdit.text = ""
		%VersionEdit.text = ""
		%TitleEdit.text = ""
		%ReleaseDateEdit.text = ""
		%DescriptionEdit.text = ""
		%StoryEdit.text = ""
	else:
		%DeletePresetButton.show()
		var info: Dictionary = %PresetOption.get_item_metadata(index)
		%NameEdit.text = info.name
		%VersionEdit.text = info.version
		%TitleEdit.text = info.title
		%ReleaseDateEdit.text = info.release
		%DescriptionEdit.text = info.description
		%StoryEdit.text = info.story
		%FileDialog.current_path = info.export_path


func _on_delete_preset_button_pressed() -> void:
	if %PresetOption.selected != 0:
		var info: Dictionary = %PresetOption.get_item_metadata(%PresetOption.selected)
		%PresetOption.remove_item(%PresetOption.selected)
		export_presets.erase(info)
		Settings.update_settings("export", {"presets": export_presets})
	%PresetOption.select(0)
	_on_preset_option_item_selected(0)

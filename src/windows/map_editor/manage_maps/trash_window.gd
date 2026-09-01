extends BaseWindow

signal done


func view_trash(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	clear()
	for filename: String in DirAccess.get_files_at(directory):
		if not filename.to_lower().ends_with(".json.0"):
			continue
		var map_info: Dictionary = Map.get_map_info_from_json_file(directory.path_join(filename))
		if map_info:
			var idx: int = %ItemList.add_item(map_info.name)
			%ItemList.set_item_metadata(idx, Map.new(map_info))
	
	toggle(true)
	await done
	await _fade_out()
	clear()
	return


func clear() -> void:
	for i in range(%ItemList.item_count-1, -1, -1):
		var map: Map = %ItemList.get_item_metadata(i)
		map.unload()
	%ItemList.clear()
	%TrashButton.disabled = true
	%RestoreButton.disabled = true
	%MapPreview.clear()


func _on_item_list_item_selected(index: int) -> void:
	var map: Map = %ItemList.get_item_metadata(index)
	%MapPreview.setup(map, true)
	%TrashButton.disabled = false
	%RestoreButton.disabled = false


func _on_item_list_multi_selected(index: int, selected: bool) -> void:
	if selected:
		_on_item_list_item_selected(index)
	else:
		if %ItemList.get_selected_items().size() > 0:
			_on_item_list_item_selected(%ItemList.get_selected_items()[0])
		else:
			%MapPreview.clear()
			%TrashButton.disabled = true
			%RestoreButton.disabled = true


func _on_cancel_button_pressed() -> void:
	done.emit()
	toggle(false)


func _on_trash_button_pressed() -> void:
	var maps: Array = []
	for index: int in %ItemList.get_selected_items():
		var map: Map = %ItemList.get_item_metadata(index)
		maps.append(map)
	var maps_string: String = "\n".join(maps.map(func(map: Map) -> String: return map.map_info.name))
	if await Dialog.confirm("Permanently erase the following maps?\n%s" % maps_string, "Confirm Deletion", false, Vector2(400,150)):
		for map: Map in maps:
			map.delete_map(true)
		var indices: Array = %ItemList.get_selected_items()
		indices.sort_custom(func (a: int, b: int) -> bool: return a > b)
		for index: int in indices:
			%ItemList.remove_item(index)
		%MapPreview.clear()
		%TrashButton.disabled = true
		%RestoreButton.disabled = true


func _on_empty_trash_button_pressed() -> void:
	if await Dialog.confirm("Permanently erase all maps in the trash?", "Confirm Deletion", false, Vector2(400,150)):
		for i in range(%ItemList.item_count-1, -1, -1):
			var map: Map = %ItemList.get_item_metadata(i)
			map.delete_map(true)
			%ItemList.remove_item(i)
		clear()


func _on_restore_button_pressed() -> void:
	var maps: Array = []
	for index: int in %ItemList.get_selected_items():
		var map: Map = %ItemList.get_item_metadata(index)
		maps.append(map)
	var maps_string: String = "\n".join(maps.map(func(map: Map) -> String: return map.map_info.name))
	if await Dialog.confirm("Restore the following maps?\n%s" % maps_string, "Confirm Restore", false, Vector2(400,150)):
		for map: Map in maps:
			map.map_info.filepath = map.map_info.filepath.get_basename()
			map.map_info.filepath_json = map.map_info.filepath_json.get_basename()
			map.map_info.filepath_map = map.map_info.filepath_map.get_basename()
			DirAccess.rename_absolute(map.map_info.filepath + ".0", map.map_info.filepath)
			DirAccess.rename_absolute(map.map_info.filepath_json + ".0", map.map_info.filepath_json)
			DirAccess.rename_absolute(map.map_info.filepath_map + ".0", map.map_info.filepath_map)
			map.map_info.map_pack = MapPack.get_unassigned_pack()
			map.map_info.map_pack.maps.append(map)
		var indices: Array = %ItemList.get_selected_items()
		indices.sort_custom(func (a: int, b: int) -> bool: return a > b)
		for index: int in indices:
			%ItemList.remove_item(index)
		%MapPreview.clear()
		%TrashButton.disabled = true
		%RestoreButton.disabled = true
		Roth.settings_updated.emit()

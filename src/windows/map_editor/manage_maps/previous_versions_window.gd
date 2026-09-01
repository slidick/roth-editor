extends BaseWindow

signal done

var current_map: Map


func previous_versions(p_map: Map) -> Map:
	current_map = p_map
	%ItemList.clear()
	%ItemList.add_item("Current")
	%ItemList.set_item_metadata(0, p_map)
	var count: int = 1
	while FileAccess.file_exists(p_map.map_info.filepath_json + ".%d" % count):
		var map_info: Dictionary = Map.get_map_info_from_json_file(p_map.map_info.filepath_json + ".%d" % count)
		if map_info:
			map_info["map_pack"] = p_map.map_info.map_pack
			map_info["das_info"] = p_map.map_info.das_info
			%ItemList.add_item("%d" % count)
			%ItemList.set_item_metadata(count, Map.new(map_info))
		count += 1
	
	%ItemList.select(0)
	_on_item_list_item_selected(0)
	
	toggle(true)
	var results: Map = await done
	await _fade_out()
	clear()
	return results


func clear() -> void:
	current_map = null
	%ItemList.clear()
	%MapPreview.clear()


func _on_item_list_item_selected(index: int) -> void:
	var map: Map = %ItemList.get_item_metadata(index)
	%MapPreview.setup(map, true)
	if index == 0:
		%SaveButton.disabled = true
	else:
		%SaveButton.disabled = false


func _on_cancel_button_pressed() -> void:
	for i in range(%ItemList.item_count-1, 0, -1):
		var map: Map = %ItemList.get_item_metadata(i)
		map.unload()
	done.emit(null)
	toggle(false)


func _on_save_button_pressed() -> void:
	if current_map.editable_map:
		if await Dialog.confirm("Map is loaded. Map must be closed.\nClose map?", "Close Map?", false, Vector2(400,160)):
			var editor: Editor = get_tree().get_root().find_child("Editor", true, false)
			if editor:
				editor.close_map(current_map.editable_map)
		else:
			return
	if await Dialog.confirm("This will restore the map to this state.\nAll versions later than this version will be lost.\nRestore this version?", "Confirm Restore", false, Vector2(400,200)):
		var new_map: Map = %ItemList.get_item_metadata(%ItemList.get_selected_items()[0])
		
		# Replace map in map_pack
		var map_pack: Dictionary = current_map.map_info.map_pack
		var pack_index: int = map_pack.maps.find(current_map)
		map_pack.maps.remove_at(pack_index)
		map_pack.maps.insert(pack_index, new_map)
		
		# Unload other maps
		var list_index: int = %ItemList.get_selected_items()[0]
		for i in range(%ItemList.item_count-1, -1, -1):
			if i == list_index:
				continue
			var map: Map = %ItemList.get_item_metadata(i)
			map.unload()
		
		# Erase files lower than list_index
		DirAccess.remove_absolute(current_map.map_info.filepath)
		DirAccess.remove_absolute(current_map.map_info.filepath_json)
		DirAccess.remove_absolute(current_map.map_info.filepath_map)
		for i in range(list_index-1, 0, -1):
			var map: Map = %ItemList.get_item_metadata(i)
			DirAccess.remove_absolute(map.map_info.filepath)
			DirAccess.remove_absolute(map.map_info.filepath_json)
			DirAccess.remove_absolute(map.map_info.filepath_map)
		
		# Rename map
		DirAccess.rename_absolute(new_map.map_info.filepath, new_map.map_info.filepath.get_basename())
		DirAccess.rename_absolute(new_map.map_info.filepath_json, new_map.map_info.filepath_json.get_basename())
		DirAccess.rename_absolute(new_map.map_info.filepath_map, new_map.map_info.filepath_map.get_basename())
		
		# Update map_info
		new_map.map_info.filepath = new_map.map_info.filepath.get_basename()
		new_map.map_info.filepath_json = new_map.map_info.filepath_json.get_basename()
		new_map.map_info.filepath_map = new_map.map_info.filepath_map.get_basename()
		
		# Rename any maps higher than list_index
		var rename_index: int = list_index + 1
		var new_count: int = 1
		while FileAccess.file_exists(new_map.map_info.filepath + ".%d" % rename_index):
			DirAccess.rename_absolute(new_map.map_info.filepath + ".%d" % rename_index, new_map.map_info.filepath + ".%d" % new_count)
			rename_index += 1
			new_count += 1
		rename_index = list_index + 1
		new_count = 1
		while FileAccess.file_exists(new_map.map_info.filepath_json + ".%d" % rename_index):
			DirAccess.rename_absolute(new_map.map_info.filepath_json + ".%d" % rename_index, new_map.map_info.filepath_json + ".%d" % new_count)
			rename_index += 1
			new_count += 1
		rename_index = list_index + 1
		new_count = 1
		while FileAccess.file_exists(new_map.map_info.filepath_map + ".%d" % rename_index):
			DirAccess.rename_absolute(new_map.map_info.filepath_map + ".%d" % rename_index, new_map.map_info.filepath_map + ".%d" % new_count)
			rename_index += 1
			new_count += 1
		
		done.emit(new_map)

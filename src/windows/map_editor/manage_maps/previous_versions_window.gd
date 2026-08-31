extends BaseWindow

signal done

var current_map: Map


func previous_versions(p_map: Map) -> Map:
	current_map = p_map
	%ItemList.clear()
	%ItemList.add_item("Current")
	%ItemList.set_item_metadata(0, p_map)
	p_map.map_info["date"] = Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(p_map.map_info.filepath_json), true)
	var count: int = 1
	while FileAccess.file_exists(p_map.map_info.filepath_json + ".%d" % count):
		var file_string: String = FileAccess.get_file_as_string(p_map.map_info.filepath_json + ".%d" % count)
		if not file_string.is_empty():
			var map_info: Variant = JSON.parse_string(file_string)
			if map_info and "das" in map_info:
				map_info["filepath"] = p_map.map_info.filepath + ".%d" % count
				map_info["filepath_json"] = p_map.map_info.filepath_json + ".%d" % count
				map_info["filepath_map"] = p_map.map_info.filepath_map + ".%d" % count
				map_info["uuid"] = p_map.map_info.uuid
				map_info["map_pack"] = p_map.map_info.map_pack
				map_info["das_info"] = p_map.map_info.das_info
				map_info["date"] = Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(p_map.map_info.filepath_json + ".%d" % count), true)
				map_info.erase("das")
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
	%Map.clear()
	%Sectors.text = ""
	%Faces.text = ""
	%Vertices.text = ""
	%Objects.text = ""
	%MapName.text = ""
	%DASFile.text = ""
	%Commands.text = ""
	%UUID.text = ""
	%Date.text = ""


func _on_item_list_item_selected(index: int) -> void:
	var map: Map = %ItemList.get_item_metadata(index)
	var map_preview: Dictionary = map.get_map_preview()
	if map_preview.is_empty():
		return
	%Map.setup(map_preview.faces)
	%Sectors.text = "%d" % map_preview.sector_count
	%Faces.text = "%d" % len(map_preview.faces)
	%Vertices.text = "%d" % map_preview.vertices_count
	%Objects.text = "%d" % map_preview.objects_count
	%MapName.text = "%s" % map.map_info.name
	%DASFile.text = "%s" % map.map_info.das_info.name
	%Commands.text = "%d" % map_preview.commands_count
	%UUID.text = "%s" % map.map_info.uuid
	%UUID.tooltip_text = "%s" % map.map_info.uuid
	%Date.text = "%s" % map.map_info.date
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
		new_map.map_info.erase("date")
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

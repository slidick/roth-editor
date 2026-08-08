extends BaseWindow

signal done(map: Map)


func new_map(p_map_pack: Dictionary) -> Map:
	%MapNameEdit.text = ""
	%ErrorLabel.text = ""
	%CreateButton.disabled = true
	%DasOption.clear()
	%MapPackOption.clear()
	for das_info: Dictionary in DASPack.das_packs:
		%DasOption.add_item(das_info.name)
		%DasOption.set_item_metadata(%DasOption.item_count-1, das_info)
	for map_pack: Dictionary in MapPack.map_packs:
		if "vanilla" in map_pack:
			continue
		%MapPackOption.add_item(map_pack.name)
		%MapPackOption.set_item_metadata(%MapPackOption.item_count-1, map_pack)
		if p_map_pack == map_pack:
			%MapPackOption.select(%MapPackOption.item_count-1)
	if "unassigned" in p_map_pack or "vanilla" in p_map_pack:
		%MapPackOption.select(%MapPackOption.item_count-1)
	
	toggle(true)
	var map: Map = await done
	toggle(false)
	return map


func _on_cancel_button_pressed() -> void:
	toggle(false)
	done.emit(null)


func _submit() -> void:
	var map_name: String = %MapNameEdit.text.to_upper()
	var map_pack: Dictionary = %MapPackOption.get_selected_metadata()
	var error := Map.check_map_name(map_name, map_pack)
	if not error.is_empty():
		await Dialog.information(error, "Name Error", false, Vector2(400,150))
		return
	
	var create_info := {
		"name": map_name,
		"das_info": %DasOption.get_selected_metadata(),
		"map_pack": map_pack,
	}
	var map := Map.new(create_info)
	map.save_map()
	map_pack.maps.append(map)
	MapPack.save(map.map_info.map_pack)
	done.emit(map)


func _changed() -> void:
	var error: String = Map.check_map_name(%MapNameEdit.text, %MapPackOption.get_selected_metadata())
	if not error.is_empty():
		%ErrorLabel.text = error
		%CreateButton.disabled = true
	else:
		%CreateButton.disabled = false
		%ErrorLabel.text = ""

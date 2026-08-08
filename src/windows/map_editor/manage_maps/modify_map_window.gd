extends BaseWindow

signal done(results: Dictionary)

enum Modification {
	RENAME,
	DUPLICATE,
	DUPLICATE_MULTIPLE,
	SAVE_AS,
	MOVE,
}

var maps: Array
var type: Modification


func modify_maps(p_maps: Array, p_type: Modification) -> Array:
	maps = p_maps
	type = p_type
	var map: Map = p_maps[0]
	%ErrorLabel.text = ""
	%MapPackOption.clear()
	for map_pack: Dictionary in MapPack.map_packs:
		if "vanilla" in map_pack:
			continue
		%MapPackOption.add_item(map_pack.name)
		%MapPackOption.set_item_metadata(%MapPackOption.item_count-1, map_pack)
		if map.map_info.map_pack == map_pack:
			%MapPackOption.select(%MapPackOption.item_count-1)
	if "vanilla" in map.map_info.map_pack:
		%MapPackOption.select(%MapPackOption.item_count-1)
	%MapNameEdit.text = map.map_info.name
	%SaveButton.disabled = true
	toggle(true)
	%MapNameEdit.edit()
	%MapNameEdit.caret_column = len(%MapNameEdit.text)
	match type:
		Modification.RENAME:
			window_title = "Rename Map"
		Modification.DUPLICATE:
			window_title = "Duplicate Map"
			_changed()
		Modification.DUPLICATE_MULTIPLE:
			window_title = "Duplicate Maps"
			_changed()
		Modification.SAVE_AS:
			window_title = "Save Map As"
			_changed()
		Modification.MOVE:
			window_title = "Move Maps"
	if type == Modification.MOVE or type == Modification.DUPLICATE_MULTIPLE:
		%MapNameLabel.hide()
		%MapNameEdit.hide()
	else:
		%MapNameLabel.show()
		%MapNameEdit.show()
	var data: Dictionary = await done
	toggle(false)
	var results: Array = [false, false]
	if not data.is_empty():
		match type:
			Modification.RENAME:
				results = [map.map_info.name != data.new_name, map.map_info.map_pack != data.new_map_pack, data.new_name, data.new_map_pack ]
				MapPack.move_map(map, data.new_map_pack)
				map.rename_map(data.new_name)
			Modification.DUPLICATE:
				var new_map: Map = map.duplicate_map(data.new_name, data.new_map_pack)
				results = [true, new_map]
			Modification.DUPLICATE_MULTIPLE:
				var new_maps: Array = []
				for each_map: Map in maps:
					var new_map: Map = each_map.duplicate_map(each_map.map_info.name, data.new_map_pack)
					new_maps.append(new_map)
				results = [true, new_maps]
			Modification.SAVE_AS:
				map.save_map_as(data.new_name, data.new_map_pack)
				results = [true, data.new_name]
			Modification.MOVE:
				for each_map: Map in maps:
					MapPack.move_map(each_map, data.new_map_pack)
				results = [true]
	return results


func _changed() -> void:
	if type == Modification.MOVE or type == Modification.DUPLICATE_MULTIPLE:
		var error: String = ""
		for map: Map in maps:
			error = Map.check_map_name(map.map_info.name, %MapPackOption.get_selected_metadata())
			if not error.is_empty():
				%ErrorLabel.text = "One of the maps: %s" % error
				%SaveButton.disabled = true
				return
		%SaveButton.disabled = false
		%ErrorLabel.text = ""
	else:
		var error: String = Map.check_map_name(%MapNameEdit.text, %MapPackOption.get_selected_metadata())
		if not error.is_empty():
			%ErrorLabel.text = error
			%SaveButton.disabled = true
		else:
			%SaveButton.disabled = false
			%ErrorLabel.text = ""


func _on_cancel_button_pressed() -> void:
	toggle(false)
	done.emit({})


func _save() -> void:
	var new_name: String = %MapNameEdit.text.to_upper()
	var new_map_pack: Dictionary = %MapPackOption.get_selected_metadata()
	done.emit({
		"new_name": new_name,
		"new_map_pack": new_map_pack,
	})

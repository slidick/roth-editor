class_name MapPack
extends Object

static var map_packs: Array = []


static func save(p_map_pack: Dictionary) -> void:
	if "vanilla" in p_map_pack:
		var options: Dictionary = {
			"%s_dbase" % p_map_pack.vanilla.id: p_map_pack.dbase_info.name,
			"%s_das2" % p_map_pack.vanilla.id: p_map_pack.das2_info.name,
			"%s_sfx" % p_map_pack.vanilla.id: p_map_pack.sfx_info.name,
			"%s_backdrop" % p_map_pack.vanilla.id: p_map_pack.backdrop_info.name,
		}
		Settings.update_settings("pack_options", options)
	elif "unassigned" in p_map_pack:
		var options: Dictionary = {
			"unassigned_dbase": p_map_pack.dbase_info.name,
			"unassigned_das2": p_map_pack.das2_info.name,
			"unassigned_sfx": p_map_pack.sfx_info.name,
			"unassigned_backdrop": p_map_pack.backdrop_info.name,
		}
		Settings.update_settings("pack_options", options)
	else:
		var save_data: Dictionary = {
			"name": p_map_pack.name,
			"dbase_name": p_map_pack.dbase_info.name,
			"das2_name": p_map_pack.das2_info.name,
			"sfx_name": p_map_pack.sfx_info.name,
			"backdrop_name": p_map_pack.backdrop_info.name,
			"icons": p_map_pack.icons,
			"map_uuids": []
		}
		for map: Map in p_map_pack.maps:
			save_data.map_uuids.append(map.map_info.uuid)
		
		if "filepath" not in p_map_pack:
			print("Saving new map pack %s" % p_map_pack.name.to_snake_case())
			p_map_pack["filepath"] = Roth.ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case()) + ".json"
		
		if p_map_pack not in map_packs:
			map_packs.insert(map_packs.size()-1, p_map_pack)
		
		if Roth.ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case())+".json" != p_map_pack.filepath:
			print("Renaming map pack %s to %s" % [p_map_pack.filepath.get_file().get_basename(), p_map_pack.name.to_snake_case()])
			if FileAccess.file_exists(p_map_pack.filepath):
				DirAccess.remove_absolute(p_map_pack.filepath)
			p_map_pack.filepath = Roth.ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case()) + ".json"
		
		var file := FileAccess.open(p_map_pack.filepath, FileAccess.WRITE)
		file.store_string(JSON.stringify(save_data, '\t', false))
		file.close()


static func move_map(p_map: Map, p_new_map_pack: Dictionary) -> void:
	if p_map.map_info.map_pack == p_new_map_pack:
		return
	p_map.map_info.map_pack.maps.erase(p_map)
	save(p_map.map_info.map_pack)
	p_new_map_pack.maps.append(p_map)
	save(p_new_map_pack)
	p_map.map_info.map_pack = p_new_map_pack


static func get_unassigned_pack() -> Dictionary:
	for map_pack: Dictionary in map_packs:
		if "unassigned" in map_pack:
			return map_pack
	return {}


static func check_name(p_name: String) -> String:
	var error := ""
	if p_name.to_snake_case() in map_packs.map(func (p: Dictionary) -> String: return p.name.to_snake_case()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


static func delete(p_map_pack: Dictionary, p_delete_maps: bool) -> void:
	if p_delete_maps:
		for i in range(len(p_map_pack.maps)-1,-1,-1):
			var map: Map = p_map_pack.maps[i]
			map.delete_map(true)
	else:
		var unassigned_pack: Dictionary = get_unassigned_pack()
		for map: Map in p_map_pack.maps:
			if map not in unassigned_pack.maps:
				unassigned_pack.maps.append(map)
	map_packs.erase(p_map_pack)
	if FileAccess.file_exists(p_map_pack.filepath):
		DirAccess.remove_absolute(p_map_pack.filepath)


static func init_vanilla(p_installation: ROTHInstallation) -> void:
	var das_packs: Array = DASPack.init_vanilla_das_pack(p_installation)
	var map_infos: Array = p_installation.get_map_infos(das_packs)
	
	# Create vanilla map pack
	var options: Dictionary = Settings.settings.get("pack_options", {})
	var vanilla_map_pack: Dictionary = {
		"name": p_installation.name,
		"maps": [],
		"vanilla": p_installation,
		"dbase_info": DBasePack.get_by_name_then_installation(options.get("%s_dbase" % p_installation.id, ""), p_installation),
		"das2_info": DASPack.get_das2_pack_by_name_then_installation(options.get("%s_das2" % p_installation.id, ""), p_installation),
		"sfx_info": SFXPack.get_by_name_then_installation(options.get("%s_sfx" % p_installation.id, ""), p_installation),
		"backdrop_info": BackdropPack.get_by_name_then_installation(options.get("%s_backdrop" % p_installation.id, ""), p_installation),
		"icons": "Original",
	}
	map_packs.append(vanilla_map_pack)
	
	# Create and assign maps to map pack
	for map_info: Dictionary in map_infos:
		map_info["map_pack"] = vanilla_map_pack
		vanilla_map_pack.maps.append(Map.new(map_info))


static func init_custom(p_map_directory: String, p_map_pack_directory: String) -> void:
	# Parse custom maps
	var custom_map_infos: Array = []
	for filename in DirAccess.get_files_at(p_map_directory):
		if filename.to_lower().ends_with(".json"):
			var file_string: String = FileAccess.get_file_as_string(p_map_directory.path_join(filename))
			if not file_string.is_empty():
				var map_info: Variant = JSON.parse_string(file_string)
				if map_info and "das" in map_info:
					map_info["filepath"] = p_map_directory.path_join(filename).get_basename() + ".RAW"
					map_info["filepath_json"] = p_map_directory.path_join(filename)
					map_info["uuid"] = filename.get_file().get_basename()
					map_info["map_pack"] = { "invalid": true }
					map_info["das_info"] = { "name": map_info.das + " (Invalid)", "invalid": true }
					for das_info: Dictionary in DASPack.das_packs:
						if map_info.das.get_file().get_basename() == das_info.name:
							map_info.das_info = das_info
							break
					map_info.erase("das")
					custom_map_infos.append(map_info)
	
	# Parse custom map_packs. Creates maps
	for filename: String in DirAccess.get_files_at(p_map_pack_directory):
		if filename.to_lower().ends_with(".json"):
			var file_string: String = FileAccess.get_file_as_string(p_map_pack_directory.path_join(filename))
			if not file_string.is_empty():
				var map_pack: Variant = JSON.parse_string(file_string)
				if map_pack:
					map_pack["filepath"] = p_map_pack_directory.path_join(filename)
					map_pack["maps"] = []
					for uuid: String in map_pack.map_uuids:
						for map_info: Dictionary in custom_map_infos:
							if map_info.uuid == uuid:
								map_info.map_pack = map_pack
								map_pack.maps.append(Map.new(map_info))
					map_pack["dbase_info"] = DBasePack.get_by_name(map_pack.dbase_name)
					map_pack["das2_info"] = DASPack.get_das2_pack_by_name(map_pack.das2_name)
					map_pack["sfx_info"] = SFXPack.get_by_name(map_pack.sfx_name)
					map_pack["backdrop_info"] = BackdropPack.get_by_name(map_pack.backdrop_name)
					map_pack.erase("dbase_name")
					map_pack.erase("das2_name")
					map_pack.erase("sfx_name")
					map_pack.erase("backdrop_name")
					map_pack.erase("map_uuids")
					map_packs.append(map_pack)
	
	
	# Create unassigned map pack
	var options: Dictionary = Settings.settings.get("pack_options", {})
	var unassigned_map_pack: Dictionary = {
		"name": "Unassigned",
		"maps": [],
		"unassigned": true,
		"dbase_info": DBasePack.get_by_name(options.get("unassigned_dbase", "")),
		"das2_info": DASPack.get_das2_pack_by_name(options.get("unassigned_das2", "")),
		"sfx_info": SFXPack.get_by_name(options.get("unassigned_sfx", "")),
		"backdrop_info": BackdropPack.get_by_name(options.get("unassigned_backdrop", "")),
		"icons": "Original",
	}
	map_packs.append(unassigned_map_pack)
	
	# Create and add remaining maps to unassigned map pack
	for map_info: Dictionary in custom_map_infos:
		if "invalid" in map_info.map_pack:
			map_info.map_pack = unassigned_map_pack
			unassigned_map_pack.maps.append(Map.new(map_info))

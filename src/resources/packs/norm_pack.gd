class_name NormPack
extends Object

static var map_packs: Array = []
static var das_packs: Array = []


static func save(p_map_pack: Dictionary) -> void:
	if "vanilla" in p_map_pack:
		pass
		#var options: Dictionary = {
			#"%s_dbase" % p_map_pack.vanilla.id: p_map_pack.dbase_info.name,
			#"%s_das2" % p_map_pack.vanilla.id: p_map_pack.das2_info.name,
			#"%s_sfx" % p_map_pack.vanilla.id: p_map_pack.sfx_info.name,
			#"%s_backdrop" % p_map_pack.vanilla.id: p_map_pack.backdrop_info.name,
			#"%s_icon" % p_map_pack.vanilla.id: p_map_pack.icon_info.name,
		#}
		#Settings.update_settings("pack_options", options)
	elif "unassigned" in p_map_pack:
		pass
		#var options: Dictionary = {
			#"unassigned_dbase": p_map_pack.dbase_info.name,
			#"unassigned_das2": p_map_pack.das2_info.name,
			#"unassigned_sfx": p_map_pack.sfx_info.name,
			#"unassigned_backdrop": p_map_pack.backdrop_info.name,
			#"unassigned_icon": p_map_pack.icon_info.name,
		#}
		#Settings.update_settings("pack_options", options)
	else:
		var save_data: Dictionary = {
			"name": p_map_pack.name,
			#"dbase_name": p_map_pack.dbase_info.name,
			#"das2_name": p_map_pack.das2_info.name,
			#"sfx_name": p_map_pack.sfx_info.name,
			#"backdrop_name": p_map_pack.backdrop_info.name,
			#"icon_name": p_map_pack.icon_info.name,
			"title": p_map_pack.title,
			"description": p_map_pack.description,
			"story": p_map_pack.story,
			"release": p_map_pack.release,
			"version": p_map_pack.version,
			"normality": true,
			"map_uuids": []
		}
		for map: Map in p_map_pack.maps:
			save_data.map_uuids.append(map.map_info.uuid)
		
		if "filepath" not in p_map_pack:
			print("Saving new map pack %s" % p_map_pack.name.to_snake_case())
			p_map_pack["filepath"] = Normality.NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case()) + ".json"
		
		if p_map_pack not in map_packs:
			map_packs.insert(map_packs.size()-1, p_map_pack)
		
		if Normality.NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case())+".json" != p_map_pack.filepath:
			print("Renaming map pack %s to %s" % [p_map_pack.filepath.get_file().get_basename(), p_map_pack.name.to_snake_case()])
			if FileAccess.file_exists(p_map_pack.filepath):
				DirAccess.remove_absolute(p_map_pack.filepath)
			p_map_pack.filepath = Normality.NORMALITY_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case()) + ".json"
		
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


static func export(p_map_pack: Dictionary, p_filepath: String) -> bool:
	print("Exporting pack to: %s" % p_filepath)
	
	var writer := ZIPPacker.new()
	var err := writer.open(p_filepath)
	if err != OK:
		return false
	
	var l_das_packs: Array = []
	var export_info: Dictionary = {}
	export_info["name"] = p_map_pack.name
	if "vanilla" in p_map_pack:
		export_info["vanilla"] = p_map_pack.vanilla.name
	export_info["title"] = p_map_pack.get("title", "")
	export_info["description"] = p_map_pack.get("description", "")
	export_info["story"] = p_map_pack.get("story", "")
	export_info["release"] = p_map_pack.get("release", "")
	export_info["version"] = p_map_pack.get("version", "")
	export_info["maps"] = []
	for map: Map in p_map_pack.maps:
		var map_info: Dictionary = {}
		map_info["name"] = map.map_info.name
		if "vanilla" in map.map_info:
			map_info["vanilla"] = map.map_info.vanilla.name
		map_info["das_name"] = map.map_info.das_info.get("base", map.map_info.das_info.name).get_file()
		if "vanilla" in map.map_info.das_info:
			map_info["das_vanilla"] = map.map_info.das_info.vanilla.name
		export_info.maps.append(map_info)
		if map.map_info.das_info not in l_das_packs:
			l_das_packs.append(map.map_info.das_info)
	writer.start_file("info.json")
	writer.write_file(JSON.stringify(export_info, '\t', false).to_utf8_buffer())
	writer.close_file()
	
	if len(l_das_packs.filter(func (a: Dictionary) -> bool: return true if "vanilla" not in a else false )) > 0:
		writer.add_directory("DAS")
	for das_info: Dictionary in l_das_packs.filter(func (a: Dictionary) -> bool: return true if "vanilla" not in a else false ):
		writer.start_file("DAS/"+das_info.get("base", das_info.name)+".DAS")
		writer.write_file(FileAccess.get_file_as_bytes(das_info.filepath))
		writer.close_file()
	
	if len(p_map_pack.maps.filter(func (a: Map) -> bool: return true if "vanilla" not in a.map_info else false )) > 0:
		writer.add_directory("MAPS")
	for map: Map in p_map_pack.maps.filter(func (a: Map) -> bool: return true if "vanilla" not in a.map_info else false ):
		writer.start_file("MAPS/"+map.map_info.name+".RAW")
		writer.write_file(FileAccess.get_file_as_bytes(map.map_info.filepath))
		writer.close_file()
	
	
	writer.close()
	return true


static func import(p_import_data: Dictionary, p_map_data: Array) -> Dictionary:
	var overwrite: bool = false
	if p_import_data.name.to_snake_case() in map_packs.map(func (p: Dictionary) -> String: return p.name.to_snake_case()):
		overwrite = true
	
	var map_pack: Dictionary = {
		"name": p_import_data.name,
		"maps": [],
		"title": p_import_data.title,
		"description": p_import_data.description,
		"story": p_import_data.story,
		"release": p_import_data.release,
		"version": p_import_data.version,
	}
	
	var i: int = 0
	for import_map_info: Dictionary in p_import_data.maps:
		if "vanilla" in import_map_info:
			continue
		
		var map_save: Dictionary = {
			"name": import_map_info.name,
			"das": import_map_info.das_name,
			"normality": true,
		}
		var uuid: String = Utility.uuidv4()
		while FileAccess.file_exists(Normality.NORMALITY_CUSTOM_MAP_DIRECTORY.path_join(uuid + ".RAW")):
			uuid = Utility.uuidv4()
		
		var filepath: String = Normality.NORMALITY_CUSTOM_MAP_DIRECTORY.path_join(uuid + ".RAW")
		var file := FileAccess.open(filepath, FileAccess.WRITE)
		file.store_buffer(p_map_data[i])
		file.close()
		
		var filepath_json: String = Normality.NORMALITY_CUSTOM_MAP_DIRECTORY.path_join(uuid + ".json")
		var file_json := FileAccess.open(filepath_json, FileAccess.WRITE)
		file_json.store_string(JSON.stringify(map_save, '\t'))
		file_json.close()
		
		var map_info: Dictionary = {
			"name": import_map_info.name,
			"das_info": get_das_by_name(import_map_info.das_name),
			"filepath": filepath,
			"filepath_json": filepath_json,
			"uuid": uuid,
			"map_pack": map_pack,
			"normality": true,
		}
		map_pack.maps.append(Map.new(map_info))
		
		i += 1
	
	if overwrite:
		for pack: Dictionary in map_packs:
			if pack.name.to_snake_case() == map_pack.name.to_snake_case():
				for j in range(len(pack.maps)-1,-1,-1):
					var map: Map = pack.maps[j]
					if map.editable_map:
						map.editable_map.unload()
					map.unload()
					map.delete_map(true)
				for key: String in pack:
					if key in map_pack:
						pack[key] = map_pack[key]
				print("Overwriting map pack: %s" % pack.name)
				save(pack)
				return pack
	else:
		save(map_pack)
	return map_pack


static func init_vanilla(p_installation: NormalityInstallation) -> void:
	das_packs = p_installation.get_das_packs()
	var map_infos: Array = p_installation.get_map_infos(das_packs)
	
	var vanilla_map_pack: Dictionary = {
		"name": p_installation.name,
		"maps": [],
		"vanilla": p_installation,
		"normality": true,
	}
	map_packs.append(vanilla_map_pack)
	
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
					map_info["normality"] = true
					map_info["map_pack"] = { "invalid": true }
					map_info["das_info"] = { "name": map_info.das + " (Invalid)", "invalid": true }
					for das_info: Dictionary in das_packs:
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
					#map_pack["dbase_info"] = DBasePack.get_by_name(map_pack.dbase_name)
					#map_pack["das2_info"] = DASPack.get_das2_pack_by_name(map_pack.das2_name)
					#map_pack["sfx_info"] = SFXPack.get_by_name(map_pack.sfx_name)
					#map_pack["backdrop_info"] = BackdropPack.get_by_name(map_pack.backdrop_name)
					#map_pack["icon_info"] = IconPack.get_by_name(map_pack.icon_name)
					#map_pack.erase("dbase_name")
					#map_pack.erase("das2_name")
					#map_pack.erase("sfx_name")
					#map_pack.erase("backdrop_name")
					#map_pack.erase("icon_name")
					map_pack.erase("map_uuids")
					map_packs.append(map_pack)
	
	
	# Create unassigned map pack
	#var options: Dictionary = Settings.settings.get("pack_options", {})
	var unassigned_map_pack: Dictionary = {
		"name": "Unassigned",
		"maps": [],
		"unassigned": true,
		"normality": true,
		#"dbase_info": DBasePack.get_by_name(options.get("unassigned_dbase", "")),
		#"das2_info": DASPack.get_das2_pack_by_name(options.get("unassigned_das2", "")),
		#"sfx_info": SFXPack.get_by_name(options.get("unassigned_sfx", "")),
		#"backdrop_info": BackdropPack.get_by_name(options.get("unassigned_backdrop", "")),
		#"icon_info": IconPack.get_by_name(options.get("unassigned_icon", "")),
	}
	map_packs.append(unassigned_map_pack)
	
	# Create and add remaining maps to unassigned map pack
	for map_info: Dictionary in custom_map_infos:
		if "invalid" in map_info.map_pack:
			map_info.map_pack = unassigned_map_pack
			unassigned_map_pack.maps.append(Map.new(map_info))


static func get_das_by_name(p_name: String) -> Dictionary:
	for das_info: Dictionary in das_packs:
		if das_info.name == p_name:
			return das_info
	return { "name": p_name + " (Invalid)", "invalid": true }

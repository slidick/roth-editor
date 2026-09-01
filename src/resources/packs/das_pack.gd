class_name DASPack
extends Object

static var das_packs: Array = []
static var das2_packs: Array = []


static func init_vanilla_das_pack(p_installation: ROTHInstallation) -> Array:
	var das_files: Array = p_installation.get_das_files()
	var vanilla_das_packs: Array = []
	for das_name: String in das_files:
		var das_info: Dictionary = {
			"name": p_installation.name + " - " + das_name,
			"filepath": p_installation.get(das_name.to_lower()),
			"vanilla": p_installation,
			"is_ademo": false,
			"base": das_name,
		}
		vanilla_das_packs.append(das_info)
	das_packs.append_array(vanilla_das_packs)
	return vanilla_das_packs


static func init_custom_das_packs(p_directory: String) -> void:
	for filename: String in DirAccess.get_files_at(p_directory):
		if filename.get_extension().to_lower() == "das":
			var das_info: Dictionary = {
				"name": filename.get_basename().get_file(),
				"filepath": p_directory.path_join(filename),
				"is_ademo": false,
				"base": filename.get_basename().get_file(),
			}
			das_packs.append(das_info)


static func init_vanilla_das2_pack(p_installation: ROTHInstallation) -> void:
	var das2_info := {
		"name": p_installation.name,
		"filepath": p_installation.ademo,
		"vanilla": p_installation,
		"is_ademo": true,
	}
	das2_packs.append(das2_info)


static func init_custom_das2_packs(p_directory: String) -> void:
	for filename: String in DirAccess.get_files_at(p_directory):
		if filename.get_extension().to_lower() == "das":
			var das2_info := {
				"name": filename.get_basename().get_file(),
				"filepath": p_directory.path_join(filename),
				"is_ademo": true,
			}
			das2_packs.append(das2_info)


static func check_name(p_name: String) -> String:
	var error := ""
	if (p_name.to_lower() in das_packs.map(func (d: Dictionary) -> String: return d.name.to_lower())
		or  p_name.to_lower() in das2_packs.map(func (d: Dictionary) -> String: return d.name.to_lower())
	):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


static func duplicate_das_pack(p_das_info: Dictionary, p_new_name: String) -> Dictionary:
	var das_info := p_das_info.duplicate()
	das_info.name = p_new_name.to_upper()
	das_info.erase("vanilla")
	das_info.filepath = Roth.ROTH_CUSTOM_DAS_DIRECTORY.path_join(p_new_name.to_upper()+".DAS")
	DirAccess.copy_absolute(p_das_info.filepath, das_info.filepath)
	das_packs.append(das_info)
	Roth.settings_updated.emit()
	return das_info


static func delete_das_pack(p_das_info: Dictionary) -> void:
	if FileAccess.file_exists(p_das_info.filepath):
		DirAccess.remove_absolute(p_das_info.filepath)
	das_packs.erase(p_das_info)
	Roth.settings_updated.emit()


static func rename_das_pack(p_das_info: Dictionary, p_new_name: String) -> void:
	DirAccess.rename_absolute(
		p_das_info.filepath,
		Roth.ROTH_CUSTOM_DAS_DIRECTORY.path_join(p_new_name.to_upper()+".DAS")
	)
	p_das_info.name = p_new_name
	p_das_info.filepath = Roth.ROTH_CUSTOM_DAS_DIRECTORY.path_join(p_new_name.to_upper()+".DAS")
	Roth.settings_updated.emit()


static func import_das_pack(p_name: String, p_data: PackedByteArray) -> void:
	var das_info := {
		"name": p_name,
		"filepath": Roth.ROTH_CUSTOM_DAS_DIRECTORY.path_join(p_name.to_upper()+".DAS"),
		"is_ademo": false,
	}
	var file := FileAccess.open(das_info.filepath, FileAccess.WRITE)
	file.store_buffer(p_data)
	file.close()
	
	das_packs.append(das_info)


static func duplicate_das2_pack(p_das2_info: Dictionary, p_new_name: String) -> Dictionary:
	var das2_info := p_das2_info.duplicate()
	das2_info.name = p_new_name.to_upper()
	das2_info.erase("vanilla")
	das2_info.filepath = Roth.ROTH_CUSTOM_DAS2_DIRECTORY.path_join(p_new_name.to_upper()+".DAS")
	DirAccess.copy_absolute(p_das2_info.filepath, das2_info.filepath)
	das2_packs.append(das2_info)
	Roth.settings_updated.emit()
	return das2_info


static func delete_das2_pack(p_das2_info: Dictionary) -> void:
	if FileAccess.file_exists(p_das2_info.filepath):
		DirAccess.remove_absolute(p_das2_info.filepath)
	das2_packs.erase(p_das2_info)
	MapPack.update_subpack_deleted(p_das2_info)
	Roth.settings_updated.emit()


static func rename_das2_pack(p_das_info: Dictionary, p_new_name: String) -> void:
	DirAccess.rename_absolute(
		p_das_info.filepath,
		Roth.ROTH_CUSTOM_DAS2_DIRECTORY.path_join(p_new_name.to_upper()+".DAS")
	)
	p_das_info.name = p_new_name
	p_das_info.filepath = Roth.ROTH_CUSTOM_DAS2_DIRECTORY.path_join(p_new_name.to_upper()+".DAS")
	MapPack.update_subpack_name(p_das_info)
	Roth.settings_updated.emit()


static func import_das2_pack(p_name: String, p_data: PackedByteArray) -> void:
	var overwrite: bool = false
	if (p_name.to_lower() in das_packs.map(func (d: Dictionary) -> String: return d.name.to_lower())
		or  p_name.to_lower() in das2_packs.map(func (d: Dictionary) -> String: return d.name.to_lower())
	):
		overwrite = true
	
	var das2_info := {
		"name": p_name,
		"filepath": Roth.ROTH_CUSTOM_DAS2_DIRECTORY.path_join(p_name.to_upper()+".DAS"),
		"is_ademo": true,
	}
	var file := FileAccess.open(das2_info.filepath, FileAccess.WRITE)
	file.store_buffer(p_data)
	file.close()
	
	if overwrite:
		pass
	else:
		das2_packs.append(das2_info)


static func get_current_vanilla_das2_pack() -> Dictionary:
	for das2_info: Dictionary in das2_packs:
		if "vanilla" in das2_info and das2_info.vanilla == Roth.current_installation:
			return das2_info
	return {}


static func get_first_vanilla_das2_pack() -> Dictionary:
	var vanilla_das2_array: Array = das2_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)
	return vanilla_das2_array[0] if len(vanilla_das2_array) > 0 else {"name": "None", "invalid": true}


static func get_das2_pack_by_installation(p_installation: ROTHInstallation) -> Dictionary:
	var vanilla_das2_array: Array = das2_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a and a.vanilla == p_installation else false)
	return vanilla_das2_array[0] if len(vanilla_das2_array) > 0 else {"name": "None", "invalid": true}


static func get_by_name(p_name: String, p_check_base_name: bool = false) -> Dictionary:
	for das_info: Dictionary in das_packs:
		if das_info.name == p_name:
			return das_info
	for das2_info: Dictionary in das2_packs:
		if das2_info.name == p_name:
			return das2_info
	if p_check_base_name:
		for das_info: Dictionary in das_packs:
			if "base" in das_info and das_info.base == p_name:
				return das_info
		for das2_info: Dictionary in das2_packs:
			if "base" in das2_info and das2_info.base == p_name:
				return das2_info
	return { "name": p_name + " (Invalid)", "invalid": true }


static func get_das2_pack_by_name(p_name: String) -> Dictionary:
	var das2_info: Dictionary = get_first_vanilla_das2_pack()
	for das2_pack: Dictionary in das2_packs:
		if das2_pack.name == p_name:
			das2_info = das2_pack
	return das2_info


static func get_das2_pack_by_name_then_installation(p_name: String, p_installation: ROTHInstallation) -> Dictionary:
	var das2_info: Dictionary = get_das2_pack_by_installation(p_installation)
	for das2_pack: Dictionary in das2_packs:
		if das2_pack.name == p_name:
			das2_info = das2_pack
	return das2_info


static func create(p_name: String, is_das2: bool) -> Dictionary:
	var filepath: String = ""
	if is_das2:
		filepath = Roth.ROTH_CUSTOM_DAS2_DIRECTORY.path_join(p_name+".DAS")
	else:
		filepath = Roth.ROTH_CUSTOM_DAS_DIRECTORY.path_join(p_name+".DAS")
	
	var das_info: Dictionary = {
		"name": p_name,
		"filepath": filepath,
		"is_ademo": is_das2,
		"base": p_name,
	}
	
	var das := {
		"header": {
			"unk_0x20": 0,
			"sky_index": 0,
		},
		"palette": [],
		"fat_1": [],
		"fat_2": [],
		"fat_3": [],
		"fat_4": [],
		"object_collisions": [],
		"unk_0x10_section": {"raw_data": []},
		"unk_0x38_section": {"raw_data": []},
		"unk_0x40_section": {"raw_data": []},
		"das_info": das_info,
	}
	
	if is_das2:
		for i in range(293):
			das.fat_3.append({"offset": 0, "size": 0, "flags_1": 0, "flags_2": 0})
	else:
		for i in range(3840):
			das.fat_1.append({"offset": 0, "size": 0, "flags_1": 0, "flags_2": 0})
		for i in range(256):
			das.fat_2.append({"offset": 0, "size": 0, "flags_1": 0, "flags_2": 0})
		for i in range(256):
			das.fat_3.append({"offset": 0, "size": 0, "flags_1": 0, "flags_2": 0})
	
	var data: PackedByteArray = await Das.compile(das)
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	
	if is_das2:
		das2_packs.append(das_info)
	else:
		das_packs.append(das_info)
	Roth.settings_updated.emit()
	return das_info

class_name SFXPack
extends Object

static var sfx_packs: Array = []


static func check_name(p_name: String) -> String:
	var error := ""
	if p_name.to_lower() in sfx_packs.map(func (d: Dictionary) -> String: return d.name.to_lower()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


static func duplicate_pack(p_sfx_info: Dictionary, p_new_name: String) -> void:
	var sfx_info := p_sfx_info.duplicate()
	sfx_info.name = p_new_name
	sfx_info.erase("vanilla")
	sfx_info.filepath = Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_new_name).path_join("FXSCRIPT.SFX")
	DirAccess.make_dir_recursive_absolute(sfx_info.filepath.get_base_dir())
	DirAccess.copy_absolute(p_sfx_info.filepath, sfx_info.filepath)
	sfx_packs.append(sfx_info)
	Roth.settings_updated.emit()


static func rename(p_sfx_info: Dictionary, p_new_name: String) -> void:
	DirAccess.rename_absolute(
		Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name),
		Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_new_name)
	)
	p_sfx_info.name = p_new_name
	p_sfx_info.filepath = Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_new_name).path_join("FXSCRIPT.SFX")
	MapPack.update_subpack_name(p_sfx_info)
	Roth.settings_updated.emit()


static func delete(p_sfx_info: Dictionary) -> void:
	if DirAccess.dir_exists_absolute(Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name)):
		Utility.remove_dir_recursive(Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name))
	sfx_packs.erase(p_sfx_info)
	MapPack.update_subpack_deleted(p_sfx_info)
	Roth.settings_updated.emit()


static func import(_p_name: String) -> void:
	pass


static func create(p_name: String) -> void:
	var fxscript := {
		"entries": []
	}
	
	var directory: String = Roth.ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_name)
	DirAccess.make_dir_recursive_absolute(directory)
	var fxscript_filepath := directory.path_join("FXSCRIPT.SFX")
	
	var data := FXScript.compile(fxscript)
	var file := FileAccess.open(fxscript_filepath, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	
	var sfx_info := {
		"name": p_name,
		"count": 0,
		"filesize": len(data),
		"filepath": fxscript_filepath,
	}
	sfx_packs.append(sfx_info)
	Roth.settings_updated.emit()


static func init_vanilla(p_installation: ROTHInstallation) -> void:
	var vanilla_sfx: Dictionary = {
			"name": p_installation.name,
			"vanilla": p_installation,
	}
	vanilla_sfx.merge(FXScript.get_info(p_installation.fx22))
	sfx_packs.append(vanilla_sfx)


static func init_custom(p_directory: String) -> void:
	for dir in DirAccess.get_directories_at(p_directory):
		var sfx_info: Dictionary = {
			"name": dir,
		}
		var fxscript_filename: String = p_directory.path_join(sfx_info.name).path_join("FXSCRIPT.SFX")
		sfx_info.merge(FXScript.get_info(fxscript_filename))
		sfx_packs.append(sfx_info)


static func get_first_vanilla() -> Dictionary:
	var vanilla_sfx_array: Array = sfx_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)
	return vanilla_sfx_array[0] if len(vanilla_sfx_array) > 0 else {"name": "None", "invalid": true}


static func get_by_installation(p_installation: ROTHInstallation) -> Dictionary:
	var vanilla_sfx_array: Array = sfx_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a and a.vanilla == p_installation else false)
	return vanilla_sfx_array[0] if len(vanilla_sfx_array) > 0 else {"name": "None", "invalid": true}


static func get_by_name(p_name: String) -> Dictionary:
	var sfx_info: Dictionary = get_first_vanilla()
	for sfx_pack: Dictionary in sfx_packs:
		if sfx_pack.name == p_name:
			sfx_info = sfx_pack
	return sfx_info


static func get_by_name_then_installation(p_name: String, p_installation: ROTHInstallation) -> Dictionary:
	var sfx_info: Dictionary = get_by_installation(p_installation)
	for sfx_pack: Dictionary in sfx_packs:
		if sfx_pack.name == p_name:
			sfx_info = sfx_pack
	return sfx_info

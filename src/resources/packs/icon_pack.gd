class_name IconPack
extends Object

static var icon_packs: Array = []


static func check_name(p_name: String) -> String:
	var error := ""
	if p_name.to_lower() in icon_packs.map(func (d: Dictionary) -> String: return d.name.to_lower()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


static func duplicate_pack(p_icon_info: Dictionary, p_new_name: String) -> Dictionary:
	var icon_info := p_icon_info.duplicate()
	icon_info.name = p_new_name
	icon_info.erase("vanilla")
	icon_info.filepath = Roth.ROTH_CUSTOM_ICONS_DIRECTORY.path_join(p_new_name+".ALL")
	DirAccess.copy_absolute(p_icon_info.filepath, icon_info.filepath)
	icon_packs.append(icon_info)
	Roth.settings_updated.emit()
	return icon_info


static func rename(p_icon_info: Dictionary, p_new_name: String) -> void:
	DirAccess.rename_absolute(
		p_icon_info.filepath,
		Roth.ROTH_CUSTOM_ICONS_DIRECTORY.path_join(p_new_name+".ALL")
	)
	p_icon_info.name = p_new_name
	p_icon_info.filepath = Roth.ROTH_CUSTOM_ICONS_DIRECTORY.path_join(p_new_name+".ALL")
	MapPack.update_subpack_name(p_icon_info)
	Roth.settings_updated.emit()


static func delete(p_icon_info: Dictionary) -> void:
	if FileAccess.file_exists(Roth.ROTH_CUSTOM_ICONS_DIRECTORY.path_join(p_icon_info.name)+".ALL"):
		DirAccess.remove_absolute(Roth.ROTH_CUSTOM_ICONS_DIRECTORY.path_join(p_icon_info.name)+".ALL")
	icon_packs.erase(p_icon_info)
	Roth.settings_updated.emit()


static func import(_p_name: String) -> void:
	pass


static func create(p_name: String) -> Dictionary:
	var icon_info: Dictionary = {
		"name": p_name,
		"filepath": Roth.ROTH_CUSTOM_ICONS_DIRECTORY.path_join(p_name)+".ALL",
	}
	return icon_info


static func init_vanilla(p_installation: ROTHInstallation) -> void:
	var vanilla_icon: Dictionary = {
		"name": p_installation.name,
		"vanilla": p_installation,
		"filepath": p_installation.icons,
	}
	icon_packs.append(vanilla_icon)


static func init_custom(p_directory: String) -> void:
	for filename in DirAccess.get_files_at(p_directory):
		if filename.get_extension().to_upper() == "ALL":
			var icon_info: Dictionary = {
				"name": filename.get_basename(),
				"filepath": p_directory.path_join(filename),
			}
			icon_packs.append(icon_info)


static func get_first_vanilla() -> Dictionary:
	var vanilla_icon_array: Array = icon_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)
	return vanilla_icon_array[0] if len(vanilla_icon_array) > 0 else {"name": "None", "invalid": true}


static func get_by_installation(p_installation: ROTHInstallation) -> Dictionary:
	var vanilla_icon_array: Array = icon_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a and a.vanilla == p_installation else false)
	return vanilla_icon_array[0] if len(vanilla_icon_array) > 0 else {"name": "None", "invalid": true}


static func get_by_name(p_name: String) -> Dictionary:
	var icon_info: Dictionary = get_first_vanilla()
	for icon_pack: Dictionary in icon_packs:
		if icon_pack.name == p_name:
			icon_info = icon_pack
	return icon_info


static func get_by_name_then_installation(p_name: String, p_installation: ROTHInstallation) -> Dictionary:
	var icon_info: Dictionary = get_by_installation(p_installation)
	for icon_pack: Dictionary in icon_packs:
		if icon_pack.name == p_name:
			icon_info = icon_pack
	return icon_info

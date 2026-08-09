class_name BackdropPack
extends Object

static var backdrop_packs: Array = []


static func check_name(p_name: String) -> String:
	var error := ""
	if p_name.to_lower() in backdrop_packs.map(func (d: Dictionary) -> String: return d.name.to_lower()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


static func duplicate_pack(p_backdrop_info: Dictionary, p_new_name: String) -> Dictionary:
	var backdrop_info := p_backdrop_info.duplicate()
	backdrop_info.name = p_new_name
	backdrop_info.erase("vanilla")
	backdrop_info.filepath = Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_new_name+".RAW")
	DirAccess.copy_absolute(p_backdrop_info.filepath, backdrop_info.filepath)
	backdrop_packs.append(backdrop_info)
	Roth.settings_updated.emit()
	return backdrop_info


static func rename(p_backdrop_info: Dictionary, p_new_name: String) -> void:
	DirAccess.rename_absolute(
		Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_backdrop_info.name+".RAW"),
		Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_new_name+".RAW")
	)
	p_backdrop_info.name = p_new_name
	p_backdrop_info.filepath = Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_new_name+".RAW")
	MapPack.update_subpack_name(p_backdrop_info)
	Roth.settings_updated.emit()


static func delete(p_backdrop_info: Dictionary) -> void:
	if FileAccess.file_exists(Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_backdrop_info.name)+".RAW"):
		DirAccess.remove_absolute(Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_backdrop_info.name)+".RAW")
	backdrop_packs.erase(p_backdrop_info)
	Roth.settings_updated.emit()


static func import(_p_name: String) -> void:
	pass


static func create(p_name: String) -> Dictionary:
	var backdrop_info: Dictionary = {
		"name": p_name,
		"filepath": Roth.ROTH_CUSTOM_BACKDROPS_DIRECTORY.path_join(p_name)+".RAW",
	}
	var raw_image := PackedByteArray()
	raw_image.resize(640*400)
	var image_data: Dictionary = {
		"image_type": 3,
		"x_offset": 0,
		"y_offset": 0,
		"width": 640,
		"height": 400,
		"raw_image": raw_image,
	}
	image_data["rle_data"] = RLE.encode_rle_image(image_data)
	var data: PackedByteArray = Backdrop.compile(image_data)
	var file := FileAccess.open(backdrop_info.filepath, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	backdrop_packs.append(backdrop_info)
	Roth.settings_updated.emit()
	return backdrop_info


static func init_vanilla(p_installation: ROTHInstallation) -> void:
	var vanilla_backdrop: Dictionary = {
			"name": p_installation.name,
			"vanilla": p_installation,
			"filepath": p_installation.backdrop,
	}
	backdrop_packs.append(vanilla_backdrop)


static func init_custom(p_directory: String) -> void:
	for filename in DirAccess.get_files_at(p_directory):
		if filename.get_extension().to_upper() == "RAW":
			var backdrop_info: Dictionary = {
				"name": filename.get_basename(),
				"filepath": p_directory.path_join(filename),
			}
			backdrop_packs.append(backdrop_info)


static func get_first_vanilla() -> Dictionary:
	var vanilla_backdrop_array: Array = backdrop_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)
	return vanilla_backdrop_array[0] if len(vanilla_backdrop_array) > 0 else {"name": "None", "invalid": true}


static func get_by_installation(p_installation: ROTHInstallation) -> Dictionary:
	var vanilla_backdrop_array: Array = backdrop_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a and a.vanilla == p_installation else false)
	return vanilla_backdrop_array[0] if len(vanilla_backdrop_array) > 0 else {"name": "None", "invalid": true}


static func get_by_name(p_name: String) -> Dictionary:
	var backdrop_info: Dictionary = get_first_vanilla()
	for backdrop_pack: Dictionary in backdrop_packs:
		if backdrop_pack.name == p_name:
			backdrop_info = backdrop_pack
	return backdrop_info


static func get_by_name_then_installation(p_name: String, p_installation: ROTHInstallation) -> Dictionary:
	var backdrop_info: Dictionary = get_by_installation(p_installation)
	for backdrop_pack: Dictionary in backdrop_packs:
		if backdrop_pack.name == p_name:
			backdrop_info = backdrop_pack
	return backdrop_info

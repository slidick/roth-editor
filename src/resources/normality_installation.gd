class_name NormalityInstallation
extends RefCounted

const REQUIRED_FILES: Array = [
	"normality_exe",
]

const SUB_DIRECTORIES: Array = [
	""
]

var directory: String = ""
var normality_exe: String :
	get():
		return find("NORM.EXE")
var maps_directory: String :
	get():
		return find_directory("MAPS")
var name: String :
	get():
		if is_valid():
			return "Normality"
		return "Invalid Installation"
var valid: Variant = null
var das_packs: Array = []
var maps: Array = []

func _init(p_directory: String) -> void:
	directory = p_directory


func _to_string() -> String:
	return JSON.stringify({
		directory = directory,
		normality_exe = normality_exe,
	}, "\t", false)


func find(p_file: String) -> String:
	for sub_directory: String in SUB_DIRECTORIES:
		if FileAccess.file_exists(directory.path_join(sub_directory).path_join(p_file)):
			return directory.path_join(sub_directory).path_join(p_file)
	return ""


func find_directory(p_directory: String) -> String:
	for sub_directory: String in SUB_DIRECTORIES:
		if DirAccess.dir_exists_absolute(directory.path_join(sub_directory).path_join(p_directory)):
			return directory.path_join(sub_directory).path_join(p_directory)
	return ""


func is_valid() -> bool:
	if valid == null:
		for file: String in REQUIRED_FILES:
			if get(file).is_empty():
				print("Missing: %s" % file)
				valid = false
		if valid == null:
			valid = true
	return valid


func get_das_packs() -> Array:
	var das_infos: Array = []
	
	for filename: String in DirAccess.get_files_at(maps_directory):
		if filename.get_extension().to_upper() == "MGL":
			var das_info: Dictionary = {
				"name": filename.get_basename().to_upper(),
				"filepath": maps_directory.path_join(filename).replacen(".MGL", ".DAS"),
				"filepath_mgl": maps_directory.path_join(filename),
				"vanilla": true,
				"normality": true,
			}
			das_infos.append(das_info)
	
	return das_infos


func get_map_infos(p_das_packs: Array) -> Array:
	var map_infos: Array = []
	
	for filename: String in DirAccess.get_files_at(maps_directory):
		if filename.get_extension().to_upper() == "RAW":
			var map_info: Dictionary = {
				"name": filename.get_basename().to_upper(),
				"das_info": find_das(p_das_packs, filename.get_basename().to_upper()),
				"filepath": maps_directory.path_join(filename),
				"vanilla": true,
				"normality": true,
			}
			map_infos.append(map_info)
	
	return map_infos


func find_das(p_das_packs: Array, p_map_name: String) -> Dictionary:
	for das_info: Dictionary in p_das_packs:
		if p_map_name.to_upper() == das_info.name.to_upper():
			return das_info
		if p_map_name.left(-1).to_upper() == das_info.name.to_upper():
			return das_info
	return { "name": "Invalid", "invalid": true }

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
				"vanilla": self,
				"normality": true,
				"base": filename.get_basename().to_upper(),
			}
			das_infos.append(das_info)
	
	return das_infos


func get_map_infos(p_das_packs: Array) -> Array:
	var map_infos: Array = []
	var map_das_list: Array = get_map_das_list()
	for map_das: Array in map_das_list:
		if FileAccess.file_exists(maps_directory.path_join(map_das[0])+".RAW"):
			var map_info: Dictionary = {
				"name": map_das[0],
				"das_info": find_das(p_das_packs, map_das[1]),
				"filepath": maps_directory.path_join(map_das[0])+".RAW",
				"vanilla": self,
				"normality": true,
			}
			map_infos.append(map_info)
	
	return map_infos


func find_das(p_das_packs: Array, p_das_name: String) -> Dictionary:
	for das_info: Dictionary in p_das_packs:
		if p_das_name == das_info.name:
			return das_info
	return { "name": p_das_name + " (Invalid)", "invalid": true }


func get_map_das_list() -> Array:
	var das_list: Array = []
	var map_list: Array = []
	var file := FileAccess.open(normality_exe, FileAccess.READ)
	file.seek(0xBA5A5)
	for i in range(30):
		das_list.append(file.get_line().to_upper().trim_prefix("MAPS\\"))
	for i in range(30):
		map_list.append([file.get_line().to_upper().trim_prefix("MAPS\\").trim_suffix(".RAW"), das_list[i]])
	file.close()
	return map_list

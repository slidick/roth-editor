class_name NormalityInstallation
extends RefCounted

const REQUIRED_FILES: Array = [
	"normality_exe",
	"lang_dat",
	"hmidet_386",
	"hmidrv_386",
	"eureka0_sfx",
	"hmimdrv_386",
	"drum",
	"melodic",
	"maps_directory",
	"gfx_directory",
	"gfx1_directory",
]

const SUB_DIRECTORIES: Array = [
	""
]

var das_offsets: Array = []
var map_offsets: Array = []

var directory: String = ""
var normality_exe: String :
	get():
		return find("NORM.EXE")
var normality_exe_md5: String :
	get():
		if not normality_exe_md5.is_empty():
			return normality_exe_md5
		normality_exe_md5 = FileAccess.get_md5(normality_exe)
		return normality_exe_md5
var normality_iso: String :
	get():
		return find("NORMAL.GOG")
var lang_dat: String :
	get():
		return find("LANG.DAT")
var hmidet_386: String :
	get():
		return find("DIGI/HMIDET.386")
var hmidrv_386: String :
	get():
		return find("DIGI/HMIDRV.386")
var eureka0_sfx: String :
	get():
		return find("DIGI/EUREKA0.SFX")
var hmimdrv_386: String :
	get():
		return find("MIDI/HMIMDRV.386")
var drum: String :
	get():
		return find("MIDI/DRUM.BNK")
var melodic: String :
	get():
		return find("MIDI/MELODIC.BNK")
var maps_directory: String :
	get():
		return find_directory("MAPS")
var gfx_directory: String :
	get():
		return find_directory("GFX")
var gfx1_directory: String :
	get():
		return find_directory("GFX1")
var id: String :
	get():
		return directory.md5_text()
var language: String :
	get():
		match normality_exe_md5:
			"2e9c068f1d87cd327da5d3fcc773702c":
				return "French"
			"1f70981fb8556f6a2514700654b5cefa":
				return "German"
			"57c595d94b424b155b15faf091f5716b":
				return "English (UK)"
		return "Unknown"
var name: String :
	get():
		if is_valid():
			return language
		return "Invalid Installation"
var map_das_offset: int = -2 :
	get():
		if map_das_offset != -2:
			return map_das_offset
		var search: PackedByteArray = "maps\\eureka0".to_ascii_buffer()
		search.append(0)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(normality_exe)
		map_das_offset = find_array_in_bytes(bytes, search)
		return map_das_offset
var valid: Variant = null
var das_packs: Array = []
var maps: Array = []


static func write_config_ini(config_ini_filepath: String, disable_cdrom: bool = false) -> void:
	if not DirAccess.dir_exists_absolute(config_ini_filepath.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_ini_filepath.get_base_dir())
	var config_ini_file := FileAccess.open(config_ini_filepath, FileAccess.WRITE)
	if not disable_cdrom:
		config_ini_file.store_string("SourcePath=D:\n")
	config_ini_file.store_string("DestinationPath=C:\\\n")
	config_ini_file.store_string("Installation=Maximum\n")
	config_ini_file.store_string("SoundCard=0xe000\n")
	config_ini_file.store_string("SoundPort=0x220\n")
	config_ini_file.store_string("SoundIRQ=7\n")
	config_ini_file.store_string("SoundDMA=1\n")
	config_ini_file.store_string("MusicCard=0xa009\n")
	config_ini_file.store_string("MusicPort=0x330\n")
	config_ini_file.close()


static func find_array_in_bytes(bytes: PackedByteArray, search_array: PackedByteArray) -> int:
	var prev_index: int = 0
	while prev_index < bytes.size():
		var starting_index: int = -1
		var i: int = 0
		for byte: int in search_array:
			var index: int = bytes.find(byte, prev_index)
			if index >= 0:
				if i == 0:
					starting_index = index
				else:
					if index != prev_index + 1:
						prev_index = starting_index + 1
						starting_index = -1
						break
				prev_index = index
			else:
				return -1
			i += 1
		if starting_index != -1:
			return starting_index
	return -1


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
	if map_das_offset < 0:
		return []
	
	var file := FileAccess.open(normality_exe, FileAccess.READ)
	file.seek(map_das_offset)
	var names: Array = []
	var offsets: Array = []
	while names.size() < 120:
		offsets.append(file.get_position())
		var s: String = file.get_line().to_upper()
		if not s.begins_with("MAPS\\"):
			break
		names.append(s.trim_prefix("MAPS\\"))
	file.close()
	
	var n: int = roundi(names.size() / 2.0)
	if names.size() % 2 != 0 or n == 0:
		push_warning("Map table has uneven strings: %d" % names.size())
		return []
	
	var map_list: Array = []
	for i in range(n):
		if names[i].ends_with(".RAW") or not names[n + i].ends_with(".RAW"):
			push_warning("Map table invalid")
			return []
		map_list.append([names[n+i].trim_suffix(".RAW"), names[i]])
		das_offsets.append(offsets[i])
		map_offsets.append(offsets[n+i])
	
	das_offsets.append(map_offsets[0])
	map_offsets.append(offsets[-1])
	return map_list



func populate_custom_install(new_directory: String) -> bool:
	if not is_valid():
		return false
	
	if DirAccess.dir_exists_absolute(new_directory):
		if (FileAccess.file_exists(new_directory.path_join("NORM.EXE"))
			and FileAccess.file_exists(new_directory.path_join("LANG.DAT"))
			and FileAccess.file_exists(new_directory.path_join("DIGI/HMIDET.386"))
			and FileAccess.file_exists(new_directory.path_join("DIGI/HMIDRV.386"))
			and FileAccess.file_exists(new_directory.path_join("DIGI/EUREKA0.SFX"))
			and FileAccess.file_exists(new_directory.path_join("MIDI/HMIMDRV.386"))
			and FileAccess.file_exists(new_directory.path_join("MIDI/DRUM.BNK"))
			and FileAccess.file_exists(new_directory.path_join("MIDI/MELODIC.BNK"))
		):
			return true
		else:
			Utility.remove_dir_recursive(new_directory)
	
	DirAccess.make_dir_recursive_absolute(new_directory.path_join("DIGI"))
	DirAccess.make_dir_recursive_absolute(new_directory.path_join("GFX"))
	DirAccess.make_dir_recursive_absolute(new_directory.path_join("GFX1"))
	DirAccess.make_dir_recursive_absolute(new_directory.path_join("MIDI"))
	DirAccess.make_dir_recursive_absolute(new_directory.path_join("SAVEGAME"))
	
	DirAccess.copy_absolute(normality_exe, new_directory.path_join("NORM.EXE"))
	DirAccess.copy_absolute(lang_dat, new_directory.path_join("LANG.DAT"))
	DirAccess.copy_absolute(hmidet_386, new_directory.path_join("DIGI/HMIDET.386"))
	DirAccess.copy_absolute(hmidrv_386, new_directory.path_join("DIGI/HMIDRV.386"))
	DirAccess.copy_absolute(eureka0_sfx, new_directory.path_join("DIGI/EUREKA0.SFX"))
	DirAccess.copy_absolute(hmimdrv_386, new_directory.path_join("MIDI/HMIMDRV.386"))
	DirAccess.copy_absolute(drum, new_directory.path_join("MIDI/DRUM.BNK"))
	DirAccess.copy_absolute(melodic, new_directory.path_join("MIDI/MELODIC.BNK"))
	write_config_ini(new_directory.path_join("CONFIG.INI"))
	
	for filename: String in DirAccess.get_files_at(gfx_directory):
		DirAccess.copy_absolute(gfx_directory.path_join(filename), new_directory.path_join("GFX").path_join(filename))
	for filename: String in DirAccess.get_files_at(gfx1_directory):
		DirAccess.copy_absolute(gfx1_directory.path_join(filename), new_directory.path_join("GFX1").path_join(filename))
	
	return true

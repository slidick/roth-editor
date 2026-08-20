class_name NormalityInstallation
extends RefCounted

const REQUIRED_FILES: Array = [
	"normality_exe",
]

const SUB_DIRECTORIES: Array = [
	""
]

const DAS_OFFSETS: Array = [
	0xBA5A5,
	0xBA5B2,
	0xBA5BF,
	0xBA5CA,
	0xBA5D6,
	0xBA5E1,
	0xBA5EE,
	0xBA5FB,
	0xBA608,
	0xBA616,
	0xBA623,
	0xBA630,
	0xBA63D,
	0xBA64A,
	0xBA657,
	0xBA665,
	0xBA66E,
	0xBA67A,
	0xBA684,
	0xBA691,
	0xBA69B,
	0xBA6A8,
	0xBA6B5,
	0xBA6C0,
	0xBA6CB,
	0xBA6D6,
	0xBA6E1,
	0xBA6EC,
	0xBA6F7,
	0xBA704,
	0xBA711,
]

const MAP_OFFSETS: Array = [
	0xBA711,
	0xBA722,
	0xBA733,
	0xBA742,
	0xBA752,
	0xBA761,
	0xBA772,
	0xBA783,
	0xBA794,
	0xBA7A6,
	0xBA7B7,
	0xBA7C8,
	0xBA7D9,
	0xBA7EA,
	0xBA7FB,
	0xBA80D,
	0xBA81A,
	0xBA82A,
	0xBA838,
	0xBA849,
	0xBA857,
	0xBA869,
	0xBA87A,
	0xBA889,
	0xBA899,
	0xBA8A9,
	0xBA8B9,
	0xBA8C9,
	0xBA8D9,
	0xBA8EA,
	0xBA8F9,
]


var directory: String = ""
var normality_exe: String :
	get():
		return find("NORM.EXE")
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
var id: String :
	get():
		return directory.md5_text()
var name: String :
	get():
		if is_valid():
			return "Normality"
		return "Invalid Installation"
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



func populate_custom_install(new_directory: String) -> bool:
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
	
	var gfx_directory: String = find_directory("GFX")
	for filename: String in DirAccess.get_files_at(gfx_directory):
		DirAccess.copy_absolute(gfx_directory.path_join(filename), new_directory.path_join("GFX").path_join(filename))
	var gfx1_directory: String = find_directory("GFX1")
	for filename: String in DirAccess.get_files_at(gfx1_directory):
		DirAccess.copy_absolute(gfx1_directory.path_join(filename), new_directory.path_join("GFX1").path_join(filename))
	
	return true

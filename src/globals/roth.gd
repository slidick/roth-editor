extends Node

signal settings_loaded
signal map_loading_started(map_info: String)
signal map_loading_updated(das_info: Dictionary, progress: float)
signal map_loading_finished(map: Map)
signal map_loading_completely_finished
@warning_ignore("unused_signal")
signal das_loading_started
signal das_loading_updated(progress: float, das_info: Dictionary)
signal das_loading_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal das_parse_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal das_compile_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal gdv_loading_updated(progress: float)
@warning_ignore("unused_signal")
signal close_map(map: Map)
@warning_ignore("unused_signal")
signal editor_action(p_map: Map, p_name: String)
@warning_ignore("unused_signal")
signal edit_texture(p_das_info: Dictionary, p_index: int)

const SCALE_3D_WORLD: float = 100.0
const SCALE_2D_WORLD: float = 10.0
var ROTH_CUSTOM_MAP_DIRECTORY: String = OS.get_user_data_dir().path_join("maps")
var ROTH_CUSTOM_MAP_PACKS_DIRECTORY: String = OS.get_user_data_dir().path_join("map_packs")
var ROTH_CUSTOM_DBASE_DIRECTORY: String = OS.get_user_data_dir().path_join("dbase")
var ROTH_CUSTOM_SFX_DIRECTORY: String = OS.get_user_data_dir().path_join("sfx")
var ROTH_CUSTOM_DAS_DIRECTORY: String = OS.get_user_data_dir().path_join("das")
var ROTH_CUSTOM_DAS2_DIRECTORY: String = OS.get_user_data_dir().path_join("das2")
var ROTH_CUSTOM_INSTALL_DIRECTORY: String = OS.get_user_data_dir().path_join("install")
var ROTH_TEMP_DIRECTORY: String = OS.get_user_data_dir().path_join("temp")

const OLD_EXE: float = 3.925
const NEW_EXE: float = 3.983
const SEQUENTIAL_UNDO_TIMEOUT: float = 1.5
const DRAGGING_THRESHOLD: float = 2.0

const HIGHLIGHT_MATERIAL: StandardMaterial3D = preload("uid://b3vv75mwnat5k")
const SELECTED_MATERIAL: StandardMaterial3D = preload("uid://bcwfrjbr5vhmi")
const HIGHLIGHT_FIXED_Y_MATERIAL: StandardMaterial3D = preload("uid://dhsattf813kya")
const SELECTED_FIXED_Y_MATERIAL: StandardMaterial3D = preload("uid://b5iarhl24whsd")

const DEFAULT_TEXTURE_PRESETS: Dictionary = {
	"DEMO.DAS": {
		"STUDY": { "ceiling": 201, "floor": 59, "wall": 35 },
		"HALLWAY": { "ceiling": 201, "floor": 58, "wall": 8 },
		"MAUSOLEUM": { "ceiling": 766, "floor": 761, "wall": 763 },
	},
	"DEMO1.DAS": {
		"CHURCH": { "ceiling": 153, "floor": 168, "wall": 154},
		"GARDEN": { "ceiling": 1, "floor": 9, "wall": 26},
		"TOWER": { "ceiling": 541, "floor": 535, "wall": 861},
	},
	"DEMO2.DAS": {
		"TEMPLE": { "ceiling": 5, "floor": 7, "wall": 4},
		"LAVA": { "ceiling": 33, "floor": 30, "wall": 32},
		"HALLWAY": { "ceiling": 115, "floor": 116, "wall": 118},
	},
	"DEMO3.DAS": {
		"ALIEN": { "ceiling": 179, "floor": 179, "wall": 180 },
		"CAVERN": { "ceiling": 50, "floor": 118, "wall": 89 },
		"RITUAL": { "ceiling": 625, "floor": 610, "wall": 605 },
	},
	"DEMO4.DAS": {
		"MAUSOLEUM": { "ceiling": 2778, "floor": 2751, "wall": 2787 },
		"EXTERIOR": { "ceiling": 0, "floor": 331, "wall": 2201 },
		"TOMB": { "ceiling": 2025, "floor": 2031, "wall": 2235 },
	}
}

var res: Dictionary = {}
#var maps: Array = []
#var loaded_maps: Array = []
var map_packs: Array = []
var das_packs: Array = []
var das2_packs: Array = []
var dbase_packs: Array = []
var sfx_packs: Array = []
var install_directory: String = ""
var loaded_das: Dictionary = {}
var loading_das: Dictionary = {}
var audio_player: RothAudioPlayer


## Initialization
func _ready() -> void:
	audio_player = RothAudioPlayer.new()
	add_child(audio_player)
	
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_MAP_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_MAP_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_MAP_PACKS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_MAP_PACKS_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DBASE_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DBASE_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_SFX_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_SFX_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DAS_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DAS_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DAS2_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DAS2_DIRECTORY)
	
	das_loading_updated.connect(_on_das_loading_updated)
	Settings.settings_updated.connect(_on_settings_updated)
	
	migrate_to_uuid_map_filenames(false)
	
	# Wait for the scene to be ready so other nodes have time to connect to this nodes settings_loaded signal
	await get_tree().get_root().ready
	load_roth_settings()


func migrate_to_uuid_map_filenames(dryrun: bool = true) -> void:
	for file: String in DirAccess.get_files_at(ROTH_CUSTOM_MAP_DIRECTORY):
		if file.get_extension() != "json":
			continue
		if file.get_basename().get_file().length() > 8:
			continue
		var filepath_json: String = ROTH_CUSTOM_MAP_DIRECTORY.path_join(file)
		var filepath: String = filepath_json.trim_suffix("json") + "RAW"
		var new_filepath_json: String = ROTH_CUSTOM_MAP_DIRECTORY.path_join(Utility.uuidv4()) + ".json"
		var new_filepath: String = new_filepath_json.trim_suffix("json") + "RAW"
		
		var uuid_collisions: int = 0
		while FileAccess.file_exists(new_filepath_json):
			if uuid_collisions == 10:
				assert(false, "Inconceivable number of uuid collisions")
				return
			uuid_collisions += 1
			new_filepath_json = ROTH_CUSTOM_MAP_DIRECTORY.path_join(Utility.uuidv4())
			new_filepath = new_filepath_json.trim_suffix("json") + "RAW"
		
		if dryrun:
			print("rename_absolute(%s, %s)" % [filepath_json, new_filepath_json])
			print("rename_absolute(%s, %s)" % [filepath, new_filepath])
		else:
			DirAccess.rename_absolute(filepath_json, new_filepath_json)
			if FileAccess.file_exists(filepath):
				DirAccess.rename_absolute(filepath, new_filepath)
		
		var count: int = 1
		while FileAccess.file_exists(filepath + ".%d" % count):
			if dryrun:
				print("rename_absolute(%s.%d, %s.%d)" % [filepath, count, new_filepath, count])
			else:
				DirAccess.rename_absolute(filepath + ".%d" % count, new_filepath + ".%d" % count)
			count += 1
		count = 1
		while FileAccess.file_exists(filepath_json + ".%d" % count):
			if dryrun:
				print("rename_absolute(%s.%d, %s.%d)" % [filepath_json, count, new_filepath_json, count])
			else:
				DirAccess.rename_absolute(filepath_json + ".%d" % count, new_filepath_json + ".%d" % count)
			count += 1


#region Settings

func _on_settings_updated(key: String) -> void:
	if key == "locations":
		load_roth_settings()


func load_roth_settings() -> void:
	var locations: Variant = Settings.settings.get("locations")
	var options: Dictionary = Settings.settings.get("options", {})
	var map_infos := []
	var das_files := []
	var das2_files := []
	if locations and locations.get("roth.res"):
		install_directory = locations.get("roth.res").get_base_dir()
		
		# Parse the roth.res file
		var file := FileAccess.open(locations.get("roth.res"), FileAccess.READ)
		while file.get_position() < file.get_length():
			var line: String = file.get_line().replace("\\", "/").replace("\"", "")
			if line.contains("="):
				var line_split: Array = line.split("=")
				if line_split[0] == "das2":
					line_split[1] += ".das"
					das2_files.append(line_split[1].to_upper())
				res[line_split[0]] = line_split[1].to_upper()
				
			elif line.contains("maps"):
				continue
			elif line.contains("}"):
				continue
			elif line.contains(" "):
				var line_split: Array = line.split(" ")
				map_infos.append({
					"name": line_split[0].get_file().get_basename().to_upper(),
					"das": (line_split[1]+".das").to_upper(),
					"filepath": install_directory.path_join((line_split[0]+".raw").to_upper()),
					"vanilla": true,
				})
			elif not line.is_empty():
				res[line] = true
		file.close()
		match res.version:
			"ROTH VERSION F1.4":
				res["exe_version"] = OLD_EXE
			"ROTH VERSION F1.8":
				res["exe_version"] = OLD_EXE
			"ROTH VERSION F1.14":
				res["exe_version"] = OLD_EXE
			"SPANISH ROTH F1":
				res["exe_version"] = NEW_EXE
			"ROTH VERSION 1.8":
				res["exe_version"] = NEW_EXE
			"ROTH VERSION 1.12":
				res["exe_version"] = NEW_EXE
			_:
				res["exe_version"] = 0.0
		
		
		# Get unique das files from vanilla map infos
		for das: String in map_infos.map(func (map: Dictionary) -> String: return map.das ):
			if das not in das_files:
				das_files.append(das)
		das_files.sort()
		
		# Assemble das files into das packs
		das_packs = []
		for filename: String in das_files:
			var das_info := { "name": filename.get_basename().get_file(), "filepath": install_directory.path_join("../DATA/").path_join(filename), "vanilla": true, "is_ademo": false}
			das_packs.append(das_info)
		
		# Append custom das packs
		for filename: String in DirAccess.get_files_at(ROTH_CUSTOM_DAS_DIRECTORY):
			if filename.get_extension().to_lower() == "das":
				var das_info := { "name": filename.get_basename().get_file(), "filepath": ROTH_CUSTOM_DAS_DIRECTORY.path_join(filename), "is_ademo": false}
				das_packs.append(das_info)
		
		
		# Assemble das2 files into das2 packs
		das2_packs = []
		for filename: String in das2_files:
			var das_info := {
				"name": filename.get_basename().get_file(),
				"filepath": install_directory.path_join("../DATA/").path_join(filename),
				"vanilla": true,
				"is_ademo": true,
			}
			das2_packs.append(das_info)
		
		# Append custom das2 packs
		for filename: String in DirAccess.get_files_at(ROTH_CUSTOM_DAS2_DIRECTORY):
			if filename.get_extension().to_lower() == "das":
				var das_info := {
					"name": filename.get_basename().get_file(),
					"filepath": ROTH_CUSTOM_DAS2_DIRECTORY.path_join(filename),
					"is_ademo": true,
				}
				das2_packs.append(das_info)
		
		
		# Create vanilla dbase pack
		dbase_packs = [
			{
				"name": "Original",
				"vanilla": true,
			}
		]
		
		# Append custom dbase packs
		for dir in DirAccess.get_directories_at(ROTH_CUSTOM_DBASE_DIRECTORY):
			var dbase_info := { "name": dir }
			dbase_packs.append(dbase_info)
		
		# Add additional information to dbase packs
		for dbase_info: Dictionary in dbase_packs:
			var dbase_dir: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
			if "vanilla" in dbase_info:
				dbase_dir = install_directory.path_join("../DATA")
			dbase_info["directory"] = dbase_dir
			dbase_info["dbase100_filepath"] = dbase_dir.path_join("DBASE100.DAT")
			dbase_info["dbase200_filepath"] = dbase_dir.path_join("DBASE200.DAT")
			dbase_info["dbase300_filepath"] = dbase_dir.path_join("DBASE300.DAT")
			dbase_info["dbase400_filepath"] = dbase_dir.path_join("DBASE400.DAT")
			dbase_info["dbase500_filepath"] = dbase_dir.path_join("DBASE500.DAT")
			var dbase_100 := FileAccess.open(dbase_dir.path_join("DBASE100.DAT"), FileAccess.READ)
			dbase_info.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
			dbase_info.erase("signature")
			dbase_info.erase("unk_dword_02")
			dbase_info.erase("unk_dword_11")
			dbase_100.close()
		
		
		# Create vanilla sfx pack
		sfx_packs = [
			{
				"name": "Original",
				"vanilla": true,
			}
		]
		
		# Append custom sfx packs
		for dir in DirAccess.get_directories_at(ROTH_CUSTOM_SFX_DIRECTORY):
			var sfx_info := { "name": dir }
			sfx_packs.append(sfx_info)
		
		# Add additional information to sfx packs
		for sfx_info: Dictionary in sfx_packs:
			var sfx_dir: String = ROTH_CUSTOM_SFX_DIRECTORY.path_join(sfx_info.name)
			var fxscript_filename := sfx_dir.path_join("FXSCRIPT.SFX")
			if "vanilla" in sfx_info:
				sfx_dir = install_directory.path_join("../DATA/DATA")
				fxscript_filename = sfx_dir.path_join("FX22.SFX")
			sfx_info.merge(FXScript.get_info(fxscript_filename))
		
		
		# Create vanilla map pack
		# Gather sub packs
		var vanilla_dbase: Dictionary = dbase_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
		var vanilla_dbase_name: String = options.get("vanilla_dbase", "Original")
		for dbase_pack: Dictionary in dbase_packs:
			if dbase_pack.name == vanilla_dbase_name:
				vanilla_dbase = dbase_pack
		var vanilla_sfx: Dictionary = sfx_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
		var vanilla_sfx_name: String = options.get("vanilla_sfx", "Original")
		for sfx_pack: Dictionary in sfx_packs:
			if sfx_pack.name == vanilla_sfx_name:
				vanilla_sfx = sfx_pack
		var vanilla_das2: Dictionary = das2_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
		var vanilla_das2_name: String = options.get("vanilla_das2", "Original")
		for das2_pack: Dictionary in das2_packs:
			if das2_pack.name == vanilla_das2_name:
				vanilla_das2 = das2_pack
		
		var vanilla_map_pack: Dictionary = {
			"name": "Original",
			"map_infos": [],
			"vanilla": true,
			"dbase_info": vanilla_dbase,
			"das2_info": vanilla_das2,
			"sfx_info": vanilla_sfx,
			"backdrop": "Original",
			"icons": "Original",
		}
		for map_info: Dictionary in map_infos:
			vanilla_map_pack["map_infos"].append(map_info)
		map_packs.append(vanilla_map_pack)
		
		
		# Parse custom maps
		var custom_map_infos: Array = []
		for filepath in DirAccess.get_files_at(ROTH_CUSTOM_MAP_DIRECTORY):
			if filepath.to_lower().ends_with(".json"):
				var file_string: String = FileAccess.get_file_as_string(ROTH_CUSTOM_MAP_DIRECTORY.path_join(filepath))
				if not file_string.is_empty():
					var file_json: Variant = JSON.parse_string(file_string)
					if file_json:
						file_json["filepath"] = ROTH_CUSTOM_MAP_DIRECTORY.path_join(filepath).get_basename() + ".RAW"
						file_json["filepath_json"] = ROTH_CUSTOM_MAP_DIRECTORY.path_join(filepath)
						file_json["uuid"] = filepath.get_file().get_basename()
						if "das" not in file_json:
							continue
						map_infos.append(file_json)
						custom_map_infos.append(file_json)
		
		
		# Parse custom map_packs
		for filename: String in DirAccess.get_files_at(ROTH_CUSTOM_MAP_PACKS_DIRECTORY):
			if filename.to_lower().ends_with(".json"):
				var file_string: String = FileAccess.get_file_as_string(ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(filename))
				if not file_string.is_empty():
					var file_json: Variant = JSON.parse_string(file_string)
					if file_json:
						file_json["filepath"] = ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(filename)
						file_json["map_infos"] = []
						for uuid: String in file_json.map_uuids:
							for map_info: Dictionary in custom_map_infos:
								if map_info.uuid == uuid:
									file_json["map_infos"].append(map_info)
						file_json["dbase_info"] = dbase_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
						for dbase_pack: Dictionary in dbase_packs:
							if dbase_pack.name == file_json.dbase_name:
								file_json["dbase_info"] = dbase_pack
						file_json["das2_info"] = das2_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
						for das2_pack: Dictionary in das2_packs:
							if das2_pack.name == file_json.das2_name:
								file_json["das2_info"] = das2_pack
						file_json["sfx_info"] = sfx_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
						for sfx_pack: Dictionary in sfx_packs:
							if sfx_pack.name == file_json.sfx_name:
								file_json["sfx_info"] = sfx_pack
						file_json.erase("dbase_name")
						file_json.erase("das2_name")
						file_json.erase("sfx_name")
						file_json.erase("map_uuids")
						map_packs.append(file_json)
		
		
		# Assign das_info and map_pack to maps
		for map_info: Dictionary in map_infos:
			var das_found: bool = false
			var map_pack_found: bool = false
			for das_info: Dictionary in das_packs:
				if map_info.das.get_file().get_basename() == das_info.name:
					map_info.das_info = das_info
					das_found = true
					break
			for map_pack: Dictionary in map_packs:
				if map_info in map_pack.map_infos:
					map_info["map_pack"] = map_pack
					map_pack_found = true
					break
			if not das_found:
				map_info["das_info"] = {"name": map_info.das+" (Invalid)", "invalid": true}
			if not map_pack_found:
				map_info["map_pack"] = {"invalid": true}
			map_info.erase("das")
		
		var maps: Array = []
		# Create list of available maps
		for map_info: Dictionary in map_infos:
			if map_info in maps.map(func (m: Map) -> Dictionary: return m.map_info):
				pass
			else:
				var map: Map = Map.new(map_info)
				maps.append(map)
				
				# Assign newly created map object to the map's cooresponding map pack
				for map_pack: Dictionary in map_packs:
					if "maps" not in map_pack:
						map_pack["maps"] = []
					for map_pack_map_info: Dictionary in map_pack.map_infos:
						if map_pack_map_info == map.map_info:
							map_pack.maps.append(map)
		
		# Cleanup map_packs
		for map_pack: Dictionary in map_packs:
			map_pack.erase("map_infos")
		
		
		# Create unassigned map pack
		# Gather sub packs
		var unassigned_dbase: Dictionary = dbase_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
		var unassigned_dbase_name: String = options.get("unassigned_dbase", "Original")
		for dbase_pack: Dictionary in dbase_packs:
			if dbase_pack.name == unassigned_dbase_name:
				unassigned_dbase = dbase_pack
		var unassigned_sfx: Dictionary = sfx_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
		var unassigned_sfx_name: String = options.get("unassigned_sfx", "Original")
		for sfx_pack: Dictionary in sfx_packs:
			if sfx_pack.name == unassigned_sfx_name:
				unassigned_sfx = sfx_pack
		var unassigned_das2: Dictionary = das2_packs.filter(func (a:Dictionary) -> bool: return true if "vanilla" in a else false)[0]
		var unassigned_das2_name: String = options.get("unassigned_das2", "Original")
		for das2_pack: Dictionary in das2_packs:
			if das2_pack.name == unassigned_das2_name:
				unassigned_das2 = das2_pack
		
		var unassigned_map_pack: Dictionary = {
			"name": "Unassigned",
			"maps": [],
			"unassigned": true,
			"dbase_info": unassigned_dbase,
			"das2_info": unassigned_das2,
			"sfx_info": unassigned_sfx,
			"backdrop": "Original",
			"icons": "Original",
		}
		for map: Map in maps:
			if "invalid" in map.map_info.map_pack:
				unassigned_map_pack.maps.append(map)
				map.map_info.map_pack = unassigned_map_pack
		map_packs.append(unassigned_map_pack)
		
		
		# Load texture presets
		if Settings.settings.get("texture_presets", {}).is_empty():
			Settings.update_settings("texture_presets", DEFAULT_TEXTURE_PRESETS.duplicate(true))
	
	settings_loaded.emit()

#endregion

#region Map Functions

func load_maps(maps_array: Array) -> void:
	var start_time: int = Time.get_ticks_msec()
	var unique_map_packs: Array = []
	for map: Map in maps_array:
		if map.map_info.map_pack not in unique_map_packs:
			unique_map_packs.append(map.map_info.map_pack)
	for map_pack: Dictionary in unique_map_packs:
		get_index_from_das(0, map_pack.das2_info, 293)
	for map: Map in maps_array:
		var loaded_map: Map = map.create_editable_map()
		loaded_map.load_map()
		map_loading_started.emit(map.map_info.name)
		await loaded_map.load_das()
		#loaded_maps.append(loaded_map)
		map_loading_finished.emit(loaded_map)
	map_loading_completely_finished.emit()
	print("Maps loaded in: %.2fs" % ((Time.get_ticks_msec()-start_time)/1000.0))


func test_run_maps(map_pack: Dictionary, starting_map: Map = null, player_data: Dictionary = {}) -> void:
	# Check for required settings
	if not FileAccess.file_exists(Settings.settings.locations.get("roth.res")):
		Console.print("Roth.res not selected.")
		return
	if not FileAccess.file_exists(Settings.settings.locations.get("dosbox")):
		Console.print("Dosbox executable not selected.")
		return
	
	# Create custom install directory
	var roth_directory: String = ROTH_CUSTOM_INSTALL_DIRECTORY
	var success: bool = create_install(install_directory.path_join(".."), roth_directory)
	if not success:
		return
	
	# Delete and recreate temporary run directory
	Utility.remove_dir_recursive(ROTH_TEMP_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(ROTH_TEMP_DIRECTORY)
	
	# Save the maps into temporary directory
	for i in range(len(map_pack.maps)):
		var map: Map = map_pack.maps[i]
		if map.editable_map:
			map.editable_map.save_map(ROTH_TEMP_DIRECTORY, player_data if map.editable_map == starting_map else {})
		else:
			if Settings.settings.get("options", {}).get("always_recompile_maps", false):
				var tmp_map: Map = map.create_editable_map(true)
				tmp_map.load_map()
				tmp_map.save_map(ROTH_TEMP_DIRECTORY, player_data if map == starting_map else {})
				tmp_map.unload()
			else:
				DirAccess.copy_absolute(map.map_info.filepath, ROTH_TEMP_DIRECTORY.path_join(map.map_info.name+".RAW"))
	
	
	# Copy sfx file into temporary directory
	DirAccess.copy_absolute(map_pack.sfx_info.filepath, ROTH_TEMP_DIRECTORY.path_join("FXSCRIPT.SFX"))
	
	
	# Copy das2 into temporary directory
	DirAccess.copy_absolute(map_pack.das2_info.filepath, ROTH_TEMP_DIRECTORY.path_join(map_pack.das2_info.name+".DAS"))
	
	
	# Create the .res file in the temporary directory with the specified maps
	var roth_res_test_filepath := ROTH_TEMP_DIRECTORY.path_join("test.res")
	var roth_res_test := """version="Roth Custom Maps"
snd=%s
das2=%s

maps {
""" % ["D:\\fxscript", "D:\\"+map_pack.das2_info.name]
	if starting_map:
		roth_res_test += "D:\\%s D:\\%s\n" % [starting_map.map_info.name.get_file().get_basename(), starting_map.map_info.das_info.name.replace("/", "\\").get_basename()]
	for map: Map in map_pack.maps:
		if map != starting_map:
			roth_res_test += "D:\\%s D:\\%s\n" % [map.map_info.name.get_file().get_basename(), map.map_info.das_info.name.replace("/", "\\").get_basename()]
	roth_res_test += "}\n"
	
	# Write the .res file
	var roth_res_test_file := FileAccess.open(roth_res_test_filepath, FileAccess.WRITE)
	roth_res_test_file.store_string(roth_res_test)
	roth_res_test_file.close()
	
	
	# Copy map das files into temporary directory
	for map: Map in map_pack.maps:
		var dest_filepath: String = ROTH_TEMP_DIRECTORY.path_join(map.map_info.das_info.name+".DAS")
		DirAccess.copy_absolute(map.map_info.das_info.filepath, dest_filepath)
	
	
	# Copy dbase into custom install directory
	for filepath: String in [map_pack.dbase_info.dbase100_filepath, map_pack.dbase_info.dbase200_filepath, map_pack.dbase_info.dbase300_filepath, map_pack.dbase_info.dbase400_filepath, map_pack.dbase_info.dbase500_filepath]:
		var dest_filepath: String = ROTH_CUSTOM_INSTALL_DIRECTORY.path_join(filepath.get_file())
		DirAccess.copy_absolute(filepath, dest_filepath)
	
	
	# Create the dosbox auto exec .conf file
	var dosbox_autoexec_filepath := OS.get_user_data_dir().path_join("dosbox_roth_auto.conf")
	var autoexec := FileAccess.open(dosbox_autoexec_filepath, FileAccess.WRITE)
	autoexec.store_string("[autoexec]\n")
	autoexec.store_string("mount d \"%s\"\n" % ROTH_TEMP_DIRECTORY)
	autoexec.store_string("mount c \"%s\"\n" % roth_directory)
	autoexec.store_string("mount g \"%s\n" % install_directory.path_join("../DATA/GDV"))
	autoexec.store_string("c:\n")
	autoexec.store_string("cd \\roth\n")
	# Only the older version allows command line arguments
	if res.exe_version == OLD_EXE:
		# Increase starting gamma
		autoexec.store_string("ROTH.EXE /G 03 @D:\\test.res\n")
	else:
		# Newer version should save gamma anyway
		autoexec.store_string("ROTH.EXE @D:\\test.res\n")
	autoexec.store_string("exit\n")
	autoexec.close()
	
	# Assemble the dosbox command line arguments
	var dosbox_args := []
	if Settings.settings.locations.get("dosbox_config") and FileAccess.file_exists(Settings.settings.locations.get("dosbox_config")):
		dosbox_args.append_array([
			"-conf",
			Settings.settings.locations.get("dosbox_config")
		])
	dosbox_args.append_array([
		"-conf",
		dosbox_autoexec_filepath
	])
	
	# Run dosbox
	var dosbox_bin: String = Settings.settings.locations.get("dosbox")
	#Console.print("Executing: %s" % dosbox_bin)
	#Console.print(dosbox_args)
	OS.execute(dosbox_bin, dosbox_args)


## Checks given map name for validity
func check_map_name(title: String, map_pack: Dictionary) -> String:
	var error := ""
	if len(title) > 8:
		error = "Please limit to 8 characters"
	if title.find(" ") > 0:
		error = "No spaces"
	if title.to_upper() in map_pack.maps.map(func (m: Map) -> String: return m.map_info.name):
		error = "Name in use"
	if len(title) == 0:
		error = "Name is empty"
	return error

#endregion

#region Rotation Functions

## Converts from player game rotation to degrees
func player_rotation_to_degrees(rotation: float) -> int:
	return int(-180 + (90 * (rotation / 128)))


## Converts from player degrees to game rotation
func player_degrees_to_rotation(degrees: float) -> int:
	return int(((degrees + 180) * 128) / 90)


## Converts from object game rotation to degrees
func object_rotation_to_degrees(rotation: int) -> int:
	return int(((rotation / 256.0) * 360) - 90)


## Converts from relative rotation degrees to relative game object rotation
func object_relative_degrees_to_rotation(degrees: float) -> int:
	return int((256.0/360) * (degrees))

#endregion

#region Audio Functions

## Plays audio by passing an array of Vector2 and a sample rate
func play_audio_buffer(buffer: PackedVector2Array, sample_rate: int) -> void:
	audio_player.play_buffer(buffer, sample_rate)


func append_audio_buffer(buffer: PackedVector2Array, sample_rate: int) -> void:
	audio_player.append_buffer(buffer, sample_rate)


## Plays audio by passing an entry returned from FXScript.get_from_entry
func play_audio_entry(entry: Dictionary) -> void:
	audio_player.play_entry(entry)


## Stops audio
func stop_audio_buffer() -> void:
	audio_player.stop_buffer()

#endregion

#region Install

func create_install(installation_directory: String, roth_directory: String) -> bool:
	if FileAccess.file_exists(roth_directory.path_join("DBASE100.DAT")):
		DirAccess.remove_absolute(roth_directory.path_join("DBASE100.DAT"))
	if FileAccess.file_exists(roth_directory.path_join("DBASE200.DAT")):
		DirAccess.remove_absolute(roth_directory.path_join("DBASE200.DAT"))
	if FileAccess.file_exists(roth_directory.path_join("DBASE300.DAT")):
		DirAccess.remove_absolute(roth_directory.path_join("DBASE300.DAT"))
	if FileAccess.file_exists(roth_directory.path_join("DBASE400.DAT")):
		DirAccess.remove_absolute(roth_directory.path_join("DBASE400.DAT"))
	if FileAccess.file_exists(roth_directory.path_join("DBASE500.DAT")):
		DirAccess.remove_absolute(roth_directory.path_join("DBASE500.DAT"))
	
	if DirAccess.dir_exists_absolute(roth_directory):
		if (FileAccess.file_exists(roth_directory.path_join("ROTH.EXE"))
			and FileAccess.file_exists(roth_directory.path_join("CONFIG.INI"))
			and FileAccess.file_exists(roth_directory.path_join("ROTH.INI"))
			and FileAccess.file_exists(roth_directory.path_join("DOS4GW.EXE"))
			and FileAccess.file_exists(roth_directory.path_join("DATA/FILELIST.TXT"))
			and FileAccess.file_exists(roth_directory.path_join("DATA/BACKDROP.RAW"))
			and FileAccess.file_exists(roth_directory.path_join("DATA/ICONS.ALL"))
			and FileAccess.file_exists(roth_directory.path_join("DIGI/HMIDET.386"))
			and FileAccess.file_exists(roth_directory.path_join("DIGI/HMIDRV.386"))
			and FileAccess.file_exists(roth_directory.path_join("MIDI/HMIMDRV.386"))
			and FileAccess.file_exists(roth_directory.path_join("MIDI/DRUM.BNK"))
			and FileAccess.file_exists(roth_directory.path_join("MIDI/MELODIC.BNK"))
		):
			return true
		else:
			Utility.remove_dir_recursive(roth_directory)
	
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("DATA"))
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("DIGI"))
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("MIDI"))
	
	
	# ROTH.EXE
	if FileAccess.file_exists(installation_directory.path_join("DATA/ROTH.EXE")):
		DirAccess.copy_absolute(installation_directory.path_join("DATA/ROTH.EXE"), roth_directory.path_join("ROTH.EXE"))
	elif FileAccess.file_exists(installation_directory.path_join("DATA/INSTALL/ROTH.EXE")):
		DirAccess.copy_absolute(installation_directory.path_join("DATA/INSTALL/ROTH.EXE"), roth_directory.path_join("ROTH.EXE"))
	elif FileAccess.file_exists(installation_directory.path_join("ROTH/ROTH.EXE")):
		DirAccess.copy_absolute(installation_directory.path_join("ROTH/ROTH.EXE"), roth_directory.path_join("ROTH.EXE"))
	else:
		Dialog.information("Couldn't find required file", "Invalid installation", false, Vector2(350, 150), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		return false
	
	var seek_value: int = 0
	var md5_sum: String = FileAccess.get_md5(roth_directory.path_join("ROTH.EXE"))
	if (md5_sum == "f0f93c7931b9a678469095d3d7f54c04" or 
			md5_sum == "c11ab446c6d92e4e89d557864aa62997"):
		seek_value = 145767
		ROTHPatch._patch_file(roth_directory.path_join("ROTH.EXE"), ROTHPatch.DEV_MODE_PATCH)
	elif (md5_sum == "d56e7641e8f5d4ec3144bb1c140a7677" or 
			md5_sum == "f588469eb868373a339bebb5fba5a9bb"):
		seek_value = 147338
	else:
		print(md5_sum)
		Dialog.information("ROTH.EXE has invalid checksum: %s" % md5_sum, "Invalid installation", false, Vector2(350, 150), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		return false
	
	# Patch the EXE to read the GDV files from G:\
	var roth_exe_file := FileAccess.open(roth_directory.path_join("ROTH.EXE"), FileAccess.READ_WRITE)
	roth_exe_file.seek(seek_value)
	roth_exe_file.store_8(0x47)
	roth_exe_file.store_8(0x3A)
	roth_exe_file.store_8(0x5C)
	roth_exe_file.store_8(0x00)
	roth_exe_file.close()
	
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DOS4GW.EXE"), roth_directory.path_join("DOS4GW.EXE"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/ICONS.ALL"), roth_directory.path_join("DATA/ICONS.ALL"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/BACKDROP.RAW"), roth_directory.path_join("DATA/BACKDROP.RAW"))
	
	var filelist_file := FileAccess.open(roth_directory.path_join("DATA/FILELIST.TXT"), FileAccess.WRITE)
	filelist_file.close()
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DIGI/HMIDET.386"), roth_directory.path_join("DIGI/HMIDET.386"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DIGI/HMIDRV.386"), roth_directory.path_join("DIGI/HMIDRV.386"))
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/DRUM.BNK"), roth_directory.path_join("MIDI/DRUM.BNK"))
	#DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/GRAVIS.INI"), roth_directory.path_join("MIDI/GRAVIS.INI"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/HMIMDRV.386"), roth_directory.path_join("MIDI/HMIMDRV.386"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/MELODIC.BNK"), roth_directory.path_join("MIDI/MELODIC.BNK"))
	#DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/MT32MAP.MTX"), roth_directory.path_join("MIDI/MT32MAP.MTX"))
	
	
	write_config_ini(roth_directory.path_join("CONFIG.INI"), false)
	
	var roth_ini_file := FileAccess.open(roth_directory.path_join("ROTH.INI"), FileAccess.WRITE)
	roth_ini_file.store_string("SpeechSub=ON\n")
	roth_ini_file.store_string("SpeechAud=ON\n")
	roth_ini_file.store_string("MovieSub=ON\n")
	roth_ini_file.store_string("MovieAud=ON\n")
	roth_ini_file.store_string("VideoMode=8\n")
	roth_ini_file.store_string("ViewSize=0\n")
	roth_ini_file.store_string("SoundFXVol=0x100\n")
	roth_ini_file.store_string("SpeechVol=0xd0\n")
	roth_ini_file.store_string("MovieVol=0x100\n")
	roth_ini_file.store_string("MusicVol=0x100\n")
	roth_ini_file.store_string("MouseSpeed=0x40\n")
	roth_ini_file.close()
	
	return true


func write_config_ini(config_ini_filepath: String, original_game: bool) -> void:
	if not DirAccess.dir_exists_absolute(config_ini_filepath.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_ini_filepath.get_base_dir())
	var config_ini_file := FileAccess.open(config_ini_filepath, FileAccess.WRITE)
	if original_game:
		config_ini_file.store_string("SourcePath=C:\\DATA\n")
		config_ini_file.store_string("DestinationPath=C:\\ROTH\n")
	config_ini_file.store_string("SoundCard=0xe018\n")
	config_ini_file.store_string("SoundPort=0x220\n")
	config_ini_file.store_string("SoundIRQ=7\n")
	config_ini_file.store_string("SoundDMA=5\n")
	config_ini_file.store_string("MusicCard=0xa009\n")
	config_ini_file.store_string("MusicPort=0x388\n")
	config_ini_file.close()

#endregion

#region DBASE Packs

func check_dbase_pack_name(p_name: String) -> String:
	var error := ""
	if p_name.to_lower() in dbase_packs.map(func (d: Dictionary) -> String: return d.name.to_lower()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


func duplicate_dbase_pack(p_dbase_info: Dictionary, new_name: String) -> void:
	var dbase_info := p_dbase_info.duplicate()
	dbase_info.name = new_name
	dbase_info.erase("vanilla")
	var copy_dir: String = ""
	var new_dir: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(new_name)
	dbase_info["directory"] = new_dir
	dbase_info["dbase100_filepath"] = new_dir.path_join("DBASE100.DAT")
	dbase_info["dbase200_filepath"] = new_dir.path_join("DBASE200.DAT")
	dbase_info["dbase300_filepath"] = new_dir.path_join("DBASE300.DAT")
	dbase_info["dbase400_filepath"] = new_dir.path_join("DBASE400.DAT")
	dbase_info["dbase500_filepath"] = new_dir.path_join("DBASE500.DAT")
	DirAccess.make_dir_recursive_absolute(new_dir)
	if "vanilla" in p_dbase_info:
		copy_dir = install_directory.path_join("../DATA")
	else:
		copy_dir = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name)
	for i in range(100, 600, 100):
		if FileAccess.file_exists(copy_dir.path_join("DBASE%d.DAT" % i)):
			DirAccess.copy_absolute(
				copy_dir.path_join("DBASE%d.DAT" % i),
				new_dir.path_join("DBASE%d.DAT" % i)
			)
	
	dbase_packs.append(dbase_info)
	settings_loaded.emit()


func rename_dbase_pack(p_dbase_info: Dictionary, new_name: String) -> void:
	DirAccess.rename_absolute(
		ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name),
		ROTH_CUSTOM_DBASE_DIRECTORY.path_join(new_name)
	)
	p_dbase_info.name = new_name
	settings_loaded.emit()


func delete_dbase_pack(p_dbase_info: Dictionary) -> void:
	if DirAccess.dir_exists_absolute(ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name)):
		Utility.remove_dir_recursive(ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name))
	dbase_packs.erase(p_dbase_info)
	settings_loaded.emit()


func import_dbase_pack(p_dbase_name: String) -> void:
	var dbase_info := {
		"name": p_dbase_name,
	}
	var dbase_dir: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
	var dbase_100_filename := dbase_dir.path_join("DBASE100.DAT")
	var dbase_100 := FileAccess.open(dbase_100_filename, FileAccess.READ)
	dbase_info.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
	dbase_info.erase("signature")
	dbase_info.erase("unk_dword_02")
	dbase_info.erase("unk_dword_11")
	dbase_100.close()
	
	dbase_packs.append(dbase_info)


func create_dbase_pack(p_dbase_name: String) -> void:
	var dbase := {
		"actions": [],
		"cutscenes": [],
		"header": {
			"unk_dword_02": 433,
			"unk_dword_11": 2
		},
		"interfaces": [
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Subtitle\'s ON." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Subtitle\'s OFF." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Run mode ON." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Run mode OFF." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "I cannot use that." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Out of power." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "No ammo." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mouse Buttons A-B." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mouse Buttons B-A." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "New game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Options" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Quit Game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK SAVE!" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK LOAD!" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Load a game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Save a game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Restore last save game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "CANCEL" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Volume settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Subtitle settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "DONE" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Saving ..." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Loading ..." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Master volume" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Sound effects" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Music" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movies" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech subtitles on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech subtitles off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech Audio on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Speech Audio off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie subtitles on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie subtitles off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie audio on" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie audio off" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Input name" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Select file to load" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Select file to save" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK to replace" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Using %s with %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "I cannot use %s with %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "I cannot use %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Quit to DOS" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Screen settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Using %s." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mouse Speed" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Input Settings" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Not available" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Empty slot" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "No name" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Scanning VESA, please wait..." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "OK to start a new game." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Reload game to take effect." } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VGA 320x200" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mode-X 320x200" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Mode-X 320x400" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 320x200" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 320x400" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 640x400" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "VESA 640x480" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Options menu" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert Original ROTH Boot-CD" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Continue" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'Boot-CD\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'CD - two\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'CD - three\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Insert ROTH \'CD - four\'" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Read error found" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Retry" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Abort video" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Movie clips" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Playback menu" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Screen size" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Play the game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Replay Intro" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Cancel, and don\'t ask again" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Intro" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Making of" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Credits" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "--RotH--^^keys:-^^F1 - Show/Hide weapon^^F2 - Subtitles On/Off^^F5 - Switch Mouse buttons^^F6 - Cycle through screen modes^^CapsLock - RunMode On/Off^^i - Inventory On/Off^^c,v - Adjust gamma^^1-6 - Select weapons^^F10/F9 - Load/Save game 0" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Quit Realms" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Select difficulty level" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Easy" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Normal" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Hard" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Define movment keys" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk forward" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Turn left" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Turn right" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk backward" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk left" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Walk right" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Fire" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Key already used by the game" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Press new key" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Very hard" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VGA 320x200>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<Mode-X 320x200>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<Mode-X 320x400>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 320x200>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 320x400>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 640x400>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "<VESA 640x480>" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Jump" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Crawl" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Gamma" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Gamma setting" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Arcade level" } },
			{ "text_entry": { "dbase500_offset": 0, "font_color": 103, "string": "Adventure level" } },
		],
		"inventory": [],
		"subtitle_entrys": [],
	}

	var directory: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_name)
	DirAccess.make_dir_recursive_absolute(directory)
	
	var dbase100_filepath := directory.path_join("DBASE100.DAT")
	var dbase400_filepath := directory.path_join("DBASE400.DAT")
	var dbase500_filepath := directory.path_join("DBASE500.DAT")
	
	var data3: = DBase500.compile(dbase)
	var file3 := FileAccess.open(dbase500_filepath, FileAccess.WRITE)
	file3.store_buffer(data3)
	file3.close()
	
	var data := DBase400.compile(dbase)
	var file := FileAccess.open(dbase400_filepath, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	
	var data2 := DBase100.compile(dbase)
	var file2 := FileAccess.open(dbase100_filepath, FileAccess.WRITE)
	file2.store_buffer(data2)
	file2.close()
	
	var dbase_info := {
		"name": p_dbase_name,
		"inventory_count": len(dbase.inventory),
		"action_count": len(dbase.actions),
		"cutscene_count": len(dbase.cutscenes),
		"interface_count": len(dbase.interfaces),
		"filesize": len(data2),
	}
	dbase_packs.append(dbase_info)
	settings_loaded.emit()

#endregion

#region SFX Packs

func check_sfx_pack_name(p_name: String) -> String:
	var error := ""
	if p_name.to_lower() in sfx_packs.map(func (d: Dictionary) -> String: return d.name.to_lower()):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


func duplicate_sfx_pack(p_sfx_info: Dictionary, new_name: String) -> void:
	var sfx_info := p_sfx_info.duplicate()
	sfx_info.name = new_name
	sfx_info.erase("vanilla")
	sfx_info.filepath = ROTH_CUSTOM_SFX_DIRECTORY.path_join(new_name)+"/FXSCRIPT.SFX"
	var copy_dir: String = ""
	var new_dir: String = ROTH_CUSTOM_SFX_DIRECTORY.path_join(new_name)
	DirAccess.make_dir_recursive_absolute(new_dir)
	if "vanilla" in p_sfx_info:
		copy_dir = install_directory.path_join("../DATA")
		DirAccess.copy_absolute(
			copy_dir.path_join("DATA/FX22.SFX"),
			new_dir.path_join("FXSCRIPT.SFX")
		)
	else:
		copy_dir = ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name)
		DirAccess.copy_absolute(
			copy_dir.path_join("FXSCRIPT.SFX"),
			new_dir.path_join("FXSCRIPT.SFX")
		)
	
	sfx_packs.append(sfx_info)
	settings_loaded.emit()


func rename_sfx_pack(p_sfx_info: Dictionary, new_name: String) -> void:
	DirAccess.rename_absolute(
		ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name),
		ROTH_CUSTOM_SFX_DIRECTORY.path_join(new_name)
	)
	p_sfx_info.name = new_name
	p_sfx_info.filepath = ROTH_CUSTOM_SFX_DIRECTORY.path_join(new_name)+"/FXSCRIPT.SFX"
	settings_loaded.emit()


func delete_sfx_pack(p_sfx_info: Dictionary) -> void:
	if DirAccess.dir_exists_absolute(ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name)):
		Utility.remove_dir_recursive(ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_info.name))
	sfx_packs.erase(p_sfx_info)
	settings_loaded.emit()


func import_sfx_pack(p_sfx_name: String) -> void:
	var sfx_info := {
		"name": p_sfx_name,
	}
	var sfx_dir: String = ROTH_CUSTOM_SFX_DIRECTORY.path_join(sfx_info.name)
	var fxscript_filename := sfx_dir.path_join("FXSCRIPT.SFX")
	sfx_info.merge(FXScript.get_info(fxscript_filename))
	
	sfx_packs.append(sfx_info)


func create_sfx_pack(p_sfx_name: String) -> void:
	var fxscript := {
		"entries": []
	}
	
	var directory: String = ROTH_CUSTOM_SFX_DIRECTORY.path_join(p_sfx_name)
	DirAccess.make_dir_recursive_absolute(directory)
	var fxscript_filepath := directory.path_join("FXSCRIPT.SFX")
	
	var data := FXScript.compile(fxscript)
	var file := FileAccess.open(fxscript_filepath, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	
	var sfx_info := {
		"name": p_sfx_name,
		"count": 0,
		"filesize": len(data),
		"filepath": fxscript_filepath,
	}
	sfx_packs.append(sfx_info)
	settings_loaded.emit()

#endregion

#region DAS Functions

func _on_das_loading_updated(progress: float, das_info: Dictionary) -> void:
	map_loading_updated.emit(das_info, progress)


func get_das(das_info: Dictionary) -> Dictionary:
	if das_info in loaded_das and "textures" in loaded_das[das_info]:
		return loaded_das[das_info]
	elif das_info in loading_das:
		return await das_loading_finished
	else:
		loading_das[das_info] = true
		loaded_das[das_info] = await Das.load_das(das_info)
		loading_das.erase(das_info)
		return loaded_das[das_info]


## Directly get a single image from a das file by index
func get_index_from_das(index:int, das_info: Dictionary, p_range: int = 1) -> Dictionary:
	if das_info in loaded_das:
		if index not in loaded_das[das_info].mapping:
			var results: Array = Das.get_index_from_das(das_info, index, p_range)
			for i in range(p_range):
				loaded_das[das_info].mapping[results[i].index] = results[i]
	else:
		loaded_das[das_info] = {"mapping": {}}
		var results: Array = Das.get_index_from_das(das_info, index, p_range)
		for i in range(p_range):
			loaded_das[das_info].mapping[results[i].index] = results[i]
	return loaded_das[das_info].mapping[index]


func check_das_pack_name(p_name: String) -> String:
	var error := ""
	if (p_name.to_lower() in das_packs.map(func (d: Dictionary) -> String: return d.name.to_lower())
		or p_name.to_lower() in das2_packs.map(func (d: Dictionary) -> String: return d.name.to_lower())
	):
		error = "Name already in use."
	if not p_name.is_valid_filename():
		error = "Can't contain the following: : / \\ ? * \" | % < >"
	return error


func duplicate_das_pack(p_das_info: Dictionary, new_name: String) -> void:
	var das_info := p_das_info.duplicate()
	das_info.name = new_name.to_upper()
	das_info.erase("vanilla")
	das_info.filepath = ROTH_CUSTOM_DAS_DIRECTORY.path_join(new_name.to_upper()+".DAS")
	DirAccess.copy_absolute(p_das_info.filepath, das_info.filepath)
	das_packs.append(das_info)
	settings_loaded.emit()


func duplicate_das2_pack(p_das_info: Dictionary, new_name: String) -> void:
	var das_info := p_das_info.duplicate()
	das_info.name = new_name.to_upper()
	das_info.erase("vanilla")
	das_info.filepath = ROTH_CUSTOM_DAS2_DIRECTORY.path_join(new_name.to_upper()+".DAS")
	DirAccess.copy_absolute(p_das_info.filepath, das_info.filepath)
	das2_packs.append(das_info)
	settings_loaded.emit()


func delete_das_pack(p_das_info: Dictionary) -> void:
	if FileAccess.file_exists(p_das_info.filepath):
		DirAccess.remove_absolute(p_das_info.filepath)
	das_packs.erase(p_das_info)
	settings_loaded.emit()


func delete_das2_pack(p_das_info: Dictionary) -> void:
	if FileAccess.file_exists(p_das_info.filepath):
		DirAccess.remove_absolute(p_das_info.filepath)
	das2_packs.erase(p_das_info)
	settings_loaded.emit()


func get_das_info_by_name(p_das_name: String) -> Dictionary:
	for das_info: Dictionary in das_packs:
		if das_info.name == p_das_name:
			return das_info
	for das_info: Dictionary in das2_packs:
		if das_info.name == p_das_name:
			return das_info
	return {}


func get_vanilla_ademo() -> Dictionary:
	for das_info: Dictionary in das2_packs:
		if "vanilla" in das_info:
			return das_info
	return {}


func unload_das(das_info: Dictionary) -> void:
	loaded_das.erase(das_info)
#endregion

#region MapPacks
func save_map_pack(p_map_pack: Dictionary) -> void:
	if "vanilla" in p_map_pack:
		var options: Dictionary = {
			"vanilla_dbase": p_map_pack.dbase_info.name,
			"vanilla_das2": p_map_pack.das2_info.name,
			"vanilla_sfx": p_map_pack.sfx_info.name,
		}
		Settings.update_settings("options", options)
	elif "unassigned" in p_map_pack:
		var options: Dictionary = {
			"unassigned_dbase": p_map_pack.dbase_info.name,
			"unassigned_das2": p_map_pack.das2_info.name,
			"unassigned_sfx": p_map_pack.sfx_info.name,
		}
		Settings.update_settings("options", options)
	else:
		var save_data: Dictionary = {
			"name": p_map_pack.name,
			"dbase_name": p_map_pack.dbase_info.name,
			"das2_name": p_map_pack.das2_info.name,
			"sfx_name": p_map_pack.sfx_info.name,
			"backdrop": p_map_pack.backdrop,
			"icons": p_map_pack.icons,
			"map_uuids": []
		}
		for map: Map in p_map_pack.maps:
			save_data.map_uuids.append(map.map_info.uuid)
		
		if "filepath" not in p_map_pack:
			print("Saving new map mack %s" % p_map_pack.name.to_snake_case())
			p_map_pack["filepath"] = ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case()) + ".json"
		
		if p_map_pack not in map_packs:
			map_packs.insert(map_packs.size()-1, p_map_pack)
		
		if ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case())+".json" != p_map_pack.filepath:
			print("Renaming map pack %s to %s" % [p_map_pack.filepath.get_file().get_basename(), p_map_pack.name.to_snake_case()])
			if FileAccess.file_exists(p_map_pack.filepath):
				DirAccess.remove_absolute(p_map_pack.filepath)
			p_map_pack.filepath = ROTH_CUSTOM_MAP_PACKS_DIRECTORY.path_join(p_map_pack.name.to_snake_case()) + ".json"
		
		var file := FileAccess.open(p_map_pack.filepath, FileAccess.WRITE)
		file.store_string(JSON.stringify(save_data, '\t', false))
		file.close()


func move_map_to_map_pack(map: Map, map_pack: Dictionary) -> void:
	if map.map_info.map_pack == map_pack:
		return
	map.map_info.map_pack.maps.erase(map)
	save_map_pack(map.map_info.map_pack)
	map_pack.maps.append(map)
	save_map_pack(map_pack)
	map.map_info.map_pack = map_pack

func get_unassigned_map_pack() -> Dictionary:
	for map_pack: Dictionary in map_packs:
		if "unassigned" in map_pack:
			return map_pack
	return {}

## Checks given map pack name for validity
func check_map_pack_name(p_name: String) -> String:
	var error := ""
	if p_name.to_snake_case() in map_packs.map(func (p: Dictionary) -> String: return p.name.to_snake_case()):
		error = "Name in use"
	if len(p_name) == 0:
		error = "Name is empty"
	return error

func delete_map_pack(p_map_pack: Dictionary, p_delete_maps: bool) -> void:
	if p_delete_maps:
		for map: Map in p_map_pack.maps:
			map.delete_map(true)
	else:
		var unassigned_pack: Dictionary = get_unassigned_map_pack()
		for map: Map in p_map_pack.maps:
			if map not in unassigned_pack.maps:
				unassigned_pack.maps.append(map)
	map_packs.erase(p_map_pack)
	if FileAccess.file_exists(p_map_pack.filepath):
		DirAccess.remove_absolute(p_map_pack.filepath)
#endregion

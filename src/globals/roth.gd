extends Node

signal settings_loaded
signal map_loading_started(map_info: String)
signal map_loading_updated(status: String, progress: float)
signal map_loading_finished(map_info: Dictionary)
signal map_loading_completely_finished
@warning_ignore("unused_signal")
signal das_loading_started
signal das_loading_updated(progress: float, das_file: String)
signal das_loading_finished(das: Dictionary)
@warning_ignore("unused_signal")
signal gdv_loading_updated(progress: float)
@warning_ignore("unused_signal")
signal close_map(map_info: Dictionary)
@warning_ignore("unused_signal")
signal editor_action(p_map_info: Dictionary, p_name: String)

const SCALE_3D_WORLD: float = 100.0
const SCALE_2D_WORLD: float = 10.0
var ROTH_CUSTOM_MAP_DIRECTORY: String = OS.get_user_data_dir().path_join("maps")
var ROTH_CUSTOM_DBASE_DIRECTORY: String = OS.get_user_data_dir().path_join("dbase")
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

var res: Dictionary = {}
var maps: Array = []
var das_files: Array = []
var dbase_packs: Array = []
var install_directory: String = ""
var loaded_maps: Dictionary = {}
var loaded_das: Dictionary = {}
var loading_das: Dictionary = {}
var audio_player: RothAudioPlayer


## Initialization
func _ready() -> void:
	audio_player = RothAudioPlayer.new()
	add_child(audio_player)
	
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_MAP_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_MAP_DIRECTORY)
	if not DirAccess.dir_exists_absolute(ROTH_CUSTOM_DBASE_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(ROTH_CUSTOM_DBASE_DIRECTORY)
	
	#Settings.update_settings("locations", {"custom.res": ROTH_CUSTOM_MAP_DIRECTORY.path_join("custom.res")})
	
	das_loading_updated.connect(_on_das_loading_updated)
	Settings.settings_updated.connect(_on_settings_updated)
	
	migrate_away_from_custom_res()
	
	# Wait for the scene to be ready so other nodes have time to connect to this nodes settings_loaded signal
	await get_tree().get_root().ready
	load_roth_settings()


## Used to save old list of map name -> das files into separate .json files per map
func migrate_away_from_custom_res() -> void:
	var locations: Dictionary = Settings.settings.get("locations", {})
	if locations and "custom.res" in locations:
		Console.print("CUSTOM.RES found. Migrating to new format...")
		
		# Cycle through custom.res, saving in new format
		if FileAccess.file_exists(locations.get("custom.res")):
			var file := FileAccess.open(locations.get("custom.res"), FileAccess.READ)
			while file.get_position() < file.get_length():
				var line: String = file.get_line()
				var line_split: Array = line.split(" ")
				var map_info: Dictionary = {
					"name": line_split[0].get_file().get_basename().to_upper(),
					"das": (line_split[1]+".das").to_upper(),
				}
				save_metadata(map_info)
		
		# Remove old files
		if FileAccess.file_exists(locations["custom.res"]):
			DirAccess.remove_absolute(locations["custom.res"])
		if FileAccess.file_exists(ROTH_CUSTOM_MAP_DIRECTORY.path_join("test.res")):
			DirAccess.remove_absolute(ROTH_CUSTOM_MAP_DIRECTORY.path_join("test.res"))
		
		# Remove entry from settings file
		locations.erase("custom.res")
		Settings._save_settings()


func _on_das_loading_updated(progress: float, das_file: String) -> void:
	map_loading_updated.emit("Loading textures: %s" % das_file, progress)


func _on_settings_updated(key: String) -> void:
	if key == "locations":
		load_roth_settings()


## Loads roth.res location using Settings autoload. [br]
## Reads roth.res to get list of maps and associated das files.
func load_roth_settings() -> void:
	var locations: Variant = Settings.settings.get("locations")
	maps.clear()
	das_files.clear()
	if locations and locations.get("roth.res"):
		install_directory = locations.get("roth.res").get_base_dir()
		var file := FileAccess.open(locations.get("roth.res"), FileAccess.READ)
		# Parse the roth.res file
		while file.get_position() < file.get_length():
			var line: String = file.get_line().replace("\\", "/").replace("\"", "")
			if line.contains("="):
				var line_split: Array = line.split("=")
				if line_split[0] == "das2":
					line_split[1] += ".das"
					das_files.append(line_split[1].to_upper())
				res[line_split[0]] = line_split[1].to_upper()
				
			elif line.contains("maps"):
				continue
			elif line.contains("}"):
				continue
			elif line.contains(" "):
				var line_split: Array = line.split(" ")
				maps.append({
					"name": line_split[0].get_file().get_basename().to_upper(),
					"das": (line_split[1]+".das").to_upper(),
					"filepath": install_directory.path_join((line_split[0]+".raw").to_upper()),
					"vanilla": true,
				})
			elif not line.is_empty():
				res[line] = true
		file.close()
		
		for das: String in maps.map(func (map: Dictionary) -> String: return map.das ):
			if das not in das_files:
				das_files.append(das)
		
		das_files.sort()
		
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
		
		
		
		var options: Dictionary = Settings.settings.get("options", {})
		
		if options.is_empty():
			options = { "active_dbase": "Original"}
			Settings.update_settings("options", options)
		else:
			if "active_dbase" not in options:
				options.active_dbase = "Original"
				Settings.update_settings("options", options)
		
		dbase_packs = [
			{
				"name": "Original",
				"active": false,
				"vanilla": true,
			}
		]
		for dir in DirAccess.get_directories_at(ROTH_CUSTOM_DBASE_DIRECTORY):
			var dbase_info := { "name": dir, "active": false }
			dbase_packs.append(dbase_info)
		
		if options.active_dbase not in dbase_packs.map(func (a:Dictionary) -> String: return a.name):
			options.active_dbase = "Original"
			Settings.update_settings("options", options)
		
		for dbase_info: Dictionary in dbase_packs:
			if dbase_info.name == options.active_dbase:
				dbase_info.active = true
			
			var dbase_dir: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
			if "vanilla" in dbase_info:
				dbase_dir = Roth.install_directory.path_join("../DATA")
			var dbase_100_filename := dbase_dir.path_join("DBASE100.DAT")
			var dbase_100 := FileAccess.open(dbase_100_filename, FileAccess.READ)
			dbase_info.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
			dbase_info.erase("signature")
			dbase_info.erase("unk_dword_02")
			dbase_info.erase("unk_dword_11")
			dbase_100.close()
	
	
	
	for file in DirAccess.get_files_at(ROTH_CUSTOM_MAP_DIRECTORY):
		if file.to_lower().ends_with(".json"):
			var file_string: String = FileAccess.get_file_as_string(ROTH_CUSTOM_MAP_DIRECTORY.path_join(file))
			if not file_string.is_empty():
				var file_json: Variant = JSON.parse_string(file_string)
				if file_json:
					file_json["filepath"] = ROTH_CUSTOM_MAP_DIRECTORY.path_join(file).get_basename() + ".RAW"
					file_json["filepath_json"] = ROTH_CUSTOM_MAP_DIRECTORY.path_join(file)
					maps.append(file_json)
	
	

	
	#print(JSON.stringify(maps, "\t"))
	#print(JSON.stringify(dbase_packs, "\t"))
	
	settings_loaded.emit()


## Does an initial partial load of a map.
func get_map(map_info: Dictionary) -> Map:
	# Check if map is already loaded
	if map_info.name in loaded_maps:
		return loaded_maps[map_info.name]
	
	var map := Map.load_from_file(map_info)
	loaded_maps[map_info.name] = map
	return map


## Loads an array of maps textures using the das file then signals viewer window
func load_maps(maps_array: Array) -> void:
	for map_info: Dictionary in maps_array:
		map_loading_started.emit(map_info.name)
		await get_das(map_info.das)
		map_loading_finished.emit(map_info)
	map_loading_completely_finished.emit()


## Deletes maps from the filesystem and removes them from the list of available maps
func delete_maps(maps_array: Array) -> void:
	for map_info: Dictionary in maps_array:
		if FileAccess.file_exists(map_info.filepath):
			DirAccess.remove_absolute(map_info.filepath)
		if FileAccess.file_exists(map_info.filepath_json):
			DirAccess.remove_absolute(map_info.filepath_json)
		maps.erase(map_info)
#	update_custom_maps_list()
	settings_loaded.emit()


## Renames a map by saving it with a new name and erasing the old version
func rename_map(map_info: Dictionary, new_map_name: String) -> void:
	Console.print("Renaming map from %s to %s" % [map_info.name, new_map_name])
	var old_map_info: Dictionary = map_info.duplicate()
	
	var map: Map = get_map(map_info)
	map.map_info.filepath = map.map_info.filepath.replace(map_info.name, new_map_name)
	map.map_info.name = new_map_name
	
	save_map(map)
	
	if FileAccess.file_exists(map.map_info.filepath) and map.map_info.filepath != old_map_info.filepath:
		if FileAccess.file_exists(old_map_info.filepath):
			DirAccess.remove_absolute(old_map_info.filepath)
		if FileAccess.file_exists(old_map_info.filepath_json):
			DirAccess.remove_absolute(old_map_info.filepath_json)


## Creates a new map
func create_new_map(map_info: Dictionary) -> void:
	var map := Map.new()
	map.map_info = map_info
	save_map(map)
	Roth.settings_loaded.emit()
	loaded_maps[map_info.name] = map
	#load_maps([map_info])


## Return or load the requested das_file. [br]
## Das files stay loaded after initial load.
func get_das(das_file: String) -> Dictionary:
	if das_file in loaded_das:
		return loaded_das[das_file]
	elif das_file in loading_das:
		return await das_loading_finished
	else:
		loading_das[das_file] = true
		loaded_das[das_file] = await Das.load_das(das_file)
		loading_das.erase(das_file)
		return loaded_das[das_file]


## Directly get a single image from a das file by index
func get_index_from_das(index:int, das_file: String) -> Dictionary:
	if das_file in loaded_das:
		if index in loaded_das[das_file]:
			return loaded_das[das_file][index]
	return Das._get_index_from_das(index, das_file)


## Takes a map and saves it to raw format, optionally overriding directory and player starting data
func save_map(map: Map, directory: String = ROTH_CUSTOM_MAP_DIRECTORY, player_data: Dictionary = {}) -> void:
	var raw_map := map.compile(player_data)
	save_raw(map.map_info, raw_map, directory)


func save_raw(map_info: Dictionary, raw_map: PackedByteArray, directory: String = ROTH_CUSTOM_MAP_DIRECTORY) -> void:
	var raw_filepath := directory.path_join(map_info.name.to_upper() + ".RAW")
	
	if directory == ROTH_CUSTOM_MAP_DIRECTORY and FileAccess.file_exists(raw_filepath):
		var json_filepath: = directory.path_join(map_info.name.to_upper() + ".json")
		var count: int = 1
		while FileAccess.file_exists(raw_filepath + ".%d" % count):
			count += 1
		count -= 1
		for i in range(count, 0, -1):
			DirAccess.rename_absolute(raw_filepath + ".%d" % i, raw_filepath + ".%d" % (i+1))
			DirAccess.rename_absolute(json_filepath + ".%d" % i, json_filepath + ".%d" % (i+1))
		
		DirAccess.rename_absolute(raw_filepath, raw_filepath + ".1")
		DirAccess.rename_absolute(json_filepath, json_filepath + ".1")
		
		count += 1
		while count > Settings.settings.get("options", {}).get("backup_saves", 5):
			DirAccess.remove_absolute(raw_filepath + ".%d" % count)
			DirAccess.remove_absolute(json_filepath + ".%d" % count)
			count -= 1
			if count < 1:
				break
	
	var file := FileAccess.open(raw_filepath, FileAccess.WRITE)
	file.store_buffer(raw_map)
	file.close()
	if map_info not in maps:
		maps.append(map_info)
	
	if directory == ROTH_CUSTOM_MAP_DIRECTORY:
		save_metadata(map_info)


## Save a map's editor metadata in a json format next to the raw file
func save_metadata(map_info: Dictionary) -> void:
	var json_filepath: String
	if "filepath_json" in map_info:
		json_filepath = map_info.filepath_json
	else:
		json_filepath = ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.name.to_upper() + ".json")
		map_info["filepath_json"] = json_filepath
	if "filepath" not in map_info:
		map_info["filepath"] = ROTH_CUSTOM_MAP_DIRECTORY.path_join(map_info.name.to_upper() + ".RAW")
	
	var save_info: Dictionary = map_info.duplicate()
	save_info.erase("filepath")
	save_info.erase("filepath_json")
	
	var json_file := FileAccess.open(json_filepath, FileAccess.WRITE)
	json_file.store_string(JSON.stringify(save_info, "\t"))
	json_file.close()


## Takes an array of Maps and an optional player start location. [br]
## Saves the maps in a temporary directory, creates a .res file for the maps, and runs it
func test_run_maps(maps_to_run: Array, player_data: Dictionary = {}) -> void:
	# Check for required settings
	if not FileAccess.file_exists(Settings.settings.locations.get("roth.res")):
		Console.print("Roth.res not selected.")
		return
	if not FileAccess.file_exists(Settings.settings.locations.get("dosbox")):
		Console.print("Dosbox executable not selected.")
		return
	
	# Delete and create temporary run directory
	remove_dir_recursive(ROTH_TEMP_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(ROTH_TEMP_DIRECTORY)
	
	# Save the maps into temporary directory
	for i in range(len(maps_to_run)):
		save_map(maps_to_run[i], ROTH_TEMP_DIRECTORY, player_data if i == 0 else {})
	
	# Create the .res file in the temporary directory with the specified maps
	var roth_res_test_filepath := ROTH_TEMP_DIRECTORY.path_join("test.res")
	var roth_res_test := """version="Roth Custom Maps"
snd=data\\fxscript.sfx
das2=m\\ademo

maps {
"""
	for map: Map in maps_to_run:
		roth_res_test += "D:\\%s %s\n" % [map.map_info.name.get_file().get_basename(), map.map_info.das.replace("/", "\\").get_basename()]
	roth_res_test += "}\n"
	
	var roth_res_test_file := FileAccess.open(roth_res_test_filepath, FileAccess.WRITE)
	roth_res_test_file.store_string(roth_res_test)
	roth_res_test_file.close()
	
	
	# Create custom install directory if using non vanilla dbase
	var roth_directory: String
	var current_dbase: Dictionary
	for dbase_info: Dictionary in dbase_packs:
		if dbase_info.active:
			current_dbase = dbase_info
	if "vanilla" not in current_dbase:
		create_install(Roth.install_directory.path_join(".."), ROTH_CUSTOM_INSTALL_DIRECTORY)
		roth_directory = ROTH_CUSTOM_INSTALL_DIRECTORY
		for file: String in DirAccess.get_files_at(ROTH_CUSTOM_DBASE_DIRECTORY.path_join(current_dbase.name)):
			var filepath := ROTH_CUSTOM_DBASE_DIRECTORY.path_join(current_dbase.name).path_join(file)
			var dest_filepath := ROTH_CUSTOM_INSTALL_DIRECTORY.path_join(file)
			DirAccess.copy_absolute(filepath, dest_filepath)
	else:
		roth_directory = Settings.settings.locations.get("roth.res").get_base_dir().path_join("..")
	
	
	# Create the dosbox auto exec .conf file
	var dosbox_autoexec_filepath := OS.get_user_data_dir().path_join("dosbox_roth_auto.conf")
	var autoexec := FileAccess.open(dosbox_autoexec_filepath, FileAccess.WRITE)
	autoexec.store_string("[autoexec]\n")
	autoexec.store_string("mount d \"%s\"\n" % ROTH_TEMP_DIRECTORY)
	autoexec.store_string("mount c \"%s\"\n" % roth_directory)
	autoexec.store_string("mount g \"%s\n" % Roth.install_directory.path_join("..").path_join("DATA/GDV"))
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


## Plays audio by passing an array of Vector2 and a sample rate
func play_audio_buffer(buffer: PackedVector2Array, sample_rate: int) -> void:
	audio_player.play_buffer(buffer, sample_rate)


## Plays audio by passing an entry returned from FXScript.get_from_entry
func play_audio_entry(entry: Dictionary) -> void:
	audio_player.play_entry(entry)


## Stops audio
func stop_audio_buffer() -> void:
	audio_player.stop_buffer()


## Helper function removes a directory recursively
func remove_dir_recursive(directory: String) -> void:
	if DirAccess.dir_exists_absolute(directory):
		for dir in DirAccess.get_directories_at(directory):
			remove_dir_recursive(directory.path_join(dir))
		for file in DirAccess.get_files_at(directory):
			DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)


## Helper function to query the user for a valid name for a map
func query_for_map_name(title: String) -> String:
	var results: Array = [false, ""]
	var error: String = "Init"
	var i: int = 0
	while not error.is_empty():
		results = await Dialog.input("New Map Name:", title, results[1], error if i != 0 else "", false)
		i += 1
		if not results[0]:
			return ""
		error = check_map_name(results[1])
	
	return results[1].to_upper()


## Checks given map name for validity
func check_map_name(title: String) -> String:
	var error := ""
	if len(title) > 8:
		error = "Please limit to 8 characters"
	if title.find(" ") > 0:
		error = "No spaces"
	if title.to_upper() in Roth.maps.map(func (m: Dictionary) -> String: return m.name):
		error = "Name in use."
	if len(title) == 0:
		error = "Name is empty"
	return error


func reload_map_info(map_info: Dictionary) -> void:
	if "vanilla" in map_info:
		map_info.erase("command_positions")
	else:
		var file_string := FileAccess.get_file_as_string(map_info.filepath_json)
		if not file_string.is_empty():
			var file_json: Variant = JSON.parse_string(file_string)
			if file_json:
				file_json["filepath"] = map_info.filepath
				file_json["filepath_json"] = map_info.filepath_json
				for key: String in map_info:
					if key in file_json:
						map_info[key] = file_json[key]
					else:
						map_info.erase(key)


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
	dbase_info.active = false
	dbase_info.erase("vanilla")
	var copy_dir: String = ""
	var new_dir: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(new_name)
	DirAccess.make_dir_recursive_absolute(new_dir)
	if "vanilla" in p_dbase_info:
		copy_dir = Roth.install_directory.path_join("../DATA")
	else:
		copy_dir = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name)
	for i in range(100, 600, 100):
		if FileAccess.file_exists(copy_dir.path_join("DBASE%d.DAT" % i)):
			DirAccess.copy_absolute(
				copy_dir.path_join("DBASE%d.DAT" % i),
				new_dir.path_join("DBASE%d.DAT" % i)
			)
	dbase_packs.append(dbase_info)
	Roth.settings_loaded.emit()


func rename_dbase_pack(p_dbase_info: Dictionary, new_name: String) -> void:
	DirAccess.rename_absolute(
		ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name),
		ROTH_CUSTOM_DBASE_DIRECTORY.path_join(new_name)
	)
	p_dbase_info.name = new_name
	Roth.settings_loaded.emit()


func delete_dbase_pack(p_dbase_info: Dictionary) -> void:
	if DirAccess.dir_exists_absolute(ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name)):
		remove_dir_recursive(ROTH_CUSTOM_DBASE_DIRECTORY.path_join(p_dbase_info.name))
	dbase_packs.erase(p_dbase_info)
	if p_dbase_info.active:
		for dbase_info: Dictionary in dbase_packs:
			if dbase_info.name == "Original":
				dbase_info.active = true
				Settings.update_settings("options", {"active_dbase": "Original"})
	Roth.settings_loaded.emit()


func import_dbase_pack(p_dbase_name: String) -> void:
	var dbase_info := {
		"name": p_dbase_name,
		"active": false
	}
	var dbase_dir: String = ROTH_CUSTOM_DBASE_DIRECTORY.path_join(dbase_info.name)
	var dbase_100_filename := dbase_dir.path_join("DBASE100.DAT")
	var dbase_100 := FileAccess.open(dbase_100_filename, FileAccess.READ)
	dbase_info.merge(Parser.parse_section(dbase_100, DBase100.DBASE100_HEADER))
	dbase_info.erase("signature")
	dbase_info.erase("unk_dword_02")
	dbase_info.erase("unk_dword_11")
	dbase_100.close()
	
	Roth.dbase_packs.append(dbase_info)


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
		"active": false,
		"inventory_count": len(dbase.inventory),
		"action_count": len(dbase.actions),
		"cutscene_count": len(dbase.cutscenes),
		"interface_count": len(dbase.interfaces),
		"filesize": len(data2),
	}
	dbase_packs.append(dbase_info)
	Roth.settings_loaded.emit()


func create_install(installation_directory: String, roth_directory: String) -> void:
	if DirAccess.dir_exists_absolute(roth_directory):
		return
	#remove_dir_recursive(roth_directory)
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("DATA"))
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("DIGI"))
	#DirAccess.make_dir_recursive_absolute(roth_directory.path_join("GDV"))
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("M"))
	DirAccess.make_dir_recursive_absolute(roth_directory.path_join("MIDI"))
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DBASE100.DAT"), roth_directory.path_join("DBASE100.DAT"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DBASE200.DAT"), roth_directory.path_join("DBASE200.DAT"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DBASE300.DAT"), roth_directory.path_join("DBASE300.DAT"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DBASE400.DAT"), roth_directory.path_join("DBASE400.DAT"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DBASE500.DAT"), roth_directory.path_join("DBASE500.DAT"))
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DOS4GW.EXE"), roth_directory.path_join("DOS4GW.EXE"))
	if FileAccess.file_exists(installation_directory.path_join("DATA/ROTH.RES")):
		DirAccess.copy_absolute(installation_directory.path_join("DATA/ROTH.RES"), roth_directory.path_join("ROTH.RES"))
	elif FileAccess.file_exists(installation_directory.path_join("DATA/INSTALL/ROTH.RES")):
		DirAccess.copy_absolute(installation_directory.path_join("DATA/INSTALL/ROTH.RES"), roth_directory.path_join("ROTH.RES"))
	else:
		Dialog.information("Couldn't find required file", "Invalid installation", false, Vector2(350, 150), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	if FileAccess.file_exists(installation_directory.path_join("DATA/ROTH.EXE")):
		DirAccess.copy_absolute(installation_directory.path_join("DATA/ROTH.EXE"), roth_directory.path_join("ROTH.EXE"))
	elif FileAccess.file_exists(installation_directory.path_join("DATA/INSTALL/ROTH.EXE")):
		DirAccess.copy_absolute(installation_directory.path_join("DATA/INSTALL/ROTH.EXE"), roth_directory.path_join("ROTH.EXE"))
	else:
		Dialog.information("Couldn't find required file", "Invalid installation", false, Vector2(350, 150), "Close", HORIZONTAL_ALIGNMENT_CENTER)
		return
	
	var seek_value: int = 0
	if (FileAccess.get_md5(roth_directory.path_join("ROTH.EXE")) == "f0f93c7931b9a678469095d3d7f54c04" or 
			FileAccess.get_md5(roth_directory.path_join("ROTH.EXE")) == "c11ab446c6d92e4e89d557864aa62997"):
		seek_value = 145767
	elif (FileAccess.get_md5(roth_directory.path_join("ROTH.EXE")) == "d56e7641e8f5d4ec3144bb1c140a7677" or 
			FileAccess.get_md5(roth_directory.path_join("ROTH.EXE")) == "f588469eb868373a339bebb5fba5a9bb"):
		seek_value = 147338
	else:
		print(FileAccess.get_md5(roth_directory.path_join("ROTH.EXE")))
		return
	
	# Patch the EXE to read the GDV files from G:\
	var roth_exe_file := FileAccess.open(roth_directory.path_join("ROTH.EXE"), FileAccess.READ_WRITE)
	roth_exe_file.seek(seek_value)
	roth_exe_file.store_8(0x47)
	roth_exe_file.store_8(0x3A)
	roth_exe_file.store_8(0x5C)
	roth_exe_file.store_8(0x00)
	roth_exe_file.close()
	
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/ICONS.ALL"), roth_directory.path_join("DATA/ICONS.ALL"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/BACKDROP.RAW"), roth_directory.path_join("DATA/BACKDROP.RAW"))
	
	#DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/FILELIST.TXT"), roth_directory.path_join("DATA/FILELIST.TXT"))
	var filelist_file := FileAccess.open(roth_directory.path_join("DATA/FILELIST.TXT"), FileAccess.WRITE)
	filelist_file.close()
	
	#DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/FXSCRIPT.SFX"), roth_directory.path_join("DATA/FXSCRIPT.SFX"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DATA/FX22.SFX"), roth_directory.path_join("DATA/FXSCRIPT.SFX"))
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DIGI/HMIDET.386"), roth_directory.path_join("DIGI/HMIDET.386"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/DIGI/HMIDRV.386"), roth_directory.path_join("DIGI/HMIDRV.386"))
	
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/DRUM.BNK"), roth_directory.path_join("MIDI/DRUM.BNK"))
	#DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/GRAVIS.INI"), roth_directory.path_join("MIDI/GRAVIS.INI"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/HMIMDRV.386"), roth_directory.path_join("MIDI/HMIMDRV.386"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/MELODIC.BNK"), roth_directory.path_join("MIDI/MELODIC.BNK"))
	#DirAccess.copy_absolute(installation_directory.path_join("DATA/MIDI/MT32MAP.MTX"), roth_directory.path_join("MIDI/MT32MAP.MTX"))
	
	
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/ADEMO.DAS"), roth_directory.path_join("M/ADEMO.DAS"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DEMO.DAS"), roth_directory.path_join("M/DEMO.DAS"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DEMO1.DAS"), roth_directory.path_join("M/DEMO1.DAS"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DEMO2.DAS"), roth_directory.path_join("M/DEMO2.DAS"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DEMO3.DAS"), roth_directory.path_join("M/DEMO3.DAS"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DEMO4.DAS"), roth_directory.path_join("M/DEMO4.DAS"))
	
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/ABAGATE2.RAW"), roth_directory.path_join("M/ABAGATE2.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/AELF.RAW"), roth_directory.path_join("M/AELF.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/ANUBIS.RAW"), roth_directory.path_join("M/ANUBIS.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/AQUA1.RAW"), roth_directory.path_join("M/AQUA1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/AQUA2.RAW"), roth_directory.path_join("M/AQUA2.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/CAVERNS.RAW"), roth_directory.path_join("M/CAVERNS.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/CAVERNS2.RAW"), roth_directory.path_join("M/CAVERNS2.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/CAVERNS3.RAW"), roth_directory.path_join("M/CAVERNS3.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/CHURCH1.RAW"), roth_directory.path_join("M/CHURCH1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DOMINION.RAW"), roth_directory.path_join("M/DOMINION.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/DOPPLE.RAW"), roth_directory.path_join("M/DOPPLE.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/ELOHIM1.RAW"), roth_directory.path_join("M/ELOHIM1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/GNARL1.RAW"), roth_directory.path_join("M/GNARL1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/GRAVE.RAW"), roth_directory.path_join("M/GRAVE.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/LRINTH.RAW"), roth_directory.path_join("M/LRINTH.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/LRINTH1.RAW"), roth_directory.path_join("M/LRINTH1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAS3.RAW"), roth_directory.path_join("M/MAS3.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAS4.RAW"), roth_directory.path_join("M/MAS4.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAS6.RAW"), roth_directory.path_join("M/MAS6.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAS7.RAW"), roth_directory.path_join("M/MAS7.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAUSO1EA.RAW"), roth_directory.path_join("M/MAUSO1EA.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAUSO1EB.RAW"), roth_directory.path_join("M/MAUSO1EB.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/MAZE.RAW"), roth_directory.path_join("M/MAZE.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/OPTEMP1.RAW"), roth_directory.path_join("M/OPTEMP1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/RAQUIA1.RAW"), roth_directory.path_join("M/RAQUIA1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/RAQUIA2.RAW"), roth_directory.path_join("M/RAQUIA2.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/RAQUIA3.RAW"), roth_directory.path_join("M/RAQUIA3.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/RAQUIA4.RAW"), roth_directory.path_join("M/RAQUIA4.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/RAQUIA5.RAW"), roth_directory.path_join("M/RAQUIA5.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/SALVAT.RAW"), roth_directory.path_join("M/SALVAT.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/SOULST2.RAW"), roth_directory.path_join("M/SOULST2.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/SOULST3.RAW"), roth_directory.path_join("M/SOULST3.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/STUDY1.RAW"), roth_directory.path_join("M/STUDY1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/STUDY2.RAW"), roth_directory.path_join("M/STUDY2.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/STUDY3.RAW"), roth_directory.path_join("M/STUDY3.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/STUDY4.RAW"), roth_directory.path_join("M/STUDY4.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/TEMPLE1.RAW"), roth_directory.path_join("M/TEMPLE1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/TGATE1F.RAW"), roth_directory.path_join("M/TGATE1F.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/TGATE1G.RAW"), roth_directory.path_join("M/TGATE1G.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/TGATE1H.RAW"), roth_directory.path_join("M/TGATE1H.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/TGATE1I.RAW"), roth_directory.path_join("M/TGATE1I.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/TOWER1.RAW"), roth_directory.path_join("M/TOWER1.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/VICAR.RAW"), roth_directory.path_join("M/VICAR.RAW"))
	DirAccess.copy_absolute(installation_directory.path_join("DATA/M/VICAR1.RAW"), roth_directory.path_join("M/VICAR1.RAW"))
	
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

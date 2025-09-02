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

const SCALE_3D_WORLD: float = 100.0
const SCALE_2D_WORLD: float = 10.0
var ROTH_CUSTOM_MAP_DIRECTORY: String = OS.get_user_data_dir().path_join("maps")
var ROTH_TEMP_DIRECTORY: String = OS.get_user_data_dir().path_join("temp")

const OLD_EXE: float = 3.925
const NEW_EXE: float = 3.983

var res: Dictionary = {}
var maps: Array = []
var das_files: Array = []
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
	
	#Settings.update_settings("locations", {"custom.res": ROTH_CUSTOM_MAP_DIRECTORY.path_join("custom.res")})
	
	das_loading_updated.connect(_on_das_loading_updated)
	Settings.settings_updated.connect(_on_settings_updated)
	
	migrate_away_from_custom_res()
	
	# Wait for the scene to be ready so other nodes have time to connect to this nodes settings_loaded signal
	await get_tree().get_root().ready
	load_roth_settings()


## Used to save old list of map name -> das files into separate .json files per map
func migrate_away_from_custom_res() -> void:
	var locations: Dictionary = Settings.settings.get("locations")
	if locations and "custom.res" in locations:
		Console.print("CUSTOM.RES found. Migrating to new format...")
		
		# Cycle through custom.res, saving in new format
		if FileAccess.file_exists(locations.get("custom.res")):
			var file := FileAccess.open(locations.get("custom.res"), FileAccess.READ)
			while file.get_position() < file.get_length():
				var line: String = file.get_line()
				var line_split: Array = line.split(" ")
				var map: Map = get_map({
					"name": line_split[0].get_file().get_basename().to_upper(),
					"das": (line_split[1]+".das").to_upper(),
					"filepath": ROTH_CUSTOM_MAP_DIRECTORY.path_join((line_split[0]+".raw").to_upper())
				})
				save_custom_metadata(map)
		
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
	
	settings_loaded.emit()


## Does an initial partial load of a map. [br]
## Once loaded, maps are not unloaded.
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
	
	save_custom(map)
	
	if FileAccess.file_exists(map.map_info.filepath) and map.map_info.filepath != old_map_info.filepath:
		if FileAccess.file_exists(old_map_info.filepath):
			DirAccess.remove_absolute(old_map_info.filepath)
		if FileAccess.file_exists(old_map_info.filepath_json):
			DirAccess.remove_absolute(old_map_info.filepath_json)


## Creates a new map
func create_new_map(map_info: Dictionary) -> void:
	var map := Map.new()
	map.map_info = map_info
	save_custom(map)
	Roth.settings_loaded.emit()
	loaded_maps[map_info.name] = map
	load_maps([map_info])


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
func save_custom(map: Map, directory: String = ROTH_CUSTOM_MAP_DIRECTORY, player_data: Dictionary = {}) -> void:
	var raw_filepath := directory.path_join(map.map_info.name.to_upper() + ".RAW")
	var raw_map := map.compile(player_data)
	var file := FileAccess.open(raw_filepath, FileAccess.WRITE)
	file.store_buffer(raw_map)
	file.close()
	if map.map_info not in maps:
		maps.append(map.map_info)
	
	if directory == ROTH_CUSTOM_MAP_DIRECTORY:
		save_custom_metadata(map)


## Save a map's editor metadata in a json format next to the raw file
func save_custom_metadata(map: Map) -> void:
	var json_filepath: String
	if "filepath_json" in map.map_info:
		json_filepath = map.map_info.filepath_json
	else:
		json_filepath = ROTH_CUSTOM_MAP_DIRECTORY.path_join(map.map_info.name.to_upper() + ".json")
	
	var save_info: Dictionary = map.map_info.duplicate()
	save_info.erase("filepath")
	
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
		save_custom(maps_to_run[i], ROTH_TEMP_DIRECTORY, player_data if i == 0 else {})
	
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
	
	
	# Create the dosbox auto exec .conf file
	var dosbox_autoexec_filepath := OS.get_user_data_dir().path_join("dosbox_roth_auto.conf")
	var roth_directory: String = Settings.settings.locations.get("roth.res").get_base_dir().path_join("..")
	var autoexec := FileAccess.open(dosbox_autoexec_filepath, FileAccess.WRITE)
	autoexec.store_string("[autoexec]\n")
	autoexec.store_string("mount d \"%s\"\n" % ROTH_TEMP_DIRECTORY)
	autoexec.store_string("mount c \"%s\"\n" % roth_directory)
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
	Console.print("Executing: %s" % dosbox_bin)
	Console.print(dosbox_args)
	OS.execute(dosbox_bin, dosbox_args)


## Converts from game rotation to degrees
func rotation_to_degrees(rotation: float) -> int:
	return int(-180 + (90 * (rotation / 128)))


## Converts from degrees to game rotation
func degrees_to_rotation(degrees: float) -> int:
	return int(((degrees + 180) * 128) / 90)


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
	var results: Array
	var error: String = "Init"
	var i: int = 0
	while not error.is_empty():
		results = await Dialog.input("New Map Name:", title, results[1], error if i != 0 else "", false)
		i += 1
		if not results[0]:
			return ""
		error = ""
		if len(results[1]) > 8:
			error = "Please limit to 8 characters"
		if results[1].find(" ") > 0:
			error = "No spaces"
		if results[1].to_upper() in Roth.maps.map(func (m: Dictionary) -> String: return m.name):
			error = "Name in use."
		if len(results[1]) == 0:
			error = "Name is empty"
	
	return results[1].to_upper()
